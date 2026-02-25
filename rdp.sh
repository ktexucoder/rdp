#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "==========================================="
echo "      Ubuntu RDP Installer (NO KVM)"
echo "==========================================="
echo -e "${NC}"

sleep 2

echo -e "${CYAN}Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${CYAN}Installing Desktop Environment...${NC}"
sudo apt install ubuntu-desktop-minimal -y

echo -e "${CYAN}Installing XRDP...${NC}"
sudo apt install xrdp -y

echo -e "${CYAN}Configuring XRDP...${NC}"
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Allow RDP port
echo -e "${CYAN}Opening firewall port 3389...${NC}"
sudo ufw allow 3389/tcp 2>/dev/null

# Fix black screen issue
echo -e "${CYAN}Fixing XRDP session...${NC}"
echo "gnome-session" > ~/.xsession

# Get Public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo -e "${GREEN}"
echo "==========================================="
echo "      INSTALLATION COMPLETE"
echo "==========================================="
echo -e "${NC}"

echo -e "${YELLOW}RDP Address:${NC} $PUBLIC_IP"
echo -e "${YELLOW}Username:${NC} $(whoami)"
echo -e "${YELLOW}Password:${NC} (Password user VPS kamu)"
echo
echo -e "${CYAN}Gunakan Remote Desktop Connection (mstsc)${NC}"
echo -e "${CYAN}Port: 3389${NC}"
