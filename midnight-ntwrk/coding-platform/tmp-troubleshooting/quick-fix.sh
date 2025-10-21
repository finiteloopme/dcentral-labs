#!/bin/bash
#
# Quick Fix for OpenCode Permission Issue
# The problem: /home/ubuntu/.config is owned by root instead of ubuntu
#

echo "==========================================="
echo "OpenCode Quick Fix"
echo "==========================================="
echo ""

echo "Current problem:"
echo "  /home/ubuntu/.config is owned by root:root"
echo "  You are user ubuntu:ubuntu"
echo "  Therefore, you cannot create /home/ubuntu/.config/opencode"
echo ""

echo "Fixing permissions..."
echo ""

# Fix the .config directory ownership
echo "1. Fixing /home/ubuntu/.config ownership..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/.config
echo "   ✓ Changed owner to ubuntu:ubuntu"

# Create the opencode directories with correct ownership
echo ""
echo "2. Creating opencode directories..."
mkdir -p /home/ubuntu/.config/opencode
mkdir -p /home/ubuntu/.local/share/opencode/log
echo "   ✓ Created /home/ubuntu/.config/opencode"
echo "   ✓ Created /home/ubuntu/.local/share/opencode/log"

# Verify the fix
echo ""
echo "3. Verifying permissions..."
echo "   /home/ubuntu/.config:"
ls -ld /home/ubuntu/.config
echo "   /home/ubuntu/.config/opencode:"
ls -ld /home/ubuntu/.config/opencode

echo ""
echo "==========================================="
echo "Fix Complete!"
echo "==========================================="
echo ""
echo "You should now be able to run:"
echo "  opencode"
echo ""
echo "If you still have issues, the problem might be that other"
echo "subdirectories in .config are owned by root. You can fix all with:"
echo "  sudo chown -R ubuntu:ubuntu /home/ubuntu/.config"
echo "  sudo chown -R ubuntu:ubuntu /home/ubuntu/.local"