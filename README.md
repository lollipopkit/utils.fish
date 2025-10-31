# utils.fish

Fish shell utility collection for archive handling and system management.

## 📦 Installation

```fish
fisher remove lollipopkit/utils.fish && fisher install lollipopkit/utils.fish
```

## 📋 Functions Reference

### Archive & Compression

Supported formats include:  
tar.bz2, tar.gz, tar.xz, tar.zst, tar.lz4, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

- `extract <file>` - Universal archive extractor with format auto-detection (alias: `x`, plus `xl`/`xt` helpers). Requires format-specific tools such as `tar`, `unzip`, `7z`, `unrar`, `zstd`, `lz4`, `cabextract`, etc.
- `extract_and_remove <file>` - Extract archives and delete the source on success (alias: `xr`).
- `compress [options] <target> [output]` - Flexible archiver supporting tar.gz/bz2/xz/zst/lz4, zip, and 7z (aliases: `cps`, `cpsz`, `cps7`). Optional dependencies: `zstd`, `lz4`, `7z`.

### Backup & Storage

- `backup_file <file> [backup_dir]` - Create a timestamped copy of any file.
- `dvbak <volume> [backup.tar.gz]` - Snapshot a Docker volume into the current directory (requires `docker`).
- `dvrst <backup_file> [volume_name]` - Restore a Docker volume from a tar.gz backup file (requires `docker`).

### System & Maintenance

- `clean_temp [-n|-v]` - Remove temporary files, cache folders, or dry-run changes.
- `du_sort [options] [dirs...]` - Human-readable directory sizing with sorting and summaries (alias: `dus`).
- `find_large [size] [path]` - Quickly list files exceeding a threshold (defaults to `100M`).
- `kill_all [options] <keyword>` - Gracefully terminate or force-kill matching processes (alias: `ka`).

### Environment & Workflow

- `env_run [options] <command>` - Load variables from `.env` files with validation/export support.
- `mdc [options] <dir...>` - Create directories and `cd` into the last one with optional verbose/mode flags.
- `git_tag_push [options] [tag] [message]` - Create annotated tags with semantic bumps and push upstream (alias: `gtp`).

### Networking

- `sshfwd <host> <remote_port> [-lp local_port] [-b]` - Establish local port forwards over SSH, optionally in the background.

### Benchmarking

- `rand4k <target> <randread|randwrite|randrw> [runtime_s]` - Run a 4K random I/O benchmark via `fio` (defaults to 30s and uses `io_uring` on Linux).

### Media

- `vid_convert <input_video> <format>` - Transcode media into `h264`, `hevc`, `mov`, `mkv`, `webm`, or `avi`. Uses hardware encoders on macOS and software encoders elsewhere (requires `ffmpeg`).

## 📄 License

AGPL v3 License - see the [LICENSE](LICENSE) file for details.
