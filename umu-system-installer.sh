#!/bin/bash

#############################################################################
# UMU System Installer - One-Time Setup for Seamless GUI Installer Support
#############################################################################
# This script installs the UMU Game Installer system ONCE, then permanently
# enables Windows .exe installers to work by double-clicking them.
#
# After running this once, you can:
# - Double-click any .exe installer
# - Right-click any .exe → "Install Game"
# - Installers work exactly like on Windows
# - No command line needed ever again
#############################################################################

set -euo pipefail

SCRIPT_VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Installation paths
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/umu-game-installer"
SHARE_DIR="${HOME}/.local/share"
DESKTOP_DIR="${HOME}/.local/share/applications"
MIME_DIR="${HOME}/.local/share/mime/packages"
FILE_MANAGER_DIR_KDE5="${HOME}/.local/share/kservices5/ServiceMenus"
FILE_MANAGER_DIR_KDE6="${HOME}/.local/share/kio/servicemenus"

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
header() { echo -e "\n${CYAN}${BOLD}═══ $* ═══${NC}\n"; }

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║           UMU GAME INSTALLER - SYSTEM SETUP                 ║
║                                                              ║
║   One-time installation to enable Windows game installers   ║
║   to work by double-clicking them - just like Windows!      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

check_dependencies() {
    header "Checking Prerequisites"
    
    # Check if python3 is installed, and if not, attempt to automatically install it first
    if ! command -v python3 &> /dev/null; then
        warn "python3 not found. Attempting to automatically install it..."
        local installed=0
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3 && installed=1
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y python3 && installed=1
        elif command -v pacman &> /dev/null; then
            if [ -f "/etc/os-release" ] && grep -q "steamdeck" /etc/os-release 2>/dev/null; then
                log "Steam Deck detected. Temporarily disabling read-only filesystem..."
                sudo steamos-readonly disable
                sudo pacman -Syy --noconfirm python && installed=1
                sudo steamos-readonly enable
            else
                sudo pacman -S --noconfirm python && installed=1
            fi
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y python3 && installed=1
        fi
        
        if [ $installed -eq 1 ]; then
            success "Successfully installed python3"
        else
            error "Could not automatically install python3. Please install python3 manually using your package manager."
        fi
    else
        success "python3 is installed"
    fi
    
    local missing=()
    
    # Check for umu-run
    if ! command -v umu-run &> /dev/null; then
        warn "umu-run not found"
        missing+=("umu-run")
    else
        success "umu-run is installed"
    fi
    
    # Check for bash and curl (required)
    for cmd in bash curl; do
        if ! command -v "$cmd" &> /dev/null; then
            warn "$cmd not found"
            missing+=("$cmd")
        else
            success "$cmd is installed"
        fi
    done
    
    # Check for GUI dialog tools (at least one needed)
    local has_gui_tool=0
    for cmd in kdialog zenity; do
        if command -v "$cmd" &> /dev/null; then
            success "$cmd is installed (GUI dialogs)"
            has_gui_tool=1
            break
        fi
    done
    
    if [ $has_gui_tool -eq 0 ]; then
        warn "No GUI dialog tool found (kdialog or zenity)"
        missing+=("kdialog or zenity")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        warn "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Please install them first:"
        echo ""
        
        if [[ " ${missing[*]} " =~ " umu-run " ]]; then
            echo "  umu-run:"
            echo "    pip install --user umu-launcher"
            echo ""
        fi
        
        if [[ " ${missing[*]} " =~ " kdialog or zenity " ]]; then
            echo "  kdialog (KDE/Steam Deck) or zenity (GNOME):"
            echo "    sudo pacman -S kdialog  # Steam Deck / KDE"
            echo "    sudo pacman -S zenity   # Alternative"
            echo "    sudo apt install kdialog zenity  # Ubuntu"
            echo ""
        fi
        
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

install_core_scripts() {
    header "Installing Core Scripts"
    
    mkdir -p "$INSTALL_DIR"
    
    # Install main installer script
    if [ -f "./umu-game-installer.sh" ]; then
        log "Installing umu-game-installer..."
        cp "./umu-game-installer.sh" "$INSTALL_DIR/umu-game-installer"
        chmod +x "$INSTALL_DIR/umu-game-installer"
        success "Installed umu-game-installer"
    else
        warn "umu-game-installer.sh not found in current directory"
    fi
    
    # Install game manager
    if [ -f "./umu-game-manager.sh" ]; then
        log "Installing umu-game-manager..."
        cp "./umu-game-manager.sh" "$INSTALL_DIR/umu-game-manager"
        chmod +x "$INSTALL_DIR/umu-game-manager"
        success "Installed umu-game-manager"
    else
        warn "umu-game-manager.sh not found in current directory"
    fi
    
    # Install default configuration
    mkdir -p "$CONFIG_DIR"
    if [ -f "./umu-installer.conf" ]; then
        if [ ! -f "$CONFIG_DIR/config" ]; then
            log "Installing default configuration..."
            cp "./umu-installer.conf" "$CONFIG_DIR/config"
            success "Installed default configuration to $CONFIG_DIR/config"
        else
            log "Configuration already exists, skipping default configuration install"
        fi
    else
        warn "umu-installer.conf not found in current directory"
    fi
    
    # Create GUI wrapper script
    log "Creating GUI wrapper..."
    cat > "$INSTALL_DIR/umu-game-installer-gui" << 'EOFGUI'
#!/bin/bash
# GUI wrapper for umu-game-installer
# This script runs the main installer in GUI mode

INSTALLER_FILE="$1"

# Detect which dialog tool to use for initial wrapper errors
if command -v kdialog &> /dev/null; then
    DIALOG_TOOL="kdialog"
elif command -v zenity &> /dev/null; then
    DIALOG_TOOL="zenity"
else
    DIALOG_TOOL="none"
fi

show_error() {
    case "$DIALOG_TOOL" in
        kdialog)
            kdialog --title "UMU Game Installer" --error "$1" 2>/dev/null
            ;;
        zenity)
            zenity --error --title="UMU Game Installer" --text="$1" --width=300 2>/dev/null
            ;;
        *)
            echo "Error: $1" >&2
            ;;
    esac
}

# Validate input
if [ -z "$INSTALLER_FILE" ]; then
    show_error "No installer file specified"
    exit 1
fi

if [ ! -f "$INSTALLER_FILE" ]; then
    show_error "File not found: $INSTALLER_FILE"
    exit 1
fi

# Ensure PATH includes ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Run the installer with GUI flag
exec umu-game-installer --gui "$INSTALLER_FILE"
EOFGUI
    
    chmod +x "$INSTALL_DIR/umu-game-installer-gui"
    success "Created GUI wrapper (KDE/GNOME compatible)"
}

setup_file_associations() {
    header "Setting Up File Associations"
    
    mkdir -p "$DESKTOP_DIR" "$MIME_DIR"
    
    # Create .desktop file for the installer
    log "Creating application launcher..."
    cat > "$DESKTOP_DIR/umu-game-installer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Install Windows Game
GenericName=Windows Game Installer
Comment=Install Windows games on Steam Deck/Linux
Exec=umu-game-installer-gui %f
Icon=system-software-install
Terminal=false
Categories=Game;System;PackageManager;
MimeType=application/x-wine-extension-msi;application/x-ms-dos-executable;application/x-msdownload;application/x-exe;application/x-winexe;
Keywords=game;install;windows;wine;proton;
StartupNotify=true
EOF
    
    success "Created application launcher"
    
    # Register MIME types
    log "Registering file types..."
    cat > "$MIME_DIR/umu-game-installer.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="application/x-ms-dos-executable">
        <comment>Windows Executable</comment>
        <glob pattern="*.exe"/>
        <icon name="application-x-executable"/>
    </mime-type>
    <mime-type type="application/x-wine-extension-msi">
        <comment>Windows Installer Package</comment>
        <glob pattern="*.msi"/>
        <icon name="application-x-executable"/>
    </mime-type>
</mime-info>
EOF
    
    success "Registered file types"
    
    # Update MIME database
    log "Updating MIME database..."
    if command -v update-mime-database &> /dev/null; then
        update-mime-database "$SHARE_DIR/mime" 2>/dev/null || true
    fi
    
    # Update desktop database
    log "Updating desktop database..."
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    fi
    
    success "File associations configured"
}

setup_context_menu() {
    header "Setting Up Context Menu Integration"
    
    # Detect KDE version
    local kde_version=""
    if command -v plasmashell &> /dev/null; then
        kde_version=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9]+' || echo "")
    fi
    
    # KDE Plasma 6.x uses new path
    if [ -n "$kde_version" ] && [ "$kde_version" -ge 6 ]; then
        log "Detected KDE Plasma $kde_version.x - using KDE 6 paths"
        mkdir -p "$FILE_MANAGER_DIR_KDE6"
        
        cat > "$FILE_MANAGER_DIR_KDE6/umu-install-game.desktop" << 'EOF'
[Desktop Entry]
Type=Service
MimeType=application/x-ms-dos-executable;application/x-wine-extension-msi;application/x-msdownload;application/x-exe;application/x-winexe;
Actions=install-game
X-KDE-Priority=TopLevel

[Desktop Action install-game]
Name=Install Windows Game
Icon=system-software-install
Exec=umu-game-installer-gui %f
EOF
        success "KDE Plasma 6 Dolphin context menu installed ✓"
    else
        # KDE Plasma 5.x uses legacy path
        log "Using KDE Plasma 5 paths (or KDE 6 fallback)"
        mkdir -p "$FILE_MANAGER_DIR_KDE5"
        
        cat > "$FILE_MANAGER_DIR_KDE5/umu-install-game.desktop" << 'EOF'
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-ms-dos-executable;application/x-wine-extension-msi;application/x-msdownload;application/x-exe;application/x-winexe;
Actions=install-game
X-KDE-Priority=TopLevel
X-KDE-Submenu=

[Desktop Action install-game]
Name=Install Windows Game
Icon=system-software-install
Exec=umu-game-installer-gui %f
EOF
        success "KDE Plasma 5 Dolphin context menu installed ✓"
        
        # Also install to KDE 6 location for forward compatibility
        mkdir -p "$FILE_MANAGER_DIR_KDE6"
        cp "$FILE_MANAGER_DIR_KDE5/umu-install-game.desktop" "$FILE_MANAGER_DIR_KDE6/"
        success "Forward compatibility: Installed to KDE 6 path as well"
    fi
    
    # Nautilus (GNOME) context menu - Optional for multi-desktop support
    if command -v nautilus &> /dev/null || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
        log "Setting up GNOME Nautilus scripts..."
        mkdir -p "$HOME/.local/share/nautilus/scripts"
        
        cat > "$HOME/.local/share/nautilus/scripts/Install Windows Game" << 'EOF'
#!/bin/bash
for file in "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"; do
    umu-game-installer-gui "$file"
done
EOF
        
        chmod +x "$HOME/.local/share/nautilus/scripts/Install Windows Game"
        success "Nautilus script installed"
    fi
    
    # Nemo (Cinnamon) context menu - Optional
    if command -v nemo &> /dev/null || [ "$XDG_CURRENT_DESKTOP" = "Cinnamon" ]; then
        log "Setting up Cinnamon Nemo actions..."
        mkdir -p "$HOME/.local/share/nemo/actions"
        
        cat > "$HOME/.local/share/nemo/actions/umu-install-game.nemo_action" << 'EOF'
[Nemo Action]
Name=Install Windows Game
Comment=Install this Windows game
Exec=umu-game-installer-gui %F
Icon-Name=system-software-install
Selection=s
Extensions=exe;msi;
EOF
        
        success "Nemo action installed"
    fi
    
    log "Context menu integration complete (KDE Dolphin - Plasma 5/6 compatible)"
}

setup_default_application() {
    header "Setting Default Application"
    
    log "Making UMU installer the default for .exe files..."
    
    # Set as default using xdg-mime
    if command -v xdg-mime &> /dev/null; then
        xdg-mime default umu-game-installer.desktop application/x-ms-dos-executable 2>/dev/null || true
        xdg-mime default umu-game-installer.desktop application/x-wine-extension-msi 2>/dev/null || true
        success "Set as default application"
    fi
}

create_desktop_launchers() {
    header "Creating Desktop Shortcuts"
    
    local desktop_dir="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
    mkdir -p "$desktop_dir"
    
    # Create game manager desktop shortcut (KDE-compatible)
    log "Creating game manager shortcut..."
    cat > "$desktop_dir/Game Manager.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Game Manager
Comment=Manage installed Windows games
Exec=konsole -e umu-game-manager list
Icon=applications-games
Terminal=false
Categories=Game;
X-KDE-SubstituteUID=false
EOF
    
    chmod +x "$desktop_dir/Game Manager.desktop"
    
    # Mark as trusted on KDE (Steam Deck)
    if command -v kwriteconfig5 &> /dev/null; then
        gio set "$desktop_dir/Game Manager.desktop" "metadata::trusted" "true" 2>/dev/null || true
    fi
    
    success "Game manager shortcut created (KDE/Steam Deck compatible)"
    
    echo ""
    log "Desktop shortcuts created in: $desktop_dir"
}

setup_steam_deck_gamemode() {
    header "Steam Deck Game Mode Integration"
    
    if [ -f "/etc/os-release" ] && grep -q "steamdeck" /etc/os-release 2>/dev/null; then
        log "Steam Deck detected - configuring Game Mode integration..."
        
        # Non-Steam games added via .desktop files will appear in Steam
        success "Game Mode integration enabled (games will appear in library)"
    else
        log "Not running on Steam Deck, skipping Game Mode setup"
    fi
}

test_installation() {
    header "Testing Installation"
    
    log "Verifying installation..."
    
    local errors=0
    
    # Check executables
    for cmd in umu-game-installer umu-game-manager umu-game-installer-gui; do
        if [ -x "$INSTALL_DIR/$cmd" ]; then
            success "$cmd installed"
        else
            warn "$cmd not found or not executable"
            ((errors++))
        fi
    done
    
    # Check .desktop file
    if [ -f "$DESKTOP_DIR/umu-game-installer.desktop" ]; then
        success "Desktop integration installed"
    else
        warn "Desktop integration not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        success "All components installed successfully!"
        return 0
    else
        warn "Installation completed with $errors warnings"
        return 1
    fi
}

show_completion_message() {
    header "Installation Complete!"
    
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║               🎉 SETUP COMPLETE! 🎉                          ║
║                                                              ║
║  Windows game installers now work by double-clicking!       ║
║  (Optimized for Steam Deck / KDE Plasma)                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    echo -e "${CYAN}How to use:${NC}\n"
    echo "  1. Download any Windows game installer (.exe file)"
    echo "  2. Double-click the .exe file in Dolphin (file manager)"
    echo "  3. Enter the game name when prompted"
    echo "  4. The Windows installer appears - use it normally!"
    echo "  5. Done! Game appears in Steam and on desktop"
    echo ""
    
    echo -e "${CYAN}Alternative methods:${NC}\n"
    echo "  • Right-click any .exe → 'Install Windows Game'"
    echo "  • Drag .exe to 'Install Windows Game' icon"
    echo ""
    
    echo -e "${CYAN}Manage your games:${NC}\n"
    echo "  • Double-click 'Game Manager' on desktop"
    echo "  • Or run: umu-game-manager list"
    echo ""
    
    echo -e "${CYAN}Example game sources:${NC}\n"
    echo "  • GOG.com - DRM-free installers (recommended)"
    echo "  • Humble Bundle - Windows installers"
    echo "  • itch.io - Independent games"
    echo ""
    
    echo -e "${GREEN}${BOLD}No command line needed anymore!${NC}"
    echo -e "Just double-click .exe files like on Windows! 🎮\n"
    
    echo -e "${CYAN}Steam Deck Users:${NC}"
    echo "  • This works best in Desktop Mode"
    echo "  • Installed games appear in Gaming Mode automatically"
    echo "  • KDE Dolphin file manager is fully integrated"
    echo ""
}

# Show final GUI notification
show_final_notification() {
    # Show in GUI if available (prefer kdialog on Steam Deck)
    if command -v kdialog &> /dev/null; then
        kdialog --title "Installation Complete" \
                --msgbox "Windows game installers now work by double-clicking!\n\nJust double-click any .exe installer file in Dolphin and it will work like Windows.\n\nOptimized for Steam Deck / KDE Plasma." 2>/dev/null &
    elif command -v zenity &> /dev/null; then
        zenity --info --title="Installation Complete" \
               --text="Windows game installers now work by double-clicking!\n\nJust double-click any .exe installer file and it will work like Windows." \
               --width=400 2>/dev/null &
    fi
}

create_uninstaller() {
    header "Creating Uninstaller"
    
    log "Creating uninstall script..."
    
    cat > "$INSTALL_DIR/umu-uninstall" << 'EOFUNINSTALL'
#!/bin/bash
# Uninstall UMU Game Installer system

echo "Uninstalling UMU Game Installer..."

# Remove executables
rm -f ~/.local/bin/umu-game-installer
rm -f ~/.local/bin/umu-game-manager
rm -f ~/.local/bin/umu-game-installer-gui
rm -f ~/.local/bin/umu-uninstall

# Remove desktop integration
rm -f ~/.local/share/applications/umu-game-installer.desktop
rm -f ~/.local/share/mime/packages/umu-game-installer.xml

# Remove context menus (both KDE 5 and KDE 6 paths)
rm -f ~/.local/share/kservices5/ServiceMenus/umu-install-game.desktop
rm -f ~/.local/share/kio/servicemenus/umu-install-game.desktop
rm -f ~/.local/share/nautilus/scripts/"Install Windows Game"
rm -f ~/.local/share/nemo/actions/umu-install-game.nemo_action

# Remove desktop shortcuts
rm -f ~/Desktop/"Game Manager.desktop"

# Update databases
update-mime-database ~/.local/share/mime 2>/dev/null || true
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Refresh KDE services (works for both KDE 5 and 6)
if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 2>/dev/null || true
elif command -v kbuildsycoca5 &> /dev/null; then
    kbuildsycoca5 --noincremental 2>/dev/null || true
fi

echo "Uninstalled successfully!"
echo ""
echo "Note: Your installed games and configuration are still in:"
echo "  • ~/Games/"
echo "  • ~/.config/umu-game-installer/"
echo ""
echo "Remove them manually if desired."
EOFUNINSTALL
    
    chmod +x "$INSTALL_DIR/umu-uninstall"
    success "Uninstaller created: umu-uninstall"
}

main() {
    show_banner
    
    echo "This will set up your system so Windows game installers"
    echo "work by simply double-clicking them - no command line needed!"
    echo ""
    read -p "Continue with installation? (Y/n): " confirm
    
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo ""
    
    # Run installation steps
    check_dependencies
    install_core_scripts
    setup_file_associations
    setup_context_menu
    setup_default_application
    create_desktop_launchers
    setup_steam_deck_gamemode
    create_uninstaller
    test_installation
    
    echo ""
    show_completion_message
    show_final_notification
}

main "$@"
