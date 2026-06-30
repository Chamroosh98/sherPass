#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Automated Online Module Synchronizer & Dynamic Loader
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

run_online_loader() {
    local github_url=$1
    local target_base="/tmp/daypass_space/modules"
    local log_file="/tmp/DayPass.log"

    local core_modules="config cleaner zero_deps iran_rules cronjob validator banner passwd"
    local feed_modules="openwrt sourceforge"

    # تنظیمات نهایی آپشن‌های شبکه بر اساس انتخاب دقیق کاربر در منو
    local c_opts="-sS -L --insecure --connect-timeout 8"
    if [ "$NET_MODE" -eq 1 ]; then
        # حالت پروکسی تونل SOCKS5
        c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    elif [ "$NET_MODE" -eq 3 ]; then
        # حالت هوشمند (تست اول با پروکسی)
        c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    fi

    # ۱. دانلود ماژول‌های روت اصلی
    for mod in $core_modules; do
        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "${target_base}/${mod}.sh" "${github_url}/modules/${mod}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        else
            wget -qO "${target_base}/${mod}.sh" "${github_url}/modules/${mod}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        fi
    done

    # ۲. دانلود ماژول‌های فید پکیج‌ها
    for feed in $feed_modules; do
        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "${target_base}/feeds/${feed}.sh" "${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        else
            wget -qO "${target_base}/feeds/${feed}.sh" "${github_url}/modules/feeds/${feed}.sh?v=$(date +%s)" >> "$log_file" 2>&1
        fi
    done

    # لود نهایی تمام ماژول‌ها در مموری رام روتر
    for mod in $core_modules; do . "${target_base}/${mod}.sh"; done
    for feed in $feed_modules; do . "${target_base}/feeds/${feed}.sh"; done
}