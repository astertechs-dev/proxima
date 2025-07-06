#!/bin/bash

# Proxima Deployment Script
# Usage: ./scripts/deploy.sh [staging|production]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
AWS_REGION="ap-northeast-1"
TERRAFORM_DIR="infra/terraform"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 [staging|production]"
    echo ""
    echo "Options:"
    echo "  staging     Deploy to staging environment"
    echo "  production  Deploy to production environment"
    echo ""
    echo "Examples:"
    echo "  $0 staging"
    echo "  $0 production"
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    local tools=("aws" "terraform" "docker" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        log_error ".env file not found. Please copy .env.example to .env and configure it."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_environment() {
    if [ -z "$ENVIRONMENT" ]; then
        log_error "Environment not specified"
        show_usage
    fi
    
    if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
        log_error "Invalid environment: $ENVIRONMENT"
        show_usage
    fi
    
    log_info "Deploying to: $ENVIRONMENT"
}

setup_terraform_backend() {
    log_info "Setting up Terraform backend..."
    
    local bucket_name="proxima-terraform-state-$(aws sts get-caller-identity --query Account --output text)"
    local backend_config="infra/terraform/backend-${ENVIRONMENT}.hcl"
    
    # Create backend configuration
    cat > "$backend_config" << EOF
bucket = "$bucket_name"
key    = "${ENVIRONMENT}/terraform.tfstate"
region = "$AWS_REGION"
encrypt = true
dynamodb_table = "proxima-terraform-locks"
EOF
    
    # Check if S3 bucket exists, create if not
    if ! aws s3 ls "s3://$bucket_name" &> /dev/null; then
        log_info "Creating S3 bucket for Terraform state: $bucket_name"
        aws s3 mb "s3://$bucket_name" --region "$AWS_REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$bucket_name" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$bucket_name" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
    fi
    
    # Check if DynamoDB table exists, create if not
    if ! aws dynamodb describe-table --table-name "proxima-terraform-locks" &> /dev/null; then
        log_info "Creating DynamoDB table for Terraform locks"
        aws dynamodb create-table \
            --table-name "proxima-terraform-locks" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$AWS_REGION"
        
        # Wait for table to be active
        aws dynamodb wait table-exists --table-name "proxima-terraform-locks"
    fi
    
    log_success "Terraform backend setup completed"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -backend-config="backend-${ENVIRONMENT}.hcl"
    
    # Validate Terraform configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -var="db_password=${DB_PASSWORD:-$(openssl rand -base64 32)}" \
        -var="docdb_password=${DOCDB_PASSWORD:-$(openssl rand -base64 32)}" \
        -var="jwt_secret=${JWT_SECRET:-$(openssl rand -base64 64)}" \
        -out="tfplan-${ENVIRONMENT}"
    
    # Ask for confirmation
    if [ "$ENVIRONMENT" = "production" ]; then
        log_warning "You are about to deploy to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply "tfplan-${ENVIRONMENT}"
    
    # Save outputs
    terraform output -json > "outputs-${ENVIRONMENT}.json"
    
    cd - > /dev/null
    
    log_success "Infrastructure deployment completed"
}

build_and_push_images() {
    log_info "Building and pushing Docker images..."
    
    # Get ECR registry URL
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local ecr_registry="${account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ecr_registry"
    
    # Build and push images
    local services=("frontend" "user-service" "job-service" "match-service" "ai-service")
    local git_sha=$(git rev-parse --short HEAD)
    
    for service in "${services[@]}"; do
        log_info "Building and pushing $service..."
        
        local image_tag="${ecr_registry}/proxima-${service}:${git_sha}"
        local latest_tag="${ecr_registry}/proxima-${service}:latest"
        
        if [ "$service" = "frontend" ]; then
            docker build -t "$image_tag" -t "$latest_tag" ./frontend
        else
            docker build -t "$image_tag" -t "$latest_tag" "./backend/${service}"
        fi
        
        docker push "$image_tag"
        docker push "$latest_tag"
        
        log_success "Pushed $service image: $image_tag"
    done
}

deploy_services() {
    log_info "Deploying ECS services..."
    
    # This would typically be handled by the GitHub Actions workflow
    # For manual deployment, we can trigger the ECS service updates here
    
    local cluster_name="proxima-${ENVIRONMENT}-cluster"
    local services=("frontend" "user-service" "job-service" "match-service" "ai-service")
    
    for service in "${services[@]}"; do
        log_info "Updating ECS service: $service"
        
        aws ecs update-service \
            --cluster "$cluster_name" \
            --service "proxima-${ENVIRONMENT}-${service}" \
            --force-new-deployment \
            --region "$AWS_REGION" > /dev/null
    done
    
    log_success "ECS services deployment initiated"
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Get ALB DNS name from Terraform outputs
    local alb_dns=$(cd "$TERRAFORM_DIR" && terraform output -raw alb_dns_name)
    
    if [ -z "$alb_dns" ]; then
        log_warning "Could not get ALB DNS name, skipping health checks"
        return
    fi
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 60
    
    # Health check endpoints
    local endpoints=("health" "api/v1/users/health" "api/v1/jobs/health" "api/v1/match/health" "api/v1/ai/health")
    
    for endpoint in "${endpoints[@]}"; do
        log_info "Checking health of $endpoint..."
        
        local url="http://${alb_dns}/${endpoint}"
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
        
        if [ "$response" = "200" ]; then
            log_success "✅ $endpoint is healthy"
        else
            log_warning "⚠️ $endpoint returned status: $response"
        fi
    done
}

cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove temporary files
    rm -f "${TERRAFORM_DIR}/tfplan-${ENVIRONMENT}"
    rm -f "${TERRAFORM_DIR}/backend-${ENVIRONMENT}.hcl"
    
    log_success "Cleanup completed"
}

main() {
    # Parse arguments
    ENVIRONMENT="$1"
    
    # Validate inputs
    validate_environment
    
    # Check prerequisites
    check_prerequisites
    
    # Load environment variables
    source .env
    
    log_info "Starting deployment to $ENVIRONMENT environment..."
    
    # Setup Terraform backend
    setup_terraform_backend
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Build and push Docker images
    build_and_push_images
    
    # Deploy services
    deploy_services
    
    # Run health checks
    run_health_checks
    
    # Cleanup
    cleanup
    
    log_success "🎉 Deployment to $ENVIRONMENT completed successfully!"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Production application is now live at: https://proxima.example.com"
    else
        local alb_dns=$(cd "$TERRAFORM_DIR" && terraform output -raw alb_dns_name 2>/dev/null || echo "check-aws-console")
        log_info "Staging application is available at: http://$alb_dns"
    fi
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
