# mdc - Enhanced make directory and change directory
#
# Creates directories (including parent directories) and changes into the last one.
# Supports multiple paths and provides feedback on created directories.
#
# Usage: mdc [OPTIONS] <directory> [directories...]
# Options:
#   -v, --verbose   Show created directories
#   -m, --mode MODE Set directory permissions (e.g., 755, 644)
#   -h, --help      Show help message

function mdc -d "Make directory and cd into it with enhanced features"
    set -l verbose false
    set -l mode ""
    set -l directories
    
    # Parse arguments
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: mdc [OPTIONS] <directory> [directories...]"
                echo "Create directories and change into the last one."
                echo ""
                echo "Options:"
                echo "  -v, --verbose     Show created directories"
                echo "  -m, --mode MODE   Set directory permissions (e.g., 755, 600)"
                echo "  -h, --help        Show this help"
                echo ""
                echo "Examples:"
                echo "  mdc project/src/utils          # Create nested dirs and cd to utils"
                echo "  mdc -v -m 755 ~/workspace      # Create with specific permissions"
                echo "  mdc dir1 dir2 dir3             # Create multiple dirs, cd to dir3"
                return 0
            case -v --verbose
                set verbose true
            case -m --mode
                # Next argument should be the mode
                continue
            case '-*'
                echo "mdc: unknown option '$arg'" >&2
                return 1
            case '*'
                set directories $directories "$arg"
        end
    end
    
    if test (count $directories) -eq 0
        echo "Usage: mdc [OPTIONS] <directory> [directories...]"
        return 1
    end
    
    # Create directories
    for dir in $directories
        if test -z "$dir"
            continue
        end
        
        if test -d "$dir"
            if test $verbose = true
                echo "Directory '$dir' already exists"
            end
        else
            set -l mkdir_args "-p"
            if test -n "$mode"
                set mkdir_args $mkdir_args "-m" "$mode"
            end
            
            if mkdir $mkdir_args "$dir"
                if test $verbose = true
                    echo "Created directory: $dir"
                    if test -n "$mode"
                        echo "  Mode: $mode"
                    end
                end
            else
                echo "mdc: failed to create directory '$dir'" >&2
                return 1
            end
        end
    end
    
    # Change to the last directory
    set -l last_dir $directories[-1]
    if not cd "$last_dir"
        echo "mdc: failed to change directory to '$last_dir'" >&2
        return 1
    end
    
    if test $verbose = true
        echo "Changed directory to: "(pwd)
    end
    
    return 0
end
