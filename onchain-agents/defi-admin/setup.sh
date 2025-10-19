#!/bin/bash

# DeFi Admin Setup Script
# This script sets up the development environment with virtual environment

set -e  # Exit on error

echo "======================================"
echo "DeFi Admin Development Setup"
echo "======================================"
echo ""

# Check Python version
echo "Checking Python version..."
python_version=$(python3 --version 2>&1 | grep -Po '(?<=Python )\d+\.\d+')
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then 
    echo "Error: Python $required_version or higher is required. Found: Python $python_version"
    exit 1
fi
echo "✓ Python $python_version found"

# Check Node.js
echo "Checking Node.js version..."
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi
node_version=$(node --version)
echo "✓ Node.js $node_version found"

# Create virtual environment
echo ""
echo "Setting up Python virtual environment..."
if [ ! -d "backend/venv" ]; then
    python3 -m venv backend/venv
    echo "✓ Virtual environment created at backend/venv"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
source backend/venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip --quiet

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r backend/requirements.txt
echo "✓ Python dependencies installed"

# Install development tools
echo "Installing development tools..."
pip install flake8 black pytest pytest-asyncio ipython --quiet
echo "✓ Development tools installed"

# Create .env file if it doesn't exist
if [ ! -f "backend/.env" ]; then
    echo ""
    echo "Creating .env file from template..."
    cp backend/.env.example backend/.env
    echo "✓ Created backend/.env"
    echo ""
    echo "⚠️  Please edit backend/.env with your API keys and configuration"
else
    echo "✓ backend/.env already exists"
fi

# Install frontend dependencies
echo ""
echo "Installing frontend dependencies..."
cd frontend
npm install
cd ..
echo "✓ Frontend dependencies installed"

# Final instructions
echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Virtual environment location: backend/venv"
echo ""
echo "To activate the virtual environment manually:"
echo "  source backend/venv/bin/activate"
echo ""
echo "To start the application:"
echo "  make run"
echo ""
echo "Or start services individually:"
echo "  make run-backend  # Start backend server"
echo "  make run-frontend # Start frontend server"
echo ""
echo "For more commands, run: make help"
echo ""

# Check if .env needs configuration
if grep -q "your_openai_api_key_here" backend/.env 2>/dev/null; then
    echo "⚠️  Don't forget to configure backend/.env with your API keys!"
fi