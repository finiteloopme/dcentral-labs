#!/bin/bash
#
# OpenCode Permission Fix Script
# This script fixes the opencode permission issue
#

echo "==========================================="
echo "OpenCode Permission Fix"
echo "==========================================="
echo ""

# Detect current user
CURRENT_USER=$(whoami)
CURRENT_HOME=$HOME

echo "Running as: $CURRENT_USER"
echo "Home directory: $CURRENT_HOME"
echo ""

# Function to create directories with proper permissions
create_directory() {
    local dir=$1
    local owner=$2
    
    if [ ! -d "$dir" ]; then
        echo "Creating $dir..."
        sudo mkdir -p "$dir"
        sudo chown -R "$owner:$owner" "$dir"
        sudo chmod 755 "$dir"
        echo "✓ Created $dir with owner $owner"
    else
        echo "✓ $dir already exists"
        # Fix permissions anyway
        sudo chown -R "$owner:$owner" "$dir" 2>/dev/null || true
        sudo chmod 755 "$dir" 2>/dev/null || true
    fi
}

echo "Method 1: Fix /home/ubuntu permissions (if ubuntu user exists)"
echo "----------------------------------------------------------------"
if id ubuntu >/dev/null 2>&1; then
    echo "Ubuntu user exists, fixing permissions..."
    
    # Create directories for ubuntu user
    create_directory "/home/ubuntu/.config" "ubuntu"
    create_directory "/home/ubuntu/.config/opencode" "ubuntu"
    create_directory "/home/ubuntu/.local/share/opencode" "ubuntu"
    create_directory "/home/ubuntu/.local/share/opencode/log" "ubuntu"
    
    echo "✓ Ubuntu directories fixed"
else
    echo "⚠ Ubuntu user does not exist"
fi
echo ""

echo "Method 2: Fix permissions for current user ($CURRENT_USER)"
echo "------------------------------------------------------------"
# Create directories for current user
create_directory "$CURRENT_HOME/.config" "$CURRENT_USER"
create_directory "$CURRENT_HOME/.config/opencode" "$CURRENT_USER"
create_directory "$CURRENT_HOME/.local/share/opencode" "$CURRENT_USER"
create_directory "$CURRENT_HOME/.local/share/opencode/log" "$CURRENT_USER"

echo "✓ Current user directories fixed"
echo ""

echo "Method 3: Create wrapper script for opencode"
echo "---------------------------------------------"
# Create a wrapper script that sets HOME correctly
WRAPPER_SCRIPT="/tmp/opencode-wrapper.sh"
cat > $WRAPPER_SCRIPT << 'EOF'
#!/bin/bash
# OpenCode wrapper to ensure correct HOME directory

# If HOME is set to /home/ubuntu but we're not ubuntu, use real home
if [ "$HOME" = "/home/ubuntu" ] && [ "$(whoami)" != "ubuntu" ]; then
    export HOME=$(getent passwd $(whoami) | cut -d: -f6)
fi

# Ensure directories exist for current user
mkdir -p $HOME/.config/opencode 2>/dev/null
mkdir -p $HOME/.local/share/opencode/log 2>/dev/null

# Run opencode with correct HOME
exec /usr/bin/env opencode "$@"
EOF

chmod +x $WRAPPER_SCRIPT
echo "✓ Created wrapper script at $WRAPPER_SCRIPT"
echo ""

echo "==========================================="
echo "Fix Complete!"
echo "==========================================="
echo ""
echo "Try running opencode in one of these ways:"
echo ""
echo "1. Direct with HOME override:"
echo "   HOME=$CURRENT_HOME opencode"
echo ""
echo "2. Using the wrapper script:"
echo "   $WRAPPER_SCRIPT"
echo ""
echo "3. If you have sudo access and want to run as ubuntu:"
echo "   sudo -u ubuntu opencode"
echo ""
echo "4. Create an alias (add to your .bashrc):"
echo "   alias opencode='HOME=$CURRENT_HOME opencode'"
echo ""

# Also create a permanent fix script
FIX_SCRIPT="$CURRENT_HOME/.local/bin/opencode-fixed"
mkdir -p "$CURRENT_HOME/.local/bin"
cat > $FIX_SCRIPT << 'EOF'
#!/bin/bash
# Permanent opencode fix
export HOME=$(getent passwd $(whoami) | cut -d: -f6)
mkdir -p $HOME/.config/opencode 2>/dev/null
mkdir -p $HOME/.local/share/opencode/log 2>/dev/null
exec /usr/bin/env opencode "$@"
EOF
chmod +x $FIX_SCRIPT

echo "5. Permanent fix installed at:"
echo "   $FIX_SCRIPT"
echo "   Add $CURRENT_HOME/.local/bin to your PATH and use 'opencode-fixed'"