#!/bin/sh
# shellcheck shell=ash
# 100% Dynamic SourceForge HTML Parser & Live APK Installer

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'passwall_packages' یا 'passwall_luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4
    local log_file=$5
    
    # ۱. نگاشت پوشه فرستاده شده از install.sh به پوشه واقعی در سورس‌فورج
    local remote_folder="$sub_folder"
    if [ "$sub_folder" = "passwall_luci" ]; then
        remote_folder="passwall2"
    fi

    # ۲. اصلاح کلمه‌ی کلیدی سرچ برای لایه باینری xray
    local search_keyword="$keyword"
    if [ "$keyword" = "xray-core" ]; then
        search_keyword="xray-plugin"
    fi

    # ۳. آدرس وب پوشه مشخص در سورس‌فورج
    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"

    print_status "work" "Scanning SourceForge registry for latest ${BOLD}$keyword${NC}..."

    # ۴. دانلود صفحه وب پوشه برای پیدا کردن اسامی فایل‌ها
    if ! wget -q -O "$tmp_html" "$folder_url"; then
        print_status "failed" "Network error: Unable to scan remote directory!"
        return 1
    fi

    # ۵. استخراج داینامیک نام کامل فایل از سورس HTML صفحه (بدون هاردکد ورژن!)
    local exact_filename=""
    exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -F "$search_keyword" | head -n 1)

    rm -f "$tmp_html" # پاکسازی فوری رم روتر

    if [ -z "$exact_filename" ]; then
        print_status "failed" "Could not find any valid .apk file matching $keyword on server!"
        return 1
    fi

    echo -e "   \033[1;32m✔ Resolved Online:\033[0m $exact_filename"

    # ۶. ساخت لینک مستقیم دانلود نهایی و دانلود فایل فیزیکی
    local download_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}/download"
    local tmp_target="/tmp/${exact_filename}"

    print_status "sub" "Downloading resolved binary..."
    if wget -qO "$tmp_target" "$download_url"; then
        print_status "sub" "Injecting into local APK Core..."
        
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly!"
            rm -f "$tmp_target"
            return 0
        else
            print_status "failed" "APK engine rejected the installation of $keyword!"
            rm -f "$tmp_target"
            return 1
        fi
    else
        print_status "failed" "Failed to download $exact_filename from mirror network!"
        return 1
    fi
}