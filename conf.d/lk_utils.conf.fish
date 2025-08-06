# extract.fish - Aliases and configuration for archive management utilities
#
# This configuration file sets up convenient aliases for the enhanced
# archive extraction and compression functions.

# Core extraction aliases
alias x "extract "                    # Quick extract
alias xr "extract_and_remove "         # Extract and remove source
alias xl "extract --list "             # List archive contents
alias xt "extract --test "             # Test archive integrity

# Compression aliases
alias cps "compress "                    # Quick compress
alias cpsz "compress -f zip "            # Compress to zip format
alias cps7 "compress -f 7z "             # Compress to 7z format

# Archive information and testing
alias arlist "list_archive "            # List archive contents
alias artest "test_archive "            # Test archive integrity

# Utility aliases
alias ka "kill_all "                   # Enhanced process killer
alias gtp "git_tag_push "              # Git tag management
alias dus "du_sort "                    # Directory size analysis

# Set default options for common commands (if not already set)
if not set -q EXTRACT_DEFAULT_FORMAT
    set -g EXTRACT_DEFAULT_FORMAT "tar.gz"
end

if not set -q COMPRESS_DEFAULT_LEVEL
    set -g COMPRESS_DEFAULT_LEVEL "6"  # Balanced compression level
end