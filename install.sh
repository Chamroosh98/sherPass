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
    enforce_root_password
    
    # راه‌اندازی و سینک مخازن و کلید معتبر سورس‌فورج قبل از شروع
    echo -e "\n${CYAN}📦 Initializing DayPass Secure Feed Environments ...${NC}"
    initialize_daypass_feeds "$LOG_FILE"

    local apk_proxy=""
    [ "$NET_MODE" -ne 1 ] && apk_proxy="ALL_PROXY=socks5h://127.0.0.1:8090"

    # 1️⃣ مرحله اول: انتخاب ورژن Passwall (UX بی‌نقص)
    local passwall_version=""
    echo -e "\n${YELLOW}🛠️ Passwall Generation Choice :${NC}"
    echo -e "  ${PURPLE}[1]${NC} Passwall 1 ${GRAY}(Classic Stable - Core + LuCI Legacy)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Passwall 2 ${GRAY}(Modern Advanced - Future Proof)${NC}"
    while true; do
        printf "  Select Framework Version [1-2]: "
        read -r v_choice </dev/tty
        case "$v_choice" in
            1) passwall_version="passwall_luci"; break ;;
            2) passwall_version="passwall2"; break ;;
            *) echo -e "${RED}[!] Invalid Choice!${NC}" ;;
        esac
    done

    # 2️⃣ مرحله دوم: انتخاب نوع دپلویمنت (Recommended vs Expert)
    local install_mode=""
    echo -e "\n${YELLOW}🚀 Installation Strategy :${NC}"
    echo -e "  ${PURPLE}[1]${NC} Recommended Mode ${GREEN}(Installs: Cores, Essentials + Persian Pack)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Expert Custom Menu ${YELLOW}(Fetch Live Registry & Toggle Packages)${NC}"
    while true; do
        printf "  Select Strategy [1-2]: "
        read -r m_choice </dev/tty
        case "$m_choice" in
            1|2) install_mode="$m_choice"; break ;;
            *) echo -e "${RED}[!] Invalid Choice!${NC}" ;;
        esac
    done

    local target_packages=""

    if [ "$install_mode" = "1" ]; then
        # 🌟 حالت اتوماتیک و توصیه‌شده (ضد کرش و سریع)
        target_packages="xray-core tcping geoview"
        if [ "$passwall_version" = "passwall2" ]; then
            target_packages="${target_packages} luci-app-passwall2 luci-i18n-passwall2-fa"
        else
            target_packages="${target_packages} luci-app-passwall luci-i18n-passwall-fa"
        fi
    else
        # 🧙‍♂️ حالت حرفه‌ای: واکشی آنلاین لیست پکیج‌ها از index.json مخزن انتخابی
        echo -e "\n${CYAN}📡 Fetching live registry list from SourceForge index.json ...${NC}"
        local core_list="" luci_list=""
        
        fetch_feed_packages_json "passwall_packages" "core_list"
        fetch_feed_packages_json "$passwall_version" "luci_list"
        
        local full_available_list=""
        for p in $core_list $luci_list; do
            # فیلتر کردن موارد تکراری یا نال
            [ -n "$p" ] && full_available_list="${full_available_list} $p"
        done

        if [ -z "$full_available_list" ]; then
            echo -e "${RED}❌ Error: Failed to fetch online registry index! Falling back to essentials.${NC}"
            target_packages="xray-core tcping geoview"
        else
            # منوی تعاملی چند انتخابی (Multi-Select Matrix Menu)
            while true; do
                clear
                generate_custom_banner
                echo -e "${YELLOW}🎯 Expert Deployment Matrix (Select/Toggle Packages):${NC}"
                echo -e "${GRAY}Enter number to Select/Deselect. Type ${GREEN}'i'${GRAY} to start Installation.${NC}\n"
                
                local idx=1
                for item in $full_available_list; do
                    local status_flag="[ ]"
                    if echo "$target_packages" | grep -q "\<$item\>"; then
                        status_flag="${GREEN}[✓]${NC}"
                    fi
                    echo -e "  ${PURPLE}[$idx]${NC} $status_flag $item"
                    idx=$((idx + 1))
                done
                
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                printf "⌨️ Enter Option Number or 'i' to install: "
                read -r exp_input </dev/tty
                
                if [ "$exp_input" = "i" ] || [ "$exp_input" = "I" ]; then
                    [ -z "$target_packages" ] && { echo -e "${RED}Please select at least one package!${NC}"; sleep 1; continue; }
                    break
                fi
                
                # پیدا کردن آیتم انتخاب شده بر اساس ایندکس عددی
                local selected_item
                selected_item=$(echo "$full_available_list" | awk -v target="$exp_input" '{print $target}')
                
                if [ -n "$selected_item" ]; then
                    if echo "$target_packages" | grep -q "\<$selected_item\>"; then
                        # حذف از لیست انتخابی
                        target_packages=$(echo "$target_packages" | sed "s/\<$selected_item\>//g")
                    else
                        # اضافه به لیست انتخابی
                        target_packages="${target_packages} ${selected_item}"
                    fi
                else
                    echo -e "${RED}Invalid Selection!${NC}"
                    sleep 0.5
                fi
            done
        fi
    fi

    # 3️⃣ مرحله نهایی: دپلویمنت امن و قطاری پکیج‌های برگزیده
    echo -e "\n${CYAN}🌐 [Phase 1/2 : Deploying Micro Proxy Components via Native Feed]${NC}"
    
    for pkg in $target_packages; do
        [ -z "$pkg" ] && continue
        echo -e "➔ Deploying ${CYAN}${pkg}${NC} via secure native core..."
        echo -e "   ${GRAY}🚀 Command: apk add $pkg${NC}"
        
        if eval "$apk_proxy apk add --allow-untrusted $pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "   ${GREEN}✔ [Success] $pkg successfully installed!${NC}"
        else
            echo -e "   ${RED}⚠️ [Warning/Failed] APK engine encountered a roadblock on $pkg!${NC}"
            echo -e "   ${GRAY}Check logs at $LOG_FILE for conflict resolution.${NC}"
        fi
    done

    echo -e "\n${GREEN}🔥 Deployment session processed! DayPass Engine is operational! ${NC}"
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