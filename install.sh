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
    print_status "work" "Flushing deprecated repository feeds"
    [ -f /etc/opkg/customfeeds.conf ] && sed -i '/passwall/d' /etc/opkg/customfeeds.conf 2>/dev/null
    [ -f /etc/apk/repositories ] && sed -i '/passwall/d' /etc/apk/repositories 2>/dev/null
    print_status "done" "Cleaned"

    print_status "work" "Upgrading router network engines & SSL"
    if $INSTALL_CMD wget curl ca-bundle libustream-openssl >> $LOG_FILE 2>&1; then
        print_status "done" "Network Upgraded"
    else
        print_status "failed" "Network Engine Upgrade Failed"
    fi
}

# 4. Fetch and compute dynamic package targets from sourceforge index.json
download_package_smart() {
    local sub_folder=$1
    local keyword=$2
    local index_file="/tmp/sf_${sub_folder}_index.json"
    
    print_status "work" "Resolving SourceForge metadata for ${BOLD}$keyword${NC}"
    wget -qO "$index_file" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/index.json"
    
    if [ ! -s "$index_file" ]; then
        print_status "failed" "Failed to fetch database index!"
        return 1
    fi

    local pkg_version=$(grep -o "\"$keyword\": \"[^\"]*" "$index_file" | cut -d'"' -f4)
    if [ -z "$pkg_version" ]; then
        print_status "failed" "Version mapping for '$keyword' not found!"
        rm -f "$index_file"
        return 1
    fi
    
    local full_name="${keyword}_${pkg_version}_${ARCH}.apk"
    print_status "sub" "Downloading ${BOLD}$full_name${NC}"
    
    if wget -qO "/tmp/$full_name" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$ARCH/$sub_folder/$full_name"; then
        print_status "sub" "Injecting package via APK into core OS"
        $INSTALL_CMD "/tmp/$full_name" >> $LOG_FILE 2>&1
        local status=$?
        rm -f "/tmp/$full_name" "$index_file"
        
        if [ $status -eq 0 ]; then
            print_status "success" "${BOLD}$keyword${NC} deployed successfully!"
            return 0
        else
            print_status "failed" "APK installation failed for $keyword"
            return 1
        fi
    else
        print_status "failed" "Download blocked or network timeout!"
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
    print_status "work" "Binding cron synchronization configurations"
    local cron_cmd="0 4 * * * wget -qO- $GITHUB_RAW_URL/install.sh | sh -s -- --update-rules"
    (crontab -l 2>/dev/null | grep -v "update-rules"; echo "$cron_cmd") | crontab -
    /etc/init.d/cron restart
    print_status "done" "Cronjob bound at 04:00 AM"
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