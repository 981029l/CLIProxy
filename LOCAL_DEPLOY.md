# Copyright (c) 2026 左岚. All rights reserved.
# CLI Proxy API 本地部署指南

## 快速启动

```bash
# 1. 进入项目目录
cd ~/Desktop/CLIProxyAPI

# 2. 编译
go build -o CLIProxyAPI-local ./cmd/server

# 3. 启动服务
./CLIProxyAPI-local
```

## 后台运行

```bash
# 后台启动（关闭终端不会停止）
./CLIProxyAPI-local &

# 查看运行状态
ps aux | grep CLIProxyAPI

# 停止服务
pkill -f CLIProxyAPI-local
```

## 访问地址

### 本机访问
| 地址 | 用途 |
|------|------|
| http://localhost:8317/management.html | 管理界面 |
| http://localhost:8317/v1/models | 模型列表 |
| http://localhost:8317/v1/chat/completions | 聊天接口 |

### 局域网访问（其他设备）
先获取本机 IP：
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
```

然后用 IP 替换 localhost，例如：
- `http://192.168.1.100:8317/management.html`
- `http://192.168.1.100:8317/v1/chat/completions`

## 配置文件

- 配置文件：`config.yaml`
- 认证文件目录：`~/.cli-proxy-api/`

## 管理密钥

在 `config.yaml` 中设置管理密钥：
```yaml
remote-management:
  allow-remote: true        # 允许远程访问管理界面
  secret-key: "your-password"  # 管理密钥
```

或通过环境变量设置：
```bash
MANAGEMENT_PASSWORD=your-password ./CLIProxyAPI-local
```

## 常用命令

```bash
# OAuth 登录（各平台）
./CLIProxyAPI-local -login              # Gemini
./CLIProxyAPI-local -codex-login        # Codex
./CLIProxyAPI-local -claude-login       # Claude
./CLIProxyAPI-local -antigravity-login  # Antigravity
```
