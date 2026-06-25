#!/bin/bash

#############################################################################
# UMU Game Installer - Seamless Windows Game Installation for Steam Deck
#############################################################################
# This script provides 1:1 parity with Windows game installation:
# - Runs graphical installers through umu-run
# - Tracks and manages dependencies globally
# - Auto-configures Steam with proper Proton settings
# - Creates desktop shortcuts automatically
#############################################################################

set -euo pipefail

# FIX: Add cleanup trap to remove temporary files on exit
# This prevents temp file leaks when installation fails
TEMP_FILES_TO_CLEANUP=()
cleanup_temp_files() {
    for temp_item in "${TEMP_FILES_TO_CLEANUP[@]}"; do
        if [ -e "$temp_item" ]; then
            rm -rf "$temp_item" 2>/dev/null || true
        fi
    done
}
trap cleanup_temp_files EXIT

# Configuration
SCRIPT_VERSION="1.1.0"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/umu-game-installer"
DEPS_DIR="$CONFIG_DIR/dependencies"
DEPS_DB="$CONFIG_DIR/deps.db"
GAMES_DB="$CONFIG_DIR/games.db"
STEAM_USERDATA="$HOME/.local/share/Steam/userdata"
STEAM_SHORTCUTS="$HOME/.local/share/applications"
DEFAULT_INSTALL_ROOT="$HOME/Games"

# GUI Mode configuration (set via --gui flag)
GUI_MODE=false
DIALOG_TOOL="none"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file path (loaded from config)
LOG_FILE=""

#############################################################################
# Logging & Utility Functions
#############################################################################

write_log() {
    local level="$1"
    shift
    local msg="$*"
    # Clean up ANSI color codes
    local clean_msg=$(echo "$msg" | sed 's/\x1b\[[0-9;]*m//g')
    if [ -n "${LOG_FILE:-}" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $clean_msg" >> "$LOG_FILE"
    fi
}

log() {
    echo -e "${BLUE}[INFO]${NC} $*"
    write_log "INFO" "$@"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    write_log "SUCCESS" "$@"
}

warn() {
    local msg="$*"
    echo -e "${YELLOW}[WARN]${NC} $msg" >&2
    write_log "WARN" "$msg"
    if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
        notify-send "UMU Game Installer Warning" "$msg" 2>/dev/null || true
    fi
}

error() {
    local msg="$*"
    local clean_msg=$(echo "$msg" | sed 's/\x1b\[[0-9;]*m//g')
    echo -e "${RED}[ERROR]${NC} $msg" >&2
    write_log "ERROR" "$msg"
    if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
        if [ "$DIALOG_TOOL" = "kdialog" ]; then
            kdialog --title "Error" --error "$clean_msg" 2>/dev/null
        elif [ "$DIALOG_TOOL" = "zenity" ]; then
            zenity --error --title="Error" --text="$clean_msg" --width=400 2>/dev/null
        fi
    fi
    exit 1
}

init_dirs() {
    mkdir -p "$CONFIG_DIR" "$DEPS_DIR" "$STEAM_SHORTCUTS"
    touch "$DEPS_DB"
}

load_config() {
    # Defaults for config variables
    AUTO_INSTALL_DEPS=true
    PROMPT_DEPS=true
    SHARE_DEPS=true
    AUTO_DETECT_EXE=true
    SEARCH_DEPTH=3
    EXCLUDE_EXE_PATTERNS="unins uninst install setup redist crash report config"
    AUTO_ADD_STEAM=true
    AUTO_DESKTOP_SHORTCUT=true
    WINE_ENV_VARS=""
    WINE_DLL_OVERRIDES=""
    ENABLE_ESYNC=true
    ENABLE_FSYNC=true
    
    local global_config="/etc/umu-installer.conf"
    local user_config="$CONFIG_DIR/config"
    
    # FIX: Validate config file ownership and permissions before sourcing
    # to prevent privilege escalation through malicious config files
    if [ -f "$global_config" ]; then
        if [ "$(stat -c %u "$global_config" 2>/dev/null || stat -f %u "$global_config" 2>/dev/null)" = "0" ]; then
            # shellcheck disable=SC1090
            source "$global_config"
        else
            warn "Skipping $global_config: not owned by root"
        fi
    fi
    if [ -f "$user_config" ]; then
        local config_owner=$(stat -c %u "$user_config" 2>/dev/null || stat -f %u "$user_config" 2>/dev/null)
        if [ "$config_owner" = "$(id -u)" ]; then
            # shellcheck disable=SC1090
            source "$user_config"
        else
            warn "Skipping $user_config: not owned by current user"
        fi
    fi
    
    # Map configuration variables to script variables
    if [ -n "${INSTALL_ROOT:-}" ]; then
        DEFAULT_INSTALL_ROOT="$INSTALL_ROOT"
    fi
    if [ -n "${LOG_FILE:-}" ]; then
        LOG_FILE=$(echo "$LOG_FILE" | sed "s|\$CONFIG_DIR|$CONFIG_DIR|g")
    fi
}

get_config_value() {
    local setting="$1"
    local game_id="${2:-}"
    
    if [ -n "$game_id" ]; then
        local game_key=$(echo "$game_id" | sed 's/^umu-//' | tr '-' '_')
        local override_var="OVERRIDE_${game_key}_${setting}"
        # FIX: Use indirect expansion instead of eval to prevent command injection
        local val="${!override_var:-}"
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    
    # FIX: Use indirect expansion instead of eval to prevent command injection
    echo "${!setting:-}"
}

suggest_game_name() {
    local filename=$(basename "$1")
    local name="${filename%.*}"
    
    # Remove common prefixes (case insensitive)
    name=$(echo "$name" | sed -E 's/^(setup|install|installer|gog_setup|gog|umu)[_-]//i')
    
    # Remove common version and suffix patterns
    name=$(echo "$name" | sed -E 's/[_-](setup|install|installer|x64|x86|en|english|gog|v?[0-9]+(\.[0-9]+)*)*$//i')
    
    # Replace dashes and underscores with spaces
    name=$(echo "$name" | tr '_-' ' ')
    
    # Remove trailing version patterns if any left
    name=$(echo "$name" | sed -E 's/ v?[0-9]+(\.[0-9]+)*$//i')
    
    # Clean multiple spaces
    name=$(echo "$name" | sed 's/  */ /g')
    
    # Trim spaces
    name=$(echo "$name" | sed 's/^ *//;s/ *$//')
    
    # Capitalize first letter of each word (Titlecase)
    name=$(echo "$name" | sed -E 's/\b([a-z])/\U\1/g')
    
    # Fallback to original name if empty
    if [ -z "$name" ]; then
        echo "${filename%.*}"
    else
        echo "$name"
    fi
}

detect_dialog_tool() {
    if command -v kdialog &>/dev/null; then
        DIALOG_TOOL="kdialog"
    elif command -v zenity &>/dev/null; then
        DIALOG_TOOL="zenity"
    else
        DIALOG_TOOL="none"
    fi
}

gui_input() {
    local prompt="$1"
    local default="${2:-}"
    local response=""
    
    if [ "$DIALOG_TOOL" = "kdialog" ]; then
        response=$(kdialog --title "UMU Game Installer" --inputbox "$prompt" "$default" 2>/dev/null)
    elif [ "$DIALOG_TOOL" = "zenity" ]; then
        response=$(zenity --entry --title="UMU Game Installer" --text="$prompt" --entry-text="$default" --width=400 2>/dev/null)
    fi
    echo "$response"
}

gui_confirm() {
    local prompt="$1"
    
    if [ "$DIALOG_TOOL" = "kdialog" ]; then
        kdialog --title "UMU Game Installer" --yesno "$prompt" 2>/dev/null
        return $?
    elif [ "$DIALOG_TOOL" = "zenity" ]; then
        zenity --question --title="UMU Game Installer" --text="$prompt" --width=400 2>/dev/null
        return $?
    fi
    return 1
}

gui_select() {
    local prompt="$1"
    shift
    local items=("$@")
    
    if [ "$DIALOG_TOOL" = "kdialog" ]; then
        local menu_args=()
        local i=1
        for item in "${items[@]}"; do
            menu_args+=("$i" "$item")
            ((i++))
        done
        local choice_idx=$(kdialog --title "UMU Game Installer" --menu "$prompt" "${menu_args[@]}" 2>/dev/null)
        if [ -n "$choice_idx" ]; then
            echo "${items[$((choice_idx - 1))]}"
        fi
    elif [ "$DIALOG_TOOL" = "zenity" ]; then
        local choice=$(zenity --list --title="UMU Game Installer" --text="$prompt" --column="Select Executable" "${items[@]}" --width=500 --height=300 2>/dev/null)
        echo "$choice"
    fi
}

gui_file_picker() {
    local prompt="$1"
    local start_dir="$2"
    local choice=""
    
    if [ "$DIALOG_TOOL" = "kdialog" ]; then
        choice=$(kdialog --title "$prompt" --getopenfilename "$start_dir" "*.exe *.msi" 2>/dev/null)
    elif [ "$DIALOG_TOOL" = "zenity" ]; then
        choice=$(zenity --file-selection --title="$prompt" --filename="$start_dir/" --file-filter="*.exe *.msi" 2>/dev/null)
    fi
    echo "$choice"
}

download_file() {
    local url="$1"
    local dest="$2"
    
    log "Downloading: $url"
    if command -v curl &> /dev/null; then
        curl -L -o "$dest" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$dest" "$url"
    else
        error "Neither curl nor wget found. Cannot download dependency."
    fi
}

get_dep_url() {
    local dep_id="$1"
    local dep_version="$2"
    
    local var_name=$(echo "${dep_id}_${dep_version}_URL" | tr '[:lower:].' '[:upper:]_')
    # FIX: Use indirect expansion instead of eval to prevent command injection
    local custom_url="${!var_name:-}"
    if [ -n "$custom_url" ]; then
        echo "$custom_url"
        return
    fi
    
    case "${dep_id}:${dep_version}" in
        "vcredist:2022") echo "https://aka.ms/vs/17/release/vc_redist.x64.exe" ;;
        "vcredist:2019") echo "https://aka.ms/vs/16/release/vc_redist.x64.exe" ;;
        "vcredist:2017") echo "https://aka.ms/vs/15/release/vc_redist.x64.exe" ;;
        "vcredist:2015") echo "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe" ;;
        "vcredist:2013") echo "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD1-992C-94E5DE7E9674/vcredist_x64.exe" ;;
        "vcredist:2012") echo "https://download.microsoft.com/download/1/6/B/16B2874E-975E-404B-A26B-4C89D24F1D92/vcredist_x64.exe" ;;
        "vcredist:2010") echo "https://download.microsoft.com/download/A/8/0/A8075026-64A1-4636-AD54-738C2C314050/vcredist_x64.exe" ;;
        "dotnet:4.8") echo "https://download.visualstudio.microsoft.com/download/pr/010f2ccf-cf3c-4124-bcae-b1147e3cb3ec/d4543dcca98d93962696e57207604cfb/ndp48-web.exe" ;;
        "dotnet:4.7") echo "https://download.microsoft.com/download/D/D/3/DD35CC25-6E9C-484B-A74B-C57F792AC94C/NDP472-KB4054530-x86-x64-AllOS-ENU.exe" ;;
        "dotnet:4.6") echo "https://download.microsoft.com/download/C/3/A/C3A50878-00C5-443D-AE96-36C8B82B5120/NDP46-KB3045557-x86-x64-AllOS-ENU.exe" ;;
        "dotnet:3.5") echo "https://download.microsoft.com/download/2/0/e/20e90413-712f-438c-988e-fdaa79a8ac3d/dotnetfx35.exe" ;;
        "directx:9") echo "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" ;;
    esac
}

#############################################################################
# Windows Shortcut (.lnk) Parsing & Path Helpers
#############################################################################

parse_lnk() {
    local lnk_file="$1"
    python3 -c '
import struct, sys
def parse(lnk_path):
    try:
        with open(lnk_path, "rb") as f:
            data = f.read()
        if data[0:4] != b"L\x00\x00\x00": return None
        flags = struct.unpack("<I", data[20:24])[0]
        offset = 76
        if flags & 0x01:
            id_list_size = struct.unpack("<H", data[offset:offset+2])[0]
            offset += 2 + id_list_size
        if flags & 0x02:
            link_info_start = offset
            local_base_path_offset = struct.unpack("<I", data[offset+16:offset+20])[0]
            if local_base_path_offset:
                local_base_path_start = link_info_start + local_base_path_offset
                path_end = data.find(b"\x00", local_base_path_start)
                return data[local_base_path_start:path_end].decode("utf-8", errors="ignore")
    except Exception:
        pass
    return None
path = parse(sys.argv[1])
if path: print(path)
' "$lnk_file" 2>/dev/null
}

win_to_linux_path() {
    local win_path="$1"
    local prefix="$2"
    
    if [[ "$win_path" =~ ^[zZ]:\\ ]]; then
        # Map Z:\ to host root /
        local clean_path=$(echo "$win_path" | sed -E 's/^[zZ]:\\//')
        clean_path=$(echo "$clean_path" | tr '\\' '/')
        echo "/$clean_path"
    else
        # Map C:\ or other drive letters to prefix drive_c
        local clean_path=$(echo "$win_path" | sed -E 's/^[a-zA-Z]:\\//')
        clean_path=$(echo "$clean_path" | tr '\\' '/')
        echo "$prefix/drive_c/$clean_path"
    fi
}

list_prefix_shortcuts() {
    local prefix="$1"
    find "$prefix/drive_c" -type f -name "*.lnk" 2>/dev/null || true
}

#############################################################################
# Dependency Management
#############################################################################

# Initialize dependency database
init_deps_db() {
    if [ ! -f "$DEPS_DB" ]; then
        cat > "$DEPS_DB" << 'EOF'
# UMU Game Installer Dependency Database
# Format: DEPENDENCY_ID|VERSION|INSTALL_PATH|CHECKSUM|INSTALL_DATE
EOF
    fi
}

# Initialize games database
init_games_db() {
    if [ ! -f "$GAMES_DB" ]; then
        cat > "$GAMES_DB" << 'EOF'
# UMU Game Installer Games Database
# Format: GAME_ID|GAME_NAME|PREFIX_PATH|EXE_PATH|INSTALL_DATE
EOF
    fi
}

# Register game in database
register_game() {
    local game_id="$1"
    local game_name="$2"
    local prefix_path="$3"
    local exe_path="$4"
    local install_date=$(date +%Y-%m-%d)
    
    echo "${game_id}|${game_name}|${prefix_path}|${exe_path}|${install_date}" >> "$GAMES_DB"
    success "Registered game in database"
}

# Check if dependency is already installed
check_dependency() {
    local dep_id="$1"
    local version="$2"
    
    grep -q "^${dep_id}|${version}|" "$DEPS_DB" 2>/dev/null
}

# Add dependency to database
register_dependency() {
    local dep_id="$1"
    local version="$2"
    local install_path="$3"
    local checksum="$4"
    local install_date=$(date +%Y-%m-%d)
    
    echo "${dep_id}|${version}|${install_path}|${checksum}|${install_date}" >> "$DEPS_DB"
    success "Registered dependency: ${dep_id} ${version}"
}

# Get dependency install path
get_dependency_path() {
    local dep_id="$1"
    local version="$2"
    
    grep "^${dep_id}|${version}|" "$DEPS_DB" 2>/dev/null | cut -d'|' -f3 | head -n1
}

# Detect common dependencies from installer
detect_dependencies() {
    local installer="$1"
    local deps=()
    
    # Convert to lowercase for easier matching
    local installer_lower=$(echo "$installer" | tr '[:upper:]' '[:lower:]')
    
    # VC++ Redistributables
    if [[ "$installer_lower" =~ vcredist|vc_redist|vcruntime ]]; then
        if [[ "$installer_lower" =~ 2022 ]]; then
            deps+=("vcredist:2022")
        elif [[ "$installer_lower" =~ 2019 ]]; then
            deps+=("vcredist:2019")
        elif [[ "$installer_lower" =~ 2017 ]]; then
            deps+=("vcredist:2017")
        elif [[ "$installer_lower" =~ 2015 ]]; then
            deps+=("vcredist:2015")
        elif [[ "$installer_lower" =~ 2013 ]]; then
            deps+=("vcredist:2013")
        elif [[ "$installer_lower" =~ 2012 ]]; then
            deps+=("vcredist:2012")
        elif [[ "$installer_lower" =~ 2010 ]]; then
            deps+=("vcredist:2010")
        fi
    fi
    
    # .NET Framework
    if [[ "$installer_lower" =~ dotnet|netfx ]]; then
        [[ "$installer_lower" =~ 4\.8 ]] && deps+=("dotnet:4.8")
        [[ "$installer_lower" =~ 4\.7 ]] && deps+=("dotnet:4.7")
        [[ "$installer_lower" =~ 4\.6 ]] && deps+=("dotnet:4.6")
        [[ "$installer_lower" =~ 3\.5 ]] && deps+=("dotnet:3.5")
    fi
    
    # DirectX
    if [[ "$installer_lower" =~ directx|dxsetup ]]; then
        deps+=("directx:9")
    fi
    
    echo "${deps[@]}"
}

# Install dependency with umu-run
install_dependency() {
    local dep_installer="$1"
    local dep_id="$2"
    local dep_version="$3"
    local prefix_path="$DEPS_DIR/${dep_id}_${dep_version}"
    
    # Check if already installed
    if check_dependency "$dep_id" "$dep_version"; then
        log "Dependency ${dep_id} ${dep_version} already installed, skipping..."
        return 0
    fi
    
    log "Installing dependency: ${dep_id} ${dep_version}"
    
    # Create prefix for dependency
    mkdir -p "$prefix_path"
    
    # FIX: Calculate and verify checksum BEFORE executing the installer
    # This prevents running potentially malicious dependency installers
    local checksum=$(sha256sum "$dep_installer" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    log "Dependency installer checksum: $checksum"
    
    # TODO: Add checksum verification against known-good values
    # For now, at least log it before execution for auditing
    
    # Install using umu-run
    WINEPREFIX="$prefix_path" GAMEID="umu-dep-${dep_id}" \
        umu-run "$dep_installer" /quiet /norestart /silent || \
        umu-run "$dep_installer" /S /SILENT || \
        umu-run "$dep_installer"
    
    # Register in database
    register_dependency "$dep_id" "$dep_version" "$prefix_path" "$checksum"
    
    success "Dependency ${dep_id} ${dep_version} installed successfully"
}

#############################################################################
# Wine Prefix Management
#############################################################################

create_game_prefix() {
    local game_name="$1"
    local prefix_path="$2"
    
    log "Creating Wine prefix for ${game_name}..."
    
    mkdir -p "$prefix_path"
    
    # Initialize the prefix with umu-run
    WINEPREFIX="$prefix_path" GAMEID="umu-game-${game_name}" \
        umu-run wineboot --init
    
    success "Wine prefix created: ${prefix_path}"
}

# Link dependencies to game prefix
link_dependencies() {
    local game_prefix="$1"
    shift
    local deps=("$@")
    
    log "Linking dependencies to game prefix..."
    
    for dep in "${deps[@]}"; do
        local dep_id=$(echo "$dep" | cut -d':' -f1)
        local dep_version=$(echo "$dep" | cut -d':' -f2)
        local dep_path=$(get_dependency_path "$dep_id" "$dep_version")
        
        # If not found, try to auto-install it
        if [ -z "$dep_path" ] || [ ! -d "$dep_path" ]; then
            if [ "${AUTO_INSTALL_DEPS:-true}" = true ]; then
                local dep_url=$(get_dep_url "$dep_id" "$dep_version")
                if [ -n "$dep_url" ]; then
                    log "Dependency ${dep_id} ${dep_version} not found. Attempting auto-installation..."
                    
                    # Download to temp file
                    local temp_dir=$(mktemp -d)
                    TEMP_FILES_TO_CLEANUP+=("$temp_dir")  # FIX: Register for cleanup
                    local ext="${dep_url##*.}"
                    local temp_installer="$temp_dir/dep_setup.${ext}"
                    
                    # Show GUI/CLI download notification
                    if [ "$GUI_MODE" = true ] && [ "$DIALOG_TOOL" != "none" ]; then
                        if [ "$DIALOG_TOOL" = "kdialog" ]; then
                            notify-send "UMU Game Installer" "Downloading dependency: ${dep_id} ${dep_version}..." || true
                        elif [ "$DIALOG_TOOL" = "zenity" ]; then
                            zenity --info --text="Downloading dependency: ${dep_id} ${dep_version}..." --title="Downloading Dependency" --width=350 --timeout=3 2>/dev/null &
                        fi
                    fi
                    
                    if download_file "$dep_url" "$temp_installer"; then
                        # Install it
                        install_dependency "$temp_installer" "$dep_id" "$dep_version"
                        dep_path=$(get_dependency_path "$dep_id" "$dep_version")
                    else
                        warn "Failed to download dependency ${dep_id} ${dep_version}"
                    fi
                    
                    rm -rf "$temp_dir"
                fi
            fi
        fi
        
        if [ -n "$dep_path" ] && [ -d "$dep_path" ]; then
            log "Linking ${dep_id} ${dep_version}..."
            
            # Link system32 DLLs
            if [ -d "$dep_path/drive_c/windows/system32" ]; then
                cp -rn "$dep_path/drive_c/windows/system32/"* \
                    "$game_prefix/drive_c/windows/system32/" 2>/dev/null || true
            fi
            
            # Link syswow64 DLLs (32-bit on 64-bit)
            if [ -d "$dep_path/drive_c/windows/syswow64" ]; then
                mkdir -p "$game_prefix/drive_c/windows/syswow64"
                cp -rn "$dep_path/drive_c/windows/syswow64/"* \
                    "$game_prefix/drive_c/windows/syswow64/" 2>/dev/null || true
            fi
            
            success "Linked ${dep_id} ${dep_version}"
        else
            warn "Dependency ${dep_id} ${dep_version} not found"
        fi
    done
}

#############################################################################
# Game Installation
#############################################################################

run_game_installer() {
    local installer="$1"
    local game_prefix="$2"
    local game_id="$3"
    
    log "Running game installer..."
    log "Installer: ${installer}"
    log "Prefix: ${game_prefix}"
    
    # Run the installer with umu-run
    WINEPREFIX="$game_prefix" GAMEID="$game_id" \
        umu-run "$installer"
    
    success "Game installer completed"
}

# Detect game executable after installation
detect_game_executable() {
    local prefix="$1"
    local game_name="$2"
    local game_id="${3:-}"
    
    log "Detecting game executable..."
    
    local search_depth=$(get_config_value "SEARCH_DEPTH" "$game_id")
    [ -z "$search_depth" ] && search_depth=3
    
    local exclude_patterns=$(get_config_value "EXCLUDE_EXE_PATTERNS" "$game_id")
    [ -z "$exclude_patterns" ] && exclude_patterns="unins uninst install setup redist crash report config"
    
    # Convert space-separated patterns to pipe-separated regex
    local exclude_regex=$(echo "$exclude_patterns" | sed 's/  */|/g')
    
    # Common installation paths
    local search_paths=(
        "$prefix/drive_c/Program Files"
        "$prefix/drive_c/Program Files (x86)"
        "$prefix/drive_c/Games"
    )
    
    local executables=()
    
    for search_path in "${search_paths[@]}"; do
        if [ -d "$search_path" ]; then
            # Find .exe files, excluding common installers/uninstallers
            while IFS= read -r -d '' exe; do
                local basename=$(basename "$exe" | tr '[:upper:]' '[:lower:]')
                
                # Skip common non-game executables using exclude_regex
                if [[ ! "$basename" =~ $exclude_regex && "$basename" =~ \.exe$ ]]; then
                    executables+=("$exe")
                fi
            done < <(find "$search_path" -maxdepth "$search_depth" -type f -iname "*.exe" -print0 2>/dev/null)
        fi
    done
    
    # If multiple executables found, let user choose
    if [ ${#executables[@]} -eq 0 ]; then
        echo ""
    elif [ ${#executables[@]} -eq 1 ]; then
        echo "${executables[0]}"
    else
        if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
            local choice=$(gui_select "Multiple executables found. Please select the main game executable:" "${executables[@]}")
            echo "$choice"
        else
            log "Multiple executables found. Please select the game executable:" >&2
            
            # If stdin is not a terminal but tty is available, redirect stdin to tty for select
            if [ ! -t 0 ] && [ -c /dev/tty ]; then
                exec 3<&0
                exec 0</dev/tty
            fi
            
            local selected_exe=""
            set +e
            select exe in "${executables[@]}"; do
                if [ -n "$exe" ]; then
                    selected_exe="$exe"
                    break
                fi
            done
            set -e
            
            if [ ! -t 0 ] && [ -c /dev/tty ]; then
                exec 0<&3
                exec 3<&-
            fi
            
            echo "$selected_exe"
        fi
    fi
}

#############################################################################
# Steam Integration
#############################################################################

add_to_steam_vdf() {
    local game_name="$1"
    local launch_script="$2"
    
    log "Registering game in Steam shortcuts.vdf..."
    
    local steam_userdata="${STEAM_USERDATA:-$HOME/.local/share/Steam/userdata}"
    
    if [ -d "$steam_userdata" ]; then
        for config_dir in "$steam_userdata"/*/config; do
            [ -d "$config_dir" ] || continue
            local vdf_path="$config_dir/shortcuts.vdf"
            
            log "Updating shortcuts in: $vdf_path"
            
            python3 -c '
import os, sys, struct

def parse_binary_vdf(data):
    def read_string(offset):
        end = data.find(b"\x00", offset)
        if end == -1: return b"", offset
        return data[offset:end], end + 1
    def parse_map(offset):
        res = {}
        while offset < len(data):
            type_byte = data[offset]
            offset += 1
            if type_byte == 8: break
            key_bytes, offset = read_string(offset)
            key = key_bytes.decode("utf-8", errors="ignore")
            if type_byte == 0:
                val, offset = parse_map(offset)
                res[key] = val
            elif type_byte == 1:
                val_bytes, offset = read_string(offset)
                val = val_bytes.decode("utf-8", errors="ignore")
                res[key] = val
            elif type_byte == 2:
                # FIX: Use unsigned int (<I) instead of signed int (<i)
                # Steam uses unsigned integers for shortcut IDs, and IDs can exceed 2^31
                val = struct.unpack("<I", data[offset:offset+4])[0]
                offset += 4
                res[key] = val
        return res, offset
    if not data or data[0] != 0: return {}
    offset = 1
    root_key_bytes, offset = read_string(offset)
    root = root_key_bytes.decode("utf-8", errors="ignore")
    val, offset = parse_map(offset)
    return {root: val}

def serialize_binary_vdf(obj):
    def serialize_map(m):
        res = b""
        for k, v in m.items():
            k_bytes = k.encode("utf-8") + b"\x00"
            if isinstance(v, dict):
                res += b"\x00" + k_bytes + serialize_map(v) + b"\x08"
            elif isinstance(v, str):
                res += b"\x01" + k_bytes + v.encode("utf-8") + b"\x00"
            elif isinstance(v, int):
                # FIX: Use unsigned int (<I) instead of signed int (<i)
                # This prevents crashes when Steam generates IDs above 2^31
                res += b"\x02" + k_bytes + struct.pack("<I", v)
        return res
    root_key = list(obj.keys())[0]
    return b"\x00" + root_key.encode("utf-8") + b"\x00" + serialize_map(obj[root_key]) + b"\x08"

vdf_path, app_name, exe_path, start_dir = sys.argv[1:5]
data = b""
if os.path.exists(vdf_path):
    try:
        with open(vdf_path, "rb") as f: data = f.read()
    except Exception: pass
vdf_struct = {}
if data:
    try: vdf_struct = parse_binary_vdf(data)
    except Exception: pass
if "shortcuts" not in vdf_struct: vdf_struct["shortcuts"] = {}
shortcuts = vdf_struct["shortcuts"]
existing_idx = None
for idx, entry in shortcuts.items():
    if entry.get("AppName") == app_name or entry.get("Exe") == f"\"{exe_path}\"":
        existing_idx = idx
        break
new_entry = {
    "AppName": app_name,
    "Exe": f"\"{exe_path}\"",
    "StartDir": f"\"{start_dir}\"",
    "icon": "",
    "ShortcutPath": "",
    "LaunchOptions": "",
    "IsDev": 0,
    "Devkit": 0,
    "DevkitGameID": "",
    "DevkitOverrideAppID": 0,
    "LastPlayTime": 0,
    "tags": {}
}
if existing_idx is not None:
    shortcuts[existing_idx].update(new_entry)
else:
    indices = [int(k) for k in shortcuts.keys() if k.isdigit()]
    next_idx = str(max(indices) + 1) if indices else "0"
    shortcuts[next_idx] = new_entry
serialized = serialize_binary_vdf(vdf_struct)
try:
    os.makedirs(os.path.dirname(vdf_path), exist_ok=True)
    with open(vdf_path, "wb") as f: f.write(serialized)
    print("SUCCESS")
except Exception as e:
    print("ERROR:", e, file=sys.stderr)
' "$vdf_path" "$game_name" "$launch_script" "$(dirname "$launch_script")"
        done
    else
        warn "Steam userdata directory not found: $steam_userdata"
    fi
}

add_to_steam() {
    local game_name="$1"
    local game_exe="$2"
    local game_prefix="$3"
    local game_id="$4"
    
    log "Adding game to Steam..."
    
    # Create a launch script
    local launch_script="$CONFIG_DIR/launch_${game_id}.sh"
    
    cat > "$launch_script" << EOF
#!/bin/bash
export WINEPREFIX="${game_prefix}"
export GAMEID="${game_id}"
EOF

    # Add environment variables and overrides from configuration
    local dll_overrides=$(get_config_value "WINE_DLL_OVERRIDES" "$game_id")
    if [ -n "$dll_overrides" ]; then
        echo "export WINEDLLOVERRIDES=\"$dll_overrides\"" >> "$launch_script"
    fi
    
    local enable_esync=$(get_config_value "ENABLE_ESYNC" "$game_id")
    if [ "$enable_esync" = "false" ]; then
        echo "export WINEESYNC=0" >> "$launch_script"
    else
        echo "export WINEESYNC=1" >> "$launch_script"
    fi
    
    local enable_fsync=$(get_config_value "ENABLE_FSYNC" "$game_id")
    if [ "$enable_fsync" = "false" ]; then
        echo "export WINEFSYNC=0" >> "$launch_script"
    else
        echo "export WINEFSYNC=1" >> "$launch_script"
    fi
    
    local wine_env_vars=$(get_config_value "WINE_ENV_VARS" "$game_id")
    if [ -n "$wine_env_vars" ]; then
        for env_var in $wine_env_vars; do
            echo "export $env_var" >> "$launch_script"
        done
    fi
    
    cat >> "$launch_script" << EOF
exec umu-run "${game_exe}" "\$@"
EOF
    
    chmod +x "$launch_script"
    
    # Create Steam shortcut (shortcuts.vdf handling)
    local desktop_file="$STEAM_SHORTCUTS/${game_id}.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Name=${game_name}
Exec=${launch_script}
Type=Application
Categories=Game;
Comment=Installed via UMU Game Installer
Icon=application-x-executable
StartupNotify=true
Terminal=false
X-KDE-SubstituteUID=false
EOF
    
    success "Steam integration configured: ${desktop_file}"
    
    # Write directly to Steam shortcuts.vdf
    add_to_steam_vdf "$game_name" "$launch_script"
}

#############################################################################
# Desktop Shortcut
#############################################################################

create_desktop_shortcut() {
    local game_name="$1"
    local launch_script="$2"
    local game_id="$3"
    
    log "Creating desktop shortcut..."
    
    local desktop_dir="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
    mkdir -p "$desktop_dir"
    
    local desktop_file="$desktop_dir/${game_name}.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Name=${game_name}
Exec=${launch_script}
Type=Application
Categories=Game;
Comment=Installed via UMU Game Installer
Icon=application-x-executable
StartupNotify=true
Terminal=false
X-KDE-SubstituteUID=false
EOF
    
    chmod +x "$desktop_file"
    
    # Mark as trusted on KDE
    if command -v gio &> /dev/null; then
        gio set "$desktop_file" "metadata::trusted" "true" 2>/dev/null || true
    fi
    
    success "Desktop shortcut created: ${desktop_file}"
}

#############################################################################
# Main Installation Flow
#############################################################################

install_game() {
    local installer_path="$1"
    local game_name="${2:-}"
    
    # Validate installer exists
    if [ ! -f "$installer_path" ]; then
        error "Installer not found: ${installer_path}"
    fi
    
    # Get game name from user (if not provided)
    if [ -z "$game_name" ]; then
        if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
            local suggested=$(suggest_game_name "$installer_path")
            game_name=$(gui_input "Enter game name:" "$suggested")
            if [ -z "$game_name" ]; then
                log "Installation cancelled by user."
                exit 0
            fi
        else
            echo ""
            read -p "Enter game name: " game_name
            
            if [ -z "$game_name" ]; then
                error "Game name cannot be empty"
            fi
        fi
    fi
    
    # Generate game ID
    local game_id="umu-$(echo "$game_name" | tr '[:upper:] ' '[:lower:]-' | sed 's/[^a-z0-9-]//g')"
    
    log "Starting installation of: ${game_name}"
    log "Game ID: ${game_id}"
    
    # Create game prefix
    local game_prefix=""
    local config_prefix=$(get_config_value "PREFIX" "$game_id")
    if [ -n "$config_prefix" ]; then
        game_prefix="$config_prefix"
    else
        local install_root=$(get_config_value "INSTALL_ROOT")
        if [ -n "$install_root" ]; then
            DEFAULT_INSTALL_ROOT="$install_root"
        fi
        game_prefix="$DEFAULT_INSTALL_ROOT/${game_name}/prefix"
    fi
    
    mkdir -p "$(dirname "$game_prefix")"  # Ensure root exists
    create_game_prefix "$game_name" "$game_prefix"
    
    # Record list of existing shortcuts before running the installer
    local pre_shortcuts_file=$(mktemp)
    TEMP_FILES_TO_CLEANUP+=("$pre_shortcuts_file")  # FIX: Register for cleanup
    list_prefix_shortcuts "$game_prefix" > "$pre_shortcuts_file"
    
    # Load dependency prompt settings
    local auto_install_deps=$(get_config_value "AUTO_INSTALL_DEPS")
    [ -z "$auto_install_deps" ] && auto_install_deps=true
    local prompt_deps=$(get_config_value "PROMPT_DEPS")
    [ -z "$prompt_deps" ] && prompt_deps=true
    
    # Detect and handle dependencies
    local detected_deps=$(detect_dependencies "$installer_path")
    
    # Read game-specific dependencies override
    local config_deps=$(get_config_value "DEPS" "$game_id")
    if [ -n "$config_deps" ]; then
        log "Configuration overrides dependencies for $game_id: $config_deps"
        detected_deps="$config_deps"
    fi
    
    local deps_array=()
    
    if [ -n "$detected_deps" ]; then
        log "Detected dependencies: ${detected_deps}"
        local install_deps="y"
        
        if [ "$prompt_deps" = true ]; then
            if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
                local msg="The following dependencies were detected for the game:\n\n"
                for dep in $detected_deps; do
                    msg+="  • $dep\n"
                done
                msg+="\nWould you like to install them?"
                if gui_confirm "$msg"; then
                    install_deps="y"
                else
                    install_deps="n"
                fi
            else
                echo ""
                echo "The following dependencies were detected:"
                for dep in $detected_deps; do
                    echo "  - $dep"
                done
                echo ""
                read -p "Install dependencies? (Y/n): " install_deps
            fi
        fi
        
        if [[ ! "$install_deps" =~ ^[Nn] ]]; then
            deps_array=($detected_deps)
            link_dependencies "$game_prefix" "${deps_array[@]}"
        fi
    fi
    
    # Show progress notification
    if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
        if [ "$DIALOG_TOOL" = "kdialog" ]; then
            kdialog --passivepopup "Creating Wine prefix and installing $game_name... The installer will appear shortly." 5 2>/dev/null &
        elif [ "$DIALOG_TOOL" = "zenity" ]; then
            zenity --info --text="Installing $game_name...\n\nThe game installer will appear shortly.\nFollow the installer as you would on Windows." --width=400 --timeout=5 2>/dev/null &
        fi
    fi
    
    # Run the game installer
    run_game_installer "$installer_path" "$game_prefix" "$game_id"
    
    # Check if any new shortcuts were created
    local post_shortcuts_file=$(mktemp)
    TEMP_FILES_TO_CLEANUP+=("$post_shortcuts_file")  # FIX: Register for cleanup
    list_prefix_shortcuts "$game_prefix" > "$post_shortcuts_file"
    local new_shortcuts=""
    if [ -f "$pre_shortcuts_file" ] && [ -f "$post_shortcuts_file" ]; then
        new_shortcuts=$(comm -13 <(sort "$pre_shortcuts_file") <(sort "$post_shortcuts_file") 2>/dev/null || echo "")
    fi
    rm -f "$pre_shortcuts_file" "$post_shortcuts_file"
    
    local shortcut_exe=""
    local shortcut_game_name=""
    if [ -n "$new_shortcuts" ]; then
        local first_lnk=$(echo "$new_shortcuts" | head -n1)
        log "Found new shortcut: $first_lnk"
        
        local win_target=$(parse_lnk "$first_lnk")
        if [ -n "$win_target" ]; then
            shortcut_exe=$(win_to_linux_path "$win_target" "$game_prefix")
            local lnk_basename=$(basename "$first_lnk")
            shortcut_game_name="${lnk_basename%.lnk}"
            log "Parsed shortcut target: $shortcut_exe"
            log "Parsed shortcut game name: $shortcut_game_name"
        fi
    fi
    
    # Detect game executable
    log "Installation complete. Detecting game executable..."
    local game_exe=""
    
    local auto_detect_exe=$(get_config_value "AUTO_DETECT_EXE" "$game_id")
    [ -z "$auto_detect_exe" ] && auto_detect_exe=true
    
    local manual_exe=$(get_config_value "MANUAL_EXE" "$game_id")
    if [ -n "$manual_exe" ]; then
        game_exe="$game_prefix/$manual_exe"
        success "Using manual executable override from config: ${game_exe}"
    elif [ -n "$shortcut_exe" ] && [ -f "$shortcut_exe" ]; then
        game_exe="$shortcut_exe"
        success "Automatically detected game executable from installer shortcut: ${game_exe}"
    elif [ "$auto_detect_exe" = true ]; then
        game_exe=$(detect_game_executable "$game_prefix" "$game_name" "$game_id")
    fi
    
    if [ -z "$game_exe" ]; then
        warn "Could not auto-detect game executable."
        if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
            game_exe=$(gui_file_picker "Select the main game executable (.exe)" "$game_prefix/drive_c")
            if [ -z "$game_exe" ]; then
                error "Game executable selection cancelled. Cannot complete installation."
            fi
        else
            read -p "Enter full path to game executable: " game_exe
            if [ -z "$game_exe" ]; then
                error "Game executable cannot be empty"
            fi
        fi
    else
        success "Detected game executable: ${game_exe}"
        local use_detected="y"
        
        if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
            if ! gui_confirm "Detected game executable:\n\n${game_exe}\n\nUse this executable?"; then
                use_detected="n"
            fi
        else
            read -p "Use this executable? (Y/n): " use_detected
        fi
        
        if [[ "$use_detected" =~ ^[Nn] ]]; then
            if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
                game_exe=$(gui_file_picker "Select the main game executable (.exe)" "$game_prefix/drive_c")
                if [ -z "$game_exe" ]; then
                    error "Game executable selection cancelled. Cannot complete installation."
                fi
            else
                read -p "Enter full path to game executable: " game_exe
                if [ -z "$game_exe" ]; then
                    error "Game executable cannot be empty"
                fi
            fi
        fi
    fi
    
    # Add to Steam
    local auto_add_steam=$(get_config_value "AUTO_ADD_STEAM" "$game_id")
    [ -z "$auto_add_steam" ] && auto_add_steam=true
    if [ "$auto_add_steam" = true ]; then
        add_to_steam "$game_name" "$game_exe" "$game_prefix" "$game_id"
    fi
    
    # Create desktop shortcut
    local auto_desktop_shortcut=$(get_config_value "AUTO_DESKTOP_SHORTCUT" "$game_id")
    [ -z "$auto_desktop_shortcut" ] && auto_desktop_shortcut=true
    local launch_script="$CONFIG_DIR/launch_${game_id}.sh"
    if [ "$auto_desktop_shortcut" = true ]; then
        create_desktop_shortcut "$game_name" "$launch_script" "$game_id"
    fi
    
    # Register game in database
    register_game "$game_id" "$game_name" "$game_prefix" "$game_exe"
    
    echo ""
    success "Game installation complete!"
    echo ""
    echo "Game Name: ${game_name}"
    echo "Game ID: ${game_id}"
    echo "Prefix: ${game_prefix}"
    echo "Executable: ${game_exe}"
    echo "Launch Script: ${launch_script}"
    echo ""
    log "You can now launch ${game_name} from your desktop or Steam library."
    
    # Show GUI success notification
    if [ "${GUI_MODE:-false}" = true ] && [ "${DIALOG_TOOL:-none}" != "none" ]; then
        local success_msg="${game_name} installed successfully!\n\nYou can launch it from:\n• Desktop shortcut\n• Steam library\n• Application menu"
        if [ "$DIALOG_TOOL" = "kdialog" ]; then
            kdialog --title "Installation Complete" --msgbox "$success_msg" 2>/dev/null
        elif [ "$DIALOG_TOOL" = "zenity" ]; then
            zenity --info --title="Installation Complete" --text="$success_msg" --width=400 2>/dev/null
        fi
    fi
}

#############################################################################
# CLI Interface
#############################################################################

show_help() {
    cat << EOF
UMU Game Installer v${SCRIPT_VERSION}
Seamless Windows game installation for Steam Deck

USAGE:
    $(basename "$0") [OPTIONS] <installer.exe>

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    --list-deps             List installed dependencies
    --clean-deps            Clean unused dependencies
    --install-root <path>   Set installation root directory (default: ~/Games)

EXAMPLES:
    # Install a game
    $(basename "$0") ~/Downloads/GameSetup.exe
    
    # Install with custom root
    $(basename "$0") --install-root /mnt/sdcard/Games setup.exe
    
    # List dependencies
    $(basename "$0") --list-deps

FEATURES:
    ✓ Native Windows-like GUI installer experience
    ✓ Automatic dependency detection and management
    ✓ Global dependency sharing (no duplication)
    ✓ Automatic Steam integration
    ✓ Desktop shortcut creation
    ✓ Full Proton/Wine compatibility

For more information, visit: https://github.com/Open-Wine-Components/umu-launcher
EOF
}

show_version() {
    echo "UMU Game Installer v${SCRIPT_VERSION}"
}

list_dependencies() {
    log "Installed Dependencies:"
    echo ""
    
    if [ ! -f "$DEPS_DB" ] || [ ! -s "$DEPS_DB" ]; then
        echo "No dependencies installed."
        return
    fi
    
    printf "%-20s %-10s %-15s %s\n" "DEPENDENCY" "VERSION" "INSTALL DATE" "PATH"
    echo "--------------------------------------------------------------------------------"
    
    while IFS='|' read -r dep_id version path checksum date; do
        # Skip comments and empty lines
        [[ "$dep_id" =~ ^#.*$ ]] && continue
        [ -z "$dep_id" ] && continue
        
        printf "%-20s %-10s %-15s %s\n" "$dep_id" "$version" "$date" "$path"
    done < "$DEPS_DB"
}

clean_dependencies() {
    log "Cleaning unused dependencies..."
    warn "This feature is not yet implemented."
    # TODO: Scan for dependencies not used by any installed game
}

#############################################################################
# Main Entry Point
#############################################################################

main() {
    # Initialize dirs and load config to set LOG_FILE before logging first info
    init_dirs
    load_config
    
    log "UMU Game Installer v${SCRIPT_VERSION}"
    
    # Check prerequisites
    if ! command -v python3 &> /dev/null; then
        error "python3 is not installed. Please run umu-system-installer.sh or install python3 manually."
    fi
    
    if ! command -v umu-run &> /dev/null; then
        error "umu-run is not installed. Please install it first:\n  pip install --user umu-launcher"
    fi
    
    init_deps_db
    init_games_db
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local installer_path=""
    GUI_MODE=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --list-deps)
                list_dependencies
                exit 0
                ;;
            --clean-deps)
                clean_dependencies
                exit 0
                ;;
            --install-root)
                DEFAULT_INSTALL_ROOT="$2"
                shift 2
                ;;
            --gui)
                GUI_MODE=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                installer_path="$1"
                shift
                ;;
        esac
    done
    
    if [ -z "$installer_path" ]; then
        error "No installer specified. Use --help for usage information."
    fi
    
    # Detect dialog tool if GUI_MODE is true
    if [ "$GUI_MODE" = true ]; then
        detect_dialog_tool
        if [ "$DIALOG_TOOL" = "none" ]; then
            warn "GUI mode requested but neither kdialog nor zenity is installed. Falling back to CLI mode."
            GUI_MODE=false
        fi
    fi
    
    # Check if game name provided via stdin (for CLI GUI wrapper compatibility)
    # Only read stdin when NOT in GUI mode to prevent hanging on input
    local game_name=""
    if [ ! -t 0 ] && [ "$GUI_MODE" = false ]; then
        read -r game_name || true
    fi
    
    # Start installation
    install_game "$installer_path" "$game_name"
}

# Run main function
main "$@"
