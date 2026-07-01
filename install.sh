#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Core Bootstrapper & Lifecycle Orchestrator
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

clear

# ۱. لود مستقیم سورس موقت UI برای بالا آوردن متغیرها و رنگ‌ها
export BASE_MODULES="/tmp/daypass_space/modules"
export GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"

mkdir -p "${BASE_MODULES}/feeds" "${BASE_MODULES}/network"

# دانلود فایل سیستم ساز با محیط کاربری
INIT_OPTS="-sS -L --insecure --connect-timeout 10"
if command -v curl >/dev/null 2>&1; then
    curl $INIT_OPTS -o "${BASE_MODULES}/network/ui.sh" "${GITHUB_RAW_URL}/modules/network/ui.sh?v=$(date +%s)" 2>/dev/null
else
    wget -qO "${BASE_MODULES}/network/ui.sh" "${GITHUB_RAW_URL}/modules/network/ui.sh?v=$(date +%s)" 2>/dev/null
fi

if [ -s "${BASE_MODULES}/network/ui.sh" ]; then
    . "${BASE_MODULES}/network/ui.sh"
else
    echo -e "\033[31m❌ Critical : UI Layer configuration component missing!\\033[0m"
    exit 1
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
export ARCH PKG_MGR INSTALL_CMD REMOVE_CMD

echo -e "${YELLOW}🚗 Bootstrapping DayPass Core Engine! ${NC}"

# دانلود سریع دیگر اسکلت‌های اولیه سیستم از گیت‌هاب
if command -v curl >/dev/null 2>&1; then
    curl $INIT_OPTS -o "${BASE_MODULES}/zero_deps.sh" "${GITHUB_RAW_URL}/modules/zero_deps.sh?v=$(date +%s)" 2>/dev/null
    curl $INIT_OPTS -o "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
    curl $INIT_OPTS -o "${BASE_MODULES}/network/menu.sh" "${GITHUB_RAW_URL}/modules/network/menu.sh?v=$(date +%s)" 2>/dev/null
else
    wget -qO "${BASE_MODULES}/zero_deps.sh" "${GITHUB_RAW_URL}/modules/zero_deps.sh?v=$(date +%s)" 2>/dev/null
    wget -qO "${BASE_MODULES}/loader.sh" "${GITHUB_RAW_URL}/modules/loader.sh?v=$(date +%s)" 2>/dev/null
    wget -qO "${BASE_MODULES}/network/menu.sh" "${GITHUB_RAW_URL}/modules/network/menu.sh?v=$(date +%s)" 2>/dev/null
fi

# تزریق وابستگی‌های حیاتی و منوی شبکه
. "${BASE_MODULES}/zero_deps.sh" && deploy_system_dependencies "$PKG_MGR" "$INSTALL_CMD" "$LOG_FILE"
. "${BASE_MODULES}/network/menu.sh" && show_network_menu

echo -e "${YELLOW}⏰ Synchronizing remaining DayPass core modules! ${NC}"
. "${BASE_MODULES}/loader.sh" && run_online_loader "$GITHUB_RAW_URL" "$@"

# لود ماژول‌های ارکستراتور بومی شبکه و بنر
[ -s "${BASE_MODULES}/network/orchestrator.sh" ] && . "${BASE_MODULES}/network/orchestrator.sh"
if [ -s "${BASE_MODULES}/banner.sh" ]; then . "${BASE_MODULES}/banner.sh"; else exit 1; fi

run_optimized_installation() {
    enforce_root_password
    echo -e "\n${CYAN}📦 Initializing DayPass Secure Feed Environments ...${NC}"
    initialize_daypass_feeds "$LOG_FILE"

    local passwall_version="" install_mode="" target_packages=""
    
    # فراخوانی ویزارد تمیز از فایل UI
    render_installation_wizard "passwall_version" "install_mode"

    if [ "$install_mode" = "1" ]; then
        target_packages="xray-core tcping geoview"
        if [ "$passwall_version" = "passwall2" ]; then
            target_packages="${target_packages} luci-app-passwall2 luci-i18n-passwall2-fa"
        else
            target_packages="${target_packages} luci-app-passwall luci-i18n-passwall-fa"
        fi
    else
        echo -e "\n${CYAN}📡 Fetching live registry list from SourceForge index.json ...${NC}"
        local core_list="" luci_list="" full_available_list=""
        fetch_feed_packages_json "passwall_packages" "core_list"
        fetch_feed_packages_json "$passwall_version" "luci_list"
        
        for p in $core_list $luci_list; do [ -n "$p" ] && full_available_list="${full_available_list} $p"; done

        if [ -z "$full_available_list" ]; then
            echo -e "${RED}❌ Error: Online registry blocked! Falling back to essentials.${NC}"
            target_packages="xray-core tcping geoview"
        else
            # رندر ماتریس چند انتخابی پکیج‌ها از فایل UI
            render_expert_matrix "$full_available_list" "target_packages"
        fi
    fi

    # اجرای نهایی نصب نیتیو با ارکستراتور اصلی
    echo -e "\n${CYAN}🌐 [Phase 1/2 : Deploying Micro Proxy Components via Native Core]${NC}"
    for pkg in $target_packages; do
        [ -z "$pkg" ] && continue
        download_package_smart "$passwall_version" "$pkg" "$ARCH" "$INSTALL_CMD" "$LOG_FILE"
    done

    echo -e "\n${GREEN}🔥 Deployment session processed! DayPass Engine is operational! ${NC}"
    exit 0
}

run_factory_reset() {
    echo -e "${RED}⚠️ WARNING : This will completely wipe the router! ${NC}"
    printf "😶‍🌫️ Are you sure? (y/n) : "
    read -r confirm </dev/tty
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] && firstboot -y && reboot
}

# 📱 هاب اصلی و سبک منوی تعاملی
while true; do
    clear; generate_custom_banner; draw_header "$ARCH" "$PKG_MGR"
    
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Cores + LuCI Selection)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${RED}[4] Factory Reset Router ${GRAY}(Emergency Recovery)${NC}"
    echo -e "  ${PURPLE}[0]${NC} Exit\n─────────────────────────────────────────────────"
    printf "  Select an option [0-4]: " && read -r choice </dev/tty
    
    case "$choice" in
        1) clear; generate_custom_banner; run_optimized_installation ;;
        2) clear; generate_custom_banner; run_iran_rules_module ;;
        3) clear; generate_custom_banner; setup_auto_update "$LOG_FILE" ;;
        4) run_factory_reset ;;
        0) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\n${GRAY}Press Enter to return to main menu! ${NC}" && read -r _unused </dev/tty
done