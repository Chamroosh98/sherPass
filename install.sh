#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine (Fix Order Edition)
#  Architect: Chamroosh (ch4mr0sh)
#  Dedicated to the immortal souls of 18-19 Dey 1404 🕊️
# ==============================================================================

clear

# 📥 ۱. لود فوری ثوابت پروژه و مسیرها
if [ -f "./consts.sh" ]; then
    . ./consts.sh
else
    export LOG_FILE="/tmp/DayPass.log"
    export GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"
    export BASE_MODULES="/tmp/daypass_space/modules"
    export NET_MODE=3
    export CYAN="\033[1;38;5;51m"; export PURPLE="\033[38;5;141m"; export GREEN="\033[32m"; export YELLOW="\033[33m"; export GRAY="\033[90m"; export RED="\033[31m"; export NC="\033[0m"
fi

# ⚙️ ۲. تشخیص مدیریت پکیج و معماری روتر
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

# 📥 ۳. تنظیم دقیق فلگ‌های دانلود بر اساس کانفیگ زنده
echo -e "${YELLOW}➔ Synchronizing DayPass core modules...${NC}"
mkdir -p "${BASE_MODULES}/feeds"

CURL_OPTS="-sS -L --insecure --connect-timeout 8"
if [ "$NET_MODE" -ne 1 ]; then
    CURL_OPTS="$CURL_OPTS --socks5-hostname 127.0.0.1:8090"
fi

# دانلود ایمن لودر آنلاین
if command -v curl >/dev/null 2>&1; then
    curl $CURL_OPTS -o "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
fi

if [ ! -f "${BASE_MODULES}/loader.sh" ]; then
    wget -qO "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
fi

# بررسی نهایی قبل از اجرای لودر برای جلوگیری از کرش
if [ ! -s "${BASE_MODULES}/loader.sh" ]; then
    echo -e "${RED}❌ Critical: Cannot download loader.sh from GitHub. Check connection!${NC}"
    exit 1
fi

# اجرای لودر آنلاین
. "${BASE_MODULES}/loader.sh"
run_online_loader "$GITHUB_RAW_URL" "$@"

# 🌐 ۴. فراخوانی منوی انتخاب شبکه از داخل ماژول اختصاصی تازه دانلود شده
show_network_menu

# 👑 ۵. رندر بنر گرافیکی تمیز شده
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

# 📱 هاب منوی اصلی تعاملی تعبیه شده
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