#!/bin/sh
# shellcheck shell=ash

run_online_loader() {
    local github_url=$1
    local target_base="/tmp/daypass_space/modules"
    local log_file="/tmp/DayPass.log"

    local core_modules="config cleaner zero_deps iran_rules cronjob validator banner passwd"
    local feed_modules="openwrt sourceforge"

    # تنظیم فلگ‌های دانلودر کرل متناسب با وضعیت شبکه انتخابی کاربر
    local c_opts="-sS -L --insecure --connect-timeout 8"
    
    if [ "$NET_MODE" -eq 2 ] || [ "$NET_MODE" -eq 3 ]; then
        # استفاده از تانل به صورت ایزوله و قفل شده در خود کامند
        c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    fi

    # ۱. دانلود ماژول‌های روت اصلی با استفاده از موتور کِرل تازه نصب شده
    for mod in $core_modules; do
        curl $c_opts -o "${target_base}/${mod}.sh" "${github_url}/modules/${mod}.sh?v=$(date +%s)" >> "$log_file" 2>&1
    done

    # ۲. دانلود ماژول‌های فید پکیج‌ها
    for feed in $feed_modules; do
        curl $c_opts -o "${target_base}/feeds/${feed}.sh" "${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)" >> "$log_file" 2>&1
    done

    # 🛡️ بررسی صحت دانلود و لود زنده در حافظه جاری سیستم
    for mod in $core_modules; do 
        if [ -s "${target_base}/${mod}.sh" ]; then
            . "${target_base}/${mod}.sh"
        else
            echo -e "   \033[31m❌ Critical Error: Failed to synchronize core module [${mod}.sh]\033[0m"
        fi
    done
    
    for feed in $feed_modules; do 
        if [ -s "${target_base}/feeds/${feed}.sh" ]; then
            . "${target_base}/feeds/${feed}.sh"
        fi
    done
}