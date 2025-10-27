function sshfwd -d "Forward a port via SSH"
    if test (count $argv) -lt 2
        echo "Usage: sshfwd <remote_host> <remote_port> [-lp <local_port>] [-b]"
        return 1
    end

    set remote_host $argv[1]
    set remote_port $argv[2]
    set local_port $remote_port
    set background_mode false
    
    # Parse remaining arguments
    set i 3
    while test $i -le (count $argv)
        switch $argv[$i]
            case '-b'
                set background_mode true
            case '-lp'
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set local_port $argv[$i]
                end
        end
        set i (math $i + 1)
    end

    echo "Forwarding localhost:$local_port -> $remote_host:$remote_port"
    if test $background_mode = true
        echo "Running in background mode..."
        ssh -f -N -L $local_port:localhost:$remote_port $remote_host
    else
        ssh -L $local_port:localhost:$remote_port $remote_host
    end
end
