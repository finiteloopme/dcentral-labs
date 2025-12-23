# OpenCode configuration symlinks
# Creates user config symlinks pointing to global config at /etc/opencode/
# Required for both local dev and Cloud Workstations

if [ ! -d "$HOME/.config/opencode" ] && [ -d /etc/opencode ]; then
    mkdir -p "$HOME/.config/opencode"
    ln -sf /etc/opencode/opencode.json "$HOME/.config/opencode/opencode.json"
    ln -sf /etc/opencode/AGENTS.md "$HOME/.config/opencode/AGENTS.md"
fi
