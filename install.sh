#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;0m'

LOG_FILE="/tmp/passwall_install.log"
# TODO: Replace 'Chamroosh98' with your actual github username if changed
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/openwrt-passwall-pro/main"

log() {
    local level=$1; local msg=$2
    case $level in
        "info")    echo -e "${BLUE}[INFO]${NC} $msg" ;;
        "success") echo -e "${GREEN}[SUCCESS]${NC} $msg" ;;
        "warn")    echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        "error")   echo -e "${RED}[ERROR]${NC} $msg" ;;
    esac
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> $LOG_FILE
}

log "info" "Loading system modules..."
if wget -qO /tmp/iran_rules_mod.sh "$GITHUB_RAW_URL/iran_rules.sh"; then
    . /tmp/iran_rules_mod.sh
    rm -f /tmp/iran_rules_mod.sh
else
    log "error" "Failed to load Iran rules module!"
fi

# 1. Package manager auto-detection (Optimized for OpenWrt 25 APK)
log "info" "Checking package manager..."
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    INSTALL_CMD="apk add --allow-untrusted"
    log "success" "Default package manager: apk (OpenWrt 25+)"
else
    PKG_MGR="opkg"
    INSTALL_CMD="opkg install"
    log "success" "Default package manager: opkg"
fi

# 2. Architecture auto-detection
log "info" "Detecting system architecture..."
if [ "$PKG_MGR" = "apk" ]; then
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi

if [ -z "$ARCH" ]; then
    log "warn" "Architecture not detected! Defaulting to arm_cortex-a7_neon-vfpv4"
    ARCH="arm_cortex-a7_neon-vfpv4"
else
    log "success" "System architecture: $ARCH"
fi

# Dynamic SourceForge base URL built from router architecture
SF_BASE_URL="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH"

# 3. Clean environment and upgrade network engines
prepare_environment() {
    log "info" "Cleaning deprecated repository feeds..."
    [ -f /etc/opkg/customfeeds.conf ] && sed -i '/passwall/d' /etc/opkg/customfeeds.conf 2>/dev/null
    [ -f /etc/apk/repositories ] && sed -i '/passwall/d' /etc/apk/repositories 2>/dev/null

    log "info" "Upgrading network certificates and download engines..."
    $INSTALL_CMD wget curl ca-bundle libustream-openssl >> $LOG_FILE 2>&1
}

# 4. Fetch latest package names dynamically from SourceForge index
download_package_smart() {
    local sub_folder=$1
    local keyword=$2
    
    # دانلود فایل ایندکس متنی برای پیدا کردن نام دقیق پکیج
    wget -qO /tmp/sf_index.html "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/"
    
    # پیدا کردن نام کامل فایل (مثلاً sing-box_1.2_arm.apk)
    local full_name=$(grep -o 'href="[^"]*' /tmp/sf_index.html | grep "$keyword" | cut -d'"' -f2 | head -n 1)
    
    if [ -z "$full_name" ]; then
        log "error" "Could not find any package matching '$keyword' on SourceForge!"
        return 1
    fi
    
    echo -e "${YELLOW}--> Downloading $full_name ...${NC}"
    # دانلود با نمایش لایو پیشرفت دانلود
    if wget --no-check-certificate --show-progress -qO "/tmp/$full_name" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/$full_name"; then
        log "info" "Installing $full_name via APK..."
        $INSTALL_CMD "/tmp/$full_name" 2>&1 | tee -a $LOG_FILE
        local status=$?
        rm -f "/tmp/$full_name"
        return $status
    else
        log "error" "Failed to download $full_name"
        return 1
    fi
}

# 5. Core installation workflow
run_full_installation() {
    prepare_environment
    
    log "info" "Starting dependency installation from passwall_packages..."
    download_package_smart "passwall_packages" "sing-box" || return 1
    download_package_smart "passwall_packages" "xray-core" || return 1
    download_package_smart "passwall_packages" "chinadns-ng" || return 1

    log "info" "Starting Passwall 2 UI installation..."
    download_package_smart "passwall2" "luci-app-passwall2" || return 1
    download_package_smart "passwall2" "luci-i18n-passwall2-fa" || return 1
    
    log "success" "All components from SourceForge have been deployed flawlessly! 🔥"
    rm -f /tmp/sf_index.html
}

setup_auto_update() {
    log "info" "Setting up CronJob for automated routing updates..."
    local cron_cmd="0 4 * * * wget -qO- $GITHUB_RAW_URL/main.sh | sh -s -- --update-rules"
    (crontab -l 2>/dev/null | grep -v "update-rules"; echo "$cron_cmd") | crontab -
    /etc/init.d/cron restart
    log "success" "Daily auto-update cronjob enabled successfully (04:00 AM)."
}

show_menu() {
    clear
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}      OpenWrt Passwall Pro Auto-Installer    ${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo -e "Arch: ${YELLOW}$ARCH${NC} | Pkg Manager: ${YELLOW}$PKG_MGR${NC}"
    echo -e "Log File: ${BLUE}$LOG_FILE${NC}"
    echo -e "---------------------------------------------"
    echo -e "1) Full Installation (Passwall 2 + Cores from SourceForge)"
    echo -e "2) Apply/Update Iran Smart Routing (DAT files)"
    echo -e "3) Enable Daily Auto-Update (CronJob)"
    echo -e "4) Exit"
    echo -e "---------------------------------------------"
    echo -n "Select an option [1-4]: "
    read choice
    case $choice in
        1) run_full_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update ;;
        4) log "info" "Exiting script. Goodbye!"; exit 0 ;;
        *) log "error" "Invalid option!"; sleep 1 ;;
    esac
}

if [ "$1" = "--update-rules" ]; then
    run_iran_rules_module
    exit 0
fi

while true; do show_menu; echo -e "\nPress Enter to return to main menu..."; read; done