#!/bin/bash
# 在腾讯云服务器上运行此脚本来更新和重新部署

echo "正在更新代码..."
cd /opt/rustdesk-api
git pull

echo "正在重新构建并启动服务..."
docker compose -f docker-compose.ruijie.yaml down
docker compose -f docker-compose.ruijie.yaml up -d --build

echo "等待服务启动..."
sleep 10

echo "检查服务状态..."
docker compose -f docker-compose.ruijie.yaml ps

echo "查看日志..."
docker compose -f docker-compose.ruijie.yaml logs --tail=50
