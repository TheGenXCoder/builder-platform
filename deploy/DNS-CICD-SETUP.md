# Catalyst9 DNS & CI/CD Setup Guide

## Overview

This guide covers setting up DNS management with Cloudflare, dynamic DNS for self-hosted environments, and a portable CI/CD pipeline that works with multiple platforms.

## Prerequisites

- Cloudflare account with catalyst9.ai domain
- DNS API token with limited permissions (stored in `~/.credentials/.cloudflare/dns-api-token`)
- Docker installed locally
- kubectl configured (for k3s deployment)
- SSH access to dev-mini server

## 🌐 DNS Configuration

### 1. Cloudflare Setup

#### Generate API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Custom token" template
4. Set permissions:
   - **Zone** → DNS → Edit
   - **Zone** → Zone → Read
5. Scope to: Include → Specific zone → catalyst9.ai
6. Save token to `~/.credentials/.cloudflare/dns-api-token`:

```bash
mkdir -p ~/.credentials/.cloudflare
echo "YOUR_TOKEN_HERE" > ~/.credentials/.cloudflare/dns-api-token
chmod 600 ~/.credentials/.cloudflare/dns-api-token
```

#### Initial DNS Setup

```bash
cd /Users/BertSmith/personal/catalyst9/catalyst-core/deploy/dns

# Make scripts executable
chmod +x *.sh

# Run initial DNS setup
./cloudflare-setup.sh
```

This creates:
- A record for catalyst9.ai
- A record for www.catalyst9.ai
- A record for api.catalyst9.ai
- A record for docs.catalyst9.ai

### 2. Dynamic DNS Configuration

Since you're self-hosting without a static IP, we need dynamic DNS updates:

#### Local Setup (on your Mac)

```bash
# Test the DDNS updater
./ddns-updater.sh --once

# Check current IP
cat ~/.catalyst9-current-ip
```

#### Remote Setup (on dev-mini)

```bash
# Deploy DDNS to dev-mini
./setup-ddns.sh --remote dev-mini

# Or SSH and run locally on dev-mini
ssh dev-mini
cd /opt/catalyst9/deploy/dns
sudo ./setup-ddns.sh --local
```

#### Systemd Service Management

```bash
# On dev-mini server
# Check service status
sudo systemctl status catalyst9-ddns

# View logs
sudo journalctl -u catalyst9-ddns -f

# Restart service
sudo systemctl restart catalyst9-ddns

# Stop service (if needed)
sudo systemctl stop catalyst9-ddns
```

The DDNS service will:
- Check your public IP every 5 minutes
- Update Cloudflare DNS if IP changes
- Log all activities to `/var/log/catalyst9-ddns.log`

### 3. Manual DNS Operations

```bash
# Force DNS update
./ddns-updater.sh --once

# Check DNS propagation
nslookup catalyst9.ai
dig catalyst9.ai @8.8.8.8

# Verify all subdomains
for domain in catalyst9.ai www.catalyst9.ai api.catalyst9.ai docs.catalyst9.ai; do
    echo "Checking $domain:"
    nslookup $domain
done
```

## 🚀 CI/CD Pipeline

### GitHub Actions (Current)

The pipeline is configured in `.github/workflows/deploy.yml` with these stages:

1. **Test** - Run Go tests
2. **Build** - Build multi-arch Docker images
3. **Push** - Push to Docker Hub
4. **Deploy** - Deploy to k3s cluster
5. **Verify** - Health check deployment
6. **Notify** - Send status notifications

#### Required GitHub Secrets

Set these in your repository settings:

```yaml
# Docker Hub
DOCKER_USERNAME: your-dockerhub-username
DOCKER_PASSWORD: your-dockerhub-token

# SSH Deployment
SSH_PRIVATE_KEY: (contents of ~/.ssh/id_rsa)
SSH_HOST: dev-mini
SSH_KNOWN_HOSTS: (output of: ssh-keyscan dev-mini)

# Kubernetes
KUBECONFIG: (base64 encoded kubeconfig)
  # Generate with: cat ~/.kube/config | base64

# Optional
SLACK_WEBHOOK: your-slack-webhook-url
```

#### Triggering Deployments

```bash
# Deploy on push to main
git push origin main

# Deploy on tag
git tag v1.0.0
git push origin v1.0.0

# Manual deployment via GitHub UI
# Go to Actions → Deploy Catalyst9 → Run workflow
```

### Portable CI/CD Script

For flexibility and easy migration away from GitHub:

```bash
cd deploy/ci

# Run full pipeline locally
./portable-deploy.sh all

# Individual stages
./portable-deploy.sh test
./portable-deploy.sh build --tag v1.0.0
./portable-deploy.sh deploy --tag v1.0.0

# Skip stages
./portable-deploy.sh all --skip-tests --skip-deploy
```

#### Environment Variables

```bash
# Docker Registry
export DOCKER_REGISTRY=docker.io
export DOCKER_USERNAME=your-username
export DOCKER_PASSWORD=your-password

# Deployment
export DEPLOY_SERVER=dev-mini
export SSH_KEY="$(cat ~/.ssh/id_rsa)"
export KUBECONFIG_CONTENT="$(cat ~/.kube/config | base64)"

# Run deployment
./portable-deploy.sh all
```

#### Integration with Other CI Platforms

**GitLab CI** (`.gitlab-ci.yml`):
```yaml
deploy:
  script:
    - ./deploy/ci/portable-deploy.sh all
  variables:
    DOCKER_USERNAME: $CI_REGISTRY_USER
    DOCKER_PASSWORD: $CI_REGISTRY_PASSWORD
```

**Jenkins** (`Jenkinsfile`):
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                sh './deploy/ci/portable-deploy.sh all'
            }
        }
    }
}
```

**Drone** (`.drone.yml`):
```yaml
steps:
  - name: deploy
    image: docker:latest
    commands:
      - ./deploy/ci/portable-deploy.sh all
```

## 📋 Quick Start Checklist

### Initial Setup

- [ ] Save Cloudflare DNS API token to `~/.credentials/.cloudflare/dns-api-token`
- [ ] Run `./cloudflare-setup.sh` to configure DNS records
- [ ] Deploy DDNS: `./setup-ddns.sh --remote dev-mini`
- [ ] Verify DNS: `nslookup catalyst9.ai`

### Local Development

- [ ] Start Docker services: `docker-compose up -d`
- [ ] Build image: `./deploy/docker-build.sh`
- [ ] Test locally: `curl http://localhost:8080/health`

### Production Deployment

- [ ] Configure GitHub secrets (or CI environment variables)
- [ ] Push to main branch or create tag
- [ ] Monitor deployment in GitHub Actions
- [ ] Verify production: `curl https://catalyst9.ai/health`

## 🔧 Troubleshooting

### DNS Issues

```bash
# Check current IP
curl -s https://ipv4.icanhazip.com

# Verify Cloudflare token
CF_API_TOKEN=$(cat ~/.credentials/.cloudflare/dns-api-token)
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer $CF_API_TOKEN"

# Force DNS update
ssh dev-mini "/opt/catalyst9/deploy/dns/ddns-updater.sh --once"

# Check DDNS logs
ssh dev-mini "sudo tail -f /var/log/catalyst9-ddns.log"
```

### CI/CD Issues

```bash
# Test Docker build locally
docker build -t catalyst9/api:test .

# Test deployment script
./deploy/ci/portable-deploy.sh build --skip-push

# Check k3s deployment
kubectl get pods -n catalyst9
kubectl logs -n catalyst9 deployment/catalyst9-api

# Manual rollback if needed
kubectl rollout undo deployment/catalyst9-api -n catalyst9
```

### Common Problems

1. **DNS not updating**
   - Check API token permissions
   - Verify Zone ID is correct
   - Check DDNS service logs

2. **Deployment failing**
   - Verify kubeconfig is valid
   - Check SSH keys are correct
   - Ensure dev-mini is accessible

3. **Docker push failing**
   - Login: `docker login`
   - Check credentials in CI secrets
   - Verify registry permissions

## 🔐 Security Notes

1. **Limited Token Permissions**: DNS API token only has DNS edit permissions
2. **Secrets Management**: Never commit tokens or keys to repository
3. **Network Security**: Use SSH keys, not passwords
4. **Container Security**: Run containers as non-root user
5. **SSL/TLS**: Always use HTTPS in production

## 📚 Additional Resources

- [Cloudflare API Documentation](https://developers.cloudflare.com/api)
- [k3s Documentation](https://docs.k3s.io)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub)

## 🚦 Status Monitoring

- **DNS Status**: https://www.whatsmydns.net/#A/catalyst9.ai
- **SSL Status**: https://www.ssllabs.com/ssltest/analyze.html?d=catalyst9.ai
- **Uptime Monitoring**: Configure with your preferred service (UptimeRobot, Pingdom, etc.)

---

**Note**: This setup is designed to be portable and not locked into any specific CI/CD platform. The scripts work with local development, GitHub Actions, and can be easily adapted to GitLab CI, Jenkins, or any other CI/CD system.