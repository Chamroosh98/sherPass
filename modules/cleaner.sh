#!/bin/sh

run_environment_setup() {
    local ins_cmd=$1
    local rem_cmd=$2
    local log_file=$3

    local targets="luci-app-passwall luci-app-passwall2 luci-i18n-passwall-fa luci-i18n-passwall2-fa xray-core sing-box tcping geoview v2ray-geosite-ir v2ray-geoip"
    
    echo -e "\n${PURPLE}➔ Deep cleaning old/conflicting Passwall components...${NC}"
    
    local installed_list=""
    for pkg in $targets; do
        # فلگ -e در apk فقط پکیج‌هایی که واقعاً روی سیستم نصب هستند را تایید میکند
        if apk info -e "$pkg" >/dev/null 2>&1; then
            installed_list="$installed_list $pkg"
        fi
    done

    if [ -z "$installed_list" ]; then
        echo -e "   ${GREEN}✔ No installed conflicting components found. System is clean!${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}   ⚡ Executing Purge Sequence:${NC}"
    for pkg in $installed_list; do
        printf "   ${YELLOW}🔄 Removing $pkg ...${RC}"
        if $rem_cmd "$pkg" >> "$log_file" 2>&1; then
            printf "\r\033[K   \033[1;32m✔ Successfully Removed: $pkg\033[0m\n"
        else
            printf "\r\033[K   \033[1;31m❌ Failed to Remove: $pkg\033[0m\n"
        fi
        sleep 1
    done

    rc-update del passwall default >/dev/null 2>&1
    /etc/init.d/passwall stop >/dev/null 2>&1
    rm -rf /etc/config/passwall /usr/share/passwall
}