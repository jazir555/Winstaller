# UMU Game Installer for Steam Deck

A comprehensive script that provides **1:1 parity with Windows game installation** on Steam Deck using umu-run. Install Windows games with their native GUI installers, automatically manage dependencies, and integrate seamlessly with Steam.

## Features

✅ **Native Windows Installation Experience**
- Run graphical game installers exactly as they appear on Windows
- Choose installation directory through the normal GUI
- Full support for all installer types (InstallShield, Inno Setup, NSIS, etc.)

✅ **Intelligent Dependency Management**
- Automatic detection of required dependencies (VC++ Redist, .NET, DirectX, etc.)
- Global dependency storage - install once, use everywhere
- Dependency-aware installation prevents duplication
- Shared dependency database across all games

✅ **Seamless Steam Integration**
- Automatically adds games to Steam library
- Configures Proton/Wine settings automatically
- Creates launch scripts with proper environment variables
- Steam-discoverable .desktop files

✅ **Desktop Integration**
- Automatic desktop shortcut creation
- Native Linux application integration
- Proper icon and metadata support

## Prerequisites

### Required
- **Steam Deck** running SteamOS (or any Linux system with umu-run)
- **umu-run** (UMU Launcher) - [Installation Guide](https://github.com/Open-Wine-Components/umu-launcher)

### Optional
- Flatpak Steam installation (for better integration)
- zenity or kdialog (for GUI file picker - future enhancement)

## Installation

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-installer.sh
chmod +x umu-game-installer.sh
```

2. Optionally, move to your PATH:
```bash
sudo mv umu-game-installer.sh /usr/local/bin/umu-game-installer
```

## Usage

### Basic Game Installation

```bash
./umu-game-installer.sh ~/Downloads/GameSetup.exe
```

The script will:
1. Prompt for the game name
2. Create a Wine prefix for the game
3. Detect any dependencies in the installer
4. Run the graphical installer (choose your install location here!)
5. Detect the game executable
6. Configure Steam integration
7. Create a desktop shortcut

### Custom Installation Directory

```bash
./umu-game-installer.sh --install-root /mnt/sdcard/Games setup.exe
```

### List Installed Dependencies

```bash
./umu-game-installer.sh --list-deps
```

Example output:
```
DEPENDENCY           VERSION    INSTALL DATE     PATH
--------------------------------------------------------------------------------
vcredist            2022       2024-01-15       /home/deck/.config/umu-game-installer/dependencies/vcredist_2022
directx             9          2024-01-15       /home/deck/.config/umu-game-installer/dependencies/directx_9
dotnet              4.8        2024-01-16       /home/deck/.config/umu-game-installer/dependencies/dotnet_4.8
```

### View Help

```bash
./umu-game-installer.sh --help
```

## How It Works

### 1. Dependency Detection & Management

The script automatically detects common dependencies from installer filenames:
- **VC++ Redistributables** (2010-2022)
- **.NET Framework** (3.5-4.8)
- **DirectX** (9, 11, 12)

When a dependency is detected:
1. Checks the global dependency database
2. If already installed → symlinks DLLs to game prefix
3. If new → installs to shared location and registers in database

**Dependency Database Format:**
```
DEPENDENCY_ID|VERSION|INSTALL_PATH|CHECKSUM|INSTALL_DATE
vcredist|2022|/path/to/prefix|sha256hash|2024-01-15
```

### 2. Wine Prefix Creation

Each game gets its own Wine prefix under:
```
~/Games/<GameName>/prefix/
```

This isolates game settings while sharing dependencies through symlinks.

### 3. Installer Execution

The graphical installer runs through umu-run with:
```bash
WINEPREFIX="$game_prefix" GAMEID="$game_id" umu-run installer.exe
```

You interact with the installer normally - select install path, components, etc.

### 4. Executable Detection

After installation, the script:
1. Scans common install paths (Program Files, Games, etc.)
2. Filters out installers/uninstallers
3. Presents candidates if multiple found
4. Allows manual specification if needed

### 5. Steam Integration

Creates a launch script:
```bash
#!/bin/bash
export WINEPREFIX="/path/to/prefix"
export GAMEID="umu-gamename"
exec umu-run "game.exe" "$@"
```

And a .desktop file Steam can discover:
```ini
[Desktop Entry]
Name=Game Name
Exec=/path/to/launch_script.sh
Type=Application
Categories=Game;
```

### 6. Desktop Shortcut

Creates an identical .desktop file on your desktop for quick access.

## Configuration

### Directory Structure

```
~/.config/umu-game-installer/
├── deps.db                      # Dependency database
├── dependencies/                # Shared dependency prefixes
│   ├── vcredist_2022/
│   ├── directx_9/
│   └── dotnet_4.8/
├── launch_*.sh                  # Game launch scripts
└── ...

~/Games/                         # Default game installation root
├── Game1/
│   └── prefix/                  # Wine prefix
└── Game2/
    └── prefix/

~/.local/share/applications/     # Steam shortcuts
└── umu-game1.desktop

~/Desktop/                       # Desktop shortcuts
└── Game1.desktop
```

### Customization

Edit the script variables at the top:

```bash
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/umu-game-installer"
DEPS_DIR="$CONFIG_DIR/dependencies"
DEFAULT_INSTALL_ROOT="$HOME/Games"
```

## Examples

### Example 1: Installing a GOG Game

```bash
# Download GOG installer
./umu-game-installer.sh ~/Downloads/setup_game_1.0.exe

# Script prompts:
# Enter game name: Witcher 3
# Detected dependencies: vcredist:2015, directx:9
# Install dependencies? (Y/n): y

# GUI installer opens - choose install path
# (e.g., /home/deck/Games/Witcher3)

# After installation completes:
# Detected game executable: .../witcher3.exe
# Use this executable? (Y/n): y

# ✓ Game installed
# ✓ Added to Steam
# ✓ Desktop shortcut created
```

### Example 2: Installing with Existing Dependencies

```bash
./umu-game-installer.sh ~/Downloads/another_game_setup.exe

# Enter game name: Another Game
# Detected dependencies: vcredist:2015
# Dependency vcredist 2015 already installed, skipping...
# Linked vcredist 2015

# (Installation continues without re-downloading dependencies)
```

### Example 3: SD Card Installation

```bash
# Mount SD card at /mnt/sdcard
./umu-game-installer.sh --install-root /mnt/sdcard/Games setup.exe

# Game will be installed to:
# /mnt/sdcard/Games/<GameName>/prefix/
```

## Advanced Features

### Manual Dependency Installation

If you have standalone dependency installers:

```bash
# The script will detect and register them
./umu-game-installer.sh vcredist_x64_2022.exe
./umu-game-installer.sh directx_Jun2010_redist.exe
```

### Debugging

Set verbose logging:
```bash
set -x  # Add to top of script for debug mode
./umu-game-installer.sh installer.exe
```

### Uninstalling Games

Currently manual:
1. Remove game directory: `rm -rf ~/Games/<GameName>`
2. Remove desktop shortcut: `rm ~/Desktop/<GameName>.desktop`
3. Remove Steam shortcut: `rm ~/.local/share/applications/umu-<game-id>.desktop`
4. Remove launch script: `rm ~/.config/umu-game-installer/launch_<game-id>.sh`

(Future: `--uninstall <game-name>` command)

## Troubleshooting

### Installer doesn't appear

**Issue:** GUI installer window doesn't show
**Solution:**
```bash
# Check umu-run is working
umu-run winecfg

# Try running installer manually
WINEPREFIX=~/test_prefix GAMEID=test umu-run installer.exe
```

### Game won't launch

**Issue:** Desktop/Steam shortcut doesn't work
**Solution:**
```bash
# Test launch script directly
~/.config/umu-game-installer/launch_<game-id>.sh

# Check logs
journalctl --user -xe | grep umu
```

### Dependency not detected

**Issue:** Installer needs VC++ 2019 but wasn't detected
**Solution:**
```bash
# Install dependency manually first
./umu-game-installer.sh vcredist_x64_2019.exe

# Then install game
./umu-game-installer.sh game_installer.exe
```

### Wrong executable detected

**Issue:** Script detected uninstaller instead of game
**Solution:** Select "n" when asked to use detected executable, then manually enter correct path

## Comparison with Windows Installation

| Feature | Windows | UMU Game Installer | Status |
|---------|---------|-------------------|--------|
| Graphical installer | ✓ | ✓ | ✓ Full parity |
| Choose install location | ✓ | ✓ | ✓ Full parity |
| Dependency auto-install | ✓ | ✓ | ✓ Full parity |
| Dependency sharing | ✓ | ✓ | ✓ Full parity |
| Desktop shortcut | ✓ | ✓ | ✓ Full parity |
| Start menu integration | ✓ | Steam/Apps | ≈ Equivalent |
| Uninstaller | ✓ | Manual | ⚠ Planned |
| Registry integration | ✓ | Wine registry | ✓ Transparent |
| System tray | ✓ | ✓ | ✓ Wine handles |

## Roadmap

- [ ] GUI file picker integration (zenity/kdialog)
- [ ] Automatic game uninstaller
- [ ] Dependency cleanup for unused libraries
- [ ] Better Steam shortcuts.vdf integration
- [ ] Game icon extraction and usage
- [ ] Save game location detection
- [ ] Cloud save integration
- [ ] Multi-language installer support
- [ ] Batch installation mode
- [ ] Web-based GUI for management

## Contributing

Contributions welcome! Areas for improvement:
- Steam shortcuts.vdf binary format handling
- Better executable detection heuristics
- Additional dependency detection patterns
- Game-specific configuration profiles
- Icon extraction from executables

## License

MIT License - See LICENSE file

## Credits

- **umu-run** - [Open Wine Components](https://github.com/Open-Wine-Components/umu-launcher)
- **Proton** - Valve Corporation
- **Wine** - Wine Development Team

## Support

- Issues: [GitHub Issues](https://github.com/yourusername/umu-game-installer/issues)
- Steam Deck Community: r/SteamDeck
- umu-run Discord: [Join](https://discord.gg/umu-launcher)

---

**Made with ❤️ for the Steam Deck community**
