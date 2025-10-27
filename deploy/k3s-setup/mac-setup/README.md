# Kubernetes on macOS (dev-mini) Setup Guide

## Overview

Since dev-mini is a Mac, we can't run k3s directly (it requires Linux). However, we have several excellent options for running Kubernetes on macOS with your external Extreme Pro drive.

## 🎯 Recommended Options

### 1. **Rancher Desktop** (Recommended) ✅

**Pros:**
- Free and open source
- Includes k3s (lightweight Kubernetes)
- No licensing concerns
- Good performance
- Built-in container runtime (containerd or dockerd)
- Easy to configure

**Cons:**
- Uses a VM (some overhead)
- Requires 4-8GB RAM for the VM

**Install:**
```bash
cd deploy/k3s-setup/mac-setup
./install-rancher-desktop.sh
```

### 2. **Docker Desktop**

**Pros:**
- Industry standard
- Excellent macOS integration
- Good UI
- Includes Kubernetes option

**Cons:**
- Requires license for commercial use (250+ employees or $10M+ revenue)
- Heavier resource usage
- Less flexible than Rancher Desktop

**Install:**
```bash
cd deploy/k3s-setup/mac-setup
./install-docker-desktop.sh
```

### 3. **kind** (Kubernetes in Docker)

**Pros:**
- Lightweight
- Fast startup
- Good for testing
- Free and open source

**Cons:**
- Not ideal for persistent workloads
- Requires Docker to be installed first

**Install:**
```bash
brew install kind
kind create cluster --name catalyst9
```

### 4. **minikube**

**Pros:**
- Official Kubernetes project
- Multiple driver options
- Good documentation

**Cons:**
- Single node only
- Can be resource heavy

**Install:**
```bash
brew install minikube
minikube start --driver=docker --mount-string="/Volumes/Extreme Pro:/data"
```

## 🚀 Quick Start with Rancher Desktop

This is the best option for your setup:

```bash
# From this directory
chmod +x install-rancher-desktop.sh
./install-rancher-desktop.sh
```

This will:
1. ✅ Install Rancher Desktop via Homebrew
2. ✅ Configure it to use your external drive
3. ✅ Set up k3s in a VM
4. ✅ Configure kubectl
5. ✅ Create storage class for external drive
6. ✅ Install helpful tools (Helm, k9s)

## 💾 External Drive Configuration

All options are configured to use your Extreme Pro drive at `/Volumes/Extreme Pro/`:

### Directory Structure
```
/Volumes/Extreme Pro/
├── rancher-desktop/           # For Rancher Desktop
│   ├── persistent-volumes/    # Application data
│   ├── docker-images/         # Container images
│   └── k3s-data/             # k3s data
├── docker-desktop/           # For Docker Desktop
│   ├── persistent-volumes/    # Application data
│   └── docker-data/          # Docker data
```

## 🔧 Persistent Volume Configuration

Each setup creates a storage class that uses your external drive:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: extreme-pro-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

## 📋 Comparison Table

| Feature | Rancher Desktop | Docker Desktop | kind | minikube |
|---------|-----------------|----------------|------|----------|
| **License** | Free (Apache 2.0) | Free for small use | Free (Apache 2.0) | Free (Apache 2.0) |
| **Kubernetes** | k3s | Full K8s | Full K8s | Full K8s |
| **Resource Usage** | Medium | High | Low | Medium |
| **External Storage** | ✅ Supported | ✅ Supported | ⚠️ Limited | ✅ Supported |
| **Production-like** | ✅ Yes | ✅ Yes | ❌ No | ⚠️ Limited |
| **Multi-node** | ❌ No | ❌ No | ✅ Yes | ⚠️ Limited |
| **Best For** | Development | Development | Testing | Learning |

## 🎯 For Catalyst9 Development

**Recommendation: Use Rancher Desktop**

Reasons:
1. Closest to production k3s
2. No licensing concerns
3. Good performance with external drive
4. Active development and support
5. Includes all necessary tools

## 🔧 Management Commands

### Rancher Desktop
```bash
# Start
rancher-start.sh
# or
open -a "Rancher Desktop"

# Stop
rancher-stop.sh
# or quit from menu bar

# Reset cluster
# In Rancher Desktop app → Troubleshooting → Reset Kubernetes

# View logs
tail -f ~/Library/Logs/rancher-desktop/k3s.log
```

### Docker Desktop
```bash
# Start
open -a Docker

# Stop
osascript -e 'quit app "Docker"'

# Reset cluster
# In Docker Desktop → Preferences → Kubernetes → Reset Kubernetes Cluster

# Switch context
kubectl config use-context docker-desktop
```

## 📊 Resource Configuration

### Recommended Settings

For dev-mini with external storage:

**Rancher Desktop:**
- CPUs: 4
- Memory: 8GB
- Storage: Use external drive

**Docker Desktop:**
- CPUs: 4
- Memory: 8GB
- Disk: 64GB+ on external drive

## 🔍 Troubleshooting

### Issue: "Cannot connect to the Docker daemon"

```bash
# For Rancher Desktop
open -a "Rancher Desktop"

# For Docker Desktop
open -a Docker
```

### Issue: "kubectl: command not found"

```bash
brew install kubectl
```

### Issue: External drive not accessible

```bash
# Check if mounted
ls /Volumes/
df -h | grep "Extreme Pro"

# Remount if needed (in Disk Utility)
```

### Issue: Kubernetes not starting

```bash
# Rancher Desktop - Reset from app
# Docker Desktop - Reset from preferences

# Or manually cleanup
rm -rf ~/.kube/config
# Then restart the application
```

## 🚀 Deploy Catalyst9

Once Kubernetes is running:

```bash
# Check cluster is ready
kubectl cluster-info
kubectl get nodes

# Deploy Catalyst9
cd /Users/BertSmith/personal/catalyst9/catalyst-core
kubectl apply -f deploy/k3s/

# Check deployment
kubectl get pods -n catalyst9
```

## 📚 Additional Resources

- [Rancher Desktop Docs](https://docs.rancherdesktop.io/)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [minikube Documentation](https://minikube.sigs.k8s.io/)

## 🎯 Summary

For your dev-mini Mac with external storage:

1. **Best Choice**: Rancher Desktop - Free, k3s-based, good performance
2. **Alternative**: Docker Desktop - If you already have a license
3. **For Testing**: kind - Quick and lightweight
4. **For Learning**: minikube - Official Kubernetes project

Run `./install-rancher-desktop.sh` to get started with the recommended setup!