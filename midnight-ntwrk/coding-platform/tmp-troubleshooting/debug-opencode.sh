#!/bin/bash
#
# OpenCode Permission Debug Script
# This script helps diagnose the opencode permission issue
#

echo "==========================================="
echo "OpenCode Permission Debugging"
echo "==========================================="
echo ""

echo "1. Current User Information:"
echo "----------------------------"
echo "Username: $(whoami)"
echo "User ID: $(id -u)"
echo "Group ID: $(id -g)"
echo "Home Directory: $HOME"
echo "Current Directory: $(pwd)"
echo ""

echo "2. Ubuntu User Check:"
echo "---------------------"
if [ -d /home/ubuntu ]; then
    echo "/home/ubuntu exists"
    echo "Permissions: $(ls -ld /home/ubuntu)"
    echo ""
    
    if [ -d /home/ubuntu/.config ]; then
        echo "/home/ubuntu/.config exists"
        echo "Permissions: $(ls -ld /home/ubuntu/.config)"
    else
        echo "/home/ubuntu/.config does NOT exist"
    fi
    echo ""
    
    echo "Can you write to /home/ubuntu/.config?"
    if touch /home/ubuntu/.config/test-write 2>/dev/null; then
        echo "YES - Write successful"
        rm -f /home/ubuntu/.config/test-write
    else
        echo "NO - Permission denied"
    fi
else
    echo "/home/ubuntu does NOT exist"
fi
echo ""

echo "3. OpenCode Installation:"
echo "-------------------------"
if command -v opencode >/dev/null 2>&1; then
    echo "OpenCode found at: $(which opencode)"
    echo "OpenCode version:"
    opencode --version 2>&1 || echo "Could not get version"
    echo ""
    echo "OpenCode binary details:"
    ls -la $(which opencode) 2>/dev/null
else
    echo "OpenCode NOT found in PATH"
fi
echo ""

echo "4. Environment Variables:"
echo "-------------------------"
echo "HOME=$HOME"
echo "USER=$USER"
echo "PATH=$PATH"
echo ""

echo "5. Suggested Directories:"
echo "-------------------------"
echo "Your config directory should be: $HOME/.config/opencode"
echo "Your log directory should be: $HOME/.local/share/opencode/log"
echo ""

echo "6. Check if your directories exist:"
echo "------------------------------------"
if [ -d "$HOME/.config" ]; then
    echo "$HOME/.config exists"
    echo "Permissions: $(ls -ld $HOME/.config)"
else
    echo "$HOME/.config does NOT exist"
fi

if [ -d "$HOME/.config/opencode" ]; then
    echo "$HOME/.config/opencode exists"
    echo "Permissions: $(ls -ld $HOME/.config/opencode)"
else
    echo "$HOME/.config/opencode does NOT exist"
fi
echo ""

echo "==========================================="
echo "Diagnosis Complete"
echo "==========================================="