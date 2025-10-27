# k3s Setup Guide for dev-mini with External Storage

## Overview

This guide provides instructions for setting up k3s (lightweight Kubernetes) on your dev-mini server using an external SSD drive (Extreme Pro) for optimal performance and storage.

## Why External Storage?

Using your external Extreme Pro SSD provides:
- **Better Performance**: SSDs offer faster I/O for container operations
- **More Space**: Dedicated storage for k3s without affecting system drive
- **Easy Backup**: All k3s data in one location
- **Portability**: Can move the entire k3s setup if needed

## Prerequisites

- dev-mini server accessible via SSH
- External drive (Extreme Pro) connected to dev-mini
- sudo access on dev-mini
- At least 50GB free space on external drive

## 🚀 Quick Installation

### Option 1: Remote Installation (from your Mac)

This is the easiest method - run everything from your local machine:

```bash
cd /Users/BertSmith/personal/catalyst9/catalyst-core/deploy/k3s-setup

# Make scripts executable
chmod +x *.sh

# Run remote installation
./remote-install.sh
```

This script will:
1. Connect to dev-mini via SSH
2. Copy installation scripts
3. Run k3s installation
4. Configure external storage
5. Copy kubeconfig to your local machine

### Option 2: Direct Installation (on dev-mini)

SSH to dev-mini and run directly:

```bash
# SSH to dev-mini
ssh dev-mini

# Copy the setup scripts (from your Mac)
scp /Users/BertSmith/personal/catalyst9/catalyst-core/deploy/k3s-setup/*.sh dev-mini:~/

# On dev-mini, run the installation
cd ~
sudo ./install-k3s-dev-mini.sh
```

## 📁 Storage Setup

The installation automatically configures your Extreme Pro drive:

### Storage Layout
```
/mnt/extreme-pro/           # Mount point for external drive
├── k3s/                    # k3s data directory
│   ├── server/            # k3s server data
│   ├── agent/             # k3s agent data
│   ├── storage/           # Persistent volumes
│   ├── manifests/         # Auto-deployed manifests
│   └── logs/              # k3s logs
```

### Manual Storage Setup (if needed)

If the automatic setup fails, manually configure storage:

```bash
# On dev-mini
sudo ./setup-k3s-storage.sh
```

This will:
- Find your Extreme Pro drive
- Mount it at `/mnt/extreme-pro`
- Create k3s directory structure
- Add to `/etc/fstab` for auto-mounting

## 🔧 Configuration Details

### k3s Configuration

The k3s installation uses these settings:

```yaml
# /etc/rancher/k3s/config.yaml
data-dir: /mnt/extreme-pro/k3s
default-local-storage-path: /mnt/extreme-pro/k3s/storage
write-kubeconfig-mode: "0644"
tls-san:
  - "dev-mini"
  - "catalyst9.ai"
  - "api.catalyst9.ai"
disable:
  - traefik  # Using custom ingress
cluster-init: true
```

### Storage Class

A custom storage class is created:

```yaml
# extreme-pro-storage (default)
provisioner: rancher.io/local-path
path: /mnt/extreme-pro/k3s/storage
```

## 📋 Post-Installation

### 1. Verify Installation

```bash
# From your Mac (after remote-install.sh)
export KUBECONFIG=~/.kube/config-dev-mini

# Check cluster
kubectl cluster-info
kubectl get nodes
kubectl get storageclass
```

### 2. Deploy Catalyst9

```bash
cd /Users/BertSmith/personal/catalyst9/catalyst-core

# Deploy to k3s
./deploy/deploy-k3s.sh --server dev-mini

# Or manually
kubectl apply -f deploy/k3s/
```

### 3. Access Cluster

From your Mac:

```bash
# Use the dev-mini cluster
export KUBECONFIG=~/.kube/config-dev-mini

# Or use helper script (created by remote-install.sh)
source ~/.kube/use-dev-mini.sh
```

## 🔍 Management Commands

### Service Management

```bash
# Check k3s status
ssh dev-mini 'sudo systemctl status k3s'

# Start/Stop/Restart k3s
ssh dev-mini 'sudo systemctl start k3s'
ssh dev-mini 'sudo systemctl stop k3s'
ssh dev-mini 'sudo systemctl restart k3s'

# View logs
ssh dev-mini 'sudo journalctl -u k3s -f'
```

### Storage Management

```bash
# Check disk usage
ssh dev-mini 'df -h /mnt/extreme-pro'

# Check k3s data size
ssh dev-mini 'du -sh /mnt/extreme-pro/k3s'

# Backup k3s data
ssh dev-mini 'k3s-backup.sh'
```

### Cluster Operations

```bash
# Get all pods
kubectl get pods -A

# Get nodes
kubectl get nodes -o wide

# Get persistent volumes
kubectl get pv,pvc -A

# Check cluster events
kubectl get events -A --sort-by='.lastTimestamp'
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Cannot connect to cluster

```bash
# Check if k3s is running
ssh dev-mini 'sudo systemctl status k3s'

# Check firewall (port 6443 must be open)
ssh dev-mini 'sudo ufw allow 6443/tcp'  # If using ufw

# Update kubeconfig
ssh dev-mini 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/config-dev-mini
# Edit ~/.kube/config-dev-mini and replace 127.0.0.1 with dev-mini IP
```

#### 2. External drive not found

```bash
# On dev-mini, check connected drives
lsblk
df -h
mount | grep -i extreme

# If not mounted, mount manually
sudo mkdir -p /mnt/extreme-pro
sudo mount /dev/disk5 /mnt/extreme-pro  # Adjust device as needed
```

#### 3. Storage class not working

```bash
# Check storage class
kubectl get storageclass

# Recreate if needed
kubectl apply -f deploy/k3s/namespace.yaml
```

#### 4. Pods not starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl describe node dev-mini

# Check disk space
ssh dev-mini 'df -h /mnt/extreme-pro'
```

## 🗑️ Uninstall

To completely remove k3s:

```bash
# On dev-mini
sudo k3s-uninstall-custom.sh

# This will:
# - Stop and remove k3s
# - Optionally remove data from external drive
# - Clean up system changes
```

## 💾 Backup & Restore

### Backup

```bash
# Manual backup (on dev-mini)
k3s-backup.sh

# Automated backup via cron
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/k3s-backup.sh
```

### Restore

```bash
# Stop k3s
sudo systemctl stop k3s

# Restore from backup
sudo tar -xzf ~/k3s-backups/k3s-backup-[timestamp].tar.gz -C /mnt/extreme-pro/

# Start k3s
sudo systemctl start k3s
```

## 🔐 Security Notes

1. **Firewall**: Only port 6443 needs to be accessible
2. **Kubeconfig**: Keep `~/.kube/config-dev-mini` secure
3. **Certificates**: k3s auto-generates certificates, valid for 1 year
4. **Network**: Consider using VPN for remote access

## 📊 Monitoring

### Resource Usage

```bash
# Install metrics server (included in setup)
kubectl top nodes
kubectl top pods -A

# Check k3s resource usage
ssh dev-mini 'top -b -n 1 | grep k3s'
```

### Disk Usage

```bash
# Monitor disk usage
watch -n 60 "ssh dev-mini 'df -h /mnt/extreme-pro'"

# Check growth rate
ssh dev-mini 'du -sh /mnt/extreme-pro/k3s/*'
```

## 🆘 Support

If you encounter issues:

1. Check logs: `ssh dev-mini 'sudo journalctl -u k3s -n 100'`
2. Review this README
3. Check k3s docs: https://docs.k3s.io
4. File an issue in the repository

## 📚 Additional Resources

- [k3s Documentation](https://docs.k3s.io)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Rancher Local Path Provisioner](https://github.com/rancher/local-path-provisioner)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Note**: This setup uses k3s for lightweight Kubernetes deployment. The external drive configuration ensures optimal performance and easy management of your container workloads.