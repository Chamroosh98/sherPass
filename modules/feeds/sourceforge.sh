#!/bin/sh
# shellcheck shell=ash

# تابع عمومی برای ثبت کلید و مخازن سورس‌فورج در سیستم
initialize_daypass_feeds() {
    local log_file=$1
    local key_destination="/etc/apk/keys/apk.pub"
    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    local apk_proxy=""
    [ "$NET_MODE" -ne 1 ] && apk_proxy="ALL_PROXY=socks5h://127.0.0.1:8090"

    # ۱. دانلود کلید عمومی در صورت عدم وجود
    if [ ! -f "$key_destination" ]; then
        echo -e "🔑 ${YELLOW}Injecting Passwall Trusted Public Key...${NC}"
        eval curl $c_opts -o "$key_destination" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub" >> "$log_file" 2>&1
    fi

    # ۲. ثبت هر ۳ دایرکتوری حیاتی سورس‌فورج برای دسترسی بدون نقص به پکیج‌ها و دپندنس‌ها
    local core_feeds="passwall_packages passwall_luci passwall2"
    local feed_added=0

    for feed in $core_feeds; do
        local repo_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${feed}"
        if ! grep -q "$feed" "$feed_file" 2>/dev/null; then
            echo -e "📡 ${YELLOW}Registering Feed [${feed}] into Custom Feeds...${NC}"
            echo "$repo_url" >> "$feed_file"
            feed_added=1
        fi
    done

    # ۳. اگر فید جدیدی اضافه شده، کل ایندکس apk را با پروکسی آپدیت کن
    if [ $feed_added -eq 1 ]; then
        echo -e "🔄 ${CYAN}Updating APK system indexes under Proxy tunnel...${NC}"
        eval "$apk_proxy apk update" >> "$log_file" 2>&1
    fi
}

# تابع هوشمند برای واکشی زنده لیست پکیج‌ها از روی فایل index.json سرور
fetch_feed_packages_json() {
    local repo_folder=$1
    local output_var=$2
    
    local json_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}/index.json"
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    # دانلود جی‌سان در حافظه موقت
    local raw_json
    raw_json=$(eval curl $c_opts "$json_url" 2>/dev/null)
    
    if [ -z "$raw_json" ]; then
        return 1
    fi

    # پارسر اختصاصی با awk برای استخراج نام کلیدهای بخش "packages"
    local parsed_list
    parsed_list=$(echo "$raw_json" | awk '
        /"packages":/ {flag=1; next}
        /}/ && flag {flag=0}
        flag {
            gsub(/[",:]/, "", $1);
            print $1
        }
    ')

    eval "$output_var=\"$parsed_list\""
    return 0
}