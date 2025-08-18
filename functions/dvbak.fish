# dvbak - Backup a Docker volume to a tar.gz archive
#
# Usage:
#   dvbak <volume_name> [backup_name]
#
# Examples:
#   dvbak my-vol             # produces ./my-vol.tar.gz
#   dvbak my-vol backup.tgz  # produces ./backup.tgz
function dvbak --description "Backup a Docker volume to a tar.gz file"
    if test (count $argv) -lt 1
        echo "Usage: dvbak <volume_name> [backup_name]"
        return 1
    end

    set volume $argv[1]
    set backup_name (string replace -a ' ' '_' $argv[2])

    if test -z "$backup_name"
        set backup_name "$volume.tar.gz"
    end

    docker run --rm \
        -v $volume:/data \
        -v (pwd):/backup \
        alpine \
        tar czf /backup/$backup_name -C /data .
end
