# Getting Started with UMU Game Installer

Welcome! This guide will get you up and running with the UMU Game Installer in under 10 minutes.

## What You'll Need

- **Steam Deck** (or Linux system with SteamOS/Arch/Ubuntu/Fedora)
- **umu-run** installed (we'll help you install this)
- **Game installer** (.exe file from GOG, Humble Bundle, etc.)
- **5-10 minutes** of your time

## Quick Start (5 Steps)

### Step 1: Install umu-run

```bash
# Check if already installed
umu-run --version

# If not installed, install it
pip install --user umu-launcher

# Verify installation
umu-run --version
```

### Step 2: Download UMU Game Installer

```bash
# Create directory for scripts
mkdir -p ~/.local/bin

# Download main installer
curl -L https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-installer.sh -o ~/.local/bin/umu-game-installer

# Download game manager
curl -L https://raw.githubusercontent.com/yourusername/umu-game-installer/main/umu-game-manager.sh -o ~/.local/bin/umu-game-manager

# Make executable
chmod +x ~/.local/bin/umu-game-installer
chmod +x ~/.local/bin/umu-game-manager

# Verify they work
umu-game-installer --version
umu-game-manager --help
```

### Step 3: Install Your First Game

```bash
# Navigate to your downloads
cd ~/Downloads

# Run the installer (replace with your actual game installer)
umu-game-installer game-setup.exe

# Follow the prompts:
# 1. Enter game name: "My Game"
# 2. Install dependencies? Y
# 3. Use GUI installer to choose install location
# 4. Confirm detected executable
```

### Step 4: Verify Installation

```bash
# List installed games
umu-game-manager list

# You should see your game listed!
```

### Step 5: Launch Your Game

```bash
# Option 1: From terminal
umu-game-manager launch "My Game"

# Option 2: From desktop
# Look for the game icon on your desktop, double-click it

# Option 3: From Steam
# Open Steam → Library → Non-Steam Games
# Your game should appear there
```

**Congratulations! 🎉 You've successfully installed your first game!**

---

## What Just Happened?

When you ran the installer, it:

1. ✅ Created a Wine prefix for your game
2. ✅ Detected and installed any required dependencies (VC++, DirectX, etc.)
3. ✅ Ran the Windows installer GUI so you could choose where to install
4. ✅ Detected the game executable automatically
5. ✅ Created a launch script with proper configuration
6. ✅ Added the game to Steam
7. ✅ Created a desktop shortcut

All with **zero duplicate dependencies** and **Windows-like installation experience**!

---

## Common First-Time Questions

### Q: Where are my games installed?

**A:** By default, in `~/Games/GameName/`

```bash
ls ~/Games/
```

### Q: Where are dependencies stored?

**A:** In `~/.config/umu-game-installer/dependencies/`

```bash
ls ~/.config/umu-game-installer/dependencies/
```

These are shared across all games to save space!

### Q: How do I see what dependencies I have?

**A:** 
```bash
umu-game-manager deps
```

### Q: Can I install games to my SD card?

**A:** Yes!

```bash
umu-game-installer --install-root /run/media/mmcblk0p1/Games game-setup.exe
```

### Q: What if the installer detects the wrong executable?

**A:** When prompted, select "n" and then type the correct path:

```
Detected game executable: .../wrong.exe
Use this executable? (Y/n): n
Enter full path to game executable: /full/path/to/correct/game.exe
```

### Q: How do I uninstall a game?

**A:**
```bash
umu-game-manager uninstall "Game Name"
```

### Q: My game won't launch, what do I do?

**A:** Try launching manually to see errors:

```bash
cd ~/Games/GameName/prefix
WINEPREFIX=$(pwd) GAMEID=umu-gamename umu-run drive_c/path/to/game.exe
```

Check the [Troubleshooting](#troubleshooting-quick-fixes) section below.

---

## Your First Hour with UMU Game Installer

### Install a Few Games

```bash
# Install multiple games
umu-game-installer ~/Downloads/game1-setup.exe
umu-game-installer ~/Downloads/game2-setup.exe
umu-game-installer ~/Downloads/game3-setup.exe

# List them all
umu-game-manager list
```

### Check Your Storage

```bash
# See how much space you're using
umu-game-manager disk

# Compare to traditional installs
# (You'll likely save 50-80% on dependencies!)
```

### Pre-Install Common Dependencies

Save time by installing common dependencies once:

```bash
# Download these from Microsoft
# VC++ 2022 Redistributable
umu-game-installer ~/Downloads/vcredist_x64_2022.exe

# VC++ 2019 Redistributable  
umu-game-installer ~/Downloads/vcredist_x64_2019.exe

# Now games that need these will skip installation!
umu-game-manager deps
```

### Create Shortcuts for Easy Access

Add to `~/.bashrc`:

```bash
# Quick game management
alias games='umu-game-manager list'
alias play='umu-game-manager launch'
alias gameinfo='umu-game-manager info'
```

Then:
```bash
source ~/.bashrc

# Now you can use:
games                    # List all games
play "My Game"          # Launch a game
gameinfo "My Game"      # Show game details
```

---

## Example: Installing a GOG Game

Let's walk through a complete real-world example:

### 1. Download from GOG

1. Go to gog.com
2. Purchase/download a game
3. Download the **Windows** installer (not Linux)
4. It'll be something like: `setup_game_name_1.2.3.exe`

### 2. Install with UMU

```bash
cd ~/Downloads
umu-game-installer setup_the_witcher_3_*.exe
```

### 3. Follow the Prompts

```
Enter game name: The Witcher 3
Detected dependencies: vcredist:2015, directx:9
Install dependencies? (Y/n): y
```

### 4. Use the GUI Installer

The Windows installer appears! 

- Accept the license
- Choose language
- Select install location (e.g., `/home/deck/Games/TheWitcher3`)
- Choose components
- Click Install
- Wait for installation to complete

### 5. Verify and Launch

```bash
# Check it's installed
umu-game-manager list

# Show details
umu-game-manager info "The Witcher 3"

# Launch it!
umu-game-manager launch "The Witcher 3"

# Or use the desktop icon
```

**That's it!** Your game is now installed exactly like on Windows.

---

## Troubleshooting Quick Fixes

### Issue: umu-run not found

```bash
# Install it
pip install --user umu-launcher

# Make sure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: GUI installer doesn't appear

```bash
# Test Wine is working
GAMEID=test umu-run winecfg

# If that works, try the installer again
# If not, check umu-run installation
```

### Issue: Game crashes on launch

```bash
# Get more debug info
cd ~/Games/GameName/prefix
WINE_DEBUG=+all WINEPREFIX=$(pwd) GAMEID=umu-gamename \
    umu-run drive_c/path/to/game.exe 2>&1 | tee debug.log

# Check debug.log for errors
less debug.log
```

### Issue: Missing dependencies

```bash
# Check what's installed
umu-game-manager deps

# Manually install missing dependency
umu-game-installer ~/Downloads/vcredist_x64.exe

# Or use winetricks
WINEPREFIX=~/Games/GameName/prefix winetricks vcrun2019
```

### Issue: Wrong executable detected

```bash
# Edit the launch script
nano ~/.config/umu-game-installer/launch_umu-gamename.sh

# Change the line:
# exec umu-run "/wrong/path.exe" "$@"
# to:
# exec umu-run "/correct/path.exe" "$@"

# Save and try launching again
```

---

## Next Steps

Now that you're up and running:

### 📚 Learn More

- **[README.md](README.md)** - Full documentation
- **[EXAMPLES.md](EXAMPLES.md)** - More real-world examples
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheat sheet

### 🎮 Install More Games

- GOG games: Perfect compatibility
- Humble Bundle: Usually works great
- itch.io: Most games work
- Old games: May need tweaks (see examples)

### ⚙️ Customize

- Edit `~/.config/umu-game-installer/config` for settings
- Add launch options in the launch scripts
- Create game-specific profiles

### 🤝 Get Help

- GitHub Issues: Report bugs
- Reddit: r/SteamDeck community
- ProtonDB: Check game compatibility

---

## Quick Reference Card

Keep this handy:

```bash
# Install game
umu-game-installer game-setup.exe

# List games
umu-game-manager list

# Launch game
umu-game-manager launch "Game Name"

# Game info
umu-game-manager info "Game Name"

# Uninstall game
umu-game-manager uninstall "Game Name"

# List dependencies
umu-game-manager deps

# Check disk usage
umu-game-manager disk

# Help
umu-game-installer --help
umu-game-manager --help
```

---

## Tips for Success

### ✅ Do:
- Install dependencies first if you have them
- Use the GUI installer normally (it works just like Windows)
- Keep game installers after installation (for reinstalls)
- Check ProtonDB for game compatibility tips

### ❌ Don't:
- Install to weird locations (stick with suggested paths)
- Mix manual Wine installs with UMU installs
- Delete dependencies (they're shared!)
- Install games to `/tmp` or other temporary locations

---

## Success! What Now?

You're all set! Here's what you can do:

1. **Install your game library** - Work through your backlog
2. **Share your experience** - Help others on Reddit/Discord
3. **Report issues** - Help improve the tool
4. **Customize further** - Tweak settings for your needs

**Happy Gaming! 🎮**

---

## Still Have Questions?

Check out:
- **[FAQ section in README.md](README.md#faq)**
- **[TESTING.md](TESTING.md)** - If something seems broken
- **[EXAMPLES.md](EXAMPLES.md)** - For game-specific help
- **GitHub Issues** - Ask the community

Remember: This tool aims for **1:1 Windows parity**. If it doesn't feel like installing on Windows, let us know!
