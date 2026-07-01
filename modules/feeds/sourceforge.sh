#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Advanced Native Feed & JSON Registry Engine (Failsafe Sync)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

initialize_daypass_feeds() {
    local log_file=$1
    local key_destination="/etc/apk/keys/apk.pub"
    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    local apk_proxy=""
    [ "$NET_MODE" -ne 1 ] && apk_proxy="ALL_PROXY=socks5h://127.0.0.1:8090"

    # ایجاد دایرکتوری در صورت عدم وجود
    mkdir -p /etc/apk/keys /etc/apk/repositories.d

    # ۱. دانلود کلید عمومی با تضمین مسیر کامل
    if [ ! -f "$key_destination" ]; then
        echo -e "🔑 ${YELLOW}Injecting Passwall Trusted Public Key...${NC}"
        eval curl $c_opts -o "$key_destination" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub" >> "$log_file" 2>&1
    fi

    # ۲. ثبت هر ۳ مخزن به صورت تفکیک‌شده و تضمینی
    local core_feeds="passwall_packages passwall_luci passwall2"
    local feed_added=0

    # پاکسازی فایل فید قدیمی برای جلوگیری از تکرار یا خطوط خراب
    cat /dev/null > "$feed_file"

    for feed in $core_feeds; do
        local repo_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${feed}"
        echo -e "📡 ${YELLOW}Registering Feed [${feed}] into Custom Feeds...${NC}"
        echo "$repo_url" >> "$feed_file"
        feed_added=1
    done

    # ۳. آپدیت مخازن با موتور لوکال و پروکسی
    if [ $feed_added -eq 1 ]; then
        echo -e "🔄 ${CYAN}Updating APK system indexes under Proxy tunnel...${NC}"
        # آپدیت ایندکس‌ها با نادیده گرفتن خطاهای جزیی و فورس کردن لود کامل
        eval "$apk_proxy apk update --allow-untrusted" >> "$log_file" 2>&1
    fi
}

fetch_feed_packages_json() {
    local repo_folder=$1
    local output_var=$2
    
    local json_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}/index.json"
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    local raw_json
    raw_json=$(eval curl $c_opts "$json_url" 2>/dev/null)
    
    if [ -z "$raw_json" ]; then
        return 1
    fi

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