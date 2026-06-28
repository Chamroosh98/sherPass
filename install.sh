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

# 4. Inject SourceForge APK Feeds (Utilizes packages.adb automatically)
setup_repositories() {
    log "info" "Injecting modern Passwall 2 repositories into the system..."
    local feed_passwall2="$SF_BASE_URL/passwall2"
    local feed_packages="$SF_BASE_URL/passwall_packages"
    
    if [ "$PKG_MGR" = "apk" ]; then
        echo "$feed_passwall2" >> /etc/apk/repositories
        echo "$feed_packages" >> /etc/apk/repositories
        log "info" "Updating APK signature databases (packages.adb)..."
        apk update >> $LOG_FILE 2>&1
    else
        echo "src/gz passwall2 $feed_passwall2" >> /etc/opkg/customfeeds.conf
        echo "src/gz passwall_packages $feed_packages" >> /etc/opkg/customfeeds.conf
        log "info" "Updating OPKG signature databases..."
        opkg update >> $LOG_FILE 2>&1
    fi
}

# 5. Core installation workflow
run_full_installation() {
    prepare_environment
    setup_repositories

    log "info" "Installing proxy cores and dependencies from SourceForge..."
    echo -e "${YELLOW}--> Downloading and installing sing-box, xray-core, and chinadns-ng...${NC}"
    
    # با حذف خروجی مخفی (>> LOG_FILE)، اجازه میدیم خود apk پراگرس دانلود رو زنده نشون بده
    # اما خروجی خطاها رو با tee به فایل لاگ هم میفرستیم
    if $INSTALL_CMD sing-box xray-core chinadns-ng 2>&1 | tee -a $LOG_FILE; then
        log "success" "Cores installed successfully."
    else
        log "error" "Failed to install cores! Check logs."
        return 1
    fi

    log "info" "Installing Passwall 2 LuCI interfaces..."
    echo -e "${YELLOW}--> Downloading and installing LuCI web interface and Persian language pack...${NC}"
    
    if $INSTALL_CMD luci-app-passwall2 luci-i18n-passwall2-fa 2>&1 | tee -a $LOG_FILE; then
        log "success" "All components from SourceForge have been deployed flawlessly! 🔥"
    else
        log "error" "Installation encountered an issue. Review logs at: $LOG_FILE"
        return 1
    fi
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