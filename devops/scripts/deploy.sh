#!/bin/bash

# LLM Platform - Deployment Script
# This script handles deployment of the LLM Platform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="llm-platform"
ENVIRONMENT="development"
DOCKER_COMPOSE_FILE="docker-compose.yml"

echo -e "${BLUE}🚀 LLM Platform Deployment Script${NC}"
echo "====================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_status "Docker is available"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_status "Docker Compose is available"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    print_status "Docker is running"
    
    # Check if docker-compose.yml exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        print_error "docker-compose.yml not found in current directory"
        exit 1
    fi
    print_status "Docker Compose file found"
}

# Function to check for port conflicts
check_ports() {
    print_info "Checking for port conflicts..."
    
    PORTS=(8000 5173 54321 6380 6333 6334 9092 3002 9002 9003 3000)
    CONFLICTS=()
    
    for port in "${PORTS[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            CONFLICTS+=($port)
        fi
    done
    
    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        print_warning "Port conflicts detected on: ${CONFLICTS[*]}"
        print_info "You may need to stop these services or modify ports in docker-compose.yml"
        return 1
    else
        print_status "No port conflicts detected"
        return 0
    fi
}

# Function to deploy services
deploy_services() {
    local rebuild="$1"
    
    print_info "Deploying LLM Platform services..."
    
    if [ "$rebuild" = true ]; then
        print_info "Performing rebuild deployment..."
        docker-compose down --remove-orphans
        docker-compose up --build -d
    else
        print_info "Performing standard deployment..."
        docker-compose up -d
    fi
    
    print_status "Deployment initiated"
}

# Function to wait for services
wait_for_services() {
    print_info "Waiting for services to start..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_info "Checking services (attempt $attempt/$max_attempts)..."
        
        # Check if containers are running
        if docker-compose ps | grep -q "Up"; then
            print_status "Services are starting up"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Services failed to start within timeout"
            return 1
        fi
        
        sleep 2
        ((attempt++))
    done
    
    # Wait a bit more for services to fully initialize
    print_info "Waiting for services to fully initialize..."
    sleep 10
}

# Function to verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    local failed_checks=0
    
    # Check API health
    if curl -s http://localhost:8000/health > /dev/null; then
        print_status "API is healthy"
    else
        print_warning "API health check failed"
        ((failed_checks++))
    fi
    
    # Check Frontend
    if curl -s http://localhost:5173 > /dev/null; then
        print_status "Frontend is accessible"
    else
        print_warning "Frontend is not accessible"
        ((failed_checks++))
    fi
    
    # Check Qdrant
    if curl -s http://localhost:6333/health > /dev/null; then
        print_status "Qdrant is healthy"
    else
        print_warning "Qdrant health check failed"
        ((failed_checks++))
    fi
    
    # Check Grafana
    if curl -s http://localhost:3002 > /dev/null; then
        print_status "Grafana is accessible"
    else
        print_warning "Grafana is not accessible"
        ((failed_checks++))
    fi
    
    if [ $failed_checks -eq 0 ]; then
        print_status "All services verified successfully"
        return 0
    else
        print_warning "$failed_checks service(s) failed verification"
        return 1
    fi
}

# Function to show deployment status
show_status() {
    print_info "Deployment Status:"
    echo ""
    docker-compose ps
    echo ""
    print_info "Service URLs:"
    echo "  Frontend:    http://localhost:5173"
    echo "  API:         http://localhost:8000"
    echo "  API Docs:    http://localhost:8000/api/docs"
    echo "  Grafana:     http://localhost:3002 (admin/admin)"
    echo "  Langfuse:    http://localhost:3000"
    echo "  MinIO:       http://localhost:9003 (minioadmin/minioadmin)"
    echo "  Prometheus:  http://localhost:9092"
}

# Function to show logs
show_logs() {
    print_info "Recent deployment logs:"
    docker-compose logs --tail=20
}

# Function to rollback
rollback() {
    print_warning "Rolling back deployment..."
    docker-compose down
    print_status "Rollback completed"
}

# Main function
main() {
    local rebuild=false
    local verify=false
    local status=false
    local logs=false
    local rollback_deploy=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rebuild)
                rebuild=true
                shift
                ;;
            --verify)
                verify=true
                shift
                ;;
            --status)
                status=true
                shift
                ;;
            --logs)
                logs=true
                shift
                ;;
            --rollback)
                rollback_deploy=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --rebuild    Force rebuild of all images"
                echo "  --verify     Verify deployment after completion"
                echo "  --status     Show deployment status"
                echo "  --logs       Show recent logs"
                echo "  --rollback   Rollback the deployment"
                echo "  -h, --help   Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                    # Standard deployment"
                echo "  $0 --rebuild          # Rebuild and deploy"
                echo "  $0 --verify           # Deploy and verify"
                echo "  $0 --status           # Show current status"
                echo "  $0 --logs             # Show recent logs"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Handle special commands
    if [ "$status" = true ]; then
        show_status
        exit 0
    fi
    
    if [ "$logs" = true ]; then
        show_logs
        exit 0
    fi
    
    if [ "$rollback_deploy" = true ]; then
        rollback
        exit 0
    fi
    
    # Main deployment workflow
    check_prerequisites
    
    if ! check_ports; then
        print_warning "Port conflicts detected. Continue anyway? (y/N)"
        read -p "" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Deployment cancelled"
            exit 0
        fi
    fi
    
    deploy_services "$rebuild"
    wait_for_services
    
    if [ "$verify" = true ]; then
        if verify_deployment; then
            print_status "Deployment verification successful"
        else
            print_warning "Deployment verification failed"
            show_logs
            exit 1
        fi
    fi
    
    show_status
    
    print_status "Deployment completed successfully!"
}

# Run main function with all arguments
main "$@"
