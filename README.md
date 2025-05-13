# extract.fish

A simple Fish shell function for extracting various types of compressed archive files with a single command.

## Features

- Supports a wide range of archive formats: `.zip`, `.rar`, `.bz2`, `.gz`, `.tar`, `.tbz2`, `.tgz`, `.Z`, `.7z`, `.xz`, `.lzma`, `.exe`, `.tar.bz2`, `.tar.gz`, `.tar.xz` and more.
- **Batch extraction**: Supports extracting multiple files at once.
- **Handles filenames with spaces**.
- Provides two commands:
  - `extract <file1> [file2 ...]`: Extracts one or more archive files.
  - `extract_and_remove <file1> [file2 ...]`: Extracts one or more archives and then deletes the original files.
- Includes convenient aliases:
  - `x <file1> [file2 ...]`: Alias for `extract <file1> [file2 ...]`
  - `xr <file1> [file2 ...]`: Alias for `extract_and_remove <file1> [file2 ...]`
- Friendly error messages and usage hints.

## Installation

```fish
fisher install lollipopkit/extract.fish
```

## Usage

```fish
x archive.tar.gz                # Extracts archive.tar.gz
xr archive.zip                  # Extracts and removes archive.zip
extract file.7z                 # Extracts file.7z
extract_and_remove file.tar.bz2 # Extracts and removes file.tar.bz2
x file1.zip file2.tar.gz        # Extract multiple archives at once
xr "file with space.rar"        # Handles filenames with spaces
```

If the file type is not recognized, an error message will be shown.
If the file does not exist, a clear error will be displayed.

## Supported Formats

- tar.bz2, tar.gz, tar.xz, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

## License

MIT
