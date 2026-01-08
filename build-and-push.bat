@echo off
REM ============================================
REM 本地构建 Docker 镜像并推送到 Docker Hub
REM ============================================
REM 使用说明:
REM   1. 确保 Docker Desktop 正在运行
REM   2. 运行此脚本: build-and-push.bat
REM   3. 输入 Docker Hub 密码
REM ============================================

setlocal enabledelayedexpansion

REM 配置信息
set DOCKER_USERNAME=xuepudong
set IMAGE_NAME=rustdesk-api
set IMAGE_TAG=latest
set IMAGE_TAG_VERSION=v1.0.0

echo.
echo ============================================
echo   RustDesk API - 构建并推送到 Docker Hub
echo ============================================
echo.

REM 检查 Docker
echo [INFO] 检查 Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未运行，请启动 Docker Desktop
    pause
    exit /b 1
)
echo [SUCCESS] Docker 已运行
echo.

REM 登录 Docker Hub
echo [INFO] 登录 Docker Hub...
echo 用户名: %DOCKER_USERNAME%
docker login -u %DOCKER_USERNAME%
if errorlevel 1 (
    echo [ERROR] Docker Hub 登录失败
    pause
    exit /b 1
)
echo [SUCCESS] 登录成功
echo.

REM 构建镜像
echo [INFO] 开始构建 Docker 镜像...
echo 这可能需要 5-10 分钟，请耐心等待...
echo.

docker build -f Dockerfile.simple -t %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG% .
if errorlevel 1 (
    echo [ERROR] 镜像构建失败
    pause
    exit /b 1
)
echo.
echo [SUCCESS] 镜像构建完成
echo.

REM 添加版本标签
echo [INFO] 添加版本标签...
docker tag %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG% %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG_VERSION%
echo [SUCCESS] 标签添加完成
echo.

REM 推送镜像
echo [INFO] 推送镜像到 Docker Hub...
echo 推送 %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%
if errorlevel 1 (
    echo [ERROR] 镜像推送失败
    pause
    exit /b 1
)
echo.

echo [INFO] 推送版本标签...
echo 推送 %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG_VERSION%
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG_VERSION%
if errorlevel 1 (
    echo [ERROR] 版本标签推送失败
    pause
    exit /b 1
)
echo.

REM 显示镜像信息
echo ============================================
echo   推送成功！
echo ============================================
echo.
echo [INFO] 镜像信息:
echo   - 仓库: https://hub.docker.com/r/%DOCKER_USERNAME%/%IMAGE_NAME%
echo   - 镜像: %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%
echo   - 版本: %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG_VERSION%
echo.
echo [INFO] 镜像大小:
docker images %DOCKER_USERNAME%/%IMAGE_NAME%
echo.
echo [INFO] 在服务器上使用:
echo   docker pull %DOCKER_USERNAME%/%IMAGE_NAME%:%IMAGE_TAG%
echo   或使用 docker-compose-hub.yaml 部署
echo.

pause
