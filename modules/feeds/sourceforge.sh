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
    
    echo -e "➔ Fetching ${pkg_name} directly from SourceForge registry..."
    
    local target_file="/tmp/${pkg_name}_sf.${extension}"
    rm -f "$target_file"

    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    if command -v curl >/dev/null 2>&1; then
        curl $c_opts -o "$target_file" "${sf_base}/${pkg_name}*.${extension}" >> "$log_file" 2>&1
    else
        wget -qO "$target_file" "${sf_base}/${pkg_name}*.${extension}" >> "$log_file" 2>&1
    fi

    if [ -s "$target_file" ]; then
        echo -e "   \033[32m✔ Payload extracted. Injecting into system core...\033[0m"
        $ins_cmd "$target_file" >> "$log_file" 2>&1
        local status=$?
        rm -f "$target_file"
        return $status
    fi

    echo -e "   \033[31m❌ SourceForge connection timed out or package mismatched.\033[0m"
    return 1
}