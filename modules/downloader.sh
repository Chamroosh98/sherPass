#!/bin/sh
# shellcheck shell=ash
# Native & Clean APK Repository Downloader Module

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'packages' یا 'luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4      
    local log_file=$5

    # ۱. نگاشت داینامیک پوشه‌ها بر اساس ساختار مخزن سورس‌فورج
    local folder_name="passwall_packages"
    if [ "$sub_folder" = "luci" ]; then
        folder_name="luci"
    fi

    # ۲. ساخت لینک استاندارد فید سورس‌فورج
    # علامت ! در انتهای آدرس به apk دستور می‌دهد که از تکرار نام معماری خودداری کند
    local repo_target="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${folder_name}!"

    echo "➔ Deploying $keyword via Remote Feed..."
    echo "   🔗 Target: $repo_target"

    # ۳. نصب زنده و مستقیم با استفاده از مخزن کاستوم بدون تداخل با کل سیستم
    if apk add --repository "$repo_target" --allow-untrusted "$keyword" >> "$log_file" 2>&1; then
        echo "✔ $keyword integrated seamlessly!"
        return 0
    else
        echo "❌ APK Engine couldn't fetch $keyword from mirror targets."
        echo "   👉 Check system log at: $log_file"
        return 1
    fi
}