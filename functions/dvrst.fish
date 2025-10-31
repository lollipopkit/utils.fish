# Restore a Docker volume from a tar.gz backup file
#
# Usage:
#   dvrst <backup_file> [volume_name]
## Examples:
#   dvrst my-vol.tar.gz         # restores to volume 'my-vol'
#   dvrst backup.tgz my-vol     # restores to volume 'my-vol'
function dvrst --description "Restore a Docker volume from a tar.gz backup file"
    if test (count $argv) -lt 1
        echo "Usage: dvrst <backup_file> [volume_name]"
        return 1
    end

    set -l backup_file $argv[1]

    # Set volume name
    set -l volume (string replace -r '\.tar\.gz$' '' (basename -- "$backup_file"))
    if test (count $argv) -ge 2
        set -l volume $argv[2]
    end

    if not test -f "$backup_file"
        echo "Error: Backup file '$backup_file' not found."
        return 1
    end

    set -l backup_dir (begin
        set -l dir (dirname -- "$backup_file")
        if test "$dir" = "."
            pwd
        else
            cd "$dir"; and pwd
        end
    end)

    set -l backup_name (basename -- "$backup_file")

    # Create the volume if it doesn't exist
    docker volume create "$volume" > /dev/null

    # Restore the backup
    docker run --rm \
        -v "$volume":/data \
        -v "$backup_dir":/backup \
        alpine \
        tar -xzf "/backup/$backup_name" -C /data
end
