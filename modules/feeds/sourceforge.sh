#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Native Trusted Repository Provisioner
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

setup_secure_sourceforge_feed() {
    local repo_folder=$1
    local log_file=$2

    local key_destination="/etc/apk/keys/apk.pub"
    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    local repo_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}"

    # آپشن‌های پروکسی برای عبور مطمئن از فیلترینگ
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    local apk_proxy=""
    [ "$NET_MODE" -ne 1 ] && apk_proxy="ALL_PROXY=socks5h://127.0.0.1:8090"

    # ۱. دانلود کلید عمومی در صورت عدم وجود
    if [ ! -f "$key_destination" ]; then
        echo -e "🔑 ${YELLOW}Injecting Passwall Trusted Public Key...${NC}"
        echo -e "   ${GRAY}📡 Target: $key_destination${NC}"
        eval curl $c_opts -o "$key_destination" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub" >> "$log_file" 2>&1
    fi

    # ۲. ثبت فید اختصاصی سورس‌فورج و آپدیت سراسری با پروکسی
    if ! grep -q "$repo_folder" "$feed_file" 2>/dev/null; then
        echo -e "📡 ${YELLOW}Registering Passwall Feed into Custom Feeds...${NC}"
        echo "$repo_url" >> "$feed_file"
        
        echo -e "🔄 ${CYAN}Updating APK system indexes under Proxy tunnel...${NC}"
        eval "$apk_proxy apk update" >> "$log_file" 2>&1
    fi
}