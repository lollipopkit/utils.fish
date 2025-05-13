# extract.fish

A simple Fish shell function for extracting various types of compressed archive files with a single command.

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
