# utils.fish

Fish shell utility collection for archive handling and system management.

## 📦 Installation

```fish
fisher remove lollipopkit/utils.fish && fisher install lollipopkit/utils.fish
```

## 📋 Functions Reference

### Archive Functions

Supported formats include:  
tar.bz2, tar.gz, tar.xz, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

- `extract <file>` - Extract archives (alias: `x`)
- `extract_and_remove <file>` - Extract and delete source (alias: `xr`)
- `compress <directory>` - Compress to tar.gz (alias: `cps`)

### System Functions

- `kill_all <keyword>` - Kill all processes matching keyword (alias: `ka`)
- `git_tag_push [tag] [message]` - Create and push git tag (alias: `gtp`)
- `mdc <dir>` - Make directory and cd into it
- `du_sort` - List directories by size (alias: `dus`)
- `env_run <command>` - Run command with .env variables
- `clean_temp` - Clean temporary files
- `find_large <directory>` - Find large files in directory
- `dvbak <volume_name> [backup_name]` - Backup Docker volume to tar.gz

## 📖 Complete Documentation

For comprehensive usage instructions, advanced features, and detailed examples, see **[details](DETAILS.md)**.

## 📄 License

GPL v3 License - see the [LICENSE](LICENSE) file for details.
