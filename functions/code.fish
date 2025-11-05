# code - Visual Studio Code launcher with CLI fallback
#
# Provides a convenient wrapper that opens Visual Studio Code for the
# current directory by default, or for the provided files/directories.
# If the official `code` CLI is available it delegates to that so all
# flags behave exactly as upstream. Otherwise it falls back to platform
# specific launchers to still open VS Code when possible.

function code -d "Open Visual Studio Code with optional paths"
    set -l args $argv
    if test (count $args) -eq 0
        set args "."
    end

    set -l system (uname)
    set -l is_wsl false
    if test "$system" = "Linux"
        if set -q WSL_DISTRO_NAME
            set is_wsl true
        else if test -r /proc/version
            if string match -q "*Microsoft*" (cat /proc/version 2>/dev/null)
                set is_wsl true
            end
        end
    end

    if command -sq code
        command code $args
        return $status
    end

    set -l candidates \
        /usr/local/bin/code \
        /usr/bin/code \
        /snap/bin/code \
        /usr/share/code/bin/code \
        /usr/local/bin/code-insiders \
        /usr/bin/code-insiders \
        /usr/local/bin/code-oss \
        /usr/bin/code-oss

    # Probe common Windows install locations (including WSL mounts)
    if string match -r -q '^(CYGWIN|MSYS|MINGW|Windows)' $system; or test $is_wsl = true
        set -l win_envs LOCALAPPDATA USERPROFILE ProgramFiles PROGRAMFILES
        for env_name in $win_envs
            if set -q $env_name
                set -l raw $$env_name
                if test -z "$raw"
                    continue
                end

                set -l normalized (string replace -a '\\' '/' $raw)
                if string match -r -q '^[A-Za-z]:' $normalized
                    set -l drive (string lower (string sub -s 1 -l 1 $normalized))
                    set -l remainder (string sub -s 3 $normalized)
                    if test $is_wsl = true
                        set -l base "/mnt/$drive$remainder"
                    else
                        set -l base "/$drive$remainder"
                    end
                else
                    set -l base $normalized
                end

                switch $env_name
                    case LOCALAPPDATA
                        set candidates $candidates \
                            "$base/Programs/Microsoft VS Code/bin/code" \
                            "$base/Programs/Microsoft VS Code/bin/code.cmd" \
                            "$base/Programs/Microsoft VS Code Insiders/bin/code" \
                            "$base/Programs/Microsoft VS Code Insiders/bin/code.cmd"
                    case USERPROFILE
                        set candidates $candidates \
                            "$base/AppData/Local/Programs/Microsoft VS Code/bin/code" \
                            "$base/AppData/Local/Programs/Microsoft VS Code/bin/code.cmd" \
                            "$base/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code" \
                            "$base/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code.cmd"
                    case ProgramFiles PROGRAMFILES
                        set candidates $candidates \
                            "$base/Microsoft VS Code/bin/code" \
                            "$base/Microsoft VS Code/bin/code.cmd" \
                            "$base/Microsoft VS Code Insiders/bin/code" \
                            "$base/Microsoft VS Code Insiders/bin/code.cmd"
                end
            end
        end
    end

    for candidate in $candidates
        if test -x "$candidate"
            command "$candidate" $args
            return $status
        end
    end

    switch $system
        case Darwin
            if command -sq open
                open -a "Visual Studio Code" $args
                return $status
            end
        case Linux
            if command -sq flatpak
                set -l flatpak_ids com.visualstudio.code com.visualstudio.code-oss
                for flatpak_id in $flatpak_ids
                    if flatpak info $flatpak_id >/dev/null 2>&1
                        flatpak run $flatpak_id $args
                        return $status
                    end
                end
            end
    end

    echo "code: Visual Studio Code command-line interface not found. Install it via 'Shell Command: Install code command in PATH' from VS Code." >&2
    return 1
end
