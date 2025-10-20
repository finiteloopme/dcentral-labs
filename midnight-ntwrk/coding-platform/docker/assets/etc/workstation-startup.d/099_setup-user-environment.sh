#!/bin/bash
#
# Setup user environment - DO NOT MODIFY .bashrc TO AVOID CORRUPTION
#

echo "Setting up user environment (without modifying .bashrc)..."

# For Cloud Workstations, setup happens for the 'user' account
USER_HOME="/home/user"

# Ensure the user home exists
if [ -d "$USER_HOME" ]; then
    # Create necessary directories
    mkdir -p $USER_HOME/.local/share/opencode/log
    mkdir -p $USER_HOME/.config/opencode
    
    # DO NOT TOUCH .bashrc or .bash_profile to avoid syntax errors
    # Instead, use /etc/profile.d which is automatically sourced
    
    # Ensure proper ownership
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        chown -R user:user $USER_HOME/.local 2>/dev/null || true
        chown -R user:user $USER_HOME/.config 2>/dev/null || true  
    fi
fi

echo "✓ User environment setup complete (no .bashrc modifications)"