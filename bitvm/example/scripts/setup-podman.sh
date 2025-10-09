#!/bin/bash

# Setup script for Podman
# This script installs and configures Podman for BitVM3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 BitVM3 Podman Setup${NC}"
echo "========================="

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

# Check if Podman is installed
if command -v podman &> /dev/null; then
    echo -e "${GREEN}✅ Podman is already installed${NC}"
    podman --version
else
    echo -e "${YELLOW}📦 Installing Podman...${NC}"
    
    if [[ "$OS" == "linux" ]]; then
        # Install on Ubuntu/Debian
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y podman podman-compose
            
        # Install on Fedora/RHEL/CentOS
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y podman podman-compose
            
        # Install on Arch
        elif command -v pacman &> /dev/null; then
            sudo pacman -S podman podman-compose
            
        else
            echo -e "${RED}Unable to detect package manager${NC}"
            echo "Please install Podman manually: https://podman.io/getting-started/installation"
            exit 1
        fi
        
    elif [[ "$OS" == "macos" ]]; then
        # Install on macOS using Homebrew
        if command -v brew &> /dev/null; then
            brew install podman podman-compose
            
            # Initialize and start Podman machine on macOS
            echo -e "${BLUE}Initializing Podman machine...${NC}"
            podman machine init
            podman machine start
        else
            echo -e "${RED}Homebrew not found${NC}"
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    fi
fi

# Install podman-compose if not present
if ! command -v podman-compose &> /dev/null; then
    echo -e "${YELLOW}📦 Installing podman-compose...${NC}"
    
    # Install via pip
    if command -v pip3 &> /dev/null; then
        pip3 install --user podman-compose
    else
        echo -e "${RED}pip3 not found. Installing python3-pip...${NC}"
        if [[ "$OS" == "linux" ]]; then
            sudo apt-get install -y python3-pip || sudo dnf install -y python3-pip
        elif [[ "$OS" == "macos" ]]; then
            brew install python3
        fi
        pip3 install --user podman-compose
    fi
fi

# Configure Podman for rootless operation
echo -e "${BLUE}🔧 Configuring Podman for rootless operation...${NC}"

# Check subuid/subgid entries
if [[ "$OS" == "linux" ]]; then
    if ! grep -q "^$USER:" /etc/subuid; then
        echo -e "${YELLOW}Adding subuid entries...${NC}"
        sudo usermod --add-subuids 100000-165535 $USER
    fi
    
    if ! grep -q "^$USER:" /etc/subgid; then
        echo -e "${YELLOW}Adding subgid entries...${NC}"
        sudo usermod --add-subgids 100000-165535 $USER
    fi
fi

# Enable lingering for user services
if [[ "$OS" == "linux" ]]; then
    loginctl enable-linger $USER 2>/dev/null || true
fi

# Create Podman configuration directory
mkdir -p ~/.config/containers

# Configure registries
echo -e "${BLUE}🔧 Configuring container registries...${NC}"
cat > ~/.config/containers/registries.conf << EOF
[registries.search]
registries = ['docker.io', 'quay.io', 'registry.fedoraproject.org']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF

# Set up Docker compatibility
echo -e "${BLUE}🔧 Setting up Docker compatibility...${NC}"

# Create docker command alias for podman
if ! grep -q "alias docker=podman" ~/.bashrc 2>/dev/null; then
    echo "alias docker=podman" >> ~/.bashrc
    echo "alias docker-compose=podman-compose" >> ~/.bashrc
fi

if ! grep -q "alias docker=podman" ~/.zshrc 2>/dev/null; then
    echo "alias docker=podman" >> ~/.zshrc 2>/dev/null || true
    echo "alias docker-compose=podman-compose" >> ~/.zshrc 2>/dev/null || true
fi

# Enable podman socket for Docker compatibility
if [[ "$OS" == "linux" ]]; then
    systemctl --user enable --now podman.socket 2>/dev/null || true
fi

# Verify installation
echo -e "${BLUE}🔍 Verifying installation...${NC}"
echo -e "Podman version: $(podman --version)"
echo -e "Podman-compose version: $(podman-compose --version 2>/dev/null || echo 'Not installed')"

# Test Podman
echo -e "${BLUE}🧪 Testing Podman...${NC}"
podman run --rm docker.io/hello-world

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Podman is working correctly!${NC}"
else
    echo -e "${RED}❌ Podman test failed${NC}"
    exit 1
fi

# Print usage information
echo ""
echo -e "${GREEN}✅ Podman setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Usage Notes:${NC}"
echo "1. Podman commands are identical to Docker:"
echo "   podman run, podman build, podman ps, etc."
echo ""
echo "2. Use podman-compose instead of docker-compose:"
echo "   podman-compose up -d"
echo ""
echo "3. Rootless mode is enabled by default (more secure)"
echo ""
echo "4. Docker aliases have been added to your shell"
echo "   Source your shell config to use them:"
echo "   source ~/.bashrc  # or ~/.zshrc"
echo ""
echo "5. To use with the Makefile:"
echo "   make docker-up    # Will use podman-compose"
echo "   make docker-down  # Will use podman"
echo ""

# Check if we need to restart the shell
if [[ "$OS" == "linux" ]]; then
    echo -e "${YELLOW}⚠️  You may need to log out and back in for subuid/subgid changes to take effect${NC}"
fi

echo -e "${BLUE}🚀 You can now use 'make docker-up' to start the BitVM3 services with Podman!${NC}"