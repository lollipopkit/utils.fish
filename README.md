# utils.fish

Fish shell utility collection for archive handling and system management.

## 📦 Installation

```fish
fisher install lollipopkit/utils.fish
```

## ✏️ Usage

### Archive Operations

```fish
# Extract archives
x archive.tar.gz                    # Quick extract
xr archive.zip                      # Extract and remove source

# Compress files/directories
c mydir                             # Create mydir.tar.gz
cz mydir                            # Create mydir.zip
```

### System Utilities

```fish
# Process management
ka firefox                          # Kill all Firefox processes

# Git operations  
gtp                                 # Auto-generate and push next version tag

# Directory operations
mdc project/src/utils               # Create nested dirs and cd to last
ds                                  # Show directory sizes
```

## 🔧 Supported Formats

tar.bz2, tar.gz, tar.xz, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

## 📋 Functions Reference

### Archive Functions

- `extract <file>` - Extract archives (alias: `x`)
- `extract_and_remove <file>` - Extract and delete source (alias: `xr`)
- `compress <directory>` - Compress to tar.gz (alias: `c`)

### System Functions

- `kill_all <keyword>` - Kill all processes matching keyword (alias: `ka`)
- `git_tag_push [tag] [message]` - Create and push git tag (alias: `gtp`)
- `mdc <dir>` - Make directory and cd into it
- `du_sort` - List directories by size (alias: `ds`)
- `env_run <command>` - Run command with .env variables (alias: `er`)

## 📖 Complete Documentation

For comprehensive usage instructions, advanced features, and detailed examples, see **[details](DETAILS.md)**.

## 📄 License

GPL v3 License - see the [LICENSE](LICENSE) file for details.
