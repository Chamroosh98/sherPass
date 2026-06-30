#!/bin/sh

# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh98
#  Dedicated to the immortal souls of 18-19 Dey 1404 🕊️
# ==============================================================================

clear
LOG_FILE="/tmp/DayPass.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"

# 🌐 [STEP 1]: نمایش منوی شبکه در همان ابتدای ابتدا برای تعیین تکلیف ترافیک
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

# ⚙️ تشخیص خودکار مدیریت پکیج روتر و معماری
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

# 📥 [STEP 2]: لودر آنلاین (اکنون با تکیه بر NET_MODE بالا بدون باگ دانلود می‌کند)
echo -e "\033[33m➔ Synchronizing framework core components...\033[0m"
mkdir -p /tmp/DayPass_space/modules/network

# آپشن‌های بازنده‌ی تحریم با curl بر اساس منوی انتخابی کاربر
CURL_OPTS="-sS -L --insecure --connect-timeout 8"
[ "$NET_MODE" -ne 1 ] && CURL_OPTS="$CURL_OPTS --socks5-hostname 127.0.0.1:8090"

# دانلود فیزیکی لودر از گیت‌هاب
if command -v curl >/dev/null 2>&1; then
    curl $CURL_OPTS -o /tmp/DayPass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh" 2>/dev/null
fi
[ ! -f "/tmp/DayPass_space/modules/loader.sh" ] && wget -qO /tmp/DayPass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh"

# اجرای لودر برای فچ کردن بقیه ماژول‌ها در RAM روتر
. /tmp/DayPass_space/modules/loader.sh
run_online_loader "$GITHUB_RAW_URL" "$@"

# 📌 امپورت مقتدرانه تمام ماژول‌ها از مسیر مطلق موقت
BASE_MODULES="/tmp/DayPass_space/modules"
. "$BASE_MODULES/config.sh"
. "$BASE_MODULES/cleaner.sh"
. "$BASE_MODULES/zero_deps.sh"
. "$BASE_MODULES/network/orchestrator.sh"
. "$BASE_MODULES/iran_rules.sh"
. "$BASE_MODULES/cronjob.sh"
. "$BASE_MODULES/validator.sh"
. "$BASE_MODULES/banner.sh"
. "$BASE_MODULES/network.sh"
. "$BASE_MODULES/passwd.sh"

[ "$1" = "--fallback-remote" ] && shift

# 👑 [STEP 3]: رندر کردن اولین بنر چمروش پس از لود کامل سیستم
generate_custom_banner

run_optimized_installation() {
    local raw_input="" local check_result="" local install_singbox="n"
    enforce_root_password

    echo -e "\n${YELLOW}⚡ Optimization Prompt:${NC}"
    while true; do
        printf "Do you want to install ${BOLD}sing-box${NC} core? (Heavy on low-end devices) [y/n]: "
        read -r raw_input </dev/tty
        check_result=$(validate_ascii_input "$raw_input")
        [ "$check_result" = "empty" ] && { install_singbox="n"; break; }
        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "${RED}[!] Error: Invalid choice.${NC}\n" ;;
        esac
    done
    

    # 🚀 احضار پکیج‌های کاربردی و پیش‌نیازها در بک‌گراند
    deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"

    
    # کلین‌آپ هوشمند تداخل‌ها
    echo -e "\n➔ Deep cleaning old/conflicting Passwall components..."
    if ! apk info -e "luci-app-passwall2" >/dev/null 2>&1; then
        echo -e "⚡ Executing Purge Sequence:"
        for pkg in tcping geoview xray-plugin sing-box luci-app-passwall; do
            if apk info -e "$pkg" >/dev/null 2>&1; then apk del "$pkg" >/dev/null 2>&1; echo -e "   ${GREEN}✔ Removed: $pkg${NC}"; fi
        done
    fi
    
    echo -e "\n${BOLD}${CYAN}[Phase 1/2: Deploying Micro Proxy Cores]${NC}"
    download_package_smart "passwall_packages" "xray-core" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "tcping" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "geoview" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    [ "$install_singbox" = "y" ] && { download_package_smart "passwall_packages" "sing-box" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1; }

    echo -e "${BOLD}${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_package_smart "passwall_luci" "luci-app-passwall2" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_luci" "luci-i18n-passwall2-fa" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    echo -e "${GREEN}${BOLD}✔ Deployment flawless! Passwall 2 Pro is fully running. 🔥${NC}"
    
    # ⚠️ بخش خطرناک تغییر آی‌پي برای جلوگیری از قفل شدن کاربر کامنت شد
    # change_lan_ip
    echo -e "${YELLOW}👉 Installation complete. Router IP remains untouched to avoid lockouts!${NC}"
    exit 0
}

# 🛠️ دکمه فرار: سیستم ریست فکتوری سریع روتر
run_factory_reset() {
    echo -e "${RED}${BOLD}⚠️ WARNING: This will completely wipe the router and reboot!${NC}"
    printf "Are you absolutely sure? (y/n): "
    read -r confirm </dev/tty
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}🔄 Initiating firstboot sequence and rebooting... Goodbye!${NC}"
        sleep 1
        firstboot -y && reboot
    fi
}

# 📱 [STEP 4]: هاب منوی اصلی تعاملی سیستم
while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Xray + Core UI + Clean-up)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${RED}[4] Factory Reset Router ${GRAY}(Emergency Recovery)${NC}"
    echo -e "  ${PURPLE}[5]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [1-5]: "
    
    read -r choice </dev/tty
    [ -z "$choice" ] && continue
    
    case "$choice" in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) run_factory_reset ;;
        5) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read -r _unused </dev/tty
done