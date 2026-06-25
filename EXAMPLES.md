# Usage Examples

This document provides real-world examples of using the UMU Game Installer with various game types and scenarios.

## Table of Contents
- [GOG Games](#gog-games)
- [Epic Games Store](#epic-games-store)
- [Steam Games (Backup)](#steam-games-backup)
- [Humble Bundle](#humble-bundle)
- [Indie Games](#indie-games)
- [Old Games](#old-games)
- [Game with Mods](#games-with-mods)
- [Multiple Discs](#multiple-discs)

---

## GOG Games

### Example: The Witcher 3 (GOG)

```bash
# Download from GOG website
# File: setup_the_witcher_3_wild_hunt_2.6.0.56.exe

# Install
umu-game-installer ~/Downloads/setup_the_witcher_3_wild_hunt_2.6.0.56.exe

# Prompts:
# Enter game name: The Witcher 3
# Detected dependencies: vcredist:2015, directx:9
# Install dependencies? (Y/n): y

# The GOG installer GUI opens
# - Accept license
# - Choose language
# - Select install path (e.g., /home/deck/Games/TheWitcher3)
# - Select components (Full Installation)
# - Click Install

# After installation:
# Detected game executable: .../witcher3.exe
# Use this executable? (Y/n): y

# ✓ Game installed successfully
# ✓ Added to Steam
# ✓ Desktop shortcut created
```

### Launching

```bash
# From desktop
# Double-click "The Witcher 3" icon

# From terminal
umu-game-manager launch "The Witcher 3"

# From Steam
# Open Steam → Library → The Witcher 3
```

---

## Epic Games Store

### Example: Installing Epic Games Launcher First

Epic Games requires their launcher to be installed first.

```bash
# Download Epic Games Launcher installer
# File: EpicInstaller.msi or EpicGamesLauncherInstaller.exe

# Install the launcher
umu-game-installer ~/Downloads/EpicGamesLauncherInstaller.exe

# Enter game name: Epic Games Launcher
# Run through installation

# Once installed, you can launch the Epic launcher
umu-game-manager launch "Epic Games Launcher"

# Sign in and download games through the launcher
# Then install them normally
```

### Example: Standalone Epic Game

Some Epic games come as standalone installers:

```bash
umu-game-installer ~/Downloads/GameInstaller.exe

# Enter game name: My Epic Game
# Follow normal installation process
```

---

## Steam Games (Backup)

### Example: Restoring Steam Backup

If you have a Steam backup of a Windows game:

```bash
# Extract the backup first
# Steam backups are usually in .csd format

# Then run the setup from the backup
umu-game-installer ~/SteamBackups/GameName/Setup.exe

# Or use Steam's built-in restore feature
# Steam → Settings → Downloads → Steam Library Folders
# Then add the game through Steam normally
```

---

## Humble Bundle

### Example: DRM-Free Humble Game

```bash
# Download installer from Humble Bundle library
# File: game-name-windows-installer.exe

umu-game-installer ~/Downloads/game-name-windows-installer.exe

# Enter game name: Game Name
# Follow installation prompts

# Many Humble games are DRM-free and work perfectly
```

---

## Indie Games

### Example: itch.io Game

```bash
# Download Windows version from itch.io
# File: game_windows.zip

# Extract first
unzip ~/Downloads/game_windows.zip -d ~/Downloads/game_windows/

# If there's an installer:
umu-game-installer ~/Downloads/game_windows/setup.exe

# If it's portable (no installer):
# You can create a manual entry
mkdir -p ~/Games/GameName
cp -r ~/Downloads/game_windows/* ~/Games/GameName/

# Then manually add to Steam/desktop using umu-game-manager
```

### Example: Portable Game (No Installer)

For games that don't have an installer:

```bash
# Create game directory
mkdir -p ~/Games/PortableGame

# Copy game files
cp -r ~/Downloads/game/* ~/Games/PortableGame/

# Create manual entry in database
echo "umu-portablegame|Portable Game|$HOME/Games/PortableGame|$HOME/Games/PortableGame/game.exe|$(date +%Y-%m-%d)" >> ~/.config/umu-game-installer/games.db

# Create launch script manually
cat > ~/.config/umu-game-installer/launch_umu-portablegame.sh << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/Games/PortableGame/prefix"
export GAMEID="umu-portablegame"
exec umu-run "$HOME/Games/PortableGame/game.exe" "$@"
EOF

chmod +x ~/.config/umu-game-installer/launch_umu-portablegame.sh

# Create desktop shortcut
cat > ~/.local/share/applications/umu-portablegame.desktop << 'EOF'
[Desktop Entry]
Name=Portable Game
Exec=$HOME/.config/umu-game-installer/launch_umu-portablegame.sh
Type=Application
Categories=Game;
Icon=application-x-executable
EOF

# List to verify
umu-game-manager list
```

---

## Old Games

### Example: Classic Game (1990s-2000s)

```bash
# Many old games need specific settings
# Example: Age of Empires II

umu-game-installer ~/Downloads/AgeOfEmpiresII_Setup.exe

# Enter game name: Age of Empires II

# Old games often work better with specific Wine settings
# After installation, you can tweak the launch script:

nano ~/.config/umu-game-installer/launch_umu-age-of-empires-ii.sh

# Add compatibility flags:
# export WINE_CPU_TOPOLOGY=4:4  # 4 cores
# export WINEDLLOVERRIDES="ddraw=n,b"  # Native DirectDraw
```

### Example: DOSBox Game

For DOS games, you might want to use DOSBox instead:

```bash
# Install DOSBox
flatpak install flathub com.dosbox.DOSBox

# Create game directory
mkdir -p ~/Games/DOSGame

# Copy game files
cp -r ~/Downloads/dos_game/* ~/Games/DOSGame/

# Create DOSBox config
cat > ~/Games/DOSGame/dosbox.conf << 'EOF'
[autoexec]
@echo off
mount c .
c:
game.exe
exit
EOF

# Create launch script
cat > ~/.config/umu-game-installer/launch_dos-game.sh << 'EOF'
#!/bin/bash
cd ~/Games/DOSGame
flatpak run com.dosbox.DOSBox -conf dosbox.conf
EOF

chmod +x ~/.config/umu-game-installer/launch_dos-game.sh
```

---

## Games with Mods

### Example: Skyrim with Mods

```bash
# 1. Install base game first
umu-game-installer ~/Downloads/SkyrimSetup.exe

# Enter game name: Skyrim
# Complete installation

# 2. Install mod managers (optional)
# Download Mod Organizer 2
umu-game-installer ~/Downloads/Mod_Organizer_2.exe

# During MO2 installation:
# - Choose "Portable" installation
# - Install to same prefix as Skyrim
# - Point it to Skyrim directory

# 3. Install SKSE (Skyrim Script Extender)
cd ~/Games/Skyrim/prefix/drive_c/Games/Skyrim
wget https://skse.silverlock.org/beta/skse64_2_02_04.7z
7z x skse64_2_02_04.7z

# 4. Update launch script to use SKSE
nano ~/.config/umu-game-installer/launch_umu-skyrim.sh

# Change the exec line to:
# exec umu-run "$HOME/Games/Skyrim/prefix/drive_c/Games/Skyrim/skse64_loader.exe" "$@"

# 5. Install mods through MO2
umu-game-manager launch "Mod Organizer 2"
```

---

## Multiple Discs

### Example: Multi-Disc Game Installation

```bash
# Some old games come on multiple discs/ISOs

# 1. Mount or extract first disc
mkdir -p ~/Downloads/game_disc1
7z x ~/Downloads/game_disc1.iso -o~/Downloads/game_disc1

# 2. Start installation
umu-game-installer ~/Downloads/game_disc1/setup.exe

# 3. When prompted for disc 2:
# - The installer will ask for next disc
# - Mount/extract second disc
mkdir -p ~/Downloads/game_disc2
7z x ~/Downloads/game_disc2.iso -o~/Downloads/game_disc2

# 4. Point the installer to disc 2 location
# - Browse to ~/Downloads/game_disc2 when prompted
# - Continue installation

# 5. Repeat for additional discs
```

### Example: Using Wine's Virtual Drives

```bash
# Alternative method using Wine drive mounting

# Create mount points in the prefix
WINEPREFIX=~/Games/GameName/prefix winecfg

# In winecfg:
# - Go to "Drives" tab
# - Add drive D: → ~/Downloads/game_disc1
# - Add drive E: → ~/Downloads/game_disc2
# - Apply and close

# Then run installer
umu-game-installer ~/Downloads/game_disc1/setup.exe

# Installer will see D: and E: as disc drives
```

---

## Advanced Examples

### Example: Game with Multiple Executables

Some games have launcher + game executable:

```bash
# Install game
umu-game-installer ~/Downloads/GameSetup.exe

# When asked for executable:
# Select the launcher (e.g., GameLauncher.exe)

# To add additional shortcuts for direct game launch:
cp ~/.config/umu-game-installer/launch_umu-game.sh ~/.config/umu-game-installer/launch_umu-game-direct.sh

# Edit the direct launch script
nano ~/.config/umu-game-installer/launch_umu-game-direct.sh

# Change to point to game.exe instead of launcher.exe

# Create additional desktop shortcut
cat > ~/Desktop/GameDirect.desktop << 'EOF'
[Desktop Entry]
Name=Game (Direct)
Exec=$HOME/.config/umu-game-installer/launch_umu-game-direct.sh
Type=Application
Categories=Game;
Icon=application-x-executable
EOF
```

### Example: Game with DLC

```bash
# 1. Install base game
umu-game-installer ~/Downloads/BaseGame.exe

# 2. Install DLC to same prefix
# Get the game's prefix path
umu-game-manager info "Game Name"
# Note the prefix path, e.g., ~/Games/GameName/prefix

# 3. Install DLC using same prefix
WINEPREFIX=~/Games/GameName/prefix GAMEID=umu-gamename \
    umu-run ~/Downloads/DLC1.exe

# 4. Repeat for additional DLC
WINEPREFIX=~/Games/GameName/prefix GAMEID=umu-gamename \
    umu-run ~/Downloads/DLC2.exe

# Game should now see the DLC
```

### Example: Custom Launch Options

```bash
# Some games need specific launch arguments

# Edit launch script
nano ~/.config/umu-game-installer/launch_umu-game.sh

# Add arguments to the exec line:
# exec umu-run "game.exe" -windowed -w 1920 -h 1080 "$@"

# Or set environment variables:
# export DXVK_HUD=fps
# export WINE_FULLSCREEN_FSR=1
# exec umu-run "game.exe" "$@"
```

---

## Troubleshooting Examples

### Game Won't Launch

```bash
# Test manually
cd ~/Games/GameName/prefix
WINEPREFIX=$(pwd) GAMEID=umu-gamename umu-run drive_c/Games/Game/game.exe

# Check logs
journalctl --user -xe | grep -i umu

# Try with debug output
WINE_DEBUG=+all umu-game-manager launch "Game Name" 2>&1 | tee game_debug.log
```

### Missing Dependencies

```bash
# Check what's installed
umu-game-manager deps

# Manually install missing dependency
umu-game-installer ~/Downloads/vcredist_x64.exe

# Re-link dependencies to game
# This requires manual editing of the script or:
WINEPREFIX=~/Games/GameName/prefix winetricks vcrun2019
```

### Performance Issues

```bash
# Edit launch script for performance
nano ~/.config/umu-game-installer/launch_umu-game.sh

# Add performance tweaks:
# export DXVK_HUD=fps,gpuload,version
# export DXVK_ASYNC=1
# export WINE_FULLSCREEN_FSR=1
# export WINE_CPU_TOPOLOGY=8:8
# export PROTON_NO_ESYNC=1  # If audio issues
# export PROTON_NO_FSYNC=1  # If stability issues
```

---

## Tips & Tricks

### Batch Installation

```bash
# Install multiple games in sequence
for installer in ~/Downloads/game*.exe; do
    umu-game-installer "$installer"
done
```

### Export Game List

```bash
# Create backup of installed games
umu-game-manager export ~/my-games-list.md

# Share with others or keep for reference
```

### Quick Launch Aliases

Add to your `~/.bashrc`:

```bash
alias skyrim='umu-game-manager launch "Skyrim"'
alias witcher='umu-game-manager launch "The Witcher 3"'
alias games='umu-game-manager list'
```

### Integration with Lutris

```bash
# Export as Lutris-compatible format (manual)
# For each game, create a Lutris script

lutris -i ~/Games/GameName/prefix
```

---

## Community Examples

Share your own examples! Create an issue or PR with:
- Game name and source (GOG, Epic, etc.)
- Any special steps required
- Performance notes
- Mod compatibility

Happy gaming! 🎮
