#!/bin/sh
# shellcheck shell=ash
# Proxy Tunnel Download Module (SOCKS5)

fetch_proxy() {
    local folder_url=$1 local full_download_url=$2 local tmp_target=$3 local log_file=$4
    local curl_opts="-sS -L --insecure --tlsv1.2 --connect-timeout 8 --socks5-hostname 127.0.0.1:8090 --retry 2 --retry-delay 2"
    
    if [ -n "$folder_url" ] && [ -z "$full_download_url" ]; then
        curl $curl_opts "$folder_url"
        return $?
    fi

    curl $curl_opts -o "$tmp_target" "$full_download_url"
    return $?
}