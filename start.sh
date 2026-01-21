#!/bin/bash
# Copyright (c) 2026 左岚. All rights reserved.
# CLI Proxy API 一键启动脚本

cd "$(dirname "$0")"

# 停止旧进程
pkill -f CLIProxyAPI-local 2>/dev/null
pkill -f "ngrok http" 2>/dev/null

# 编译（注入版本号）
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
go build -ldflags="-s -w -X 'main.Version=${VERSION}' -X 'main.Commit=${COMMIT}' -X 'main.BuildDate=${BUILD_DATE}'" -o CLIProxyAPI-local ./cmd/server

# 启动服务
./CLIProxyAPI-local &
sleep 2

# 启动内网穿透
ngrok http 8317 --log=stdout > /tmp/ngrok.log 2>&1 &
sleep 3

# 获取公网地址 (尝试多次)
sleep 2
URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$URL" ]; then
    sleep 2
    URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*"' | head -1 | cut -d'"' -f4)
fi

# 获取本机局域网 IP
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo "=================================================="
echo "✅ CLI Proxy API 服务已启动 (版本: ${VERSION})"
echo "=================================================="
echo "🖥️  Local (本机访问):"
echo "   - 管理界面: http://localhost:8317/management.html"
echo "   - API 接口: http://localhost:8317/v1/chat/completions"
echo ""
echo "🏠 LAN (局域网访问):"
echo "   - 管理界面: http://${LOCAL_IP}:8317/management.html"
echo "   - API 接口: http://${LOCAL_IP}:8317/v1/chat/completions"
echo ""
echo "🌏 Public (公网访问):"
if [ -n "$URL" ]; then
    echo "   - 管理界面: ${URL}/management.html"
    echo "   - API 接口: ${URL}/v1/chat/completions"
else
    echo "   - (未获取到公网地址，ngrok 可能启动失败)"
fi
echo "=================================================="
echo "🔑 管理密钥: admin123"
echo "=================================================="
