#!/bin/sh
# shellcheck shell=ash
# Direct Connection Download Module (No Proxy)

fetch_direct() {
    local folder_url=$1 local full_download_url=$2 local tmp_target=$3 local log_file=$4
    local curl_opts="-sS -L --insecure --tlsv1.2 --connect-timeout 8 --retry 2 --retry-delay 2"

    if [ -n "$folder_url" ] && [ -z "$full_download_url" ]; then
        curl $curl_opts "$folder_url"
        return $?
    fi

    curl $curl_opts -o "$tmp_target" "$full_download_url"
    return $?
}