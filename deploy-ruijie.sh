#!/bin/bash

# ============================================
# RustDesk API with Ruijie SID - 快速部署脚本
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  RustDesk API with Ruijie SID - 部署脚本${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# 检查 Docker 和 Docker Compose
check_requirements() {
    print_info "检查环境依赖..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    print_success "环境检查通过"
}

# 检查配置文件
check_config() {
    print_info "检查配置文件..."

    if [ ! -f ".env" ]; then
        print_warning ".env 文件不存在，正在从模板创建..."
        cp .env.ruijie.example .env
        print_warning "请编辑 .env 文件，配置以下必要信息:"
        print_warning "  - MYSQL_ROOT_PASSWORD"
        print_warning "  - MYSQL_PASSWORD"
        print_warning "  - API_SERVER"
        print_warning "  - RUIJIE_SID_CLIENT_ID"
        print_warning "  - RUIJIE_SID_CLIENT_SECRET"
        echo ""
        read -p "按 Enter 键继续编辑 .env 文件..."
        ${EDITOR:-vim} .env
    fi

    # 检查关键配置是否已修改
    if grep -q "YOUR_CLIENT_ID_HERE" .env || grep -q "your_secure_password" .env; then
        print_warning ".env 文件中仍包含默认值，请确保已修改所有必要配置"
        read -p "是否继续部署？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "部署已取消"
            exit 1
        fi
    fi

    print_success "配置文件检查完成"
}

# 检查数据库初始化脚本
check_database_script() {
    print_info "检查数据库初始化脚本..."

    if grep -q "YOUR_CLIENT_ID_HERE" scripts/ruijie_sid_mysql_setup.sql; then
        print_warning "scripts/ruijie_sid_mysql_setup.sql 中包含默认值"
        print_warning "请编辑以下内容:"
        print_warning "  - 第 185 行: YOUR_CLIENT_ID_HERE"
        print_warning "  - 第 186 行: YOUR_CLIENT_SECRET_HERE"
        print_warning "  - 第 219 行: 管理员密码哈希"
        echo ""
        read -p "是否编辑数据库初始化脚本？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-vim} scripts/ruijie_sid_mysql_setup.sql
        fi
    fi

    print_success "数据库脚本检查完成"
}

# 构建镜像
build_images() {
    print_info "开始构建 Docker 镜像..."

    docker-compose -f docker-compose.ruijie.yaml build --no-cache

    print_success "Docker 镜像构建完成"
}

# 启动服务
start_services() {
    print_info "启动服务..."

    # 询问是否启动 phpMyAdmin
    read -p "是否启动 phpMyAdmin？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -f docker-compose.ruijie.yaml --profile tools up -d
    else
        docker-compose -f docker-compose.ruijie.yaml up -d
    fi

    print_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务就绪..."

    # 等待 MySQL
    print_info "等待 MySQL 数据库启动..."
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f docker-compose.ruijie.yaml ps | grep -q "rustdesk-mysql.*healthy"; then
            print_success "MySQL 数据库就绪"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    if [ $attempt -eq $max_attempts ]; then
        print_error "MySQL 数据库启动超时"
        return 1
    fi

    # 等待 API 服务
    print_info "等待 API 服务启动..."
    attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f docker-compose.ruijie.yaml ps | grep -q "rustdesk-api.*healthy"; then
            print_success "API 服务就绪"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    if [ $attempt -eq $max_attempts ]; then
        print_error "API 服务启动超时"
        return 1
    fi

    print_success "所有服务已就绪"
}

# 验证部署
verify_deployment() {
    print_info "验证部署..."

    # 检查健康状态
    print_info "检查 API 健康状态..."
    if curl -s http://localhost:21114/api/health | grep -q "ok"; then
        print_success "API 健康检查通过"
    else
        print_error "API 健康检查失败"
        return 1
    fi

    # 检查 OAuth 配置
    print_info "检查 OAuth 配置..."
    if curl -s http://localhost:21114/api/oauth/providers | grep -q "ruijie_sid"; then
        print_success "锐捷 SID OAuth 配置已加载"
    else
        print_warning "未找到锐捷 SID OAuth 配置"
    fi

    print_success "部署验证完成"
}

# 显示部署信息
show_deployment_info() {
    echo ""
    print_success "============================================"
    print_success "  部署成功！"
    print_success "============================================"
    echo ""
    print_info "服务地址:"
    print_info "  - API 服务: http://localhost:21114"
    print_info "  - API 文档: http://localhost:21114/swagger/api/index.html"
    print_info "  - 管理后台: http://localhost:21114/swagger/admin/index.html"

    if docker-compose -f docker-compose.ruijie.yaml ps | grep -q "rustdesk-phpmyadmin"; then
        print_info "  - phpMyAdmin: http://localhost:8080"
    fi

    echo ""
    print_info "常用命令:"
    print_info "  - 查看日志: docker-compose -f docker-compose.ruijie.yaml logs -f"
    print_info "  - 重启服务: docker-compose -f docker-compose.ruijie.yaml restart"
    print_info "  - 停止服务: docker-compose -f docker-compose.ruijie.yaml down"
    echo ""
    print_info "详细文档: docs/DOCKER_DEPLOYMENT.md"
    echo ""
}

# 主函数
main() {
    print_header

    # 检查环境
    check_requirements

    # 检查配置
    check_config
    check_database_script

    # 构建镜像
    print_info "准备构建 Docker 镜像"
    read -p "是否开始构建？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "部署已取消"
        exit 0
    fi

    build_images

    # 启动服务
    start_services

    # 等待服务就绪
    if ! wait_for_services; then
        print_error "服务启动失败，查看日志:"
        print_error "  docker-compose -f docker-compose.ruijie.yaml logs"
        exit 1
    fi

    # 验证部署
    if ! verify_deployment; then
        print_warning "部署验证出现问题，请检查日志"
    fi

    # 显示部署信息
    show_deployment_info
}

# 运行主函数
main "$@"
