#!/bin/bash

# ==============================================================================
# Script Name: Debian Desktop Environment & Remote Access One-Click Installer (Android VM Edition)
# Description: Automatically installs the selected desktop environment and configures SSH and TigerVNC remote access.
# Supported Systems: Debian 12 / Debian 13 / Android Linux VM
# ==============================================================================

# --- Global Variables and Initialization ---
TARGET_USER=$(whoami)

if [ "$(id -u)" -eq 0 ]; then
  echo -e "\033[0;31m[ERROR]\033[0m Please do not run this script as root. Run it as a regular user."
  exit 1
fi

if ! command -v sudo &> /dev/null; then
  echo -e "\033[0;31m[ERROR]\033[0m 'sudo' command not found. Please install sudo and configure the current user first."
  exit 1
fi

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Message Dictionary ---
declare -A messages
messages=(
    ["press_enter"]="Press Enter to continue..."
    ["invalid_option"]="Invalid option, please try again."
    ["operation_cancelled"]="Operation cancelled."
    ["install_success"]="Successfully installed %s"
    ["install_fail"]="Failed to install %s"
    ["command_fail"]="Command failed: %s"
    
    ["welcome_banner"]="Welcome to the Debian Desktop Environment Installer (Android VM Edition)"
    ["set_password_prompt"]="Set or change the login password for user '$TARGET_USER'? (y/n): "
    ["desktop_select"]="Select the desktop environment you want to install"
    ["enter_desktop_num"]="Please enter the number for the desktop environment: "
    
    ["confirm_banner"]="Installation Confirmation"
    ["confirm_intro"]="The following actions will be performed on your system:"
    ["confirm_user"]="  - User: '$TARGET_USER'"
    ["confirm_desktop"]="  - Install Desktop: "
    ["confirm_ssh"]="  - Configure SSH Service (Port 10022, IPv4 forced for stability)"
    ["confirm_vnc"]="  - Configure VNC Service (Port 5901, includes Android X11 fixes)"
    ["confirm_proceed"]="Do you want to continue? (y/n): "

    ["update_pkg"]="Updating package list..."
    ["upgrade_pkg"]="Upgrading installed packages..."
    ["ssh_modify"]="Configuring SSH server..."
    ["network_fix"]="Applying Android VM network bridge stability patch..."
    ["locale_check"]="Configuring system locale and font packages..."
    ["desktop_install"]="Installing %s desktop environment, this may take a while..."
    ["vnc_passwd_prompt"]="Next, please set a password for your VNC session (at least 6 characters)."
    ["vnc_config"]="Configuring TigerVNC and fixing Android VM dependencies..."
    
    ["android_share_banner"]="Mounting Android shared directory..."
    ["input_method_prompt"]="Install Fcitx5 input method framework? (y/n): "
    ["ime_install_banner"]="Installing input method framework (Fcitx5)..."
    ["common_apps_desc"]="Optional software suite includes:\n  - Chromium, LibreOffice, VLC, GIMP, htop, curl, git, etc."
    ["common_apps_prompt"]="Install the above common desktop & system software suite? (y/n): "
    ["apps_install_banner"]="Installing common software suite..."

    ["final_summary"]="🎉 All configurations completed!"
    ["final_client_title"]="${GREEN}💻 Recommended Connection Methods:${NC}"
    ["final_client_phone"]="  - 📱 ${BLUE}On Phone:${NC} Install the [AVNC] app, connect to address ${YELLOW}127.0.0.1${NC}, port ${YELLOW}5901${NC}."
    ["final_client_pc"]="  - 🖥️ ${BLUE}On Windows PC (Recommended, via ADB Forwarding):${NC}"
    ["final_client_adb"]="      1. Connect phone via USB and enable [USB Debugging].\n      2. Run in Windows CMD/PowerShell: ${YELLOW}adb forward tcp:5901 tcp:5901${NC}\n      3. Open TigerVNC client on PC, connect to: ${YELLOW}127.0.0.1:5901${NC}"

    ["final_audio_title"]="${GREEN}🔊 Audio Solution (Fix Missing Sound in VNC):${NC}"
    ["final_audio_desc"]="  - Android 16 VM lacks native audio passthrough. Use companion app [Simple Protocol Player]:\n      🔗 App Download: ${YELLOW}https://github.com/xlzhen-940218/SimpleProtocolPlayer/releases${NC}\n      1. Run in Linux terminal to start audio streaming module:\n         ${YELLOW}pactl load-module module-simple-protocol-tcp rate=44100 format=s16le channels=2 record=true port=12345${NC}\n      2. Open App on phone, set IP ${YELLOW}127.0.0.1${NC}, port ${YELLOW}12345${NC}, mode [Speaker], and tap Start Stream!"

    ["final_faq_title"]="${RED}🛠️ Troubleshooting & FAQ:${NC}"
    ["final_faq_1"]="  ${YELLOW}1. VNC connection refused, timeout, or black screen?${NC}\n     -> Usually caused by Android killing background processes. Swipe away/kill the terminal app, then reopen it. Set [Battery Optimization] to [Unrestricted] in Android settings."
    ["final_faq_2"]="  ${YELLOW}2. Cannot type in desktop / input method not working?${NC}\n     -> Input framework needs a restart. Close and reopen the terminal app, or run 'vncserver -kill :1 && vncserver :1'."
    ["final_faq_3"]="  ${YELLOW}3. The 'Android_Files' shared folder is empty / Permission denied?${NC}\n     -> Ensure your VM App has [All Files Access] permission. If mount fails, restart your phone to reset Android mounts."
    ["final_faq_4"]="  ${YELLOW}4. No audio output when playing videos/webpages?${NC}\n     -> Android 16 VM lacks native sound card mapping. Use the Simple Protocol Player solution above to stream desktop audio to your phone."
)

function lang() { local key="$1"; printf -- "${messages[$key]}"; }
function info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function error() { echo -e "${RED}[ERROR]${NC} $1"; }
function banner() { echo -e "${BLUE}============================================================${NC}\n${BLUE}$1${NC}\n${BLUE}============================================================${NC}"; }
function run_cmd() { if ! "$@"; then error "$(printf "$(lang command_fail)" "$*")"; exit 1; fi; }
function install_package() { local pkg_name=$1; if ! sudo apt install -y "$pkg_name"; then error "$(printf "$(lang install_fail)" "$pkg_name")"; exit 1; fi; }

# --- Step 1: User Interaction ---
function user_selections() {
    clear
    banner "$(lang welcome_banner)"
    
    read -p "$(lang set_password_prompt)" set_pwd
    if [[ "$set_pwd" =~ ^[Yy]$ ]]; then sudo passwd $TARGET_USER; fi

    banner "$(lang desktop_select)"
    echo "1. KDE Plasma"; echo "2. GNOME"; echo "3. XFCE"; echo "4. MATE"; echo "5. Cinnamon"; echo "6. LXQt"; echo "7. LXDE"; echo "8. GNOME Flashback"

    while true; do
        read -p "$(lang enter_desktop_num)" desktop_choice
        case $desktop_choice in
            1) DESKTOP_NAME="KDE Plasma"; TASKSEL_TASK="kde-desktop"; VNC_SESSION="plasmax11"; VNC_FALLBACK="plasma"; break ;;
            2) DESKTOP_NAME="GNOME"; TASKSEL_TASK="gnome-desktop"; VNC_SESSION="gnome-xorg"; VNC_FALLBACK="gnome"; break ;;
            3) DESKTOP_NAME="XFCE"; TASKSEL_TASK="xfce-desktop"; VNC_SESSION="xfce"; VNC_FALLBACK=""; break ;;
            4) DESKTOP_NAME="MATE"; TASKSEL_TASK="mate-desktop"; VNC_SESSION="mate"; VNC_FALLBACK=""; break ;;
            5) DESKTOP_NAME="Cinnamon"; TASKSEL_TASK="cinnamon-desktop"; VNC_SESSION="cinnamon"; VNC_FALLBACK="cinnamon2d"; break ;;
            6) DESKTOP_NAME="LXQt"; TASKSEL_TASK="lxqt-desktop"; VNC_SESSION="lxqt"; VNC_FALLBACK=""; break ;;
            7) DESKTOP_NAME="LXDE"; TASKSEL_TASK="lxde-desktop"; VNC_SESSION="LXDE"; VNC_FALLBACK="lxde"; break ;;
            8) DESKTOP_NAME="GNOME Flashback"; TASKSEL_TASK="gnome-flashback-desktop"; VNC_SESSION="gnome-flashback-metacity"; VNC_FALLBACK=""; break ;;
            *) error "$(lang invalid_option)" ;;
        esac
    done

    clear; banner "$(lang confirm_banner)"
    echo "$(lang confirm_intro)"; printf "$(lang confirm_user)\n"; printf "$(lang confirm_desktop) '$DESKTOP_NAME'\n"
    read -p "$(lang confirm_proceed)" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then exit 0; fi
}

# --- Step 2: System Preparation & Locale Configuration ---
function prepare_system() {
    banner "$(lang update_pkg)"; run_cmd sudo apt-get update -y
    banner "$(lang upgrade_pkg)"; run_cmd sudo apt-get upgrade -y
    
    if ! grep -q "$(hostname)" /etc/hosts; then echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts > /dev/null; fi

    banner "$(lang locale_check)"
    install_package "locales"
    
    SYS_LOCALE="en_US.UTF-8"
    sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    
    run_cmd sudo locale-gen
    sudo update-locale LANG=$SYS_LOCALE
    
    if ! grep -q "export LANG=" ~/.bashrc; then
        echo "export LANG=$SYS_LOCALE" >> ~/.bashrc
        echo "export LC_ALL=$SYS_LOCALE" >> ~/.bashrc
    else
        sed -i "s/export LANG=.*/export LANG=$SYS_LOCALE/" ~/.bashrc
        sed -i "s/export LC_ALL=.*/export LC_ALL=$SYS_LOCALE/" ~/.bashrc
    fi
    
    install_package "fonts-dejavu"; install_package "fonts-noto-core"
}

# --- Step 3: Inject Android Network Bridge Stability Patch ---
function fix_android_network_bridge() {
    banner "$(lang network_fix)"
    sudo mkdir -p /etc/systemd/system/ssh.service.d
    cat << 'EOFB' | sudo tee /etc/systemd/system/ssh.service.d/wait-network.conf > /dev/null
[Unit]
After=network-online.target
Wants=network-online.target
EOFB

    sudo mkdir -p /etc/systemd/system/tigervncserver@.service.d
    cat << 'EOFB' | sudo tee /etc/systemd/system/tigervncserver@.service.d/wait-network.conf > /dev/null
[Unit]
After=network-online.target
Wants=network-online.target
EOFB
    sudo systemctl daemon-reload
}

# --- Step 4: SSH Configuration ---
function setup_ssh() {
    banner "$(lang ssh_modify)"; install_package "openssh-server"

    if sudo systemctl is-active --quiet ssh.socket 2>/dev/null || sudo systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
        sudo systemctl disable --now ssh.socket 2>/dev/null || true
        sudo systemctl enable --now ssh.service 2>/dev/null || true
    fi

    sudo sed -i -E -e 's/^#?\s*Port\s+[0-9]+/Port 10022/' -e 's/^#?\s*PasswordAuthentication\s+no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    if ! sudo grep -q "^Port 10022" /etc/ssh/sshd_config; then echo "Port 10022" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    if ! sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    if ! sudo grep -q "^ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then echo "ListenAddress 0.0.0.0" | sudo tee -a /etc/ssh/sshd_config > /dev/null; fi
    
    if systemctl list-unit-files | grep -q "^ssh.service"; then
        run_cmd sudo systemctl restart ssh
    else
        run_cmd sudo systemctl restart sshd
    fi
}

# --- Step 5: Install Desktop Environment ---
function install_desktop() {
    banner "$(printf "$(lang desktop_install)" "$DESKTOP_NAME")"
    install_package "tasksel"; run_cmd sudo tasksel install $TASKSEL_TASK
}

# --- Step 6: VNC Configuration ---
function setup_vnc() {
    banner "$(lang vnc_config)"
    install_package "tigervnc-standalone-server"; install_package "tigervnc-common"; install_package "dbus-x11"
    
    sudo mkdir -p /tmp/.X11-unix; sudo chmod 1777 /tmp/.X11-unix
    info "$(lang vnc_passwd_prompt)"; run_cmd vncpasswd
    mkdir -p ~/.vnc
    
    ACTUAL_SESSION="$VNC_SESSION"
    if [ ! -f "/usr/share/xsessions/${VNC_SESSION}.desktop" ] && [ -n "$VNC_FALLBACK" ] && [ -f "/usr/share/xsessions/${VNC_FALLBACK}.desktop" ]; then
        ACTUAL_SESSION="$VNC_FALLBACK"
    fi

    cat > ~/.vnc/config <<- EOFB
		session=$ACTUAL_SESSION
		geometry=1920x1080
		localhost=no
		alwaysshared
	EOFB
    
    sudo mkdir -p /etc/tigervnc
    echo ":1=$TARGET_USER" | sudo tee /etc/tigervnc/vncserver.users >/dev/null
    
    run_cmd sudo systemctl daemon-reload
    sudo systemctl enable tigervncserver@:1.service 2>/dev/null || true
    run_cmd sudo systemctl restart tigervncserver@:1.service
}

# --- Step 7: Mount Android Shared Directory (Fix Permissions) ---
function setup_android_shared() {
    banner "$(lang android_share_banner)"
    install_package "xdg-user-dirs"; xdg-user-dirs-update
    
    # [Fix 1] Create directory only if it does not exist to avoid permission issues under Android Root Squash
    if [ ! -d "/mnt/shared" ]; then
        sudo mkdir -p /mnt/shared 2>/dev/null || true
    fi
    
    # [Fix 2] Reset personal config directory ownership that may have been locked by root
    sudo chown -R $TARGET_USER:$TARGET_USER ~/.config 2>/dev/null || true
    
    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null)
    if [ -z "$DESKTOP_DIR" ]; then DESKTOP_DIR="$HOME/Desktop"; fi
    
    if [ ! -d "$DESKTOP_DIR" ]; then
        mkdir -p "$DESKTOP_DIR"
    fi
    sudo chown -R $TARGET_USER:$TARGET_USER "$DESKTOP_DIR" 2>/dev/null || true
    
    LINK_NAME="Android_Files"
    ln -sf /mnt/shared "$DESKTOP_DIR/$LINK_NAME"
    
    mkdir -p ~/.config/gtk-3.0
    touch ~/.config/gtk-3.0/bookmarks
    if ! grep -q "file:///mnt/shared" ~/.config/gtk-3.0/bookmarks; then
        echo "file:///mnt/shared 📱Android_Shared_Disk" >> ~/.config/gtk-3.0/bookmarks
    fi
}

# --- Step 8: Optional Components ---
function optional_components() {
    read -p "$(lang input_method_prompt)" install_ime
    if [[ "$install_ime" =~ ^[Yy]$ ]]; then
        banner "$(lang ime_install_banner)"
        install_package "fcitx5"
        install_package "fcitx5-frontend-gtk3"; install_package "fcitx5-frontend-qt5"
        install_package "im-config"; im-config -n fcitx5
    fi

    echo ""; echo -e "$(lang common_apps_desc)"
    read -p "$(lang common_apps_prompt)" install_apps
    if [[ "$install_apps" =~ ^[Yy]$ ]]; then
        banner "$(lang apps_install_banner)"
        install_package "curl"; install_package "wget"; install_package "git"; install_package "htop"
        install_package "unzip"; install_package "p7zip-full"; install_package "chromium"
        install_package "vlc"; install_package "gimp"; install_package "flameshot"
        install_package "remmina"; install_package "libreoffice"; install_package "pulseaudio-utils"
    fi
}

# --- Step 9: Summary & Troubleshooting ---
function final_summary() {
    clear; banner "$(lang final_summary)"
    
    echo -e "$(lang final_client_title)"
    echo -e "$(lang final_client_phone)"
    echo -e "$(lang final_client_pc)"
    echo -e "$(lang final_client_adb)\n"
    
    echo -e "$(lang final_audio_title)"
    echo -e "$(lang final_audio_desc)\n"

    echo -e "$(lang final_faq_title)"
    echo -e "$(lang final_faq_1)\n"
    echo -e "$(lang final_faq_2)\n"
    echo -e "$(lang final_faq_3)\n"
    echo -e "$(lang final_faq_4)\n"
}

# --- Main Program Entry Point ---
function main() {
    user_selections
    prepare_system
    fix_android_network_bridge
    setup_ssh
    install_desktop
    setup_vnc
    setup_android_shared
    optional_components
    final_summary
}

main
