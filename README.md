# extract.fish

A simple Fish shell function for extracting various types of compressed archive files with a single command.

## Features

- Supports a wide range of archive formats: `.zip`, `.rar`, `.bz2`, `.gz`, `.tar`, `.tbz2`, `.tgz`, `.Z`, `.7z`, `.xz`, `.lzma`, `.exe`, `.tar.bz2`, `.tar.gz`, `.tar.xz` and more.
- Provides two commands:
  - `extract <file>`: Extracts the specified archive file.
  - `extract_and_remove <file>`: Extracts the archive and then deletes the original file.
- Includes convenient aliases:
  - `x <file>`: Alias for `extract <file>`
  - `xr <file>`: Alias for `extract_and_remove <file>`

## Installation

```fish
fisher install lollipopkit/extract.fish
```

## Usage

```fish
x archive.tar.gz      # Extracts archive.tar.gz
xr archive.zip        # Extracts and removes archive.zip
extract file.7z       # Extracts file.7z
extract_and_remove file.tar.bz2  # Extracts and removes file.tar.bz2
```

If the file type is not recognized, an error message will be shown.

## Supported Formats

- tar.bz2, tar.gz, tar.xz, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

## License

MIT
