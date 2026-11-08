## AD FocuSee [Record Your Screen. Get Polished Videos Automatically.](https://focusee.imobie.com?ad=github-xlzhen)

# Android 16 Terminal Debian GUI Access Tool

![Bash](https://img.shields.io/badge/Shell-Bash-green) ![Debian](https://img.shields.io/badge/OS-Debian%2012%20|%2013-red) ![VNC](https://img.shields.io/badge/Protocol-VNC-blue)

**Documentation**: [README.md](README.md)

---

## 📖 Feature Overview

This script is specifically designed for Linux virtual machine / terminal environments on Android 16 systems. It enables fully automated configuration of a complete graphical user interface (GUI) for **Debian 12 (Bookworm)** and **Debian 13 (Trixie)**, resolving deep system-level compatibility issues between the Android host and Debian.

Once configured, you can seamlessly access the native Debian desktop environment locally on your phone or on a large PC screen.

## ✨ Key Features

- **Standard English Interface**: Streamlined script execution and configuration running entirely in English.
- **Debian 13 & Wayland Compatibility**: Automatically detects and forces VNC to use X11 sessions, completely preventing black screens and crash loops caused by Debian 13's default Wayland environments.
- **Deep Android VM Integration**:
  - Injects Systemd network bridge wait patches to eliminate VNC/SSH premature binding failures and random disconnects.
  - Automatically maps the Android host `/mnt/shared` directory directly to the Linux Desktop as an independent disk for seamless cross-system file transfer.
- **Global Locale & IME Support**: Overcomes the VM's restrictive `C.UTF-8` limitations, sets up UTF-8 locale, installs comprehensive font packages, and integrates the next-generation **Fcitx5** input method framework.
- **One-Click Productivity Suite (Optional)**: Provides one-click installation of Chromium browser, LibreOffice suite, VLC media player, GIMP image editor, and full system CLI tools (`htop`, `git`, `curl`, `unzip`, `p7zip-full`, etc.).
- **Secure Remote Access**: Configures SSH (forced IPv4 on custom port `10022` with password authentication enabled) and TigerVNC server (port `5901`).
- **Wireless Audio Streaming**: Solves the absence of physical sound card / virtio-sound passthrough in the Android 16 Linux VM using an ultra-low-latency PulseAudio TCP streaming solution. Paired with the open-source companion Android app [Simple Protocol Player](https://github.com/xlzhen-940218/SimpleProtocolPlayer), desktop audio plays directly through your phone speakers in real time.

---

## 🚀 Usage Guide

### Prerequisites

- Android 16 system terminal / Linux virtual machine environment.
- **Run the script as a regular user** (Do **not** run directly as `root`; the script will invoke `sudo` when elevated privileges are required).

### Installation Steps

1. Save the script to your Android terminal device (e.g., as `android16-terminal.sh`).
2. Grant execution permissions:
```bash
chmod +x android16-terminal.sh
```
3. Run the script:
```bash
./android16-terminal.sh
```
4. Follow the interactive prompts on screen to choose your desktop environment (supports 8 environments: KDE Plasma, GNOME, XFCE, MATE, Cinnamon, LXQt, LXDE, GNOME Flashback), set your VNC password, and select optional software packages.

---

## 💻 Recommended Connection Methods

### Method 1: On Windows PC (Recommended, via ADB Forwarding)

1. Connect your phone to your PC via USB cable and ensure **USB Debugging** is enabled in Android Developer Options.
2. In Windows CMD or PowerShell, execute the port forwarding command:
```bash
adb forward tcp:5901 tcp:5901
```
3. Open any VNC client on your PC (such as TigerVNC Viewer) and connect to:
```text
127.0.0.1:5901
```

> **💡 Tip**: If you want to connect to the terminal via SSH from your PC, execute `adb forward tcp:10022 tcp:10022`, then connect from your PC terminal using `ssh username@127.0.0.1 -p 10022`.

### Method 2: Direct Access on Phone

1. Download and install a VNC client app on your Android phone (strongly recommended: **AVNC**).
2. Create a new connection in the app with address `127.0.0.1` and port `5901`.
3. Connect and enter the VNC password you set during script execution to enter the desktop.

---

## 🔊 Audio Solution (Fix Missing Sound in VNC Desktop)

Android 16's native Linux VM (AVF/Terminal) currently lacks physical sound card emulation or virtio-sound hardware passthrough. Consequently, playing videos, browser audio, or music inside the VNC desktop produces no sound by default.

This solution uses the **PulseAudio TCP Simple Protocol** module to stream audio from the Debian VM to the Android host in real time over loopback:

### 1. Install Android Audio Receiver Client

Download and install the dedicated PulseAudio companion app **Simple Protocol Player** on your Android phone:
- 📥 **App Download**: [Simple Protocol Player Releases](https://github.com/xlzhen-940218/SimpleProtocolPlayer/releases)
- Source Repository: [xlzhen-940218/SimpleProtocolPlayer](https://github.com/xlzhen-940218/SimpleProtocolPlayer)

### 2. Start Audio Server in Debian VM

Execute the following commands in your Debian terminal (installs utilities and loads the module):
```bash
# Ensure pactl tool is installed
sudo apt install -y pulseaudio-utils

# Load audio streaming module (listening on port 12345)
pactl load-module module-simple-protocol-tcp rate=44100 format=s16le channels=2 record=true port=12345
```

> 💡 **Tip**: To start the audio server automatically on boot or terminal startup, append the `pactl load-module ...` command above to the end of your `~/.bashrc` file.

### 3. Connect and Listen on Phone

1. Open the **Simple Protocol Player** app on your phone.
2. **Configure settings**:
   - **IP Address**: Enter `127.0.0.1` (the phone host shares local loopback with the VM)
   - **Audio Port**: Enter `12345`
   - **Mode**: Select **Speaker (Receiver)**
   - **Audio Format**: Default 44100Hz / Stereo / 50ms buffer
3. Tap **Start Stream**. Audio played in the Debian desktop (videos, music, browser) will now stream instantly through your phone speakers!
4. *(Advanced)*: The app also supports "Microphone (Transmitter)" mode, allowing phone microphone input to serve as a virtual mic input for Linux.

---

## 🛠️ Troubleshooting & FAQ

* **❓ VNC connection suddenly drops, times out, or shows a black screen?**
  * **Cause**: Usually caused by Android's aggressive background battery optimization suspending the VM process or freezing network sockets.
  * **Solution**: Go to Android **Settings** -> **Apps** -> Find the Terminal/VM app -> Set **Battery Optimization** to **Unrestricted**. If disconnected, swipe away and close the terminal app completely from the recent tasks switcher, then reopen it.
* **❓ Cannot type or input method not working?**
  * **Cause**: The input framework requires restarting the desktop session after initial installation to apply environment variables.
  * **Solution**: Completely restart the terminal app, or run `vncserver -kill :1 && vncserver :1` to restart the VNC service.
* **❓ The desktop "Android_Files" shared directory is empty or shows Permission Denied?**
  * **Cause**: Caused by Android's Root Squash mechanism or missing filesystem permissions.
  * **Solution**: Ensure your terminal app has been granted **All Files Access / Storage** permission in Android Settings. If permissions are granted but the folder is still empty, restart your phone to reset the underlying VirtioFS mount state.
* **❓ No sound when playing media or web videos in VNC?**
  * **Cause**: The Android 16 Linux VM currently lacks physical sound card passthrough.
  * **Solution**: Follow the **Audio Solution** section above by running `pactl load-module module-simple-protocol-tcp ...` in Debian and streaming to [Simple Protocol Player](https://github.com/xlzhen-940218/SimpleProtocolPlayer) on your phone.

---

## ⚙️ Underlying Execution Workflow

The script automatically executes the following core procedures in sequence:

1. **Environment Preparation**: Updates apt cache and writes local hostname mappings to `/etc/hosts` to prevent DNS resolution hangs.
2. **Locale Configuration**: Configures `/etc/default/locale` and `~/.bashrc` to ensure clean UTF-8 environment and installs font packages.
3. **Network Patch Injection**: Writes Systemd drop-in rules (`wait-network.conf`) for SSH and TigerVNC to enforce IPv4 binding and wait for network online targets.
4. **Desktop Deployment**: Deploys the selected desktop environment via `tasksel` and installs `dbus-x11` to prevent desktop crashes.
5. **Userland Session Mapping**: Generates `~/.vnc/config` forcing X11 sessions and updates GTK sidebar bookmarks to map Android storage (`/mnt/shared`).

---

## ⚠️ Notes

1. A stable internet connection is recommended to ensure smooth downloading of desktop environment packages.
2. After configuration, you can manage the VNC service manually using:
   - Start service: `sudo systemctl start tigervncserver@:1.service`
   - Stop service: `sudo systemctl stop tigervncserver@:1.service`
   - Check status: `sudo systemctl status tigervncserver@:1.service`

---

## 🤝 Contribution & Feedback

Issues and Pull Requests are welcome to improve this project. Please provide detailed reproduction steps and error logs when reporting issues.

## 📜 License

This project is open-source under the [MIT License](LICENSE).
