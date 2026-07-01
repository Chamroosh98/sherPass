#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Native APK Package Delivery & Feed Orchestrator (Fixed Proxies)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

print_status() {
    local type=$1 local msg=$2
    case "$type" in
        "work") echo -e "   ${YELLOW}➔${NC} $msg" ;;
        "success") echo -e "   ${GREEN}✔${NC} $msg" ;;
        "failed") echo -e "   ${RED}❌${NC} $msg" ;;
    esac
}

initialize_daypass_feeds() {
    local log_file=$1
    local key_destination="/etc/apk/keys/apk.pub"
    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    
    # ✨ فیکس شرط شبکه: گزینه 2 دایرکت است، پس برای بقیه حالت‌ها (1 و 3) پروکسی ست می‌شود
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 2 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    mkdir -p /etc/apk/keys /etc/apk/repositories.d

    # تزریق کلید عمومی سورس‌فورج
    if [ ! -f "$key_destination" ]; then
        echo -e "🔑 ${YELLOW}Injecting Passwall Trusted Public Key ...${NC}"
        eval curl $c_opts -o "$key_destination" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub" >> "$log_file" 2>&1
    fi

    # ساخت تمیز لیست فیدها با ساختار نیتیو packages.adb
    cat /dev/null > "$feed_file"
    local core_feeds="passwall_packages passwall_luci passwall2"
    for feed in $core_feeds; do
        local repo_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${feed}/packages.adb"
        echo -e "📡 ${YELLOW}Registering Feed [${feed}] into Custom Feeds ...${NC}"
        echo "$repo_url" >> "$feed_file"
    done

    # ✨ فیکس انقلابی پروکسی: اکسپورت سراسری متغیرها برای نفوذ به بازوهای دانلودر داخلی سیستم (uclient / wget)
    if [ "$NET_MODE" -ne 2 ]; then
        export ALL_PROXY="socks5h://127.0.0.1:8090"
        export all_proxy="socks5h://127.0.0.1:8090"
        export HTTP_PROXY="socks5h://127.0.0.1:8090"
        export http_proxy="socks5h://127.0.0.1:8090"
    fi

    # آپدیت سراسری ایندکس دیتابیس سیستم عامل با در نظر گرفتن پروکسی محیطی ارث‌بری شده
    echo -e "🔄 ${CYAN}Updating APK system indexes under Proxy tunnel ...${NC}"
    apk update --allow-untrusted >> "$log_file" 2>&1
}

fetch_feed_packages_json() {
    local repo_folder=$1 local output_var=$2
    local json_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}/index.json"
    
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 2 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    local raw_json
    raw_json=$(eval curl $c_opts "$json_url" 2>/dev/null)
    [ -z "$raw_json" ] && return 1

    local parsed_list
    parsed_list=$(echo "$raw_json" | awk '
        /"packages":/ {flag=1; next}
        /}/ && flag {flag=0}
        flag { gsub(/[",:]/, "", $1); print $1 }
    ')

    eval "$output_var=\"$parsed_list\""
    return 0
}

download_package_smart() {
    local sub_folder=$1 local keyword=$2 local arch=$3 local ins_cmd=$4 local log_file=$5

    # ۱. گارد چک کردن نصب بودن پکیج (برای جلوگیری از دوباره‌کاری)
    if apk info -e "$keyword" >/dev/null 2>&1; then
        echo -e "   ${GREEN}✔ [Skipped] $keyword is already installed natively! ✨${NC}"
        return 0
    fi

    # ۲. تمدید و تداوم پروکسی محیطی برای امنیت ساب‌شل‌ها و فرآیند نصب
    if [ "$NET_MODE" -ne 2 ]; then
        export ALL_PROXY="socks5h://127.0.0.1:8090"
        export all_proxy="socks5h://127.0.0.1:8090"
        export HTTP_PROXY="socks5h://127.0.0.1:8090"
        export http_proxy="socks5h://127.0.0.1:8090"
    fi

    print_status "work" "Installing ${CYAN}$keyword${NC} via native APK package manager..."

    # ۳. نصب کاملاً نیتیو و بدون تمپ
    apk add --allow-untrusted "$keyword" >> "$log_file" 2>&1

    # ۴. راستی‌آزمایی واقعی از دیتابیس سیستم
    if apk info -e "$keyword" >/dev/null 2>&1; then
        print_status "success" "${BOLD}$keyword${NC} deployed flawlessly via Custom Feed! 🔥"
        return 0
    else
        print_status "failed" "Critical : Failed to install $keyword natively. Check $log_file"
        return 1
    fi
}