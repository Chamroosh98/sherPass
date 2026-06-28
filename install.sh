#!/bin/sh

LOG_FILE="/tmp/passwall_install.log"

# Env Auto-Detection
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
fi

if [ "$PKG_MGR" = "apk" ]; then
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

# Strict Local Modularity Loader (Relative directory loading)
. ./modules/config.sh
. ./modules/cleaner.sh
. ./modules/downloader.sh
. ./modules/iran_rules.sh
. ./modules/cronjob.sh

run_optimized_installation() {
    local install_singbox="n"
    echo -e "\n${YELLOW}⚡ Optimization Prompt:${NC}"
    printf "Do you want to install ${BOLD}sing-box${NC} core? (Heavy on low-end devices) [y/N]: "
    read install_singbox </dev/tty
    
    # فراخوانی ماژول محیط‌سازی
    run_environment_setup "$INSTALL_CMD" "$REMOVE_CMD" "$LOG_FILE"
    
    echo -e "\n${BOLD}${CYAN}[Phase 1/2: Deploying Micro Proxy Cores]${NC}"
    download_package_smart "passwall_packages" "xray-core" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "tcping" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "geoview" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    if [ "$install_singbox" = "y" ] || [ "$install_singbox" = "Y" ]; then
        download_package_smart "passwall_packages" "sing-box" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi

    echo -e "${BOLD}${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_package_smart "passwall2" "luci-app-passwall2" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall2" "luci-i18n-passwall2-fa" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    echo -e "${GREEN}${BOLD}✔ Deployment flawless! Passwall 2 Pro is fully running. 🔥${NC}"
}

if [ "$1" = "--update-rules" ]; then
    run_iran_rules_module
    exit 0
fi

while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Xray + Core UI + Clean-up)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${PURPLE}[4]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [1-4]: "
    read choice </dev/tty
    
    case $choice in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read _unused </dev/tty
done