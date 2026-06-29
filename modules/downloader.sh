#!/bin/sh
# shellcheck shell=ash
# Advanced Dynamic Downloader Powered by Curl with Local SOCKS5 Proxy Routing

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'passwall_packages' یا 'passwall_luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4
    local log_file=$5
    
    # ۱. نگاشت پوشه‌های سورس‌فورج
    local remote_folder="$sub_folder"
    if [ "$sub_folder" = "passwall_luci" ]; then
        remote_folder="passwall2"
    fi

    # ۲. اصلاح کلمه‌ی کلیدی بر اساس واقعیت نام‌گذاری فایل باینری xray
    local search_keyword="$keyword"
    if [ "$keyword" = "xray-core" ]; then
        search_keyword="xray-plugin"
    fi

    # ۳. تنظیمات کانفیگ و فلگ‌های برنده Curl تو برای عبور امن از فیلترینگ
    # استفاده از لایه پروکسی لوکال و لوپ کانکشن تروتمیز
    local curl_base_opts="-sS -L --insecure --tlsv1.2 --connect-timeout 8 --socks5-hostname 127.0.0.1:8090"
    
    # ۴. آدرس وب پوشه معماری روتر در سورس‌فورج جهت اسکن داینامیک
    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"

    print_status "work" "Scanning SourceForge registry for latest $keyword via Proxy Tunnel..."
    
    local exact_filename=""

    # ۵. تلاش برای اسکن آنلاین مخزن با ابزار curl (پلان A)
    if curl $curl_base_opts -o "$tmp_html" "$folder_url"; then
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    # ۶. پلان B: اگر اسکن آنلاین به هر دلیلی خالی بود، سوئیچ به آدرس پایدار
    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Registry scan blocked! Activating stable fallback path...${NC}"
        case "$keyword" in
            "xray-core") exact_filename="xray-plugin-1.8.24-r1.apk" ;;
            "tcping")    exact_filename="tcping-0.3-r1.apk" ;;
            "geoview")   exact_filename="geoview-2.0.2-r1.apk" ;;
            "sing-box")  exact_filename="sing-box-1.9.3-r1.apk" ;;
            "luci-app-passwall2")     exact_filename="luci-app-passwall2-4.77-r3.apk" ;;
            "luci-i18n-passwall2-fa") exact_filename="luci-i18n-passwall2-fa-4.77-r3.apk" ;;
        esac
    else
        echo -e "   \033[1;32m✔ Live Registry Decoded Successfully!${NC}"
    fi

    # ۷. ساخت لینک مستقیم دانلود نهایی دقیقا منطبق بر تست موفق خودت
    local full_download_url="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    # 🎯 فرمت و استایل خاکستری درخواستی و تمیز تو:
    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Target: $full_download_url${NC}"
    
    # ۸. دانلود نهایی فایل با باینری curl از روی میرور اصلی
    if curl $curl_base_opts -o "$tmp_target" "$full_download_url"; then
        print_status "sub" "Injecting into local APK Core..."
        
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
        print_status "failed" "Critical: Curl failed to pull $exact_filename from proxy link!"
        return 1
    fi
}