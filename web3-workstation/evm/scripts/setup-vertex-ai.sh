#!/bin/bash

# Setup script for Vertex AI access in the container

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Vertex AI Setup for Web3 Workstation${NC}\n"

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if running in container or host
if [ -f /.dockerenv ] || [ -n "$container" ]; then
    echo "Running inside container"
    IN_CONTAINER=true
else
    echo "Running on host"
    IN_CONTAINER=false
fi

# Setup options
echo -e "${YELLOW}Choose authentication method:${NC}"
echo "1. Use Application Default Credentials (recommended for local dev)"
echo "2. Use Service Account Key"
echo "3. Use Google Cloud Workstation identity (for cloud deployment)"
echo "4. Setup for both local and cloud"
echo ""
read -p "Select (1-4): " AUTH_METHOD

case $AUTH_METHOD in
    1)
        echo -e "\n${BLUE}Setting up Application Default Credentials${NC}"
        
        if [ "$IN_CONTAINER" = "true" ]; then
            # Inside container
            echo "Run this command on your host machine:"
            echo -e "${GREEN}gcloud auth application-default login${NC}"
            echo ""
            echo "Then restart the container with:"
            echo -e "${GREEN}make local${NC}"
        else
            # On host
            if ! command -v gcloud &> /dev/null; then
                print_error "gcloud CLI not installed"
                echo "Install from: https://cloud.google.com/sdk/docs/install"
                exit 1
            fi
            
            print_info "Authenticating with Google Cloud..."
            gcloud auth application-default login
            
            print_status "Authentication complete"
            echo ""
            echo "Your credentials will be automatically mounted when running:"
            echo -e "${GREEN}make local${NC}"
        fi
        ;;
    
    2)
        echo -e "\n${BLUE}Setting up Service Account Key${NC}"
        
        if [ "$IN_CONTAINER" = "false" ]; then
            echo "Steps:"
            echo "1. Create a service account in GCP Console"
            echo "2. Grant it Vertex AI User role"
            echo "3. Download the key JSON file"
            echo "4. Set environment variable:"
            echo ""
            echo -e "${GREEN}export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json${NC}"
            echo -e "${GREEN}make local${NC}"
        fi
        ;;
    
    3)
        echo -e "\n${BLUE}Using Workstation Identity${NC}"
        echo ""
        echo "When running in Google Cloud Workstations, the container"
        echo "automatically inherits the workstation's service account."
        echo ""
        echo "Ensure the workstation service account has these roles:"
        echo "  • Vertex AI User"
        echo "  • Storage Object Viewer (if accessing GCS)"
        echo ""
        echo "No additional setup needed!"
        ;;
    
    4)
        echo -e "\n${BLUE}Hybrid Setup (Local + Cloud)${NC}"
        echo ""
        echo "The container is configured to work in both environments:"
        echo ""
        echo "For local development:"
        echo "  1. Run: gcloud auth application-default login"
        echo "  2. Start container: make local"
        echo ""
        echo "For Cloud Workstations:"
        echo "  • Automatically uses workstation service account"
        echo ""
        ;;
esac

# Test Vertex AI access if in container
if [ "$IN_CONTAINER" = "true" ]; then
    echo -e "\n${BLUE}Testing Vertex AI Access${NC}"
    
    python3 -c "
try:
    from google.cloud import aiplatform
    import google.auth
    
    credentials, project = google.auth.default()
    print('✓ Google Cloud credentials found')
    print(f'  Project: {project}')
    
    # Try to initialize Vertex AI
    aiplatform.init(project=project, location='us-central1')
    print('✓ Vertex AI client initialized')
    
except Exception as e:
    print(f'✗ Error: {e}')
    print('')
    print('Make sure to:')
    print('1. Set up credentials (see above)')
    print('2. Enable Vertex AI API in your project')
    print('3. Set PROJECT_ID environment variable')
" || true
fi

# Show example code
echo -e "\n${YELLOW}Example Vertex AI Usage:${NC}"
cat << 'EOF'

# Python example
from google.cloud import aiplatform
from vertexai.preview.generative_models import GenerativeModel

# Initialize
aiplatform.init(project="your-project", location="us-central1")

# Use Gemini model
model = GenerativeModel("gemini-pro")
response = model.generate_content("Explain smart contracts")
print(response.text)

# In a Foundry test, call Python script
# forge script scripts/VertexAI.s.sol

EOF

echo -e "${GREEN}Setup complete!${NC}"