#!/bin/bash

# LLM Platform - Monitoring Script
# This script provides monitoring and health checks for the LLM Platform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:5173"
GRAFANA_URL="http://localhost:3002"
PROMETHEUS_URL="http://localhost:9092"
QDRANT_URL="http://localhost:6333"

echo -e "${BLUE}📊 LLM Platform Monitoring Script${NC}"
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

# Function to check HTTP endpoint
check_endpoint() {
    local url="$1"
    local name="$2"
    local timeout="${3:-5}"
    
    if curl -s --max-time "$timeout" "$url" > /dev/null; then
        print_status "$name is responding"
        return 0
    else
        print_error "$name is not responding"
        return 1
    fi
}

# Function to check API health
check_api_health() {
    print_info "Checking API health..."
    
    local health_url="$API_URL/health"
    local response=$(curl -s --max-time 5 "$health_url" 2>/dev/null || echo "ERROR")
    
    if [ "$response" = "ERROR" ]; then
        print_error "API health check failed - endpoint not reachable"
        return 1
    fi
    
    # Parse JSON response
    local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    local environment=$(echo "$response" | grep -o '"environment":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$status" = "healthy" ]; then
        print_status "API is healthy (environment: $environment)"
        return 0
    else
        print_error "API health check failed - status: $status"
        return 1
    fi
}

# Function to check container status
check_containers() {
    print_info "Checking container status..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not available"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose not available"
        return 1
    fi
    
    local containers=$(docker-compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null)
    
    if [ -n "$containers" ]; then
        echo "$containers" | tail -n +2 | while read -r name status; do
            if [[ "$status" == *"Up"* ]]; then
                print_status "Container $name is running"
            else
                print_error "Container $name is not running: $status"
            fi
        done
    else
        print_error "No containers found or docker-compose not running"
        return 1
    fi
}

# Function to check resource usage
check_resources() {
    print_info "Checking resource usage..."
    
    # Check Docker resource usage
    if command -v docker &> /dev/null; then
        print_info "Docker container resource usage:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || print_warning "Could not retrieve Docker stats"
    fi
    
    # Check system resources
    print_info "System resource usage:"
    
    # CPU usage
    if command -v top &> /dev/null; then
        local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        print_info "CPU Usage: ${cpu_usage}%"
    fi
    
    # Memory usage
    if command -v vm_stat &> /dev/null; then
        local memory_info=$(vm_stat | grep -E "(free|active|inactive|wired)")
        print_info "Memory Info:"
        echo "$memory_info"
    fi
    
    # Disk usage
    if command -v df &> /dev/null; then
        local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
        print_info "Disk Usage: $disk_usage"
    fi
}

# Function to check logs
check_logs() {
    local service="$1"
    local lines="${2:-10}"
    
    if [ -n "$service" ]; then
        print_info "Recent logs for $service:"
        docker-compose logs --tail="$lines" "$service" 2>/dev/null || print_error "Could not retrieve logs for $service"
    else
        print_info "Recent logs for all services:"
        docker-compose logs --tail="$lines" 2>/dev/null || print_error "Could not retrieve logs"
    fi
}

# Function to check database connectivity
check_database() {
    print_info "Checking database connectivity..."
    
    # Check PostgreSQL
    if docker-compose exec -T postgres pg_isready -U llmuser -d llmplatform 2>/dev/null; then
        print_status "PostgreSQL is ready"
    else
        print_error "PostgreSQL is not ready"
    fi
    
    # Check Redis
    if docker-compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        print_status "Redis is responding"
    else
        print_error "Redis is not responding"
    fi
}

# Function to check external services
check_external_services() {
    print_info "Checking external services..."
    
    check_endpoint "$FRONTEND_URL" "Frontend" 5
    check_endpoint "$GRAFANA_URL" "Grafana" 5
    check_endpoint "$PROMETHEUS_URL" "Prometheus" 5
    check_endpoint "$QDRANT_URL/health" "Qdrant" 5
}

# Function to generate monitoring report
generate_report() {
    local output_file="${1:-monitoring-report.txt}"
    
    print_info "Generating monitoring report: $output_file"
    
    {
        echo "LLM Platform Monitoring Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo ""
        
        echo "Container Status:"
        docker-compose ps 2>/dev/null || echo "Docker Compose not available"
        echo ""
        
        echo "API Health:"
        check_api_health || echo "API health check failed"
        echo ""
        
        echo "External Services:"
        check_external_services || echo "External service checks failed"
        echo ""
        
        echo "Database Status:"
        check_database || echo "Database checks failed"
        echo ""
        
        echo "Resource Usage:"
        docker stats --no-stream 2>/dev/null || echo "Could not retrieve resource stats"
        echo ""
        
    } > "$output_file"
    
    print_status "Monitoring report saved to: $output_file"
}

# Function to start monitoring loop
start_monitoring() {
    local interval="${1:-30}"
    
    print_info "Starting monitoring loop (interval: ${interval}s)"
    print_info "Press Ctrl+C to stop"
    
    while true; do
        echo ""
        echo "=== Monitoring Check - $(date) ==="
        
        check_containers
        check_api_health
        check_external_services
        
        echo "Waiting ${interval} seconds for next check..."
        sleep "$interval"
    done
}

# Function to show service URLs
show_urls() {
    print_info "Service URLs:"
    echo "  Frontend:    $FRONTEND_URL"
    echo "  API:         $API_URL"
    echo "  API Docs:    $API_URL/api/docs"
    echo "  Grafana:     $GRAFANA_URL (admin/admin)"
    echo "  Prometheus:  $PROMETHEUS_URL"
    echo "  Qdrant:      $QDRANT_URL"
}

# Main function
main() {
    local check_containers_flag=false
    local check_api_flag=false
    local check_external_flag=false
    local check_database_flag=false
    local check_resources_flag=false
    local check_all=false
    local logs_service=""
    local logs_lines=10
    local generate_report_flag=false
    local report_file=""
    local monitor_flag=false
    local monitor_interval=30
    local show_urls_flag=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --containers)
                check_containers_flag=true
                shift
                ;;
            --api)
                check_api_flag=true
                shift
                ;;
            --external)
                check_external_flag=true
                shift
                ;;
            --database)
                check_database_flag=true
                shift
                ;;
            --resources)
                check_resources_flag=true
                shift
                ;;
            --logs)
                logs_service="$2"
                shift 2
                ;;
            --lines)
                logs_lines="$2"
                shift 2
                ;;
            --report)
                generate_report_flag=true
                report_file="$2"
                shift 2
                ;;
            --monitor)
                monitor_flag=true
                monitor_interval="$2"
                shift 2
                ;;
            --urls)
                show_urls_flag=true
                shift
                ;;
            --all)
                check_all=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --containers        Check container status"
                echo "  --api               Check API health"
                echo "  --external          Check external services"
                echo "  --database          Check database connectivity"
                echo "  --resources         Check resource usage"
                echo "  --logs SERVICE      Show logs for specific service"
                echo "  --lines NUM         Number of log lines to show (default: 10)"
                echo "  --report FILE       Generate monitoring report"
                echo "  --monitor SECONDS   Start monitoring loop"
                echo "  --urls              Show service URLs"
                echo "  --all               Run all checks"
                echo "  -h, --help          Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --all                    # Run all checks"
                echo "  $0 --api --external         # Check API and external services"
                echo "  $0 --logs api --lines 20    # Show 20 lines of API logs"
                echo "  $0 --monitor 60             # Monitor every 60 seconds"
                echo "  $0 --report report.txt      # Generate report file"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Default to checking all if no specific options
    if [ "$check_containers_flag" = false ] && [ "$check_api_flag" = false ] && [ "$check_external_flag" = false ] && [ "$check_database_flag" = false ] && [ "$check_resources_flag" = false ] && [ "$check_all" = false ] && [ -z "$logs_service" ] && [ "$generate_report_flag" = false ] && [ "$monitor_flag" = false ] && [ "$show_urls_flag" = false ]; then
        check_all=true
    fi
    
    # Handle special commands
    if [ "$show_urls_flag" = true ]; then
        show_urls
        exit 0
    fi
    
    if [ "$monitor_flag" = true ]; then
        start_monitoring "$monitor_interval"
        exit 0
    fi
    
    if [ "$generate_report_flag" = true ]; then
        generate_report "$report_file"
        exit 0
    fi
    
    if [ -n "$logs_service" ]; then
        check_logs "$logs_service" "$logs_lines"
        exit 0
    fi
    
    # Run checks
    if [ "$check_all" = true ]; then
        check_containers
        check_api_health
        check_external_services
        check_database
        check_resources
    else
        if [ "$check_containers_flag" = true ]; then
            check_containers
        fi
        
        if [ "$check_api_flag" = true ]; then
            check_api_health
        fi
        
        if [ "$check_external_flag" = true ]; then
            check_external_services
        fi
        
        if [ "$check_database_flag" = true ]; then
            check_database
        fi
        
        if [ "$check_resources_flag" = true ]; then
            check_resources
        fi
    fi
    
    show_urls
    print_status "Monitoring completed successfully!"
}

# Run main function with all arguments
main "$@"
