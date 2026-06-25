# Quick Reference Card

## Installation

```bash
# Download and setup
curl -O https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-installer.sh
chmod +x umu-game-installer.sh
mv umu-game-installer.sh ~/.local/bin/umu-game-installer
```

## Basic Commands

### Install a Game
```bash
umu-game-installer game-setup.exe
umu-game-installer --install-root /mnt/sdcard/Games game-setup.exe
```

### List Games
```bash
umu-game-manager list
```

### Launch a Game
```bash
umu-game-manager launch "Game Name"
```

### Show Game Info
```bash
umu-game-manager info "Game Name"
```

### Uninstall a Game
```bash
umu-game-manager uninstall "Game Name"
```

### List Dependencies
```bash
umu-game-installer --list-deps
umu-game-manager deps
```

### Check Disk Usage
```bash
umu-game-manager disk
```

### Clean Orphaned Files
```bash
umu-game-manager clean
```

## Directory Structure

```
~/.config/umu-game-installer/    # Configuration
  ├── deps.db                    # Dependency database
  ├── games.db                   # Games database
  ├── dependencies/              # Shared dependencies
  └── launch_*.sh                # Launch scripts

~/Games/                         # Games (default)
  └── GameName/
      └── prefix/                # Wine prefix

~/.local/share/applications/     # Steam integration
  └── umu-*.desktop

~/Desktop/                       # Desktop shortcuts
  └── GameName.desktop
```

## Common Patterns

### Install with GUI
```bash
umu-game-installer setup.exe
# Enter game name when prompted
# GUI installer opens → choose location
# Auto-detects executable → confirm
```

### Manual Executable Selection
```bash
umu-game-installer setup.exe
# When prompted for executable:
# n (reject auto-detected)
# /path/to/game.exe (enter manually)
```

### Install to SD Card
```bash
umu-game-installer --install-root /mnt/sdcard/Games setup.exe
```

### Batch Install
```bash
for game in ~/Downloads/*.exe; do
  umu-game-installer "$game"
done
```

## Dependency Management

### Pre-install Common Dependencies
```bash
# VC++ 2022
umu-game-installer vcredist_x64_2022.exe

# VC++ 2019
umu-game-installer vcredist_x64_2019.exe

# DirectX
umu-game-installer dxwebsetup.exe

# .NET 4.8
umu-game-installer ndp48-web.exe
```

### Check What's Installed
```bash
umu-game-manager deps
```

### Manually Link Dependencies
```bash
# After installing to same prefix
WINEPREFIX=~/Games/GameName/prefix GAMEID=umu-gamename \
  umu-run dependency-installer.exe
```

## Troubleshooting

### Game Won't Launch
```bash
# Test manually
cd ~/Games/GameName/prefix
WINEPREFIX=$(pwd) GAMEID=umu-gamename umu-run drive_c/path/to/game.exe

# Check logs
journalctl --user -xe | grep umu
```

### Wrong Executable Detected
```bash
# Get game info
umu-game-manager info "Game Name"

# Edit launch script
nano ~/.config/umu-game-installer/launch_umu-game-name.sh

# Change the game.exe path
```

### Missing Dependencies
```bash
# Check what's installed
umu-game-manager deps

# Install manually
umu-game-installer vcredist.exe

# Or use winetricks
WINEPREFIX=~/Games/GameName/prefix winetricks vcrun2019
```

### Performance Issues
```bash
# Edit launch script
nano ~/.config/umu-game-installer/launch_umu-game.sh

# Add performance flags:
export DXVK_ASYNC=1
export WINE_FULLSCREEN_FSR=1
export WINE_CPU_TOPOLOGY=8:8
```

## Launch Script Template

```bash
#!/bin/bash
export WINEPREFIX="/home/deck/Games/GameName/prefix"
export GAMEID="umu-gamename"

# Optional performance tweaks:
# export DXVK_HUD=fps
# export DXVK_ASYNC=1
# export WINE_FULLSCREEN_FSR=1

exec umu-run "/path/to/game.exe" "$@"
```

## Environment Variables

```bash
# Show FPS
export DXVK_HUD=fps

# Async shader compilation
export DXVK_ASYNC=1

# FSR upscaling
export WINE_FULLSCREEN_FSR=1

# CPU topology (8 cores, 8 threads)
export WINE_CPU_TOPOLOGY=8:8

# Disable Esync
export PROTON_NO_ESYNC=1

# Disable Fsync
export PROTON_NO_FSYNC=1

# Debug mode
export WINE_DEBUG=+all
```

## File Locations

```bash
# Main installer script
~/.local/bin/umu-game-installer

# Game manager
~/.local/bin/umu-game-manager

# Configuration
~/.config/umu-game-installer/

# Game databases
~/.config/umu-game-installer/*.db

# Launch scripts
~/.config/umu-game-installer/launch_*.sh

# Games
~/Games/

# Steam shortcuts
~/.local/share/applications/umu-*.desktop

# Desktop shortcuts
~/Desktop/*.desktop
```

## Steam Integration

### Manual Steam Shortcut
```bash
cat > ~/.local/share/applications/umu-mygame.desktop << 'EOF'
[Desktop Entry]
Name=My Game
Exec=/home/deck/.config/umu-game-installer/launch_umu-mygame.sh
Type=Application
Categories=Game;
Icon=application-x-executable
EOF
```

### Refresh Steam Library
```bash
update-desktop-database ~/.local/share/applications/
killall steam
steam &
```

## Backup & Restore

### Backup Configuration
```bash
tar -czf umu-backup.tar.gz ~/.config/umu-game-installer/
```

### Backup Game
```bash
tar -czf game-backup.tar.gz ~/Games/GameName/
```

### Restore
```bash
tar -xzf umu-backup.tar.gz -C ~/
tar -xzf game-backup.tar.gz -C ~/
```

## Useful Aliases

Add to `~/.bashrc`:
```bash
alias games='umu-game-manager list'
alias game-install='umu-game-installer'
alias game-info='umu-game-manager info'
alias game-launch='umu-game-manager launch'
alias game-remove='umu-game-manager uninstall'
```

## Quick Diagnostics

```bash
# System check
umu-run --version
echo $XDG_CONFIG_HOME
echo $HOME

# Installation check
ls -la ~/.config/umu-game-installer/
ls -la ~/Games/

# Database check
cat ~/.config/umu-game-installer/games.db
cat ~/.config/umu-game-installer/deps.db

# Game count
umu-game-manager list | grep -c "^umu-"

# Disk usage
du -sh ~/Games/
du -sh ~/.config/umu-game-installer/
```

## Get Help

```bash
# Installer help
umu-game-installer --help

# Manager help
umu-game-manager --help

# Version info
umu-game-installer --version

# Online docs
# https://github.com/yourusername/umu-game-installer
```

## Common Game Types

| Game Source | Installation Method |
|-------------|-------------------|
| GOG | `umu-game-installer setup_*.exe` |
| Epic Games | Install Epic Launcher first |
| Humble Bundle | `umu-game-installer game-installer.exe` |
| itch.io | Extract zip, then install or manual |
| Steam Backup | Use Steam's restore feature |
| Old Games | May need compatibility flags |

## Emergency Recovery

```bash
# Clean everything
rm -rf ~/Games/
rm -rf ~/.config/umu-game-installer/
rm -f ~/.local/share/applications/umu-*.desktop

# Fresh start
umu-game-installer --help

# Restore from backup
tar -xzf umu-backup.tar.gz -C ~/
```

---

**Print this page for quick reference!** 📄
