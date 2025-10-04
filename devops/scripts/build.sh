#!/bin/bash

# LLM Platform - Build Script
# This script handles building of the LLM Platform components

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="llm-platform"
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"

echo -e "${BLUE}🔨 LLM Platform Build Script${NC}"
echo "================================="

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
    print_info "Checking build prerequisites..."
    
    # Check Node.js for frontend
    if command -v node &> /dev/null; then
        print_status "Node.js is available ($(node --version))"
    else
        print_warning "Node.js not found (frontend builds will be skipped)"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        print_status "npm is available ($(npm --version))"
    else
        print_warning "npm not found (frontend builds will be skipped)"
    fi
    
    # Check Python for backend
    if command -v python3 &> /dev/null; then
        print_status "Python3 is available ($(python3 --version))"
    else
        print_warning "Python3 not found (backend builds will be skipped)"
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        print_status "pip3 is available"
    else
        print_warning "pip3 not found (backend builds will be skipped)"
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_status "Docker is available"
    else
        print_error "Docker is required for containerized builds"
        exit 1
    fi
}

# Function to clean build artifacts
clean_build() {
    print_info "Cleaning build artifacts..."
    
    # Clean frontend
    if [ -d "$FRONTEND_DIR" ]; then
        print_info "Cleaning frontend build artifacts..."
        cd "$FRONTEND_DIR"
        rm -rf dist/ node_modules/.cache/ .vite/
        cd ..
        print_status "Frontend build artifacts cleaned"
    fi
    
    # Clean backend
    if [ -d "$BACKEND_DIR" ]; then
        print_info "Cleaning backend build artifacts..."
        cd "$BACKEND_DIR"
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find . -type f -name "*.pyc" -delete 2>/dev/null || true
        cd ..
        print_status "Backend build artifacts cleaned"
    fi
    
    # Clean Docker
    print_info "Cleaning Docker build cache..."
    docker builder prune -f
    print_status "Docker build cache cleaned"
}

# Function to build frontend
build_frontend() {
    print_info "Building frontend..."
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies
    print_info "Installing frontend dependencies..."
    if npm install; then
        print_status "Frontend dependencies installed"
    else
        print_error "Failed to install frontend dependencies"
        cd ..
        return 1
    fi
    
    # Build frontend
    print_info "Building frontend for production..."
    if npm run build; then
        print_status "Frontend build completed successfully"
    else
        print_error "Frontend build failed"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Function to build backend
build_backend() {
    print_info "Building backend..."
    
    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "Backend directory not found"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_info "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    print_info "Installing backend dependencies..."
    if pip install -r requirements.txt; then
        print_status "Backend dependencies installed"
    else
        print_error "Failed to install backend dependencies"
        deactivate
        cd ..
        return 1
    fi
    
    # Run tests (optional)
    if [ -d "tests" ]; then
        print_info "Running backend tests..."
        if python -m pytest tests/ -v; then
            print_status "Backend tests passed"
        else
            print_warning "Backend tests failed"
        fi
    fi
    
    deactivate
    cd ..
    return 0
}

# Function to build Docker images
build_docker() {
    print_info "Building Docker images..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found"
        return 1
    fi
    
    # Build all services
    if docker-compose build; then
        print_status "Docker images built successfully"
    else
        print_error "Docker build failed"
        return 1
    fi
    
    return 0
}

# Function to run linting
run_linting() {
    print_info "Running linting checks..."
    
    # Frontend linting
    if [ -d "$FRONTEND_DIR" ]; then
        print_info "Running frontend linting..."
        cd "$FRONTEND_DIR"
        if npm run lint 2>/dev/null; then
            print_status "Frontend linting passed"
        else
            print_warning "Frontend linting failed or not configured"
        fi
        cd ..
    fi
    
    # Backend linting (if available)
    if [ -d "$BACKEND_DIR" ]; then
        print_info "Checking backend code quality..."
        cd "$BACKEND_DIR"
        if command -v flake8 &> /dev/null; then
            if flake8 .; then
                print_status "Backend code quality check passed"
            else
                print_warning "Backend code quality issues found"
            fi
        else
            print_warning "flake8 not installed, skipping backend linting"
        fi
        cd ..
    fi
}

# Function to run tests
run_tests() {
    print_info "Running tests..."
    
    local test_results=0
    
    # Frontend tests
    if [ -d "$FRONTEND_DIR" ]; then
        print_info "Running frontend tests..."
        cd "$FRONTEND_DIR"
        if npm test 2>/dev/null; then
            print_status "Frontend tests passed"
        else
            print_warning "Frontend tests failed or not configured"
            test_results=1
        fi
        cd ..
    fi
    
    # Backend tests
    if [ -d "$BACKEND_DIR/tests" ]; then
        print_info "Running backend tests..."
        cd "$BACKEND_DIR"
        if [ -d "venv" ]; then
            source venv/bin/activate
            if python -m pytest tests/ -v; then
                print_status "Backend tests passed"
            else
                print_warning "Backend tests failed"
                test_results=1
            fi
            deactivate
        fi
        cd ..
    fi
    
    return $test_results
}

# Function to show build summary
show_summary() {
    print_info "Build Summary:"
    echo ""
    echo "Project: $PROJECT_NAME"
    echo "Frontend: $([ -d "$FRONTEND_DIR/dist" ] && echo "✅ Built" || echo "❌ Not built")"
    echo "Backend: $([ -d "$BACKEND_DIR/venv" ] && echo "✅ Built" || echo "❌ Not built")"
    echo "Docker: $([ -n "$(docker images | grep agentic)" ] && echo "✅ Built" || echo "❌ Not built")"
    echo ""
    
    # Show Docker images
    print_info "Docker Images:"
    docker images | grep agentic || echo "No agentic images found"
}

# Main function
main() {
    local clean=false
    local frontend=false
    local backend=false
    local docker=false
    local lint=false
    local test=false
    local all=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean=true
                shift
                ;;
            --frontend)
                frontend=true
                shift
                ;;
            --backend)
                backend=true
                shift
                ;;
            --docker)
                docker=true
                shift
                ;;
            --lint)
                lint=true
                shift
                ;;
            --test)
                test=true
                shift
                ;;
            --all)
                all=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --clean      Clean build artifacts"
                echo "  --frontend   Build frontend only"
                echo "  --backend    Build backend only"
                echo "  --docker     Build Docker images only"
                echo "  --lint       Run linting checks"
                echo "  --test       Run tests"
                echo "  --all        Build everything"
                echo "  -h, --help   Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --all              # Build everything"
                echo "  $0 --frontend --test  # Build frontend and run tests"
                echo "  $0 --clean --docker   # Clean and build Docker images"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Default to building all if no specific options
    if [ "$clean" = false ] && [ "$frontend" = false ] && [ "$backend" = false ] && [ "$docker" = false ] && [ "$lint" = false ] && [ "$test" = false ] && [ "$all" = false ]; then
        all=true
    fi
    
    check_prerequisites
    
    if [ "$clean" = true ] || [ "$all" = true ]; then
        clean_build
    fi
    
    if [ "$frontend" = true ] || [ "$all" = true ]; then
        build_frontend
    fi
    
    if [ "$backend" = true ] || [ "$all" = true ]; then
        build_backend
    fi
    
    if [ "$docker" = true ] || [ "$all" = true ]; then
        build_docker
    fi
    
    if [ "$lint" = true ]; then
        run_linting
    fi
    
    if [ "$test" = true ]; then
        run_tests
    fi
    
    show_summary
    
    print_status "Build completed successfully!"
}

# Run main function with all arguments
main "$@"
