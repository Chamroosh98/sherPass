#!/bin/sh
# shellcheck shell=ash
# Fail-Safe Hybrid Downloader (Dynamic Scan with Local Hardcoded Fallback)

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'passwall_packages' یا 'passwall_luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4
    local log_file=$5
    
    # ۱. نگاشت درست پوشه‌های سورس‌فورج
    local remote_folder="$sub_folder"
    if [ "$sub_folder" = "passwall_luci" ]; then
        remote_folder="passwall2"
    fi

    # ۲. اصلاح کلمه‌ی کلیدی بر اساس واقعیت نام‌گذاری فایل باینری xray
    local search_keyword="$keyword"
    if [ "$keyword" = "xray-core" ]; then
        search_keyword="xray-plugin"
    fi

    # ۳. آدرس وب پوشه معماری روتر در سورس‌فورج جهت اسکن داینامیک
    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"

    print_status "work" "Scanning SourceForge registry for latest $keyword..."
    
    local exact_filename=""

    # ۴. تلاش برای اسکن آنلاین (پلان A)
    if wget --tries=1 --timeout=4 -q -O "$tmp_html" "$folder_url"; then
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    # ۵. پلان B: اگر اسکن آنلاین به خاطر تایم‌اوت یا فیلترینگ ناموفق بود، از اسامی پایدار استفاده کن
    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Network restricted! Activating static fallback path...${NC}"
        case "$keyword" in
            "xray-core") exact_filename="xray-plugin-1.8.24-r1.apk" ;;
            "tcping")    exact_filename="tcping-0.3-r1.apk" ;;
            "geoview")   exact_filename="geoview-2.0.2-r1.apk" ;;
            "sing-box")  exact_filename="sing-box-1.9.3-r1.apk" ;;
            "luci-app-passwall2")     exact_filename="luci-app-passwall2-4.77-r3.apk" ;;
            "luci-i18n-passwall2-fa") exact_filename="luci-i18n-passwall2-fa-4.77-r3.apk" ;;
        esac
    else
        echo -e "   \033[1;32m✔ Dynamic Match Resolved Successfully!${NC}"
    fi

    # ۶. ساخت لینک مستقیم و نهایی دانلود
    local full_download_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    # 🎯 دقیقاً همان فرمت و استایل خاکستری درخواستی تو:
    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Target: $full_download_url${NC}"
    
    # ۷. دانلود مستقیم فایل باینری فیزیکی (با ۲ بار تلاش و تایم‌اوت بیشتر)
    if wget --tries=2 --timeout=15 -qO "$tmp_target" "$full_download_url"; then
        print_status "sub" "Injecting into local APK Core..."
        
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly! 🔥"
            rm -f "$tmp_target"
            return 0
        else
            print_status "failed" "APK engine rejected $exact_filename"
            rm -f "$tmp_target"
            return 1
        fi
    else
        print_status "failed" "Critical: Failed to download $exact_filename. Check your router internet connection!"
        return 1
    fi
}