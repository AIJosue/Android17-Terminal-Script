#!/bin/bash

# Software Installation Script
# Function: Automatically install Chromium, wget, VS Code, and Pi-Apps

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
sudo apt install -y code
check_status

# Clean up temporary keys
rm -f packages.microsoft.gpg

# Install Pi-Apps
echo -e "\n${GREEN} Installing Pi-Apps...${NC}"
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

# Completion summary
echo -e "\n${GREEN}🎉 All software installed successfully!${NC}"
echo -e "${BLUE}The following software has been installed:${NC}"
echo -e "${BLUE}• Chromium Browser${NC}"
echo -e "${BLUE}• wget Download Tool${NC}"
echo -e "${BLUE}• VS Code${NC}"
echo -e "${BLUE}• Pi-Apps Package App Store${NC}"
print_separator
