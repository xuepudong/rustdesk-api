# 腾讯云服务器部署指南

> 本指南专门为腾讯云服务器部署 RustDesk API with Ruijie SID 准备。

## 目录

- [准备工作](#准备工作)
- [方案 A: 一键自动部署（推荐）](#方案-a-一键自动部署推荐)
- [方案 B: 手动部署](#方案-b-手动部署)
- [验证部署](#验证部署)
- [常见问题](#常见问题)

---

## 准备工作

### 1. 服务器要求

- **系统**: Ubuntu 20.04 LTS 或更高版本
- **配置**:
  - 最低: 2核 CPU, 4GB 内存, 20GB 硬盘
  - 推荐: 4核 CPU, 8GB 内存, 50GB 硬盘
- **网络**: 公网 IP，开放端口 80, 443

### 2. 域名配置

**已配置域名**: `rd.jiecloud.com.cn`

请确保域名已解析到腾讯云服务器 IP:

```bash
# 检查域名解析
nslookup rd.jiecloud.com.cn

# 或者
dig rd.jiecloud.com.cn
```

在腾讯云 DNS 控制台添加 A 记录:
- 主机记录: `rd`
- 记录类型: `A`
- 记录值: `你的服务器公网 IP`
- TTL: `600`

### 3. 锐捷 SID 配置

登录锐捷 SID 管理平台: https://sid.ruijie.com.cn

配置应用信息:
- **应用名称**: RustDesk API
- **回调地址**: `https://rd.jiecloud.com.cn/api/oidc/callback`
- **Client ID**: `ruijiedesk`（已配置）
- **Client Secret**: `WMWljn4HdWyhek1FRPlZ-QYG45A7H0RpEiE1b0MEg_FEGJNCcX_skpDyxtLIWiSu`（已配置）

---

## 方案 A: 一键自动部署（推荐）

### 步骤 1: 连接服务器

```bash
# SSH 连接到腾讯云服务器
ssh ubuntu@YOUR_SERVER_IP

# 或使用腾讯云 Web SSH
```

### 步骤 2: 下载并运行部署脚本

```bash
# 下载部署脚本
wget -O deploy-server.sh https://raw.githubusercontent.com/xuepudong/rustdesk-api/master/deploy-server.sh

# 添加执行权限
chmod +x deploy-server.sh

# 运行脚本（需要 root 权限）
sudo ./deploy-server.sh
```

### 步骤 3: 等待部署完成

脚本会自动完成以下操作:

1. ✅ 更新系统软件包
2. ✅ 安装依赖（Nginx, Certbot, Git 等）
3. ✅ 检查并安装 Docker 和 Docker Compose
4. ✅ 克隆代码仓库到 `/opt/rustdesk-api`
5. ✅ 配置环境变量
6. ✅ 配置 Nginx 反向代理
7. ✅ 申请 Let's Encrypt SSL 证书
8. ✅ 启动 Docker 服务
9. ✅ 配置防火墙

部署成功后会显示:

```
============================================
  部署完成！
============================================

服务地址:
  - 主站: https://rd.jiecloud.com.cn
  - API 文档: https://rd.jiecloud.com.cn/swagger/api/index.html
  - 管理后台: https://rd.jiecloud.com.cn/swagger/admin/index.html

默认管理员账号:
  - 用户名: admin
  - 密码: admin123
  ⚠️  请立即登录并修改密码！
```

### 步骤 4: 验证部署

```bash
# 检查服务状态
cd /opt/rustdesk-api
docker compose -f docker-compose.ruijie.yaml ps

# 检查日志
docker compose -f docker-compose.ruijie.yaml logs -f
```

---

## 方案 B: 手动部署

如果自动部署脚本遇到问题，可以手动部署。

### 步骤 1: 更新系统并安装依赖

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    nginx \
    certbot \
    python3-certbot-nginx
```

### 步骤 2: 安装 Docker

```bash
# 添加 Docker GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker compose version
```

### 步骤 3: 克隆代码

```bash
# 克隆到 /opt 目录
sudo git clone https://github.com/xuepudong/rustdesk-api.git /opt/rustdesk-api

# 进入目录
cd /opt/rustdesk-api
```

### 步骤 4: 配置环境变量

```bash
# 复制环境变量模板
sudo cp .env.ruijie.example .env

# 编辑配置文件
sudo vim .env
```

确认以下配置正确:

```bash
API_SERVER=https://rd.jiecloud.com.cn
RUIJIE_SID_BASE_URL=https://sid.ruijie.com.cn
RUIJIE_SID_CLIENT_ID=ruijiedesk
RUIJIE_SID_CLIENT_SECRET=WMWljn4HdWyhek1FRPlZ-QYG45A7H0RpEiE1b0MEg_FEGJNCcX_skpDyxtLIWiSu
```

### 步骤 5: 配置 Nginx

```bash
# 复制 Nginx 配置
sudo cp nginx-rustdesk-api.conf /etc/nginx/sites-available/rustdesk-api

# 创建软链接
sudo ln -s /etc/nginx/sites-available/rustdesk-api /etc/nginx/sites-enabled/

# 删除默认配置
sudo rm /etc/nginx/sites-enabled/default

# 测试配置
sudo nginx -t
```

### 步骤 6: 申请 SSL 证书

```bash
# 启动 Nginx
sudo systemctl start nginx

# 申请证书
sudo certbot certonly --nginx -d rd.jiecloud.com.cn

# 配置自动续期
(sudo crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | sudo crontab -
```

### 步骤 7: 启动 Docker 服务

```bash
# 构建并启动
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml up -d --build

# 查看日志
sudo docker compose -f docker-compose.ruijie.yaml logs -f
```

### 步骤 8: 重启 Nginx

```bash
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 步骤 9: 配置防火墙

```bash
# 允许 HTTP, HTTPS, SSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

# 启用防火墙
sudo ufw --force enable

# 查看状态
sudo ufw status
```

---

## 验证部署

### 1. 检查服务状态

```bash
# 检查 Docker 容器
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml ps

# 应该看到:
# rustdesk-mysql     healthy
# rustdesk-api       healthy
```

### 2. 检查 API 健康状态

```bash
# 本地检查
curl http://localhost:21114/api/health

# 应返回: {"status":"ok"}

# 外部检查
curl https://rd.jiecloud.com.cn/api/health
```

### 3. 访问 Web 界面

在浏览器中访问:

- **主站**: https://rd.jiecloud.com.cn
- **API 文档**: https://rd.jiecloud.com.cn/swagger/api/index.html
- **管理后台**: https://rd.jiecloud.com.cn/swagger/admin/index.html

### 4. 测试锐捷 SID OAuth

```bash
# 测试登录流程
curl "https://rd.jiecloud.com.cn/api/oidc/login?op=ruijie_sid&action=login&id=test&uuid=test123"

# 应该返回锐捷 SID 授权 URL
```

### 5. 查看日志

```bash
# Docker 日志
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml logs -f

# Nginx 日志
sudo tail -f /var/log/nginx/rustdesk-api-access.log
sudo tail -f /var/log/nginx/rustdesk-api-error.log
```

---

## 常见问题

### 问题 1: 域名解析失败

**现象**: 访问域名无响应

**解决方法**:

```bash
# 检查域名解析
nslookup rd.jiecloud.com.cn

# 检查 Nginx 状态
sudo systemctl status nginx

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### 问题 2: SSL 证书申请失败

**现象**: Let's Encrypt 证书申请失败

**解决方法**:

```bash
# 检查域名解析是否正确
# 确保 80 端口可访问

# 手动申请证书
sudo certbot certonly --nginx -d rd.jiecloud.com.cn --dry-run

# 如果 dry-run 成功，去掉 --dry-run 正式申请
sudo certbot certonly --nginx -d rd.jiecloud.com.cn
```

### 问题 3: Docker 容器启动失败

**现象**: `docker compose ps` 显示容器 Exit

**解决方法**:

```bash
# 查看详细日志
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml logs

# 检查配置文件
cat .env

# 重新构建并启动
sudo docker compose -f docker-compose.ruijie.yaml down
sudo docker compose -f docker-compose.ruijie.yaml up -d --build
```

### 问题 4: MySQL 连接失败

**现象**: API 日志显示数据库连接错误

**解决方法**:

```bash
# 检查 MySQL 容器
sudo docker compose -f docker-compose.ruijie.yaml ps mysql

# 查看 MySQL 日志
sudo docker compose -f docker-compose.ruijie.yaml logs mysql

# 重启 MySQL
sudo docker compose -f docker-compose.ruijie.yaml restart mysql
```

### 问题 5: 锐捷 SID OAuth 失败

**现象**: OAuth 登录返回 "ConfigNotFound"

**解决方法**:

```bash
# 检查数据库配置
sudo docker exec -it rustdesk-mysql mysql -u rustdesk -p
USE rustdesk;
SELECT * FROM oauths WHERE op = 'ruijie_sid';

# 如果没有记录，检查初始化脚本是否执行
# 查看 MySQL 容器日志
sudo docker compose -f docker-compose.ruijie.yaml logs mysql
```

### 问题 6: 端口被占用

**现象**: Nginx 或 Docker 启动失败，提示端口被占用

**解决方法**:

```bash
# 检查端口占用
sudo netstat -tuln | grep :80
sudo netstat -tuln | grep :443
sudo netstat -tuln | grep :21114

# 查找占用进程
sudo lsof -i :80

# 停止占用进程
sudo kill -9 PID
```

---

## 常用命令

### Docker 相关

```bash
# 查看日志
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml logs -f

# 重启服务
sudo docker compose -f docker-compose.ruijie.yaml restart

# 停止服务
sudo docker compose -f docker-compose.ruijie.yaml down

# 重新构建
sudo docker compose -f docker-compose.ruijie.yaml up -d --build

# 查看容器状态
sudo docker compose -f docker-compose.ruijie.yaml ps

# 进入容器
sudo docker exec -it rustdesk-api /bin/sh
sudo docker exec -it rustdesk-mysql mysql -u rustdesk -p
```

### Nginx 相关

```bash
# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 查看状态
sudo systemctl status nginx

# 查看日志
sudo tail -f /var/log/nginx/rustdesk-api-access.log
sudo tail -f /var/log/nginx/rustdesk-api-error.log
```

### 数据库备份

```bash
# 备份数据库
sudo docker exec rustdesk-mysql mysqldump -u rustdesk -p rustdesk > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢复数据库
sudo docker exec -i rustdesk-mysql mysql -u rustdesk -p rustdesk < backup_20260108_120000.sql
```

### 更新代码

```bash
# 拉取最新代码
cd /opt/rustdesk-api
sudo git pull

# 重新构建并启动
sudo docker compose -f docker-compose.ruijie.yaml down
sudo docker compose -f docker-compose.ruijie.yaml up -d --build
```

---

## 安全建议

### 1. 修改默认密码

首次登录后立即修改:
- 管理员密码（默认 admin123）
- MySQL root 密码
- MySQL rustdesk 用户密码

### 2. 限制 Swagger 访问

编辑 Nginx 配置，添加 IP 白名单:

```nginx
location /swagger/ {
    allow YOUR_OFFICE_IP;
    deny all;
    proxy_pass http://127.0.0.1:21114;
}
```

### 3. 配置防火墙

```bash
# 只允许必要端口
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 4. 定期更新

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 更新 Docker 镜像
cd /opt/rustdesk-api
sudo docker compose -f docker-compose.ruijie.yaml pull
sudo docker compose -f docker-compose.ruijie.yaml up -d
```

### 5. 监控和日志

```bash
# 配置日志轮转
sudo nano /etc/logrotate.d/rustdesk-api

# 添加:
/var/log/nginx/rustdesk-api-*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

---

## 技术支持

- **GitHub 仓库**: https://github.com/xuepudong/rustdesk-api
- **原项目**: https://github.com/lejianwen/rustdesk-api
- **锐捷 SID**: https://sid.ruijie.com.cn

---

## 附录

### 完整配置清单

| 项目 | 值 |
|------|-----|
| 域名 | rd.jiecloud.com.cn |
| SID 服务器 | https://sid.ruijie.com.cn |
| Client ID | ruijiedesk |
| 回调地址 | https://rd.jiecloud.com.cn/api/oidc/callback |
| API 端口 | 21114 |
| MySQL 端口 | 3306 |
| 部署目录 | /opt/rustdesk-api |

### 相关文档

- [Docker 部署指南](DOCKER_DEPLOYMENT.md)
- [锐捷 SID OAuth 文档](docs/RUIJIE_SID_OAUTH.md)
- [OAuth 流程说明](docs/OAUTH_FLOW.md)
- [快速入门](QUICKSTART_DOCKER.md)

---

最后更新: 2026-01-08
