#!/bin/bash

# 1. Update package lists 123
sudo apt update

sudo apt install -y git cockpit-* distrobox tldr podmansh podman-docker

# 2. Install KDE Plasma Desktop and Xorg
# Using --no-install-recommends keeps the installation lighter
sudo apt install -y --no-install-recommends plasma-workspace-x11 xserver-xorg sddm kde-plasma-desktop

# 3. Install XRDP for remote access
sudo apt install -y xrdp

# 4. Install KWin X11 (Window Manager)
sudo apt install -y kwin-x11

# 5. Set the system to boot into graphical mode by default
sudo systemctl set-default graphical.target

echo "Setup complete. Please set a password for your user if you haven't already."

# We use sudo to ensure the file is created in the correct home directory
sudo -u admin bash -c 'echo "exec startplasma-x11" > /home/admin/.Xclients'
sudo -u admin chmod +x /home/admin/.Xclients

# 5. Open RDP port on the firewall
sudo firewall-cmd --add-service=rdp --permanent
sudo firewall-cmd --reload
sudo reboot now
