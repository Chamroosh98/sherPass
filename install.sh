#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine (Lifecycle & Cores Fixed)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

clear

if [ -f "./consts.sh" ]; then
    . ./consts.sh
else
    export LOG_FILE="/tmp/DayPass.log"
    export GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"
    export BASE_MODULES="/tmp/daypass_space/modules"
    export CYAN="\033[1;38;5;51m"; export PURPLE="\033[38;5;141m"; export GREEN="\033[32m"; export YELLOW="\033[33m"; export GRAY="\033[90m"; export RED="\033[31m"; export NC="\033[0m"
fi

# ⚙️ تشخیص پکیج منیجر و معماری سخت‌افزاری روتر
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

echo -e "${YELLOW}🚗 Bootstrapping DayPass Core Engine! ${NC}"
mkdir -p "${BASE_MODULES}/feeds"
mkdir -p "${BASE_MODULES}/network"

INIT_OPTS="-sS -L --insecure --connect-timeout 10"

# دانلود اجزای اولیه استارت‌آپ به صورت ارتباط مستقیم
if command -v curl >/dev/null 2>&1; then
    curl $INIT_OPTS -o "${BASE_MODULES}/zero_deps.sh" "${GITHUB_RAW_URL}/modules/zero_deps.sh?v=$(date +%s)" 2>/dev/null
    curl $INIT_OPTS -o "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
    curl $INIT_OPTS -o "${BASE_MODULES}/network/menu.sh" "${GITHUB_RAW_URL}/modules/network/menu.sh?v=$(date +%s)" 2>/dev/null
else
    wget -qO "${BASE_MODULES}/zero_deps.sh" "${GITHUB_RAW_URL}/modules/zero_deps.sh?v=$(date +%s)" 2>/dev/null
    wget -qO "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
    wget -qO "${BASE_MODULES}/network/menu.sh" "${GITHUB_RAW_URL}/modules/network/menu.sh?v=$(date +%s)" 2>/dev/null
fi

# ولیدیتور اولیه اسکریپت
if [ ! -s "${BASE_MODULES}/loader.sh" ] || [ ! -s "${BASE_MODULES}/network/menu.sh" ] || [ ! -s "${BASE_MODULES}/zero_deps.sh" ]; then
    echo -e "${RED}❌ Critical : Bootloader failed to fetch core structures from GitHub! ${NC}"
    echo -e "${YELLOW}🛎️ Notify the developer please!  ${NC}"
    exit 1
fi

# 🔥 گام حیاتی ۱: اجرای ضربتی تزریق دپندنس‌ها (تضمین مجهز شدن روتر به دستور curl واقعی قبل از هر چیز)
. "${BASE_MODULES}/zero_deps.sh"
deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"

# 📡 گام حیاتی ۲: لود منوی هوشمند شبکه با داشتن ابزار کرل پایدار
. "${BASE_MODULES}/network/menu.sh"
show_network_menu

# 🚀 گام حیاتی ۳: سینک بقیه ماژول‌های هسته بدون تداخل محیطی پروکسی (با منطق ایزوله شده در خود لودر)
echo -e "${YELLOW}⏰ Synchronizing remaining DayPass core modules! Wait a minute please! ${NC}"
. "${BASE_MODULES}/loader.sh"
run_online_loader "$GITHUB_RAW_URL" "$@"

# در این مرحله مطمئن هستیم banner.sh دانلود شده و می‌توان آن را صدا زد
if [ -s "${BASE_MODULES}/banner.sh" ]; then
    . "${BASE_MODULES}/banner.sh"
else
    echo -e "${RED}❌ Critical : Dynamic banner module is missing inside storage!${NC}"
    echo -e "${YELLOW}🛎️ Notify the developer please!  ${NC}"
    exit 1
fi

run_optimized_installation() {
    local raw_input="" check_result="" install_singbox="n"
    enforce_root_password

    echo -e "\n${YELLOW}⚡ Optimization Prompt :${NC}"
    while true; do
        printf "🤔 Do you want to install ${CYAN}sing-box${NC} core instead of ${CYAN}xray${NC} core?  ${RED}(💩 Heavy on low-end devices!)${NC} [y/n] : "
        read -r raw_input </dev/tty
        check_result=$(validate_ascii_input "$raw_input")
        [ "$check_result" = "empty" ] && { install_singbox="n"; break; }
        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "${RED}[!] ❌ Error : Invalid choice! 😒${NC}\n" ;;
        esac
    done
    
    # دپندنس‌ها یک بار همان اول نصب شدند، اما برای اطمینان مجدد چک می‌شوند
    deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"
    
    echo -e "\n🧼 Deep cleaning old/conflicting Passwall components! "
    # زره‌پوش کردن دستور پاکسازی برای جلوگیری از ارورهای ناگهانی شل
    if command -v execute_purge_sequence >/dev/null 2>&1; then
        execute_purge_sequence "$PKG_MGR" "$REMOVE_CMD"
    else
        echo -e "${YELLOW}⚠️ Warning : Cleaner engine not fully mapped in memory. Skipping purge ...${NC}"
    fi
    
    echo -e "\n${CYAN}🌐 [Phase 1/2 : Deploying Micro Proxy Cores via Native Custom Feed]${NC}"
    
    # دپلویمنت پکیج‌ها یکی پس از دیگری از طریق پکیج منیجر لوکال
    download_from_sourceforge_feed "passwall_packages" "xray-core" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_from_sourceforge_feed "passwall_packages" "xray-plugin" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_from_sourceforge_feed "passwall_packages" "tcping" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_from_sourceforge_feed "passwall_packages" "geoview" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    if [ "$install_singbox" = "y" ]; then
        download_from_sourceforge_feed "passwall_packages" "sing-box" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi
    
    # echo -e "\n${CYAN}🌐 [Phase 1/2 : Deploying Micro Proxy Cores]${NC}"
    # echo -e "⚙️ Processing ${CYAN}xray-core${NC} deployment..."
    # download_from_openwrt_feed "xray-core" "$INSTALL_CMD" "$LOG_FILE" || \
    # download_from_sourceforge_feed "passwall_packages" "xray-core" "$INSTALL_CMD" "$LOG_FILE" || return 1

    # echo -e "⚙️ Processing ${CYAN}xray-plugin${NC} deployment..."
    # download_from_openwrt_feed "xray-plugin" "$INSTALL_CMD" "$LOG_FILE" || \
    # download_from_sourceforge_feed "passwall_packages" "xray-plugin" "$INSTALL_CMD" "$LOG_FILE" || return 1

    # echo -e "⚙️ Processing ${CYAN}tcping${NC} deployment..."
    # download_from_openwrt_feed "tcping" "$INSTALL_CMD" "$LOG_FILE" || \
    # download_from_sourceforge_feed "passwall_packages" "tcping" "$INSTALL_CMD" "$LOG_FILE" || return 1

    # echo -e "⚙️ Processing ${CYAN}geoview${NC} deployment..."
    # download_from_openwrt_feed "geoview" "$INSTALL_CMD" "$LOG_FILE" || \
    # download_from_sourceforge_feed "passwall_packages" "geoview" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    # if [ "$install_singbox" = "y" ]; then
    #     echo -e "⚙️ Processing ${CYAN}sing-box${NC} deployment..."
    #     download_from_openwrt_feed "sing-box" "$INSTALL_CMD" "$LOG_FILE" || \
    #     download_from_sourceforge_feed "passwall_packages" "sing-box" "$INSTALL_CMD" "$LOG_FILE" || return 1
    # fi

    echo -e "\n${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_from_sourceforge_feed "passwall2" "luci-app-passwall2" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    local install_fa="n" fa_input=""
    echo -e "\n${YELLOW}🌐 Language Pack Selection :${NC}"
    while true; do
        printf "🦁☀️ Do you want to install ${GREEN}Persian (FA)${NC} language pack? [y/n] : "
        read -r fa_input </dev/tty
        check_result=$(validate_ascii_input "$fa_input")
        [ "$check_result" = "empty" ] && { install_fa="n"; break; }
        case "$check_result" in
            [yY]) install_fa="y"; break ;;
            [nN]) install_fa="n"; break ;;
            *) echo -e "${RED}[!] ❌ Error: Invalid choice! 😒${NC}\n" ;;
        esac
    done

    if [ "$install_fa" = "y" ]; then
        download_from_sourceforge_feed "passwall2" "luci-i18n-passwall2-fa" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi
    
    echo -e "\n${GREEN}🔥 Deployment flawless! DayPass Engine is fully running! ${NC}"
    exit 0
}

run_factory_reset() {
    echo -e "${RED}⚠️ WARNING : This will completely wipe the router and reboot! ${NC}"
    printf "😶‍🌫️ Are you absolutely sure? (y/n) : "
    read -r confirm </dev/tty
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}🔄 Initiating firstboot sequence and rebooting ... Goodbye!${NC}"
        sleep 1
        firstboot -y && reboot
    fi
}

# 📱 هاب تعاملی منوی اصلی
while true; do
    clear
    
    generate_custom_banner
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
        1) 
            clear
            generate_custom_banner 
            run_optimized_installation 
            ;;
        2) 
            clear
            generate_custom_banner
            run_iran_rules_module 
            ;;
        3) 
            clear
            generate_custom_banner
            setup_auto_update "$LOG_FILE" 
            ;;
        4) 
            run_factory_reset 
            ;;
        0) 
            echo -e "${CYAN}Goodbye!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Invalid Option!${NC}"
            sleep 1 
            ;;
    esac
    
    echo -e "\n${GRAY}Press Enter to return to main menu! ${NC}"
    read -r _unused </dev/tty
done