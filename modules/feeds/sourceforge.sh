#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Native APK Custom Feed Injector (SourceForge Edition)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

download_from_sourceforge_feed() {
    local repo_folder=$1
    local pkg_name=$2
    local ins_cmd=$3 # در اینجا همان apk add است
    local log_file=$4

    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    # لینک مستقیم دایرکتوری مخزن که حاوی پکیج‌ها و فایل packages.adb است
    local repo_url="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}"

    echo -e "🔎 Injecting SourceForge Custom Feed for ${CYAN}${pkg_name}${NC} ..."

    # ۱. ثبت مخزن در customfeeds.list در صورت عدم وجود
    if ! grep -q "$repo_folder" "$feed_file" 2>/dev/null; then
        echo -e "   ${GRAY}📡 Adding to Custom Feeds: $feed_file${NC}"
        # استفاده از --insecure برای مخازن بدون SSL تایید شده در روتر
        echo "$repo_url" >> "$feed_file"
        
        echo -e "   ${YELLOW}🔄 Synchronizing APK package index (packages.adb)...${NC}"
        apk update >> "$log_file" 2>&1
    fi

    # برای نمایش در UI
    echo -e "   ${GRAY}📡 Remote Registry : ${repo_url}/packages.adb${NC}"
    echo -e "   ${PURPLE}🚀 Requesting native APK core to pull and deploy ${pkg_name}...${NC}"

    # ۲. نصب مستقیم پکیج از مخزن جدید به همراه فلگ نادیده گرفتن سورس‌های بدون امضا
    if apk add --allow-untrusted "$pkg_name" >> "$log_file" 2>&1; then
        echo -e "   ${GREEN}✔ [Success] $pkg_name deployment complete via Native Package Manager!${NC}"
        return 0
    fi

    echo -e "   ${RED}❌ APK Engine failed to pull $pkg_name. Check network or repository integrity!${NC}"
    return 1
}