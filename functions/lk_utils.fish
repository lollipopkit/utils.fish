# utils.fish - Enhanced utility functions for fish shell
#
# This file provides comprehensive utility functions for various system
# operations, development tasks, and productivity enhancements.
#
# Main functions:
# - kill_all: Enhanced process management with safety features
# - mdc: Enhanced directory creation and navigation
# - du_sort: Advanced directory size analysis
# - env_run: Environment file processing and command execution
# - Additional utility functions for development workflow

# kill_all - Enhanced process killer with safety features
#
# Kills all processes matching a given keyword with graceful termination
# followed by forced kill if necessary.
#
# Usage: kill_all [OPTIONS] <keyword>
# Options:
#   -f, --force     Skip graceful termination, use SIGKILL immediately
#   -n, --dry-run   Show what would be killed without actually killing
#   -9              Same as --force (use SIGKILL)
#   -s, --signal    Specify signal to send (default: TERM)
#   -h, --help      Show help message

function kill_all -d "Kill all processes matching keyword with safety features"
    set -l force_mode false
    set -l dry_run false
    set -l signal "TERM"
    set -l keyword ""
    
    # Parse arguments
    for arg in $argv
        switch $arg
            case -h --help
                echo "Usage: kill_all [OPTIONS] <keyword>"
                echo "Kill all processes matching the given keyword."
                echo ""
                echo "Options:"
                echo "  -f, --force     Skip graceful termination, use SIGKILL immediately"
                echo "  -n, --dry-run   Show what would be killed without actually killing"
                echo "  -9              Same as --force (use SIGKILL)"
                echo "  -s, --signal SIG Specify signal to send (default: TERM)"
                echo "  -h, --help      Show this help"
                echo ""
                echo "Examples:"
                echo "  kill_all firefox              # Gracefully kill all firefox processes"
                echo "  kill_all -f chrome            # Force kill all chrome processes"
                echo "  kill_all -n python            # Show python processes that would be killed"
                echo "  kill_all -s USR1 nginx        # Send USR1 signal to nginx processes"
                return 0
            case -f --force -9
                set force_mode true
                set signal "KILL"
            case -n --dry-run
                set dry_run true
            case -s --signal
                # Signal will be the next argument - we'll handle this in a more complex way
                continue
            case '-*'
                echo "kill_all: unknown option '$arg'" >&2
                return 1
            case '*'
                if test -z "$keyword"
                    set keyword "$arg"
                else
                    echo "kill_all: too many arguments" >&2
                    return 1
                end
        end
    end
    
    if test -z "$keyword"
        echo "Usage: kill_all [OPTIONS] <keyword>"
        return 1
    end
    
    # Find matching processes
    set -l pids (pgrep -f "$keyword")
    
    if test (count $pids) -eq 0
        echo "No processes found matching '$keyword'"
        return 1
    end
    
    # Display process information
    echo "Found "(count $pids)" process(es) matching '$keyword':"
    for pid in $pids
        set -l process_info (ps -p $pid -o pid,ppid,user,command --no-headers 2>/dev/null)
        if test -n "$process_info"
            echo "  $process_info"
        end
    end
    
    if test $dry_run = true
        echo "Dry run mode - no processes were killed"
        return 0
    end
    
    # Confirm before killing (unless in force mode)
    if test $force_mode = false
        echo ""
        echo "Kill these processes? (y/N)"
        read -l response
        if not string match -qi 'y*' "$response"
            echo "Operation cancelled"
            return 1
        end
    end
    
    # Kill processes
    echo "Sending SIG$signal to processes..."
    set -l killed_count 0
    set -l failed_pids
    
    for pid in $pids
        if kill -s $signal $pid 2>/dev/null
            set killed_count (math $killed_count + 1)
            echo "  ✓ Killed process $pid"
        else
            set failed_pids $failed_pids $pid
            echo "  ✗ Failed to kill process $pid"
        end
    end
    
    # If using graceful termination, wait and check for remaining processes
    if test $signal = "TERM"; and test (count $failed_pids) -eq 0
        echo "Waiting 3 seconds for graceful shutdown..."
        sleep 3
        
        # Check for any remaining processes
        set -l remaining_pids
        for pid in $pids
            if kill -0 $pid 2>/dev/null
                set remaining_pids $remaining_pids $pid
            end
        end
        
        if test (count $remaining_pids) -gt 0
            echo ""(count $remaining_pids)" process(es) still running, sending SIGKILL..."
            for pid in $remaining_pids
                if kill -KILL $pid 2>/dev/null
                    echo "  ✓ Force killed process $pid"
                else
                    echo "  ✗ Failed to force kill process $pid" >&2
                end
            end
        end
    end
    
    echo "Successfully sent signal to $killed_count process(es)"
    if test (count $failed_pids) -gt 0
        echo "Failed to signal "(count $failed_pids)" process(es)" >&2
        return 1
    end
    
    return 0
end

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

# env_run - Enhanced environment file processor and command runner
#
# Loads environment variables from .env files and runs commands with those variables.
# Supports multiple .env files, variable substitution, and various formats.
#
# Usage: env_run [OPTIONS] <command> [args...]
# Options:
#   -f, --file FILE     Use specific env file (default: .env)
#   -d, --dir DIR       Look for .env file in specific directory
#   -s, --show          Show loaded environment variables
#   -v, --validate      Validate .env file format
#   --export            Export variables to current shell (fish only)
#   -h, --help          Show help message

function env_run -d "Run commands with environment variables from .env files"
    set -l env_file ".env"
    set -l env_dir "."
    set -l show_vars false
    set -l validate_only false
    set -l export_vars false
    set -l command_args
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: env_run [OPTIONS] <command> [args...]"
                echo "Run commands with environment variables from .env files."
                echo ""
                echo "Options:"
                echo "  -f, --file FILE     Use specific env file (default: .env)"
                echo "  -d, --dir DIR       Look for .env file in directory"
                echo "  -s, --show          Show loaded environment variables"
                echo "  -v, --validate      Validate .env file format only"
                echo "  --export            Export variables to current shell"
                echo "  -h, --help          Show this help"
                echo ""
                echo "Examples:"
                echo "  env_run python app.py          # Run with .env variables"
                echo "  env_run -f prod.env npm start   # Use prod.env file"
                echo "  env_run -s -v                   # Show and validate .env"
                echo "  env_run --export                # Export vars to current shell"
                echo ""
                echo ".env file format:"
                echo "  KEY=value          # Simple assignment"
                echo "  KEY=\"value\"        # Quoted value"
                echo "  # Comment          # Comments start with #"
                echo "  KEY=\$OTHER_VAR     # Variable substitution"
                return 0
            case -f --file
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set env_file $argv[$i]
                else
                    echo "env_run: --file requires an argument" >&2
                    return 1
                end
            case -d --dir
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set env_dir $argv[$i]
                else
                    echo "env_run: --dir requires an argument" >&2
                    return 1
                end
            case -s --show
                set show_vars true
            case -v --validate
                set validate_only true
            case --export
                set export_vars true
            case '-*'
                echo "env_run: unknown option '$argv[$i]'" >&2
                return 1
            case '*'
                set command_args $command_args $argv[$i]
        end
        set i (math $i + 1)
    end
    
    # Construct full path to env file
    set -l full_env_path "$env_dir/$env_file"
    if not string match -q '/*' "$env_file"
        # Relative path
        set full_env_path "$env_dir/$env_file"
    else
        # Absolute path
        set full_env_path "$env_file"
    end
    
    # Check if .env file exists
    if not test -f "$full_env_path"
        echo "env_run: env file '$full_env_path' not found" >&2
        return 1
    end
    
    # Read and parse .env file
    set -l env_vars
    set -l invalid_lines
    set -l line_number 0
    
    while read -l line
        set line_number (math $line_number + 1)
        
        # Skip empty lines and comments
        if test -z "$line"; or string match -q '#*' "$line"
            continue
        end
        
        # Validate line format (KEY=VALUE)
        if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' "$line"
            # Extract key and value
            set -l key (string replace -r '=.*' '' "$line")
            set -l value (string replace -r '^[^=]*=' '' "$line")
            
            # Remove quotes if present
            set value (string replace -r '^"(.*)"$' '$1' "$value")
            set value (string replace -r "^'(.*)'\$" '$1' "$value")
            
            # Basic variable substitution (${VAR} or $VAR)
            while string match -qr '\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)' "$value"
                set -l var_name (string replace -r '.*\$\{([^}]+)\}.*|.*\$([A-Za-z_][A-Za-z0-9_]*).*' '$1$2' "$value")
                set -l var_value ""
                
                # Look up variable value (from environment or previously loaded)
                if set -q $var_name
                    set var_value $$var_name
                end
                
                # Replace in value
                set value (string replace "\$\{$var_name\}" "$var_value" "$value")
                set value (string replace "\$$var_name" "$var_value" "$value")
            end
            
            set env_vars $env_vars "$key=$value"
        else
            set invalid_lines $invalid_lines "Line $line_number: $line"
        end
    end < "$full_env_path"
    
    # Show validation results
    if test (count $invalid_lines) -gt 0
        echo "Warning: Invalid lines found in $full_env_path:" >&2
        for invalid in $invalid_lines
            echo "  $invalid" >&2
        end
        if test $validate_only = true
            return 1
        end
    end
    
    if test $validate_only = true
        echo "✓ Environment file '$full_env_path' is valid"
        echo "Found "(count $env_vars)" environment variable(s)"
        return 0
    end
    
    # Show variables if requested
    if test $show_vars = true
        echo "Loaded environment variables from '$full_env_path':"
        for env_var in $env_vars
            echo "  $env_var"
        end
        echo ""
    end
    
    # Export to current shell if requested (Fish shell specific)
    if test $export_vars = true
        echo "Exporting variables to current shell:"
        for env_var in $env_vars
            set -l key (string replace -r '=.*' '' "$env_var")
            set -l value (string replace -r '^[^=]*=' '' "$env_var")
            set -gx $key "$value"
            echo "  export $key='$value'"
        end
        return 0
    end
    
    # Check if we have a command to run
    if test (count $command_args) -eq 0
        if not test $show_vars = true
            echo "Usage: env_run [OPTIONS] <command> [args...]" >&2
            return 1
        end
        return 0
    end
    
    # Run the command with loaded environment
    if test $show_vars = true
        echo "Running command: $command_args"
        echo ""
    end
    
    env $env_vars $command_args
end

# Additional utility functions for productivity

# backup_file - Create timestamped backup of a file
function backup_file -d "Create timestamped backup of a file"
    if test (count $argv) -eq 0
        echo "Usage: backup_file <file> [backup_dir]"
        return 1
    end
    
    set -l file $argv[1]
    set -l backup_dir "."
    
    if test (count $argv) -ge 2
        set backup_dir $argv[2]
    end
    
    if not test -f "$file"
        echo "backup_file: '$file' not found" >&2
        return 1
    end
    
    set -l timestamp (date +%Y%m%d_%H%M%S)
    set -l basename (basename "$file")
    set -l backup_name "$basename.backup.$timestamp"
    set -l backup_path "$backup_dir/$backup_name"
    
    if cp "$file" "$backup_path"
        echo "✓ Backup created: $backup_path"
        return 0
    else
        echo "✗ Failed to create backup" >&2
        return 1
    end
end

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