#!/bin/sh
# shellcheck shell=ash

download_from_sourceforge_feed() {
    local repo_folder=$1
    local pkg_name=$2
    local ins_cmd=$3
    local log_file=$4

    local extension="apk"
    [ "$PKG_MGR" = "opkg" ] && extension="ipk"

    local sf_base="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}"
    local download_url="${sf_base}/${pkg_name}*.${extension}"
    local target_file="/tmp/${pkg_name}_sf.${extension}"
    
    echo -e "🔎 Fetching ${CYAN}${pkg_name}${NC} directly from SourceForge registry ..."
    
    rm -f "$target_file"

    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    echo -e "   ${GRAY}📡 Remote Link  : ${download_url}${NC}"
    echo -e "   ${GRAY}📦 Temp Storage : ${target_file}${NC}"

    if command -v curl >/dev/null 2>&1; then
        curl $c_opts -o "$target_file" "$download_url" >> "$log_file" 2>&1
    else
        wget -qO "$target_file" "$download_url" >> "$log_file" 2>&1
    fi

    if [ -s "$target_file" ]; then
        echo -e "   ${GREEN}✅ Payload extracted! Injecting into system core ... ${NC}"
        
        # 🚚 نمایش مقصد نهایی فایل‌ها در فریمور روتر
        echo -e "   ${PURPLE}🚀 Extracting package elements into /usr/share/ and configuration nodes ...${NC}"

        $ins_cmd "$target_file" >> "$log_file" 2>&1
        local status=$?
        
        if [ $status -eq 0 ]; then
            echo -e "   ${GREEN}✅ Deployment complete! Configuration links active in LuCI interface.${NC}"
        fi

        rm -f "$target_file"
        return $status
    fi

    echo -e "   ${RED}🥴 SourceForge connection timed out or package mismatched!${NC}"
    return 1
}