#!/bin/sh
# shellcheck shell=ash
# Final Bulletproof Dynamic HTML Parser & Direct Downloader (With Fail-Safe Timeout)

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

    # ۳. آدرس وب پوشه معماری روتر در سورس‌فورج
    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"

    print_status "work" "Scanning SourceForge for latest $keyword..."

    # ۴. دانلود صفحه وب با محدودیت زمان و تلاش (جلوگیری از هک شدن/قفل کردن اسکریپت)
    # --tries=2 : فقط ۲ بار تلاش کن
    # --timeout=5 : اگر بعد از ۵ ثانیه وصل نشد انصراف بده
    if ! wget --tries=2 --timeout=5 -q -O "$tmp_html" "$folder_url"; then
        print_status "failed" "Network Timeout! SourceForge is unreachable. Check router DNS/Internet."
        return 1
    fi

    # ۵. استخراج داینامیک نام کامل فایل
    local exact_filename=""
    exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)

    rm -f "$tmp_html" # پاکسازی رم

    if [ -z "$exact_filename" ]; then
        print_status "failed" "Could not find any online binary matching: $search_keyword"
        return 1
    fi

    echo -e "   \033[1;32m✔ Dynamic Match Found:\033[0m $exact_filename"

    # ۶. ساخت لینک مستقیم و نهایی
    local download_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    print_status "sub" "Downloading payload directly..."
    
    # دانلود مستقیم فایل باینری با فیکس تایم‌اوت
    if wget --tries=2 --timeout=10 -qO "$tmp_target" "$download_url"; then
        print_status "sub" "Injecting into local APK Core..."
        
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed successfully!"
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