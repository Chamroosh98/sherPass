#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  sherPass Framework - Core Network Orchestrator Logic Component
#  Architect: Chamroosh (ch4mr0sh)
#  Function: Multi-Engine Pulling, Smart Verification & Resilient Fallback
# ==============================================================================

download_package_smart() {
    local sub_folder=$1 local keyword=$2 local arch=$3 local ins_cmd=$4 local log_file=$5
    local space_path="/tmp/sherpass_space/modules/network"

    # ۱. Smart Check (بررسی هوشمند برای جلوگیری از دانلود تکراری و اتلاف حجم)
    if apk info -e "$keyword" >/dev/null 2>&1 || [ "$keyword" = "xray-core" ] && apk info -e "xray-plugin" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✔ [Skipped] $keyword is already deployed flawlessly. No re-download needed! ✨${NC}"
        return 0
    fi

    # ۲. لود منوی یو‌آی شبکه در صورت نیاز و عدم وجود کانفیگ قبلی
    if [ -z "$NET_MODE" ]; then
        . "$space_path/menu.sh"
        show_network_menu
    fi

    # ۳. نگاشت درست مسیرها و پکیج‌های سورس‌فورج
    local remote_folder="$sub_folder"
    [ "$sub_folder" = "passwall_luci" ] && remote_folder="passwall2"
    local search_keyword="$keyword"
    [ "$keyword" = "xray-core" ] && search_keyword="xray-plugin"

    # ۴. امپورت داینامیک ماژول کانکشن اختصاصی بر اساس انتخاب کاربر
    if [ "$NET_MODE" -eq 1 ]; then
        . "$space_path/direct.sh"
        local engine_mode="direct"
    else
        . "$space_path/proxy.sh"
        local engine_mode=$([ "$NET_MODE" -eq 2 ] && echo "proxy" || echo "smart-proxy")
    fi

    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html" local exact_filename=""

    print_status "work" "Scanning SourceForge registry for latest $keyword [Engine: $engine_mode]..."
    
    # اجرای اسکن آنلاین مخزن
    local html_content
    html_content=$([ "$engine_mode" = "direct" ] && fetch_direct "$folder_url" "" "" "$log_file" || fetch_proxy "$folder_url" "" "" "$log_file")

    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        echo "$html_content" > "$tmp_html"
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    # فال‌بک استاتیک و پایدار در صورت انسداد یا پکت‌لاست شدید روی اسکنر آنلاین
    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Registry scan blocked! Activating static fallback...${NC}"
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

    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Remote Link: $full_download_url${NC}"
    echo -e "   ${GRAY}💾 Local Destination: $tmp_target (RAM Storage)${NC}"

    # ۵. اجرای پروسه دانلود با مکانیزم تاب‌آوری بالا (Smart Proxy Auto-Fallback)
    local dl_status=1
    if [ "$engine_mode" = "direct" ]; then
        fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
    else
        fetch_proxy "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
        if [ $dl_status -ne 0 ] && [ "$engine_mode" = "smart-proxy" ]; then
            echo -e "   ${YELLOW}⚠️ Proxy dropped connection. Retrying via Direct Connection...${NC}"
            . "$space_path/direct.sh"
            fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
        fi
    fi

    # ۶. لایه تزریق نهایی فایل دریافت شده به هسته سیستم‌عامل روتر
    if [ $dl_status -eq 0 ]; then
        print_status "sub" "Injecting payload into local system core..."
        echo -e "   ${GRAY}⚙️ Engine Command: apk add --allow-untrusted $tmp_target${NC}"
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly! 🔥"
            rm -f "$tmp_target" && return 0
        fi
    fi
    print_status "failed" "Critical: Network execution failed for $keyword" && rm -f "$tmp_target" && return 1
}