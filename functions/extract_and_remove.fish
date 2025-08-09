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
