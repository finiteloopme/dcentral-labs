#!/bin/bash
# Configure Code OSS to use port 8080 instead of 80
echo "🌙 Configuring Code OSS port for Midnight Vibe Platform..."

# Wait for user to be created
sleep 2

# Create the Code OSS config directory
mkdir -p /home/user/.codeoss-cloudworkstations/data/Machine

# Create settings with port 8080 configuration
cat > /home/user/.codeoss-cloudworkstations/data/Machine/settings.json << 'EOF'
{
    "workbench.colorTheme": "Default Dark Modern",
    "extensions.autoUpdate": false,
    "extensions.ignoreRecommendations": true,
    "workbench.startupEditor": "none",
    "terminal.integrated.defaultProfile.linux": "bash",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "editor.fontSize": 14,
    "editor.fontFamily": "Monaco, Menlo, monospace",
    "workbench.panel.defaultLocation": "bottom",
    "git.enableSmartCommit": true,
    "extensions.recommendations": [
        "ms-vscode.vscode-json",
        "rust-lang.rust-analyzer",
        "ms-vscode.cpptools",
        "redhat.vscode-yaml",
        "midnight-network.midnight-compact"
    ]
}
EOF

# Set proper ownership
chown -R user:user /home/user/.codeoss-cloudworkstations

echo "✅ Code OSS configured for port 8080"