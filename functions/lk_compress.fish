# compress.fish - Enhanced compression utilities for fish shell
#
# This file provides comprehensive compression functionality supporting
# multiple archive formats with various compression levels and options.
#
# Main functions:
# - compress: Compress files/directories to various formats
# - compress_to: Compress with custom output filename
# - compress_fast/compress_best: Compress with specific compression levels

# compress - Universal compression function
#
# Compresses files or directories to various archive formats based on file extension
# or explicit format specification.
#
# Usage: compress [OPTIONS] <target> [output_name]
# Options:
#   -f, --format FORMAT   Specify compression format (tar.gz, tar.bz2, tar.xz, zip, 7z, tar.zst, tar.lz4)
#   -l, --level LEVEL     Compression level (1-9, where 9 is best compression)
#   -q, --quiet           Suppress verbose output
#   -e, --exclude PATTERN Exclude files matching pattern
#   --fast                Use fastest compression (level 1)
#   --best                Use best compression (level 9)
#   -h, --help            Show help message

function compress -d "Universal compression function supporting multiple formats"
    # Default values
    set -l format ""
    set -l level ""
    set -l quiet_mode false
    set -l exclude_patterns
    set -l target ""
    set -l output_name ""
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: compress [OPTIONS] <target> [output_name]"
                echo "Compress files or directories to various archive formats."
                echo ""
                echo "Options:"
                echo "  -f, --format FORMAT   Specify format: tar.gz, tar.bz2, tar.xz, zip, 7z, tar.zst, tar.lz4"
                echo "  -l, --level LEVEL     Compression level (1-9)"
                echo "  -q, --quiet           Suppress verbose output"
                echo "  -e, --exclude PATTERN Exclude files matching pattern"
                echo "  --fast                Use fastest compression (level 1)"
                echo "  --best                Use best compression (level 9)"
                echo "  -h, --help            Show this help"
                echo ""
                echo "Supported formats: tar.gz, tar.bz2, tar.xz, tar.zst, tar.lz4, zip, 7z"
                echo "Default format: tar.gz"
                echo ""
                echo "Examples:"
                echo "  compress mydir                    # Creates mydir.tar.gz"
                echo "  compress -f zip mydir             # Creates mydir.zip"
                echo "  compress --best mydir backup      # Creates backup.tar.gz with best compression"
                echo "  compress -e '*.tmp' mydir         # Exclude .tmp files"
                return 0
            case -f --format
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set format $argv[$i]
                else
                    echo "compress: --format requires an argument" >&2
                    return 1
                end
            case -l --level
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set level $argv[$i]
                else
                    echo "compress: --level requires an argument" >&2
                    return 1
                end
            case -q --quiet
                set quiet_mode true
            case -e --exclude
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set exclude_patterns $exclude_patterns $argv[$i]
                else
                    echo "compress: --exclude requires an argument" >&2
                    return 1
                end
            case --fast
                set level 1
            case --best
                set level 9
            case '-*'
                echo "compress: unknown option '$argv[$i]'" >&2
                return 1
            case '*'
                if test -z "$target"
                    set target $argv[$i]
                else if test -z "$output_name"
                    set output_name $argv[$i]
                else
                    echo "compress: too many arguments" >&2
                    return 1
                end
        end
        set i (math $i + 1)
    end
    
    # Validate target
    if test -z "$target"
        echo "Usage: compress [OPTIONS] <target> [output_name]"
        return 1
    end
    
    if not test -e "$target"
        echo "compress: '$target' does not exist" >&2
        return 1
    end
    
    # Determine format if not specified
    if test -z "$format"
        if test -n "$output_name"
            # Guess format from output name extension
            switch (string lower "$output_name")
                case "*.tar.gz" "*.tgz"
                    set format "tar.gz"
                case "*.tar.bz2" "*.tbz2"
                    set format "tar.bz2"
                case "*.tar.xz"
                    set format "tar.xz"
                case "*.tar.zst"
                    set format "tar.zst"
                case "*.tar.lz4"
                    set format "tar.lz4"
                case "*.zip"
                    set format "zip"
                case "*.7z"
                    set format "7z"
                case "*"
                    set format "tar.gz"
            end
        else
            set format "tar.gz"
        end
    end
    
    # Generate output filename if not provided
    if test -z "$output_name"
        switch $format
            case "tar.gz"
                set output_name "$target.tar.gz"
            case "tar.bz2"
                set output_name "$target.tar.bz2"
            case "tar.xz"
                set output_name "$target.tar.xz"
            case "tar.zst"
                set output_name "$target.tar.zst"
            case "tar.lz4"
                set output_name "$target.tar.lz4"
            case "zip"
                set output_name "$target.zip"
            case "7z"
                set output_name "$target.7z"
        end
    end
    
    # Check if output file already exists
    if test -e "$output_name"
        echo "compress: '$output_name' already exists. Overwrite? (y/N)"
        read -l response
        if not string match -qi 'y*' "$response"
            echo "compress: operation cancelled"
            return 1
        end
    end
    
    # Display compression info
    if test $quiet_mode = false
        set -l size_info ""
        if test -d "$target"
            set size_info " ("(du -sh "$target" | cut -f1)")"
        else if test -f "$target"
            set size_info " ("(du -sh "$target" | cut -f1)")"
        end
        echo "Compressing '$target'$size_info to '$output_name' using $format format..."
    end
    
    # Build exclude arguments
    set -l exclude_args
    for pattern in $exclude_patterns
        switch $format
            case tar.gz tar.bz2 tar.xz tar.zst tar.lz4
                set exclude_args $exclude_args --exclude="$pattern"
            case zip
                set exclude_args $exclude_args -x "$pattern"
            case 7z
                # 7z uses different exclude syntax
                set exclude_args $exclude_args "-x!$pattern"
        end
    end
    
    # Compression level arguments
    set -l level_args
    if test -n "$level"
        switch $format
            case tar.gz tar.bz2 tar.xz tar.zst tar.lz4
                switch $format
                    case tar.gz
                        set level_args "-$level"
                    case tar.bz2
                        set level_args "-$level"
                    case tar.xz
                        set level_args "-$level"
                    case tar.zst
                        set level_args "--zstd" "-$level"
                    case tar.lz4
                        set level_args "--lz4" "-$level"
                end
            case zip
                set level_args "-$level"
            case 7z
                set level_args "-mx=$level"
        end
    end
    
    # Execute compression
    set -l start_time (date +%s)
    set -l success false
    
    switch $format
        case tar.gz
            if test $quiet_mode = true
                tar -czf "$output_name" $exclude_args $level_args "$target"
            else
                tar -czvf "$output_name" $exclude_args $level_args "$target"
            end
            set success true
            
        case tar.bz2
            if test $quiet_mode = true
                tar -cjf "$output_name" $exclude_args $level_args "$target"
            else
                tar -cjvf "$output_name" $exclude_args $level_args "$target"
            end
            set success true
            
        case tar.xz
            if test $quiet_mode = true
                tar -cJf "$output_name" $exclude_args $level_args "$target"
            else
                tar -cJvf "$output_name" $exclude_args $level_args "$target"
            end
            set success true
            
        case tar.zst
            if command -q zstd
                if test $quiet_mode = true
                    tar --use-compress-program="zstd $level_args" -cf "$output_name" $exclude_args "$target"
                else
                    tar --use-compress-program="zstd $level_args" -cvf "$output_name" $exclude_args "$target"
                end
                set success true
            else
                echo "compress: zstd command not found for tar.zst format" >&2
                return 1
            end
            
        case tar.lz4
            if command -q lz4
                if test $quiet_mode = true
                    tar --use-compress-program="lz4 $level_args" -cf "$output_name" $exclude_args "$target"
                else
                    tar --use-compress-program="lz4 $level_args" -cvf "$output_name" $exclude_args "$target"
                end
                set success true
            else
                echo "compress: lz4 command not found for tar.lz4 format" >&2
                return 1
            end
            
        case zip
            if test $quiet_mode = true
                zip -r $level_args "$output_name" "$target" $exclude_args
            else
                zip -rv $level_args "$output_name" "$target" $exclude_args
            end
            set success true
            
        case 7z
            if command -q 7z
                7z a $level_args "$output_name" "$target" $exclude_args
                set success true
            else
                echo "compress: 7z command not found for 7z format" >&2
                return 1
            end
            
        case '*'
            echo "compress: unsupported format '$format'" >&2
            return 1
    end
    
    # Check result and display summary
    set -l command_status $status
    if test $command_status -eq 0; and test $success = true
        set -l end_time (date +%s)
        set -l duration (math $end_time - $start_time)
        
        if test $quiet_mode = false
            set -l original_size ""
            set -l compressed_size ""
            
            if command -q du
                if test -e "$output_name"
                    set compressed_size (du -sh "$output_name" | cut -f1)
                end
                if test -e "$target"
                    set original_size (du -sh "$target" | cut -f1)
                end
            end
            
            echo "✓ Compression completed in {$duration}s"
            if test -n "$original_size"; and test -n "$compressed_size"
                echo "  Original: $original_size → Compressed: $compressed_size"
            end
            echo "  Output: $output_name"
        end
        return 0
    else
        echo "✗ Compression failed" >&2
        # Clean up partial file
        if test -e "$output_name"
            rm -f "$output_name"
        end
        return 1
    end
end

# compress_to - Compress with explicit output filename
#
# Usage: compress_to <target> <output_name> [options]

function compress_to -d "Compress with explicit output filename"
    if test (count $argv) -lt 2
        echo "Usage: compress_to <target> <output_name> [compress_options]"
        return 1
    end
    
    set -l target $argv[1]
    set -l output_name $argv[2]
    set -l options $argv[3..-1]
    
    compress $options "$target" "$output_name"
end

# compress_fast - Compress with fastest settings
#
# Usage: compress_fast <target> [output_name]

function compress_fast -d "Compress with fastest settings (level 1)"
    compress --fast $argv
end

# compress_best - Compress with best compression settings
#
# Usage: compress_best <target> [output_name]

function compress_best -d "Compress with best compression settings (level 9)"
    compress --best $argv
end
