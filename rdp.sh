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
███████╗ ██████╗ ██████╗  ██████╗███████╗
██╔════╝██╔════╝██╔═══██╗██╔════╝██╔════╝
█████╗  ██║     ██║   ██║██║     █████╗
██╔══╝  ██║     ██║   ██║██║     ██╔══╝
██║     ╚██████╗╚██████╔╝╚██████╗███████╗
╚═╝      ╚═════╝ ╚═════╝  ╚═════╝╚══════╝
NO KVM · SOFTWARE EMULATION MODE
EOF
echo -e "${NC}"
sleep 2

# ===================== ROOT CHECK =====================
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as root. Jangan bandel.${NC}"
  exit 1
fi

# ===================== WARNING =====================
echo -e "${YELLOW}"
echo "WARNING:"
echo "- VPS TIDAK PUNYA KVM"
echo "- Windows akan SANGAT LAMBAT"
echo "- Boot bisa 30–90 menit"
echo "- RDP bisa freeze"
echo
read -p "Ketik YES untuk lanjut: " CONFIRM
echo -e "${NC}"

if [ "$CONFIRM" != "YES" ]; then
  echo "Dibatalkan. Keputusan bijak."
  exit 0
fi

# ===================== UPDATE =====================
echo -e "${CYAN}Updating system...${NC}"
apt update && apt upgrade -y

# ===================== DOCKER INSTALL (DEBIAN) =====================
echo -e "${CYAN}Installing Docker...${NC}"

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

# ===================== WINDOWS CONFIG =====================
echo
echo "RECOMMENDED:"
echo "- VERSION  : 2019 / 2022"
echo "- RAM      : 2G–4G"
echo "- CPU      : 1"
echo "- DISK     : 50–80G"
echo

read -p "Windows Version (2019/2022): " WINDOWS_VERSION
read -p "Username: " WINDOWS_USERNAME
read -s -p "Password: " WINDOWS_PASSWORD
echo
read -p "RAM (e.g. 2G): " RAM_SIZE
read -p "CPU cores (1 only): " CPU_CORES
read -p "Disk size (e.g. 60G): " DISK_SIZE

# ===================== DOCKER COMPOSE (NO KVM) =====================
cat > docker-compose.yml <<EOF
services:
  windows:
    image: dockurr/windows
    container_name: windows
    privileged: true
    environment:
      VERSION: "$WINDOWS_VERSION"
      USERNAME: "$WINDOWS_USERNAME"
      PASSWORD: "$WINDOWS_PASSWORD"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
      DISK_SIZE: "$DISK_SIZE"
      KVM: "false"
      QEMU_CPU: "max"
      QEMU_ACCEL: "tcg"
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    restart: unless-stopped
    stop_grace_period: 5m
EOF

# ===================== START =====================
echo -e "${CYAN}Starting Windows (SOFTWARE EMULATION)...${NC}"
docker compose up -d

IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo
echo -e "${GREEN}Container started.${NC}"
echo -e "${CYAN}Installer Web: http://$IP:8006${NC}"
echo -e "${CYAN}RDP         : $IP:3389${NC}"
echo
echo -e "${YELLOW}Kalau hang, TUNGGU. Jangan restart. Ini emulasi, bukan VM beneran.${NC}"
