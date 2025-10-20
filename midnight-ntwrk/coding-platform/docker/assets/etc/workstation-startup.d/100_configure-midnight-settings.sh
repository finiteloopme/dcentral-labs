#!/bin/bash
#
# Configure Code OSS settings for Midnight development
# Based on Google's cloud-workstations-custom-image-examples pattern
#

# In Cloud Workstations, this runs as the workstation user
# In local dev, this might run as root and switch to user
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  # If running as root (local dev), switch to user if available
  if id user >/dev/null 2>&1; then
    exec runuser user "${BASH_SOURCE[0]}"
  else
    # No user account yet, skip for now
    exit 0
  fi
fi

echo "Configuring Code OSS for Midnight development..."

settings_file="/home/user/.codeoss-cloudworkstations/data/Machine/settings.json"

if [[ ! -f ${settings_file} ]]; then
  mkdir -p /home/user/.codeoss-cloudworkstations/data/Machine/
  echo "{}" > ${settings_file}
fi

# Configure file associations for Midnight Compact files
if [[ ! $(grep "files.associations" "${settings_file}") ]]; then
  jq '{"files.associations": {"*.compact": "compact"}} + .' ${settings_file} > ${settings_file}.tmp
  mv ${settings_file}.tmp ${settings_file}
fi

# Configure workspace settings
if [[ ! $(grep "workbench.colorTheme" "${settings_file}") ]]; then
  jq '{"workbench.colorTheme": "Default Dark Modern"} + .' ${settings_file} > ${settings_file}.tmp
  mv ${settings_file}.tmp ${settings_file}
fi

# Configure terminal to use bash with login shell (shows welcome message)
if [[ ! $(grep "terminal.integrated.shell.linux" "${settings_file}") ]]; then
  jq '{"terminal.integrated.shell.linux": "/bin/bash"} + .' ${settings_file} > ${settings_file}.tmp
  mv ${settings_file}.tmp ${settings_file}
fi

if [[ ! $(grep "terminal.integrated.shellArgs.linux" "${settings_file}") ]]; then
  jq '{"terminal.integrated.shellArgs.linux": ["-l"]} + .' ${settings_file} > ${settings_file}.tmp
  mv ${settings_file}.tmp ${settings_file}
fi

echo "✓ Code OSS configuration complete"