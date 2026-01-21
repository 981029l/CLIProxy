#!/bin/bash

# CLI Proxy API - One-Click Setup Script for AWS EC2 (Ubuntu)
# Only supports Ubuntu 20.04/22.04/24.04

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}    CLI Proxy API - AWS EC2 Auto Setup (Ubuntu)   ${NC}"
echo -e "${BLUE}============================================================${NC}"

# 1. Check OS
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}Error: OS detection failed. This script expects Ubuntu.${NC}"
    exit 1
fi
source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    echo -e "${RED}Error: This script is designed for Ubuntu. You are using $ID.${NC}"
    echo -e "${RED}Please create an EC2 instance using the 'Ubuntu Server' AMI.${NC}"
    exit 1
fi

echo -e "${GREEN}[1/5] Updating system packages...${NC}"
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y git curl ca-certificates gnupg lsb-release

# 2. Install Docker
echo -e "${GREEN}[2/5] Checking/Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    # Start Docker and enable on boot
    sudo systemctl start docker
    sudo systemctl enable docker
    # Add current user to docker group
    sudo usermod -aG docker paramiko 2>/dev/null || sudo usermod -aG docker ubuntu
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# 3. Clone Repository
REPO_URL="https://github.com/981029l/CLIProxy.git"
INSTALL_DIR="/home/ubuntu/CLIProxy"

echo -e "${GREEN}[3/5] Cloning repository...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Directory $INSTALL_DIR already exists. Pulling latest code...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 4. Generate Random Secret (if needed) or Setup Basic Config
# Note: In production, you might want to ask user for keys. 
# For now, we assume defaults or user edits config.yaml later.

# 5. Build and Run
echo -e "${GREEN}[4/5] Building and starting service...${NC}"

# Ensure we have the start script or just use docker compose
if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
    # Create empty config if not exists
    if [ ! -f "config/config.yaml" ]; then
        echo -e "${BLUE}Creating default config/config.yaml...${NC}"
        mkdir -p config
        cp config/config.example.yaml config/config.yaml 2>/dev/null || touch config/config.yaml
    fi

    # Configure Upstream Remote for Updates
    echo -e "${GREEN}[3.5/5] Configuring official update source...${NC}"
    git remote add upstream https://github.com/router-for-me/CLIProxyAPI.git 2>/dev/null || git remote set-url upstream https://github.com/router-for-me/CLIProxyAPI.git
    git fetch upstream

    # Create simplified update script
    cat > update.sh << 'EOF'
#!/bin/bash
echo "Pulling latest code from official repository..."
git pull upstream main
echo "Rebuilding and restarting service..."
sudo docker compose up -d --build
echo "Update complete!"
EOF
    chmod +x update.sh
    
    # Run with Docker Compose
    sudo docker compose up -d --build
    
    echo -e "${GREEN}[5/5] Deployment Complete!${NC}"
    echo -e "${BLUE}============================================================${NC}"
    
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || echo "YOUR_SERVER_IP")
    
    echo -e "Service is running!"
    echo -e "Access via IP:"
    echo -e "  Management: ${GREEN}http://${PUBLIC_IP}:8317/management.html${NC}"
    echo -e "  API Base:   ${GREEN}http://${PUBLIC_IP}:8317/v1${NC}"
    echo -e ""
    echo -e "Access via Domain (if configured):"
    echo -e "  Management: ${GREEN}http://your-domain.com/management.html${NC}"
    echo -e ""
    echo -e "${RED}IMPORTANT: Ensure AWS Security Group allows TCP port 8317 AND 80!${NC}"
    echo -e "${BLUE}============================================================${NC}"

else
    echo -e "${RED}Error: docker-compose.yml not found in repository.${NC}"
    exit 1
fi
