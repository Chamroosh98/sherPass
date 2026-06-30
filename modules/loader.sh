#!/bin/sh
# shellcheck shell=ash

run_online_loader() {
    local github_url=$1
    local target_base="/tmp/daypass_space/modules"
    local log_file="/tmp/DayPass.log"

    # لیست تمام ماژول‌های اصلی مستقر در پوشه modules
    local core_modules="config cleaner zero_deps iran_rules cronjob validator banner network passwd"
    
    # لیست ماژول‌های مستقر در زیرپوشه feeds
    local feed_modules="openwrt sourceforge"

    # مطمئن شدن از وجود دایرکتوری‌ها به صورت فیزیکی در رم روتر
    mkdir -p "${target_base}/feeds"

    # تنظیمات آپشن‌های کِرل بر اساس وضعیت شبکه انتخابی کاربر
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    # ۱. دانلود ماژول‌های روتِ اصلی
    for mod in $core_modules; do
        local mod_url="${github_url}/modules/${mod}.sh?v=$(date +%s)"
        local dest_file="${target_base}/${mod}.sh"

        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "$dest_file" "$mod_url" >> "$log_file" 2>&1
        else
            wget -qO "$dest_file" "$mod_url" >> "$log_file" 2>&1
        fi

        # بررسی سلامت دانلود فایل
        if [ ! -s "$dest_file" ]; then
            echo -e "   \033[31m❌ Critical Error: Failed to synchronize core module [${mod}.sh]\033[0m"
        fi
    done

    # ۲. دانلود ماژول‌های داخل پوشه feeds
    for feed in $feed_modules; do
        local feed_url="${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)"
        local dest_feed_file="${target_base}/feeds/${feed}.sh"

        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "$dest_feed_file" "$feed_url" >> "$log_file" 2>&1
        else
            wget -qO "$dest_feed_file" "$feed_url" >> "$log_file" 2>&1
        fi

        # بررسی سلامت دانلود فیدها
        if [ ! -s "$dest_feed_file" ]; then
            echo -e "   \033[31m❌ Critical Error: Failed to synchronize feed module [${feed}.sh]\033[0m"
        fi
    done
}