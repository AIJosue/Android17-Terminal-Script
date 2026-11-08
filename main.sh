#!/bin/bash
set -e

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

# 1. Update and install utilities (fixed package names)
sudo apt update
sudo apt install -y git cockpit distrobox tldr-py podman podman-docker

# 2. Install KDE Plasma Desktop, Xorg, and XRDP drivers
sudo apt install -y --no-install-recommends \
    plasma-workspace-x11 \
    xserver-xorg \
    kde-plasma-desktop \
    kwin-x11 \
    xrdp \
    xorgxrdp \
    dbus-x11

# 3. Configure XRDP permissions
sudo adduser xrdp ssl-cert 2>/dev/null || true

# 4. Set up ~/.xsession for Plasma X11
cat << 'EOF' > "$TARGET_HOME/.xsession"
#!/bin/sh
export DESKTOP_SESSION=plasma
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE
exec dbus-run-session -- startplasma-x11
EOF

chmod +x "$TARGET_HOME/.xsession"
cp "$TARGET_HOME/.xsession" "$TARGET_HOME/.xsessionrc"

# 5. Prevent polkit colord popups
sudo mkdir -p /etc/polkit-1/localauthority/50-local.d/
sudo tee /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla > /dev/null << 'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# 6. Start XRDP service
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running 2>/dev/null; then
    sudo systemctl enable xrdp --now
else
    # Fallback for chroot/proot containers without systemd
    sudo service xrdp restart || sudo /etc/init.d/xrdp restart
fi

echo "Setup complete! Connect to port 3389 with user: $TARGET_USER"
