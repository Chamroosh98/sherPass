#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;0m'

LOG_FILE="/tmp/passwall_install.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/openwrt-passwall-pro/main"

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

# Package manager and Architecture auto-detection
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

setup_auto_update() {
    log "info" "Setting up CronJob for automated updates..."
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
    echo -e "1) Full Installation (Passwall 2 + Cores)"
    echo -e "2) Apply/Update Iran Smart Routing (DAT files)"
    echo -e "3) Enable Daily Auto-Update (CronJob)"
    echo -e "4) Exit"
    echo -e "---------------------------------------------"
    echo -n "Select an option [1-4]: "
    read choice
    case $choice in
        1) log "info" "Starting full installation..." ;; # Installation logic
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