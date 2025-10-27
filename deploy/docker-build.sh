#!/bin/bash

# Catalyst9 Docker Build Script
# Build and optionally push Docker images

set -e

# Configuration
REGISTRY="${DOCKER_REGISTRY:-docker.io}"
NAMESPACE="${DOCKER_NAMESPACE:-catalyst9}"
TAG="${TAG:-latest}"
PUSH="${PUSH:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building Catalyst9 Docker Images${NC}"
echo -e "${BLUE}====================================${NC}"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --push) PUSH="true";;
        --tag) TAG="$2"; shift;;
        --registry) REGISTRY="$2"; shift;;
        --namespace) NAMESPACE="$2"; shift;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

# Image name
IMAGE_NAME="${REGISTRY}/${NAMESPACE}/api:${TAG}"

echo -e "${YELLOW}Building image: ${IMAGE_NAME}${NC}"

# Build the Docker image
echo -e "\n${YELLOW}Building Catalyst9 API image...${NC}"
docker build -t "${IMAGE_NAME}" -f Dockerfile .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image built successfully${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Tag as latest if not already
if [ "${TAG}" != "latest" ]; then
    docker tag "${IMAGE_NAME}" "${REGISTRY}/${NAMESPACE}/api:latest"
    echo -e "${GREEN}✅ Tagged as latest${NC}"
fi

# Push to registry if requested
if [ "${PUSH}" == "true" ]; then
    echo -e "\n${YELLOW}Pushing to registry...${NC}"

    # Login to registry if credentials are provided
    if [ -n "${DOCKER_USERNAME}" ] && [ -n "${DOCKER_PASSWORD}" ]; then
        echo "${DOCKER_PASSWORD}" | docker login "${REGISTRY}" -u "${DOCKER_USERNAME}" --password-stdin
    fi

    docker push "${IMAGE_NAME}"

    if [ "${TAG}" != "latest" ]; then
        docker push "${REGISTRY}/${NAMESPACE}/api:latest"
    fi

    echo -e "${GREEN}✅ Image pushed to registry${NC}"
fi

# Output summary
echo -e "\n${GREEN}📦 Build Complete!${NC}"
echo -e "${BLUE}=================${NC}"
echo -e "Image: ${GREEN}${IMAGE_NAME}${NC}"
echo -e "Size: $(docker images "${IMAGE_NAME}" --format "{{.Size}}")"

# Suggest next steps
if [ "${PUSH}" != "true" ]; then
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "  • Push to registry: ${GREEN}$0 --push${NC}"
    echo -e "  • Test locally: ${GREEN}docker-compose up${NC}"
    echo -e "  • Deploy to k3s: ${GREEN}./deploy-k3s.sh${NC}"
else
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo -e "  • Deploy to k3s: ${GREEN}./deploy-k3s.sh${NC}"
    echo -e "  • Update k3s deployment: ${GREEN}kubectl set image deployment/catalyst9-api catalyst9-api=${IMAGE_NAME} -n catalyst9${NC}"
fi