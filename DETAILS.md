# utils.fish - Complete Usage Guide

This document provides comprehensive usage instructions for all functions in the utils.fish collection.

## Archive Operations

### extract - Universal Archive Extractor

Extract archives with support for 20+ formats including advanced options for listing, testing, and batch processing.

**Basic Usage:**

```fish
extract archive.tar.gz                 # Extract single archive
extract file1.zip file2.rar file3.7z   # Extract multiple archives
```

**Advanced Options:**

```fish
extract --help                         # Show detailed help
extract -q archive.zip                 # Quiet mode (no verbose output)
extract -l archive.tar.bz2             # List contents without extracting
extract -t archive.rar                 # Test archive integrity
extract --list *.tar.gz                # List contents of multiple archives
extract --test --quiet *.zip           # Test multiple archives silently
```

**Features:**

- **Batch Processing**: Extract multiple archives in one command
- **Progress Indication**: Shows file sizes and extraction progress
- **Error Handling**: Continues processing other files if one fails
- **Integrity Testing**: Verify archives before extraction
- **Content Listing**: Preview archive contents
- **Safety Checks**: Validates file existence and format support

### extract_and_remove - Extract and Clean Up

Extract archives and automatically remove source files after successful extraction.

**Usage:**

```fish
xr archive.zip                         # Extract and remove (using alias)
extract_and_remove archive.tar.gz     # Full function name
extract_and_remove -q *.rar           # Batch extract and remove quietly
```

**Safety Features:**

- Only removes files after successful extraction
- Preserves original files if extraction fails
- Confirms each file removal
- Works with all extract options

### compress - Universal Compression Function

Compress files and directories to various formats with extensive customization options.

**Basic Usage:**

```fish
compress mydir                             # Create mydir.tar.gz
compress myfile.txt                        # Create myfile.txt.tar.gz
```

**Format Selection:**

```fish
compress -f zip mydir                      # Create mydir.zip
compress -f tar.bz2 mydir backup          # Create backup.tar.bz2
compress -f 7z mydir                       # Create mydir.7z
```

**Compression Levels:**

```fish
compress --fast mydir                      # Fastest compression (level 1)
compress --best mydir                      # Best compression (level 9)
compress -l 5 mydir                        # Custom level (1-9)
```

**Advanced Options:**

```fish
compress -e '*.tmp' mydir                  # Exclude temporary files
compress -e '*.log' -e '*.cache' mydir     # Multiple exclusion patterns
compress -q mydir                          # Quiet mode
compress --help                            # Show all options
```

**Supported Output Formats:**

- `tar.gz` (default) - Good balance of speed and compression
- `tar.bz2` - Better compression, slower
- `tar.xz` - Best compression, slowest  
- `tar.lz4` - Fastest compression, larger files
- `tar.zst` - Modern format, good speed/compression balance
- `zip` - Cross-platform compatibility
- `7z` - Excellent compression, many algorithms

## System Utilities

### kill_all - Enhanced Process Management

Kill processes matching keywords with safety features and graceful termination.

**Basic Usage:**

```fish
ka firefox                                 # Kill all Firefox (using alias)
kill_all chrome                           # Kill all Chrome processes
```

**Safety Options:**

```fish
kill_all -n python                        # Dry run - show what would be killed
kill_all -f nodejs                        # Force kill (SIGKILL immediately)
kill_all -9 hung_process                  # Same as --force
```

**Custom Signals:**

```fish
kill_all -s USR1 nginx                    # Send custom signal
kill_all -s HUP ssh                       # Reload configuration
```

**Process Information:**

- Shows PID, PPID, user, and command for each match
- Displays process count before killing
- Confirms action unless in force mode
- Graceful termination followed by SIGKILL if needed

### git_tag_push - Semantic Versioning and Git Tags

Create and push git tags with automatic version bumping and semantic versioning support.

**Automatic Versioning:**

```fish
gtp                                        # Auto-bump patch version (alias)
git_tag_push                               # Same as above
git_tag_push --patch                       # Explicit patch bump (1.0.0 → 1.0.1)
git_tag_push --minor                       # Minor bump (1.0.0 → 1.1.0)
git_tag_push --major                       # Major bump (1.0.0 → 2.0.0)
```

**Pre-release Tags:**

```fish
git_tag_push --pre beta                    # Create beta pre-release
git_tag_push --pre alpha --minor           # Minor bump with alpha suffix
```

**Custom Tags:**

```fish
git_tag_push v2.1.0                       # Specific version
git_tag_push v2.1.0 "Major release"       # With custom message
git_tag_push -f v1.0.0                    # Force overwrite existing tag
```

**Safety Features:**

```fish
git_tag_push --dry-run                     # Preview without creating
git_tag_push --dry-run --minor             # Preview version bump
```

**Automatic Features:**

- Generates release notes from recent commits
- Shows commit hash and statistics
- Prevents duplicate tags (unless forced)
- Pushes to origin automatically
- Displays tag information after creation

### mdc - Enhanced Directory Creation

Create directories and navigate to them with advanced features.

**Basic Usage:**

```fish
mdc project/src/components                 # Create nested dirs, cd to last
mdc -v ~/workspace/new-project             # Verbose mode
```

**Permission Control:**

```fish
mdc -m 755 public_dir                      # Set specific permissions
mdc -m 700 private_dir                     # Private directory
```

**Multiple Directories:**

```fish
mdc dir1 dir2 dir3                         # Create all, cd to dir3
mdc -v -m 755 shared/ private/ temp/       # With options
```

### du_sort - Directory Size Analysis

List directories by size with advanced sorting and filtering options.

**Basic Usage:**

```fish
dus                                        # Sort current dir by size (alias)
du_sort                                    # Full function name
du_sort /home /var /tmp                    # Multiple directories
```

**Sorting Options:**

```fish
du_sort -r                                 # Largest first (reverse)
du_sort -d 2                               # Scan 2 levels deep
du_sort -r -d 3                            # Combined options
```

**Filtering:**

```fish
du_sort -t 100M                            # Only show dirs > 100MB
du_sort -t 1G /home                        # Large directories in /home
du_sort -a                                 # Include hidden directories
```

**Output Control:**

```fish
du_sort -s                                 # Show summary statistics
du_sort --no-total                         # Hide total size line
du_sort -s -a -r                           # All options combined
```

### env_run - Environment File Processing

Load environment variables from .env files and run commands with those variables.

**Basic Usage:**

```fish
env_run npm start                          # Full function name
```

**Custom Files:**

```fish
env_run -f production.env python app.py   # Use specific env file
env_run -d config/ -f app.env npm start   # File in different directory
```

**Environment Management:**

```fish
env_run -s python app.py                  # Show loaded variables
env_run -v                                 # Validate .env file format
env_run --export                           # Export vars to current shell
```

**File Validation:**

```fish
env_run -v -f .env.example                # Check file format
env_run -s -v                              # Show vars and validate
```

**Supported .env Format:**

```bash
# Comments start with #
DATABASE_URL=postgresql://localhost:5432/myapp
API_KEY="your-secret-key-here"
DEBUG=true
PORT=3000
LOG_LEVEL=${DEBUG:+debug}                  # Variable substitution
REDIS_URL=$DATABASE_URL/redis              # Reference other variables
```

## Utility Functions

### backup_file - File Backup

Create timestamped backups of important files.

```fish
backup_file config.json                    # Creates config.json.backup.20240101_143022
backup_file app.py ~/backups/              # Backup to specific directory
```

### find_large - Large File Discovery

Find files larger than specified size thresholds.

```fish
find_large                                 # Find files > 100M in current dir
find_large 50M                             # Find files > 50M
find_large 1G /home                        # Find files > 1G in /home
```

### clean_temp - Temporary File Cleanup

Clean temporary files and cache directories.

```fish
clean_temp                                 # Clean temp files
clean_temp -n                              # Dry run (show what would be cleaned)
clean_temp -v                              # Verbose output
```

**Cleaned Items:**

- `*.tmp`, `*.temp` files
- Backup files (`*~`)
- System files (`.DS_Store`, `Thumbs.db`)
- Cache directories (`.cache`, `__pycache__`, `node_modules/.cache`)

## Command Reference

### Aliases

The following aliases are available for quick access:

```fish
x          # extract
xr         # extract_and_remove  
cps        # compress
ka         # kill_all
gtp        # git_tag_push
dus        # du_sort
```

### Exit Codes

All functions return appropriate exit codes:

- `0` - Success
- `1` - General error (file not found, invalid arguments, etc.)
- `2` - Partial success (some operations failed in batch processing)

### Error Handling

- **File Validation**: All functions check file existence before processing
- **Permission Checks**: Warns about permission issues
- **Graceful Degradation**: Continues processing other files when one fails
- **User Confirmation**: Prompts for destructive operations (unless forced)
- **Detailed Error Messages**: Clear indication of what went wrong

## Optional Tools

Install these tools for full functionality:

**Ubuntu/Debian:**

```bash
sudo apt install unrar-free p7zip-full lz4 zstd cabextract rpm2cpio
```

**macOS:**

```bash
brew install unrar p7zip lz4 zstd cabextract rpm2cpio
```

**Arch Linux:**

```bash
sudo pacman -S unrar p7zip lz4 zstd cabextract rpm-tools
```
