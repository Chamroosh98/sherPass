#!/bin/sh

download_package_smart() {
    local sub_folder=$1   # مقدار ورودی 'packages' یا 'luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری روتر
    local ins_cmd=$4      # پکیج منیجر دیفالت
    local log_file=$5

    # ۱. اصلاح نام پوشه بر اساس تست موفقیت‌آمیز تو
    local folder_name="passwall_packages"
    if [ "$sub_folder" = "luci" ]; then
        folder_name="luci"
    fi

    # ۲. ساخت لینک استاندارد وب‌سایت سورس‌فورج که قابلیت ریدایرکت به میرورهای زنده را دارد
    # طبق مستندات رسمی APK، ته آدرس فید علامت ! می‌گذاریم تا پکیج‌منیجر اسم معماری را دوباره در ته پث تکرار نکند!
    local repo_target="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/$arch/$folder_name!"

    print_status "work" "Deploying ${BOLD}$keyword${NC} via Dynamic Remote Feed..."
    echo -e "   ${GRAY}🔗 Repository Target: $repo_target${NC}"

    # ۳. نصب زنده و مستقیم با استفاده از مخزن کاستوم بدون تداخل با کل سیستم
    if apk add --repository "$repo_target" --allow-untrusted "$keyword" >> "$log_file" 2>&1; then
        print_status "success" "${BOLD}$keyword${NC} integrated seamlessly!"
        return 0
    else
        print_status "failed" "APK Engine couldn't fetch $keyword from mirror targets."
        echo -e "${RED}[!] Check system log at: $log_file${NC}"
        return 1
    fi
}