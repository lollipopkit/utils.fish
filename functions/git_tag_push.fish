# git_tag_push - Enhanced git tagging with semantic versioning support
#
# Creates annotated git tags with automatic version bumping and semantic versioning.
# Supports conventional commit style messages and automatic changelog generation.
#
# Usage: git_tag_push [OPTIONS] [tag] [message]
# Options:
#   --major     Bump major version (X.0.0)
#   --minor     Bump minor version (x.Y.0)
#   --patch     Bump patch version (x.y.Z)
#   --pre PRE   Add pre-release suffix (x.y.z-PRE)
#   --dry-run   Show what would be tagged without creating tag
#   -f, --force Force tag creation (overwrite existing)
#   -h, --help  Show help message

function git_tag_push -d "Create and push git tags with semantic versioning support"
    set -l tag ""
    set -l message ""
    set -l bump_type ""
    set -l prerelease ""
    set -l dry_run false
    set -l force false
    
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
                echo "  --dry-run     Show what would be tagged without creating tag"
                echo "  -f, --force   Force tag creation (overwrite existing)"
                echo "  -h, --help    Show this help"
                echo ""
                echo "Examples:"
                echo "  git_tag_push                    # Auto-generate next patch version"
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
    
    # Auto-generate tag if not provided
    if test -z "$tag"
        # Get the latest tag
        set -l latest_tag (git describe --tags --abbrev=0 2>/dev/null; or echo "v0.0.0")
        
        # Parse version components
        set -l version (string replace -r '^v?(.*)$' '$1' "$latest_tag")
        set -l parts (string split '.' "$version")
        
        if test (count $parts) -ge 3
            set -l major $parts[1]
            set -l minor $parts[2]
            set -l patch (string replace -r '(\d+).*' '$1' $parts[3])
            
            # Determine bump type if not specified
            if test -z "$bump_type"
                set bump_type "patch"
            end
            
            # Apply version bump
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
            
            # Construct new tag
            set tag "v$major.$minor.$patch"
            if test -n "$prerelease"
                set tag "$tag-$prerelease"
            end
        else
            # Fallback to commit count method
            set -l count (git rev-list --count HEAD)
            set tag "v1.0.$count"
        end
    end
    
    # Generate message if not provided
    if test -z "$message"
        # Try to generate message from recent commits
        set -l recent_commits (git log --oneline -10 --pretty=format:"%s")
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
    if git tag -l "$tag" | grep -q "$tag"
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
    
    # Show tag information
    git show --stat "$tag"
    
    return 0
end
