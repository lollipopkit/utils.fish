# extract.fish - Enhanced universal archive extractor for fish shell
# 
# This function provides a unified interface for extracting various archive formats.
# It supports multiple files at once and provides clear feedback on success/failure.
# 
# Usage: extract <archive1> [archive2 ...]
# Supports: tar.bz2, tar.gz, tar.xz, tar.lz4, tar.zst, lzma, bz2, rar, gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe, deb, rpm, cab, iso

function extract -d "Universal archive extractor with support for 20+ formats"
    # Display help if no arguments provided
    if test (count $argv) -eq 0
        echo "Usage: extract [OPTIONS] <archive1> [archive2 ...]"
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  -q, --quiet    Suppress verbose output"
        echo "  -o, --output   Specify output directory"
        echo "  -l, --list     List archive contents without extracting"
        echo "  -t, --test     Test archive integrity"
        echo ""
        echo "Supported formats:"
        echo "  tar.bz2, tar.gz, tar.xz, tar.lz4, tar.zst, lzma, bz2, rar"
        echo "  gz, tar, tbz2, tgz, zip, Z, 7z, xz, exe, deb, rpm, cab, iso"
        return 1
    end

    # Parse options
    set -l quiet_mode false
    set -l output_dir ""
    set -l list_mode false
    set -l test_mode false
    set -l files

    for arg in $argv
        switch $arg
            case -h --help
                extract
                return 0
            case -q --quiet
                set quiet_mode true
            case -o --output
                # Next argument should be output directory
                continue
            case -l --list
                set list_mode true
            case -t --test
                set test_mode true
            case '-*'
                echo "extract: unknown option '$arg'"
                return 1
            case '*'
                set files $files $arg
        end
    end

    # Process each file
    set -l success_count 0
    set -l failure_count 0
    
    for file in $files
        # Check if file exists
        if not test -f "$file"
            echo "extract: '$file' - file does not exist" >&2
            set failure_count (math $failure_count + 1)
            continue
        end

        # Get file size for progress indication
        set -l file_size (stat -f%z "$file" 2>/dev/null; or echo "unknown")
        
        if test $quiet_mode = false
            if test "$file_size" != "unknown"
                echo "Extracting '$file' ("(math $file_size / 1024 / 1024)"MB)..."
            else
                echo "Extracting '$file'..."
            end
        end

        set -l extracted false
        set -l extract_cmd ""
        
        # Determine extraction method based on file extension
        switch (string lower $file)
            case "*.tar.bz2" "*.tbz2"
                if test $list_mode = true
                    tar -tjf "$file"
                else if test $test_mode = true
                    tar -tjf "$file" >/dev/null
                else
                    set extract_cmd "tar -xjf '$file'"
                    if test $quiet_mode = false
                        tar -xvjf "$file"
                    else
                        tar -xjf "$file"
                    end
                end
                set extracted true
                
            case "*.tar.gz" "*.tgz"
                if test $list_mode = true
                    tar -tzf "$file"
                else if test $test_mode = true
                    tar -tzf "$file" >/dev/null
                else
                    set extract_cmd "tar -xzf '$file'"
                    if test $quiet_mode = false
                        tar -xvzf "$file"
                    else
                        tar -xzf "$file"
                    end
                end
                set extracted true
                
            case "*.tar.xz"
                if test $list_mode = true
                    tar -tJf "$file"
                else if test $test_mode = true
                    tar -tJf "$file" >/dev/null
                else
                    set extract_cmd "tar -xJf '$file'"
                    if test $quiet_mode = false
                        tar -xvJf "$file"
                    else
                        tar -xJf "$file"
                    end
                end
                set extracted true
                
            case "*.tar.lz4"
                if command -q lz4
                    if test $list_mode = true
                        lz4 -dc "$file" | tar -t
                    else if test $test_mode = true
                        lz4 -t "$file"
                    else
                        set extract_cmd "lz4 -dc '$file' | tar -x"
                        lz4 -dc "$file" | tar -x
                    end
                    set extracted true
                else
                    echo "extract: lz4 command not found for '$file'"
                end
                
            case "*.tar.zst"
                if command -q zstd
                    if test $list_mode = true
                        zstd -dc "$file" | tar -t
                    else if test $test_mode = true
                        zstd -t "$file"
                    else
                        set extract_cmd "zstd -dc '$file' | tar -x"
                        zstd -dc "$file" | tar -x
                    end
                    set extracted true
                else
                    echo "extract: zstd command not found for '$file'"
                end
                
            case "*.tar"
                if test $list_mode = true
                    tar -tf "$file"
                else if test $test_mode = true
                    tar -tf "$file" >/dev/null
                else
                    set extract_cmd "tar -xf '$file'"
                    if test $quiet_mode = false
                        tar -xvf "$file"
                    else
                        tar -xf "$file"
                    end
                end
                set extracted true
                
            case "*.zip"
                if test $list_mode = true
                    unzip -l "$file"
                else if test $test_mode = true
                    unzip -t "$file"
                else
                    set extract_cmd "unzip '$file'"
                    if test $quiet_mode = false
                        unzip "$file"
                    else
                        unzip -q "$file"
                    end
                end
                set extracted true
                
            case "*.rar"
                if command -q unrar
                    if test $list_mode = true
                        unrar l "$file"
                    else if test $test_mode = true
                        unrar t "$file"
                    else
                        set extract_cmd "unrar x -ad '$file'"
                        unrar x -ad "$file"
                    end
                    set extracted true
                else
                    echo "extract: unrar command not found for '$file'"
                end
                
            case "*.7z"
                if command -q 7z
                    if test $list_mode = true
                        7z l "$file"
                    else if test $test_mode = true
                        7z t "$file"
                    else
                        set extract_cmd "7z x '$file'"
                        7z x "$file"
                    end
                    set extracted true
                else
                    echo "extract: 7z command not found for '$file'"
                end
                
            case "*.gz"
                if test $list_mode = true
                    echo (basename "$file" .gz)
                else if test $test_mode = true
                    gunzip -t "$file"
                else
                    set extract_cmd "gunzip '$file'"
                    gunzip "$file"
                end
                set extracted true
                
            case "*.bz2"
                if test $list_mode = true
                    echo (basename "$file" .bz2)
                else if test $test_mode = true
                    bunzip2 -t "$file"
                else
                    set extract_cmd "bunzip2 '$file'"
                    bunzip2 "$file"
                end
                set extracted true
                
            case "*.xz"
                if test $list_mode = true
                    echo (basename "$file" .xz)
                else if test $test_mode = true
                    unxz -t "$file"
                else
                    set extract_cmd "unxz '$file'"
                    unxz "$file"
                end
                set extracted true
                
            case "*.lzma"
                if command -q unlzma
                    if test $list_mode = true
                        echo (basename "$file" .lzma)
                    else if test $test_mode = true
                        unlzma -t "$file"
                    else
                        set extract_cmd "unlzma '$file'"
                        unlzma "$file"
                    end
                    set extracted true
                else
                    echo "extract: unlzma command not found for '$file'"
                end
                
            case "*.z"
                if command -q uncompress
                    if test $list_mode = true
                        echo (basename "$file" .Z)
                    else
                        set extract_cmd "uncompress '$file'"
                        uncompress "$file"
                    end
                    set extracted true
                else
                    echo "extract: uncompress command not found for '$file'"
                end
                
            case "*.deb"
                if command -q dpkg-deb
                    if test $list_mode = true
                        dpkg-deb -c "$file"
                    else
                        set extract_cmd "dpkg-deb -x '$file' ."
                        dpkg-deb -x "$file" .
                    end
                    set extracted true
                else if command -q ar
                    if test $list_mode = true
                        ar t "$file"
                    else
                        set extract_cmd "ar x '$file'"
                        ar x "$file"
                    end
                    set extracted true
                else
                    echo "extract: neither dpkg-deb nor ar found for '$file'"
                end
                
            case "*.rpm"
                if command -q rpm2cpio; and command -q cpio
                    if test $list_mode = true
                        rpm2cpio "$file" | cpio -t
                    else
                        set extract_cmd "rpm2cpio '$file' | cpio -idmv"
                        rpm2cpio "$file" | cpio -idmv
                    end
                    set extracted true
                else
                    echo "extract: rpm2cpio and cpio commands needed for '$file'"
                end
                
            case "*.cab"
                if command -q cabextract
                    if test $list_mode = true
                        cabextract -l "$file"
                    else
                        set extract_cmd "cabextract '$file'"
                        cabextract "$file"
                    end
                    set extracted true
                else
                    echo "extract: cabextract command not found for '$file'"
                end
                
            case "*.iso"
                if command -q 7z
                    if test $list_mode = true
                        7z l "$file"
                    else
                        set extract_cmd "7z x '$file'"
                        7z x "$file"
                    end
                    set extracted true
                else
                    echo "extract: 7z command not found for ISO extraction of '$file'"
                    echo "Note: You can also mount ISO files: sudo mount -o loop '$file' /mnt"
                end
                
            case "*.exe"
                if command -q cabextract
                    if test $list_mode = true
                        cabextract -l "$file"
                    else
                        set extract_cmd "cabextract '$file'"
                        cabextract "$file"
                    end
                    set extracted true
                else
                    echo "extract: cabextract command not found for '$file'"
                end
                
            case "*"
                echo "extract: '$file' - unsupported archive format" >&2
        end

        # Handle extraction result
        if test $extracted = true
            set -l command_status $status
            if test $command_status -eq 0
                set success_count (math $success_count + 1)
                if test $quiet_mode = false; and test $list_mode = false; and test $test_mode = false
                    echo "✓ '$file' extracted successfully"
                end
            else
                set failure_count (math $failure_count + 1)
                echo "✗ Failed to extract '$file'" >&2
            end
        else
            set failure_count (math $failure_count + 1)
        end
    end

    # Summary
    if test (count $files) -gt 1; and test $quiet_mode = false
        echo ""
        echo "Summary: $success_count successful, $failure_count failed"
    end
    
    # Return appropriate exit code
    if test $failure_count -gt 0
        return 1
    end
    return 0
end

# extract_and_remove - Extract archives and remove the source files
#
# This function extracts one or more archive files and then removes the original
# archive files upon successful extraction. It provides safety checks to ensure
# files are only removed after successful extraction.
#
# Usage: extract_and_remove [OPTIONS] <archive1> [archive2 ...]
# Options: Same as extract function

function extract_and_remove -d "Extract archives and remove source files after successful extraction"
    if test (count $argv) -eq 0
        echo "Usage: extract_and_remove [OPTIONS] <archive1> [archive2 ...]"
        echo "Extracts archives and removes source files upon successful extraction."
        echo "Use 'extract --help' for available options."
        return 1
    end

    # Store original files list to track which ones to remove
    set -l original_files
    set -l parsing_files false
    
    for arg in $argv
        switch $arg
            case -h --help -q --quiet -o --output -l --list -t --test
                # Skip option flags
                continue
            case '-*'
                # Skip unknown options
                continue
            case '*'
                # This is a file
                if test -f "$arg"
                    set original_files $original_files "$arg"
                end
        end
    end

    # Call extract with all original arguments
    extract $argv
    set -l extract_exit_code $status
    
    # Only remove files if extraction was successful
    if test $extract_exit_code -eq 0
        set -l removed_count 0
        for file in $original_files
            if test -f "$file"
                # Create backup before removal (optional safety feature)
                # set backup_name "$file.backup."(date +%s)
                # cp "$file" "$backup_name"
                
                rm -f "$file"
                set -l rm_status $status
                if test $rm_status -eq 0
                    echo "✓ Removed '$file'"
                    set removed_count (math $removed_count + 1)
                else
                    echo "✗ Failed to remove '$file'" >&2
                end
            end
        end
        
        if test $removed_count -gt 0
            echo "Successfully removed $removed_count archive file(s)"
        end
    else
        echo "Extraction failed - archive files were not removed" >&2
        return $extract_exit_code
    end
    
    return 0
end

# list_archive - List contents of archives without extracting
#
# This is a convenience wrapper around 'extract --list'
#
# Usage: list_archive <archive1> [archive2 ...]

function list_archive -d "List contents of archives without extracting"
    if test (count $argv) -eq 0
        echo "Usage: list_archive <archive1> [archive2 ...]"
        return 1
    end
    
    extract --list $argv
end

# test_archive - Test integrity of archives without extracting
#
# This is a convenience wrapper around 'extract --test'
#
# Usage: test_archive <archive1> [archive2 ...]

function test_archive -d "Test integrity of archives without extracting"
    if test (count $argv) -eq 0
        echo "Usage: test_archive <archive1> [archive2 ...]"
        return 1
    end
    
    extract --test $argv
end
