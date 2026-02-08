#!/bin/bash

# ===================== COLORS =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}"
cat << "EOF"
$$\   $$\ $$$$$$$$\      $$$$$$$$\           $$\                                       $$\
$$$\  $$ |\__$$  __|     $$  _____|          $$ |                                      $$ |
$$$$\ $$ |   $$ |        $$ |      $$\   $$\ $$$$$$$\   $$$$$$\  $$\   $$\  $$$$$$$\ $$$$$$\
$$ $$\$$ |   $$ |$$$$$$\ $$$$$\    \$$\ $$  |$$  __$$\  \____$$\ $$ |  $$ |$$  _____|\_$$  _|
$$ \$$$$ |   $$ |\______|$$  __|    \$$$$  / $$ |  $$ | $$$$$$$ |$$ |  $$ |\$$$$$$\    $$ |
$$ |\$$$ |   $$ |        $$ |       $$  $$<  $$ |  $$ |$$  __$$ |$$ |  $$ | \____$$\   $$ |$$\
$$ | \$$ |   $$ |        $$$$$$$$\ $$  /\$$\ $$ |  $$ |\$$$$$$$ |\$$$$$$  |$$$$$$$  |  \$$$$  |
\__|  \__|   \__|        \________|\__/  \__|\__|  \__| \_______| \______/ \_______/    \____/
EOF
echo -e "${NC}"
echo "Join Telegram: https://t.me/NTExhaust"
sleep 3

# ===================== ROOT CHECK =====================
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as root. Jangan pura-pura kuat.${NC}"
  exit 1
fi

# ===================== KVM CHECK =====================
if [ ! -e /dev/kvm ]; then
  echo -e "${RED}"
  echo "ERROR: /dev/kvm not found"
  echo "VPS ini TIDAK support virtualization."
  echo "Windows TIDAK AKAN BISA JALAN."
  echo -e "${NC}"
  exit 1
fi

echo -e "${GREEN}KVM detected. VPS ini layak diajak serius.${NC}"

# ===================== SYSTEM UPDATE =====================
echo -e "${CYAN}Updating system...${NC}"
apt update && apt upgrade -y

# ===================== DOCKER INSTALL (DEBIAN OFFICIAL) =====================
echo -e "${CYAN}Installing Docker (Debian repo)...${NC}"

apt install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian trixie stable" \
> /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker --now

echo -e "${GREEN}Docker ready.${NC}"

# ===================== WINDOWS SELECTION =====================
echo
echo "Select Windows Version:"
echo "--------------------------------------"
echo " 2025 | Windows Server 2025"
echo " 2022 | Windows Server 2022"
echo " 2019 | Windows Server 2019"
echo " 11   | Windows 11 Pro"
echo " 10   | Windows 10 Pro"
echo "--------------------------------------"

read -p "Version: " WINDOWS_VERSION
read -p "Username: " WINDOWS_USERNAME
read -s -p "Password: " WINDOWS_PASSWORD
echo
read -p "RAM (e.g. 8G): " RAM_SIZE
read -p "CPU cores (e.g. 4): " CPU_CORES
read -p "Disk size (e.g. 100G): " DISK_SIZE

# ===================== DOCKER COMPOSE =====================
cat > docker-compose.yml <<EOF
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "$WINDOWS_VERSION"
      USERNAME: "$WINDOWS_USERNAME"
      PASSWORD: "$WINDOWS_PASSWORD"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    restart: unless-stopped
    stop_grace_period: 2m
EOF

# ===================== START =====================
echo -e "${CYAN}Starting Windows VM...${NC}"
docker compose up -d

IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo -e "${GREEN}DONE.${NC}"
echo "Web installer : http://$IP:8006"
echo "RDP           : $IP:3389"
echo
echo -e "${YELLOW}Kalau ini gagal, berarti providermu bohong soal KVM.${NC}"
