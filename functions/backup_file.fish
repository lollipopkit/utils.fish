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
