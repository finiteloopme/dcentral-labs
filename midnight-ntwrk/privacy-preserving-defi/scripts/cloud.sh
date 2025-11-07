#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_ID=""
REGION="us-central1"
SERVICE_NAME="privacy-defi-tee"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "Not authenticated with gcloud. Run 'gcloud auth login' first."
        exit 1
    fi
    
    # Set project if provided
    if [ -n "$PROJECT_ID" ]; then
        gcloud config set project "$PROJECT_ID"
    fi
    
    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -z "$CURRENT_PROJECT" ]; then
        print_error "No Google Cloud project set. Use 'gcloud config set project PROJECT_ID' or provide --project flag."
        exit 1
    fi
    
    print_status "Using project: $CURRENT_PROJECT"
    print_status "Using region: $REGION"
}

# Function to build application
build_app() {
    print_header "Building Application"
    
    print_status "Building and pushing TEE service image..."
    gcloud builds submit --config=cicd/cloudbuild-app.yaml . --substitutions=_REGION="$REGION"
    
    print_status "Application build completed!"
}

# Function to build and deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    print_status "Building and deploying infrastructure..."
    gcloud builds submit --config=cicd/cloudbuild-infra.yaml . --substitutions=_REGION="$REGION"
    
    print_status "Infrastructure deployment completed!"
}

# Function to deploy both app and infrastructure
deploy_all() {
    print_header "Full Deployment"
    
    print_status "Deploying application and infrastructure..."
    
    # Build application first
    build_app
    
    # Then deploy infrastructure
    deploy_infrastructure
    
    print_status "Full deployment completed!"
    
    # Show service URL
    show_service_url
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_header "Destroying Infrastructure"
    
    print_warning "This will destroy all cloud resources. This action cannot be undone."
    read -p "Are you sure you want to continue? (yes/no): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Destruction cancelled."
        exit 0
    fi
    
    print_status "Destroying infrastructure..."
    gcloud builds submit --config=cicd/cloudbuild-destroy.yaml . --substitutions=_REGION="$REGION"
    
    print_status "Infrastructure destruction completed!"
}

# Function to show service URL
show_service_url() {
    print_header "Service Information"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "")
    
    if [ -n "$SERVICE_URL" ]; then
        print_status "Service URL: $SERVICE_URL"
        print_status "Health check: $SERVICE_URL/healthz"
        print_status "API endpoint: $SERVICE_URL/api/v1"
    else
        print_warning "Service not found or not deployed"
    fi
}

# Function to show deployment status
show_status() {
    print_header "Deployment Status"
    
    # Show Cloud Run services
    print_status "Cloud Run Services:"
    gcloud run services list --region="$REGION" --format="table(name,status,latestReadyRevisionCreatedAt,url)" || print_warning "No services found"
    
    # Show Cloud Build history
    print_status "Recent Builds:"
    gcloud builds list --limit=5 --format="table(id,status,createTime,duration)" || print_warning "No builds found"
    
    # Show service URL
    show_service_url
}

# Function to show logs
show_logs() {
    local service_name=${1:-$SERVICE_NAME}
    local lines=${2:-50}
    
    print_header "Service Logs ($service_name)"
    
    print_status "Fetching last $lines log entries..."
    gcloud logs read "resource.type=cloud_run_revision resource.labels.service_name=$service_name" \
        --limit="$lines" \
        --format="table(timestamp,textPayload)" \
        --freshness=1s || print_warning "No logs found for service: $service_name"
}

# Function to test deployment
test_deployment() {
    print_header "Testing Deployment"
    
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)" 2>/dev/null || "")
    
    if [ -z "$SERVICE_URL" ]; then
        print_error "Service not deployed. Run 'cloud.sh deploy' first."
        exit 1
    fi
    
    print_status "Testing service health..."
    
    # Test health endpoint
    if curl -s "$SERVICE_URL/healthz" | grep -q "healthy"; then
        print_status "✅ Health check passed"
    else
        print_error "❌ Health check failed"
        exit 1
    fi
    
    # Test session creation
    print_status "Testing session creation..."
    SESSION_RESPONSE=$(curl -s -X POST "$SERVICE_URL/api/v1/session" \
        -H "Content-Type: application/json" \
        -d '{"user_address":"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266","user_pubkey":"0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"}')
    
    if echo "$SESSION_RESPONSE" | grep -q "session_token"; then
        print_status "✅ Session creation test passed"
    else
        print_error "❌ Session creation test failed"
        echo "Response: $SESSION_RESPONSE"
        exit 1
    fi
    
    print_status "✅ All tests passed!"
}

# Function to set configuration
set_config() {
    local project_id=$1
    local region=$2
    
    if [ -n "$project_id" ]; then
        gcloud config set project "$project_id"
        print_status "Project set to: $project_id"
    fi
    
    if [ -n "$region" ]; then
        REGION="$region"
        print_status "Region set to: $region"
    fi
}

# Function to show help
show_help() {
    echo "Privacy-Preserving DeFi Cloud Operations Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build            Build and push application image"
    echo "  infra            Deploy infrastructure only"
    echo "  deploy           Deploy both app and infrastructure"
    echo "  destroy          Destroy all cloud resources"
    echo "  status           Show deployment status"
    echo "  logs [service]   Show service logs [default: $SERVICE_NAME]"
    echo "  test             Test deployed service"
    echo "  url              Show service URL"
    echo "  config <project> <region>  Set configuration"
    echo "  help             Show this help message"
    echo ""
    echo "Options:"
    echo "  --project <id>   Google Cloud project ID"
    echo "  --region <name>  Deployment region [default: us-central1]"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                    # Deploy everything"
    echo "  $0 deploy --project myproj   # Deploy to specific project"
    echo "  $0 logs --region us-east1    # Show logs in us-east1"
    echo "  $0 test                     # Test deployment"
    echo ""
    echo "Environment Variables:"
    echo "  GOOGLE_CLOUD_PROJECT         Default project ID"
    echo "  CLOUD_REGION                Default region"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT_ID="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# Set environment variables if not provided
if [ -z "$PROJECT_ID" ] && [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
    PROJECT_ID="$GOOGLE_CLOUD_PROJECT"
fi

if [ -n "$CLOUD_REGION" ]; then
    REGION="$CLOUD_REGION"
fi

# Main script logic
case "${COMMAND:-help}" in
    "build")
        check_prerequisites
        build_app
        ;;
    "infra"|"infrastructure")
        check_prerequisites
        deploy_infrastructure
        ;;
    "deploy"|"all")
        check_prerequisites
        deploy_all
        ;;
    "destroy"|"destroy-all")
        check_prerequisites
        destroy_infrastructure
        ;;
    "status")
        check_prerequisites
        show_status
        ;;
    "logs")
        check_prerequisites
        show_logs "$SERVICE_NAME" "50"
        ;;
    "test")
        check_prerequisites
        test_deployment
        ;;
    "url")
        check_prerequisites
        show_service_url
        ;;
    "config")
        set_config "$PROJECT_ID" "$REGION"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac