# LLM Platform - Troubleshooting Guide

## Table of Contents
1. [Common Issues](#common-issues)
2. [Docker Issues](#docker-issues)
3. [Frontend Issues](#frontend-issues)
4. [Backend Issues](#backend-issues)
5. [Database Issues](#database-issues)
6. [Port Conflicts](#port-conflicts)
7. [Network Issues](#network-issues)
8. [Performance Issues](#performance-issues)
9. [Complete Rebuild Guide](#complete-rebuild-guide)

## Common Issues

### Application Won't Start
**Symptoms**: Docker containers fail to start or exit immediately
**Solutions**:
```bash
# Check Docker is running
docker --version

# Check available ports
lsof -i :8000 -i :5173 -i :54321 -i :6380 -i :6333

# Clean up and restart
docker-compose down
docker system prune -f
docker-compose up --build -d
```

### Port Already in Use
**Symptoms**: `address already in use` errors
**Solutions**:
```bash
# Find what's using the port
lsof -i :PORT_NUMBER

# Kill the process
kill -9 PID_NUMBER

# Or change ports in docker-compose.yml
```

## Docker Issues

### Container Build Failures
**Symptoms**: `unable to get image` or build errors
**Solutions**:
```bash
# Remove all containers and images
docker-compose down --volumes --remove-orphans
docker system prune -a -f

# Restart Docker Desktop
killall Docker
open -a Docker

# Wait for Docker to start, then rebuild
sleep 10
docker-compose up --build -d
```

### Image Corruption
**Symptoms**: `blob sha256 expected at` errors
**Solutions**:
```bash
# Complete Docker reset
docker system prune -a -f --volumes
docker builder prune -a -f

# Restart Docker Desktop
# On macOS:
killall Docker
open -a Docker

# Wait and rebuild
sleep 15
docker-compose up --build -d
```

### Permission Issues
**Symptoms**: Permission denied errors in containers
**Solutions**:
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod -R 755 .

# Rebuild with proper permissions
docker-compose up --build -d
```

## Frontend Issues

### Tailwind CSS Errors
**Symptoms**: `[plugin:vite:css] [postcss] EIO: i/o error`
**Solutions**:
```bash
# Run frontend locally to test
cd frontend
npm install
npm run dev

# If successful, the issue is Docker-related
# Check tailwind.config.js for missing plugins
# Ensure all dependencies are in package.json
```

### Proxy Errors
**Symptoms**: `Error: getaddrinfo ENOTFOUND api`
**Solutions**:
```bash
# Frontend can't reach backend API
# Ensure backend container is running
docker-compose ps

# Check API health
curl http://localhost:8000/health

# If running frontend locally, update vite.config.ts proxy:
# Change target from 'http://api:8000' to 'http://localhost:8000'
```

### Build Failures
**Symptoms**: `npm install` or build errors
**Solutions**:
```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# For Docker builds, ensure Dockerfile has proper cache layers
```

## Backend Issues

### Database Connection Errors
**Symptoms**: `connection refused` to PostgreSQL
**Solutions**:
```bash
# Check if database is running
docker-compose ps postgres

# Check database logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres

# Wait for database to be ready
sleep 10
docker-compose up api
```

### API Not Responding
**Symptoms**: 500 errors or timeouts
**Solutions**:
```bash
# Check API logs
docker-compose logs api

# Check API health
curl http://localhost:8000/health

# Restart API service
docker-compose restart api

# Check environment variables
docker-compose exec api env | grep DATABASE
```

### Import/Module Errors
**Symptoms**: Python import errors
**Solutions**:
```bash
# Check if all dependencies are installed
docker-compose exec api pip list

# Reinstall requirements
docker-compose exec api pip install -r requirements.txt

# Rebuild container
docker-compose up --build api -d
```

## Database Issues

### PostgreSQL Connection Issues
**Symptoms**: Database connection timeouts
**Solutions**:
```bash
# Check database status
docker-compose exec postgres pg_isready -U llmuser -d llmplatform

# Check database logs
docker-compose logs postgres

# Reset database (WARNING: This will delete data)
docker-compose down
docker volume rm agentic_postgres_data
docker-compose up postgres -d
```

### Redis Connection Issues
**Symptoms**: Redis connection errors
**Solutions**:
```bash
# Check Redis status
docker-compose exec redis redis-cli ping

# Restart Redis
docker-compose restart redis

# Check Redis logs
docker-compose logs redis
```

### Qdrant Issues
**Symptoms**: Vector database errors
**Solutions**:
```bash
# Check Qdrant status
curl http://localhost:6333/health

# Restart Qdrant
docker-compose restart qdrant

# Check Qdrant logs
docker-compose logs qdrant
```

## Port Conflicts

### Common Port Conflicts
**Default Ports**:
- Frontend: 5173
- Backend API: 8000
- PostgreSQL: 54321
- Redis: 6380
- Qdrant: 6333-6334
- Prometheus: 9092
- Grafana: 3002
- MinIO: 9002-9003
- Langfuse: 3000

**Solutions**:
```bash
# Check what's using ports
lsof -i :8000 -i :5173 -i :54321

# Kill processes using ports
sudo lsof -ti:8000 | xargs kill -9

# Or modify docker-compose.yml to use different ports
```

## Network Issues

### Container Communication
**Symptoms**: Services can't reach each other
**Solutions**:
```bash
# Check network
docker network ls
docker network inspect agentic_llm-platform

# Recreate network
docker-compose down
docker network prune -f
docker-compose up -d
```

### DNS Resolution Issues
**Symptoms**: `getaddrinfo ENOTFOUND` errors
**Solutions**:
```bash
# Check container DNS
docker-compose exec api nslookup postgres

# Restart containers
docker-compose restart

# Check /etc/hosts if running locally
```

## Performance Issues

### Slow Startup
**Symptoms**: Containers take long time to start
**Solutions**:
```bash
# Check system resources
docker stats

# Increase Docker memory allocation
# In Docker Desktop: Settings > Resources > Memory

# Use multi-stage builds for smaller images
```

### Memory Issues
**Symptoms**: Containers killed or out of memory
**Solutions**:
```bash
# Check memory usage
docker stats

# Increase Docker memory limit
# Restart Docker Desktop with more memory allocated

# Optimize container resource usage
```

## Complete Rebuild Guide

### Prerequisites Check
Before rebuilding, ensure you have:
- Docker Desktop 4.0+ installed and running
- At least 8GB RAM available
- 10GB free disk space
- Ports 8000, 5173, 54321, 6380, 6333, 6334, 9092, 3002, 9002, 9003, 3000 available

### Quick Rebuild (When Things Are Mostly Working)
```bash
# 1. Stop all services
docker-compose down

# 2. Rebuild and start
docker-compose up --build -d

# 3. Verify services
docker-compose ps
curl http://localhost:8000/health
```

### Complete Clean Rebuild (When Everything Goes Wrong)
```bash
# 1. Stop everything and remove volumes
docker-compose down --volumes --remove-orphans

# 2. Clean Docker completely (removes all images, containers, networks)
docker system prune -a -f --volumes
docker builder prune -a -f

# 3. Restart Docker Desktop (macOS)
killall Docker
open -a Docker

# 4. Wait for Docker to fully start
sleep 15

# 5. Verify Docker is working
docker --version
docker info

# 6. Check for port conflicts
lsof -i :8000 -i :5173 -i :54321 -i :6380 -i :6333 -i :6334 -i :9092 -i :3002 -i :9002 -i :9003 -i :3000

# 7. Kill any conflicting processes (if needed)
sudo lsof -ti:8000 | xargs kill -9
sudo lsof -ti:5173 | xargs kill -9
sudo lsof -ti:54321 | xargs kill -9

# 8. Navigate to project directory
cd /path/to/your/agentic/project

# 9. Rebuild everything from scratch
docker-compose up --build -d

# 10. Wait for services to start (30-60 seconds)
sleep 30

# 11. Check all services are running
docker-compose ps

# 12. Test all endpoints
curl http://localhost:8000/health
curl http://localhost:5173
curl http://localhost:6333/health
curl http://localhost:3002

# 13. Check logs if any service failed
docker-compose logs api
docker-compose logs frontend
docker-compose logs postgres
```

### Emergency Recovery (Docker Corruption)
If Docker images are corrupted:
```bash
# 1. Complete Docker reset
docker-compose down --volumes --remove-orphans
docker system prune -a -f --volumes --force
docker builder prune -a -f --force

# 2. Restart Docker Desktop completely
# On macOS: Quit Docker Desktop from menu bar, then restart
killall Docker
sleep 5
open -a Docker

# 3. Wait for Docker to initialize
sleep 20

# 4. Verify Docker is healthy
docker run hello-world

# 5. Rebuild with fresh images
docker-compose build --no-cache
docker-compose up -d

# 6. Monitor startup
docker-compose logs -f
```

### Alternative: Hybrid Setup (Frontend Local + Backend Docker)
If Docker issues persist with frontend:
```bash
# 1. Start only backend services
docker-compose up postgres redis qdrant api prometheus grafana minio langfuse -d

# 2. Wait for backend to be ready
sleep 30

# 3. Test backend
curl http://localhost:8000/health

# 4. Run frontend locally
cd frontend
npm install
npm run dev

# 5. Update vite.config.ts proxy (if needed)
# Change target from 'http://api:8000' to 'http://localhost:8000'
```

### Network Reset (If Containers Can't Communicate)
```bash
# 1. Stop all services
docker-compose down

# 2. Remove networks
docker network prune -f

# 3. Remove volumes (WARNING: This deletes data)
docker volume prune -f

# 4. Restart Docker Desktop
killall Docker
open -a Docker
sleep 15

# 5. Rebuild with fresh network
docker-compose up --build -d
```

### Database Recovery (If Database is Corrupted)
```bash
# 1. Stop services
docker-compose down

# 2. Remove database volume (WARNING: This deletes all data)
docker volume rm agentic_postgres_data

# 3. Restart database
docker-compose up postgres -d

# 4. Wait for database to initialize
sleep 30

# 5. Start other services
docker-compose up -d
```

### Verification Checklist
After rebuild, verify:
- [ ] All containers are running: `docker-compose ps`
- [ ] API health check passes: `curl http://localhost:8000/health`
- [ ] Frontend loads: `curl http://localhost:5173`
- [ ] Database is accessible: `docker-compose exec postgres pg_isready`
- [ ] Redis is accessible: `docker-compose exec redis redis-cli ping`
- [ ] Qdrant is accessible: `curl http://localhost:6333/health`
- [ ] Grafana is accessible: `curl http://localhost:3002`
- [ ] No error logs: `docker-compose logs --tail=50`

### Alternative: Run Frontend Locally
If Docker issues persist, run frontend locally:

```bash
# 1. Start only backend services
docker-compose up postgres redis qdrant api -d

# 2. Run frontend locally
cd frontend
npm install
npm run dev

# 3. Update vite.config.ts proxy target to 'http://localhost:8000'
```

## Getting Help

### Logs to Check
```bash
# Application logs
docker-compose logs api
docker-compose logs frontend
docker-compose logs postgres

# System logs
docker-compose logs
docker system events
```

### Useful Commands
```bash
# Check container status
docker-compose ps

# Check resource usage
docker stats

# Check network connectivity
docker-compose exec api ping postgres

# Check environment variables
docker-compose exec api env

# Access container shell
docker-compose exec api bash
docker-compose exec postgres psql -U llmuser -d llmplatform
```

### Health Checks
```bash
# API health
curl http://localhost:8000/health

# Frontend
curl http://localhost:5173

# Database
curl http://localhost:54321

# Redis
docker-compose exec redis redis-cli ping

# Qdrant
curl http://localhost:6333/health
```

## Prevention Tips

1. **Regular Cleanup**: Run `docker system prune` weekly
2. **Port Management**: Keep track of which ports you're using
3. **Resource Monitoring**: Monitor Docker memory usage
4. **Backup Data**: Regularly backup important volumes
5. **Update Dependencies**: Keep Docker and dependencies updated
6. **Use .dockerignore**: Optimize build context
7. **Multi-stage Builds**: Reduce final image sizes
8. **Health Checks**: Implement proper health checks in containers

---

**Last Updated**: October 2024
**Version**: 1.0.0
