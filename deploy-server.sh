#!/bin/bash

# ============================================
# RustDesk API - 腾讯云服务器一键部署脚本
# ============================================
# 使用说明:
#   wget -O deploy-server.sh https://raw.githubusercontent.com/xuepudong/rustdesk-api/master/deploy-server.sh
#   chmod +x deploy-server.sh
#   sudo ./deploy-server.sh
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置信息
GITHUB_REPO="xuepudong/rustdesk-api"
DOMAIN="rd.jiecloud.com.cn"
EMAIL="admin@jiecloud.com.cn"

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 打印标题
print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  RustDesk API - 腾讯云一键部署${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# 检查是否为 root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 更新系统
update_system() {
    print_info "更新系统软件包..."
    apt-get update -qq
    apt-get upgrade -y -qq
    print_success "系统更新完成"
}

# 安装依赖
install_dependencies() {
    print_info "安装依赖软件..."
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        nginx \
        certbot \
        python3-certbot-nginx
    print_success "依赖安装完成"
}

# 检查 Docker
check_docker() {
    print_info "检查 Docker..."
    if command -v docker &> /dev/null; then
        print_success "Docker 已安装: $(docker --version)"
    else
        print_warning "Docker 未安装，开始安装..."
        install_docker
    fi
}

# 安装 Docker
install_docker() {
    print_info "安装 Docker..."

    # 添加 Docker GPG 密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 添加 Docker 仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # 启动 Docker
    systemctl start docker
    systemctl enable docker

    print_success "Docker 安装完成"
}

# 检查 Docker Compose
check_docker_compose() {
    print_info "检查 Docker Compose..."
    if docker compose version &> /dev/null; then
        print_success "Docker Compose 已安装: $(docker compose version)"
    else
        print_error "Docker Compose 未安装"
        exit 1
    fi
}

# 克隆代码
clone_repository() {
    print_info "克隆代码仓库..."

    if [ -d "/opt/rustdesk-api" ]; then
        print_warning "目录已存在，更新代码..."
        cd /opt/rustdesk-api
        git pull
    else
        print_info "克隆新代码..."
        git clone https://github.com/${GITHUB_REPO}.git /opt/rustdesk-api
        cd /opt/rustdesk-api
    fi

    print_success "代码克隆完成"
}

# 配置环境变量
configure_env() {
    print_info "配置环境变量..."

    cd /opt/rustdesk-api

    if [ -f ".env" ]; then
        print_warning ".env 文件已存在，保留现有配置"
    else
        print_info "创建 .env 配置文件..."
        cp .env.ruijie.example .env

        # 自动替换配置
        sed -i "s|API_SERVER=.*|API_SERVER=https://${DOMAIN}|g" .env
        sed -i "s|MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)|g" .env
        sed -i "s|MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$(openssl rand -base64 32)|g" .env

        print_success ".env 文件创建完成"
        print_warning "请手动编辑 /opt/rustdesk-api/.env 文件，配置锐捷 SID 参数:"
        print_warning "  - RUIJIE_SID_CLIENT_ID"
        print_warning "  - RUIJIE_SID_CLIENT_SECRET"
    fi
}

# 配置 Nginx
configure_nginx() {
    print_info "配置 Nginx..."

    # 备份默认配置
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak
    fi

    # 创建配置文件
    cat > /etc/nginx/sites-available/rustdesk-api << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    # Let's Encrypt 验证
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # 重定向到 HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    # SSL 证书（Let's Encrypt）
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 日志
    access_log /var/log/nginx/rustdesk-api-access.log;
    error_log /var/log/nginx/rustdesk-api-error.log;

    # 代理到 Docker 容器
    location / {
        proxy_pass http://127.0.0.1:21114;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 限制上传大小
    client_max_body_size 100M;
}
EOF

    # 启用配置
    ln -sf /etc/nginx/sites-available/rustdesk-api /etc/nginx/sites-enabled/

    # 测试配置
    nginx -t

    print_success "Nginx 配置完成"
}

# 申请 SSL 证书
request_ssl_certificate() {
    print_info "申请 SSL 证书..."

    # 检查证书是否已存在
    if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
        print_warning "SSL 证书已存在，跳过申请"
        return
    fi

    # 启动 Nginx（用于验证域名）
    systemctl start nginx

    # 申请证书
    certbot certonly --nginx -d ${DOMAIN} --non-interactive --agree-tos --email ${EMAIL}

    if [ $? -eq 0 ]; then
        print_success "SSL 证书申请成功"

        # 配置自动续期
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -
        print_success "已配置证书自动续期"
    else
        print_error "SSL 证书申请失败"
        print_warning "您可以稍后手动申请: certbot certonly --nginx -d ${DOMAIN}"
    fi
}

# 启动服务
start_services() {
    print_info "启动 Docker 服务..."

    cd /opt/rustdesk-api
    docker compose -f docker-compose.ruijie.yaml down
    docker compose -f docker-compose.ruijie.yaml up -d --build

    print_success "Docker 服务启动完成"
}

# 重启 Nginx
restart_nginx() {
    print_info "重启 Nginx..."
    systemctl restart nginx
    systemctl enable nginx
    print_success "Nginx 已启动"
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙..."

    if command -v ufw &> /dev/null; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 22/tcp
        ufw --force enable
        print_success "防火墙配置完成"
    else
        print_warning "未检测到 UFW 防火墙"
    fi
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务就绪..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:21114/api/health | grep -q "ok"; then
            print_success "API 服务已就绪"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done

    print_error "API 服务启动超时"
    return 1
}

# 显示部署信息
show_deployment_info() {
    echo ""
    print_success "============================================"
    print_success "  部署完成！"
    print_success "============================================"
    echo ""
    print_info "服务地址:"
    print_info "  - 主站: https://${DOMAIN}"
    print_info "  - API 文档: https://${DOMAIN}/swagger/api/index.html"
    print_info "  - 管理后台: https://${DOMAIN}/swagger/admin/index.html"
    echo ""
    print_info "默认管理员账号:"
    print_info "  - 用户名: admin"
    print_info "  - 密码: admin123"
    print_warning "  ⚠️  请立即登录并修改密码！"
    echo ""
    print_info "常用命令:"
    print_info "  - 查看日志: cd /opt/rustdesk-api && docker compose -f docker-compose.ruijie.yaml logs -f"
    print_info "  - 重启服务: cd /opt/rustdesk-api && docker compose -f docker-compose.ruijie.yaml restart"
    print_info "  - 停止服务: cd /opt/rustdesk-api && docker compose -f docker-compose.ruijie.yaml down"
    echo ""
    print_info "配置文件:"
    print_info "  - 环境变量: /opt/rustdesk-api/.env"
    print_info "  - Nginx 配置: /etc/nginx/sites-available/rustdesk-api"
    echo ""
    print_warning "重要提醒:"
    print_warning "1. 请编辑 /opt/rustdesk-api/.env 配置锐捷 SID 参数"
    print_warning "2. 在锐捷 SID 管理平台配置回调地址: https://${DOMAIN}/api/oidc/callback"
    print_warning "3. 定期备份数据库: docker exec rustdesk-mysql mysqldump -u rustdesk -p rustdesk > backup.sql"
    echo ""
}

# 主函数
main() {
    print_header

    # 检查 root 权限
    check_root

    # 更新系统
    update_system

    # 安装依赖
    install_dependencies

    # 检查 Docker
    check_docker
    check_docker_compose

    # 克隆代码
    clone_repository

    # 配置环境变量
    configure_env

    # 配置 Nginx
    configure_nginx

    # 申请 SSL 证书
    request_ssl_certificate

    # 启动 Docker 服务
    start_services

    # 等待服务就绪
    wait_for_services

    # 重启 Nginx
    restart_nginx

    # 配置防火墙
    configure_firewall

    # 显示部署信息
    show_deployment_info
}

# 运行主函数
main "$@"
