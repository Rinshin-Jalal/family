#!/bin/bash

# Family+ Deployment Script
# This script automates the deployment of backend, trigger tasks, and provides iOS deployment instructions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLOUDFLARE_WORKER_NAME="family-plus-backend"
R2_BUCKET_NAME="family-plus-audio"
TRIGGER_PROJECT_ID="proj_vdbanaagzxesesgrgmgvuz"

# Helper functions
print_header() {
    echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "\n${YELLOW}▶ $1${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        exit 1
    fi
}

# Main deployment function
deploy_backend() {
    print_header "DEPLOYING BACKEND"

    print_step "Checking prerequisites"
    check_command "wrangler"
    check_command "npm"
    check_command "node"

    print_step "Installing dependencies"
    cd backend
    npm install
    print_success "Dependencies installed"

    print_step "Checking Cloudflare authentication"
    if ! wrangler whoami &> /dev/null; then
        print_error "Not authenticated with Cloudflare. Run: wrangler login"
        exit 1
    fi
    print_success "Authenticated with Cloudflare"

    print_step "Verifying R2 bucket exists"
    if wrangler r2 bucket list | grep -q "$R2_BUCKET_NAME"; then
        print_success "R2 bucket '$R2_BUCKET_NAME' exists"
    else
        print_step "Creating R2 bucket '$R2_BUCKET_NAME'"
        wrangler r2 bucket create "$R2_BUCKET_NAME"
        print_success "R2 bucket created"
    fi

    print_step "Checking environment secrets"
    print_success "Please ensure these secrets are set:"
    echo "  - SUPABASE_URL"
    echo "  - SUPABASE_KEY"
    echo "  - AWS_BEARER_TOKEN_BEDROCK"
    echo "  - AWS_REGION"
    echo "  - CARTESIA_API_KEY"
    echo "  - OPENAI_API_KEY"
    echo ""
    read -p "Have you set all required secrets? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Please set secrets first:"
        echo "  wrangler secret put SUPABASE_URL"
        echo "  wrangler secret put SUPABASE_KEY"
        echo "  etc."
        exit 1
    fi

    print_step "Deploying Cloudflare Worker"
    npm run deploy
    print_success "Cloudflare Worker deployed"

    cd ..
}

deploy_trigger_tasks() {
    print_header "DEPLOYING TRIGGER.DEV TASKS"

    print_step "Checking Trigger.dev CLI"
    if ! npx trigger.dev@latest whoami &> /dev/null; then
        print_error "Not authenticated with Trigger.dev. Run: npx trigger.dev@latest login"
        exit 1
    fi
    print_success "Authenticated with Trigger.dev"

    print_step "Deploying background tasks"
    cd backend
    npx trigger.dev@latest deploy
    print_success "Trigger.dev tasks deployed"

    print_step "Verifying task registration"
    npx trigger.dev@latest tasks

    cd ..
}

deploy_supabase() {
    print_header "DEPLOYING SUPABASE DATABASE"

    print_step "Checking Supabase CLI"
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI is not installed. Run: npm install -g supabase"
        exit 1
    fi

    cd supabase

    print_step "Checking Supabase project link"
    if ! supabase status &> /dev/null; then
        print_error "Supabase project not linked. Run: supabase link --project-ref YOUR_PROJECT_REF"
        exit 1
    fi
    print_success "Supabase project linked"

    print_step "Pushing database migrations"
    read -p "This will reset your database. Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        supabase db reset
        print_success "Database migrated and seeded"
    else
        print_error "Database migration cancelled"
        cd ..
        exit 1
    fi

    cd ..
}

test_deployment() {
    print_header "TESTING DEPLOYMENT"

    print_step "Testing API health check"
    WORKER_URL=$(wrangler deployments list --name "$CLOUDFLARE_WORKER_NAME" | grep -oP 'https://[^\s]+' | head -1)

    if [ -z "$WORKER_URL" ]; then
        print_error "Could not determine worker URL"
        exit 1
    fi

    echo "Testing endpoint: $WORKER_URL"
    if curl -f -s "$WORKER_URL" > /dev/null; then
        print_success "API health check passed"
    else
        print_error "API health check failed"
        exit 1
    fi

    print_step "Checking Trigger.dev tasks"
    cd backend
    if npx trigger.dev@latest tasks | grep -q "generate-podcast-from-story"; then
        print_success "Trigger.dev tasks registered"
    else
        print_error "Trigger.dev tasks not found"
        exit 1
    fi
    cd ..

    print_step "Deployment verification complete"
}

ios_instructions() {
    print_header "IOS APP DEPLOYMENT INSTRUCTIONS"

    echo "To deploy the iOS app:"
    echo ""
    echo "1. Update API configuration:"
    echo "   - Edit: familyplus/Services/APIService.swift"
    echo "   - Set: private let API_BASE_URL = \"$WORKER_URL\""
    echo ""
    echo "2. Update Supabase configuration:"
    echo "   - Edit: familyplus/Services/SupabaseService.swift"
    echo "   - Set: supabaseURL and supabaseKey"
    echo ""
    echo "3. Open in Xcode:"
    echo "   - open familyplus/familyplus.xcodeproj"
    echo ""
    echo "4. Configure code signing:"
    echo "   - Select target: familyplus"
    echo "   - Signing & Capabilities → Select your team"
    echo "   - Add required capabilities"
    echo ""
    echo "5. Build and archive:"
    echo "   - Product → Archive"
    echo "   - Distribute App → App Store Connect"
    echo ""
    echo "For detailed instructions, see: familyplus/DEPLOYMENT.md"
}

# Main script
main() {
    print_header "FAMILY+ DEPLOYMENT"

    # Parse arguments
    DEPLOY_BACKEND=false
    DEPLOY_TRIGGER=false
    DEPLOY_SUPABASE=false
    RUN_TESTS=false
    IOS_HELP=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --backend)
                DEPLOY_BACKEND=true
                shift
                ;;
            --trigger)
                DEPLOY_TRIGGER=true
                shift
                ;;
            --supabase)
                DEPLOY_SUPABASE=true
                shift
                ;;
            --all)
                DEPLOY_BACKEND=true
                DEPLOY_TRIGGER=true
                DEPLOY_SUPABASE=true
                RUN_TESTS=true
                shift
                ;;
            --test)
                RUN_TESTS=true
                shift
                ;;
            --ios)
                IOS_HELP=true
                shift
                ;;
            --help)
                echo "Usage: ./deploy.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --backend     Deploy Cloudflare Worker backend"
                echo "  --trigger     Deploy Trigger.dev background tasks"
                echo "  --supabase    Deploy Supabase database migrations"
                echo "  --all         Deploy everything and run tests"
                echo "  --test        Run deployment tests"
                echo "  --ios         Show iOS deployment instructions"
                echo "  --help        Show this help message"
                echo ""
                echo "Examples:"
                echo "  ./deploy.sh --all"
                echo "  ./deploy.sh --backend --trigger"
                echo "  ./deploy.sh --ios"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Run: ./deploy.sh --help"
                exit 1
                ;;
        esac
    done

    # If no arguments, show help
    if [ "$DEPLOY_BACKEND" = false ] && [ "$DEPLOY_TRIGGER" = false ] && [ "$DEPLOY_SUPABASE" = false ] && [ "$RUN_TESTS" = false ] && [ "$IOS_HELP" = false ]; then
        ./deploy.sh --help
        exit 0
    fi

    # Execute deployment steps
    if [ "$DEPLOY_SUPABASE" = true ]; then
        deploy_supabase
    fi

    if [ "$DEPLOY_BACKEND" = true ]; then
        deploy_backend
    fi

    if [ "$DEPLOY_TRIGGER" = true ]; then
        deploy_trigger_tasks
    fi

    if [ "$RUN_TESTS" = true ]; then
        test_deployment
    fi

    if [ "$IOS_HELP" = true ]; then
        ios_instructions
    fi

    print_header "DEPLOYMENT COMPLETE"
    print_success "All components deployed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Test the API endpoints"
    echo "  2. Monitor background tasks in Trigger.dev dashboard"
    echo "  3. Deploy iOS app (see --ios instructions)"
    echo ""
}

# Run main function
main "$@"
