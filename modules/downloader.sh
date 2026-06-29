#!/bin/sh
# shellcheck shell=ash
# Bulletproof Dynamic Downloader with Exact User-Requested Logging Format

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

    # دانلود سریع صفحه وب برای پیدا کردن نام فایل (با تایم‌اوت ۵ ثانیه‌ای)
    if ! wget --tries=2 --timeout=5 -q -O "$tmp_html" "$folder_url"; then
        print_status "failed" "Network Timeout! SourceForge is unreachable. Check router DNS/Internet."
        return 1
    fi

    # ۴. استخراج داینامیک نام کامل فایل از روی سورس صفحه
    local exact_filename=""
    exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)

    rm -f "$tmp_html" # پاکسازی فوری رم روتر

    if [ -z "$exact_filename" ]; then
        print_status "failed" "Could not find any online binary matching: $search_keyword"
        return 1
    fi

    # ۵. ساخت لینک مستقیم و نهایی دانلود مشابه ساختار برنده تو
    local full_download_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    # 🎯 دقیقاً همان فرمت و استایلی که فرستادی:
    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Target: $full_download_url${NC}"
    
    # ۶. دانلود مستقیم فایل باینری با فیکس تایم‌اوت
    if wget --tries=2 --timeout=10 -qO "$tmp_target" "$full_download_url"; then
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
        print_status "failed" "Failed to download $exact_filename (Network/Mirror error)!"
        return 1
    fi
}