# ==============================================================================
# Container Environment Variables
# ==============================================================================
# Sources environment variables that were passed to the container via -e flags.
# These are persisted to /etc/container-env.sh at startup by 015_user-dirs.sh
# because login shells (su - user) clear the environment.
#
# Variables sourced:
#   - GOOGLE_CLOUD_PROJECT - for Vertex AI
#   - RPC_URL, CHAIN_ID, etc. - chain config overrides
# ==============================================================================

if [ -f /etc/container-env.sh ]; then
    . /etc/container-env.sh
fi
