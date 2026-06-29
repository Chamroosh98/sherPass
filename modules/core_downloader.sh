#!/bin/sh

# 🌐 تابع داخلی برای مدیریت منوی انتخاب شبکه
show_network_menu() {
    clear
    echo -e "${PURPLE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}       ${BOLD}🌐 SELECT NETWORK DEPLOYMENT MODE${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[1] Proxy Tunnel (SOCKS5 127.0.0.1:8090)${NC}    ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Best if GitHub/SourceForge is blocked.${NC} ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[2] Direct Connection (No Proxy)${NC}            ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Native router network bypass.${NC}          ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[3] Smart Resilient Fallback (Recommended)${NC}   ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Tries Proxy first, drops to Direct on loss.${NC}${PURPLE}│${NC}"
    echo -e "${PURPLE}└───────────────────────────────────────────────┘${NC}"
    printf "  Select network routing [1-3] (Default 3): "
    
    local net_choice
    read -r net_choice </dev/tty
    
    case "$net_choice" in
        1) NET_MODE=2 ;; # پروکسی خالص
        2) NET_MODE=1 ;; # دایرکت خالص
        *) NET_MODE=3 ;; # هوشمند / پیشنهادی
    esac
    export NET_MODE
    echo -e "   ${GREEN}✔ Network configuration locked!${NC}\n"
    sleep 1
}

# 📥 تابع اصلی ارکستراتور برای دانلود و تزریق پکیج‌ها
download_package_smart() {
    local sub_folder=$1 local keyword=$2 local arch=$3 local ins_cmd=$4 local log_file=$5

    # نگاشت درست دایرکتوری‌های سورس‌فورج
    local remote_folder="$sub_folder"
    [ "$sub_folder" = "passwall_luci" ] && remote_folder="passwall2"

    local search_keyword="$keyword"
    [ "$keyword" = "xray-core" ] && search_keyword="xray-plugin"

    # اگر کاربر هنوز شبکه رو انتخاب نکرده، اول منو رو بهش نشون بده (فقط یک‌بار برای پکیج اول)
    if [ -z "$NET_MODE" ]; then
        show_network_menu
    fi

    # لود داینامیک انجین بر اساس کانفیگ ست شده در منو
    if [ "$NET_MODE" -eq 1 ]; then
        . /tmp/sherpass_space/modules/network/direct.sh
        local engine_mode="direct"
    elif [ "$NET_MODE" -eq 2 ]; then
        . /tmp/sherpass_space/modules/network/proxy.sh
        local engine_mode="proxy"
    else
        . /tmp/sherpass_space/modules/network/proxy.sh
        local engine_mode="smart-proxy"
    fi

    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"
    local exact_filename=""

    print_status "work" "Scanning SourceForge registry for latest $keyword [Engine: $engine_mode]..."

    # اجرای اسکن آنلاین از طریق تابع ماژول امپورت شده
    if [ "$engine_mode" = "direct" ]; then
        local html_content; html_content=$(fetch_direct "$folder_url" "" "" "$log_file")
    else
        local html_content; html_content=$(fetch_proxy "$folder_url" "" "" "$log_file")
    fi

    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        echo "$html_content" > "$tmp_html"
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    # هاردکد استاتیک برای سناریوهای پکت‌لاست کور کننده
    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Registry scan blocked or Packet Loss detected! Activating static fallback...${NC}"
        case "$keyword" in
            "xray-core") exact_filename="xray-plugin-1.8.24-r1.apk" ;;
            "tcping")    exact_filename="tcping-0.3-r1.apk" ;;
            "geoview")   exact_filename="geoview-2.0.2-r1.apk" ;;
            "sing-box")  exact_filename="sing-box-1.9.3-r1.apk" ;;
            "luci-app-passwall2")     exact_filename="luci-app-passwall2-4.77-r3.apk" ;;
            "luci-i18n-passwall2-fa") exact_filename="luci-i18n-passwall2-fa-4.77-r3.apk" ;;
        esac
    fi

    local full_download_url="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    # لاگ‌های خاکستری شفاف و بسیار شیک تو
    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Remote Link: $full_download_url${NC}"
    echo -e "   ${GRAY}💾 Local Destination: $tmp_target (RAM Storage)${NC}"

    # پروسه دانلود نهایی
    local dl_status=1
    if [ "$engine_mode" = "direct" ]; then
        fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"
        dl_status=$?
    else
        fetch_proxy "" "$full_download_url" "$tmp_target" "$log_file"
        dl_status=$?
        
        # 🛡️ اگر روی حالت اسمارت بود و پروکسی ارور داد، بلافاصله شانس مجدد با اینترنت مستقیم
        if [ $dl_status -ne 0 ] && [ "$engine_mode" = "smart-proxy" ]; then
            echo -e "   ${YELLOW}⚠️ Proxy core dropped connection. Retrying immediately via Direct Connection...${NC}"
            . /tmp/sherpass_space/modules/network/direct.sh
            fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"
            dl_status=$?
        fi
    fi

    # لایه تزریق فیزیکی به اوپن‌ورت
    if [ $dl_status -eq 0 ]; then
        print_status "sub" "Injecting payload into local system core..."
        echo -e "   ${GRAY}⚙️ Engine Command: apk add --allow-untrusted $tmp_target${NC}"
        
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly! 🔥"
            rm -f "$tmp_target"
            return 0
        else
            print_status "failed" "APK engine rejected $exact_filename Layout"
            rm -f "$tmp_target"
            return 1
        fi
    else
        print_status "failed" "Critical: Network execution failed to pull $exact_filename under all fallback modes!"
        return 1
    fi
}