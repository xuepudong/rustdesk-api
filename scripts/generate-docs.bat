@echo off
REM RustDesk API - Swagger 文档生成脚本 (Windows)
REM
REM 此脚本用于生成 Swagger API 文档
REM 需要安装 swag 工具: go install github.com/swaggo/swag/cmd/swag@latest
REM

echo ========================================
echo RustDesk API - Swagger 文档生成
echo ========================================
echo.

REM 检查 swag 命令是否存在
where swag >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 swag 命令
    echo 请先安装 swag 工具:
    echo   go install github.com/swaggo/swag/cmd/swag@latest
    echo.
    pause
    exit /b 1
)

echo [信息] 检测到 swag 工具
echo.

REM 切换到项目根目录
cd /d "%~dp0.."

echo [步骤 1/2] 生成 API 文档 (Client API)...
swag init --parseDependency --parseInternal --instanceName api --dir cmd,http,model,service --generalInfo cmd/apimain.go --output docs/api

if %ERRORLEVEL% NEQ 0 (
    echo [错误] API 文档生成失败
    pause
    exit /b 1
)

echo [成功] API 文档生成完成: docs/api/
echo.

echo [步骤 2/2] 生成 Admin 文档 (管理后台)...
swag init --parseDependency --parseInternal --instanceName admin --dir cmd,http,model,service --generalInfo cmd/apimain.go --output docs/admin

if %ERRORLEVEL% NEQ 0 (
    echo [错误] Admin 文档生成失败
    pause
    exit /b 1
)

echo [成功] Admin 文档生成完成: docs/admin/
echo.

echo ========================================
echo 文档生成完成！
echo ========================================
echo.
echo 生成的文档:
echo   - API 文档: docs/api/
echo   - Admin 文档: docs/admin/
echo.
echo 启动项目后访问 Swagger UI:
echo   - API: http://localhost:21114/swagger/index.html
echo   - Admin: http://localhost:21114/admin/swagger/index.html
echo.
pause
