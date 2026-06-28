#!/bin/sh
# shellcheck shell=ash
# Verified Native APK Repository Integrator & Core Installer

prepare_apk_repositories() {
    local arch=$1
    local custom_feeds_file="/etc/apk/repositories.d/customfeeds.list"
    
    # استخراج ورژن بیس سیستم (مثلا 25.12)
    local release
    release=$(. /etc/openwrt_release ; echo ${DISTRIB_RELEASE%.*} )
    [ -z "$release" ] && release="25.12"

    # ساختن پث‌های رسمی و تأیید شده بر اساس اسکریپت اصلی پاسوال
    local repo_packages="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/passwall_packages"
    local repo_luci="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/passwall2"
    
    # پاکسازی خطوط قدیمی جهت جلوگیری از تکرار
    mkdir -p /etc/apk/repositories.d
    [ -f "$custom_feeds_file" ] && sed -i '/openwrt-passwall-build/d' "$custom_feeds_file" 2>/dev/null
    
    # تزریق آدرس‌های کاملاً درست به فیدهای APK روتر
    echo "$repo_packages" >> "$custom_feeds_file"
    echo "$repo_luci" >> "$custom_feeds_file"
    
    # ریفرش کردن دیتابیس رسمی apk و کش کردن پکیج‌های جدید پاسوال
    echo "➔ Syncing remote package databases (pulling packages.adb)..."
    if apk update; then
        return 0
    else
        return 1
    fi
}

download_package_smart() {
    local sub_folder=$1   # این متغیر دیگر تأثیری ندارد چون فیدها یکبار به صورت سراسری ست شده‌اند
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3
    local ins_cmd=$4
    local log_file=$5
    
    # اجرای پروسه تنظیم فیدها و apk update فقط و فقط برای اولین پکیج
    if [ ! -f "/tmp/.sf_repo_synced" ]; then
        if prepare_apk_repositories "$arch"; then
            touch /tmp/.sf_repo_synced
        else
            echo "❌ Failed to sync Passwall repositories!"
            return 1
        fi
    fi
    
    echo "➔ Installing $keyword via Native APK Engine..."
    
    # نصب کاملاً نیتیو پکیج از روی فیدهای فعال شده
    # فلگ --allow-untrusted برای پکیج‌های بدون امضای پاسوال حیاتی است
    if apk add --allow-untrusted "$keyword" >> "$log_file" 2>&1; then
        echo "✔ $keyword integrated seamlessly!"
        return 0
    else
        echo "❌ APK engine rejected or failed to install $keyword!"
        return 1
    fi
}