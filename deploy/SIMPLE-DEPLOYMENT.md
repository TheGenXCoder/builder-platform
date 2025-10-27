# Simple Deployment Guide for Catalyst9

## Overview

This is the **simple, straightforward** approach to deploying Catalyst9 using Docker Swarm - no Kubernetes complexity needed!

## Why Docker Swarm?

- ✅ **Built into Docker** - No extra tools to install
- ✅ **Open source** - No licensing concerns
- ✅ **Works on Mac** - Runs natively on dev-mini
- ✅ **Simple** - Much easier than Kubernetes
- ✅ **Production ready** - Used by many companies
- ✅ **External drive support** - Uses your Extreme Pro SSD

## 🚀 Quick Start

### 1. Setup Docker Swarm (One Time)

```bash
cd deploy/swarm
chmod +x *.sh
./setup-docker-swarm.sh
```

This creates a single-node swarm on dev-mini with your external drive.

### 2. Deploy Catalyst9

```bash
./deploy-stack.sh
```

That's it! Your entire stack is now running.

## 📁 What Gets Deployed?

The stack includes:
- **PostgreSQL 17** with pgvector
- **Redis** for caching
- **Ollama** for AI embeddings
- **Catalyst9 API** (2 replicas for high availability)
- **Nginx** for SSL/proxy

All data is stored on your external drive at:
```
/Volumes/Extreme Pro/docker-swarm/
├── volumes/
│   ├── postgres/
│   ├── redis/
│   └── ollama/
└── configs/
```

## 🔧 Management Commands

### Basic Operations

```bash
# View all services
docker service ls

# View specific service
docker service ps catalyst9_catalyst9-api

# View logs
docker service logs -f catalyst9_catalyst9-api

# Scale services
docker service scale catalyst9_catalyst9-api=5

# Update service (new image)
docker service update --image catalyst9/api:v2 catalyst9_catalyst9-api
```

### Stack Management

```bash
# Deploy/update stack
docker stack deploy -c docker-stack.yml catalyst9

# List stacks
docker stack ls

# Remove stack (stops everything)
docker stack rm catalyst9

# Leave swarm (reset everything)
docker swarm leave --force
```

## 🌐 DNS & Access

Your services are available at:
- **Local**: http://localhost
- **API**: http://localhost:8080
- **HTTPS**: https://localhost (if SSL configured)

With your Cloudflare DNS setup:
- **Production**: https://catalyst9.ai
- **API**: https://api.catalyst9.ai

## 📊 Monitoring

### Check Health

```bash
# Service health
curl http://localhost:8080/health

# View resource usage
docker stats

# Check disk usage
df -h "/Volumes/Extreme Pro"
```

### View Logs

```bash
# All logs for a service
docker service logs catalyst9_catalyst9-api

# Follow logs
docker service logs -f catalyst9_catalyst9-api

# Last 100 lines
docker service logs --tail 100 catalyst9_catalyst9-api
```

## 🔄 Updates & Rollbacks

### Rolling Update

```bash
# Build new image
docker build -t catalyst9/api:v2 .

# Update service (zero downtime)
docker service update --image catalyst9/api:v2 catalyst9_catalyst9-api
```

### Rollback

```bash
# Rollback to previous version
docker service rollback catalyst9_catalyst9-api
```

## 🛠️ Troubleshooting

### Service Not Starting

```bash
# Check service status
docker service ps catalyst9_catalyst9-api

# View error details
docker service ps catalyst9_catalyst9-api --no-trunc

# Check logs
docker service logs catalyst9_catalyst9-api
```

### Clean Restart

```bash
# Remove everything and start fresh
docker stack rm catalyst9
docker system prune -a
./deploy-stack.sh
```

## 🎯 Production on dev-mini

To run this in "production" on dev-mini:

1. **Ensure Docker starts on boot**:
   ```bash
   # macOS
   # Docker Desktop: Enable "Start Docker Desktop when you log in"
   # In Docker Desktop preferences
   ```

2. **Setup automatic restart**:
   ```bash
   # Services already have restart policies in docker-stack.yml
   # They'll restart automatically if they crash
   ```

3. **Monitor with your DDNS**:
   - Your Dynamic DNS is already updating Cloudflare
   - Access via https://catalyst9.ai once DNS propagates

## 🔐 Security Notes

- Secrets are managed by Docker Swarm (encrypted at rest)
- SSL certificates are loaded from `~/.credentials/.catalyst9.ai/`
- Database passwords are auto-generated
- All internal communication is encrypted (overlay network)

## 📈 Scaling

```bash
# Scale API horizontally
docker service scale catalyst9_catalyst9-api=5

# Add more nodes (optional)
# On another machine:
docker swarm join --token <worker-token> <manager-ip>:2377
```

## 🎉 That's It!

Much simpler than Kubernetes, right? Docker Swarm gives you:
- Production-grade orchestration
- Built-in load balancing
- Automatic restarts
- Rolling updates
- Secret management
- Persistent storage on your external drive

All without the complexity of k8s!

## Commands Cheat Sheet

```bash
# Deploy
./setup-docker-swarm.sh  # One time
./deploy-stack.sh         # Deploy app

# Manage
docker service ls         # List services
docker service logs NAME  # View logs
docker service scale NAME=N  # Scale

# Update
docker build -t catalyst9/api:new .
docker service update --image catalyst9/api:new catalyst9_catalyst9-api

# Remove
docker stack rm catalyst9
docker swarm leave --force  # Full reset
```