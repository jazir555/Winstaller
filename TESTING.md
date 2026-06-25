# Testing Guide

This guide helps you test the UMU Game Installer before using it with real games.

## Pre-Flight Checks

### 1. Verify Prerequisites

```bash
# Check umu-run is installed
which umu-run
umu-run --version

# Check Wine is available through umu
umu-run --help

# Verify directories
ls -la ~/.config/umu-game-installer/ 2>/dev/null || echo "Config dir will be created on first run"
ls -la ~/Games/ 2>/dev/null || echo "Games dir will be created on first run"
```

### 2. Test Basic Script Functionality

```bash
# Test help output
./umu-game-installer.sh --help

# Test version
./umu-game-installer.sh --version

# Test manager
./umu-game-manager.sh --help
```

## Test with Sample Applications

### Test 1: Simple Windows Application

Download a small, free Windows application to test:

```bash
# Download Notepad++ installer (small, safe, free)
curl -L https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5.8/npp.8.5.8.Installer.exe -o ~/Downloads/npp-installer.exe

# Test installation
./umu-game-installer.sh ~/Downloads/npp-installer.exe

# Follow prompts:
# Enter game name: Notepad++
# Install dependencies? (Y/n): n  (Notepad++ doesn't need special deps)

# GUI installer should appear
# - Accept license
# - Choose install location (e.g., /home/deck/Games/NotepadPlusPlus)
# - Complete installation

# After installation:
# - Script should detect npp.exe or similar
# - Confirm or select manually

# Verify installation
umu-game-manager list
# Should show "Notepad++"

# Test launch
umu-game-manager launch "Notepad++"
# Notepad++ should open
```

### Test 2: Application with Dependencies

Create a mock dependency installer:

```bash
# Download VC++ Redist (common dependency)
curl -L https://aka.ms/vs/17/release/vc_redist.x64.exe -o ~/Downloads/vcredist_x64.exe

# Install dependency
./umu-game-installer.sh ~/Downloads/vcredist_x64.exe

# The dependency detection should trigger
# Follow silent install process

# Verify dependency registered
./umu-game-installer.sh --list-deps
# Should show vcredist 2022

# Check dependency database
cat ~/.config/umu-game-installer/deps.db
```

### Test 3: Portable Application (No Installer)

Test with a portable Windows app:

```bash
# Download a portable app (example: Foobar2000 portable)
curl -L https://www.foobar2000.org/files/foobar2000_v2.0_portable.zip -o ~/Downloads/foobar_portable.zip

# Extract
unzip ~/Downloads/foobar_portable.zip -d ~/Downloads/foobar

# Manually set up (installer script won't detect portable apps automatically)
mkdir -p ~/Games/Foobar2000
cp -r ~/Downloads/foobar/* ~/Games/Foobar2000/

# Create Wine prefix
WINEPREFIX=~/Games/Foobar2000/prefix GAMEID=umu-foobar umu-run wineboot --init

# Create launch script
cat > ~/.config/umu-game-installer/launch_umu-foobar.sh << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/Games/Foobar2000/prefix"
export GAMEID="umu-foobar"
exec umu-run "$HOME/Games/Foobar2000/foobar2000.exe" "$@"
EOF

chmod +x ~/.config/umu-game-installer/launch_umu-foobar.sh

# Test launch
~/.config/umu-game-installer/launch_umu-foobar.sh
```

## Automated Test Suite

### Create Test Script

```bash
cat > test-umu-installer.sh << 'EOF'
#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

echo "UMU Game Installer Test Suite"
echo "=============================="
echo ""

# Test 1: Check scripts exist
echo "Test 1: Script files exist"
if [ -f "./umu-game-installer.sh" ] && [ -f "./umu-game-manager.sh" ]; then
    test_pass "Scripts found"
else
    test_fail "Scripts not found"
fi

# Test 2: Check scripts are executable
echo "Test 2: Scripts are executable"
if [ -x "./umu-game-installer.sh" ] && [ -x "./umu-game-manager.sh" ]; then
    test_pass "Scripts are executable"
else
    test_fail "Scripts are not executable"
    echo "Run: chmod +x *.sh"
fi

# Test 3: Check umu-run availability
echo "Test 3: umu-run is available"
if command -v umu-run &> /dev/null; then
    test_pass "umu-run found in PATH"
else
    test_fail "umu-run not found"
    echo "Install umu-run first"
fi

# Test 4: Check help output
echo "Test 4: Help output works"
if ./umu-game-installer.sh --help &> /dev/null; then
    test_pass "Help output works"
else
    test_fail "Help output failed"
fi

# Test 5: Check version output
echo "Test 5: Version output works"
if ./umu-game-installer.sh --version &> /dev/null; then
    test_pass "Version output works"
else
    test_fail "Version output failed"
fi

# Test 6: Check directory creation
echo "Test 6: Configuration directory"
./umu-game-installer.sh --help > /dev/null 2>&1
if [ -d "$HOME/.config/umu-game-installer" ]; then
    test_pass "Config directory created"
else
    test_fail "Config directory not created"
fi

# Test 7: Check dependency database
echo "Test 7: Dependency database"
if [ -f "$HOME/.config/umu-game-installer/deps.db" ]; then
    test_pass "Dependency database created"
else
    test_fail "Dependency database not created"
fi

# Test 8: Check games database
echo "Test 8: Games database"
./umu-game-manager.sh list > /dev/null 2>&1
if [ -f "$HOME/.config/umu-game-installer/games.db" ]; then
    test_pass "Games database created"
else
    test_fail "Games database not created"
fi

# Test 9: Check default install root
echo "Test 9: Default install root"
if [ -d "$HOME/Games" ] || mkdir -p "$HOME/Games"; then
    test_pass "Default install root available"
else
    test_fail "Cannot create default install root"
fi

# Test 10: Check Wine through umu-run
echo "Test 10: Wine via umu-run"
if GAMEID=test umu-run wineboot --version &> /dev/null; then
    test_pass "Wine works through umu-run"
else
    test_fail "Wine not working through umu-run"
fi

echo ""
echo "=============================="
echo "Test Results"
echo "=============================="
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Ready to install games.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please fix issues before proceeding.${NC}"
    exit 1
fi
EOF

chmod +x test-umu-installer.sh
```

### Run Tests

```bash
./test-umu-installer.sh
```

Expected output:
```
UMU Game Installer Test Suite
==============================

Test 1: Script files exist
✓ PASS: Scripts found
Test 2: Scripts are executable
✓ PASS: Scripts are executable
Test 3: umu-run is available
✓ PASS: umu-run found in PATH
...
==============================
Test Results
==============================
Passed: 10
Failed: 0

All tests passed! Ready to install games.
```

## Integration Tests

### Test Full Installation Flow

```bash
# Create a test installer (mock)
# We'll use a real small Windows app for realistic testing

# Test with 7-Zip (small, free, safe)
curl -L https://www.7-zip.org/a/7z2201-x64.exe -o ~/Downloads/7zip-installer.exe

# Run full installation test
./umu-game-installer.sh ~/Downloads/7zip-installer.exe

# Verify each step:
# 1. Prefix creation
ls -la ~/Games/7-Zip/prefix/

# 2. Database entry
grep "7-Zip" ~/.config/umu-game-installer/games.db

# 3. Launch script
ls -la ~/.config/umu-game-installer/launch_umu-7-zip.sh

# 4. Desktop file
ls -la ~/.local/share/applications/umu-7-zip.desktop

# 5. Desktop shortcut
ls -la ~/Desktop/7-Zip.desktop

# 6. Can launch
umu-game-manager launch "7-Zip"
```

### Test Dependency Sharing

```bash
# Install first game with VC++ 2019
# (Use a real game installer that includes vcredist)

# Check dependency installed
./umu-game-installer.sh --list-deps | grep vcredist

# Install second game that needs same dependency
# It should detect and skip reinstallation

# Verify in logs:
# "Dependency vcredist 2019 already installed, skipping..."
```

### Test Uninstallation

```bash
# Install test app
./umu-game-installer.sh ~/Downloads/test-app.exe

# Verify installation
umu-game-manager list

# Uninstall
umu-game-manager uninstall "Test App"

# Verify removal
umu-game-manager list | grep -i "test app" && echo "Still there!" || echo "Removed successfully"

# Check files removed
ls -la ~/Games/TestApp/ 2>/dev/null && echo "Files still there!" || echo "Files removed"
```

## Performance Tests

### Measure Installation Time

```bash
# Time a full installation
time ./umu-game-installer.sh ~/Downloads/game-installer.exe

# Expected:
# - Small app (< 100MB): 2-5 minutes
# - Medium app (100MB-1GB): 5-15 minutes
# - Large game (> 1GB): 15+ minutes
```

### Measure Disk Usage

```bash
# Check before
du -sh ~/Games/
du -sh ~/.config/umu-game-installer/

# Install game
./umu-game-installer.sh game-installer.exe

# Check after
du -sh ~/Games/
du -sh ~/.config/umu-game-installer/

# Compare
umu-game-manager disk
```

## Stress Tests

### Install Multiple Games

```bash
# Install 5-10 small games
for i in {1..5}; do
    ./umu-game-installer.sh ~/Downloads/game${i}.exe
done

# Verify all installed
umu-game-manager list

# Check dependencies shared
./umu-game-installer.sh --list-deps
```

### Concurrent Installations

```bash
# Try installing two games simultaneously (not recommended, but good stress test)
./umu-game-installer.sh game1.exe &
./umu-game-installer.sh game2.exe &

wait

# Check for conflicts
umu-game-manager list
```

## Compatibility Tests

### Test on Different Systems

If possible, test on:

1. **Steam Deck (SteamOS)**
   ```bash
   uname -a
   # Should show SteamOS
   
   ./test-umu-installer.sh
   ```

2. **Arch Linux**
   ```bash
   ./test-umu-installer.sh
   ```

3. **Ubuntu/Debian**
   ```bash
   ./test-umu-installer.sh
   ```

4. **Fedora**
   ```bash
   ./test-umu-installer.sh
   ```

## Regression Tests

### After Script Updates

```bash
# 1. Backup test environment
tar -czf test-backup.tar.gz ~/Games ~/.config/umu-game-installer/

# 2. Update scripts
git pull  # or download new versions

# 3. Run test suite
./test-umu-installer.sh

# 4. Test existing game launches
umu-game-manager list
umu-game-manager launch "Existing Game"

# 5. Test new installation
./umu-game-installer.sh ~/Downloads/new-game.exe

# 6. If issues, restore backup
tar -xzf test-backup.tar.gz -C ~/
```

## Bug Reporting Template

When reporting issues, include:

```bash
# System info
uname -a
umu-run --version

# Script version
./umu-game-installer.sh --version

# Test results
./test-umu-installer.sh

# Error logs
cat ~/.config/umu-game-installer/installer.log

# Game info
umu-game-manager info "Game Name"

# Dependency info
./umu-game-installer.sh --list-deps
```

## Cleanup After Testing

```bash
# Remove test games
umu-game-manager uninstall "Notepad++"
umu-game-manager uninstall "7-Zip"

# Or clean everything
rm -rf ~/Games/
rm -rf ~/.config/umu-game-installer/
rm -f ~/.local/share/applications/umu-*.desktop
rm -f ~/Desktop/*.desktop  # Be careful!

# Fresh start
./umu-game-installer.sh --help
```

## Success Criteria

✅ All automated tests pass
✅ Can install a real Windows application
✅ Application launches successfully
✅ Dependencies are detected and installed
✅ Dependencies are shared between games
✅ Games appear in Steam/application menu
✅ Desktop shortcuts work
✅ Games can be uninstalled cleanly
✅ No orphaned files after uninstallation

---

If all tests pass, you're ready to install real games! 🎮
