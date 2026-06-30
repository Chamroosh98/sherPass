#!/bin/sh
# shellcheck shell=ash

clear

[ -f "./consts.sh" ] && . ./consts.sh

if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

echo -e "${YELLOW}➔ Synchronizing DayPass core modules...${NC}"
mkdir -p "${BASE_MODULES}/feeds"

CURL_OPTS="-sS -L --insecure --connect-timeout 8"
[ "$NET_MODE" -ne 1 ] && CURL_OPTS="$CURL_OPTS --socks5-hostname 127.0.0.1:8090"

if command -v curl >/dev/null 2>&1; then
    curl $CURL_OPTS -o "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
fi
[ ! -f "${BASE_MODULES}/loader.sh" ] && wget -qO "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)"

. "${BASE_MODULES}/loader.sh"
run_online_loader "$GITHUB_RAW_URL" "$@"

show_network_menu

generate_custom_banner

run_optimized_installation() {
    local raw_input="" check_result="" install_singbox="n"
    enforce_root_password

    echo -e "\n${YELLOW}⚡ Optimization Prompt:${NC}"
    while true; do
        printf "Do you want to install ${CYAN}sing-box${NC} core? (Heavy on low-end devices) [y/n]: "
        read -r raw_input </dev/tty
        check_result=$(validate_ascii_input "$raw_input")
        [ "$check_result" = "empty" ] && { install_singbox="n"; break; }
        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "${RED}[!] Error: Invalid choice.${NC}\n" ;;
        esac
    done
    
    deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"
    
    echo -e "\n➔ Deep cleaning old/conflicting Passwall components..."
    execute_purge_sequence "$PKG_MGR" "$REMOVE_CMD"
    
    echo -e "\n${CYAN}[Phase 1/2: Deploying Micro Proxy Cores]${NC}"
    download_from_openwrt_feed "xray-core" "$INSTALL_CMD" "$LOG_FILE" || \
    download_from_sourceforge_feed "passwall_packages" "xray-plugin" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_from_openwrt_feed "tcping" "$INSTALL_CMD" "$LOG_FILE" || \
    download_from_sourceforge_feed "passwall_packages" "tcping" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_from_openwrt_feed "geoview" "$INSTALL_CMD" "$LOG_FILE" || \
    download_from_sourceforge_feed "passwall_packages" "geoview" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    if [ "$install_singbox" = "y" ]; then
        download_from_openwrt_feed "sing-box" "$INSTALL_CMD" "$LOG_FILE" || \
        download_from_sourceforge_feed "passwall_packages" "sing-box" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi

    echo -e "\n${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_from_sourceforge_feed "passwall2" "luci-app-passwall2" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    local install_fa="n" fa_input=""
    echo -e "\n${YELLOW}🌐 Language Pack Prompt:${NC}"
    while true; do
        printf "Do you want to install ${CYAN}Persian (FA)${NC} language pack? [y/n]: "
        read -r fa_input </dev/tty
        check_result=$(validate_ascii_input "$fa_input")
        [ "$check_result" = "empty" ] && { install_fa="n"; break; }
        case "$check_result" in
            [yY]) install_fa="y"; break ;;
            [nN]) install_fa="n"; break ;;
            *) echo -e "${RED}[!] Error: Invalid choice.${NC}\n" ;;
        esac
    done

    if [ "$install_fa" = "y" ]; then
        download_from_sourceforge_feed "passwall2" "luci-i18n-passwall2-fa" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi
    
    echo -e "\n${GREEN}✔ Deployment flawless! DayPass Engine is fully running. 🔥${NC}"
    exit 0
}

run_factory_reset() {
    echo -e "${RED}⚠️ WARNING: This will completely wipe the router and reboot!${NC}"
    printf "Are you absolutely sure? (y/n): "
    read -r confirm </dev/tty
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}🔄 Initiating firstboot sequence and rebooting... Goodbye!${NC}"
        sleep 1
        firstboot -y && reboot
    fi
}

while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Cores + LuCI Selection)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${RED}[4] Factory Reset Router ${GRAY}(Emergency Recovery)${NC}"
    echo -e "  ${PURPLE}[0]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [0-4]: "
    read -r choice </dev/tty
    [ -z "$choice" ] && continue
    case "$choice" in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) run_factory_reset ;;
        0) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read -r _unused </dev/tty
done