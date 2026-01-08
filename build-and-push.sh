#!/bin/bash
# ============================================
# 本地构建 Docker 镜像并推送到 Docker Hub
# ============================================
# 使用说明:
#   chmod +x build-and-push.sh
#   ./build-and-push.sh
# ============================================

set -e

# 配置信息
DOCKER_USERNAME="xuepudong"
IMAGE_NAME="rustdesk-api"
IMAGE_TAG="latest"
IMAGE_TAG_VERSION="v1.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  RustDesk API - 构建并推送到 Docker Hub${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_header

# 检查 Docker
print_info "检查 Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装"
    exit 1
fi
print_success "Docker 已安装: $(docker --version)"
echo ""

# 登录 Docker Hub
print_info "登录 Docker Hub..."
echo "用户名: $DOCKER_USERNAME"
docker login -u $DOCKER_USERNAME
if [ $? -ne 0 ]; then
    print_error "Docker Hub 登录失败"
    exit 1
fi
print_success "登录成功"
echo ""

# 构建镜像
print_info "开始构建 Docker 镜像..."
print_info "这可能需要 5-10 分钟，请耐心等待..."
echo ""

docker build -f Dockerfile.simple -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
if [ $? -ne 0 ]; then
    print_error "镜像构建失败"
    exit 1
fi
echo ""
print_success "镜像构建完成"
echo ""

# 添加版本标签
print_info "添加版本标签..."
docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG_VERSION}
print_success "标签添加完成"
echo ""

# 推送镜像
print_info "推送镜像到 Docker Hub..."
print_info "推送 ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
if [ $? -ne 0 ]; then
    print_error "镜像推送失败"
    exit 1
fi
echo ""

print_info "推送版本标签..."
print_info "推送 ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG_VERSION}"
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG_VERSION}
if [ $? -ne 0 ]; then
    print_error "版本标签推送失败"
    exit 1
fi
echo ""

# 显示镜像信息
print_success "============================================"
print_success "  推送成功！"
print_success "============================================"
echo ""
print_info "镜像信息:"
print_info "  - 仓库: https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
print_info "  - 镜像: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
print_info "  - 版本: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG_VERSION}"
echo ""
print_info "镜像大小:"
docker images ${DOCKER_USERNAME}/${IMAGE_NAME}
echo ""
print_info "在服务器上使用:"
print_info "  docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
print_info "  或使用 docker-compose-hub.yaml 部署"
echo ""
