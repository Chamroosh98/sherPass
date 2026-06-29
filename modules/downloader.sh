#!/bin/sh

download_package_smart() {
    local sub_folder=$1   # یا 'packages' است یا 'luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4
    local log_file=$5
    
    # تعریف مستقیم ورژن‌ها بر اساس ریلیز ۲۵.۱۲ پاسوال برای پایداری ۱۰۰٪ بدون نیاز به دیتابیس آنلاین
    local version=""
    case "$keyword" in
        "xray-core") version="1.8.24-1" ;;
        "tcping") version="0.3-1" ;;
        "geoview") version="2.0.2-1" ;;
        "sing-box") version="1.9.3-1" ;;
        "luci-app-passwall2") version="4.77-3" ;;
        "luci-i18n-passwall2-fa") version="4.77-3" ;;
        *) version="latest" ;;
    esac

    # ساختن لینک مستقیم دانلود فایل .apk
    local base_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch/$sub_folder"
    local apk_file="${keyword}_${version}_${arch}.apk"
    
    # برای لوچی‌ها معماری در نام فایل وجود ندارد یا کلمه all است
    # if [ "$sub_folder" = "luci" ]; then
    #     apk_file="${keyword}_${version}_all.apk"
    # fi

    # local full_download_url="$base_url/$apk_file"
    local full_download_url="$base_url/"

    local tmp_target="/tmp/$apk_file"

    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Target: $full_download_url${NC}"

    # دانلود فایل با wget با فلگ تایم‌اوت و کانکشن امن
    if wget -qO "$tmp_target" "$full_download_url"; then
        print_status "sub" "Installing $apk_file via Native APK Core..."
        
        # نصب مستقیم فایل دانلود شده از روی دیسک موقت
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
        print_status "failed" "Network failed to fetch $keyword (Error 404/Timeout)!"
        return 1
    fi
}