# Installation Guide

## Quick Start

### 1. Install Prerequisites

#### Install umu-run

On SteamOS/Steam Deck:
```bash
# Add Flathub (if not already added)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install umu-launcher
# Note: As of 2024, check the official repo for latest installation method
# https://github.com/Open-Wine-Components/umu-launcher

# Using pip (if available)
pip install --user umu-launcher

# Or download release binary
curl -L https://github.com/Open-Wine-Components/umu-launcher/releases/latest/download/umu-run -o ~/.local/bin/umu-run
chmod +x ~/.local/bin/umu-run
```

#### Verify Installation

```bash
which umu-run
umu-run --version
```

### 2. Install UMU Game Installer

```bash
# Download the scripts
curl -O https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-installer.sh
curl -O https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-manager.sh

# Make executable
chmod +x umu-game-installer.sh umu-game-manager.sh

# Move to PATH (optional)
mkdir -p ~/.local/bin
mv umu-game-installer.sh ~/.local/bin/umu-game-installer
mv umu-game-manager.sh ~/.local/bin/umu-game-manager

# Add to PATH if not already
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3. First Time Setup

```bash
# Run installer once to create directories
umu-game-installer --help

# This creates:
# ~/.config/umu-game-installer/
# ~/Games/
```

### 4. Install Your First Game

```bash
# Navigate to where your installer is
cd ~/Downloads

# Run the installer
umu-game-installer game-setup.exe

# Follow the prompts:
# - Enter game name
# - Confirm dependencies
# - Use the GUI installer (choose install path)
# - Confirm detected executable
```

## Installation Options

### System-Wide Installation (requires sudo)

```bash
sudo cp umu-game-installer.sh /usr/local/bin/umu-game-installer
sudo cp umu-game-manager.sh /usr/local/bin/umu-game-manager
sudo chmod +x /usr/local/bin/umu-game-installer
sudo chmod +x /usr/local/bin/umu-game-manager
```

### Custom Install Location

```bash
# Install to custom directory
mkdir -p /mnt/sdcard/Games

# Use --install-root flag
umu-game-installer --install-root /mnt/sdcard/Games game-setup.exe

# Or set as default in config
echo 'INSTALL_ROOT="/mnt/sdcard/Games"' > ~/.config/umu-game-installer/config
```

## Post-Installation

### Add to Application Menu

Create a launcher for the installer itself:

```bash
cat > ~/.local/share/applications/umu-game-installer.desktop << 'EOF'
[Desktop Entry]
Name=UMU Game Installer
Comment=Install Windows games on Steam Deck
Exec=konsole -e umu-game-installer %f
Type=Application
Categories=Utility;System;
Icon=system-software-install
Terminal=false
MimeType=application/x-ms-dos-executable;application/x-wine-extension-msp;
EOF
```

Now you can right-click any .exe file and select "Open With → UMU Game Installer"!

### Shell Completion (Bash)

```bash
cat > ~/.local/share/bash-completion/completions/umu-game-installer << 'EOF'
_umu_game_installer() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --list-deps --clean-deps --install-root"
    
    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
    
    case "${prev}" in
        --install-root)
            COMPREPLY=( $(compgen -d -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -f -X '!*.exe' -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _umu_game_installer umu-game-installer
EOF

# Reload bash completion
source ~/.bashrc
```

### Desktop Mode Integration

For Steam Deck Desktop Mode:

```bash
# Install Dolphin service menu (right-click context menu)
mkdir -p ~/.local/share/kservices5/ServiceMenus

cat > ~/.local/share/kservices5/ServiceMenus/umu-install.desktop << 'EOF'
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-ms-dos-executable;
Actions=install-umu
X-KDE-Priority=TopLevel

[Desktop Action install-umu]
Name=Install with UMU
Icon=system-software-install
Exec=konsole --hold -e umu-game-installer %f
EOF
```

Now you can right-click any .exe in Dolphin and select "Install with UMU"!

## Verification

### Test the Installation

```bash
# Check commands are available
umu-game-installer --version
umu-game-manager --help

# Verify directories created
ls -la ~/.config/umu-game-installer/
ls -la ~/Games/

# Check umu-run integration
umu-run --version
```

### Test with Sample Game

If you have a small portable game:

```bash
# Example with a GOG installer
umu-game-installer ~/Downloads/setup_game.exe
```

## Troubleshooting

### umu-run not found

```bash
# Check if in PATH
echo $PATH

# Find umu-run
find ~ -name "umu-run" 2>/dev/null

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Permission Denied

```bash
# Make sure scripts are executable
chmod +x umu-game-installer.sh umu-game-manager.sh

# Check file permissions
ls -l umu-game-installer.sh
```

### Dependencies Not Working

```bash
# Check dependency database
cat ~/.config/umu-game-installer/deps.db

# List installed dependencies
umu-game-manager deps

# Manually register a dependency
# Edit ~/.config/umu-game-installer/deps.db
```

### Steam Not Detecting Games

```bash
# Check .desktop files
ls -la ~/.local/share/applications/umu-*.desktop

# Update desktop database
update-desktop-database ~/.local/share/applications/

# Restart Steam
killall steam
steam &
```

## Advanced Setup

### Multiple Installation Roots

Create profiles for different storage locations:

```bash
# SD Card profile
echo 'INSTALL_ROOT="/run/media/mmcblk0p1/Games"' > ~/.config/umu-game-installer/profile-sdcard

# SSD profile
echo 'INSTALL_ROOT="/home/deck/Games"' > ~/.config/umu-game-installer/profile-ssd

# Use with:
source ~/.config/umu-game-installer/profile-sdcard
umu-game-installer game.exe
```

### Automated Dependency Installation

Pre-install common dependencies:

```bash
# Download common redistributables
cd ~/Downloads

# VC++ Redist 2022
curl -L https://aka.ms/vs/17/release/vc_redist.x64.exe -o vcredist2022.exe

# VC++ Redist 2019
curl -L https://aka.ms/vs/16/release/vc_redist.x64.exe -o vcredist2019.exe

# Install them
umu-game-installer vcredist2022.exe
umu-game-installer vcredist2019.exe

# Now they're cached for future games
umu-game-manager deps
```

### Backup and Restore

```bash
# Backup configuration and databases
tar -czf umu-backup.tar.gz ~/.config/umu-game-installer/

# Backup games (warning: large!)
tar -czf games-backup.tar.gz ~/Games/

# Restore
tar -xzf umu-backup.tar.gz -C ~/
tar -xzf games-backup.tar.gz -C ~/
```

## Uninstallation

To completely remove:

```bash
# Remove installed games
rm -rf ~/Games/

# Remove configuration
rm -rf ~/.config/umu-game-installer/

# Remove scripts
rm ~/.local/bin/umu-game-installer
rm ~/.local/bin/umu-game-manager

# Remove desktop files
rm ~/.local/share/applications/umu-*.desktop
rm ~/Desktop/*.desktop  # Be careful with this one!

# Remove service menus
rm ~/.local/share/kservices5/ServiceMenus/umu-install.desktop

# Optional: Remove umu-run
pip uninstall umu-launcher
# or
rm ~/.local/bin/umu-run
```

## Next Steps

- Read the [README.md](README.md) for usage examples
- Check out [EXAMPLES.md](EXAMPLES.md) for game-specific tips
- Join the community for support

## Getting Help

- GitHub Issues: Report bugs and request features
- Steam Deck Subreddit: r/SteamDeck
- ProtonDB: Check game compatibility
- umu-run Documentation: https://github.com/Open-Wine-Components/umu-launcher
