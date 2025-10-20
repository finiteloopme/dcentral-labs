#!/bin/bash
# Quick test to verify Docker build works

set -e

echo "Testing Docker build..."
echo "====================="
echo ""

# Build the image
echo "Building image..."
if docker build -t midnight-workstation:test . ; then
    echo "✓ Build successful"
    
    # Show image size
    echo ""
    echo "Image details:"
    docker images midnight-workstation:test --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
    
    # Quick test run
    echo ""
    echo "Testing container startup..."
    CONTAINER_ID=$(docker run -d --rm --name midnight-test midnight-workstation:test sleep 30)
    
    # Check if container is running
    sleep 2
    if docker ps | grep -q midnight-test; then
        echo "✓ Container started successfully"
        
        # Test basic commands
        echo ""
        echo "Testing Midnight tools..."
        docker exec midnight-test which midnight && echo "✓ midnight CLI found"
        docker exec midnight-test which compactc && echo "✓ compactc found"
        docker exec midnight-test test -f /opt/midnight/extensions/compact-0.2.13.vsix && echo "✓ VSCode extension found"
        docker exec midnight-test test -d /opt/midnight/proof-server && echo "✓ Proof server found"
        
        # Clean up
        docker stop midnight-test >/dev/null 2>&1
        echo ""
        echo "✓ All tests passed!"
    else
        echo "✗ Container failed to start"
        exit 1
    fi
else
    echo "✗ Build failed"
    exit 1
fi

echo ""
echo "Build test complete. Image is ready for deployment."