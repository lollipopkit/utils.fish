# Restore a Docker volume from a tar.gz backup file
#
# Usage:
#   dvrst <backup_file> [volume_name]
## Examples:
#   dvrst my-vol.tar.gz         # restores to volume 'my-vol'
#   dvrst backup.tgz my-vol     # restores to volume 'my-vol'
function dvrst --description "Restore a Docker volume from a tar.gz backup file"
    if test (count $argv) -lt 2
        echo "Usage: dvrst <backup_file> [volume_name]"
        return 1
    end

    set backup_file $argv[1]

    # Set volume name
    if test (count $argv) -ge 2
        set volume $argv[2]
    else
        set volume (string replace -r '\.tar\.gz$' '' (basename $backup_file))
    end

    if not test -f $backup_file
        echo "Error: Backup file '$backup_file' not found."
        return 1
    end

    # Create the volume if it doesn't exist
    docker volume create $volume > /dev/null

    # Restore the backup
    docker run --rm \
        -v $volume:/data \
        -v (pwd):/backup \
        alpine \
        sh -c "cd /data && tar xzf /backup/(basename $backup_file)"
end
