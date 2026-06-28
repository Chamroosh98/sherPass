#!/bin/sh

run_environment_setup() {
    local ins_cmd=$1
    local rem_cmd=$2
    local log_file=$3

    # تعریف پکیج‌هایی که پتانسیل تداخل دارند و باید پاکسازی شوند
    local targets="luci-app-passwall luci-app-passwall2 luci-i18n-passwall-fa luci-i18n-passwall2-fa xray-core sing-box tcping geoview v2ray-geosite-ir v2ray-geoip"
    
    echo -e "\n${PURPLE}➔ Deep cleaning old/conflicting Passwall components...${NC}"
    echo -e "${GRAY}   Scanning system registry for leftover packages...${NC}\n"

    # ۱. پیدا کردن پکیج‌های نصب شده واقعی جهت نمایش لیست اولیه
    local installed_list=""
    for pkg in $targets; do
        if apk info "$pkg" >/dev/null 2>&1; then
            installed_list="$installed_list $pkg"
            # نمایش لیست کاندیداها با رنگ خاکستری
            echo -e "   ${GRAY}⏳ Pending Removal: $pkg${NC}"
        fi
    done

    # اگر هیچ پکیج قدیمی پیدا نشد
    if [ -z "$installed_list" ]; then
        echo -e "   ${GREEN}✔ No conflicting components found. System is already clean!${NC}"
        echo -e "${GREEN}✔ System Environment Sanitized${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}   ⚡ Executing Purge Sequence:${NC}"

    # ۲. پروسه حذف دونه‌دونه همراه با تغییر رنگ زنده
    for pkg in $installed_list; do
        # چاپ وضعیت در حال حذف
        printf "   ${YELLOW}🔄 Removing $pkg ...${RC}"
        
        # اجرای دستور حذف در پس‌زمینه و هدایت خروجی به لاگ فایل
        if $rem_cmd "$pkg" >> "$log_file" 2>&1; then
            # پاک کردن خط فعلی ترمینال و جایگزینی با تیک سبز
            printf "\r\033[K   ${GREEN}✔ Successfully Removed: $pkg${NC}\n"
        else
            # در صورت بروز خطا به هر دلیل
            printf "\r\033[K   ${RED}❌ Failed to Remove: $pkg (Check log)${NC}\n"
        fi
        sleep 0.2 # یک تاخیر خیلی ریز برای اینکه چشم کاربر پروسه حرکت رو لمس کنه
    done

    # ۳. پاکسازی سرویس‌ها و فایروال‌های باقی‌مانده در پس‌زمینه
    rc-update del passwall default >/dev/null 2>&1
    /etc/init.d/passwall stop >/dev/null 2>&1
    rm -rf /etc/config/passwall /usr/share/passwall

    echo -e "\n${GREEN}✔ System Environment Sanitized Perfectly!${NC}"
}