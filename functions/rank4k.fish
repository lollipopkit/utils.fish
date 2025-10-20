function rand4k --description "Random 4k disk bench：randread/randwrite/randrw on file or device"
    set -l target $argv[1]
    set -l mode   $argv[2]
    set -l secs   30

    if test -z "$target" -o -z "$mode"
        echo "Usage: rand4k <filename|/dev/xxx> <randread|randwrite|randrw> [runtime_s]"
        return 1
    end

    if test (count $argv) -ge 3
        set secs $argv[3]
    end

    switch $mode
        case randread randwrite randrw
            # Accept supported fio patterns as-is.
        case '*'
            echo "rand4k: unsupported mode '$mode' (use randread|randwrite|randrw)"
            return 1
    end

    set -l ioengine io_uring
    if test (uname) != Linux
        set ioengine posixaio
    end

    fio --name=rand4k-$mode \
        --filename=$target \
        --rw=$mode --bs=4k \
        --ioengine=$ioengine --direct=1 \
        --time_based=1 --runtime=$secs \
        --iodepth=64 --numjobs=4 \
        --randrepeat=0 --group_reporting
end
