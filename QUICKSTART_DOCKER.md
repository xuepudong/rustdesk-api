# RustDesk API with Ruijie SID - 快速入门

## 📦 已创建的 Docker 部署文件

本次为你创建了以下 Docker 部署相关文件:

### 核心文件

1. **`Dockerfile.ruijie`** - 生产级 Docker 镜像定义
   - 多阶段构建（前端 + 后端）
   - 自动生成 Swagger 文档
   - 基于 Alpine Linux（体积小）
   - 包含健康检查

2. **`docker-compose.ruijie.yaml`** - Docker Compose 编排配置
   - MySQL 8.0 数据库
   - RustDesk API 服务
   - phpMyAdmin 管理工具（可选）
   - 自动初始化数据库
   - 健康检查和依赖管理

3. **`.env.ruijie.example`** - 环境变量配置模板
   - MySQL 数据库配置
   - API 服务配置
   - 锐捷 SID OAuth 配置
   - 其他环境变量

### 部署脚本

4. **`deploy-ruijie.sh`** - Linux/macOS 一键部署脚本
   - 自动检查环境依赖
   - 自动检查配置文件
   - 交互式部署流程
   - 自动验证部署结果

5. **`deploy-ruijie.bat`** - Windows 一键部署脚本
   - 与 Linux 版本功能相同
   - 适配 Windows 命令行

### 文档

6. **`docs/DOCKER_DEPLOYMENT.md`** - 完整的 Docker 部署指南
   - 详细的部署步骤
   - 常见问题排查
   - 生产环境建议
   - 性能优化指南
   - 监控和告警

## 🚀 快速开始

### Linux/macOS

```bash
# 1. 复制环境变量配置
cp .env.ruijie.example .env

# 2. 编辑配置文件（必须修改）
vim .env

# 3. 修改数据库初始化脚本中的 OAuth 配置（必须修改）
vim scripts/ruijie_sid_mysql_setup.sql

# 4. 运行一键部署脚本
./deploy-ruijie.sh
```

### Windows

```batch
# 1. 复制环境变量配置
copy .env.ruijie.example .env

# 2. 编辑配置文件（必须修改）
notepad .env

# 3. 修改数据库初始化脚本中的 OAuth 配置（必须修改）
notepad scripts\ruijie_sid_mysql_setup.sql

# 4. 运行一键部署脚本
deploy-ruijie.bat
```

## 📝 配置说明

### 1. 环境变量配置 (`.env`)

**必须修改的配置:**

```bash
# MySQL 密码（安全！）
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_password

# API 服务器地址（重要！）
API_SERVER=https://your-domain.com

# 锐捷 SID OAuth 配置（核心！）
RUIJIE_SID_CLIENT_ID=your_actual_client_id
RUIJIE_SID_CLIENT_SECRET=your_actual_client_secret

# 如果使用私有部署的锐捷 SID，修改此项
RUIJIE_SID_BASE_URL=https://sourceid.ruishan.cc
```

**可选配置:**

```bash
# 端口配置
API_PORT=21114
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080

# RustDesk 服务器配置（如果有）
RUSTDESK_ID_SERVER=
RUSTDESK_RELAY_SERVER=
RUSTDESK_KEY=
```

### 2. 数据库初始化脚本 (`scripts/ruijie_sid_mysql_setup.sql`)

**必须修改的位置:**

```sql
-- 第 185-187 行: 锐捷 SID OAuth 配置
INSERT INTO `oauths` (...) VALUES (
    'ruijie_sid',
    'ruijie_sid',
    'YOUR_CLIENT_ID_HERE',          -- 【必改】实际的 Client ID
    'YOUR_CLIENT_SECRET_HERE',      -- 【必改】实际的 Client Secret
    'https://sourceid.ruishan.cc',  -- 【可改】SID 服务器地址
    ...
);

-- 第 219 行: 管理员密码
'$2a$10$YourBcryptHashHere',  -- 【必改】实际的 bcrypt 密码哈希
```

**生成 bcrypt 密码哈希:**

```bash
# 使用 Python
python3 -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt()).decode())"

# 或使用在线工具
# https://bcrypt-generator.com/
```

## 🔧 手动部署（不使用脚本）

如果你想手动控制每一步:

```bash
# 1. 更新依赖
go mod tidy

# 2. 构建 Docker 镜像
docker-compose -f docker-compose.ruijie.yaml build --no-cache

# 3. 启动服务（不包含 phpMyAdmin）
docker-compose -f docker-compose.ruijie.yaml up -d

# 或启动包含 phpMyAdmin
docker-compose -f docker-compose.ruijie.yaml --profile tools up -d

# 4. 查看日志
docker-compose -f docker-compose.ruijie.yaml logs -f

# 5. 检查服务状态
docker-compose -f docker-compose.ruijie.yaml ps
```

## ✅ 验证部署

### 1. 检查服务状态

```bash
docker-compose -f docker-compose.ruijie.yaml ps
```

应该看到:
- `rustdesk-mysql` (healthy)
- `rustdesk-api` (healthy)

### 2. 检查 API 健康状态

```bash
curl http://localhost:21114/api/health
```

应该返回: `{"status":"ok"}`

### 3. 访问 Swagger 文档

- API 文档: http://localhost:21114/swagger/api/index.html
- 管理后台文档: http://localhost:21114/swagger/admin/index.html

### 4. 测试锐捷 SID OAuth

```bash
# 获取 OAuth 配置列表
curl http://localhost:21114/api/oauth/providers

# 应该看到 "ruijie_sid" 在列表中
```

### 5. 查看数据库配置

```bash
# 连接到 MySQL
docker exec -it rustdesk-mysql mysql -u rustdesk -p

# 执行 SQL
USE rustdesk;
SELECT op, oauth_type, client_id, issuer FROM oauths WHERE op = 'ruijie_sid';
```

## 📊 服务管理

### 查看日志

```bash
# 查看所有服务日志
docker-compose -f docker-compose.ruijie.yaml logs -f

# 查看 API 日志
docker-compose -f docker-compose.ruijie.yaml logs -f rustdesk-api

# 查看 MySQL 日志
docker-compose -f docker-compose.ruijie.yaml logs -f mysql
```

### 重启服务

```bash
# 重启所有服务
docker-compose -f docker-compose.ruijie.yaml restart

# 重启 API 服务
docker-compose -f docker-compose.ruijie.yaml restart rustdesk-api
```

### 停止服务

```bash
# 停止服务（保留数据）
docker-compose -f docker-compose.ruijie.yaml down

# 停止并删除数据卷（⚠️ 会删除所有数据！）
docker-compose -f docker-compose.ruijie.yaml down -v
```

### 更新代码

```bash
# 1. 停止服务
docker-compose -f docker-compose.ruijie.yaml down

# 2. 拉取最新代码
git pull

# 3. 重新构建
docker-compose -f docker-compose.ruijie.yaml build --no-cache

# 4. 启动服务
docker-compose -f docker-compose.ruijie.yaml up -d
```

## 🌐 生产环境部署

### 1. 使用 HTTPS

建议使用 Nginx 反向代理:

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

### 2. 修改 API_SERVER 配置

在 `.env` 中:

```bash
API_SERVER=https://your-domain.com
```

### 3. 在锐捷 SID 管理平台配置回调地址

```
https://your-domain.com/api/oidc/callback
```

## 🔍 故障排查

### 问题 1: MySQL 连接失败

```bash
# 检查 MySQL 状态
docker-compose -f docker-compose.ruijie.yaml ps mysql

# 查看 MySQL 日志
docker-compose -f docker-compose.ruijie.yaml logs mysql

# 重启 MySQL
docker-compose -f docker-compose.ruijie.yaml restart mysql
```

### 问题 2: OAuth 配置未生效

```bash
# 检查数据库中的 OAuth 配置
docker exec -it rustdesk-mysql mysql -u rustdesk -p
USE rustdesk;
SELECT * FROM oauths WHERE op = 'ruijie_sid';
```

### 问题 3: Swagger 文档显示错误

```bash
# 重新生成 Swagger 文档
docker exec rustdesk-api /bin/sh -c "swag init -g cmd/apimain.go --output ./docs/api --instanceName api"

# 重启 API 服务
docker-compose -f docker-compose.ruijie.yaml restart rustdesk-api
```

## 📚 相关文档

- **完整部署指南**: `docs/DOCKER_DEPLOYMENT.md`
- **锐捷 SID OAuth 文档**: `docs/RUIJIE_SID_OAUTH.md`
- **OAuth 流程说明**: `docs/OAUTH_FLOW.md`
- **Swagger 编写规范**: `docs/SWAGGER_GUIDELINES.md`
- **数据库初始化脚本**: `scripts/ruijie_sid_mysql_setup.sql`

## 🎯 下一步

1. **配置锐捷 SID**
   - 在锐捷 SID 管理平台注册应用
   - 获取 Client ID 和 Client Secret
   - 配置回调地址: `https://your-domain.com/api/oidc/callback`

2. **测试 OAuth 登录**
   - 访问: `http://localhost:21114/api/oidc/login?op=ruijie_sid&action=login&id=test&uuid=test123`
   - 完成授权流程
   - 验证用户信息

3. **部署到生产环境**
   - 配置 HTTPS
   - 修改 API_SERVER
   - 启用防火墙
   - 配置监控

## 💡 提示

- **首次部署**: 使用 `deploy-ruijie.sh` 或 `deploy-ruijie.bat` 自动部署
- **生产环境**: 仔细阅读 `docs/DOCKER_DEPLOYMENT.md`
- **故障排查**: 先查看日志 `docker-compose -f docker-compose.ruijie.yaml logs`
- **数据备份**: 定期备份 MySQL 数据卷

## 📞 技术支持

- RustDesk API: https://github.com/lejianwen/rustdesk-api/issues
- 锐捷 SID: https://sourceid.ruishan.cc/

---

最后更新: 2026-01-08
