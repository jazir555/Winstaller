#!/bin/bash

#############################################################################
# UMU Game Installer - Verification Script
#############################################################################
# Run this after installation to verify everything works correctly
#############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $*"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $*"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $*"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ INFO${NC}: $*"
}

header() {
    echo ""
    echo -e "${CYAN}${BOLD}═══ $* ═══${NC}"
    echo ""
}

echo -e "${CYAN}${BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         UMU GAME INSTALLER - VERIFICATION SCRIPT            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

header "1. Checking Prerequisites"

# Check umu-run
if command -v umu-run &> /dev/null; then
    pass "umu-run is installed"
    info "Version: $(umu-run --version 2>&1 || echo 'Unknown')"
else
    fail "umu-run is NOT installed"
    info "Install with: pip install --user umu-launcher"
fi

# Check dialog tools
if command -v kdialog &> /dev/null; then
    pass "kdialog is installed (KDE dialogs)"
elif command -v zenity &> /dev/null; then
    pass "zenity is installed (GNOME dialogs)"
else
    warn "No GUI dialog tool found (kdialog or zenity)"
    info "Install with: sudo pacman -S kdialog"
fi

# Check bash
if command -v bash &> /dev/null; then
    pass "bash is installed"
else
    fail "bash is NOT installed"
fi

# Check python3
if command -v python3 &> /dev/null; then
    pass "python3 is installed"
    info "Version: $(python3 --version 2>&1)"
else
    fail "python3 is NOT installed"
    info "Install with: sudo pacman -S python"
fi

header "2. Checking Installed Scripts"

# Check main installer
if [ -f "$HOME/.local/bin/umu-game-installer" ] && [ -x "$HOME/.local/bin/umu-game-installer" ]; then
    pass "umu-game-installer is installed and executable"
else
    fail "umu-game-installer not found or not executable"
    info "Location: $HOME/.local/bin/umu-game-installer"
fi

# Check game manager
if [ -f "$HOME/.local/bin/umu-game-manager" ] && [ -x "$HOME/.local/bin/umu-game-manager" ]; then
    pass "umu-game-manager is installed and executable"
else
    fail "umu-game-manager not found or not executable"
    info "Location: $HOME/.local/bin/umu-game-manager"
fi

# Check GUI wrapper
if [ -f "$HOME/.local/bin/umu-game-installer-gui" ] && [ -x "$HOME/.local/bin/umu-game-installer-gui" ]; then
    pass "umu-game-installer-gui is installed and executable"
else
    warn "umu-game-installer-gui not found (GUI mode not installed)"
    info "Run: ./umu-system-installer.sh"
fi

header "3. Checking Configuration Directories"

# Check config dir
if [ -d "$HOME/.config/umu-game-installer" ]; then
    pass "Configuration directory exists"
else
    fail "Configuration directory not found"
    info "Location: $HOME/.config/umu-game-installer"
fi

# Check configuration file
if [ -f "$HOME/.config/umu-game-installer/config" ]; then
    pass "Configuration file exists"
else
    warn "Configuration file not found (will be created on system install)"
    info "Location: $HOME/.config/umu-game-installer/config"
fi

# Check databases
if [ -f "$HOME/.config/umu-game-installer/deps.db" ]; then
    pass "Dependency database exists"
else
    warn "Dependency database not found (will be created on first run)"
fi

if [ -f "$HOME/.config/umu-game-installer/games.db" ]; then
    pass "Games database exists"
else
    warn "Games database not found (will be created on first run)"
fi

# Check install root
if [ -d "$HOME/Games" ]; then
    pass "Default install root exists"
else
    warn "Default install root not found (will be created when installing games)"
    info "Location: $HOME/Games"
fi

header "4. Checking Desktop Integration"

# Check .desktop launcher
if [ -f "$HOME/.local/share/applications/umu-game-installer.desktop" ]; then
    pass "Application launcher (.desktop file) exists"
else
    warn "Application launcher not found (GUI mode not fully installed)"
fi

# Check MIME types
if [ -f "$HOME/.local/share/mime/packages/umu-game-installer.xml" ]; then
    pass "MIME type registration exists"
else
    warn "MIME types not registered (GUI mode not fully installed)"
fi

# Check KDE context menu
KDE_VERSION=""
if command -v plasmashell &> /dev/null; then
    KDE_VERSION=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9]+' || echo "")
fi

if [ -n "$KDE_VERSION" ] && [ "$KDE_VERSION" -ge 6 ]; then
    # KDE 6
    if [ -f "$HOME/.local/share/kio/servicemenus/umu-install-game.desktop" ]; then
        pass "KDE Plasma 6 Dolphin context menu installed"
    else
        warn "KDE Plasma 6 context menu not found"
    fi
else
    # KDE 5 or unknown
    if [ -f "$HOME/.local/share/kservices5/ServiceMenus/umu-install-game.desktop" ]; then
        pass "KDE Plasma 5 Dolphin context menu installed"
    else
        warn "KDE context menu not found (GUI mode not installed or not using KDE)"
    fi
fi

header "5. Checking File Associations"

# Check .exe association
if command -v xdg-mime &> /dev/null; then
    EXE_HANDLER=$(xdg-mime query default application/x-ms-dos-executable 2>/dev/null || echo "none")
    if [ "$EXE_HANDLER" = "umu-game-installer.desktop" ]; then
        pass ".exe files associated with UMU installer"
    else
        warn ".exe files not associated with UMU installer"
        info "Current handler: $EXE_HANDLER"
        info "Run: xdg-mime default umu-game-installer.desktop application/x-ms-dos-executable"
    fi
fi

header "6. Testing Commands"

# Test help command
if "$HOME/.local/bin/umu-game-installer" --help &> /dev/null; then
    pass "umu-game-installer --help works"
else
    fail "umu-game-installer --help failed"
fi

# Test version command
if "$HOME/.local/bin/umu-game-installer" --version &> /dev/null; then
    pass "umu-game-installer --version works"
else
    fail "umu-game-installer --version failed"
fi

# Test game manager
if "$HOME/.local/bin/umu-game-manager" --help &> /dev/null; then
    pass "umu-game-manager --help works"
else
    fail "umu-game-manager --help failed"
fi

header "7. Checking Installed Games"

GAME_COUNT=$(grep -v '^#' "$HOME/.config/umu-game-installer/games.db" 2>/dev/null | grep -c '^' || echo "0")
if [ "$GAME_COUNT" -gt 0 ]; then
    pass "$GAME_COUNT game(s) installed"
    info "Run 'umu-game-manager list' to see them"
else
    info "No games installed yet"
    info "Install a game with: umu-game-installer game-setup.exe"
fi

header "8. Checking Dependencies"

DEP_COUNT=$(grep -v '^#' "$HOME/.config/umu-game-installer/deps.db" 2>/dev/null | grep -c '^' || echo "0")
if [ "$DEP_COUNT" -gt 0 ]; then
    pass "$DEP_COUNT dependenc(ies) installed"
    info "Run 'umu-game-installer --list-deps' to see them"
else
    info "No dependencies installed yet"
fi

header "9. System Information"

info "Operating System: $(uname -s)"
info "Kernel: $(uname -r)"
info "Architecture: $(uname -m)"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    info "Distribution: $NAME ${VERSION:-}"
fi

if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
    info "Desktop Environment: $XDG_CURRENT_DESKTOP"
    
    # Detect KDE version
    if command -v plasmashell &> /dev/null; then
        PLASMA_VERSION=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9.]+' || echo "Unknown")
        info "KDE Plasma Version: $PLASMA_VERSION"
    fi
fi

if command -v dolphin &> /dev/null; then
    info "File Manager: Dolphin (KDE) detected"
elif command -v nautilus &> /dev/null; then
    info "File Manager: Nautilus (GNOME) detected"
fi

header "VERIFICATION RESULTS"

echo ""
echo -e "${GREEN}Passed:  $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed:  $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ System is ready to use!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Download a Windows game installer (.exe)"
    echo "  2. Double-click it (GUI mode) or run:"
    echo "     umu-game-installer game-setup.exe"
    echo ""
else
    echo -e "${RED}${BOLD}✗ Some checks failed${NC}"
    echo ""
    echo "Please fix the failed checks above before using the system."
    echo ""
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Note: Warnings are not critical but may affect some features.${NC}"
    echo ""
fi

exit $FAILED
