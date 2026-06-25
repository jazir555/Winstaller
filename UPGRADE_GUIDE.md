# Upgrade Guide: Security Fixes

## For Users Already Running UMU Game Installer

This guide helps you safely upgrade from the vulnerable version to the secure version with all security fixes applied.

---

## 🚨 Why Upgrade?

The previous version had **5 critical security vulnerabilities**:

1. **Command Injection** - Malicious game names could execute arbitrary code
2. **Config File Injection** - Attackers could take over your system through config files
3. **Unverified Installers** - Dependency installers ran before integrity checks
4. **Integer Overflow** - Steam shortcut IDs could crash the installer
5. **Resource Leaks** - Failed installations left temporary files on disk

**All vulnerabilities have been fixed in this version.**

---

## ✅ Quick Upgrade (Recommended)

### Step 1: Backup Your Data
```bash
# Backup your games database
cp ~/.config/umu-game-installer/games.db ~/.config/umu-game-installer/games.db.backup

# Backup your dependencies database
cp ~/.config/umu-game-installer/deps.db ~/.config/umu-game-installer/deps.db.backup

# Backup your configuration
cp ~/.config/umu-game-installer/config ~/.config/umu-game-installer/config.backup
```

### Step 2: Download Updated Scripts
```bash
cd ~/Downloads/umu-game-installer
git pull  # If using git
# OR download the latest release
```

### Step 3: Run System Installer Again
```bash
cd ~/Downloads/umu-game-installer
./umu-system-installer.sh
```

This will:
- ✅ Overwrite old scripts with secure versions
- ✅ Keep your existing games and data
- ✅ Preserve your configuration (with security validation added)

### Step 4: Verify Installation
```bash
# Check version (should show updated script)
umu-game-installer --version

# List your games (should all still be there)
umu-game-manager list
```

---

## 🔍 Manual Upgrade (Advanced Users)

If you prefer manual installation:

### Step 1: Backup (same as above)

### Step 2: Copy Updated Scripts
```bash
cp umu-game-installer.sh ~/.local/bin/umu-game-installer
cp umu-game-manager.sh ~/.local/bin/umu-game-manager
chmod +x ~/.local/bin/umu-game-installer
chmod +x ~/.local/bin/umu-game-manager
```

### Step 3: Verify Checksums (Optional but Recommended)
```bash
sha256sum ~/.local/bin/umu-game-installer
sha256sum ~/.local/bin/umu-game-manager
# Compare with checksums in SECURITY_FIXES.md
```

---

## 🔐 Post-Upgrade Security Hardening

After upgrading, follow these steps to improve security:

### 1. Verify Config File Ownership
```bash
# Your user config should be owned by you
ls -la ~/.config/umu-game-installer/config
# Should show: -rw-r--r-- 1 youruser youruser

# If it shows a different owner, fix it:
chown $(id -u):$(id -g) ~/.config/umu-game-installer/config
```

### 2. Check System Config (if exists)
```bash
# System config should be owned by root
ls -la /etc/umu-installer.conf
# Should show: -rw-r--r-- 1 root root

# If you don't have a system config, you can skip this
```

### 3. Clean Up Old Temporary Files
```bash
# Remove any leaked temp files from old version
find /tmp -name "tmp.*" -mtime +7 -user $(whoami) -delete

# Check disk space recovered
df -h /tmp
```

### 4. Review Your Config File
```bash
# Check for suspicious entries
cat ~/.config/umu-game-installer/config

# Remove any lines you don't recognize
nano ~/.config/umu-game-installer/config
```

---

## 🧪 Testing Your Upgrade

### Test 1: Security Validation Works
```bash
# Try to source a config owned by wrong user (should be rejected)
touch /tmp/test-config
sudo chown root /tmp/test-config
cp /tmp/test-config ~/.config/umu-game-installer/config
umu-game-installer --help 2>&1 | grep -i "skipping"
# Expected: "Skipping .../config: not owned by current user"

# Restore your config
mv ~/.config/umu-game-installer/config.backup ~/.config/umu-game-installer/config
```

### Test 2: Games Still Work
```bash
# List your games
umu-game-manager list

# Try launching a game
umu-game-manager launch "YourGameName"
```

### Test 3: New Installations Work
```bash
# Try installing a test game
# (with a simple installer you can cancel)
umu-game-installer ~/Downloads/test-setup.exe
# Cancel after the installer window appears
```

---

## 🐛 Troubleshooting

### Issue: "Command not found: umu-game-installer"

**Solution:**
```bash
# Ensure ~/.local/bin is in your PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Games list is empty after upgrade

**Solution:**
```bash
# Restore your backup
cp ~/.config/umu-game-installer/games.db.backup ~/.config/umu-game-installer/games.db

# Verify
umu-game-manager list
```

### Issue: Config warnings on every run

**Solution:**
```bash
# Fix config file ownership
chown $(id -u):$(id -g) ~/.config/umu-game-installer/config

# Or remove config to use defaults
mv ~/.config/umu-game-installer/config ~/.config/umu-game-installer/config.old
```

### Issue: Steam shortcuts missing

**Solution:**
```bash
# Regenerate Steam shortcuts
for game in $(umu-game-manager list | grep "umu-" | awk '{print $2}'); do
    echo "Regenerating shortcut for $game"
    # The upgrade preserves launch scripts, so shortcuts should still work
done

# Restart Steam to refresh
killall steam
steam &
```

---

## 📋 What's Preserved During Upgrade

✅ **Preserved:**
- Installed games
- Games database
- Dependencies database  
- Configuration settings
- Launch scripts
- Desktop shortcuts
- Steam shortcuts

❌ **Not Preserved (Regenerated):**
- Script executables (umu-game-installer, umu-game-manager)
- System integration files (.desktop files)
- Context menu entries

---

## 🔄 Rollback (If Needed)

If you encounter issues and need to rollback:

### Step 1: Restore Old Scripts
```bash
# Copy back old scripts (if you saved them)
cp ~/old-scripts/umu-game-installer.sh ~/.local/bin/umu-game-installer
cp ~/old-scripts/umu-game-manager.sh ~/.local/bin/umu-game-manager
```

### Step 2: Restore Databases
```bash
cp ~/.config/umu-game-installer/games.db.backup ~/.config/umu-game-installer/games.db
cp ~/.config/umu-game-installer/deps.db.backup ~/.config/umu-game-installer/deps.db
```

### Step 3: Restore Config
```bash
cp ~/.config/umu-game-installer/config.backup ~/.config/umu-game-installer/config
```

⚠️ **Note:** Rollback leaves you vulnerable to security issues. Only rollback temporarily while reporting bugs.

---

## 📞 Getting Help

### Before Reporting Issues

1. Check you're running the latest version:
   ```bash
   umu-game-installer --version
   ```

2. Check the logs:
   ```bash
   tail -n 50 ~/.config/umu-game-installer/installer.log
   ```

3. Verify file permissions:
   ```bash
   ls -la ~/.config/umu-game-installer/
   ls -la ~/.local/bin/umu-game-installer*
   ```

### Reporting Issues

Include this information:
- UMU Game Installer version
- Operating system (e.g., SteamOS 3.5)
- Error messages from logs
- Steps to reproduce
- What you expected to happen

---

## ✅ Upgrade Checklist

Use this checklist to ensure a smooth upgrade:

- [ ] Backed up games database
- [ ] Backed up dependencies database
- [ ] Backed up configuration
- [ ] Downloaded latest version
- [ ] Ran system installer
- [ ] Verified version number
- [ ] Tested game list appears
- [ ] Verified config ownership
- [ ] Cleaned old temp files
- [ ] Tested launching a game
- [ ] Tested installing new game
- [ ] Confirmed Steam shortcuts work

---

## 📅 Future Updates

After this security update, follow these practices:

1. **Check for updates monthly:**
   ```bash
   cd ~/umu-game-installer
   git pull
   ./umu-system-installer.sh
   ```

2. **Subscribe to security notifications:**
   - Watch the GitHub repository
   - Enable release notifications

3. **Keep backups:**
   - Backup your databases weekly
   - Store backups in a safe location

4. **Test new versions:**
   - Test in a non-production environment first
   - Read CHANGELOG.md before upgrading

---

**Upgrade Date:** _______________  
**Upgraded By:** _______________  
**Version After Upgrade:** _______________  
**Issues Encountered:** _______________

---

**Last Updated:** 2026-06-25  
**Document Version:** 1.0
