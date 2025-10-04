#!/bin/bash

# LLM Platform - Quick Rebuild Script
# This script provides different levels of rebuild for the LLM Platform

set -e  # Exit on any error

echo "🚀 LLM Platform Rebuild Script"
echo "================================"

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker Desktop first."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to check for port conflicts
check_ports() {
    echo "🔍 Checking for port conflicts..."
    CONFLICTS=()
    
    PORTS=(8000 5173 54321 6380 6333 6334 9092 3002 9002 9003 3000)
    
    for port in "${PORTS[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            CONFLICTS+=($port)
        fi
    done
    
    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        echo "⚠️  Port conflicts detected on: ${CONFLICTS[*]}"
        echo "You may need to kill these processes or change ports in docker-compose.yml"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ No port conflicts detected"
    fi
}

# Function for quick rebuild
quick_rebuild() {
    echo "🔄 Performing quick rebuild..."
    docker-compose down
    docker-compose up --build -d
    echo "✅ Quick rebuild completed"
}

# Function for clean rebuild
clean_rebuild() {
    echo "🧹 Performing clean rebuild..."
    docker-compose down --volumes --remove-orphans
    docker system prune -f
    docker-compose up --build -d
    echo "✅ Clean rebuild completed"
}

# Function for emergency rebuild
emergency_rebuild() {
    echo "🚨 Performing emergency rebuild (this will remove all Docker data)..."
    read -p "Are you sure? This will delete all Docker containers, images, and volumes! (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Emergency rebuild cancelled"
        exit 1
    fi
    
    echo "🧹 Cleaning Docker completely..."
    docker-compose down --volumes --remove-orphans
    docker system prune -a -f --volumes
    docker builder prune -a -f
    
    echo "🔄 Restarting Docker Desktop..."
    killall Docker 2>/dev/null || true
    open -a Docker
    echo "⏳ Waiting for Docker to start..."
    sleep 15
    
    echo "🔍 Verifying Docker is working..."
    check_docker
    
    echo "🏗️  Building from scratch..."
    docker-compose up --build -d
    
    echo "✅ Emergency rebuild completed"
}

# Function to verify services
verify_services() {
    echo "🔍 Verifying services..."
    sleep 10
    
    echo "📊 Container status:"
    docker-compose ps
    
    echo "🏥 Health checks:"
    
    # Check API
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ API is healthy"
    else
        echo "❌ API health check failed"
    fi
    
    # Check Frontend
    if curl -s http://localhost:5173 > /dev/null; then
        echo "✅ Frontend is accessible"
    else
        echo "❌ Frontend is not accessible"
    fi
    
    # Check Qdrant
    if curl -s http://localhost:6333/health > /dev/null; then
        echo "✅ Qdrant is healthy"
    else
        echo "❌ Qdrant health check failed"
    fi
    
    echo "📋 Service URLs:"
    echo "   Frontend: http://localhost:5173"
    echo "   API: http://localhost:8000"
    echo "   API Docs: http://localhost:8000/api/docs"
    echo "   Grafana: http://localhost:3002"
    echo "   Langfuse: http://localhost:3000"
}

# Function to show logs
show_logs() {
    echo "📋 Recent logs:"
    docker-compose logs --tail=20
}

# Main script
case "${1:-}" in
    "quick")
        check_docker
        check_ports
        quick_rebuild
        verify_services
        ;;
    "clean")
        check_docker
        check_ports
        clean_rebuild
        verify_services
        ;;
    "emergency")
        check_docker
        emergency_rebuild
        verify_services
        ;;
    "verify")
        verify_services
        ;;
    "logs")
        show_logs
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  quick     - Quick rebuild (stop, rebuild, start)"
        echo "  clean     - Clean rebuild (remove volumes, prune, rebuild)"
        echo "  emergency - Emergency rebuild (complete Docker reset)"
        echo "  verify    - Verify all services are running"
        echo "  logs      - Show recent logs"
        echo "  help      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 quick     # Quick rebuild when things are mostly working"
        echo "  $0 clean     # Clean rebuild when you have issues"
        echo "  $0 emergency # Emergency rebuild when everything is broken"
        echo "  $0 verify    # Check if services are running properly"
        ;;
    *)
        echo "❌ Unknown command: ${1:-}"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo "🎉 Script completed successfully!"
echo "📖 For detailed troubleshooting, see docs/troubleshooting.md"
