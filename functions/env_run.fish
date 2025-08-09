# env_run - Enhanced environment file processor and command runner
#
# Loads environment variables from .env files and runs commands with those variables.
# Supports multiple .env files, variable substitution, and various formats.
#
# Usage: env_run [OPTIONS] <command> [args...]
# Options:
#   -f, --file FILE     Use specific env file (default: .env)
#   -d, --dir DIR       Look for .env file in specific directory
#   -s, --show          Show loaded environment variables
#   -v, --validate      Validate .env file format
#   --export            Export variables to current shell (fish only)
#   -h, --help          Show help message

function env_run -d "Run commands with environment variables from .env files"
    set -l env_file ".env"
    set -l env_dir "."
    set -l show_vars false
    set -l validate_only false
    set -l export_vars false
    set -l command_args
    
    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: env_run [OPTIONS] <command> [args...]"
                echo "Run commands with environment variables from .env files."
                echo ""
                echo "Options:"
                echo "  -f, --file FILE     Use specific env file (default: .env)"
                echo "  -d, --dir DIR       Look for .env file in directory"
                echo "  -s, --show          Show loaded environment variables"
                echo "  -v, --validate      Validate .env file format only"
                echo "  --export            Export variables to current shell"
                echo "  -h, --help          Show this help"
                echo ""
                echo "Examples:"
                echo "  env_run python app.py          # Run with .env variables"
                echo "  env_run -f prod.env npm start   # Use prod.env file"
                echo "  env_run -s -v                   # Show and validate .env"
                echo "  env_run --export                # Export vars to current shell"
                echo ""
                echo ".env file format:"
                echo "  KEY=value          # Simple assignment"
                echo "  KEY=\"value\"        # Quoted value"
                echo "  # Comment          # Comments start with #"
                echo "  KEY=\$OTHER_VAR     # Variable substitution"
                return 0
            case -f --file
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set env_file $argv[$i]
                else
                    echo "env_run: --file requires an argument" >&2
                    return 1
                end
            case -d --dir
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set env_dir $argv[$i]
                else
                    echo "env_run: --dir requires an argument" >&2
                    return 1
                end
            case -s --show
                set show_vars true
            case -v --validate
                set validate_only true
            case --export
                set export_vars true
            case '-*'
                echo "env_run: unknown option '$argv[$i]'" >&2
                return 1
            case '*'
                set command_args $command_args $argv[$i]
        end
        set i (math $i + 1)
    end
    
    # Construct full path to env file
    set -l full_env_path "$env_dir/$env_file"
    if not string match -q '/*' "$env_file"
        # Relative path
        set full_env_path "$env_dir/$env_file"
    else
        # Absolute path
        set full_env_path "$env_file"
    end
    
    # Check if .env file exists
    if not test -f "$full_env_path"
        echo "env_run: env file '$full_env_path' not found" >&2
        return 1
    end
    
    # Read and parse .env file
    set -l env_vars
    set -l invalid_lines
    set -l line_number 0
    
    while read -l line
        set line_number (math $line_number + 1)
        
        # Skip empty lines and comments
        if test -z "$line"; or string match -q '#*' "$line"
            continue
        end
        
        # Validate line format (KEY=VALUE)
        if string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' "$line"
            # Extract key and value
            set -l key (string replace -r '=.*' '' "$line")
            set -l value (string replace -r '^[^=]*=' '' "$line")
            
            # Remove quotes if present
            set value (string replace -r '^"(.*)"$' '$1' "$value")
            set value (string replace -r "^'(.*)'\$" '$1' "$value")
            
            # Basic variable substitution (${VAR} or $VAR)
            while string match -qr '\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)' "$value"
                set -l var_name (string replace -r '.*\$\{([^}]+)\}.*|.*\$([A-Za-z_][A-Za-z0-9_]*).*' '$1$2' "$value")
                set -l var_value ""
                
                # Look up variable value (from environment or previously loaded)
                if set -q $var_name
                    set var_value $$var_name
                end
                
                # Replace in value
                set value (string replace "\$\{$var_name\}" "$var_value" "$value")
                set value (string replace "\$$var_name" "$var_value" "$value")
            end
            
            set env_vars $env_vars "$key=$value"
        else
            set invalid_lines $invalid_lines "Line $line_number: $line"
        end
    end < "$full_env_path"
    
    # Show validation results
    if test (count $invalid_lines) -gt 0
        echo "Warning: Invalid lines found in $full_env_path:" >&2
        for invalid in $invalid_lines
            echo "  $invalid" >&2
        end
        if test $validate_only = true
            return 1
        end
    end
    
    if test $validate_only = true
        echo "✓ Environment file '$full_env_path' is valid"
        echo "Found "(count $env_vars)" environment variable(s)"
        return 0
    end
    
    # Show variables if requested
    if test $show_vars = true
        echo "Loaded environment variables from '$full_env_path':"
        for env_var in $env_vars
            echo "  $env_var"
        end
        echo ""
    end
    
    # Export to current shell if requested (Fish shell specific)
    if test $export_vars = true
        echo "Exporting variables to current shell:"
        for env_var in $env_vars
            set -l key (string replace -r '=.*' '' "$env_var")
            set -l value (string replace -r '^[^=]*=' '' "$env_var")
            set -gx $key "$value"
            echo "  export $key='$value'"
        end
        return 0
    end
    
    # Check if we have a command to run
    if test (count $command_args) -eq 0
        if not test $show_vars = true
            echo "Usage: env_run [OPTIONS] <command> [args...]" >&2
            return 1
        end
        return 0
    end
    
    # Run the command with loaded environment
    if test $show_vars = true
        echo "Running command: $command_args"
        echo ""
    end
    
    env $env_vars $command_args
end
