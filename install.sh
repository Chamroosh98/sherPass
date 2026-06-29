#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  sherPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh (ch4mr0sh)
#  Components: Modular Network Orchestrator [Direct / SOCKS5 Proxy / Fallback]
# ==============================================================================

clear

echo -e "\033[38;5;141m┌───────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;141m│\033[0m   \033[1;38;5;51m⚡ sherPass Framework Engine Loading...     \033[0m\033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m└───────────────────────────────────────────────┘\033[0m"

LOG_FILE="/tmp/sherPass.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/sherPass/main"

# ۱. تشخیص خودکار مدیریت پکیج روتر
if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
fi

# ۲. استخراج معماری دقیق سیستمی پردازنده
if [ "$PKG_MGR" = "apk" ]; then
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

# ۳. دانلود و راه‌اندازی لودر آنلاین برای دریافت فایل‌های زیرمجموعه
if [ -f "./modules/loader.sh" ]; then
    . ./modules/loader.sh
else
    mkdir -p /tmp/sherpass_space/modules
    # استفاده از curl مجهز به پروکسی در صورت فعال بودن (برای حل مشکل لود اولیه)
    if command -v curl >/dev/null 2>&1; then
        curl -sS -L --insecure --socks5-hostname 127.0.0.1:8090 -o /tmp/sherpass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh" 2>/dev/null
    fi
    # فال‌بک روی wget در صورتی که بالا شکست خورد
    [ ! -f "/tmp/sherpass_space/modules/loader.sh" ] && wget -qO /tmp/sherpass_space/modules/loader.sh "$GITHUB_RAW_URL/modules/loader.sh"
    
    . /tmp/sherpass_space/modules/loader.sh
fi

# اجرای فرآیند دانلود و لود داینامیک تمام سورس‌ها از گیت‌هاب (شامل پکیج‌های شبکه)
run_online_loader "$GITHUB_RAW_URL" "$@"

# ۴. امپورت ماژول‌های سبک و تفکیک‌شده (بخش لاجیک فشرده)
. ./modules/config.sh
. ./modules/cleaner.sh
. /tmp/sherpass_space/modules/network/orchestrator.sh # لود ارکستراتور جدید شبکه
. ./modules/iran_rules.sh
. ./modules/cronjob.sh
. ./modules/validator.sh
. ./modules/banner.sh
. ./modules/network.sh
. ./modules/passwd.sh

[ "$1" = "--fallback-remote" ] && shift

# ۵. پروسه اصلی نصب بهینه‌سازی شده (گزینه ۱)
run_optimized_installation() {
    local raw_input=""
    local check_result=""
    local install_singbox="n"
    
    enforce_root_password

    echo -e "\n${YELLOW}⚡ Optimization Prompt:${NC}"
    while true; do
        printf "Do you want to install ${BOLD}sing-box${NC} core? (Heavy on low-end devices) [y/n]: "
        read -r raw_input </dev/tty
        check_result=$(validate_ascii_input "$raw_input")
        
        if [ "$check_result" = "non-ascii" ]; then
            echo -e "${RED}[!] Error: Invalid characters detected. Please switch your keyboard to English!${NC}\n"
            continue
        fi
        if [ "$check_result" = "empty" ]; then
            install_singbox="n"
            break
        fi
        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "${RED}[!] Error: Invalid choice.${NC}\n" ;;
        esac
    done
    
    # اجرای پاکسازی هوشمند تداخل‌ها بدون حذف کردن کارهای نصب شده شیرپاس
    echo -e "\n➔ Deep cleaning old/conflicting Passwall components..."
    if ! apk info -e "luci-app-passwall2" >/dev/null 2>&1; then
        echo -e "⚡ Executing Purge Sequence:"
        for pkg in tcping geoview xray-plugin sing-box luci-app-passwall; do
            if apk info -e "$pkg" >/dev/null 2>&1; then
                apk del "$pkg" >/dev/null 2>&1
                echo -e "   ${GREEN}✔ Successfully Removed: $pkg${NC}"
            fi
        done
    else
        echo -e "   ${GREEN}✔ Safe state detected. Skipping purge sequence to preserve active deployment!${NC}"
    fi
    
    # شروع فازهای دانلود با ارکستراتور ماژولار و زره‌پوش جدید
    echo -e "\n${BOLD}${CYAN}[Phase 1/2: Deploying Micro Proxy Cores]${NC}"
    download_package_smart "passwall_packages" "xray-core" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "tcping" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_packages" "geoview" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    if [ "$install_singbox" = "y" ]; then
        download_package_smart "passwall_packages" "sing-box" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi

    echo -e "${BOLD}${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_package_smart "passwall_luci" "luci-app-passwall2" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "passwall_luci" "luci-i18n-passwall2-fa" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    generate_custom_banner
    
    echo -e "${GREEN}${BOLD}✔ Deployment flawless! Passwall 2 Pro is fully running. 🔥${NC}"
    
    change_lan_ip
    echo -e "${YELLOW}👉 Please reconnect using the new IP: ${BOLD}10.1.1.1${NC}"
    exit 0
}

if [ "$1" = "--update-rules" ]; then
    run_iran_rules_module
    exit 0
fi

# ۶. هاب منوی اصلی و تعاملی سیستم (کامپوننت لوپ)
while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Xray + Core UI + Clean-up)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${PURPLE}[4]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [1-4]: "
    
    read -r choice </dev/tty
    [ -z "$choice" ] && continue
    
    case "$choice" in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read -r _unused </dev/tty
done