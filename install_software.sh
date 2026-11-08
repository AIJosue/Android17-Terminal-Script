#!/bin/bash

# Software Installation Script
# Function: Automatically install Chromium, wget, Clash Verge, VS Code, and Bilibili client

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Separator function
print_separator() {
    echo -e "${BLUE}=============================================${NC}"
}

# Check if command executed successfully
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        exit 1
    fi
}
echo -e "apt update..."
# Update package lists
echo -e "\n${YELLOW}🔄 Updating package list...${NC}"
print_separator
sudo apt update
check_status

# Install Chromium
echo -e "\n${YELLOW}🌐 Installing Chromium browser...${NC}"
print_separator
sudo apt install -y chromium
check_status

# Install wget
echo -e "\n${YELLOW}📥 Installing wget download tool...${NC}"
print_separator
sudo apt install -y wget
check_status

# Method 1: Use official API to get the latest release tag (recommended)
LATEST_CLASH_RELEASE=$(curl -s https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest | jq -r '.tag_name')
echo "Latest version tag: $LATEST_CLASH_RELEASE"

VERSION_CLASH_WITHOUT_V="${LATEST_CLASH_RELEASE#v}"

# Download and install Clash Verge
echo -e "\n${YELLOW}🛡️ Downloading Clash Verge (${LATEST_CLASH_RELEASE} arm64)...${NC}"
print_separator
wget https://github.com/clash-verge-rev/clash-verge-rev/releases/download/${LATEST_CLASH_RELEASE}/Clash.Verge_${VERSION_CLASH_WITHOUT_V}_arm64.deb -O Clash.Verge_${VERSION_CLASH_WITHOUT_V}_arm64.deb
check_status

echo -e "\n${YELLOW}🛠️ Installing Clash Verge...${NC}"
print_separator
sudo apt --fix-broken install ./Clash.Verge_${VERSION_CLASH_WITHOUT_V}_arm64.deb
check_status

# Download and install VS Code
echo -e "\n${YELLOW}💻 Downloading VS Code (arm64)...${NC}"
print_separator
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update
check_status

echo -e "\n${YELLOW}🛠️ Installing VS Code...${NC}"
print_separator
sudo apt install code # Or install code-insiders for the Insiders version
check_status

# Method 1: Use official API to get the latest release tag (recommended)
LATEST_BILIBILI_RELEASE=$(curl -s https://api.github.com/repos/msojocs/bilibili-linux/releases/latest | jq -r '.tag_name')
echo "Latest version tag: $LATEST_BILIBILI_RELEASE"

VERSION_BILIBILI_WITHOUT_V="${LATEST_BILIBILI_RELEASE#v}"

# Download and install Bilibili client
echo -e "\n${YELLOW}📺 Downloading Bilibili client (${LATEST_BILIBILI_RELEASE} arm64)...${NC}"
print_separator
wget https://github.com/msojocs/bilibili-linux/releases/download/${LATEST_BILIBILI_RELEASE}/io.github.msojocs.bilibili_${VERSION_BILIBILI_WITHOUT_V}_arm64.deb -O io.github.msojocs.bilibili_${VERSION_BILIBILI_WITHOUT_V}_arm64.deb
check_status

echo -e "\n${YELLOW}🛠️ Installing Bilibili client...${NC}"
print_separator
sudo dpkg -i io.github.msojocs.bilibili_${VERSION_BILIBILI_WITHOUT_V}_arm64.deb
sudo apt --fix-broken install -y
check_status

# Clean up installation packages
echo -e "\n${YELLOW}🧹 Cleaning up installation packages...${NC}"
print_separator
rm -f Clash.Verge_${VERSION_CLASH_WITHOUT_V}_arm64.deb io.github.msojocs.bilibili_${VERSION_BILIBILI_WITHOUT_V}_arm64.deb
check_status

echo -e "\n${GREEN} Installing Pi-Apps...${NC}"
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

# Completion summary
echo -e "\n${GREEN}🎉 All software installed successfully!${NC}"
echo -e "${BLUE}The following software has been installed:${NC}"
echo -e "${BLUE}• Chromium Browser${NC}"
echo -e "${BLUE}• wget Download Tool${NC}"
echo -e "${BLUE}• Clash Verge (${LATEST_CLASH_RELEASE})${NC}"
echo -e "${BLUE}• VS Code${NC}"
echo -e "${BLUE}• Bilibili Client (${LATEST_BILIBILI_RELEASE})${NC}"
print_separator
