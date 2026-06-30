#!/bin/sh

run_online_loader() {
    local github_url=$1
    local target_base="/tmp/daypass_space/modules"
    local log_file="/tmp/DayPass.log"

    # لیست دقیق تمام ماژول‌های روت
    local core_modules="config cleaner zero_deps iran_rules cronjob validator banner passwd"
    local feed_modules="openwrt sourceforge"

    # ساخت فیزیکی دایرکتوری‌ها در رم روتر
    mkdir -p "${target_base}/feeds"
    mkdir -p "${target_base}/network"

    # تنظیمات پیش‌فرض کرل قبل از مشخص شدن حالت شبکه توسط کاربر (استفاده از سیستم هوشمند)
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    # ۱. دانلود ماژول شبکه (UI منو)
    if command -v curl >/dev/null 2>&1; then
        curl $c_opts -o "${target_base}/network/menu.sh" "${github_url}/modules/network/menu.sh?v=$(date +%s)" >> "$log_file" 2>&1
    else
        wget -qO "${target_base}/network/menu.sh" "${github_url}/modules/network/menu.sh?v=$(date +%s)" >> "$log_file" 2>&1
    fi

    # ۲. دانلود ماژول‌های روت اصلی
    for mod in $core_modules; do
        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "${target_base}/${mod}.sh" "${github_url}/modules/${mod}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        else
            wget -qO "${target_base}/${mod}.sh" "${github_url}/modules/${mod}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        fi
    done

    # ۳. دانلود ماژول‌های پوشه feeds
    for feed in $feed_modules; do
        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "${target_base}/feeds/${feed}.sh" "${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        else
            wget -qO "${target_base}/feeds/${feed}.sh" "${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        fi
    done

    # ⚡ [شاهکار خلوت‌سازی]: لود کردن خودکار و زنجیره‌ای تمام فایل‌های دانلود شده در حافظه محیط جاری
    . "${target_base}/network/menu.sh"
    for mod in $core_modules; do . "${target_base}/${mod}.sh"; done
    for feed in $feed_modules; do . "${target_base}/feeds/${feed}.sh"; done
}