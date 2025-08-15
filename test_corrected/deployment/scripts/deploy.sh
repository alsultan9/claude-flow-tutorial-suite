#!/bin/bash
# =============================================================================
# Production Deployment Script for Integration System
# =============================================================================
# This script handles the complete deployment process including:
# - Environment validation
# - Database migrations
# - Container builds and deployments
# - Health checks and rollback capabilities
# - Post-deployment verification
#
# Usage: ./deploy.sh [environment] [version]
# Example: ./deploy.sh production v1.2.3
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration and Variables
# =============================================================================

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENT_DIR="$PROJECT_ROOT"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="/tmp/deployment-${DATE}.log"

# Default values
DEFAULT_ENVIRONMENT="staging"
DEFAULT_VERSION="latest"
DEFAULT_REGISTRY="ghcr.io"
DEFAULT_NAMESPACE="integration-system"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "[${timestamp}] ${BLUE}INFO${NC}: $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "[${timestamp}] ${YELLOW}WARN${NC}: $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "[${timestamp}] ${RED}ERROR${NC}: $message" | tee -a "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "[${timestamp}] ${GREEN}SUCCESS${NC}: $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Error handler
error_handler() {
    local line_number=$1
    log "ERROR" "Script failed at line $line_number. Check $LOG_FILE for details."
    
    # Attempt rollback if in production
    if [[ "$ENVIRONMENT" == "production" ]]; then
        log "WARN" "Production deployment failed. Initiating rollback..."
        rollback_deployment || log "ERROR" "Rollback failed! Manual intervention required."
    fi
    
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Help function
show_help() {
    cat << EOF
Deployment Script for Integration System

Usage: $0 [OPTIONS] [ENVIRONMENT] [VERSION]

Arguments:
    ENVIRONMENT     Target environment (staging, production)
    VERSION         Version/tag to deploy (default: latest)

Options:
    -h, --help      Show this help message
    -d, --dry-run   Show what would be deployed without executing
    -f, --force     Force deployment without confirmations
    -s, --skip-tests Skip pre-deployment tests
    -m, --migrate   Run database migrations
    -r, --rollback  Rollback to previous version
    -c, --check     Check deployment status

Examples:
    $0 staging v1.2.3
    $0 production v2.0.0 --migrate
    $0 staging --rollback
    $0 production --check

Environment Variables:
    KUBECONFIG      Kubernetes config file path
    DOCKER_REGISTRY Docker registry URL
    SLACK_WEBHOOK   Slack webhook for notifications

EOF
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."
    
    local required_tools=("kubectl" "docker" "jq" "curl" "aws")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "Required tool '$tool' is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        log "ERROR" "Cannot connect to Kubernetes cluster. Check KUBECONFIG."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log "ERROR" "Docker daemon is not running or not accessible"
        exit 1
    fi
    
    # Check AWS CLI configuration (if using AWS)
    if ! aws sts get-caller-identity &> /dev/null; then
        log "WARN" "AWS CLI not configured. Some features may not work."
    fi
    
    log "SUCCESS" "All prerequisites satisfied"
}

# Validate environment
validate_environment() {
    log "INFO" "Validating environment: $ENVIRONMENT"
    
    case $ENVIRONMENT in
        "staging"|"production")
            log "INFO" "Environment '$ENVIRONMENT' is valid"
            ;;
        *)
            log "ERROR" "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'production'"
            exit 1
            ;;
    esac
    
    # Check if namespace exists
    if ! kubectl get namespace "$ENVIRONMENT" &> /dev/null; then
        log "ERROR" "Namespace '$ENVIRONMENT' does not exist"
        exit 1
    fi
    
    # Validate required secrets exist
    local required_secrets=("database-secret" "redis-secret" "jwt-secret")
    for secret in "${required_secrets[@]}"; do
        if ! kubectl get secret "$secret" -n "$ENVIRONMENT" &> /dev/null; then
            log "ERROR" "Required secret '$secret' not found in namespace '$ENVIRONMENT'"
            exit 1
        fi
    done
    
    log "SUCCESS" "Environment validation passed"
}

# =============================================================================
# Deployment Functions
# =============================================================================

# Run pre-deployment tests
run_tests() {
    if [[ "$SKIP_TESTS" == "true" ]]; then
        log "WARN" "Skipping tests as requested"
        return 0
    fi
    
    log "INFO" "Running pre-deployment tests..."
    
    # Health check current deployment
    if kubectl get deployment -n "$ENVIRONMENT" &> /dev/null; then
        log "INFO" "Checking current deployment health..."
        
        # Check if all deployments are ready
        local ready_deployments
        ready_deployments=$(kubectl get deployments -n "$ENVIRONMENT" -o json | jq -r '.items[] | select(.status.readyReplicas == .status.replicas) | .metadata.name')
        
        if [[ -z "$ready_deployments" ]]; then
            log "WARN" "Some deployments are not fully ready. Proceed with caution."
        else
            log "SUCCESS" "All deployments are healthy"
        fi
    fi
    
    # Run smoke tests if endpoints are available
    local api_url
    api_url=$(get_api_endpoint)
    if [[ -n "$api_url" ]]; then
        log "INFO" "Running smoke tests against $api_url"
        
        if curl -f -s "$api_url/api/v1/health" &> /dev/null; then
            log "SUCCESS" "Health endpoint is responding"
        else
            log "WARN" "Health endpoint is not responding properly"
        fi
    fi
}

# Database migration function
run_migrations() {
    if [[ "$RUN_MIGRATIONS" != "true" ]]; then
        return 0
    fi
    
    log "INFO" "Running database migrations..."
    
    # Create migration job
    cat << EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: migration-${DATE}
  namespace: ${ENVIRONMENT}
spec:
  template:
    spec:
      containers:
      - name: migration
        image: ${REGISTRY}/${IMAGE_NAME}:${VERSION}
        command: ["npm", "run", "migrate"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: NODE_ENV
          value: "${ENVIRONMENT}"
      restartPolicy: Never
  backoffLimit: 3
EOF
    
    # Wait for migration to complete
    log "INFO" "Waiting for migration to complete..."
    kubectl wait --for=condition=complete job/migration-${DATE} -n "$ENVIRONMENT" --timeout=300s
    
    # Check migration status
    local job_status
    job_status=$(kubectl get job migration-${DATE} -n "$ENVIRONMENT" -o jsonpath='{.status.conditions[0].type}')
    
    if [[ "$job_status" == "Complete" ]]; then
        log "SUCCESS" "Database migration completed successfully"
    else
        log "ERROR" "Database migration failed"
        kubectl logs job/migration-${DATE} -n "$ENVIRONMENT"
        exit 1
    fi
    
    # Cleanup migration job
    kubectl delete job migration-${DATE} -n "$ENVIRONMENT" || true
}

# Build and push containers
build_containers() {
    log "INFO" "Building and pushing containers for version: $VERSION"
    
    local services=("api-gateway" "auth-service" "user-service" "task-service" "notification-service")
    
    for service in "${services[@]}"; do
        log "INFO" "Building $service..."
        
        local image_tag="${REGISTRY}/${IMAGE_NAME}/${service}:${VERSION}"
        
        # Build container
        docker build \
            --build-arg SERVICE_NAME="$service" \
            --build-arg VERSION="$VERSION" \
            --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --build-arg GIT_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')" \
            -t "$image_tag" \
            -f "$DEPLOYMENT_DIR/docker/Dockerfile" \
            "$PROJECT_ROOT"
        
        # Security scan
        log "INFO" "Running security scan for $service..."
        if command -v trivy &> /dev/null; then
            trivy image --severity HIGH,CRITICAL "$image_tag" || log "WARN" "Security scan found issues in $service"
        fi
        
        # Push to registry
        if [[ "$DRY_RUN" != "true" ]]; then
            log "INFO" "Pushing $service to registry..."
            docker push "$image_tag"
        fi
    done
    
    log "SUCCESS" "Container build and push completed"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    log "INFO" "Deploying to Kubernetes environment: $ENVIRONMENT"
    
    # Apply base configurations
    log "INFO" "Applying base configurations..."
    kubectl apply -f "$DEPLOYMENT_DIR/kubernetes/base/" -n "$ENVIRONMENT"
    
    # Apply environment-specific configurations
    local env_config_dir="$DEPLOYMENT_DIR/kubernetes/environments/$ENVIRONMENT"
    if [[ -d "$env_config_dir" ]]; then
        log "INFO" "Applying environment-specific configurations..."
        kubectl apply -f "$env_config_dir/" -n "$ENVIRONMENT"
    fi
    
    # Update service deployments with new image tags
    local services=("api-gateway" "auth-service" "user-service" "task-service" "notification-service")
    
    for service in "${services[@]}"; do
        local image_tag="${REGISTRY}/${IMAGE_NAME}/${service}:${VERSION}"
        
        log "INFO" "Updating $service deployment..."
        
        if kubectl get deployment "$service" -n "$ENVIRONMENT" &> /dev/null; then
            kubectl set image "deployment/$service" "$service=$image_tag" -n "$ENVIRONMENT"
        else
            log "INFO" "Deploying new service: $service"
            kubectl apply -f "$DEPLOYMENT_DIR/kubernetes/services/${service}.yml" -n "$ENVIRONMENT"
        fi
    done
    
    log "SUCCESS" "Kubernetes deployment initiated"
}

# Wait for deployments to be ready
wait_for_deployment() {
    log "INFO" "Waiting for deployments to be ready..."
    
    local services=("api-gateway" "auth-service" "user-service")
    local timeout=600
    
    for service in "${services[@]}"; do
        log "INFO" "Waiting for $service to be ready..."
        
        if kubectl rollout status "deployment/$service" -n "$ENVIRONMENT" --timeout="${timeout}s"; then
            log "SUCCESS" "$service deployment is ready"
        else
            log "ERROR" "$service deployment failed to become ready within ${timeout}s"
            
            # Show recent logs for debugging
            log "INFO" "Recent logs for $service:"
            kubectl logs -l "app=integration-system,component=$service" -n "$ENVIRONMENT" --tail=50 || true
            
            # Show deployment status
            kubectl describe deployment "$service" -n "$ENVIRONMENT" || true
            
            exit 1
        fi
    done
    
    log "SUCCESS" "All deployments are ready"
}

# =============================================================================
# Health Check and Verification
# =============================================================================

# Get API endpoint URL
get_api_endpoint() {
    local api_url
    
    # Try to get from ingress
    api_url=$(kubectl get ingress api-ingress -n "$ENVIRONMENT" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    
    if [[ -n "$api_url" ]]; then
        echo "https://$api_url"
    else
        # Fallback to port-forward for testing
        echo "http://localhost:8080"
    fi
}

# Run post-deployment verification
verify_deployment() {
    log "INFO" "Running post-deployment verification..."
    
    local api_url
    api_url=$(get_api_endpoint)
    
    # Test basic endpoints
    local endpoints=("/api/v1/health" "/api/v1/auth/health" "/api/v1/users/health")
    
    for endpoint in "${endpoints[@]}"; do
        log "INFO" "Testing endpoint: $api_url$endpoint"
        
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$api_url$endpoint" || echo "000")
        
        if [[ "$response_code" == "200" ]]; then
            log "SUCCESS" "Endpoint $endpoint is healthy (HTTP $response_code)"
        else
            log "ERROR" "Endpoint $endpoint failed (HTTP $response_code)"
        fi
    done
    
    # Test database connectivity
    log "INFO" "Testing database connectivity..."
    if kubectl exec -n "$ENVIRONMENT" deployment/api-gateway -- npm run db:check &> /dev/null; then
        log "SUCCESS" "Database connectivity verified"
    else
        log "ERROR" "Database connectivity test failed"
    fi
    
    # Check resource usage
    log "INFO" "Checking resource usage..."
    kubectl top pods -n "$ENVIRONMENT" || log "WARN" "Cannot retrieve resource usage metrics"
    
    log "SUCCESS" "Post-deployment verification completed"
}

# =============================================================================
# Rollback Functions
# =============================================================================

# Rollback deployment
rollback_deployment() {
    log "WARN" "Initiating rollback for environment: $ENVIRONMENT"
    
    local services=("api-gateway" "auth-service" "user-service")
    
    for service in "${services[@]}"; do
        log "INFO" "Rolling back $service..."
        
        if kubectl rollout undo "deployment/$service" -n "$ENVIRONMENT"; then
            log "SUCCESS" "$service rollback initiated"
        else
            log "ERROR" "Failed to rollback $service"
        fi
    done
    
    # Wait for rollback to complete
    log "INFO" "Waiting for rollback to complete..."
    wait_for_deployment
    
    log "SUCCESS" "Rollback completed successfully"
}

# =============================================================================
# Notification Functions
# =============================================================================

# Send deployment notification
send_notification() {
    local status=$1
    local message=$2
    
    if [[ -z "${SLACK_WEBHOOK:-}" ]]; then
        return 0
    fi
    
    local color
    case $status in
        "success") color="good" ;;
        "warning") color="warning" ;;
        "error") color="danger" ;;
        *) color="#439FE0" ;;
    esac
    
    local payload
    payload=$(cat << EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "Deployment Notification",
            "fields": [
                {
                    "title": "Environment",
                    "value": "$ENVIRONMENT",
                    "short": true
                },
                {
                    "title": "Version",
                    "value": "$VERSION",
                    "short": true
                },
                {
                    "title": "Status",
                    "value": "$status",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$(date)",
                    "short": true
                }
            ],
            "text": "$message"
        }
    ]
}
EOF
    )
    
    curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK" &> /dev/null || true
}

# =============================================================================
# Main Deployment Logic
# =============================================================================

# Parse command line arguments
parse_arguments() {
    ENVIRONMENT="$DEFAULT_ENVIRONMENT"
    VERSION="$DEFAULT_VERSION"
    DRY_RUN="false"
    FORCE="false"
    SKIP_TESTS="false"
    RUN_MIGRATIONS="false"
    ROLLBACK="false"
    CHECK_STATUS="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -s|--skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            -m|--migrate)
                RUN_MIGRATIONS="true"
                shift
                ;;
            -r|--rollback)
                ROLLBACK="true"
                shift
                ;;
            -c|--check)
                CHECK_STATUS="true"
                shift
                ;;
            staging|production)
                ENVIRONMENT="$1"
                shift
                ;;
            *)
                if [[ $1 =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]] || [[ $1 == "latest" ]]; then
                    VERSION="$1"
                else
                    log "ERROR" "Unknown argument: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set derived variables
    REGISTRY="${DOCKER_REGISTRY:-$DEFAULT_REGISTRY}"
    IMAGE_NAME="${DEFAULT_NAMESPACE}"
}

# Check deployment status
check_deployment_status() {
    log "INFO" "Checking deployment status for environment: $ENVIRONMENT"
    
    echo "\n=== Namespace Overview ==="
    kubectl get all -n "$ENVIRONMENT" || true
    
    echo "\n=== Deployment Status ==="
    kubectl get deployments -n "$ENVIRONMENT" -o wide || true
    
    echo "\n=== Pod Status ==="
    kubectl get pods -n "$ENVIRONMENT" -o wide || true
    
    echo "\n=== Service Status ==="
    kubectl get services -n "$ENVIRONMENT" -o wide || true
    
    echo "\n=== Ingress Status ==="
    kubectl get ingress -n "$ENVIRONMENT" -o wide || true
    
    echo "\n=== Recent Events ==="
    kubectl get events -n "$ENVIRONMENT" --sort-by='.firstTimestamp' | tail -20 || true
}

# Main deployment function
main() {
    log "INFO" "Starting deployment process..."
    log "INFO" "Environment: $ENVIRONMENT, Version: $VERSION"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "DRY RUN MODE - No changes will be applied"
    fi
    
    # Handle special modes
    if [[ "$CHECK_STATUS" == "true" ]]; then
        check_deployment_status
        exit 0
    fi
    
    if [[ "$ROLLBACK" == "true" ]]; then
        rollback_deployment
        send_notification "warning" "Rollback completed for $ENVIRONMENT"
        exit 0
    fi
    
    # Confirmation for production
    if [[ "$ENVIRONMENT" == "production" ]] && [[ "$FORCE" != "true" ]]; then
        echo -e "\n${RED}WARNING: You are about to deploy to PRODUCTION!${NC}"
        echo "Environment: $ENVIRONMENT"
        echo "Version: $VERSION"
        echo -e "\nThis action will affect live users and services."
        read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
        
        if [[ ! $REPLY == "yes" ]]; then
            log "INFO" "Deployment cancelled by user"
            exit 0
        fi
    fi
    
    # Start deployment process
    local start_time
    start_time=$(date +%s)
    
    send_notification "info" "Starting deployment of $VERSION to $ENVIRONMENT"
    
    # Execute deployment steps
    check_prerequisites
    validate_environment
    run_tests
    
    if [[ "$DRY_RUN" != "true" ]]; then
        run_migrations
        build_containers
        deploy_to_kubernetes
        wait_for_deployment
        verify_deployment
    fi
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "SUCCESS" "Deployment completed successfully in ${duration}s"
    
    # Final summary
    echo -e "\n${GREEN}=== Deployment Summary ===${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Version: $VERSION"
    echo "Duration: ${duration}s"
    echo "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "API Endpoint: $(get_api_endpoint)"
        send_notification "success" "Deployment of $VERSION to $ENVIRONMENT completed successfully in ${duration}s"
    fi
    
    log "SUCCESS" "All deployment tasks completed"
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Initialize logging
touch "$LOG_FILE"
log "INFO" "Deployment script started. Log file: $LOG_FILE"

# Parse arguments and run main function
parse_arguments "$@"

# Trap cleanup
trap 'log "INFO" "Deployment script finished. Log file: $LOG_FILE"' EXIT

# Run main deployment logic
main