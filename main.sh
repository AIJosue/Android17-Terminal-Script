#!/bin/bash
set -e

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# 1. Update package lists
sudo apt update

# 2. Install CLI tools (using Debian-valid packages: tldr-py and podman)
sudo apt install -y git cockpit distrobox tldr-py podman podman-docker

# 3. Install KDE Plasma Desktop and Xorg
sudo apt install -y --no-install-recommends \
    plasma-workspace-x11 \
    xserver-xorg \
    kde-plasma-desktop \
    kwin-x11 \
    xrdp \
    xorgxrdp \
    dbus-x11

# 4. Add xrdp user to ssl-cert group
sudo adduser xrdp ssl-cert 2>/dev/null || true

# 5. Fix black screen: export KDE environment and wrap session in D-Bus
cat << 'EOF' > "$TARGET_HOME/.xsession"
#!/bin/sh
export DESKTOP_SESSION=plasma
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
exec dbus-run-session -- startplasma-x11
EOF

chmod +x "$TARGET_HOME/.xsession"
cp "$TARGET_HOME/.xsession" "$TARGET_HOME/.xsessionrc"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xsession" "$TARGET_HOME/.xsessionrc"

# 6. Prevent colord authentication dialog loops
sudo mkdir -p /etc/polkit-1/localauthority/50-local.d/
sudo tee /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla > /dev/null << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# 7. Start XRDP daemon
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running 2>/dev/null; then
    sudo systemctl enable xrdp --now
else
    sudo service xrdp restart || sudo /etc/init.d/xrdp restart
fi

echo "=========================================="
echo "Done! Connect using an RDP client to: 127.0.0.1:3389"
echo "Username: $TARGET_USER"
echo "=========================================="
