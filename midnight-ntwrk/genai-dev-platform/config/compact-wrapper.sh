#!/bin/bash
# Compact wrapper script that ensures configuration is always available

# Get current user and home directory
CURRENT_USER=$(whoami)
CURRENT_HOME=$(eval echo "~$CURRENT_USER")

# Ensure compact config exists
if [ ! -f "$CURRENT_HOME/.compact/config.toml" ]; then
    mkdir -p "$CURRENT_HOME/.compact"
    echo '[compiler]\ndefault = "0.25.0"' > "$CURRENT_HOME/.compact/config.toml"
    chmod 644 "$CURRENT_HOME/.compact/config.toml"
fi

# Set COMPACT_DIRECTORY to user's home if not set
if [ -z "$COMPACT_DIRECTORY" ]; then
    export COMPACT_DIRECTORY="$CURRENT_HOME/.compact"
fi

# Execute the actual compact command
exec /usr/local/bin/compact "$@"