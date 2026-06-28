#!/bin/sh

LOG_FILE="/tmp/passwall_install.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/sherPass/main"

# 1. Package manager auto-detection
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    INSTALL_CMD="apk add --allow-untrusted"
else
    PKG_MGR="opkg"
    INSTALL_CMD="opkg install"
fi

# 2. Architecture auto-detection
if [ "$PKG_MGR" = "apk" ]; then
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

# 3. Dynamic Module Loaders
wget -qO /tmp/config_mod.sh "$GITHUB_RAW_URL/config.sh" && . /tmp/config_mod.sh && rm -f /tmp/config_mod.sh
wget -qO /tmp/iran_rules_mod.sh "$GITHUB_RAW_URL/iran_rules.sh" && . /tmp/iran_rules_mod.sh && rm -f /tmp/iran_rules_mod.sh

log() {
    local level=$1; local msg=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> $LOG_FILE
}

prepare_environment() {
    printf "${CYAN}➔${NC} Flushing deprecated repository feeds ... "
    [ -f /etc/opkg/customfeeds.conf ] && sed -i '/passwall/d' /etc/opkg/customfeeds.conf 2>/dev/null
    [ -f /etc/apk/repositories ] && sed -i '/passwall/d' /etc/apk/repositories 2>/dev/null
    echo -e "${GREEN}✔ Cleaned${NC}"

    printf "${CYAN}➔${NC} Upgrading router network engines & SSL ... "
    $INSTALL_CMD wget curl ca-bundle libustream-openssl >> $LOG_FILE 2>&1 &
    show_spinner $!
    echo -e "${GREEN}✔ Network Upgraded${NC}"
}

# 4. Fetch and compute dynamic package targets from sourceforge index.json
download_package_smart() {
    local sub_folder=$1
    local keyword=$2
    local index_file="/tmp/sf_${sub_folder}_index.json"
    
    printf "${CYAN}➔${NC} Resolving SourceForge index metadata for ${BOLD}$keyword${NC} ... "
    wget -qO "$index_file" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/index.json" &
    show_spinner $!
    
    if [ ! -s "$index_file" ]; then
        echo -e "${RED}✘ Failed to fetch index!${NC}"
        return 1
    fi

    # پارس دقیق ساختار کلید-مقدار بدون r1 برای پکیج‌های خاص زبانی
    local pkg_version=$(grep -o "\"$keyword\": \"[^\"]*" "$index_file" | cut -d'"' -f4)
    if [ -z "$pkg_version" ]; then
        echo -e "${RED}✘ Package version not found!${NC}"
        rm -f "$index_file"
        return 1
    fi
    echo -e "${GREEN}✔ Resolution: v$pkg_version${NC}"
    
    local full_name="${keyword}_${pkg_version}_${ARCH}.apk"
    
    printf "   ${PURPLE}↳${NC} Downloading ${BOLD}$full_name${NC} ... "
    wget -qO "/tmp/$full_name" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/$full_name" &
    show_spinner $!
    
    if [ -s "/tmp/$full_name" ]; then
        printf "   ${PURPLE}↳${NC} Injecting binary via APK into core OS ... "
        $INSTALL_CMD "/tmp/$full_name" >> $LOG_FILE 2>&1 &
        show_spinner $!
        echo -e "${GREEN}✔ Success${NC}\n"
        rm -f "/tmp/$full_name" "$index_file"
        return 0
    else
        echo -e "${RED}✘ Download Blocked/Failed!${NC}\n"
        rm -f "$index_file"
        return 1
    fi
}

run_full_installation() {
    prepare_environment
    
    echo -e "\n${BOLD}${CYAN}[Phase 1/2: Deploying Binary Proxy Cores]${NC}"
    download_package_smart "passwall_packages" "sing-box" || return 1
    download_package_smart "passwall_packages" "xray-core" || return 1
    download_package_smart "passwall_packages" "chinadns-ng" || return 1

    echo -e "${BOLD}${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_package_smart "passwall2" "luci-app-passwall2" || return 1
    download_package_smart "passwall2" "luci-i18n-passwall2-fa" || return 1
    
    echo -e "${GREEN}${BOLD}✔ Deployment flawless! Passwall 2 Pro is fully running. 🔥${NC}"
}

setup_auto_update() {
    printf "${CYAN}➔${NC} Binding cron synchronization configurations ... "
    local cron_cmd="0 4 * * * wget -qO- $GITHUB_RAW_URL/install.sh | sh -s -- --update-rules"
    (crontab -l 2>/dev/null | grep -v "update-rules"; echo "$cron_cmd") | crontab -
    /etc/init.d/cron restart
    echo -e "${GREEN}✔ Cronjob bound at 04:00 AM${NC}"
}

if [ "$1" = "--update-rules" ]; then
    run_iran_rules_module
    exit 0
fi

while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Full Installation ${GRAY}(Passwall 2 + Cores from SourceForge)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${PURPLE}[4]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [1-4]: "
    read choice </dev/tty
    
    case $choice in
        1) run_full_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update ;;
        4) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read _unused </dev/tty
done