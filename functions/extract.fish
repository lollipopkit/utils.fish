# extract.fish - Enhanced universal archive extractor for fish shell
# Usage: extract <archive1> [archive2 ...]
# Supports: tar.bz2, tar.gz, tar.xz, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe

function extract
    if test (count $argv) -eq 0
        echo "Usage: extract <archive1> [archive2 ...]"
        echo "Supported: .tar.bz2 .tar.gz .tar.xz .lzma .bz2 .rar .gz .tar .tbz2 .tgz .zip .Z .7z .xz .exe"
        return 1
    end
    for file in $argv
        if not test -f "$file"
            echo "extract: '$file' - file does not exist"
            continue
        end
        set extracted 1
        switch $file
            case "*.tar.bz2"
                tar xvjf "$file"
            case "*.tar.gz"
                tar xvzf "$file"
            case "*.tar.xz"
                tar xvJf "$file"
            case "*.lzma"
                unlzma "$file"
            case "*.bz2"
                bunzip2 "$file"
            case "*.rar"
                unrar x -ad "$file"
            case "*.gz"
                gunzip "$file"
            case "*.tar"
                tar xvf "$file"
            case "*.tbz2"
                tar xvjf "$file"
            case "*.tgz"
                tar xvzf "$file"
            case "*.zip"
                unzip "$file"
            case "*.Z"
                uncompress "$file"
            case "*.7z"
                7z x "$file"
            case "*.xz"
                unxz "$file"
            case "*.exe"
                cabextract "$file"
            case "*"
                echo "extract: '$file' - unknown archive method"
                set extracted 0
        end
        if test $extracted -eq 1
            echo "extract: '$file' extracted successfully."
        end
    end
end

function extract_and_remove
    if test (count $argv) -eq 0
        echo "Usage: extract_and_remove <archive1> [archive2 ...]"
        return 1
    end
    for file in $argv
        extract "$file"
        if test -f "$file"
            rm -f "$file"
            echo "extract_and_remove: '$file' removed."
        end
    end
end
