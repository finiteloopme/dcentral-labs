# OpenCode Troubleshooting Scripts

This directory contains scripts to diagnose and fix the OpenCode permission issue.

## Problem
OpenCode is failing with:
```
EACCES: permission denied, mkdir '/home/ubuntu/.config/opencode'
```

## Scripts

### 1. debug-opencode.sh
Diagnoses the permission issue by checking:
- Current user information
- Ubuntu user/directory existence
- OpenCode installation details
- Environment variables
- Directory permissions

**Usage:**
```bash
bash tmp-troubleshooting/debug-opencode.sh
```

### 2. fix-opencode.sh
Attempts to fix the permission issue using multiple methods:
- Fixes /home/ubuntu permissions (if ubuntu user exists)
- Creates proper directories for current user
- Creates wrapper scripts to handle HOME directory correctly
- Provides multiple solutions to run opencode

**Usage:**
```bash
bash tmp-troubleshooting/fix-opencode.sh
```

## Quick Solutions

### Solution 1: Run with HOME override
```bash
HOME=$HOME opencode
```

### Solution 2: Create alias
Add to your ~/.bashrc:
```bash
alias opencode='HOME=$HOME opencode'
```

### Solution 3: Use the wrapper script
After running fix-opencode.sh:
```bash
~/.local/bin/opencode-fixed
```

## Cleanup
Once the issue is resolved, you can remove this directory:
```bash
rm -rf tmp-troubleshooting
```