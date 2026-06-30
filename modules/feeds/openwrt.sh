#!/bin/sh

# shellcheck shell=ash

download_from_openwrt_feed() {
    local pkg_name=$1
    local ins_cmd=$2
    local log_file=$3

    local os_ver
    os_ver=$(ubus call system board 2>/dev/null | grep '"release":' | awk -F'"' '{print $4}' | grep -E '^[0-9]')
    [ -z "$os_ver" ] && os_ver="25.12.4"

    local extension="apk"
    [ "$PKG_MGR" = "opkg" ] && extension="ipk"

    local feeds_list="packages base luci routing"
    
    echo -e "➔ Scanning OpenWrt Official CDN for ${pkg_name}..."

    for feed in $feeds_list; do
        local download_url="https://downloads.openwrt.org/releases/${os_ver}/packages/${ARCH}/${feed}/${pkg_name}"
        
        if [ "$feed" = "base" ]; then
            local tgt_plat
            tgt_plat=$(ubus call system board 2>/dev/null | grep '"target":' | awk -F'"' '{print $4}')
            [ -z "$tgt_plat" ] && tgt_plat="ipq40xx/generic"
            download_url="https://downloads.openwrt.org/releases/${os_ver}/targets/${tgt_plat}/packages/${pkg_name}"
        fi

        local target_file="/tmp/${pkg_name}_download.${extension}"
        rm -f "$target_file"

        local c_opts="-sS -L --insecure --connect-timeout 6"
        [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

        if command -v curl >/dev/null 2>&1; then
            curl $c_opts -o "$target_file" "${download_url}*.${extension}" 2>/dev/null
        else
            wget -qO "$target_file" "${download_url}*.${extension}" 2>/dev/null
        fi

        if [ -s "$target_file" ]; then
            echo -e "   \033[32m✔ Package located in [$feed] feed. Injecting payload...\033[0m"
            $ins_cmd "$target_file" >> "$log_file" 2>&1
            local status=$?
            rm -f "$target_file"
            return $status
        fi
    done

    echo -e "   \033[90m↳ Not found in official OpenWrt feeds.\033[0m"
    return 1
}