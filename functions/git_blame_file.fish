function git_blame_file -d "Quickly view git blame for a file"
    if test (count $argv) -eq 0
        echo "Usage: git_blame_file <file> [line|start,end] [git blame options]" >&2
        echo "Example: git_blame_file README.md" >&2
        echo "Example: git_blame_file README.md 42" >&2
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "git_blame_file: not a git repository" >&2
        return 1
    end

    set -l target $argv[1]

    if not test -e "$target"
        echo "git_blame_file: file not found: $target" >&2
        return 1
    end

    set -l blame_args

    if test (count $argv) -ge 2
        if string match -rq '^[0-9]+$' -- $argv[2]
            set blame_args -L "$argv[2],$argv[2]" $argv[3..-1]
        else if string match -rq '^[0-9]+,[0-9]+$' -- $argv[2]
            set blame_args -L "$argv[2]" $argv[3..-1]
        else
            set blame_args $argv[2..-1]
        end
    end

    git blame --date=short $blame_args -- "$target"
end
