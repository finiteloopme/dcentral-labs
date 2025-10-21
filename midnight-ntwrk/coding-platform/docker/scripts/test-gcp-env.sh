#!/bin/bash
#
# Test if GCP_PROJECT_ID is properly set in different contexts
#

echo "=========================================="
echo "🔍 GCP Environment Test"
echo "=========================================="
echo ""

# Test 1: Current shell
echo "1️⃣  Current Shell:"
echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:-[NOT SET]}"
echo "   GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-[NOT SET]}"
echo ""

# Test 2: New bash shell
echo "2️⃣  New Bash Shell (non-login):"
bash -c 'echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:-[NOT SET]}"'
bash -c 'echo "   GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-[NOT SET]}"'
echo ""

# Test 3: New login shell
echo "3️⃣  New Login Shell:"
bash -l -c 'echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:-[NOT SET]}"'
bash -l -c 'echo "   GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT:-[NOT SET]}"'
echo ""

# Test 4: Metadata service
echo "4️⃣  Metadata Service:"
PROJECT_FROM_METADATA=$(curl -s -f -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
if [ -n "$PROJECT_FROM_METADATA" ]; then
    echo "   ✅ Available: $PROJECT_FROM_METADATA"
else
    echo "   ❌ Not available (not in GCP)"
fi
echo ""

# Test 5: Check configuration files
echo "5️⃣  Configuration Files:"
echo -n "   /etc/environment: "
grep -q "GCP_PROJECT_ID" /etc/environment 2>/dev/null && echo "✅ Configured" || echo "❌ Not configured"

echo -n "   /etc/bash.bashrc: "
grep -q "GCP_PROJECT_ID" /etc/bash.bashrc 2>/dev/null && echo "✅ Configured" || echo "❌ Not configured"

echo -n "   /etc/profile.d/*gcp*: "
ls /etc/profile.d/*gcp* 2>/dev/null >/dev/null && echo "✅ Exists" || echo "❌ Not found"
echo ""

# Test 6: Simulate VS Code terminal
echo "6️⃣  Simulated VS Code Terminal:"
env -i HOME="$HOME" USER="$USER" SHELL="/bin/bash" TERM="xterm-256color" \
    VSCODE_IPC_HOOK_CLI="simulated" \
    /bin/bash -c 'source /etc/bash.bashrc 2>/dev/null; echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:-[NOT SET]}"'
echo ""

# Summary
echo "=========================================="
echo "📊 SUMMARY:"
if [ -n "$GCP_PROJECT_ID" ]; then
    echo "   ✅ GCP_PROJECT_ID is set in current shell: $GCP_PROJECT_ID"
else
    echo "   ❌ GCP_PROJECT_ID is NOT set in current shell"
fi

# Test if it would be set in a new terminal
NEW_SHELL_HAS_IT=$(bash -c 'source /etc/bash.bashrc 2>/dev/null; [ -n "$GCP_PROJECT_ID" ] && echo "yes" || echo "no"')
if [ "$NEW_SHELL_HAS_IT" = "yes" ]; then
    echo "   ✅ New terminals WILL have GCP_PROJECT_ID set"
else
    echo "   ⚠️  New terminals MAY NOT have GCP_PROJECT_ID set"
    echo "   Run: source /etc/bash.bashrc"
fi
echo "=========================================="