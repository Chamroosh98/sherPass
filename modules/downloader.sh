#!/bin/sh
# shellcheck shell=ash
# Fully Dynamic Native APK Database Resolver & Downloader

download_package_smart() {
    local sub_folder=$1   # مقدار 'packages' یا 'luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4      
    local log_file=$5

    # ۱. اصلاح نام پوشه‌ها بر اساس ساختار دقیق رپو سورس‌فورج
    local folder_name="passwall_packages"
    [ "$sub_folder" = "luci" ] && folder_name="luci"

    # ۲. آدرس دیتابیس باینری پکیج‌ها (این فایل اسمش ثابت و همیشه در دسترس است)
    local base_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${folder_name}"
    local db_url="${base_url}/packages.adb/download"
    local local_db="/tmp/packages_${folder_name}.adb"

    # ۳. دانلود فایل دیتابیس پکیج‌ها به حافظه موقت روتر در صورت عدم وجود
    if [ ! -f "$local_db" ]; then
        echo "➔ Fetching remote index (${folder_name}/packages.adb)..."
        if ! wget -q -O "$local_db" "$db_url" >> "$log_file" 2>&1; then
            echo "❌ Failed to fetch database index for $folder_name"
            return 1
        fi
    fi

    echo "➔ Resolving latest version for $keyword..."

    # ۴. استخراج داینامیک نام کامل فایل و ورژن از دیتابیس باینری (بدون هاردکد کردن!)
    local exact_filename
    exact_filename=$(strings "$local_db" | grep -E "^${keyword}_[0-9].*\.apk$" | head -n 1)

    if [ -z "$exact_filename" ]; then
        # بک‌آپ برای پکیج‌هایی که ممکنه خط تیره یا ساختار نام‌گذاری خاصی داشته باشند
        exact_filename=$(strings "$local_db" | grep -F "$keyword" | grep "\.apk" | head -n 1)
    fi

    if [ -z "$exact_filename" ]; then
        echo "❌ Could not resolve filename for $keyword inside packages.adb"
        return 1
    fi

    echo "   ✔ Found Latest: $exact_filename"

    # ۵. ساخت لینک دانلود مستقیم فایل واقعی .apk بر اساس ورژنی که داینامیک پیدا شد
    local full_download_url="${base_url}/${exact_filename}/download"
    local local_apk="/tmp/${exact_filename}"

    echo "➔ Downloading resolved binary..."
    if wget -q -O "$local_apk" "$full_download_url" >> "$log_file" 2>&1; then
        
        # ۶. نصب آفلاین و امن پکیج دانلود شده بدون بازی با ریپوزیتوری‌های آنلاین سیستم
        echo "➔ Injecting $exact_filename into system..."
        if apk add --allow-untrusted "$local_apk" >> "$log_file" 2>&1; then
            echo "✔ $keyword deployed dynamically!"
            rm -f "$local_apk"
            return 0
        else
            echo "❌ APK engine rejected $exact_filename"
            rm -f "$local_apk"
            return 1
        fi
    else
        echo "❌ Network error while downloading $exact_filename"
        return 1
    fi
}