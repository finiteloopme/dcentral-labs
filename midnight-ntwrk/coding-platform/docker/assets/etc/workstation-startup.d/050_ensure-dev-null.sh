#!/bin/bash
#
# Ensure /dev/null exists and is accessible
# This fixes issues with OpenCode and other tools that require /dev/null
#

echo "Checking /dev/null..."

# Always try to create /dev/null if not a character device
if [ ! -c /dev/null ]; then
    echo "Warning: /dev/null is missing or not a character device"
    
    # Try different approaches to create /dev/null
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        echo "Creating /dev/null..."
        
        # Remove any existing file
        rm -f /dev/null 2>&1 || true
        
        # Try mknod first
        if mknod -m 666 /dev/null c 1 3 2>&1; then
            echo "✓ Created /dev/null with mknod"
        else
            # If mknod fails, try creating a regular file as fallback
            touch /dev/null
            chmod 666 /dev/null
            echo "✓ Created /dev/null as regular file (fallback)"
        fi
    else
        # Not root, but try to create as regular file anyway
        if [ ! -e /dev/null ]; then
            touch /dev/null 2>&1 || echo "Warning: Cannot create /dev/null (permission denied)"
        fi
    fi
fi

# Verify /dev/null is working
if echo "test" > /dev/null 2>&1; then
    echo "✓ /dev/null is working correctly"
else
    echo "⚠️  /dev/null is not working properly"
    # As a last resort, create a symlink to /tmp/null
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        touch /tmp/null
        chmod 666 /tmp/null
        ln -sf /tmp/null /dev/null 2>&1 || true
    fi
fi

# Also ensure /dev/zero and /dev/random exist (commonly needed)
for device in zero random urandom; do
    if [ ! -c /dev/$device ]; then
        echo "Warning: /dev/$device is missing"
        if [ "${EUID:-$(id -u)}" -eq 0 ]; then
            case $device in
                zero)
                    mknod -m 666 /dev/zero c 1 5
                    ;;
                random)
                    mknod -m 666 /dev/random c 1 8
                    ;;
                urandom)
                    mknod -m 666 /dev/urandom c 1 9
                    ;;
            esac
            echo "✓ Created /dev/$device"
        fi
    fi
done