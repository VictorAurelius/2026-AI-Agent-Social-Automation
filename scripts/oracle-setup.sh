#!/bin/bash
# Oracle Cloud Free Tier - Server Setup Script
# Usage: Run on fresh Ubuntu 22.04 ARM64 VM
# ssh -i key.pem ubuntu@<ip> 'bash -s' < scripts/oracle-setup.sh

set -e

echo "========================================"
echo "  Oracle Cloud Setup - AI Agent"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: System update
echo -e "\n${YELLOW}[1/7] Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker
echo -e "\n${YELLOW}[2/7] Installing Docker...${NC}"
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Step 3: Install Nginx + Certbot
echo -e "\n${YELLOW}[3/7] Installing Nginx + Certbot...${NC}"
sudo apt install -y nginx certbot python3-certbot-nginx

# Step 4: Install utilities
echo -e "\n${YELLOW}[4/7] Installing utilities...${NC}"
sudo apt install -y jq git htop fail2ban

# Step 5: Configure fail2ban
echo -e "\n${YELLOW}[5/7] Configuring fail2ban...${NC}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Step 6: Configure firewall
echo -e "\n${YELLOW}[6/7] Configuring firewall...${NC}"
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p icmp -j ACCEPT
# Don't apply DROP rule automatically - let user confirm
echo -e "${YELLOW}WARNING: Run 'sudo iptables -A INPUT -j DROP' manually after verifying SSH works${NC}"

# Step 7: Create directories
echo -e "\n${YELLOW}[7/7] Creating directories...${NC}"
mkdir -p ~/logs ~/backups

echo -e "\n${GREEN}========================================"
echo "  Setup Complete!"
echo "========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Clone repo:"
echo "     git clone https://github.com/VictorAurelius/2026-AI-Agent-Social-Automation.git"
echo "  2. Setup Docker:"
echo "     cd 2026-AI-Agent-Social-Automation && bash scripts/setup.sh"
echo "  3. Pull Qwen2 14B:"
echo "     docker exec ollama ollama pull qwen2:14b"
echo "  4. Setup Nginx (see documents/02-architecture/design-oracle-cloud-migration.md)"
echo "  5. Get SSL: sudo certbot --nginx -d your-domain.com"
echo ""
