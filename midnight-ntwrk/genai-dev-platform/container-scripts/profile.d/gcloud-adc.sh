# ==============================================================================
# LOCAL DEVELOPMENT ONLY
# ==============================================================================
# This script is only active when running locally via 'make run'.
# On Cloud Workstations, the ADC file won't exist and this script does nothing.
#
# For local dev:
#   - ADC file is mounted to /etc/gcloud-adc/ by run-local.sh
#   - This exports GOOGLE_APPLICATION_CREDENTIALS for OpenCode/Vertex AI
#
# For Cloud Workstations:
#   - Uses workstation service account (ADC via metadata server)
#   - See gcp-project.sh for workstation-specific env setup
# ==============================================================================

if [ -f /etc/gcloud-adc/application_default_credentials.json ]; then
    export GOOGLE_APPLICATION_CREDENTIALS="/etc/gcloud-adc/application_default_credentials.json"
fi
