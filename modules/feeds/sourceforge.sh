#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - SourceForge Passwall Registry Injector (Pure Registry)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

download_from_sourceforge_feed() {
    local repo_folder=$1
    local pkg_name=$2
    local ins_cmd=$3
    local log_file=$4

    local extension="apk"
    [ "$PKG_MGR" = "opkg" ] && extension="ipk"

    # آدرس ریشه مخزن سورس‌فورج شما
    local sf_base="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}"
    
    echo -e "🔎 Fetching ${CYAN}${pkg_name}${NC} directly from SourceForge registry ..."

    # 🛠️ حل مشکل ستاره (*): اسکن مخزن برای پیدا کردن نام کامل و دقیق فایل
    local exact_name=""
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    echo -e "   ${GRAY}📡 Scanning registry index for exact filename...${NC}"
    
    # واکشی فایل ایندکس سورس‌فورج و استخراج نام دقیق با Regex
    exact_name=$(curl $c_opts "$sf_base/" 2>/dev/null | grep -oE "${pkg_name}_[^\"'>]+\.${extension}" | head -n 1)

    # اگر به هر دلیلی نام دقیق در ایندکس یافت نشد، به عنوان آخرین شانس نام استاندارد را حدس می‌زنیم
    if [ -z "$exact_name" ]; then
        exact_name="${pkg_name}.${extension}"
    fi

    local download_url="${sf_base}/${exact_name}"
    local target_file="/tmp/${exact_name}"
    
    # 🌐 نمایش تمام مسیرهای دانلود، موقت و نصب نهایی برای UI بی‌نقص
    echo -e "   ${GRAY}📡 Remote Link  : ${download_url}${NC}"
    echo -e "   ${GRAY}📦 Temp Storage : ${target_file}${NC}"

    rm -f "$target_file"
    
    # پروسه دانلود فایل واقعی
    if command -v curl >/dev/null 2>&1; then
        curl $c_opts -o "$target_file" "$download_url" >> "$log_file" 2>&1
    else
        wget -qO "$target_file" "$download_url" >> "$log_file" 2>&1
    fi

    # تایید اصالت حجم فایل و اقدام به نصب
    if [ -s "$target_file" ]; then
        echo -e "   ${GREEN}✅ Payload extracted. Injecting into system core!${NC}"
        
        if [ "$PKG_MGR" = "apk" ]; then
            echo -e "   ${PURPLE}🚀 Installing via APK into system root storage...${NC}"
        else
            echo -e "   ${PURPLE}🚀 Installing via OPKG into system overlay storage...${NC}"
        fi

        # اجرای دستور نصب نهایی
        $ins_cmd "$target_file" >> "$log_file" 2>&1
        local status=$?
        
        if [ $status -eq 0 ]; then
            echo -e "   ${GREEN}✔ [Success] $pkg_name deployment complete. Binaries active.${NC}"
            rm -f "$target_file"
            return 0
        fi
    fi

    echo -e "   ${RED}❌ SourceForge connection timed out or payload corrupted!${NC}"
    rm -f "$target_file"
    return 1
}