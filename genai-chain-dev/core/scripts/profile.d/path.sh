# PATH configuration for development tools
# Sourced by shells at login

# Add local bin directories to PATH
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.foundry/bin:${PATH}"

# Chain CLI directory (if installed)
if [[ -d /opt/chain-cli ]]; then
    export PATH="/opt/chain-cli:${PATH}"
fi
