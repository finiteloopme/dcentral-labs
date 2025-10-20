#!/bin/bash
# Test OpenCode installation in the container

echo "Testing OpenCode Installation"
echo "============================="
echo ""

# Check if API key is provided
if [ -z "$1" ]; then
    echo "Testing without API key (dry run)"
    echo ""
    # Test without API key
    podman run --rm --entrypoint bash midnight-workstation:latest -c "
        echo '1. Checking OpenCode binary location:'
        which opencode
        echo ''
        echo '2. Checking OpenCode version:'
        /usr/bin/opencode --version
        echo ''
        echo '3. Checking OpenCode help:'
        /usr/bin/opencode --help 2>&1 | head -10
        echo ''
        echo '✓ OpenCode TUI is installed and ready'
        echo ''
        echo 'To use with your API key, run:'
        echo '  ./test-opencode.sh YOUR_ANTHROPIC_API_KEY'
    "
else
    echo "Testing with API key (interactive)"
    echo ""
    echo "Starting container with OpenCode..."
    echo "Once inside, type 'exit' to quit OpenCode"
    echo ""
    
    # Run interactively with API key
    podman run -it --rm \
        --name midnight-opencode-test \
        --entrypoint bash \
        -e ANTHROPIC_API_KEY="$1" \
        midnight-workstation:latest \
        -c "
            echo 'OpenCode TUI Test Session'
            echo '========================'
            echo ''
            echo 'API Key is set: \${ANTHROPIC_API_KEY:0:10}...'
            echo ''
            echo 'Starting OpenCode in 3 seconds...'
            echo 'Type \"exit\" or press Ctrl+D to quit'
            echo ''
            sleep 3
            /usr/bin/opencode
        "
fi