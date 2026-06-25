# 🎮 Quick Start - GUI Mode

## Install Once, Double-Click Forever

**✨ Optimized for Steam Deck / KDE Plasma ✨**

---

## ⚡ 2-Minute Setup

### 1. Install Prerequisites

```bash
# Install umu-run
pip install --user umu-launcher

# Install kdialog (Steam Deck already has this!)
sudo pacman -S kdialog  # Usually pre-installed
```

**Steam Deck users:** kdialog is already there! Just install umu-run.

### 2. Download and Extract

```bash
cd ~/Downloads
curl -L https://github.com/yourusername/umu-game-installer/archive/main.zip -o umu-installer.zip
unzip umu-installer.zip
cd umu-game-installer-main
```

### 3. Run Setup

```bash
chmod +x umu-system-installer.sh
./umu-system-installer.sh
```

**Done! You'll never need the terminal again!**

---

## 🎯 How to Use

### Install a Game (3 clicks)

```
1. Double-click any .exe installer (in Dolphin file manager)
2. Enter game name in KDialog popup
3. Follow Windows installer normally
```

**That's it!**

**Works with:**
- ✅ KDE Plasma (Steam Deck default)
- ✅ Dolphin file manager
- ✅ KDialog native dialogs
- ✅ Also supports GNOME, Cinnamon

### Alternative: Right-Click

```
1. Right-click any .exe file
2. Select "Install Windows Game"
3. Follow prompts
```

---

## 🎮 Example: Installing from GOG

```
1. Download setup_witcher3.exe from GOG
2. Go to Downloads folder
3. Double-click setup_witcher3.exe
4. Type "The Witcher 3" when asked
5. Windows installer appears
6. Choose install location
7. Click Install
8. Game appears in Steam!
```

**Exactly like Windows!**

---

## 📍 Where Things Are

### After Installation:
- 🎮 **Games:** `~/Games/GameName/`
- 📱 **Desktop Shortcuts:** Created automatically
- 🎯 **Steam Library:** Games appear automatically
- ⚙️ **Config:** `~/.config/umu-game-installer/`

### Desktop Icons Created:
- **Game Manager** - Manage your games
- **Your Games** - Each installed game gets an icon

---

## 🎯 Manage Games

Double-click **"Game Manager"** on desktop

Or:
```bash
umu-game-manager list          # List all games
umu-game-manager launch "Name" # Launch a game
umu-game-manager disk          # Check space used
```

---

## ❓ Quick FAQ

**Q: Do I need the terminal after setup?**  
A: No! Just double-click .exe files.

**Q: Where do I get games?**  
A: GOG.com, Humble Bundle, itch.io (download Windows versions)

**Q: Will games appear in Steam?**  
A: Yes, automatically!

**Q: Can I install to SD card?**  
A: Yes, choose SD card location in Windows installer

**Q: How do I uninstall?**  
A: Run `umu-uninstall` in terminal

---

## 🎉 That's It!

**Three steps:**
1. ✅ Run setup (one time)
2. ✅ Double-click installers
3. ✅ Play games

**No command line. No Wine knowledge. Just gaming.**

---

## 📖 More Info

- **Full GUI guide:** [README-GUI.md](README-GUI.md)
- **All features:** [README.md](README.md)
- **Examples:** [EXAMPLES.md](EXAMPLES.md)
- **Help:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Ready?**

```bash
./umu-system-installer.sh
```

**Then just double-click any .exe game installer!** 🎮
