# KDE Plasma 6 Migration Guide

## 🆕 Upgrading from KDE Plasma 5 to 6

This guide helps users who are upgrading from KDE Plasma 5 to Plasma 6 ensure the UMU Game Installer continues working correctly.

---

## 🔍 Do You Need This Guide?

### Check Your KDE Version:

```bash
plasmashell --version
```

**Output Examples:**
- `plasmashell 5.27.10` → You have Plasma 5
- `plasmashell 6.0.5` → You have Plasma 6

---

## ✅ Good News: Automatic Compatibility

If you installed UMU Game Installer **after June 2024**, it already includes Plasma 6 support and no migration is needed!

The installer automatically:
- ✅ Detects your Plasma version
- ✅ Installs to the correct location
- ✅ Handles both Plasma 5 and 6

---

## 🔄 Migration Steps (If Needed)

### Scenario 1: Fresh Install on Plasma 6

**No migration needed!** Just run the installer:

```bash
./umu-system-installer.sh
```

It will automatically detect Plasma 6 and install correctly.

---

### Scenario 2: Upgrading from Plasma 5 to 6

If you:
1. Installed UMU Game Installer on Plasma 5
2. Then upgraded your system to Plasma 6
3. Context menu doesn't work anymore

**Follow these steps:**

#### Step 1: Verify Your Plasma Version

```bash
plasmashell --version
# Should show 6.x.x
```

#### Step 2: Re-run the System Installer

```bash
cd ~/Downloads/umu-game-installer-main
./umu-system-installer.sh
```

The installer will:
- Detect Plasma 6
- Install context menu to new location (`~/.local/share/kio/servicemenus/`)
- Keep all your installed games intact
- Update all necessary components

#### Step 3: Refresh KDE Services

```bash
kbuildsycoca6
```

#### Step 4: Restart Dolphin

```bash
killall dolphin
dolphin &
```

#### Step 5: Test

Right-click an `.exe` file in Dolphin. You should see "Install Windows Game" in the menu.

---

### Scenario 3: Manual Migration

If you prefer manual migration:

#### Step 1: Remove Old Plasma 5 Menu

```bash
rm ~/.local/share/kservices5/ServiceMenus/umu-install-game.desktop
```

#### Step 2: Create Plasma 6 Menu

```bash
mkdir -p ~/.local/share/kio/servicemenus

cat > ~/.local/share/kio/servicemenus/umu-install-game.desktop << 'EOF'
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
```

#### Step 3: Refresh Services

```bash
kbuildsycoca6
```

---

## 🔧 Key Differences: Plasma 5 vs Plasma 6

### Service Menu Location

| Component | Plasma 5 | Plasma 6 |
|-----------|----------|----------|
| **Path** | `~/.local/share/kservices5/ServiceMenus/` | `~/.local/share/kio/servicemenus/` |
| **File** | `umu-install-game.desktop` | `umu-install-game.desktop` |
| **Format** | Includes `ServiceTypes=KonqPopupMenu/Plugin` | Simplified (no ServiceTypes) |

### Cache Rebuild Command

| Plasma 5 | Plasma 6 |
|----------|----------|
| `kbuildsycoca5 --noincremental` | `kbuildsycoca6` |

### Desktop Entry Format

**Plasma 5:**
```ini
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-ms-dos-executable;
Actions=install-game
X-KDE-Submenu=
```

**Plasma 6:**
```ini
[Desktop Entry]
Type=Service
MimeType=application/x-ms-dos-executable;
Actions=install-game
```

---

## ✅ Verification After Migration

### Test 1: Context Menu

1. Open Dolphin
2. Navigate to a folder with an `.exe` file
3. Right-click the `.exe` file
4. **Expected:** "Install Windows Game" appears in menu

### Test 2: Double-Click

1. Double-click an `.exe` file
2. **Expected:** KDialog prompts for game name
3. Enter a name
4. **Expected:** Windows installer appears

### Test 3: Run Verification Script

```bash
./verify-installation.sh
```

Should show:
```
✓ PASS: KDE Plasma 6 Dolphin context menu installed
```

---

## 🐛 Troubleshooting Migration Issues

### Issue: Context menu still not appearing

**Solution:**
```bash
# Clear all KDE caches
rm -rf ~/.cache/kio*
rm -rf ~/.cache/ksycoca*

# Rebuild
kbuildsycoca6

# Restart Dolphin
killall dolphin
dolphin &

# Log out and back in (if still not working)
```

### Issue: Both Plasma 5 and 6 files exist

**This is fine!** Having both doesn't cause issues. The system will use the correct one.

**If you want to clean up:**
```bash
# Keep only Plasma 6 version
rm ~/.local/share/kservices5/ServiceMenus/umu-install-game.desktop

# Rebuild cache
kbuildsycoca6
```

### Issue: Wrong kbuildsycoca command

**Error message:**
```
kbuildsycoca5: command not found
```

**Solution:** You're on Plasma 6, use:
```bash
kbuildsycoca6
```

### Issue: Installer doesn't detect Plasma 6

**Check:**
```bash
plasmashell --version
echo $?  # Should be 0 (success)
```

**If plasmashell command fails:**
```bash
# Install plasma-desktop
sudo pacman -S plasma-desktop  # Arch
sudo apt install plasma-desktop  # Ubuntu
sudo dnf install plasma-desktop  # Fedora
```

---

## 🎯 Migration Checklist

Before migration:
- [ ] Backup your games: `tar -czf games-backup.tar.gz ~/Games/`
- [ ] Note your Plasma version: `plasmashell --version`
- [ ] Verify umu-run still works: `umu-run --version`

During migration:
- [ ] Run system installer: `./umu-system-installer.sh`
- [ ] Rebuild cache: `kbuildsycoca6`
- [ ] Restart Dolphin

After migration:
- [ ] Test context menu (right-click .exe)
- [ ] Test double-click
- [ ] Run verification: `./verify-installation.sh`
- [ ] Verify games still launch: `umu-game-manager list`

---

## 📊 Compatibility Matrix

| Scenario | Plasma 5 Path | Plasma 6 Path | Works? |
|----------|---------------|---------------|--------|
| Fresh install on Plasma 5 | ✅ Installed | ✅ Installed | ✅ |
| Fresh install on Plasma 6 | ⚠️ Also installed | ✅ Installed | ✅ |
| Upgrade 5→6 without re-install | ✅ Still there | ❌ Not installed | ⚠️ May not work |
| Upgrade 5→6 with re-install | ✅ Old version | ✅ Installed | ✅ |

**Recommendation:** Re-run installer after Plasma upgrade.

---

## 🚀 Future-Proofing

### For System Administrators

If deploying to multiple machines that might upgrade:

```bash
# Install to both locations preemptively
mkdir -p ~/.local/share/kservices5/ServiceMenus
mkdir -p ~/.local/share/kio/servicemenus

# Copy to both
cp umu-install-game.desktop ~/.local/share/kservices5/ServiceMenus/
cp umu-install-game.desktop ~/.local/share/kio/servicemenus/

# Rebuild both caches
kbuildsycoca5 --noincremental 2>/dev/null || true
kbuildsycoca6 2>/dev/null || true
```

### For Package Maintainers

Include both paths in your package:
```
/usr/share/kservices5/ServiceMenus/umu-install-game.desktop
/usr/share/kio/servicemenus/umu-install-game.desktop
```

---

## 📅 Timeline

- **KDE Plasma 5:** Released 2014, stable and mature
- **KDE Plasma 6:** Released February 2024
- **Steam Deck:** Currently uses Plasma 5.27.x
- **Future Steam Deck:** Will likely upgrade to Plasma 6

**This installer supports both, ensuring smooth transition.**

---

## 🆘 Still Having Issues?

1. **Check logs:**
   ```bash
   journalctl --user -xe | grep -i kde
   ```

2. **Verify paths:**
   ```bash
   ls -la ~/.local/share/kservices5/ServiceMenus/
   ls -la ~/.local/share/kio/servicemenus/
   ```

3. **Test manually:**
   ```bash
   umu-game-installer-gui ~/Downloads/test.exe
   ```

4. **Re-install everything:**
   ```bash
   ./umu-system-installer.sh
   ```

5. **Report issue:**
   - Include `plasmashell --version` output
   - Include output from `./verify-installation.sh`
   - Mention you're on Plasma 6

---

## ✅ Success Indicators

After successful migration, you should see:

- ✅ Right-click menu in Dolphin works
- ✅ Double-click .exe files works
- ✅ KDialog prompts appear
- ✅ Games install correctly
- ✅ Existing games still launch
- ✅ No error messages in logs

**If all checked: Migration successful! 🎉**

---

**Your games are safe.** This migration only affects context menus, not installed games or configurations.

**Made with ❤️ for KDE Plasma 6 users**
