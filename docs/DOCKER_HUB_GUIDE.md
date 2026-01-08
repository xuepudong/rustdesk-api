# Docker Hub 镜像构建和部署指南

本指南介绍如何在本地构建 Docker 镜像，推送到 Docker Hub，然后在服务器上直接使用预构建镜像部署。

## 优点

✅ **快速部署**: 服务器直接拉取镜像，无需编译
✅ **稳定可靠**: 本地构建成功后再推送，避免服务器构建失败
✅ **节省资源**: 服务器不需要安装 Go 编译环境
✅ **多服务器部署**: 一次构建，多处使用
✅ **��本管理**: 可以推送多个版本标签

---

## 前提条件

### 1. Docker Hub 账号

- 注册地址: https://hub.docker.com
- 用户名: `xuepudong`
- 仓库: https://hub.docker.com/r/xuepudong/rustdesk-api

### 2. 本地环境

**Windows 用户:**
- Docker Desktop for Windows (已安装)
- Git Bash 或 PowerShell

**Linux/macOS 用户:**
- Docker (已安装)
- Docker Compose

---

## 第一步: 本地构建并推送镜像

### Windows 用户

```batch
# 1. 打开命令提示符（CMD）
cd C:\Users\Administrator\Source\Repos\rustdesk-api

# 2. 运行构建脚本
build-and-push.bat

# 3. 输入 Docker Hub 密码
# （系统会提示输入密码）
```

### Linux/macOS 用户

```bash
# 1. 打开终端
cd /path/to/rustdesk-api

# 2. 添加执行权限
chmod +x build-and-push.sh

# 3. 运行构建��本
./build-and-push.sh

# 4. 输入 Docker Hub 密码
# （系统会提示输入密码）
```

### 构建过程

脚本会自动完成:

1. ✅ 检查 Docker 环境
2. ✅ 登录 Docker Hub
3. ✅ 构建 Docker 镜像（约 5-10 分钟）
4. ✅ 添加版本标签（latest 和 v1.0.0）
5. ✅ 推送镜像到 Docker Hub

### 构建成功的标志

```
============================================
  推送成功！
============================================

[INFO] 镜像信息:
  - 仓库: https://hub.docker.com/r/xuepudong/rustdesk-api
  - 镜像: xuepudong/rustdesk-api:latest
  - 版本: xuepudong/rustdesk-api:v1.0.0

[INFO] 镜像大小:
REPOSITORY                TAG       IMAGE ID       CREATED         SIZE
xuepudong/rustdesk-api    latest    abc123def456   2 minutes ago   45.3MB
xuepudong/rustdesk-api    v1.0.0    abc123def456   2 minutes ago   45.3MB
```

---

## 第二步: 在服务器上部署

### 方案 A: 使用 docker-compose-hub.yaml（推荐）

这是最简单的方法，直接使用 Docker Hub 的预构建镜像。

```bash
# 1. SSH 连接到腾讯云服务器
ssh root@YOUR_SERVER_IP

# 2. 进入部署目录
cd /opt/rustdesk-api

# 3. 拉取最新代码
git pull

# 4. 确保 .env 文件配置正确
cat .env

# 5. 停止旧服务
docker compose -f docker-compose-hub.yaml down

# 6. 拉取最新镜像
docker pull xuepudong/rustdesk-api:latest

# 7. 启动服务
docker compose -f docker-compose-hub.yaml up -d

# 8. 查看日志
docker compose -f docker-compose-hub.yaml logs -f
```

### 方案 B: 手动拉取镜像

```bash
# 1. 拉取镜像
docker pull xuepudong/rustdesk-api:latest

# 2. 运行容器
docker run -d \
  --name rustdesk-api \
  -p 21114:21114 \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_NAME=rustdesk \
  -e DB_USER=rustdesk \
  -e DB_PASSWORD=your_password \
  -e API_SERVER=https://rd.jiecloud.com.cn \
  -e RUIJIE_SID_BASE_URL=https://sid.ruijie.com.cn \
  -e RUIJIE_SID_CLIENT_ID=ruijiedesk \
  -e RUIJIE_SID_CLIENT_SECRET=your_secret \
  xuepudong/rustdesk-api:latest
```

---

## 第三步: 验证部署

### 1. 检查容器状态

```bash
docker compose -f docker-compose-hub.yaml ps

# 应该看到:
# rustdesk-mysql    Up (healthy)
# rustdesk-api      Up (healthy)
```

### 2. 检查 API 健康状态

```bash
curl http://localhost:21114/api/health

# 应返回: {"status":"ok"}
```

### 3. 查看 Docker Hub 仓库

访问: https://hub.docker.com/r/xuepudong/rustdesk-api

确认镜像已成功推送。

---

## 更新镜像

### 在本地构建新版本

```bash
# Windows
build-and-push.bat

# Linux/macOS
./build-and-push.sh
```

### 在服务器上更新

```bash
cd /opt/rustdesk-api

# 拉取最新镜像
docker pull xuepudong/rustdesk-api:latest

# 重启服务
docker compose -f docker-compose-hub.yaml down
docker compose -f docker-compose-hub.yaml up -d
```

---

## 版本管理

### 推送特定版本

编辑构建脚本，修改版本号:

```bash
# build-and-push.bat 或 build-and-push.sh
IMAGE_TAG_VERSION="v1.0.1"  # 修改版本号
```

然后运行构建脚本。

### 在服务器上使用特定版本

修改 `docker-compose-hub.yaml`:

```yaml
rustdesk-api:
  image: xuepudong/rustdesk-api:v1.0.0  # 指定版本
  # image: xuepudong/rustdesk-api:latest  # 或使用最新版
```

---

## 镜像信息

### 查看本地镜像

```bash
# 列出镜像
docker images xuepudong/rustdesk-api

# 查看镜像详情
docker inspect xuepudong/rustdesk-api:latest
```

### 删除本地镜像

```bash
# 删除特定版本
docker rmi xuepudong/rustdesk-api:v1.0.0

# 删除所有版本
docker rmi xuepudong/rustdesk-api:latest
docker rmi xuepudong/rustdesk-api:v1.0.0
```

### 删除 Docker Hub 镜像

1. 访问: https://hub.docker.com/r/xuepudong/rustdesk-api/tags
2. 选择要删除的标签
3. 点击删除按钮

---

## 配置文件对比

### docker-compose.ruijie.yaml（本地构建）

```yaml
rustdesk-api:
  build:
    context: .
    dockerfile: Dockerfile.simple
  # 从本地代码构建镜像
```

**优点**:
- 使用最新代码
- 可以修改代码后立即构建

**缺点**:
- 构建时间长（3-5 分钟）
- 需要编译环境
- 可能遇到构建错误

### docker-compose-hub.yaml（使用 Docker Hub）

```yaml
rustdesk-api:
  image: xuepudong/rustdesk-api:latest
  # 直接使用 Docker Hub 镜像
```

**优点**:
- 部署超快（拉取镜像 < 1 分钟）
- 不需要编译环境
- 稳定可靠

**缺点**:
- 需要先在本地构建并推送
- 镜像更新需要两步（本地推送 + 服务器拉取）

---

## 故障排查

### 问题 1: Docker Hub 登录失败

**解决方法**:

```bash
# 手动登录
docker login

# 输入用户名: xuepudong
# 输入密码: [你的 Docker Hub 密码]
```

### 问题 2: 推送失败（权限不足）

**原因**: 没有登录或用户名错误

**解决方法**:

```bash
# 确认登录状态
docker info | grep Username

# 重新登录
docker logout
docker login
```

### 问题 3: 镜像拉取失败

**原因**: 网络问题或镜像不存在

**解决方法**:

```bash
# 检查镜像是否存在
curl https://hub.docker.com/v2/repositories/xuepudong/rustdesk-api/tags

# 使用镜像加速器（国内服务器）
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}

# 重启 Docker
sudo systemctl restart docker
```

### 问题 4: 构建时间过长

**原因**: 下载依赖慢

**解决方法**:

```bash
# 使用 Go 代理（仅限构建阶段）
# 编辑 Dockerfile.simple，在 go mod download 前添加:
ENV GOPROXY=https://goproxy.cn,direct
```

---

## 常用命令

### 本地命令

```bash
# 构建镜像
docker build -f Dockerfile.simple -t xuepudong/rustdesk-api:latest .

# 推送镜像
docker push xuepudong/rustdesk-api:latest

# 测试镜像
docker run --rm xuepudong/rustdesk-api:latest ./rustdesk-api --version
```

### 服务器命令

```bash
# 拉取镜像
docker pull xuepudong/rustdesk-api:latest

# 查看镜像
docker images xuepudong/rustdesk-api

# 运行容器
docker run -d --name rustdesk-api xuepudong/rustdesk-api:latest

# 查看日志
docker logs -f rustdesk-api
```

---

## 安全建议

### 1. 使用私有仓库（可选）

如果不想公开镜像:

1. 在 Docker Hub 创建私有仓库
2. 修改构建脚本中的仓库名
3. 在服务器上拉取前先登录

### 2. 扫描镜像漏洞

```bash
# 使用 Docker Scout 扫描
docker scout cves xuepudong/rustdesk-api:latest
```

### 3. 不要在镜像中包含敏感信息

- ❌ 不要硬编码密码
- ❌ 不要包含 .env 文件
- ✅ 使用环境变量传递配置

---

## 相关链接

- **Docker Hub 仓库**: https://hub.docker.com/r/xuepudong/rustdesk-api
- **GitHub 仓库**: https://github.com/xuepudong/rustdesk-api
- **Docker Hub 文档**: https://docs.docker.com/docker-hub/
- **Docker 镜像最佳实践**: https://docs.docker.com/develop/dev-best-practices/

---

最后更新: 2026-01-08
