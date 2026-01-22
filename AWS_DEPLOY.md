# Copyright (c) 2026 左岚. All rights reserved.
# AWS EC2 部署指南

## 快速部署

### 1. 创建 EC2 实例

| 配置项 | 推荐值 |
|--------|--------|
| AMI | Ubuntu Server 24.04 LTS |
| 实例类型 | t3.small (2GB RAM) 或更高 |
| 安全组入站规则 | 22 (SSH), 80 (HTTP), 8317 (API) |

### 2. SSH 连接

```bash
chmod 400 ~/Desktop/your-key.pem
ssh -i ~/Desktop/your-key.pem ubuntu@YOUR_PUBLIC_IP
```

### 3. 安装依赖并部署

```bash
# 安装 Docker
sudo apt update && sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable docker && sudo systemctl start docker

# 克隆代码
cd ~ && git clone https://github.com/router-for-me/CLIProxyAPI.git
cd CLIProxyAPI

# 配置
cp config.example.yaml config.yaml
sed -i 's/allow-remote: false/allow-remote: true/' config.yaml
sed -i '0,/secret-key: ""/s//secret-key: "your-password"/' config.yaml

# 启动
sudo docker compose up -d
```

### 4. 访问

```
http://YOUR_PUBLIC_IP:8317/management.html
```

---

## 更新到最新版本

```bash
cd ~/CLIProxyAPI
git pull
sudo docker compose pull
sudo docker compose down && sudo docker compose up -d
```

---

## 常用命令

| 命令 | 说明 |
|------|------|
| `sudo docker ps` | 查看容器状态 |
| `sudo docker logs cli-proxy-api` | 查看日志 |
| `sudo docker compose restart` | 重启服务 |
| `sudo docker compose down` | 停止服务 |
| `sudo docker compose up -d` | 启动服务 |

---

## 故障排查

### 无法访问

1. 检查安全组是否开放 80/8317 端口
2. 检查容器状态：`sudo docker ps -a`
3. 检查日志：`sudo docker logs cli-proxy-api`

### 配置文件错误

```bash
rm config.yaml
cp config.example.yaml config.yaml
# 重新配置后重启
sudo docker compose restart
```
