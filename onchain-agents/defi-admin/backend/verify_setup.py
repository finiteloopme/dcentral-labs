#!/usr/bin/env python3
"""
Verify that all required packages are installed and working correctly.
Run this after setting up the virtual environment.
"""

import sys
import os
from importlib import import_module

def check_package(package_name, import_name=None):
    """Check if a package is installed and can be imported."""
    import_name = import_name or package_name
    try:
        module = import_module(import_name)
        version = getattr(module, '__version__', 'unknown')
        print(f"✓ {package_name:<20} {version}")
        return True
    except ImportError as e:
        print(f"✗ {package_name:<20} NOT INSTALLED - {e}")
        return False

def check_environment():
    """Check if running in virtual environment."""
    in_venv = hasattr(sys, 'real_prefix') or (
        hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix
    )
    
    if in_venv:
        print(f"✓ Running in virtual environment: {sys.prefix}")
    else:
        print("⚠ Not running in virtual environment")
    
    return in_venv

def main():
    print("=" * 60)
    print("DeFi Admin - Environment Verification")
    print("=" * 60)
    print()
    
    # Check virtual environment
    print("Virtual Environment Check:")
    print("-" * 30)
    check_environment()
    print()
    
    # Check Python version
    print("Python Version Check:")
    print("-" * 30)
    python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    if sys.version_info >= (3, 8):
        print(f"✓ Python {python_version}")
    else:
        print(f"✗ Python {python_version} (3.8+ required)")
    print()
    
    # Check required packages
    print("Package Installation Check:")
    print("-" * 30)
    
    packages = [
        ("fastapi", "fastapi"),
        ("uvicorn", "uvicorn"),
        ("pydantic", "pydantic"),
        ("python-dotenv", "dotenv"),
        ("web3", "web3"),
        ("aiohttp", "aiohttp"),
        ("openai", "openai"),
        ("langchain", "langchain"),
        ("pandas", "pandas"),
        ("numpy", "numpy"),
        ("sqlalchemy", "sqlalchemy"),
        ("alembic", "alembic"),
        ("redis", "redis"),
        ("celery", "celery"),
        ("pytest", "pytest"),
        ("httpx", "httpx"),
        ("toml", "toml"),
    ]
    
    all_installed = True
    for package in packages:
        if isinstance(package, tuple):
            installed = check_package(*package)
        else:
            installed = check_package(package)
        all_installed = all_installed and installed
    
    print()
    
    # Check configuration files
    print("Configuration Files Check:")
    print("-" * 30)
    
    config_files = [
        "config/chains.toml",
        ".env.example",
    ]
    
    for config_file in config_files:
        full_path = os.path.join(os.path.dirname(__file__), config_file)
        if os.path.exists(full_path):
            print(f"✓ {config_file:<30} EXISTS")
        else:
            print(f"✗ {config_file:<30} NOT FOUND")
    
    # Check .env file
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_path):
        print(f"✓ .env file                    EXISTS")
        # Check if API key is configured
        with open(env_path, 'r') as f:
            content = f.read()
            if 'your_openai_api_key_here' in content:
                print("⚠ .env file needs configuration (contains default values)")
    else:
        print(f"⚠ .env file                    NOT FOUND (create from .env.example)")
    
    print()
    print("=" * 60)
    
    if all_installed:
        print("✓ All packages are installed correctly!")
        print("  You can now run: python main.py")
    else:
        print("✗ Some packages are missing.")
        print("  Run: pip install -r requirements.txt")
    
    print("=" * 60)

if __name__ == "__main__":
    main()