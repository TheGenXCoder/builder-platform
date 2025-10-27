#!/bin/bash

# Portable CI/CD Deployment Script for Catalyst9
# Works with any CI/CD platform (Jenkins, GitLab CI, Drone, etc.)
# Not tied to GitHub Actions

set -e

# Configuration (can be overridden by environment variables)
PROJECT_NAME="${PROJECT_NAME:-catalyst9}"
REGISTRY="${DOCKER_REGISTRY:-docker.io}"
NAMESPACE="${DOCKER_NAMESPACE:-catalyst9}"
IMAGE_NAME="${IMAGE_NAME:-api}"
DEPLOY_SERVER="${DEPLOY_SERVER:-dev-mini}"
K8S_NAMESPACE="${K8S_NAMESPACE:-catalyst9}"

# CI Environment Detection
detect_ci_environment() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "github"
        CI_BRANCH="${GITHUB_REF_NAME:-$GITHUB_HEAD_REF}"
        CI_COMMIT="${GITHUB_SHA}"
        CI_TAG="${GITHUB_REF_NAME}"
        CI_PR="${GITHUB_EVENT_NAME}"
    elif [ -n "$GITLAB_CI" ]; then
        echo "gitlab"
        CI_BRANCH="${CI_COMMIT_REF_NAME}"
        CI_COMMIT="${CI_COMMIT_SHA}"
        CI_TAG="${CI_COMMIT_TAG}"
        CI_PR="${CI_PIPELINE_SOURCE}"
    elif [ -n "$JENKINS_URL" ]; then
        echo "jenkins"
        CI_BRANCH="${GIT_BRANCH##*/}"
        CI_COMMIT="${GIT_COMMIT}"
        CI_TAG="${TAG_NAME}"
        CI_PR="${CHANGE_ID}"
    elif [ -n "$DRONE" ]; then
        echo "drone"
        CI_BRANCH="${DRONE_BRANCH}"
        CI_COMMIT="${DRONE_COMMIT}"
        CI_TAG="${DRONE_TAG}"
        CI_PR="${DRONE_PULL_REQUEST}"
    elif [ -n "$CIRCLECI" ]; then
        echo "circleci"
        CI_BRANCH="${CIRCLE_BRANCH}"
        CI_COMMIT="${CIRCLE_SHA1}"
        CI_TAG="${CIRCLE_TAG}"
        CI_PR="${CIRCLE_PULL_REQUEST}"
    elif [ -n "$BITBUCKET_PIPELINES" ]; then
        echo "bitbucket"
        CI_BRANCH="${BITBUCKET_BRANCH}"
        CI_COMMIT="${BITBUCKET_COMMIT}"
        CI_TAG="${BITBUCKET_TAG}"
        CI_PR="${BITBUCKET_PR_ID}"
    else
        echo "local"
        CI_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        CI_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        CI_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
        CI_PR=""
    fi
}

# Colors for output (disable in CI)
if [ -t 1 ] && [ -z "$CI" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Main deployment functions
run_tests() {
    log "Running tests..."
    cd projects/knowledge-graph-system

    if [ -f "go.mod" ]; then
        go mod download
        go test -v -race -coverprofile=coverage.out ./...
        log "Tests passed ✅"
    else
        warning "No Go module found, skipping tests"
    fi

    cd ../..
}

build_docker_image() {
    local TAG=$1
    local FULL_IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

    log "Building Docker image: ${FULL_IMAGE}"

    # Build the image
    docker build -t "${FULL_IMAGE}" -f Dockerfile .

    # Tag as latest if building from main
    if [ "$CI_BRANCH" = "main" ] || [ "$CI_BRANCH" = "master" ]; then
        docker tag "${FULL_IMAGE}" "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest"
    fi

    log "Docker image built successfully ✅"
}

push_docker_image() {
    local TAG=$1
    local FULL_IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

    log "Pushing Docker image: ${FULL_IMAGE}"

    # Login to registry if credentials provided
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        echo "${DOCKER_PASSWORD}" | docker login "${REGISTRY}" -u "${DOCKER_USERNAME}" --password-stdin
    elif [ -n "$DOCKER_CONFIG_JSON" ]; then
        # For GitLab/other CIs that provide config as JSON
        mkdir -p ~/.docker
        echo "${DOCKER_CONFIG_JSON}" | base64 -d > ~/.docker/config.json
    fi

    # Push the image
    docker push "${FULL_IMAGE}"

    # Push latest tag if applicable
    if [ "$CI_BRANCH" = "main" ] || [ "$CI_BRANCH" = "master" ]; then
        docker push "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest"
    fi

    log "Docker image pushed successfully ✅"
}

deploy_to_k8s() {
    local TAG=$1
    local FULL_IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

    log "Deploying to Kubernetes..."

    # Setup kubectl
    if [ -n "$KUBECONFIG_CONTENT" ]; then
        # Config provided as environment variable
        mkdir -p ~/.kube
        echo "${KUBECONFIG_CONTENT}" | base64 -d > ~/.kube/config
    elif [ -n "$KUBECONFIG" ]; then
        # Config file path provided
        export KUBECONFIG="${KUBECONFIG}"
    else
        # Try to SSH to deploy server
        if [ -n "$SSH_KEY" ]; then
            mkdir -p ~/.ssh
            echo "${SSH_KEY}" > ~/.ssh/id_rsa
            chmod 600 ~/.ssh/id_rsa

            # Deploy via SSH
            ssh -o StrictHostKeyChecking=no "${DEPLOY_SERVER}" << EOF
                kubectl set image deployment/${PROJECT_NAME}-api \
                    ${PROJECT_NAME}-api=${FULL_IMAGE} \
                    -n ${K8S_NAMESPACE}
                kubectl rollout status deployment/${PROJECT_NAME}-api -n ${K8S_NAMESPACE} --timeout=5m
EOF
            log "Deployment via SSH completed ✅"
            return
        fi
    fi

    # Direct kubectl deployment
    kubectl set image "deployment/${PROJECT_NAME}-api" \
        "${PROJECT_NAME}-api=${FULL_IMAGE}" \
        -n "${K8S_NAMESPACE}"

    kubectl rollout status "deployment/${PROJECT_NAME}-api" \
        -n "${K8S_NAMESPACE}" \
        --timeout=5m

    log "Kubernetes deployment completed ✅"
}

update_dns() {
    log "Updating DNS records..."

    if [ -n "$SSH_KEY" ] && [ -n "$DEPLOY_SERVER" ]; then
        ssh -o StrictHostKeyChecking=no "${DEPLOY_SERVER}" \
            "/opt/catalyst9/deploy/dns/ddns-updater.sh --once" || \
            warning "DNS update failed, but deployment continues"
    else
        warning "SSH not configured, skipping DNS update"
    fi
}

verify_deployment() {
    log "Verifying deployment..."

    # Get service endpoint
    if command -v kubectl &> /dev/null; then
        SERVICE_IP=$(kubectl get svc "${PROJECT_NAME}-api" -n "${K8S_NAMESPACE}" \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

        if [ -z "$SERVICE_IP" ]; then
            SERVICE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || echo "")
        fi
    fi

    if [ -n "$SERVICE_IP" ]; then
        if curl -f "http://${SERVICE_IP}/health" --max-time 10; then
            log "Health check passed ✅"
            return 0
        else
            error "Health check failed"
            return 1
        fi
    else
        warning "Could not determine service IP, skipping health check"
    fi
}

# Parse command line arguments
COMMAND=""
TAG=""
SKIP_TESTS=false
SKIP_PUSH=false
SKIP_DEPLOY=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        test)
            COMMAND="test"
            ;;
        build)
            COMMAND="build"
            ;;
        deploy)
            COMMAND="deploy"
            ;;
        all)
            COMMAND="all"
            ;;
        --tag)
            TAG="$2"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            ;;
        --skip-push)
            SKIP_PUSH=true
            ;;
        --skip-deploy)
            SKIP_DEPLOY=true
            ;;
        --help)
            echo "Catalyst9 Portable CI/CD Script"
            echo ""
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  test     Run tests only"
            echo "  build    Build Docker image"
            echo "  deploy   Deploy to Kubernetes"
            echo "  all      Run full pipeline (default)"
            echo ""
            echo "Options:"
            echo "  --tag TAG         Docker image tag"
            echo "  --skip-tests      Skip running tests"
            echo "  --skip-push       Skip pushing to registry"
            echo "  --skip-deploy     Skip deployment"
            echo "  --help           Show this help"
            echo ""
            echo "Environment Variables:"
            echo "  DOCKER_REGISTRY   Docker registry (default: docker.io)"
            echo "  DOCKER_USERNAME   Docker username"
            echo "  DOCKER_PASSWORD   Docker password"
            echo "  DEPLOY_SERVER    Deployment server (default: dev-mini)"
            echo "  SSH_KEY          SSH private key for deployment"
            echo "  KUBECONFIG       Path to kubeconfig file"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Set default command
COMMAND="${COMMAND:-all}"

# Detect CI environment
CI_ENV=$(detect_ci_environment)
log "Detected CI environment: $CI_ENV"
log "Branch: $CI_BRANCH, Commit: ${CI_COMMIT:0:8}"

# Determine image tag
if [ -n "$TAG" ]; then
    IMAGE_TAG="$TAG"
elif [ -n "$CI_TAG" ]; then
    IMAGE_TAG="$CI_TAG"
elif [ "$CI_BRANCH" = "production" ]; then
    IMAGE_TAG="production-${CI_COMMIT:0:8}"
elif [ "$CI_BRANCH" = "main" ] || [ "$CI_BRANCH" = "master" ]; then
    IMAGE_TAG="main-${CI_COMMIT:0:8}"
else
    IMAGE_TAG="${CI_BRANCH}-${CI_COMMIT:0:8}"
fi

log "Using image tag: $IMAGE_TAG"

# Execute commands
case $COMMAND in
    test)
        run_tests
        ;;
    build)
        [ "$SKIP_TESTS" = false ] && run_tests
        build_docker_image "$IMAGE_TAG"
        [ "$SKIP_PUSH" = false ] && push_docker_image "$IMAGE_TAG"
        ;;
    deploy)
        deploy_to_k8s "$IMAGE_TAG"
        [ "$CI_BRANCH" = "production" ] && update_dns
        verify_deployment
        ;;
    all)
        [ "$SKIP_TESTS" = false ] && run_tests
        build_docker_image "$IMAGE_TAG"
        [ "$SKIP_PUSH" = false ] && push_docker_image "$IMAGE_TAG"
        if [ "$SKIP_DEPLOY" = false ] && [ "$CI_BRANCH" = "main" -o "$CI_BRANCH" = "production" -o -n "$CI_TAG" ]; then
            deploy_to_k8s "$IMAGE_TAG"
            [ "$CI_BRANCH" = "production" ] && update_dns
            verify_deployment
        fi
        ;;
esac

log "Pipeline completed successfully! 🎉"