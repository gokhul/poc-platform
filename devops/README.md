# DevOps Scripts - LLM Platform

This directory contains all the DevOps scripts and tools for managing the LLM Platform deployment, monitoring, and maintenance.

## 📁 Directory Structure

```
devops/
├── README.md              # This file
├── devops.sh              # Main DevOps management script
├── scripts/               # Individual script files
│   ├── build.sh           # Build automation script
│   ├── deploy.sh          # Deployment script
│   ├── git-update.sh      # Git operations script
│   └── monitor.sh         # Monitoring and health checks
├── configs/               # Configuration files
├── deployments/           # Deployment configurations
└── monitoring/            # Monitoring configurations
```

## 🚀 Quick Start

### Main DevOps Script

Use the main `devops.sh` script to access all DevOps operations:

```bash
# Show all available commands
./devops.sh help

# Show project information
./devops.sh info

# Build everything
./devops.sh build

# Deploy services
./devops.sh deploy

# Monitor services
./devops.sh monitor

# Update git repository
./devops.sh git-update
```

## 📋 Available Scripts

### 1. Build Script (`scripts/build.sh`)

Handles building of all platform components.

```bash
# Build everything
./devops/scripts/build.sh --all

# Build frontend only
./devops/scripts/build.sh --frontend

# Build backend only
./devops/scripts/build.sh --backend

# Build Docker images only
./devops/scripts/build.sh --docker

# Clean and build
./devops/scripts/build.sh --clean --all

# Run tests
./devops/scripts/build.sh --test
```

**Features:**
- Frontend build with npm
- Backend build with Python virtual environment
- Docker image building
- Linting and code quality checks
- Automated testing
- Build artifact cleanup

### 2. Deployment Script (`scripts/deploy.sh`)

Manages deployment of the platform services.

```bash
# Standard deployment
./devops/scripts/deploy.sh

# Rebuild and deploy
./devops/scripts/deploy.sh --rebuild

# Deploy and verify
./devops/scripts/deploy.sh --verify

# Show deployment status
./devops/scripts/deploy.sh --status

# Show logs
./devops/scripts/deploy.sh --logs

# Rollback deployment
./devops/scripts/deploy.sh --rollback
```

**Features:**
- Prerequisites checking
- Port conflict detection
- Service deployment with Docker Compose
- Health verification
- Rollback capabilities
- Status monitoring

### 3. Git Update Script (`scripts/git-update.sh`)

Handles Git operations and GitHub synchronization.

```bash
# Auto-commit and push to dev
./devops/scripts/git-update.sh

# Commit with custom message
./devops/scripts/git-update.sh -m "Fix API bug"

# Push to specific branch
./devops/scripts/git-update.sh -b main

# Push and create pull request
./devops/scripts/git-update.sh --create-pr

# Show repository information
./devops/scripts/git-update.sh --info
```

**Features:**
- Automatic change detection
- Custom commit messages
- Multi-branch support
- Pull request creation
- Repository information display
- Confirmation prompts

### 4. Monitoring Script (`scripts/monitor.sh`)

Provides comprehensive monitoring and health checks.

```bash
# Run all checks
./devops/scripts/monitor.sh --all

# Check specific components
./devops/scripts/monitor.sh --api --external

# Monitor continuously
./devops/scripts/monitor.sh --monitor 60

# Show service logs
./devops/scripts/monitor.sh --logs api --lines 20

# Generate monitoring report
./devops/scripts/monitor.sh --report report.txt

# Show service URLs
./devops/scripts/monitor.sh --urls
```

**Features:**
- Container status monitoring
- API health checks
- External service verification
- Database connectivity checks
- Resource usage monitoring
- Continuous monitoring loops
- Report generation
- Service log viewing

## 🛠️ Common Workflows

### Daily Development Workflow

```bash
# 1. Check project status
./devops.sh status

# 2. Build and test changes
./devops.sh build --test

# 3. Deploy changes
./devops.sh deploy --verify

# 4. Commit and push changes
./devops.sh git-update -m "Daily updates"
```

### Emergency Recovery Workflow

```bash
# 1. Check what's broken
./devops.sh monitor --all

# 2. Rollback if needed
./devops.sh rollback

# 3. Clean and rebuild
./devops.sh rebuild

# 4. Verify everything is working
./devops.sh status
```

### Production Deployment Workflow

```bash
# 1. Clean build
./devops/scripts/build.sh --clean --all

# 2. Run tests
./devops/scripts/build.sh --test

# 3. Deploy with verification
./devops/scripts/deploy.sh --rebuild --verify

# 4. Monitor deployment
./devops/scripts/monitor.sh --monitor 30

# 5. Create pull request
./devops/scripts/git-update.sh --create-pr
```

## 📊 Monitoring and Health Checks

### Service Endpoints

- **Frontend**: http://localhost:5173
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs
- **Grafana**: http://localhost:3002 (admin/admin)
- **Prometheus**: http://localhost:9092
- **Qdrant**: http://localhost:6333
- **Langfuse**: http://localhost:3000
- **MinIO**: http://localhost:9003 (minioadmin/minioadmin)

### Health Check Commands

```bash
# API health
curl http://localhost:8000/health

# Container status
docker-compose ps

# Service logs
docker-compose logs --tail=50

# Resource usage
docker stats --no-stream
```

## 🔧 Configuration

### Environment Variables

Key environment variables used by the scripts:

- `REPO_NAME`: GitHub repository name
- `GITHUB_USER`: GitHub username
- `DEFAULT_BRANCH`: Default branch for git operations
- `API_URL`: API endpoint URL
- `FRONTEND_URL`: Frontend endpoint URL

### Script Configuration

Scripts can be configured by modifying the variables at the top of each script file:

```bash
# Example: scripts/git-update.sh
REPO_NAME="poc-platform"
GITHUB_USER="gokhul"
DEFAULT_BRANCH="dev"
```

## 🚨 Troubleshooting

### Common Issues

1. **Script Permission Errors**
   ```bash
   chmod +x devops/scripts/*.sh
   chmod +x devops/devops.sh
   ```

2. **Docker Not Running**
   ```bash
   # Start Docker Desktop
   open -a Docker
   ```

3. **Port Conflicts**
   ```bash
   # Check for port conflicts
   lsof -i :8000 -i :5173 -i :54321
   
   # Kill conflicting processes
   sudo lsof -ti:8000 | xargs kill -9
   ```

4. **Git Authentication Issues**
   ```bash
   # Check git configuration
   git config --list
   
   # Set up authentication
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### Getting Help

- Use `--help` flag with any script for detailed usage information
- Check the main troubleshooting guide: `docs/troubleshooting.md`
- Review script logs for detailed error messages

## 📝 Best Practices

1. **Always verify deployments** using the monitoring scripts
2. **Use meaningful commit messages** when pushing changes
3. **Test changes locally** before deploying to production
4. **Monitor resource usage** regularly
5. **Keep scripts updated** with the latest configurations
6. **Use version control** for all script changes
7. **Document custom configurations** for team members

## 🔄 Updates and Maintenance

- Scripts are version controlled with the main project
- Update scripts when adding new services or changing configurations
- Test scripts after any infrastructure changes
- Keep dependencies updated (Docker, Node.js, Python, etc.)

---

**Last Updated**: October 2024  
**Version**: 1.0.0  
**Maintained by**: Development Team
