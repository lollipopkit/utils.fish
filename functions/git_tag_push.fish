function git_tag_push -d "Create and push git tags with semantic versioning support"
    set -l tag ""
    set -l message ""
    set -l bump_type ""
    set -l prerelease ""
    set -l dry_run false
    set -l force false
    # `git describe` returns the nearest tag by ancestry whatever its shape, so
    # the series to bump has to be named. Without this, a tag from an unrelated
    # series (monitor-v0.1.1) parses as major="monitor-v0" and yields
    # "vmonitor-v0.1.15".
    set -l match_glob 'v[0-9]*.[0-9]*.[0-9]*'
    set -l latest_tag ""

    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "git_tag_push: not a git repository" >&2
        return 1
    end
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: git_tag_push [OPTIONS] [tag] [message]"
                echo "Create annotated git tags with automatic version bumping."
                echo ""
                echo "Options:"
                echo "  --major       Bump major version (X.0.0)"
                echo "  --minor       Bump minor version (x.Y.0)"
                echo "  --patch       Bump patch version (x.y.Z)"
                echo "  --pre PRE     Add pre-release suffix (x.y.z-PRE)"
                echo "  --match GLOB  Tag glob to bump from (default: v[0-9]*.[0-9]*.[0-9]*)"
                echo "  --dry-run     Show what would be tagged without creating tag"
                echo "  -f, --force   Force tag creation (overwrite existing)"
                echo "  -h, --help    Show this help"
                echo ""
                echo "Examples:"
                echo "  git_tag_push                    # Auto-generate next version based on commit count"
                echo "  git_tag_push v1.2.3             # Create specific tag"
                echo "  git_tag_push --minor            # Bump minor version"
                echo "  git_tag_push --pre beta         # Create pre-release tag"
                echo "  git_tag_push v2.0.0 \"Major release\" # Custom tag with message"
                return 0
            case --major
                set bump_type "major"
            case --minor
                set bump_type "minor"
            case --patch
                set bump_type "patch"
            case --pre
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set prerelease $argv[$i]
                else
                    echo "git_tag_push: --pre requires an argument" >&2
                    return 1
                end
            case --match
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set match_glob $argv[$i]
                else
                    echo "git_tag_push: --match requires an argument" >&2
                    return 1
                end
            case --dry-run
                set dry_run true
            case -f --force
                set force true
            case '-*'
                echo "git_tag_push: unknown option '$argv[$i]'" >&2
                return 1
            case '*'
                if test -z "$tag"
                    set tag $argv[$i]
                else if test -z "$message"
                    set message $argv[$i]
                else
                    echo "git_tag_push: too many arguments" >&2
                    return 1
                end
        end
        set i (math $i + 1)
    end
    
    # Latest tag of the series, used for the bump and for the message range
    set latest_tag (git describe --tags --abbrev=0 --match $match_glob 2>/dev/null; or echo "")

    # Auto-generate tag if not provided
    if test -z "$tag"
        # Whatever shape the series has - a prefix, a leading v, neither - is
        # kept, so a bump stays inside the series it came from
        set -l series_prefix ""
        set -l series_v "v"
        set -l major 0
        set -l minor 0
        set -l patch 0
        set -l commit_count 0

        if test -n "$latest_tag"
            # Full match plus five groups; anything else is not a version and
            # guessing one from it is how a wrong tag gets pushed
            set -l parts (string match -r '^(.*?)(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(?:[-+].*)?$' -- $latest_tag)
            if test (count $parts) -ne 6
                echo "git_tag_push: cannot parse a version from '$latest_tag'" >&2
                echo "Pass a tag explicitly, or narrow the series with --match GLOB." >&2
                return 1
            end
            set series_prefix $parts[2]
            set series_v $parts[3]
            set major $parts[4]
            set minor $parts[5]
            set patch $parts[6]
            set commit_count (git rev-list --count "$latest_tag..HEAD" 2>/dev/null; or echo "0")
        else
            set commit_count (git rev-list --count HEAD 2>/dev/null; or echo "0")
        end

        # Apply version bump based on type
        if test -n "$bump_type"
            # Manual bump type specified - ignore commit count
            switch $bump_type
                case major
                    set major (math $major + 1)
                    set minor 0
                    set patch 0
                case minor
                    set minor (math $minor + 1)
                    set patch 0
                case patch
                    set patch (math $patch + 1)
            end
        else
            # Auto bump - patch + commit count
            if test $commit_count -eq 0
                echo "git_tag_push: no new commits since last tag '$latest_tag'" >&2
                return 1
            end
            set patch (math $patch + $commit_count)
        end

        # Construct new tag
        set tag "$series_prefix$series_v$major.$minor.$patch"
        if test -n "$prerelease"
            set tag "$tag-$prerelease"
        end
    end
    
    # Generate message if not provided
    if test -z "$message"
        # Try to generate message from recent commits
        set -l commit_range HEAD
        set -l log_limit -n 10
        if test -n "$latest_tag"
            set commit_range "$latest_tag..HEAD"
            set log_limit
        end

        set -l recent_commits (git log --pretty=format:"%s" $log_limit $commit_range 2>/dev/null)
        if test -n "$recent_commits"
            set message "Release $tag

Recent changes:"
            for commit in $recent_commits
                set message "$message
- $commit"
            end
        else
            set message "Release $tag"
        end
    end
    
    # Check if tag already exists
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null
        if test $force = false
            echo "git_tag_push: tag '$tag' already exists (use --force to overwrite)" >&2
            return 1
        else
            echo "Warning: Tag '$tag' already exists and will be overwritten"
        end
    end
    
    # Display what will be done
    echo "Tag: $tag"
    echo "Message: $message"
    echo "Commit: "(git rev-parse --short HEAD)
    
    if test $dry_run = true
        echo "Dry run mode - no tag was created"
        return 0
    end
    
    # Confirm before creating tag
    echo ""
    echo "Create and push this tag? (y/N)"
    read -l response
    if not string match -qi 'y*' "$response"
        echo "Operation cancelled"
        return 1
    end
    
    # Create the tag
    set -l tag_args
    if test $force = true
        set tag_args $tag_args "-f"
    end
    
    if not git tag -a $tag_args "$tag" -m "$message"
        echo "git_tag_push: failed to create tag '$tag'" >&2
        return 1
    end
    
    # Push the tag
    set -l push_args
    if test $force = true
        set push_args $push_args "--force"
    end
    
    if not git push origin $push_args "$tag"
        echo "git_tag_push: failed to push tag '$tag'" >&2
        echo "Tag created locally but not pushed. Use 'git push origin $tag' to push manually."
        return 1
    end
    
    echo "✓ Tag '$tag' created and pushed successfully"
    
    return 0
end