# Android Chroot Debian 12 Deployment Guide

### Part 1: Core Execution Scripts

It is recommended to save the following two scripts in `/data/local/tmp` on your phone or in your internal storage for convenient future execution.

#### 1. `start_debian.sh` (Daily Startup Script to Enter the System)
This script handles mounting core directories, removing the `nosuid` restriction, and safely entering the Chroot environment.

```bash
#!/system/bin/sh
# start_debian.sh - Start and enter the Debian Chroot environment

MNT="/data/debian"

# 1. Root permission check
if [ "$(id -u)" != "0" ]; then
    echo "Please acquire root permissions using the su command before running this script!"
    exit 1
fi

# 2. Temporarily disable SELinux (prevents permission denied errors)
setenforce 0

# 3. Remount /data partition to remove nosuid restriction (enables sudo)
mount -o remount,suid /data

# 4. Mount core system directories (if not already mounted)
for dir in dev dev/pts proc sys; do
    if ! grep -q "$MNT/$dir" /proc/mounts; then
        if [ "$dir" = "dev" ]; then
            busybox mount -o bind /dev $MNT/dev
        elif [ "$dir" = "dev/pts" ]; then
            busybox mount -t devpts devpts $MNT/dev/pts
        elif [ "$dir" = "proc" ]; then
            busybox mount -t proc proc $MNT/proc
        elif [ "$dir" = "sys" ]; then
            busybox mount -t sysfs sysfs $MNT/sys
        fi
    fi
done

echo "Environment mounted successfully. Entering Debian..."

# 5. Enter chroot environment
env -i HOME=/root TERM=$TERM PATH=/bin:/usr/bin:/sbin:/usr/sbin \
busybox chroot $MNT /bin/bash
```

#### 2. `stop_debian.sh` (Safe Unmount Script)
After exiting Debian, run this script to unmount and release resources.

```bash
#!/system/bin/sh
# stop_debian.sh - Safely unmount Debian Chroot environment

MNT="/data/debian"

busybox umount $MNT/dev/pts
busybox umount $MNT/dev
busybox umount $MNT/proc
busybox umount $MNT/sys

echo "Debian environment has been safely unmounted."
```

---

### Part 2: Deployment Guide

```markdown
# Android Chroot Debian Deployment Guide

This project provides a guide to deploying a native, fully privileged Debian environment with complete root access and without network or SUID restrictions on Android devices using Magisk, BusyBox, and Chroot technologies, supporting the XFCE4 desktop environment.

## 📋 Phase 1: Prerequisites

1. **Device Requirements**:
   - Phone with an unlocked bootloader and rooted with **Magisk**.
   - Search for and install the **BusyBox for Android NDK** module inside Magisk, then reboot the device.
2. **PC Requirements**:
   - Install the ADB (Android Debug Bridge) toolkit.
   - Enable "Developer Options" and "USB Debugging" on your phone, and connect it to your PC via USB cable.
   - Run `adb devices` in your PC terminal to ensure the device is recognized and authorized.

---

## 🚀 Phase 2: Download & Deploy System Image

### 1. Download Debian Rootfs
First, check whether your phone can download directly using `wget`:
```bash
adb shell
su
wget https://raw.githubusercontent.com/EXALAB/Anlinux-Resources/refs/heads/master/Rootfs/Debian/arm64/debian-rootfs-arm64.tar.xz -O /data/local/tmp/debian-rootfs-arm64.tar.xz
```
*If an error occurs or the download speed is extremely slow, download the URL in your PC browser and push it via ADB:*
```bash
adb push debian-rootfs-arm64.tar.xz /data/local/tmp/
```

### 2. Extract Rootfs Image
Execute the following commands in your PC terminal to enter the phone's root shell and extract:
```bash
adb shell
su

# Temporarily disable SELinux (Important! Prevents cryptic permission errors)
setenforce 0

# Create target directory (recommended in /data for full Linux filesystem permission support)
mkdir -p /data/debian
cd /data/debian

# Extract the archive (extraction time depends on phone storage speed; please be patient)
busybox tar -xf /data/local/tmp/debian-rootfs-arm64.tar.xz
```

---

## 🛠️ Phase 3: Initial Entry & Environment Fixes

Run the prepared `start_debian.sh` script or execute the core mount commands manually to enter the system:

```bash
# 1. Remount /data partition to remove nosuid restriction (makes sudo work)
mount -o remount,suid /data

# 2. Mount core pseudo-filesystems
busybox mount -t proc proc /data/debian/proc
busybox mount -t sysfs sysfs /data/debian/sys
busybox mount -o bind /dev /data/debian/dev
busybox mount -t devpts devpts /data/debian/dev/pts

# 3. Enter Chroot
env -i HOME=/root TERM=$TERM PATH=/bin:/usr/bin:/sbin:/usr/sbin /system/xbin/busybox chroot /data/debian /bin/bash
```

### 4. Fix Network Permissions and APT Groups
**(Execute the following commands inside the Debian chroot bash)**

Configure DNS and localhost:
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "127.0.0.1 localhost" > /etc/hosts
```

**Core Fix: Resolve Android-specific network and application permission isolation:**
```bash
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
```

Update package repositories and install basic tools:
```bash
apt update
apt upgrade -y
apt install nano vim net-tools sudo git wget curl -y
```

---

## 🔐 Phase 4: Configure Sudo and Regular User

Because using the root account for daily desktop usage is risky and certain GUI applications refuse to run as root, create a standard user account:

```bash
# 1. Fix sudo binary permissions
chown root:root /usr/bin/sudo
chmod 4755 /usr/bin/sudo
chmod 4755 /bin/su

# 2. Create your personal user account (replace yourname with your desired username)
adduser yourname

# 3. Add the new user to sudo and Android network groups
usermod -aG sudo,aid_inet,aid_net_raw,aid_graphics yourname

# 4. Switch to the new user and test sudo
su - yourname
sudo apt update # Verify that sudo works without errors
```

---

## 🖥️ Phase 5: Install XFCE4 Desktop Environment (Optional)

If you require a graphical user interface, proceed with the following steps:

```bash
# Install XFCE4 desktop, utilities, VNC server, and DBUS
sudo apt install xfce4 xfce4-goodies tigervnc-standalone-server dbus-x11 -y
```

**Configure and Start VNC Service:**
```bash
# 1. Start VNC once to set the password (only needed once)
vncserver

# 2. Edit VNC startup script to launch XFCE desktop
nano ~/.vnc/xstartup
```
Set the contents of `~/.vnc/xstartup` to:
```bash
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
```
Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`). Grant execution permissions and restart VNC:
```bash
chmod +x ~/.vnc/xstartup
vncserver -kill :1
vncserver -geometry 1920x1080 :1
```

**Connecting to Desktop:**
Install **VNC Viewer** (or **AVNC**) on your Android phone, set connection address to `127.0.0.1:5901`, enter the VNC password you configured, and access your responsive XFCE4 desktop!
```
