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
