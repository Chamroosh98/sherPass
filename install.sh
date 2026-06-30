#!/bin/sh
# shellcheck shell=ash

######### In memory of the brutal massacre of IRAN in 8-9 january 2026 (18-19 Day 1404) #########
# ===============================================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh98
# ==============================================================================

clear
LOG_FILE="/tmp/DayPass.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"

clear
echo -e "\033[38;5;141m┌───────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;141m│\033[0m       \033[1;38;5;51m🌐 SELECT NETWORK DEPLOYMENT MODE\033[0m      \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m├───────────────────────────────────────────────┤\033[0m"
echo -e "\033[38;5;141m│\033[0m  [1] Proxy Tunnel (SOCKS5 127.0.0.1:8090)    \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m│      \033[90m↳ Best if GitHub/SourceForge is blocked.\033[0m \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m│\033[0m  [2] Direct Connection (No Proxy)            \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m│      \033[90m↳ Native router network bypass.\033[0m          \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m│\033[0m  [3] Smart Resilient Fallback (Recommended)   \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m│      \033[90m↳ Tries Proxy first, drops to Direct.\033[0m    \033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m└───────────────────────────────────────────────┘\033[0m"
printf "  Select network routing [1-3] (Default 3): "
read -r net_choice </dev/tty
case "$net_choice" in
    1) NET_MODE=2 ;;
    2) NET_MODE=1 ;;
    *) NET_MODE=3 ;;
esac
export NET_MODE
echo -e "   \033[32m✔ Network configuration locked!\033[0m\n"
sleep 1

if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

echo -e "\033[33m➔ Synchronizing DayPass core modules...\033[0m"
mkdir -p /tmp/daypass_space/modules/feeds

CURL_OPTS="-sS -L --insecure --connect-timeout 8"
[ "$NET_MODE" -ne 1 ] && CURL_OPTS="$CURL_OPTS --socks5-hostname 127.0.0.1:8090"

if command -v curl >/dev/null 2>&1; then
    curl $CURL_OPTS -o /tmp/daypass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh?v=$(date +%s)" 2>/dev/null
fi
[ ! -f "/tmp/daypass_space/modules/loader.sh" ] && wget -qO /tmp/daypass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh?v=$(date +%s)"

# اجرای لودر آنلاین
. /tmp/daypass_space/modules/loader.sh
run_online_loader "$GITHUB_RAW_URL" "$@"

BASE_MODULES="/tmp/daypass_space/modules"
. "$BASE_MODULES/config.sh"
. "$BASE_MODULES/cleaner.sh"
. "$BASE_MODULES/zero_deps.sh"
. "$BASE_MODULES/iran_rules.sh"
. "$BASE_MODULES/cronjob.sh"
. "$BASE_MODULES/validator.sh"
. "$BASE_MODULES/banner.sh"
. "$BASE_MODULES/passwd.sh"

. "$BASE_MODULES/feeds/openwrt.sh"
. "$BASE_MODULES/feeds/sourceforge.sh"


generate_custom_banner

run_optimized_installation() {
    local raw_input="" local check_result="" local install_singbox="n"
    enforce_root_password

    echo -e "\n\033[33m⚡ Optimization Prompt:\033[0m"
    while true; do
        printf "Do you want to install \033[1msing-box\033[0m core? (Heavy on low-end devices) [y/n]: "
        read -r raw_input </dev/tty
        check_result=$(validate_ascii_input "$raw_input")
        [ "$check_result" = "empty" ] && { install_singbox="n"; break; }
        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "\033[31m[!] Error: Invalid choice.\033[0m\n" ;;
        esac
    done
    
    deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"
    
    echo -e "\n➔ Deep cleaning old/conflicting Passwall components..."
    execute_purge_sequence "$PKG_MGR" "$REMOVE_CMD"
    
    echo -e "\n\033[1;\033[38;5;51m[Phase 1/2: Deploying Micro Proxy Cores]\033[0m"
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

    download_from_sourceforge_feed "passwall2" "luci-app-passwall2" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    local install_fa="n" local fa_input=""
    echo -e "\n\033[33m🌐 Language Pack Prompt:\033[0m"
    while true; do
        printf "Do you want to install \033[1mPersian (FA)\033[0m language pack? [y/n]: "
        read -r fa_input </dev/tty
        check_result=$(validate_ascii_input "$fa_input")
        [ "$check_result" = "empty" ] && { install_fa="n"; break; }
        case "$check_result" in
            [yY]) install_fa="y"; break ;;
            [nN]) install_fa="n"; break ;;
            *) echo -e "\033[31m[!] Error: Invalid choice.\033[0m\n" ;;
        esac
    done

    if [ "$install_fa" = "y" ]; then
        download_from_sourceforge_feed "passwall2" "luci-i18n-passwall2-fa" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi
    
    echo -e "\n\033[32m\033[1m✔ Deployment flawless! DayPass Engine is fully running. 🔥\033[0m"
    echo -e "\033[33m👉 Router IP remains untouched to avoid lockouts!\033[0m"
    exit 0
}

run_factory_reset() {
    echo -e "\033[31m\033[1m⚠️ WARNING: This will completely wipe the router and reboot!\033[0m"
    printf "Are you absolutely sure? (y/n): "
    read -r confirm </dev/tty
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "\033[33m🔄 Initiating firstboot sequence and rebooting... Goodbye!\033[0m"
        sleep 1
        firstboot -y && reboot
    fi
}

while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  \033[38;5;141m[1]\033[0m Optimized Installation \033[90m(Cores + LuCI Selection)\033[0m"
    echo -e "  \033[38;5;141m[2]\033[0m Apply/Update Iran Smart Routing \033[90m(DAT files)\033[0m"
    echo -e "  \033[38;5;141m[3]\033[0m Enable Daily Auto-Update \033[90m(CronJob)\033[0m"
    echo -e "  \033[31m[4] Factory Reset Router \033[90m(Emergency Recovery)\033[0m"
    echo -e "  \033[38;5;141m[5]\033[0m Exit"
    echo -e "\033[38;5;141m─────────────────────────────────────────────────\033[0m"
    printf "  Select an option [1-5]: "
    read -r choice </dev/tty
    [ -z "$choice" ] && continue
    case "$choice" in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) run_factory_reset ;;
        5) echo -e "\033[1;38;5;51mGoodbye!\033[0m"; exit 0 ;;
        *) echo -e "\033[31mInvalid Option!\033[0m"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read -r _unused </dev/tty
done