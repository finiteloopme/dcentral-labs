#!/bin/bash
# Validate the Docker build structure

echo "Validating Docker build structure..."
echo "===================================="
echo ""

ERRORS=0

# Check required files exist
echo "Checking required files..."
for file in Dockerfile proof-server-package.json proof-server.js; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ Missing: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check assets directory
echo ""
echo "Checking assets directory..."
if [ -d "assets/etc/workstation-startup.d" ]; then
    echo "✓ assets/etc/workstation-startup.d/"
    for script in assets/etc/workstation-startup.d/*.sh; do
        if [ -f "$script" ]; then
            echo "  ✓ $(basename $script)"
            if [ ! -x "$script" ]; then
                echo "    ⚠ Warning: Not executable"
            fi
        fi
    done
else
    echo "✗ Missing: assets/etc/workstation-startup.d/"
    ERRORS=$((ERRORS + 1))
fi

# Check templates
echo ""
echo "Checking templates..."
if [ -d "templates/basic-token" ]; then
    echo "✓ templates/basic-token/"
    if [ -f "templates/basic-token/contracts/Token.compact" ]; then
        echo "  ✓ Token.compact"
    else
        echo "  ✗ Missing Token.compact"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✗ Missing: templates/basic-token/"
    ERRORS=$((ERRORS + 1))
fi

# Check scripts
echo ""
echo "Checking scripts..."
if [ -d "scripts" ]; then
    echo "✓ scripts/"
    SCRIPT_COUNT=$(ls scripts/*.sh 2>/dev/null | wc -l)
    echo "  Found $SCRIPT_COUNT scripts"
else
    echo "✗ Missing: scripts/"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! Ready to build."
    echo ""
    echo "To build:"
    echo "  docker build -t midnight-workstation:latest ."
    echo ""
    echo "To test locally:"
    echo "  docker run -p 8080:80 -p 8081:8080 midnight-workstation:latest"
else
    echo "❌ Found $ERRORS error(s). Please fix before building."
    exit 1
fi