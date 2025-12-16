#!/bin/bash
# OpenCode System and User Configuration Setup
# Sets up OpenCode for all users in Cloud Workstation environment

echo "🔧 Setting up OpenCode configuration..."

# Fix Cloud Workstations gcloud check by creating required user structure
# This prevents the annoying error message about missing gcloud config
if [ ! -d "/home/user" ]; then
    echo "🔧 Creating Cloud Workstations user structure to prevent gcloud errors..."
    sudo mkdir -p /home/user/.config/gcloud
    echo "False" | sudo tee /home/user/.config/gcloud/gce > /dev/null
    sudo chown -R root:root /home/user
    echo "✅ Fixed Cloud Workstations gcloud configuration"
fi

# Create system-wide OpenCode config directory
sudo mkdir -p /etc/opencode
sudo mkdir -p /usr/local/share/opencode

# Copy OpenCode configuration template to system location
if [ -f "/tmp/midnight-config/opencode-config-template.json" ]; then
    sudo cp /tmp/midnight-config/opencode-config-template.json /etc/opencode/opencode.json
    sudo chmod 644 /etc/opencode/opencode.json
    
    # Create a script that copies config to user's home on first login
    sudo tee /usr/local/share/opencode/setup-user-config.sh > /dev/null << 'EOF'
#!/bin/bash
# Setup OpenCode configuration for user

USER_HOME="$1"
if [ -z "$USER_HOME" ]; then
    USER_HOME="$HOME"
fi

# Create user's OpenCode config directory
mkdir -p "$USER_HOME/.config/opencode"

# Copy system config if user config doesn't exist
if [ ! -f "$USER_HOME/.config/opencode/opencode.json" ] && [ -f "/etc/opencode/opencode.json" ]; then
    cp /etc/opencode/opencode.json "$USER_HOME/.config/opencode/opencode.json"
    if [ -n "$USER_HOME" ]; then
        chown "$(stat -c %U:%G "$USER_HOME" 2>/dev/null || echo "root:root")" "$USER_HOME/.config/opencode/opencode.json"
    fi
fi
EOF

    sudo chmod +x /usr/local/share/opencode/setup-user-config.sh
    
    # Set up user's OpenCode config for all common users
    for USER_DIR in "/home/ubuntu" "/home/user" "/root"; do
        if [ -d "$USER_DIR" ]; then
            echo "🔧 Setting up OpenCode for user: $(basename "$USER_DIR")"
            /usr/local/share/opencode/setup-user-config.sh "$USER_DIR"
        fi
    done
    
    echo "✅ OpenCode system configuration installed"
else
    echo "⚠️  OpenCode configuration template not found"
fi

# Create symlink to ensure opencode is in standard PATH
if [ -f "/usr/local/opencode/opencode" ] && [ ! -f "/usr/local/bin/opencode" ]; then
    sudo ln -sf /usr/local/opencode/opencode /usr/local/bin/opencode
    echo "✅ Created opencode symlink in /usr/local/bin"
fi

# Add opencode to system-wide profile for all users
if ! grep -q "/usr/local/opencode" /etc/profile 2>/dev/null; then
    echo 'export PATH="/usr/local/opencode:$PATH"' | sudo tee -a /etc/profile
    echo "✅ Added opencode to system-wide PATH"
fi

# Ensure OpenCode is in PATH
if command -v opencode &> /dev/null; then
    echo "✅ OpenCode is available at: $(which opencode)"
else
    echo "⚠️  OpenCode not found in PATH"
fi

# Add opencode setup to skeleton profile for all future users
if ! grep -q "setup-user-config.sh" /etc/skel/.bashrc 2>/dev/null; then
    echo '# Setup OpenCode configuration on shell startup' | sudo tee -a /etc/skel/.bashrc
    echo 'if [ -x /usr/local/share/opencode/setup-user-config.sh ]; then' | sudo tee -a /etc/skel/.bashrc
    echo '    /usr/local/share/opencode/setup-user-config.sh "$HOME"' | sudo tee -a /etc/skel/.bashrc
    echo 'fi' | sudo tee -a /etc/skel/.bashrc
    echo '' | sudo tee -a /etc/skel/.bashrc
    echo "✅ Added OpenCode setup to skeleton profile"
fi