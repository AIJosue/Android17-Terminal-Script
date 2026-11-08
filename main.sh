#!/bin/bash
set -e

# Detect the non-root user running the script
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# 1. Update and install extra utilities
sudo apt update
sudo apt install -y git cockpit distrobox tldr podmansh podman-docker

# 2. Install KDE Plasma Desktop, Xorg, and XRDP drivers
# Adding xorgxrdp is required for proper hardware/X11 rendering in XRDP
sudo apt install -y --no-install-recommends \
    plasma-workspace-x11 \
    xserver-xorg \
    kde-plasma-desktop \
    kwin-x11 \
    xrdp \
    xorgxrdp \
    dbus-x11

# 3. Add xrdp user to the ssl-cert group
sudo adduser xrdp ssl-cert || true

# 4. Configure ~/.xsession properly with D-Bus and KDE environment
sudo -u "$TARGET_USER" tee "$TARGET_HOME/.xsession" > /dev/null << 'EOF'
#!/bin/sh
export DESKTOP_SESSION=plasma
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
exec dbus-run-session -- startplasma-x11
EOF

sudo chmod +x "$TARGET_HOME/.xsession"
sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xsession"

# Also symlink to .xsessionrc to guarantee startwm.sh catches it
sudo -u "$TARGET_USER" cp "$TARGET_HOME/.xsession" "$TARGET_HOME/.xsessionrc"

# 5. Fix Polkit authentication spam on login
sudo mkdir -p /etc/polkit-1/localauthority/50-local.d/
sudo tee /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla > /dev/null << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# 6. Configure firewall (checks for UFW or firewalld)
if command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --add-port=3389/tcp --permanent
    sudo firewall-cmd --reload
elif command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 3389/tcp
    sudo ufw reload
fi

# 7. Enable and restart XRDP
sudo systemctl enable xrdp
sudo systemctl restart xrdp

echo "Setup complete for user $TARGET_USER. Rebooting now..."
sudo reboot now
