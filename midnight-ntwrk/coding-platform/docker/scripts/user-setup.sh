#!/bin/bash
# User setup script - runs as the workstation user
# This script is called from customize_environment or can be run manually

set -e

echo "Setting up Midnight development environment for user..."

# Create workspace directories if they don't exist
mkdir -p ~/workspace/projects
mkdir -p ~/workspace/templates
mkdir -p ~/.midnight

# Copy templates if not already present
if [ ! -d ~/workspace/templates/basic-token ]; then
    echo "Copying project templates..."
    cp -r /opt/templates/* ~/workspace/templates/ 2>/dev/null || true
fi

# Create a sample project if workspace is empty
if [ ! -d ~/workspace/projects/sample-token ] && [ -d /opt/templates/basic-token ]; then
    echo "Creating sample project..."
    cp -r /opt/templates/basic-token ~/workspace/projects/sample-token
    echo "Sample project created at ~/workspace/projects/sample-token"
fi

# Set up Git config if not configured (non-destructive)
if ! git config --global user.name > /dev/null 2>&1; then
    git config --global user.name "Midnight Developer"
fi

if ! git config --global user.email > /dev/null 2>&1; then
    git config --global user.email "developer@midnight.local"
fi

# Create useful aliases in .bashrc if they don't exist
if ! grep -q "# Midnight aliases" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Midnight aliases" >> ~/.bashrc
    echo "alias workspace='cd ~/workspace'" >> ~/.bashrc
    echo "alias projects='cd ~/workspace/projects'" >> ~/.bashrc
    echo "alias midnight-help='midnight help'" >> ~/.bashrc
fi

# Create a welcome file to track first-time setup
if [ ! -f ~/.midnight/setup-complete ]; then
    echo "First-time setup completed on $(date)" > ~/.midnight/setup-complete
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║   🌙 Midnight Development Environment Ready!           ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "Quick commands:"
    echo "  midnight new <name>  - Create a new project"
    echo "  midnight help        - Show all commands"
    echo "  workspace           - Go to workspace directory"
    echo "  projects            - Go to projects directory"
    echo ""
fi

echo "User environment setup complete."