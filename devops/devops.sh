#!/bin/bash

# LLM Platform - DevOps Management Script
# Main entry point for all DevOps operations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

echo -e "${BLUE}🚀 LLM Platform DevOps Management${NC}"
echo "===================================="

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

# Function to show available scripts
show_scripts() {
    print_info "Available DevOps Scripts:"
    echo ""
    echo "  🔨 Build Scripts:"
    echo "    ./devops.sh build [options]     - Build components"
    echo "    ./devops.sh clean               - Clean build artifacts"
    echo ""
    echo "  🚀 Deployment Scripts:"
    echo "    ./devops.sh deploy [options]    - Deploy services"
    echo "    ./devops.sh rebuild             - Rebuild and deploy"
    echo "    ./devops.sh rollback            - Rollback deployment"
    echo ""
    echo "  📊 Monitoring Scripts:"
    echo "    ./devops.sh monitor [options]   - Monitor services"
    echo "    ./devops.sh status              - Show service status"
    echo "    ./devops.sh logs [service]      - Show service logs"
    echo ""
    echo "  📝 Git Scripts:"
    echo "    ./devops.sh git-update [options] - Push to GitHub"
    echo "    ./devops.sh git-status           - Show git status"
    echo ""
    echo "  🛠️  Utility Scripts:"
    echo "    ./devops.sh help                 - Show this help"
    echo "    ./devops.sh info                 - Show project info"
    echo ""
}

# Function to show project info
show_info() {
    print_info "LLM Platform Project Information:"
    echo ""
    echo "  Project: LLM Platform"
    echo "  Repository: https://github.com/gokhul/poc-platform"
    echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'Unknown')"
    echo "  Last Commit: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "  Scripts Directory: $SCRIPTS_DIR"
    echo "  Project Root: $(pwd)"
    echo ""
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        print_status "Docker is available"
    else
        print_error "Docker is not available"
    fi
    
    # Check if Docker Compose is available
    if command -v docker-compose &> /dev/null; then
        print_status "Docker Compose is available"
    else
        print_error "Docker Compose is not available"
    fi
    
    # Check if Node.js is available
    if command -v node &> /dev/null; then
        print_status "Node.js is available ($(node --version))"
    else
        print_warning "Node.js is not available"
    fi
    
    # Check if Python is available
    if command -v python3 &> /dev/null; then
        print_status "Python3 is available ($(python3 --version))"
    else
        print_warning "Python3 is not available"
    fi
}

# Function to run build script
run_build() {
    print_info "Running build script..."
    "$SCRIPTS_DIR/build.sh" "$@"
}

# Function to run deployment script
run_deploy() {
    print_info "Running deployment script..."
    "$SCRIPTS_DIR/deploy.sh" "$@"
}

# Function to run monitoring script
run_monitor() {
    print_info "Running monitoring script..."
    "$SCRIPTS_DIR/monitor.sh" "$@"
}

# Function to run git update script
run_git_update() {
    print_info "Running git update script..."
    "$SCRIPTS_DIR/git-update.sh" "$@"
}

# Function to clean project
clean_project() {
    print_info "Cleaning project..."
    
    # Clean build artifacts
    if [ -d "frontend" ]; then
        print_info "Cleaning frontend..."
        cd frontend
        rm -rf dist/ node_modules/.cache/ .vite/
        cd ..
    fi
    
    if [ -d "backend" ]; then
        print_info "Cleaning backend..."
        cd backend
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find . -type f -name "*.pyc" -delete 2>/dev/null || true
        cd ..
    fi
    
    # Clean Docker
    print_info "Cleaning Docker..."
    docker system prune -f
    
    print_status "Project cleaned successfully"
}

# Function to show git status
show_git_status() {
    print_info "Git Status:"
    git status --short
    echo ""
    print_info "Recent commits:"
    git log --oneline -5
}

# Function to rebuild everything
rebuild_all() {
    print_info "Rebuilding everything..."
    
    # Clean first
    clean_project
    
    # Stop services
    docker-compose down
    
    # Rebuild and start
    docker-compose up --build -d
    
    # Wait and verify
    sleep 30
    "$SCRIPTS_DIR/monitor.sh" --all
    
    print_status "Rebuild completed"
}

# Function to rollback
rollback_deployment() {
    print_warning "Rolling back deployment..."
    docker-compose down
    print_status "Rollback completed"
}

# Main function
main() {
    local command="$1"
    shift || true
    
    case "$command" in
        "build")
            run_build "$@"
            ;;
        "deploy")
            run_deploy "$@"
            ;;
        "monitor"|"status")
            if [ "$command" = "status" ]; then
                run_monitor --all
            else
                run_monitor "$@"
            fi
            ;;
        "logs")
            run_monitor --logs "$1"
            ;;
        "git-update")
            run_git_update "$@"
            ;;
        "git-status")
            show_git_status
            ;;
        "clean")
            clean_project
            ;;
        "rebuild")
            rebuild_all
            ;;
        "rollback")
            rollback_deployment
            ;;
        "info")
            show_info
            ;;
        "help"|"-h"|"--help"|"")
            show_scripts
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_scripts
            exit 1
            ;;
    esac
}

# Check if scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    print_error "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

# Run main function with all arguments
main "$@"
