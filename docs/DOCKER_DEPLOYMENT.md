# RustDesk API with Ruijie SID - Docker 部署指南

## 概述

本指南介绍如何使用 Docker 部署支持锐捷 SID OAuth 认证的 RustDesk API 服务。

## 部署架构

```
┌─────────────────────────────────────────────┐
│            Docker Compose Stack             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────┐      ┌───────────────┐   │
│  │              │      │               │   │
│  │  RustDesk    │─────▶│    MySQL      │   │
│  │     API      │      │   Database    │   │
│  │              │      │               │   │
│  └──────────────┘      └───────────────┘   │
│         ��                                   │
│         │                                   │
│         ▼                                   │
│  ┌──────────────┐                          │
│  │  phpMyAdmin  │ (可选)                    │
│  │   (tools)    │                          │
│  └──────────────┘                          │
│                                             │
└─────────────────────────────────────────────┘
         │
         ▼
   锐捷 SID 服务器
(https://sourceid.ruishan.cc)
```

## 前置条件

1. **Docker 和 Docker Compose**
   - Docker: 20.10 或更高版本
   - Docker Compose: 2.0 或更高版本

2. **锐捷 SID 应用凭证**
   - Client ID（应用账号）
   - Client Secret（应用密钥）
   - 回调地址已在锐捷 SID 管理平台配置为: `https://your-domain.com/api/oidc/callback`

3. **服务器要求**
   - 最小配置: 2 核 CPU, 4GB 内存, 20GB 磁盘
   - 推荐配置: 4 核 CPU, 8GB 内存, 50GB 磁盘

## 快速开始

### 1. 准备配置文件

```bash
# 复制环境变量模板
cp .env.ruijie.example .env

# 编辑配置文件（使用你喜欢的编辑器）
vim .env  # 或 nano .env
```

### 2. 修改关键配置

在 `.env` 文件中修改以下配置:

```bash
# MySQL 密码（必改！）
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_password

# API 服务器地址（必改！）
API_SERVER=https://your-domain.com

# 锐捷 SID 配置（必改！）
RUIJIE_SID_CLIENT_ID=your_actual_client_id
RUIJIE_SID_CLIENT_SECRET=your_actual_client_secret

# 如果使用私有部署的锐捷 SID，修改此项
RUIJIE_SID_BASE_URL=https://sid.your-company.com
```

### 3. 初始化数据库配置

编辑 `scripts/ruijie_sid_mysql_setup.sql`，修改以下内容:

```sql
-- 第 185-187 行: 修改锐捷 SID OAuth 配置
INSERT INTO `oauths` (...) VALUES (
    'ruijie_sid',
    'ruijie_sid',
    'YOUR_CLIENT_ID_HERE',          -- 【修改】实际的 Client ID
    'YOUR_CLIENT_SECRET_HERE',      -- 【修改】实际的 Client Secret
    'https://sourceid.ruishan.cc',  -- 【可选】SID 服务器地址
    ...
);

-- 第 219 行: 修改管理员密码哈希
'$2a$10$YourBcryptHashHere',  -- 【修改】实际的 bcrypt 密码哈希
```

**生成 bcrypt 密码哈希**:

```bash
# 使用 Python
python3 -c "import bcrypt; print(bcrypt.hashpw(b'your_password', bcrypt.gensalt()).decode())"

# 或使用在线工具
# https://bcrypt-generator.com/
```

### 4. 构建并启动服务

```bash
# 构建并启动所有服务
docker-compose -f docker-compose.ruijie.yaml up -d

# 查看启动日志
docker-compose -f docker-compose.ruijie.yaml logs -f

# 仅查看 API 日志
docker-compose -f docker-compose.ruijie.yaml logs -f rustdesk-api
```

### 5. 启动 phpMyAdmin（可选）

```bash
# 启动包含 phpMyAdmin 的服务
docker-compose -f docker-compose.ruijie.yaml --profile tools up -d

# 访问 http://localhost:8080
# 用户名: root
# 密码: 环境变量中的 MYSQL_ROOT_PASSWORD
```

## 验证部署

### 1. 检查服务状态

```bash
# 查看所有服务状态
docker-compose -f docker-compose.ruijie.yaml ps

# 应该看到以下服务运行中:
# - rustdesk-mysql (healthy)
# - rustdesk-api (healthy)
```

### 2. 检查健康状态

```bash
# 检查 API 健康状态
curl http://localhost:21114/api/health

# 应返回: {"status":"ok"}
```

### 3. 访问 Swagger 文档

打开浏览器访问:
- API 文档: http://localhost:21114/swagger/api/index.html
- 管理后台文档: http://localhost:21114/swagger/admin/index.html

### 4. 测试锐捷 SID OAuth

```bash
# 获取 OAuth 配置列表
curl http://localhost:21114/api/oauth/providers

# 应该看到 "ruijie_sid" 在列表中

# 测试锐捷 SID 登录流程
curl "http://localhost:21114/api/oidc/login?op=ruijie_sid&action=login&id=test_device&uuid=test_uuid"

# 应该返回授权 URL
```

### 5. 验证数据库

```bash
# 连接到 MySQL 容器
docker exec -it rustdesk-mysql mysql -u rustdesk -p

# 输入密码后执行以下 SQL
USE rustdesk;

-- 查看 OAuth 配置
SELECT op, oauth_type, client_id, issuer FROM oauths WHERE op = 'ruijie_sid';

-- 应该看到你配置的锐捷 SID OAuth 信息
```

## 常用操作

### 查看日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.ruijie.yaml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.ruijie.yaml logs -f rustdesk-api
docker-compose -f docker-compose.ruijie.yaml logs -f mysql

# 查看最近 100 行日志
docker-compose -f docker-compose.ruijie.yaml logs --tail=100
```

### 重启服务

```bash
# 重启所有服务
docker-compose -f docker-compose.ruijie.yaml restart

# 重启特定服务
docker-compose -f docker-compose.ruijie.yaml restart rustdesk-api
```

### 更新代码并重新部署

```bash
# 停止服务
docker-compose -f docker-compose.ruijie.yaml down

# 拉取最新代码
git pull

# 重新构建镜像
docker-compose -f docker-compose.ruijie.yaml build --no-cache

# 启动服务
docker-compose -f docker-compose.ruijie.yaml up -d
```

### 数据备份

```bash
# 备份 MySQL 数据库
docker exec rustdesk-mysql mysqldump -u rustdesk -p rustdesk > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢复数据库
docker exec -i rustdesk-mysql mysql -u rustdesk -p rustdesk < backup_20260108_120000.sql
```

### 清理和停止

```bash
# 停止服务（保留数据）
docker-compose -f docker-compose.ruijie.yaml down

# 停止服务并删除卷（⚠️ 会删除所有数据！）
docker-compose -f docker-compose.ruijie.yaml down -v

# 清理未使用的镜像
docker image prune -a
```

## 故障排查

### 问题 1: MySQL 连接失败

**现象**: API 日志显示 "Error 1045: Access denied"

**解决方法**:
```bash
# 1. 检查环境变量配置
cat .env | grep MYSQL

# 2. 重置 MySQL 容器
docker-compose -f docker-compose.ruijie.yaml down
docker volume rm rustdesk-api_mysql_data
docker-compose -f docker-compose.ruijie.yaml up -d
```

### 问题 2: OAuth 配置未生效

**现象**: 锐捷 SID 登录返回 "ConfigNotFound"

**解决方法**:
```bash
# 1. 检查数据库中的 OAuth 配置
docker exec -it rustdesk-mysql mysql -u rustdesk -p
USE rustdesk;
SELECT * FROM oauths WHERE op = 'ruijie_sid';

# 2. 如果配置不存在，手动插入
# 编辑 scripts/ruijie_sid_mysql_setup.sql 后重新执行
docker exec -i rustdesk-mysql mysql -u rustdesk -p rustdesk < scripts/ruijie_sid_mysql_setup.sql
```

### 问题 3: Swagger 文档显示错误

**现象**: 访问 Swagger 页面返回 404 或显示不完整

**解决方法**:
```bash
# 1. 重新生成 Swagger 文档
docker exec rustdesk-api /bin/sh -c "cd /app && swag init -g cmd/apimain.go --output ./docs/api --instanceName api"

# 2. 重启 API 服务
docker-compose -f docker-compose.ruijie.yaml restart rustdesk-api
```

### 问题 4: 容器启动失败

**现象**: `docker-compose ps` 显示服务 Exit

**解决方法**:
```bash
# 1. 查看详细错误日志
docker-compose -f docker-compose.ruijie.yaml logs rustdesk-api

# 2. 检查端口占用
netstat -tuln | grep 21114
netstat -tuln | grep 3306

# 3. 检查文件权限
ls -la config/ logs/
```

## 生产环境建议

### 1. 使用 HTTPS

在生产环境中，必须使用 HTTPS。建议使用 Nginx 反向代理:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:21114;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2. 数据持久化

确保数据卷在主机上有备份:

```yaml
# 在 docker-compose.ruijie.yaml 中修改
volumes:
  mysql_data:
    driver: local
    driver_opts:
      type: none
      device: /data/rustdesk/mysql
      o: bind
```

### 3. 资源限制

为容器设置资源限制:

```yaml
# 在 docker-compose.ruijie.yaml 中添加
services:
  rustdesk-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 4. 日志管理

配置日志轮转:

```yaml
# 在 docker-compose.ruijie.yaml 中添加
services:
  rustdesk-api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 5. 安全加固

- 修改默认端口
- 使用强密码
- 定期更新镜像
- 启用防火墙
- 配置 fail2ban

## 性能优化

### 1. MySQL 优化

在 `docker-compose.ruijie.yaml` 中添加 MySQL 配置:

```yaml
services:
  mysql:
    command:
      - --max_connections=500
      - --innodb_buffer_pool_size=1G
      - --query_cache_size=0
      - --query_cache_type=0
```

### 2. API 优化

设置环境变量:

```bash
# 在 .env 中添加
GIN_MODE=release
GOMAXPROCS=4
```

## 监控和告警

### 1. 使用 Prometheus + Grafana

```bash
# 可以添加 Prometheus 和 Grafana 服务
# 在 docker-compose.ruijie.yaml 中添加相关服务
```

### 2. 健康检查

Docker Compose 已配置健康检查:

```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:21114/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 技术支持

如有问题，请查看:
- RustDesk API: https://github.com/lejianwen/rustdesk-api/issues
- 锐捷 SID: https://sourceid.ruishan.cc/
- Ruijie SID OAuth 文档: `docs/RUIJIE_SID_OAUTH.md`
- MySQL 设置脚本: `scripts/ruijie_sid_mysql_setup.sql`

---

最后更新: 2026-01-08
