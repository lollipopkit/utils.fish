# clean_temp - Clean temporary files and directories
function clean_temp -d "Clean temporary files and common cache directories"
    set -l dry_run false
    set -l verbose false
    
    # Parse arguments
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: clean_temp [OPTIONS]"
                echo "Clean temporary files and cache directories."
                echo ""
                echo "Options:"
                echo "  -n, --dry-run    Show what would be cleaned without deleting"
                echo "  -v, --verbose    Show detailed output"
                echo "  -h, --help       Show this help"
                return 0
            case -n --dry-run
                set dry_run true
            case -v --verbose
                set verbose true
            case '-*'
                echo "clean_temp: unknown option '$arg'" >&2
                return 1
        end
    end
    
    set -l temp_patterns "*.tmp" "*.temp" "*~" ".DS_Store" "Thumbs.db"
    set -l cache_dirs ".cache" "node_modules/.cache" "__pycache__"
    
    if test $dry_run = true
        echo "Dry run mode - showing what would be cleaned:"
    else
        echo "Cleaning temporary files and caches..."
    end
    
    set -l cleaned_count 0
    
    # Clean temporary files
    for pattern in $temp_patterns
        set -l files (find . -name "$pattern" -type f 2>/dev/null)
        for file in $files
            if test $verbose = true; or test $dry_run = true
                echo "  $file"
            end
            if test $dry_run = false
                rm -f "$file"
                set cleaned_count (math $cleaned_count + 1)
            end
        end
    end
    
    # Clean cache directories
    for cache_dir in $cache_dirs
        set -l dirs (find . -name "$cache_dir" -type d 2>/dev/null)
        for dir in $dirs
            if test $verbose = true; or test $dry_run = true
                echo "  $dir/"
            end
            if test $dry_run = false
                rm -rf "$dir"
                set cleaned_count (math $cleaned_count + 1)
            end
        end
    end
    
    if test $dry_run = false
        echo "✓ Cleaned $cleaned_count items"
    end
end
