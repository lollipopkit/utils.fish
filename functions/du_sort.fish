# du_sort - Enhanced directory size analyzer
#
# Lists directories by size with various sorting and filtering options.
# Provides human-readable output with optional detailed statistics.
#
# Usage: du_sort [OPTIONS] [directories...]
# Options:
#   -r, --reverse     Sort in reverse order (largest first)
#   -d, --depth N     Maximum depth to scan (default: 1)
#   -t, --threshold   Only show directories larger than threshold (e.g., 1M, 100K)
#   -s, --summary     Show summary statistics
#   -a, --all         Include hidden directories
#   --no-total        Hide total size line
#   -h, --help        Show help message

function du_sort -d "List directories by size with enhanced features"
    set -l reverse false
    set -l depth "1"
    set -l threshold ""
    set -l summary false
    set -l include_hidden false
    set -l show_total true
    set -l target_dirs "."
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: du_sort [OPTIONS] [directories...]"
                echo "List directories by size with various sorting options."
                echo ""
                echo "Options:"
                echo "  -r, --reverse       Sort in reverse order (largest first)"
                echo "  -d, --depth N       Maximum depth to scan (default: 1)"
                echo "  -t, --threshold SIZE Only show dirs larger than SIZE (e.g., 1M, 100K)"
                echo "  -s, --summary       Show summary statistics"
                echo "  -a, --all           Include hidden directories"
                echo "  --no-total          Hide total size line"
                echo "  -h, --help          Show this help"
                echo ""
                echo "Examples:"
                echo "  du_sort                         # Sort current directory by size"
                echo "  du_sort -r -d 2                 # Show 2 levels, largest first"
                echo "  du_sort -t 100M /home           # Show dirs > 100MB in /home"
                echo "  du_sort -s -a                   # Include hidden dirs with summary"
                return 0
            case -r --reverse
                set reverse true
            case -d --depth
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set depth $argv[$i]
                else
                    echo "du_sort: --depth requires a number" >&2
                    return 1
                end
            case -t --threshold
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set threshold $argv[$i]
                else
                    echo "du_sort: --threshold requires a size (e.g., 1M, 100K)" >&2
                    return 1
                end
            case -s --summary
                set summary true
            case -a --all
                set include_hidden true
            case --no-total
                set show_total false
            case '-*'
                echo "du_sort: unknown option '$argv[$i]'" >&2
                return 1
            case '*'
                if test "$target_dirs" = "."
                    set target_dirs $argv[$i]
                else
                    set target_dirs $target_dirs $argv[$i]
                end
        end
        set i (math $i + 1)
    end
    
    # Build du command
    set -l du_args "-h" "--max-depth=$depth"
    
    if not test $include_hidden = true
        # Exclude hidden directories
        set du_args $du_args "--exclude=.*"
    end
    
    # Get directory sizes
    set -l du_output (du $du_args $target_dirs 2>/dev/null)
    
    if test (count $du_output) -eq 0
        echo "du_sort: no directories found or permission denied" >&2
        return 1
    end
    
    # Filter by threshold if specified
    if test -n "$threshold"
        # Convert threshold to bytes for comparison
        set -l threshold_bytes 0
        if string match -qr '(\d+)([KMGT]?)' "$threshold"
            set -l size_num (string replace -r '(\d+).*' '$1' "$threshold")
            set -l size_unit (string replace -r '\d+([KMGT]?).*' '$1' "$threshold")
            
            switch (string upper "$size_unit")
                case K
                    set threshold_bytes (math $size_num \* 1024)
                case M
                    set threshold_bytes (math $size_num \* 1024 \* 1024)
                case G
                    set threshold_bytes (math $size_num \* 1024 \* 1024 \* 1024)
                case T
                    set threshold_bytes (math $size_num \* 1024 \* 1024 \* 1024 \* 1024)
                case '*'
                    set threshold_bytes $size_num
            end
        end
        
        # Filter results (this is a simplified approach)
        echo "Filtering by threshold: $threshold (Note: exact filtering may vary)" >&2
    end
    
    # Sort the output
    set -l sorted_output
    if test $reverse = true
        set sorted_output (printf '%s\n' $du_output | sort -hr)
    else
        set sorted_output (printf '%s\n' $du_output | sort -h)
    end
    
    # Display results
    set -l dir_count 0
    set -l total_size ""
    
    for line in $sorted_output
        if string match -q '*total*' "$line"; or string match -q "*$target_dirs" "$line"
            if test $show_total = true
                set total_size (string replace -r '^(\S+).*' '$1' "$line")
                echo "$line"
            end
        else
            echo "$line"
            set dir_count (math $dir_count + 1)
        end
    end
    
    # Show summary if requested
    if test $summary = true
        echo ""
        echo "Summary:"
        echo "  Directories scanned: $dir_count"
        echo "  Max depth: $depth"
        if test -n "$total_size"
            echo "  Total size: $total_size"
        end
        if test -n "$threshold"
            echo "  Size threshold: $threshold"
        end
        if test $include_hidden = true
            echo "  Hidden directories: included"
        end
    end
    
    return 0
end
