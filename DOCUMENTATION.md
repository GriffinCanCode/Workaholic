# Workaholic - System Optimization Tool Documentation

## Overview

**Workaholic** is a macOS system optimization script that performs comprehensive cleanup and performance optimization while preserving specified applications. It combines practical system maintenance with entertaining visual effects (Matrix-style animations, rainbow text, terminal transparency).

## What Does It Do?

### Core Functionality

The program performs 7 major operations in sequence:

1. **Application Management** - Closes all running apps except whitelisted ones
2. **Cache Clearing** - Removes temporary files and cache data
3. **System Maintenance** - Runs system health and maintenance tasks
4. **Disk Optimization** - Cleans up disk space by removing unnecessary files
5. **Memory Optimization** - Frees up RAM and optimizes memory usage
6. **Network Optimization** - Clears DNS cache and optimizes TCP settings
7. **Application Optimization** - Clears application-specific caches

### Visual Effects

- Matrix-style "rain" effect with colorful characters
- Terminal transparency fading effects
- Rainbow-colored text
- Progress bars and animated cleaning indicators
- Before/after memory statistics display

---

## What Is It Clearing?

### 1. System Caches (`clear_system_cache()`)

**User-level caches:**
- `~/Library/Caches` - General application cache directory
- `~/Library/Logs` - System and application log files
- `~/Downloads/*.log` and `~/Downloads/*.tmp` - Temporary download files

**Browser caches:**
- Chrome: `~/Library/Application Support/Google/Chrome/Default/Cache`
- Chrome Code Cache: `~/Library/Application Support/Google/Chrome/Default/Code Cache`
- Firefox: `~/Library/Application Support/Firefox/Profiles/*/cache2`
- Safari: `~/Library/Caches/com.apple.Safari`

**Application-specific caches:**
- Spotify: `~/Library/Application Support/Spotify/PersistentCache`

**Developer caches:**
- Xcode DerivedData: `~/Library/Developer/Xcode/DerivedData`
- Xcode Archives: `~/Library/Developer/Xcode/Archives`
- CoreSimulator Caches: `~/Library/Developer/CoreSimulator/Caches`

### 2. DNS Cache (`clear_dns_cache()`)

Clears the system DNS cache using:
- `dscacheutil -flushcache`
- Restarts mDNSResponder service

### 3. Application Caches (`optimize_applications()`)

Clears additional application caches:
- `~/Library/Containers/*/Data/Library/Caches/*`
- `~/Library/Application Support/*/Cache/*`
- `~/Library/Caches/com.apple.*`

### 4. Disk Space Cleanup (`optimize_disk_space()`)

Removes:
- All items in `~/Library/Caches/*`
- Old iOS backups: `~/Downloads/*/MobileSync/Backup`
- Old software updates: `/Library/Updates/*`

### 5. Memory Optimization (`optimize_memory()`)

Executes:
- `purge` - Clears filesystem cache and frees inactive memory
- `sync` - Syncs filesystem buffers to disk

### 6. Network Cache (`optimize_network()`)

Clears network-related caches and optimizes TCP:
- DNS cache flush (dscacheutil, mDNSResponder)
- TCP delayed ACK disabled
- TCP MSS set to 1460

### 7. System Maintenance Tasks (`run_maintenance_tasks()`)

Performs various system health checks:
- Updates dyld shared cache
- Checks for critical software updates
- Verifies system packages
- Verifies disk volume integrity
- Rebuilds kernel extension cache
- Prevents `.DS_Store` file creation on network volumes

---

## Application Management

### Default Protected Applications

By default, these apps are **NOT** closed:
- Google Chrome
- Cursor
- Terminal

### Environment Variable Configuration

You can customize protected apps via `.env` file:
```bash
KEEP_APPS=Google Chrome,Cursor,Terminal,Slack,Discord
```

### Command-Line Flags

**`ft` flag** - Keep FaceTime and Zoom open:
```bash
./workaholic ft
```

**`leave` flag** - Keep a specific application open:
```bash
./workaholic leave Spotify
./workaholic leave "Visual Studio Code"
```

**`help` or `h` flag** - Display help message:
```bash
./workaholic help
```

---

## How It Works (Technical Flow)

### 1. Initialization
```python
# Load environment from .env file
load_environment()

# Get sudo password from environment
SUDO_PASSWORD = get_sudo_password()
```

### 2. Password Management
- Reads `SUDO_PASSWORD` from `.env` file (created via `internal/load_environment.py`)
- Uses `-S` flag with sudo to pass password via stdin
- All privileged commands run non-interactively

### 3. Safe File Removal
```python
def safe_remove(path):
    # Checks write permissions before removal
    # Handles directories recursively
    # Gracefully handles permission errors
    # Continues on failure rather than crashing
```

### 4. Command Execution
```python
def run_command(command):
    # Detects sudo commands
    # Injects password via stdin
    # Captures stdout/stderr
    # Returns output or empty string on error
```

### 5. Visual Effects System
- **Matrix Effect**: Uses `curses` library for terminal graphics
- **Terminal Transparency**: Uses AppleScript to control Terminal.app
- **Color System**: ANSI escape codes for colored output
- **Progress Bars**: Unicode block characters for visual progress

---

## Rebuilding from First Principles

### Core Design Philosophy

When rebuilding this tool, consider these principles:

#### 1. **Safety First**
- Always check permissions before deletion
- Use user-level paths, avoid system directories
- Graceful degradation (continue on error)
- Create logs of all operations
- Never force-delete without permission checks

#### 2. **Non-Interactive Execution**
- Store credentials securely (environment variables)
- All sudo commands must be non-interactive
- Support command-line flags for configuration

#### 3. **Reversibility**
- Only clear caches and temporary files
- Avoid deleting user data or configurations
- Keep logs of what was cleaned

#### 4. **Visibility**
- Show before/after statistics
- Display what's being cleaned in real-time
- Provide progress indicators

### Recommended Architecture

```
workaholic/
├── internal/
│   ├── load_environment.py      # Environment variable management
│   └── __init__.py
├── modules/
│   ├── cache_cleaner.py         # Cache clearing logic
│   ├── app_manager.py           # Application lifecycle management
│   ├── memory_optimizer.py      # Memory optimization
│   ├── network_optimizer.py     # Network optimization
│   ├── disk_optimizer.py        # Disk optimization
│   └── visual_effects.py        # All visual effects
├── utils/
│   ├── command_runner.py        # Sudo command execution
│   ├── safe_delete.py           # Safe file/directory removal
│   └── logger.py                # Logging utilities
├── .env.example                 # Template environment file
├── workaholic                   # Main executable script
├── DOCUMENTATION.md             # This file
└── README.md                    # Quick start guide
```

### Implementation Steps (First Principles)

#### Phase 1: Core Infrastructure
1. **Command Runner**
   - Non-interactive sudo execution
   - Error handling and logging
   - Output capture

2. **Safe File Operations**
   - Permission checking
   - Recursive directory handling
   - Error recovery

3. **Environment Management**
   - `.env` file parsing
   - Environment variable validation
   - Secure password handling

#### Phase 2: Cleanup Modules
1. **Cache Discovery**
   - Enumerate cache directories
   - Calculate sizes before deletion
   - Categorize by safety level

2. **Smart Deletion**
   - Delete by category (safest first)
   - Skip files in use
   - Report what couldn't be deleted

3. **Application Management**
   - Discover running applications
   - Filter by whitelist
   - Gracefully quit (not force-quit)

#### Phase 3: Optimization Modules
1. **Memory Optimization**
   - Measure memory before/after
   - Use system-appropriate commands
   - Validate improvements

2. **Network Optimization**
   - DNS cache clearing
   - TCP parameter tuning
   - Connection pool cleanup

3. **Disk Optimization**
   - Find duplicate files
   - Compress old logs
   - Remove old downloads

#### Phase 4: User Experience
1. **Visual Feedback**
   - Real-time progress
   - Color-coded status messages
   - Summary statistics

2. **Interactive Mode**
   - Confirm before destructive operations
   - Preview what will be deleted
   - Select categories to clean

3. **Dry-Run Mode**
   - Show what would be deleted
   - Calculate space to be freed
   - No actual deletion

### Key Improvements for Rebuild

#### 1. **Configuration System**
```python
# config.yaml
cleaning:
  categories:
    - name: browser_caches
      enabled: true
      paths:
        - ~/Library/Caches/com.apple.Safari
        - ~/Library/Application Support/Google/Chrome/Default/Cache
      risk_level: low
    
    - name: developer_caches
      enabled: true
      paths:
        - ~/Library/Developer/Xcode/DerivedData
      risk_level: medium
      
  protected_apps:
    - Google Chrome
    - Terminal
    - Cursor
```

#### 2. **Size Calculation Before Deletion**
```python
def calculate_cleanup_size(paths):
    """Calculate total size before deletion."""
    total_size = 0
    for path in paths:
        total_size += get_directory_size(path)
    return format_bytes(total_size)
```

#### 3. **Undo Capability**
```python
def create_snapshot(paths):
    """Create metadata snapshot before deletion."""
    snapshot = {
        'timestamp': datetime.now(),
        'deleted_files': [],
        'sizes': {}
    }
    # Store file list and sizes
    return snapshot

def undo_cleanup(snapshot_id):
    """Inform user what was deleted (can't actually restore)."""
    pass
```

#### 4. **Scheduling System**
```python
# Run automatically on schedule
@schedule.every().day.at("02:00")
def scheduled_cleanup():
    workaholic.run(auto_mode=True)
```

#### 5. **Web Dashboard**
```python
# Flask/FastAPI web interface
# View cleanup history
# Configure settings
# Schedule cleanups
# View statistics
```

#### 6. **Safety Levels**
```python
SAFETY_LEVELS = {
    'conservative': {
        'only_caches': True,
        'skip_apps': True,
        'confirm_each': True
    },
    'balanced': {  # Default
        'clear_caches': True,
        'close_apps': True,
        'optimize_memory': True
    },
    'aggressive': {
        'clear_everything': True,
        'force_quit_apps': True,
        'deep_clean': True
    }
}
```

### Testing Strategy

#### Unit Tests
```python
def test_safe_remove():
    # Test permission checking
    # Test recursive deletion
    # Test error handling
    pass

def test_app_filtering():
    # Test whitelist matching (case-insensitive)
    # Test command-line flag parsing
    pass
```

#### Integration Tests
```python
def test_full_cleanup_cycle():
    # Run in dry-run mode
    # Verify no actual deletion occurred
    # Check all commands generated correctly
    pass
```

#### Safety Tests
```python
def test_never_delete_user_data():
    # Ensure no Documents, Desktop, etc.
    # Verify only cache directories
    pass
```

---

## Security Considerations

### Current Implementation
- Password stored in `.env` (plaintext)
- Passed via stdin to sudo (not visible in process list)
- `.env` should have 0600 permissions

### Improvements for Production
1. **macOS Keychain Integration**
   ```python
   import keyring
   password = keyring.get_password("workaholic", "sudo")
   ```

2. **Touch ID Integration**
   ```bash
   # Use sudo with Touch ID (configured via pam)
   sudo -i
   ```

3. **Privilege Separation**
   - Run as daemon with elevated privileges
   - Main script runs as user
   - IPC for privileged operations

4. **Audit Logging**
   ```python
   # Log all privileged operations
   audit_log.info(f"User {user} executed {command} at {timestamp}")
   ```

---

## Performance Considerations

### Current Performance
- Sequential operation execution
- Blocking I/O for file deletion
- No parallelization

### Optimization Opportunities

#### 1. **Parallel Deletion**
```python
from concurrent.futures import ThreadPoolExecutor

def parallel_cleanup(paths):
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(safe_remove, path) for path in paths]
        results = [f.result() for f in futures]
```

#### 2. **Smart Caching**
```python
# Cache directory sizes
# Skip empty directories
# Remember what was already clean
```

#### 3. **Incremental Cleaning**
```python
# Only clean what's grown since last run
# Track last cleanup timestamp per directory
```

---

## Platform Compatibility

### Current: macOS Only
- Uses `osascript` (AppleScript)
- Uses `vm_stat`, `purge` (macOS commands)
- Uses macOS-specific paths

### Cross-Platform Considerations

#### Linux Adaptation
```python
def clear_cache_linux():
    paths = [
        "~/.cache",
        "~/.local/share/Trash",
        "/var/tmp",
        "/tmp"
    ]
```

#### Windows Adaptation
```python
def clear_cache_windows():
    paths = [
        "%TEMP%",
        "%LocalAppData%\\Temp",
        "%ProgramData%\\Temp"
    ]
```

---

## Common Issues and Solutions

### Issue 1: Permission Denied Errors
**Cause**: Script doesn't have permission to delete certain files  
**Solution**: The script already handles this gracefully with `safe_remove()`  
**Improvement**: Add option to show list of files that couldn't be deleted

### Issue 2: Apps Re-opening Automatically
**Cause**: macOS app restoration feature  
**Solution**: Disable in System Preferences or add to script:
```python
run_command("defaults write com.apple.loginwindow TALLogoutSavesState -bool false")
```

### Issue 3: Sudo Password Prompt
**Cause**: `SUDO_PASSWORD` not set in `.env`  
**Solution**: Create `.env` file with password  
**Security Note**: Ensure `.env` has 0600 permissions

### Issue 4: Terminal Transparency Not Working
**Cause**: Different terminal emulator (not Terminal.app)  
**Solution**: Script silently fails - visual effects are optional  
**Improvement**: Detect terminal emulator and adapt

---

## Future Enhancements

### 1. Machine Learning-Based Cleanup
- Learn user patterns
- Predict what can be safely deleted
- Suggest cleanup opportunities

### 2. Cloud Integration
- Sync settings across machines
- Aggregate statistics
- Compare performance with similar systems

### 3. Smart Scheduling
- Run during low-activity periods
- Pause if user is active
- Adjust frequency based on cleanup yield

### 4. Application Profiles
```yaml
profiles:
  developer:
    keep_apps: [Cursor, Terminal, Chrome, Slack]
    aggressive_clean: [Xcode caches, node_modules]
  
  creative:
    keep_apps: [Photoshop, Illustrator, Chrome]
    aggressive_clean: [Adobe caches, Lightroom previews]
```

### 5. Notification System
```python
# macOS notification when cleanup completes
osascript -e 'display notification "Freed 5.2 GB" with title "Workaholic Complete"'
```

### 6. Health Score System
```python
def calculate_health_score():
    factors = {
        'free_disk_space': 0.3,
        'free_memory': 0.25,
        'cache_size': 0.2,
        'running_apps': 0.15,
        'last_cleanup': 0.1
    }
    return weighted_score(factors)
```

---

## Conclusion

**Workaholic** is a practical system maintenance tool that combines functionality with entertainment. When rebuilding from first principles, focus on:

1. **Safety** - Never delete user data
2. **Transparency** - Always show what's being done
3. **Configurability** - Let users control behavior
4. **Reliability** - Handle errors gracefully
5. **Performance** - Run efficiently
6. **Security** - Protect credentials and audit actions

The current implementation is a solid foundation that can be extended with the modular architecture and improvements outlined in this document.

---

## Quick Reference

### What Gets Cleaned
- ✅ Browser caches (Chrome, Firefox, Safari)
- ✅ Application caches
- ✅ System logs
- ✅ Developer build artifacts (Xcode)
- ✅ DNS cache
- ✅ Memory (inactive pages)
- ✅ Network connection cache
- ✅ Temporary files

### What Is Protected
- ❌ User documents
- ❌ Application settings
- ❌ Passwords and keychain
- ❌ Application data
- ❌ System files
- ❌ Whitelisted running applications

### Commands Used
- `sudo purge` - Clear memory
- `sudo dscacheutil -flushcache` - Clear DNS
- `sudo killall -HUP mDNSResponder` - Restart DNS
- `osascript` - Control applications
- `vm_stat` - View memory statistics
- Various `sysctl` commands for network tuning

### Exit Codes
- `0` - Success
- `1` - Error during optimization
- Exits on missing `SUDO_PASSWORD`

