# Steam Deck Setup Guide

**🎮 Optimized for Steam Deck with KDE Plasma Desktop**

This guide is specifically for Steam Deck users who want to install Windows games by double-clicking installers in Desktop Mode.

---

## ⚡ Quick Setup (2 Minutes in Desktop Mode)

### Step 1: Enter Desktop Mode

1. Press STEAM button
2. Select "Power"
3. Select "Switch to Desktop"

### Step 2: Open Konsole (Terminal)

1. Click the Application Menu (bottom-left)
2. Search for "Konsole"
3. Click to open

### Step 3: Install umu-run

```bash
pip install --user umu-launcher
```

**Note:** kdialog is already installed on Steam Deck - nothing else needed!

### Step 4: Download and Run Setup

```bash
cd ~/Downloads
curl -L https://github.com/yourusername/umu-game-installer/archive/main.zip -o umu-installer.zip
unzip umu-installer.zip
cd umu-game-installer-main
chmod +x umu-system-installer.sh
./umu-system-installer.sh
```

Follow the prompts. Setup takes ~30 seconds.

### Step 5: Done!

**You can now close Konsole. You'll never need it again.**

---

## 🎯 How to Install Games (Desktop Mode)

### Method 1: Double-Click (Easiest)

1. Download a Windows game installer (e.g., from GOG)
2. Go to Downloads folder in Dolphin (file manager)
3. **Double-click the .exe file**
4. KDE dialog asks for game name → type it in
5. Windows installer appears → install normally
6. Done! Game appears in Gaming Mode

### Method 2: Right-Click Menu

1. Find your .exe installer in Dolphin
2. **Right-click** the file
3. Select **"Install Windows Game"**
4. Enter game name → installer appears
5. Done!

---

## 🎮 Playing Games

### In Desktop Mode:
- Double-click the desktop shortcut
- Or find in Application Menu → Games

### In Gaming Mode:
1. Press STEAM button → Power → Return to Gaming Mode
2. Games appear in your Library automatically
3. Launch like any other game!

---

## 🔧 Steam Deck Specific Features

### KDE Plasma Integration ✓
- **Dolphin file manager** - Right-click any .exe
- **KDialog** - Native KDE dialogs (no GNOME dependencies)
- **Konsole** - Optional terminal access
- **Plasma Desktop** - Full desktop integration

### Gaming Mode Integration ✓
- Games appear in library automatically
- Launch from Gaming Mode normally
- Per-game controller configs work
- Steam Input fully functional

### Performance Optimized ✓
- Proton compatibility layer via umu-run
- AMD GPU acceleration (RADV)
- FSR upscaling support
- Controller-first experience

---

## 📁 Where Things Are Stored

### Games:
```
/home/deck/Games/
├── GameName1/
├── GameName2/
└── ...
```

### Desktop Shortcuts:
```
/home/deck/Desktop/
├── Game Manager.desktop
├── GameName1.desktop
└── ...
```

### Steam Library:
Games appear automatically in Gaming Mode library

---

## 🎯 Recommended Game Sources for Steam Deck

### Best Sources:

1. **GOG.com** ⭐ BEST
   - DRM-free
   - Offline installers
   - Great compatibility
   - Example: The Witcher 3, Cyberpunk 2077

2. **Humble Bundle** ⭐ EXCELLENT  
   - DRM-free Windows installers
   - Often includes Linux versions too
   - Great deals

3. **itch.io** ⭐ VERY GOOD
   - Independent games
   - DRM-free
   - Many have native Linux builds

### Also Works:

4. **Epic Games**
   - Need to install Epic Launcher first
   - Then install games through launcher

5. **Old Games**
   - Classic PC games (90s-2000s)
   - Often work better than on modern Windows!

---

## 🎮 Example: Installing The Witcher 3 (GOG)

### Full Walkthrough:

**Desktop Mode:**

1. Open Firefox browser
2. Go to GOG.com → login
3. Find The Witcher 3 in your library
4. Download → "Download Offline Backup Game Installers"
5. Select "Windows" version
6. Download setup_witcher3_xxx.exe

**After Download:**

7. Open Dolphin file manager
8. Go to Downloads folder
9. **Double-click setup_witcher3_xxx.exe**
10. KDialog appears: "Enter game name:"
11. Type: **"The Witcher 3"**
12. Click OK

**Windows Installer Appears:**

13. Click "Next"
14. Accept license
15. Choose install location (default is fine: ~/Games/TheWitcher3)
16. Select components (Full Installation)
17. Click "Install"
18. Wait for installation (~15 minutes)
19. Click "Finish"

**Done!**

20. Desktop shortcut created ✓
21. Check Application Menu → Games → The Witcher 3 ✓
22. Return to Gaming Mode → Game in Library ✓

**Launch in Gaming Mode:**

23. Press STEAM → Power → Return to Gaming Mode
24. Library → Search "Witcher"
25. Click to launch
26. Play! 🎮

---

## 💡 Tips for Steam Deck

### Storage Management:

**Install to SD Card:**
When the Windows installer appears, change the install path:
- Default: `/home/deck/Games/GameName`
- SD Card: `/run/media/mmcblk0p1/Games/GameName`

**Check Space:**
```bash
umu-game-manager disk
```

### Performance:

**Most games work great!** But if you need tweaks:
```bash
# Edit launch script for a specific game
nano ~/.config/umu-game-installer/launch_umu-gamename.sh

# Add performance flags:
export DXVK_ASYNC=1
export RADV_PERFTEST=gpl
export WINE_FULLSCREEN_FSR=1
```

### Controls:

- Steam Input works automatically
- Configure per-game in Gaming Mode
- Desktop Mode: Use mouse/keyboard or controller

### Graphics:

- FSR upscaling: Works automatically
- Resolution: Set in game options
- Most games: 800p medium settings = 40-60 FPS

---

## ❓ FAQ (Steam Deck Specific)

### Q: Do I need to disable read-only mode?
**A:** No! Everything installs to your home directory (`/home/deck/`). No system modifications needed.

### Q: Will this void my warranty?
**A:** No! This is just software installation in user space.

### Q: Can I do this in Gaming Mode?
**A:** No, you need Desktop Mode for initial setup and installing games. But launching games works in both modes.

### Q: Does this work with the Deck's SD card?
**A:** Yes! Just choose the SD card path when the Windows installer asks where to install.

### Q: Will games appear in Gaming Mode?
**A:** Yes, automatically! They appear as non-Steam games.

### Q: Can I uninstall games?
**A:** Yes:
```bash
umu-game-manager uninstall "Game Name"
```
Or just delete from `~/Games/` folder.

### Q: Does this work after SteamOS updates?
**A:** Yes! Everything is in your home folder, not the system partition.

### Q: What if kdialog isn't working?
**A:** It's pre-installed on Steam Deck. If somehow missing:
```bash
sudo steamos-readonly disable
sudo pacman -S kdialog
sudo steamos-readonly enable
```

### Q: Can I use this with Heroic/Lutris?
**A:** Yes, they can coexist. UMU installer is completely separate.

---

## 🔧 Troubleshooting

### Installer doesn't appear when double-clicking

**Fix in Desktop Mode:**
```bash
cd ~/Downloads/umu-game-installer-main
./umu-system-installer.sh
```
Re-run the setup.

### KDialog not showing

**Test it:**
```bash
kdialog --inputbox "Test"
```

If error, reinstall:
```bash
sudo steamos-readonly disable
sudo pacman -S kdialog
sudo steamos-readonly enable
```

### Game won't launch in Gaming Mode

**Check it works in Desktop Mode first:**
1. Double-click desktop shortcut
2. If works: It will work in Gaming Mode too
3. If not: Check game compatibility

**Test manually:**
```bash
umu-game-manager launch "Game Name"
```

### Right-click menu not showing

**Refresh Dolphin:**
```bash
kbuildsycoca5 --noincremental
```

Or logout and login to Desktop Mode.

---

## 🎊 Success Checklist

After setup, you should have:

✓ Can double-click .exe files in Dolphin
✓ KDialog asks for game name
✓ Windows installer appears
✓ Games install successfully
✓ Desktop shortcuts created
✓ Games appear in Gaming Mode library
✓ Games launch from Gaming Mode

**If all checked: You're ready to game! 🎮**

---

## 📖 More Resources

- **Main Documentation:** [README-GUI.md](README-GUI.md)
- **Quick Start:** [QUICKSTART-GUI.md](QUICKSTART-GUI.md)
- **Game Examples:** [EXAMPLES.md](EXAMPLES.md)
- **Windows Parity:** [COMPARISON.md](COMPARISON.md)

---

## 🎮 Enjoy Your Steam Deck!

**You now have the best of both worlds:**
- Steam games in Gaming Mode
- Windows games installed like on Windows
- Everything in one device
- No dual boot needed!

**Happy Gaming! 🎮**

---

*This guide is optimized for Steam Deck running SteamOS 3.x with KDE Plasma Desktop.*
