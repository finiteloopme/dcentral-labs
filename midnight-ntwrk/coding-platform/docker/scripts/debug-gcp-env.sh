#!/bin/bash
#
# Debug GCP environment variable setup
#

echo "=========================================="
echo "🔍 GCP Environment Diagnostic"
echo "=========================================="
echo ""

# Current environment
echo "1️⃣  Current Environment:"
echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:-[NOT SET]}"
echo "   GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-[NOT SET]}"
echo "   CLOUD_WORKSTATIONS_CONFIG_DIRECTORY: ${CLOUD_WORKSTATIONS_CONFIG_DIRECTORY:-[NOT SET]}"
echo "   CLOUD_WORKSTATIONS_CLUSTER: ${CLOUD_WORKSTATIONS_CLUSTER:-[NOT SET]}"
echo ""

# Metadata service check
echo "2️⃣  Metadata Service Check:"
PROJECT_FROM_METADATA=$(curl -s -f -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
if [ -n "$PROJECT_FROM_METADATA" ]; then
    echo "   ✅ Metadata service accessible"
    echo "   Project ID from metadata: $PROJECT_FROM_METADATA"
else
    echo "   ❌ Metadata service NOT accessible"
    echo "   (This is normal if not running in GCP)"
fi
echo ""

# Check configuration files
echo "3️⃣  Configuration Files:"

# /etc/environment
echo "   /etc/environment:"
if [ -f /etc/environment ]; then
    if grep -q "GCP_PROJECT_ID" /etc/environment 2>/dev/null; then
        echo "      ✅ Contains GCP_PROJECT_ID"
        grep "GCP_PROJECT_ID" /etc/environment | head -1 | sed 's/^/      /'
    else
        echo "      ❌ Does NOT contain GCP_PROJECT_ID"
    fi
else
    echo "      ❌ File does not exist"
fi

# /etc/bash.bashrc
echo "   /etc/bash.bashrc:"
if [ -f /etc/bash.bashrc ]; then
    if grep -q "GCP_PROJECT_ID" /etc/bash.bashrc 2>/dev/null; then
        echo "      ✅ Contains GCP_PROJECT_ID"
        grep -A1 "GCP_PROJECT_ID" /etc/bash.bashrc | head -2 | sed 's/^/      /'
    else
        echo "      ❌ Does NOT contain GCP_PROJECT_ID"
    fi
else
    echo "      ❌ File does not exist"
fi

# /etc/profile.d/
echo "   /etc/profile.d/:"
for file in /etc/profile.d/*gcp* /etc/profile.d/*-gcp* /etc/profile.d/01-* /etc/profile.d/00-*; do
    if [ -f "$file" ]; then
        echo "      ✅ $(basename $file) exists"
        if grep -q "GCP_PROJECT_ID" "$file" 2>/dev/null; then
            echo "         Contains GCP_PROJECT_ID export"
        fi
    fi
done
if [ ! -f /etc/profile.d/*gcp* ] && [ ! -f /etc/profile.d/0*-* ]; then
    echo "      ❌ No GCP-related profile scripts found"
fi

# User's .profile and .bashrc
echo "   User files:"
for file in ~/.profile ~/.bashrc ~/.bash_profile; do
    if [ -f "$file" ]; then
        if grep -q "GCP_PROJECT_ID" "$file" 2>/dev/null; then
            echo "      ✅ $file contains GCP_PROJECT_ID"
        else
            echo "      ⚪ $file exists but no GCP_PROJECT_ID"
        fi
    fi
done
echo ""

# Check what shell we're in
echo "4️⃣  Shell Information:"
echo "   Current shell: $SHELL"
echo "   Shell options: $-"
if [ -n "$BASH_VERSION" ]; then
    echo "   Bash version: $BASH_VERSION"
    echo "   Login shell: $(shopt -q login_shell && echo "YES" || echo "NO")"
fi
echo ""

# Check process tree
echo "5️⃣  Process Tree:"
echo "   Parent processes:"
ps -o pid,ppid,comm -p $$ -p $PPID 2>/dev/null | sed 's/^/   /'
echo ""

# Check if we're in Code OSS terminal
echo "6️⃣  IDE Detection:"
if [ -n "$VSCODE_IPC_HOOK_CLI" ] || [ -n "$TERM_PROGRAM" ]; then
    echo "   ✅ Running in VS Code/Code OSS terminal"
    echo "      TERM_PROGRAM: ${TERM_PROGRAM:-[not set]}"
    echo "      VSCODE_IPC_HOOK_CLI: ${VSCODE_IPC_HOOK_CLI:+[set]}"
else
    echo "   ⚪ Not detected as VS Code terminal"
fi
echo ""

# Startup script check
echo "7️⃣  Startup Scripts:"
for script in /etc/workstation-startup.d/05*gcp* /etc/workstation-startup.d/10*env*; do
    if [ -f "$script" ]; then
        echo "   ✅ $(basename $script) exists"
        if [ -r "$script" ]; then
            echo "      Executable: $([ -x "$script" ] && echo "YES" || echo "NO")"
        fi
    fi
done
echo ""

# Recommendations
echo "=========================================="
echo "📊 RECOMMENDATIONS:"
echo ""

if [ -z "$GCP_PROJECT_ID" ]; then
    if [ -n "$PROJECT_FROM_METADATA" ]; then
        echo "The metadata service has project ID: $PROJECT_FROM_METADATA"
        echo ""
        echo "To set it now, run:"
        echo "  export GCP_PROJECT_ID=\"$PROJECT_FROM_METADATA\""
        echo "  export GOOGLE_CLOUD_PROJECT=\"$PROJECT_FROM_METADATA\""
        echo ""
        echo "To make it permanent, add to ~/.bashrc or ~/.profile"
    else
        echo "Metadata service is not available."
        echo "Set manually with:"
        echo "  export GCP_PROJECT_ID=\"your-project-id\""
        echo "  export GOOGLE_CLOUD_PROJECT=\"your-project-id\""
    fi
else
    echo "✅ GCP_PROJECT_ID is already set to: $GCP_PROJECT_ID"
fi
echo "=========================================="