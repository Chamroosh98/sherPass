#!/bin/sh

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'passwall_packages' یا 'passwall_luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4
    local log_file=$5
    
    # ۱. تنظیم نام پوشه فیزیکی روی سرور سورس‌فورج بر اساس ورودی اسکریپت اصلی
    local remote_folder="passwall_packages"
    if [ "$sub_folder" = "passwall_luci" ]; then
        remote_folder="passwall2"
    fi

    # ۲. ست کردن دقیق ورژن‌ها و اسامی فایل‌ها بر اساس واقعیت ریپوزیتوری ۲۵.۱۲
    local version=""
    local file_name=""
    
    case "$keyword" in
        "xray-core")
            version="1.8.24-r1"
            # طبق لاگ تست خودت، نام فایل روی سرور xray-plugin است
            file_name="xray-plugin_${version}_${arch}.apk"
            ;;
        "tcping")
            version="0.3-r1"
            file_name="tcping_${version}_${arch}.apk"
            ;;
        "geoview")
            version="2.0.2-r1"
            file_name="geoview_${version}_${arch}.apk"
            ;;
        "sing-box")
            version="1.9.3-r1"
            file_name="sing-box_${version}_${arch}.apk"
            ;;
        "luci-app-passwall2")
            version="4.77-r3"
            file_name="luci-app-passwall2_${version}_all.apk"
            ;;
        "luci-i18n-passwall2-fa")
            version="4.77-r3"
            file_name="luci-i18n-passwall2-fa_${version}_all.apk"
            ;;
        *)
            print_status "failed" "Unknown package: $keyword"
            return 1
            ;;
    esac

    # ۳. لینک ۱۰۰٪ درست سورس‌فورج (بخش /files/ به جای /releases/) همراه با چسباندن /download
    local full_download_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/${file_name}/download"
    local tmp_target="/tmp/${file_name}"

    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Target: $full_download_url${NC}"

    # ۴. دانلود و نصب آفلاین محلی
    if wget -qO "$tmp_target" "$full_download_url"; then
        print_status "sub" "Installing $file_name via Native APK Core..."
        
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