#!/bin/bash

# LLM Platform - Git Update Script
# This script pushes all changes to the dev GitHub repository

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="poc-platform"
GITHUB_USER="gokhul"
DEFAULT_BRANCH="dev"
MAIN_BRANCH="main"

echo -e "${BLUE}🚀 LLM Platform Git Update Script${NC}"
echo "=================================="

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

# Function to check if git is available
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed or not in PATH"
        exit 1
    fi
    print_status "Git is available"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    print_status "In a git repository"
}

# Function to check git status
check_git_status() {
    print_info "Checking git status..."
    
    # Check if there are any changes
    if git diff-index --quiet HEAD --; then
        if [ -z "$(git status --porcelain)" ]; then
            print_warning "No changes to commit"
            return 1
        fi
    fi
    
    # Show status
    echo "Current status:"
    git status --short
    
    return 0
}

# Function to add all changes
add_changes() {
    print_info "Adding all changes..."
    git add .
    print_status "All changes added to staging"
}

# Function to commit changes
commit_changes() {
    local message="$1"
    
    if [ -z "$message" ]; then
        print_info "Generating commit message..."
        message="Update: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    print_info "Committing changes with message: '$message'"
    git commit -m "$message"
    print_status "Changes committed successfully"
}

# Function to push to GitHub
push_to_github() {
    local branch="$1"
    
    if [ -z "$branch" ]; then
        branch="$DEFAULT_BRANCH"
    fi
    
    print_info "Pushing to GitHub repository: $GITHUB_USER/$REPO_NAME"
    print_info "Branch: $branch"
    
    # Check if remote exists
    if ! git remote get-url origin > /dev/null 2>&1; then
        print_error "No remote 'origin' found"
        print_info "Adding remote origin..."
        git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    fi
    
    # Push to GitHub
    if git push -u origin "$branch"; then
        print_status "Successfully pushed to GitHub"
        
        # Show repository URL
        local repo_url="https://github.com/$GITHUB_USER/$REPO_NAME"
        echo ""
        print_info "Repository URL: $repo_url"
        print_info "Branch URL: $repo_url/tree/$branch"
    else
        print_error "Failed to push to GitHub"
        exit 1
    fi
}

# Function to create pull request
create_pull_request() {
    local target_branch="$1"
    
    if [ -z "$target_branch" ]; then
        target_branch="$MAIN_BRANCH"
    fi
    
    print_info "Creating pull request from $DEFAULT_BRANCH to $target_branch"
    
    # Check if GitHub CLI is available
    if command -v gh &> /dev/null; then
        print_info "Using GitHub CLI to create pull request..."
        gh pr create --base "$target_branch" --head "$DEFAULT_BRANCH" --title "Update from dev branch" --body "Automated update from development branch"
        print_status "Pull request created successfully"
    else
        print_warning "GitHub CLI not found. Please create pull request manually:"
        print_info "URL: https://github.com/$GITHUB_USER/$REPO_NAME/compare/$target_branch...$DEFAULT_BRANCH"
    fi
}

# Function to show repository info
show_repo_info() {
    print_info "Repository Information:"
    echo "  Repository: $GITHUB_USER/$REPO_NAME"
    echo "  Current branch: $(git branch --show-current)"
    echo "  Remote URL: $(git remote get-url origin 2>/dev/null || echo 'Not set')"
    echo "  Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)')"
}

# Function to clean up
cleanup() {
    print_info "Cleaning up..."
    # Add any cleanup tasks here
}

# Main function
main() {
    local commit_message=""
    local target_branch=""
    local create_pr=false
    local show_info=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--message)
                commit_message="$2"
                shift 2
                ;;
            -b|--branch)
                target_branch="$2"
                shift 2
                ;;
            --create-pr)
                create_pr=true
                shift
                ;;
            --info)
                show_info=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -m, --message MESSAGE    Commit message (default: auto-generated)"
                echo "  -b, --branch BRANCH      Target branch (default: dev)"
                echo "  --create-pr              Create pull request after push"
                echo "  --info                   Show repository information"
                echo "  -h, --help               Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                       # Auto-commit and push to dev"
                echo "  $0 -m \"Fix API bug\"      # Commit with custom message"
                echo "  $0 --create-pr           # Push and create PR to main"
                echo "  $0 --info                # Show repository info"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Show info and exit if requested
    if [ "$show_info" = true ]; then
        check_git_repo
        show_repo_info
        exit 0
    fi
    
    # Main workflow
    check_git
    check_git_repo
    show_repo_info
    
    # Check if there are changes to commit
    if ! check_git_status; then
        print_warning "No changes detected. Nothing to push."
        exit 0
    fi
    
    # Confirm before proceeding
    echo ""
    print_warning "The following changes will be committed and pushed:"
    git status --short
    echo ""
    
    if [ "$create_pr" = true ]; then
        print_info "A pull request will be created after push"
    fi
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 0
    fi
    
    # Execute the workflow
    add_changes
    commit_changes "$commit_message"
    push_to_github "$target_branch"
    
    if [ "$create_pr" = true ]; then
        create_pull_request
    fi
    
    # Show final status
    echo ""
    print_status "Git update completed successfully!"
    print_info "Repository: https://github.com/$GITHUB_USER/$REPO_NAME"
    print_info "Branch: $(git branch --show-current)"
    
    cleanup
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "$@"
