#!/bin/bash

#############################################################################
# UMU Game Manager - Manage installed games and dependencies
#############################################################################

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/umu-game-installer"
DEPS_DB="$CONFIG_DIR/deps.db"
GAMES_DB="$CONFIG_DIR/games.db"
DEFAULT_INSTALL_ROOT="$HOME/Games"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

load_config() {
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
    
    if [ -n "${INSTALL_ROOT:-}" ]; then
        DEFAULT_INSTALL_ROOT="$INSTALL_ROOT"
    fi
}

#############################################################################
# Game Database Management
#############################################################################

init_games_db() {
    mkdir -p "$CONFIG_DIR"
    
    if [ ! -f "$GAMES_DB" ]; then
        cat > "$GAMES_DB" << 'EOF'
# UMU Game Manager Database
# Format: GAME_ID|GAME_NAME|PREFIX_PATH|EXE_PATH|INSTALL_DATE
EOF
    fi
}

list_games() {
    log "Installed Games:"
    echo ""
    
    if [ ! -f "$GAMES_DB" ] || [ ! -s "$GAMES_DB" ]; then
        echo "No games installed yet."
        echo ""
        echo "Install a game with: umu-game-installer.sh installer.exe"
        return
    fi
    
    printf "%-30s %-20s %-15s\n" "GAME NAME" "GAME ID" "INSTALL DATE"
    echo "--------------------------------------------------------------------------------"
    
    while IFS='|' read -r game_id game_name prefix_path exe_path install_date; do
        [[ "$game_id" =~ ^#.*$ ]] && continue
        [ -z "$game_id" ] && continue
        
        printf "%-30s %-20s %-15s\n" "$game_name" "$game_id" "$install_date"
    done < "$GAMES_DB"
    
    echo ""
}

list_dependencies() {
    log "Installed Dependencies:"
    echo ""
    
    if [ ! -f "$DEPS_DB" ] || [ ! -s "$DEPS_DB" ]; then
        echo "No dependencies installed."
        return
    fi
    
    printf "%-20s %-10s %-15s %-10s\n" "DEPENDENCY" "VERSION" "INSTALL DATE" "SIZE"
    echo "--------------------------------------------------------------------------------"
    
    while IFS='|' read -r dep_id version path checksum date; do
        [[ "$dep_id" =~ ^#.*$ ]] && continue
        [ -z "$dep_id" ] && continue
        
        local size="N/A"
        if [ -d "$path" ]; then
            size=$(du -sh "$path" 2>/dev/null | cut -f1)
        fi
        
        printf "%-20s %-10s %-15s %-10s\n" "$dep_id" "$version" "$date" "$size"
    done < "$DEPS_DB"
    
    echo ""
}

show_game_info() {
    local game_identifier="$1"
    
    if [ ! -f "$GAMES_DB" ]; then
        error "No games database found"
    fi
    
    local found=0
    
    while IFS='|' read -r game_id game_name prefix_path exe_path install_date; do
        [[ "$game_id" =~ ^#.*$ ]] && continue
        [ -z "$game_id" ] && continue
        
        if [[ "$game_id" == "$game_identifier" ]] || [[ "$game_name" == "$game_identifier" ]]; then
            found=1
            
            echo ""
            echo "Game Information"
            echo "================"
            echo "Name:          $game_name"
            echo "ID:            $game_id"
            echo "Install Date:  $install_date"
            echo "Prefix:        $prefix_path"
            echo "Executable:    $exe_path"
            echo ""
            
            if [ -d "$prefix_path" ]; then
                local size=$(du -sh "$prefix_path" 2>/dev/null | cut -f1)
                echo "Prefix Size:   $size"
            fi
            
            # Check for launch script
            local launch_script="$CONFIG_DIR/launch_${game_id}.sh"
            if [ -f "$launch_script" ]; then
                echo "Launch Script: $launch_script"
            fi
            
            # Check for desktop file
            local desktop_file="$HOME/.local/share/applications/${game_id}.desktop"
            if [ -f "$desktop_file" ]; then
                echo "Steam Entry:   $desktop_file"
            fi
            
            echo ""
            break
        fi
    done < "$GAMES_DB"
    
    if [ $found -eq 0 ]; then
        error "Game not found: $game_identifier"
    fi
}

uninstall_game() {
    local game_identifier="$1"
    
    if [ ! -f "$GAMES_DB" ]; then
        error "No games database found"
    fi
    
    local found=0
    local game_id=""
    local game_name=""
    local prefix_path=""
    
    while IFS='|' read -r gid gname ppath epath idate; do
        [[ "$gid" =~ ^#.*$ ]] && continue
        [ -z "$gid" ] && continue
        
        if [[ "$gid" == "$game_identifier" ]] || [[ "$gname" == "$game_identifier" ]]; then
            found=1
            game_id="$gid"
            game_name="$gname"
            prefix_path="$ppath"
            break
        fi
    done < "$GAMES_DB"
    
    if [ $found -eq 0 ]; then
        error "Game not found: $game_identifier"
    fi
    
    warn "This will remove: $game_name"
    echo "  - Prefix: $prefix_path"
    echo "  - Launch script: $CONFIG_DIR/launch_${game_id}.sh"
    echo "  - Desktop shortcuts"
    echo ""
    read -p "Are you sure? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled"
        return
    fi
    
    log "Uninstalling $game_name..."
    
    # Remove prefix
    if [ -d "$prefix_path" ]; then
        rm -rf "$prefix_path"
        success "Removed prefix"
    fi
    
    # Remove launch script
    local launch_script="$CONFIG_DIR/launch_${game_id}.sh"
    if [ -f "$launch_script" ]; then
        rm -f "$launch_script"
        success "Removed launch script"
    fi
    
    # Remove desktop files
    local desktop_file="$HOME/.local/share/applications/${game_id}.desktop"
    if [ -f "$desktop_file" ]; then
        rm -f "$desktop_file"
        success "Removed Steam entry"
    fi
    
    local desktop_shortcut="$HOME/Desktop/${game_name}.desktop"
    if [ -f "$desktop_shortcut" ]; then
        rm -f "$desktop_shortcut"
        success "Removed desktop shortcut"
    fi
    
    # Remove from database
    local temp_db=$(mktemp)
    grep -v "^${game_id}|" "$GAMES_DB" > "$temp_db"
    mv "$temp_db" "$GAMES_DB"
    
    success "Game uninstalled: $game_name"
}

launch_game() {
    local game_identifier="$1"
    
    if [ ! -f "$GAMES_DB" ]; then
        error "No games database found"
    fi
    
    local found=0
    local game_id=""
    local launch_script=""
    
    while IFS='|' read -r gid gname ppath epath idate; do
        [[ "$gid" =~ ^#.*$ ]] && continue
        [ -z "$gid" ] && continue
        
        if [[ "$gid" == "$game_identifier" ]] || [[ "$gname" == "$game_identifier" ]]; then
            found=1
            game_id="$gid"
            launch_script="$CONFIG_DIR/launch_${game_id}.sh"
            break
        fi
    done < "$GAMES_DB"
    
    if [ $found -eq 0 ]; then
        error "Game not found: $game_identifier"
    fi
    
    if [ ! -f "$launch_script" ]; then
        error "Launch script not found: $launch_script"
    fi
    
    log "Launching game..."
    "$launch_script"
}

check_disk_usage() {
    log "Disk Usage Summary:"
    echo ""
    
    # Games
    if [ -d "$DEFAULT_INSTALL_ROOT" ]; then
        local games_size=$(du -sh "$DEFAULT_INSTALL_ROOT" 2>/dev/null | cut -f1)
        echo "Games:        $games_size ($DEFAULT_INSTALL_ROOT)"
    fi
    
    # Dependencies
    local deps_dir="$CONFIG_DIR/dependencies"
    if [ -d "$deps_dir" ]; then
        local deps_size=$(du -sh "$deps_dir" 2>/dev/null | cut -f1)
        echo "Dependencies: $deps_size ($deps_dir)"
    fi
    
    # Config
    if [ -d "$CONFIG_DIR" ]; then
        local config_size=$(du -sh "$CONFIG_DIR" 2>/dev/null | cut -f1)
        echo "Config:       $config_size ($CONFIG_DIR)"
    fi
    
    echo ""
}

clean_orphaned() {
    log "Checking for orphaned files..."
    
    local orphaned_count=0
    
    # Check for launch scripts without database entries
    if [ -d "$CONFIG_DIR" ]; then
        for launch_script in "$CONFIG_DIR"/launch_*.sh; do
            [ -f "$launch_script" ] || continue
            
            local script_name=$(basename "$launch_script")
            local game_id=${script_name#launch_}
            game_id=${game_id%.sh}
            
            if ! grep -q "^${game_id}|" "$GAMES_DB" 2>/dev/null; then
                warn "Orphaned launch script: $launch_script"
                ((orphaned_count++))
                
                read -p "Remove? (y/N): " remove
                if [[ "$remove" =~ ^[Yy]$ ]]; then
                    rm -f "$launch_script"
                    success "Removed"
                fi
            fi
        done
    fi
    
    # Check for desktop files
    for desktop_file in "$HOME/.local/share/applications"/umu-*.desktop; do
        [ -f "$desktop_file" ] || continue
        
        local file_name=$(basename "$desktop_file")
        local game_id=${file_name%.desktop}
        
        if ! grep -q "^${game_id}|" "$GAMES_DB" 2>/dev/null; then
            warn "Orphaned Steam entry: $desktop_file"
            ((orphaned_count++))
            
            read -p "Remove? (y/N): " remove
            if [[ "$remove" =~ ^[Yy]$ ]]; then
                rm -f "$desktop_file"
                success "Removed"
            fi
        fi
    done
    
    if [ $orphaned_count -eq 0 ]; then
        success "No orphaned files found"
    else
        log "Found $orphaned_count orphaned files"
    fi
}

export_game_list() {
    local output_file="$1"
    
    if [ ! -f "$GAMES_DB" ]; then
        error "No games database found"
    fi
    
    log "Exporting game list to: $output_file"
    
    {
        echo "# UMU Game Installer - Installed Games"
        echo "# Generated: $(date)"
        echo ""
        
        while IFS='|' read -r game_id game_name prefix_path exe_path install_date; do
            [[ "$game_id" =~ ^#.*$ ]] && continue
            [ -z "$game_id" ] && continue
            
            echo "## $game_name"
            echo "- **ID:** $game_id"
            echo "- **Installed:** $install_date"
            echo "- **Prefix:** $prefix_path"
            echo "- **Executable:** $exe_path"
            echo ""
        done < "$GAMES_DB"
    } > "$output_file"
    
    success "Exported to: $output_file"
}

show_help() {
    cat << EOF
UMU Game Manager - Manage installed games and dependencies

USAGE:
    $(basename "$0") COMMAND [OPTIONS]

COMMANDS:
    list                    List all installed games
    deps                    List installed dependencies
    info <game>             Show detailed game information
    launch <game>           Launch a game
    uninstall <game>        Uninstall a game
    disk                    Show disk usage summary
    clean                   Clean orphaned files
    export <file>           Export game list to file

OPTIONS:
    -h, --help             Show this help message

EXAMPLES:
    # List all games
    $(basename "$0") list
    
    # Show game info
    $(basename "$0") info "Witcher 3"
    $(basename "$0") info umu-witcher-3
    
    # Launch game
    $(basename "$0") launch "Witcher 3"
    
    # Uninstall game
    $(basename "$0") uninstall "Witcher 3"
    
    # Check disk usage
    $(basename "$0") disk
    
    # Export game list
    $(basename "$0") export ~/my-games.md

EOF
}

main() {
    load_config
    init_games_db
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        list)
            list_games
            ;;
        deps)
            list_dependencies
            ;;
        info)
            [ $# -lt 2 ] && error "Usage: $(basename "$0") info <game>"
            show_game_info "$2"
            ;;
        launch)
            [ $# -lt 2 ] && error "Usage: $(basename "$0") launch <game>"
            launch_game "$2"
            ;;
        uninstall)
            [ $# -lt 2 ] && error "Usage: $(basename "$0") uninstall <game>"
            uninstall_game "$2"
            ;;
        disk)
            check_disk_usage
            ;;
        clean)
            clean_orphaned
            ;;
        export)
            [ $# -lt 2 ] && error "Usage: $(basename "$0") export <file>"
            export_game_list "$2"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            error "Unknown command: $1 (use --help for usage)"
            ;;
    esac
}

main "$@"
