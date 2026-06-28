#!/bin/sh
# shellcheck shell=ash
# Native APK Database (packages.adb) Integrator & Core Installer

# تابعی برای آماده‌سازی و تزریق فیدها به فایل رسمی customfeeds.list
prepare_apk_repositories() {
    local arch=$1
    local custom_feeds_file="/etc/apk/repositories.d/customfeeds.list"
    
    # ساختن پث‌های رسمی فیدهای پاسوال
    local repo_packages="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch/packages"
    local repo_luci="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch/luci"
    
    print_status "work" "Integrating Passwall Pro feeds into customfeeds.list"
    
    # بک‌آپ گرفتن از فایل قبلی در صورت وجود و پاکسازی خطوط قدیمی پاسوال جهت جلوگیری از تکرار
    mkdir -p /etc/apk/repositories.d
    [ -f "$custom_feeds_file" ] && sed -i '/openwrt-passwall-build/d' "$custom_feeds_file" 2>/dev/null
    
    # تزریق آدرس‌ها دقیقاً طبق ساختار استاندارد داکیومنت رسمی اوپن‌ورت (بدون نیاز به نوشتن لایو packages.adb در ته لایو لینک، خود apk ایندکس رو سرچ میکنه)
    echo "$repo_packages" >> "$custom_feeds_file"
    echo "$repo_luci" >> "$custom_feeds_file"
    
    # ریفرش کردن و دانلود باینری دیتابیس packages.adb از سورس‌فورج
    print_status "sub" "Syncing remote package databases (pulling packages.adb)..."
    if apk update; then
        print_status "done" "Database synchronized with SourceForge successfully."
        return 0
    else
        print_status "failed" "Failed to sync packages.adb database! Please check internet connection."
        return 1
    fi
}

download_package_smart() {
    local sub_folder=$1   # جهت حفظ ساختار قبلی در install.sh (اینجا نیازی به آن نداریم چون مخزن یکبار ست شده)
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3
    local ins_cmd=$4
    local log_file=$5
    
    # یک کلید فلگ در حافظه موقت می‌سازیم که پروسه سنگین apk update فقط یکبار در فاز اول اجرا بشه، نه لایو برای تک‌تک پکیج‌ها!
    if [ ! -f "/tmp/.sf_repo_synced" ]; then
        prepare_apk_repositories "$arch" || return 1
        touch /tmp/.sf_repo_synced
    fi
    
    print_status "work" "Installing ${BOLD}$keyword${NC} via Native APK Engine"
    
    # نصب پکیج مستقیماً از دیتابیس لوکال شده‌ی packages.adb
    # آپشن --allow-untrusted برای دور زدن خطای پکیج‌های بدون امضای دیجیتال (Self-signed) پاسوال الزامی است
    if apk add --allow-untrusted "$keyword"; then
        print_status "success" "${BOLD}$keyword${NC} deployed successfully!"
        return 0
    else
        print_status "failed" "APK engine rejected or failed to install $keyword!"
        return 1
    fi
}