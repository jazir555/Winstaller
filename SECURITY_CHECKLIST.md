# Security Checklist for UMU Game Installer

## Quick Reference for Developers

This checklist ensures security best practices are followed when modifying the UMU Game Installer scripts.

---

## ✅ Code Review Checklist

### 1. Variable Expansion
- [ ] **Never use `eval` with user-controlled data**
  - ❌ BAD: `eval "local var=\${$user_input}"`
  - ✅ GOOD: `local var="${!user_input}"`

- [ ] **Use indirect expansion for dynamic variable names**
  - Use `${!varname}` instead of `eval`

### 2. Configuration Files
- [ ] **Always validate file ownership before sourcing**
  ```bash
  # Check if config is owned by root (for system configs)
  [ "$(stat -c %u "$config" 2>/dev/null)" = "0" ]
  
  # Check if config is owned by current user (for user configs)
  [ "$(stat -c %u "$config" 2>/dev/null)" = "$(id -u)" ]
  ```

- [ ] **Never source config files blindly**

### 3. Downloaded Files
- [ ] **Calculate checksums BEFORE execution**
- [ ] **Log checksums for audit trail**
- [ ] **Verify checksums against whitelist (when available)**
- [ ] **Never execute files before integrity check**

### 4. Temporary Files
- [ ] **Register all temp files for cleanup**
  ```bash
  local temp=$(mktemp)
  TEMP_FILES_TO_CLEANUP+=("$temp")
  ```

- [ ] **Set up trap handler at script start**
  ```bash
  trap cleanup_temp_files EXIT
  ```

### 5. Input Validation
- [ ] **Sanitize all user inputs**
- [ ] **Validate file paths before use**
- [ ] **Check for path traversal attempts (../ sequences)**
- [ ] **Escape special characters in shell commands**

### 6. Integer Handling
- [ ] **Use appropriate integer types**
  - Unsigned for IDs: `struct.pack("<I", value)`
  - Signed for counts/deltas: `struct.pack("<i", value)`

- [ ] **Check for integer overflow**
- [ ] **Validate range before packing/unpacking**

### 7. Error Handling
- [ ] **Use `set -euo pipefail` at script start**
- [ ] **Handle errors gracefully**
- [ ] **Clean up resources on error**
- [ ] **Log errors for debugging**

---

## 🔒 Security Patterns

### Safe Variable Expansion
```bash
# SECURE: Indirect expansion
setting="AUTO_INSTALL_DEPS"
value="${!setting}"

# INSECURE: eval
eval "value=\${$setting}"  # ❌ Don't do this
```

### Safe Config Loading
```bash
# SECURE: Validate before source
if [ -f "$config" ]; then
    if [ "$(stat -c %u "$config")" = "$(id -u)" ]; then
        source "$config"
    else
        warn "Skipping $config: wrong owner"
    fi
fi

# INSECURE: Direct source
source "$config"  # ❌ Don't do this
```

### Safe File Execution
```bash
# SECURE: Verify before execute
checksum=$(sha256sum "$file" | cut -d' ' -f1)
log "Checksum: $checksum"
# TODO: verify against whitelist
umu-run "$file"

# INSECURE: Execute then verify
umu-run "$file"
checksum=$(sha256sum "$file" | cut -d' ' -f1)  # ❌ Too late!
```

### Safe Temp File Handling
```bash
# SECURE: Register for cleanup
TEMP_FILES_TO_CLEANUP=()
trap cleanup_temp_files EXIT

temp_dir=$(mktemp -d)
TEMP_FILES_TO_CLEANUP+=("$temp_dir")

# INSECURE: No cleanup
temp_dir=$(mktemp -d)  # ❌ Will leak if script fails
```

---

## 🚨 Common Pitfalls

### 1. Command Injection
**Vulnerable Code:**
```bash
game_name="My Game"
game_id="umu-$(echo $game_name | tr ' ' '-')"
eval "local setting=\${OVERRIDE_${game_id}_DEPS}"  # ❌ INJECTION!
```

**Attack:**
```bash
game_name='$(rm -rf ~)'  # Executes when eval runs
```

**Fix:**
```bash
local setting="${!override_var}"  # ✅ Safe
```

### 2. TOCTOU (Time-of-Check-Time-of-Use)
**Vulnerable Code:**
```bash
if [ -f "$installer" ]; then  # Check
    sleep 1
    umu-run "$installer"       # Use - file could change!
fi
```

**Fix:**
```bash
# Verify integrity immediately before use
checksum=$(sha256sum "$installer" | cut -d' ' -f1)
umu-run "$installer"
```

### 3. Integer Overflow
**Vulnerable Code:**
```python
# Steam can generate IDs > 2^31
shortcut_id = struct.pack("<i", steam_id)  # ❌ Overflow!
```

**Fix:**
```python
# Use unsigned int
shortcut_id = struct.pack("<I", steam_id)  # ✅ 0 to 2^32-1
```

### 4. Resource Leaks
**Vulnerable Code:**
```bash
temp_file=$(mktemp)
# If script crashes here, temp_file leaks
do_something
rm "$temp_file"
```

**Fix:**
```bash
TEMP_FILES_TO_CLEANUP+=("$(mktemp)")
trap cleanup_temp_files EXIT
# Cleanup happens automatically
```

---

## 🔍 Testing Security Fixes

### Test 1: Command Injection
```bash
# Try to inject commands through game names
./umu-game-installer.sh --gui 'setup.exe'
# When prompted, enter: $(whoami)
# Expected: Game installs with literal name, no command execution
```

### Test 2: Config Security
```bash
# Create malicious config
echo "rm -rf ~/test-dir" > ~/.config/umu-game-installer/config
sudo chown root ~/.config/umu-game-installer/config
./umu-game-installer.sh setup.exe
# Expected: Warning about wrong owner, config skipped
```

### Test 3: Checksum Timing
```bash
# Monitor logs
tail -f ~/.config/umu-game-installer/installer.log | grep -i checksum
# Expected: "Checksum: ..." BEFORE "Installing dependency..."
```

### Test 4: Cleanup
```bash
# Count temp files before
before=$(ls /tmp | wc -l)
# Start installation and kill it
./umu-game-installer.sh setup.exe &
PID=$!
sleep 5
kill $PID
# Count temp files after
after=$(ls /tmp | wc -l)
# Expected: after <= before (no leaks)
```

---

## 📚 References

- **CWE-78:** OS Command Injection
- **CWE-94:** Code Injection  
- **CWE-367:** Time-of-Check Time-of-Use (TOCTOU)
- **CWE-190:** Integer Overflow
- **CWE-459:** Incomplete Cleanup

---

## ✅ Pre-Commit Checklist

Before committing code changes:

1. [ ] Reviewed for `eval` usage with user data
2. [ ] Checked config file sourcing has ownership validation
3. [ ] Verified checksums calculated before file execution
4. [ ] Confirmed temp files registered for cleanup
5. [ ] Validated integer types for packing/unpacking
6. [ ] Tested error conditions and cleanup
7. [ ] Ran shellcheck on all modified scripts
8. [ ] Updated security documentation if needed

---

## 🔄 Continuous Security

### Regular Tasks
- Weekly: Review new code for security issues
- Monthly: Re-run security tests
- Quarterly: Update dependency checksums whitelist
- Annually: Full security audit

### Monitoring
- Monitor logs for unusual patterns
- Track failed integrity checks
- Alert on config validation failures
- Review temp file cleanup success rate

---

**Last Updated:** 2026-06-25  
**Version:** 1.0
