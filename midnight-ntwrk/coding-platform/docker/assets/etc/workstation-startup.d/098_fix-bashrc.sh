#!/bin/bash
#
# Fix potentially corrupted .bashrc files in Cloud Workstations
# This runs early in the startup sequence to ensure .bashrc is valid
#

echo "Checking and fixing .bashrc files..."

# Function to validate and fix .bashrc
fix_bashrc() {
    local bashrc_file="$1"
    
    if [ ! -f "$bashrc_file" ]; then
        return 0
    fi
    
    # Check for common syntax errors
    local temp_file="/tmp/bashrc_check_$$"
    
    # Test if the file has bash syntax errors
    if ! bash -n "$bashrc_file" 2>/dev/null; then
        echo "Found syntax errors in $bashrc_file, attempting to fix..."
        
        # Create a backup
        cp "$bashrc_file" "${bashrc_file}.backup.$(date +%Y%m%d%H%M%S)"
        
        # Try to fix common issues:
        # 1. Add missing 'esac' after color prompt case statement
        # 2. Fix incomplete case statements
        sed -i '
            # Fix first case statement (around line 40)
            /^case "\$TERM" in$/,/^[^[:space:]]/ {
                /xterm-color|\*-256color) color_prompt=yes;;$/ {
                    a\
esac
                }
            }
        ' "$bashrc_file"
        
        # Test again
        if ! bash -n "$bashrc_file" 2>/dev/null; then
            echo "Still has errors, applying more comprehensive fix..."
            
            # More aggressive fix: ensure all case statements are closed
            awk '
                /^case .* in$/ { case_count++ }
                /^esac$/ { case_count-- }
                { print }
                END {
                    while(case_count > 0) {
                        print "esac"
                        case_count--
                    }
                }
            ' "$bashrc_file" > "$temp_file"
            
            # Verify the fixed version
            if bash -n "$temp_file" 2>/dev/null; then
                mv "$temp_file" "$bashrc_file"
                echo "✓ Fixed $bashrc_file"
            else
                echo "Unable to auto-fix $bashrc_file, using minimal safe version"
                # Create a minimal working .bashrc
                cat > "$bashrc_file" << 'SAFE_BASHRC'
# Minimal safe .bashrc for Cloud Workstations

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Basic prompt
PS1='\u@\h:\w\$ '

# History settings
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Window size
shopt -s checkwinsize

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Source profile.d scripts for Midnight environment
for script in /etc/profile.d/*.sh; do
    [ -r "$script" ] && . "$script"
done

# Source Midnight environment if available
[ -f ~/.midnight-env.sh ] && source ~/.midnight-env.sh
SAFE_BASHRC
            fi
        fi
        
        rm -f "$temp_file"
    else
        echo "✓ $bashrc_file syntax is valid"
    fi
}

# Fix root's .bashrc if it exists
[ -f /root/.bashrc ] && fix_bashrc /root/.bashrc

# Fix user's .bashrc
if [ -d /home/user ]; then
    fix_bashrc /home/user/.bashrc
fi

# Fix any other user home directories
for homedir in /home/*; do
    if [ -d "$homedir" ] && [ -f "$homedir/.bashrc" ]; then
        fix_bashrc "$homedir/.bashrc"
    fi
done

echo "✓ .bashrc validation complete"