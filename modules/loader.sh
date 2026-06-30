#!/bin/sh

# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh98
#  Dedicated to the immortal souls of 18-19 Dey 1404 🕊️
# ==============================================================================

# shellcheck shell=ash
# sherPass Dynamic Component Loader with Sub-Directory Support

run_online_loader() {
    local base_url=$1
    local remote_space="/tmp/sherpass_space/modules"
    
    # تعریف لیست تمام ماژول‌های استاندارد در روتِ modules
    local core_modules="config cleaner iran_rules zero_deps cronjob validator banner network passwd"
    
    # تعریف لیست ماژول‌های جدید دایرکتوری network
    local network_modules="menu direct proxy orchestrator"

    # ساخت دایرکتوری‌های لازم در رم روتر
    mkdir -p "$remote_space/network"
    cd "$remote_space" || return 1

    # فلگ‌های برنده‌ی curl شما برای عبور از فیلترینگ گیت‌هاب حین دانلود ماژول‌ها
    local curl_opts="-sS -L --insecure --connect-timeout 6 --socks5-hostname 127.0.0.1:8090"

    # ۱. دانلود ماژول‌های اصلی روت
    for mod in $core_modules; do
        if [ ! -f "./${mod}.sh" ]; then
            curl $curl_opts -o "./${mod}.sh" "$base_url/modules/${mod}.sh" 2>/dev/null
            [ ! -f "./${mod}.sh" ] && wget -qO "./${mod}.sh" "$base_url/modules/${mod}.sh"
        fi
    done

    # ۲. دانلود ماژول‌های زیرمجموعه پوشه network (حل مشکل ارور خط ۵۴)
    for net_mod in $network_modules; do
        if [ ! -f "./network/${net_mod}.sh" ]; then
            curl $curl_opts -o "./network/${net_mod}.sh" "$base_url/modules/network/${net_mod}.sh" 2>/dev/null
            [ ! -f "./network/${net_mod}.sh" ] && wget -qO "./network/${net_mod}.sh" "$base_url/modules/network/${net_mod}.sh"
        fi
    done
    
    # بازگشت به مسیر پیش‌فرض حافظه موقت جهت امپورت بی‌دردسر
    cd /tmp/sherpass_space || return 1
}