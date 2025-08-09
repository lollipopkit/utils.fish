# find_large - Find large files in directory
function find_large -d "Find large files in directory"
    set -l size_threshold "100M"
    set -l search_path "."
    
    # Parse arguments
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: find_large [size] [path]"
                echo "Find files larger than specified size (default: 100M)"
                echo ""
                echo "Examples:"
                echo "  find_large              # Find files > 100M in current dir"
                echo "  find_large 50M          # Find files > 50M in current dir"
                echo "  find_large 1G /home     # Find files > 1G in /home"
                return 0
            case +([0-9])*([KMGT])
                set size_threshold $arg
            case '-*'
                echo "find_large: unknown option '$arg'" >&2
                return 1
            case '*'
                set search_path $arg
        end
    end
    
    echo "Finding files larger than $size_threshold in $search_path..."
    find "$search_path" -type f -size +"$size_threshold" -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr
end
