@echo off
REM ============================================
REM RustDesk API with Ruijie SID - Windows 部署脚本
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ============================================
echo   RustDesk API with Ruijie SID - 部署脚本
echo ============================================
echo.

REM 检查 Docker
echo [INFO] 检查环境依赖...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未安装，请先安装 Docker Desktop
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    docker compose version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Docker Compose 未安��
        pause
        exit /b 1
    )
)

echo [SUCCESS] 环境检查通过
echo.

REM 检查配置文件
echo [INFO] 检查配置文件...
if not exist ".env" (
    echo [WARNING] .env 文件不存在，正在从模板创建...
    copy .env.ruijie.example .env
    echo.
    echo [WARNING] 请编辑 .env 文件，配置以下必要信息:
    echo   - MYSQL_ROOT_PASSWORD
    echo   - MYSQL_PASSWORD
    echo   - API_SERVER
    echo   - RUIJIE_SID_CLIENT_ID
    echo   - RUIJIE_SID_CLIENT_SECRET
    echo.
    pause
    notepad .env
)

REM 检查默认值
findstr /C:"YOUR_CLIENT_ID_HERE" .env >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] .env 文件中仍包含默认值
    set /p continue="是否继续部署？(y/N): "
    if /i not "!continue!"=="y" (
        echo [INFO] 部署已取消
        pause
        exit /b 0
    )
)

echo [SUCCESS] 配置文件检查完成
echo.

REM 检查数据库初始化脚本
echo [INFO] 检查数据库初始化脚本...
findstr /C:"YOUR_CLIENT_ID_HERE" scripts\ruijie_sid_mysql_setup.sql >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] scripts\ruijie_sid_mysql_setup.sql 中包含默认值
    echo [WARNING] 请编辑以下内容:
    echo   - 第 185 行: YOUR_CLIENT_ID_HERE
    echo   - 第 186 行: YOUR_CLIENT_SECRET_HERE
    echo   - 第 219 行: 管理员密码哈希
    echo.
    set /p edit="是否编辑数据库初始化脚本？(y/N): "
    if /i "!edit!"=="y" (
        notepad scripts\ruijie_sid_mysql_setup.sql
    )
)

echo [SUCCESS] 数据库脚本检查完成
echo.

REM 询问是否构建
echo [INFO] 准备构建 Docker 镜像
set /p build="是否开始构建？(y/N): "
if /i not "!build!"=="y" (
    echo [INFO] 部署已取消
    pause
    exit /b 0
)

REM 构建镜像
echo.
echo [INFO] 开始构建 Docker 镜像...
docker-compose -f docker-compose.ruijie.yaml build --no-cache
if errorlevel 1 (
    echo [ERROR] Docker 镜像构建失败
    pause
    exit /b 1
)

echo [SUCCESS] Docker 镜像构建完成
echo.

REM 询问是否启动 phpMyAdmin
set /p phpmyadmin="是否启动 phpMyAdmin？(y/N): "

REM 启动服务
echo.
echo [INFO] 启动服务...
if /i "!phpmyadmin!"=="y" (
    docker-compose -f docker-compose.ruijie.yaml --profile tools up -d
) else (
    docker-compose -f docker-compose.ruijie.yaml up -d
)

if errorlevel 1 (
    echo [ERROR] 服务启动失败
    pause
    exit /b 1
)

echo [SUCCESS] 服务启动完成
echo.

REM 等待服务就绪
echo [INFO] 等待服务就绪...
timeout /t 10 /nobreak >nul

REM 检查服务状态
echo [INFO] 检查服务状态...
docker-compose -f docker-compose.ruijie.yaml ps

REM 验证部署
echo.
echo [INFO] 验证部署...

REM 等待 API 服务启动
timeout /t 5 /nobreak >nul

REM 检查健康状态
echo [INFO] 检查 API 健康状态...
curl -s http://localhost:21114/api/health 2>nul | findstr "ok" >nul
if not errorlevel 1 (
    echo [SUCCESS] API 健康检查通过
) else (
    echo [WARNING] API 健康检查失败，服务可能还在启动中
)

REM 显示部署信息
echo.
echo ============================================
echo   部署完成！
echo ============================================
echo.
echo [INFO] 服务地址:
echo   - API 服务: http://localhost:21114
echo   - API 文档: http://localhost:21114/swagger/api/index.html
echo   - 管理后台: http://localhost:21114/swagger/admin/index.html

if /i "!phpmyadmin!"=="y" (
    echo   - phpMyAdmin: http://localhost:8080
)

echo.
echo [INFO] 常用命令:
echo   - 查看日志: docker-compose -f docker-compose.ruijie.yaml logs -f
echo   - 重启服务: docker-compose -f docker-compose.ruijie.yaml restart
echo   - 停止服务: docker-compose -f docker-compose.ruijie.yaml down
echo.
echo [INFO] 详细文档: docs\DOCKER_DEPLOYMENT.md
echo.

pause
