#!/bin/bash

# Install script for Web3 Workstation dependencies
# Supports multiple OS and package managers

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            PKG_MANAGER="apt"
            print_info "Detected Debian/Ubuntu Linux"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            PKG_MANAGER="dnf"
            print_info "Detected RedHat/Fedora/CentOS Linux"
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            PKG_MANAGER="pacman"
            print_info "Detected Arch Linux"
        elif [ -f /etc/alpine-release ]; then
            OS="alpine"
            PKG_MANAGER="apk"
            print_info "Detected Alpine Linux"
        else
            OS="linux"
            PKG_MANAGER="unknown"
            print_warning "Unknown Linux distribution"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
        print_info "Detected macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        PKG_MANAGER="choco"
        print_info "Detected Windows"
    else
        OS="unknown"
        PKG_MANAGER="unknown"
        print_error "Unknown operating system: $OSTYPE"
        exit 1
    fi
}

# Check if running with proper permissions
check_permissions() {
    if [ "$OS" != "macos" ] && [ "$OS" != "windows" ] && [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            print_warning "This script needs sudo privileges for some installations"
            SUDO="sudo"
        else
            print_error "Please run this script with sudo or as root"
            exit 1
        fi
    else
        SUDO=""
    fi
}

# Install gcloud CLI
install_gcloud() {
    print_info "Installing Google Cloud SDK..."
    
    case "$OS" in
        debian)
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
                $SUDO tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            $SUDO apt-get install -y apt-transport-https ca-certificates gnupg
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
                $SUDO apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            $SUDO apt-get update && $SUDO apt-get install -y google-cloud-sdk
            ;;
        redhat)
            $SUDO tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
            $SUDO dnf install -y google-cloud-sdk
            ;;
        arch)
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm google-cloud-sdk
            else
                print_warning "Installing from official script..."
                curl https://sdk.cloud.google.com | bash
                source $HOME/.bashrc
            fi
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install --cask google-cloud-sdk
            else
                print_warning "Homebrew not found, using official installer"
                curl https://sdk.cloud.google.com | bash
                source $HOME/.bash_profile
            fi
            ;;
        windows)
            if command -v choco >/dev/null 2>&1; then
                choco install gcloudsdk -y
            else
                print_error "Please install from: https://cloud.google.com/sdk/docs/install"
                return 1
            fi
            ;;
        *)
            print_warning "Using generic installer"
            curl https://sdk.cloud.google.com | bash
            source $HOME/.bashrc
            ;;
    esac
    
    print_status "Google Cloud SDK installed"
}

# Install Terraform
install_terraform() {
    print_info "Installing Terraform..."
    
    case "$OS" in
        debian)
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
                $SUDO tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
                $SUDO tee /etc/apt/sources.list.d/hashicorp.list
            $SUDO apt-get update && $SUDO apt-get install -y terraform
            ;;
        redhat)
            $SUDO dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            $SUDO dnf install -y terraform
            ;;
        arch)
            $SUDO pacman -S --noconfirm terraform
            ;;
        alpine)
            $SUDO apk add terraform
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew tap hashicorp/tap
                brew install hashicorp/tap/terraform
            else
                print_error "Please install Homebrew first: https://brew.sh"
                return 1
            fi
            ;;
        windows)
            if command -v choco >/dev/null 2>&1; then
                choco install terraform -y
            else
                print_error "Please install from: https://www.terraform.io/downloads"
                return 1
            fi
            ;;
        *)
            print_warning "Installing Terraform from binary"
            TERRAFORM_VERSION="1.6.0"
            wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
            unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
            $SUDO mv terraform /usr/local/bin/
            rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
            ;;
    esac
    
    print_status "Terraform installed"
}

# Install Podman
install_podman() {
    print_info "Installing Podman..."
    
    case "$OS" in
        debian)
            $SUDO apt-get update
            $SUDO apt-get install -y podman
            ;;
        redhat)
            $SUDO dnf install -y podman
            ;;
        arch)
            $SUDO pacman -S --noconfirm podman
            ;;
        alpine)
            $SUDO apk add podman
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install podman
                print_info "Initializing Podman machine..."
                podman machine init
                podman machine start
            else
                print_error "Please install Homebrew first: https://brew.sh"
                return 1
            fi
            ;;
        windows)
            print_warning "Podman on Windows requires WSL2"
            print_info "Please follow: https://github.com/containers/podman/blob/main/docs/tutorials/podman-for-windows.md"
            ;;
        *)
            print_error "Podman installation not supported for this OS"
            return 1
            ;;
    esac
    
    print_status "Podman installed"
}

# Install Docker (alternative to Podman)
install_docker() {
    print_info "Installing Docker..."
    
    case "$OS" in
        debian)
            $SUDO apt-get update
            $SUDO apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
                $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
                https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io
            
            # Add current user to docker group
            $SUDO usermod -aG docker $USER
            print_warning "You need to log out and back in for docker group changes to take effect"
            ;;
        redhat)
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io
            $SUDO systemctl start docker
            $SUDO systemctl enable docker
            $SUDO usermod -aG docker $USER
            ;;
        arch)
            $SUDO pacman -S --noconfirm docker
            $SUDO systemctl start docker
            $SUDO systemctl enable docker
            $SUDO usermod -aG docker $USER
            ;;
        macos)
            print_info "Please install Docker Desktop from: https://docs.docker.com/desktop/mac/install/"
            ;;
        windows)
            print_info "Please install Docker Desktop from: https://docs.docker.com/desktop/windows/install/"
            ;;
        *)
            print_error "Docker installation not supported for this OS"
            return 1
            ;;
    esac
    
    print_status "Docker installed"
}

# Install additional tools
install_additional_tools() {
    print_info "Installing additional helpful tools..."
    
    case "$OS" in
        debian)
            $SUDO apt-get install -y jq git curl wget unzip
            ;;
        redhat)
            $SUDO dnf install -y jq git curl wget unzip
            ;;
        arch)
            $SUDO pacman -S --noconfirm jq git curl wget unzip
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install jq git
            fi
            ;;
        *)
            print_warning "Skipping additional tools for this OS"
            ;;
    esac
}

# Main installation flow
main() {
    echo ""
    echo "======================================"
    echo "Web3 Workstation Dependency Installer"
    echo "======================================"
    echo ""
    
    # Detect OS
    detect_os
    check_permissions
    
    # Check what's missing
    MISSING_DEPS=""
    
    echo ""
    print_info "Checking installed dependencies..."
    
    # Check gcloud
    if ! command -v gcloud >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS gcloud"
        echo "  • gcloud: $(print_error "Not installed")"
    else
        echo "  • gcloud: $(print_status "Installed")"
    fi
    
    # Check terraform
    if ! command -v terraform >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS terraform"
        echo "  • terraform: $(print_error "Not installed")"
    else
        echo "  • terraform: $(print_status "Installed")"
    fi
    
    # Check container runtime
    if command -v podman >/dev/null 2>&1; then
        echo "  • podman: $(print_status "Installed")"
    elif command -v docker >/dev/null 2>&1; then
        echo "  • docker: $(print_status "Installed")"
    else
        MISSING_DEPS="$MISSING_DEPS container-runtime"
        echo "  • container runtime: $(print_error "Not installed")"
    fi
    
    if [ -z "$MISSING_DEPS" ]; then
        echo ""
        print_status "All dependencies are already installed!"
        exit 0
    fi
    
    echo ""
    print_warning "Missing dependencies found: $MISSING_DEPS"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to install missing dependencies? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Install missing dependencies
    for dep in $MISSING_DEPS; do
        case $dep in
            gcloud)
                install_gcloud || print_error "Failed to install gcloud"
                ;;
            terraform)
                install_terraform || print_error "Failed to install terraform"
                ;;
            container-runtime)
                print_info "Choose container runtime:"
                echo "  1) Podman (recommended - rootless)"
                echo "  2) Docker"
                read -p "Selection (1-2): " -n 1 -r
                echo ""
                case $REPLY in
                    1)
                        install_podman || print_error "Failed to install Podman"
                        ;;
                    2)
                        install_docker || print_error "Failed to install Docker"
                        ;;
                    *)
                        print_warning "Invalid selection, installing Podman"
                        install_podman || print_error "Failed to install Podman"
                        ;;
                esac
                ;;
        esac
    done
    
    # Install additional tools
    read -p "Install additional helpful tools (jq, git, etc.)? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_additional_tools
    fi
    
    echo ""
    print_status "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Set your GCP project: export PROJECT_ID=your-project-id"
    echo "  2. Authenticate: gcloud auth login"
    echo "  3. Run: make quick-start"
    echo ""
    
    # Remind about docker group if Docker was installed
    if [[ "$MISSING_DEPS" == *"container-runtime"* ]] && command -v docker >/dev/null 2>&1; then
        print_warning "If you installed Docker, log out and back in for group changes to take effect"
    fi
}

# Run main function
main "$@"