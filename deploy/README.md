# Catalyst9 Docker & Kubernetes Deployment Guide

## Overview

Catalyst9 can be deployed using Docker for local development or Kubernetes (k3s/k8s) for production environments. This guide covers both deployment methods.

## Prerequisites

- Docker & Docker Compose (for local development)
- kubectl (for Kubernetes deployment)
- SSL certificates (stored in `~/.credentials/.catalyst9.ai/`)
- 8GB+ RAM recommended for running all services

## Quick Start

### Local Development with Docker Compose

```bash
# Clone the repository
git clone https://github.com/catalyst9/catalyst-core
cd catalyst9/catalyst-core

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access the services
# API: http://localhost:8080
# pgAdmin: http://localhost:5050 (admin@catalyst9.ai / admin)
```

### Production Deployment with k3s

```bash
# Make scripts executable
chmod +x deploy/*.sh

# Build Docker image
./deploy/docker-build.sh --push --tag v0.9.0

# Deploy to k3s (local)
./deploy/deploy-k3s.sh --local

# Deploy to remote server (e.g., dev-mini)
./deploy/deploy-k3s.sh --server dev-mini
```

## Architecture

### Services

1. **PostgreSQL 17** (with pgvector)
   - Vector similarity search for knowledge graph
   - Persistent storage for all data

2. **Redis**
   - Session management
   - Caching layer
   - Rate limiting

3. **Ollama**
   - Local LLM inference
   - Embedding generation (nomic-embed-text)
   - Models: llama3, codellama

4. **Catalyst9 API**
   - Go-based REST API
   - WebSocket support for streaming
   - Knowledge graph operations

5. **NGINX** (optional)
   - SSL termination
   - Load balancing
   - Static file serving

## Docker Deployment

### Directory Structure

```
catalyst-core/
├── Dockerfile              # API container definition
├── docker-compose.yml      # Local development stack
├── deploy/
│   ├── docker-build.sh    # Build script
│   ├── deploy-k3s.sh      # k3s deployment script
│   ├── sql/
│   │   └── init.sql       # Database initialization
│   ├── nginx/
│   │   ├── catalyst9.conf        # Production nginx
│   │   └── catalyst9-docker.conf # Docker nginx
│   └── k3s/               # Kubernetes manifests
│       ├── namespace.yaml
│       ├── postgres.yaml
│       ├── redis.yaml
│       ├── ollama.yaml
│       ├── catalyst9-api.yaml
│       └── ingress.yaml
```

### Building Images

```bash
# Build locally
docker build -t catalyst9/api:latest .

# Build with script (includes tagging)
./deploy/docker-build.sh

# Build and push to registry
./deploy/docker-build.sh --push --registry docker.io --namespace catalyst9
```

### Environment Variables

Create a `.env` file for local development:

```env
# Database
DB_HOST=postgres
DB_NAME=catalyst9
DB_USER=catalyst9
DB_PASSWORD=catalyst9_dev

# Redis
REDIS_HOST=redis:6379

# Security
JWT_SECRET=development_jwt_secret

# Ollama
OLLAMA_HOST=http://ollama:11434

# API
PORT=8080
```

### Docker Compose Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Rebuild after code changes
docker-compose up -d --build catalyst9-api

# Reset everything (including volumes)
docker-compose down -v

# Scale API instances
docker-compose up -d --scale catalyst9-api=3
```

## Kubernetes Deployment (k3s)

### Prerequisites

- k3s installed (or any Kubernetes cluster)
- kubectl configured
- Storage class available (local-path for k3s)

### Deployment Steps

1. **Create Namespace**
```bash
kubectl apply -f deploy/k3s/namespace.yaml
```

2. **Update SSL Certificates**
```bash
kubectl create secret tls catalyst9-tls \
  --cert=~/.credentials/.catalyst9.ai/fullchain.pem \
  --key=~/.credentials/.catalyst9.ai/privkey.pem \
  -n catalyst9
```

3. **Deploy Services**
```bash
# Deploy all services
kubectl apply -f deploy/k3s/

# Or deploy individually
kubectl apply -f deploy/k3s/postgres.yaml
kubectl apply -f deploy/k3s/redis.yaml
kubectl apply -f deploy/k3s/ollama.yaml
kubectl apply -f deploy/k3s/catalyst9-api.yaml
kubectl apply -f deploy/k3s/ingress.yaml
```

4. **Verify Deployment**
```bash
# Check pod status
kubectl get pods -n catalyst9

# Check services
kubectl get svc -n catalyst9

# View logs
kubectl logs -f deployment/catalyst9-api -n catalyst9
```

### k3s on Remote Server

```bash
# Install k3s on remote server
ssh dev-mini
curl -sfL https://get.k3s.io | sh -

# Get kubeconfig locally
scp dev-mini:/etc/rancher/k3s/k3s.yaml ~/.kube/config-dev-mini

# Deploy using script
./deploy/deploy-k3s.sh --server dev-mini
```

## SSL/TLS Configuration

### Local Development

For local HTTPS testing, create self-signed certificates:

```bash
# Create self-signed cert for local dev
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout catalyst9-local.key \
  -out catalyst9-local.crt \
  -subj "/CN=localhost"
```

### Production

Place your SSL certificates in `~/.credentials/.catalyst9.ai/`:
- `fullchain.pem` - Full certificate chain
- `privkey.pem` - Private key

## Monitoring & Maintenance

### Health Checks

```bash
# API health
curl http://localhost:8080/health

# PostgreSQL
docker-compose exec postgres pg_isready

# Redis
docker-compose exec redis redis-cli ping

# Ollama
curl http://localhost:11434/
```

### Logs

```bash
# Docker Compose
docker-compose logs -f catalyst9-api

# Kubernetes
kubectl logs -f deployment/catalyst9-api -n catalyst9

# All pods in namespace
kubectl logs -f -n catalyst9 --all-containers=true
```

### Database Management

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U catalyst9

# Backup database
docker-compose exec postgres pg_dump -U catalyst9 catalyst9 > backup.sql

# Restore database
docker-compose exec -T postgres psql -U catalyst9 catalyst9 < backup.sql
```

### Scaling

```bash
# Docker Compose
docker-compose up -d --scale catalyst9-api=3

# Kubernetes
kubectl scale deployment catalyst9-api --replicas=5 -n catalyst9

# Or use HPA (Horizontal Pod Autoscaler)
kubectl apply -f deploy/k3s/catalyst9-api.yaml  # HPA included
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
```bash
# Find process using port
lsof -i :8080
# Kill process or change port in docker-compose.yml
```

2. **Permission Denied (Docker)**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

3. **Ollama Models Not Loading**
```bash
# Manually pull models
docker-compose exec ollama ollama pull nomic-embed-text
docker-compose exec ollama ollama pull llama3
```

4. **Database Connection Issues**
```bash
# Check PostgreSQL logs
docker-compose logs postgres
# Verify connection
docker-compose exec postgres pg_isready
```

5. **k3s Ingress Not Working**
```bash
# Check Traefik (k3s ingress controller)
kubectl logs -n kube-system deployment/traefik

# Verify ingress
kubectl describe ingress catalyst9-ingress -n catalyst9
```

### Debug Commands

```bash
# Enter container shell
docker-compose exec catalyst9-api sh

# Check environment variables
docker-compose exec catalyst9-api env

# Test internal connectivity
docker-compose exec catalyst9-api ping postgres

# Kubernetes pod shell
kubectl exec -it deployment/catalyst9-api -n catalyst9 -- sh

# Get pod events
kubectl describe pod -n catalyst9
```

## Performance Tuning

### PostgreSQL

```sql
-- Tune for pgvector performance
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET work_mem = '32MB';
SELECT pg_reload_conf();
```

### Resource Limits

Adjust in `docker-compose.yml` or k8s manifests:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Security Considerations

1. **Change Default Passwords**
   - Update all passwords in production
   - Use secrets management (Kubernetes secrets, Docker secrets)

2. **Network Policies**
   - Implement Kubernetes NetworkPolicies
   - Use Docker networks for isolation

3. **SSL/TLS**
   - Always use HTTPS in production
   - Keep certificates updated

4. **Rate Limiting**
   - Configure in NGINX or API
   - Use Redis for distributed rate limiting

## Support

- GitHub Issues: https://github.com/catalyst9/catalyst-core/issues
- Documentation: https://docs.catalyst9.ai
- Email: support@catalyst9.ai

---

Built with ❤️ by Catalyst9 Team