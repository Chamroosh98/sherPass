#!/bin/sh
# shellcheck shell=ash
# Environment sanitizer and prerequisite installer

purge_conflicts() {
    local rm_cmd=$1
    local log_file=$2
    
    print_status "work" "Deep cleaning old/conflicting Passwall components"
    $rm_cmd luci-app-passwall luci-app-passwall2 luci-i18n-passwall2-fa v2ray-geoip v2ray-geosite sing-box xray-core >> "$log_file" 2>&1
    [ -f /etc/opkg/customfeeds.conf ] && sed -i '/passwall/d' /etc/opkg/customfeeds.conf 2>/dev/null
    [ -f /etc/apk/repositories ] && sed -i '/passwall/d' /etc/apk/repositories 2>/dev/null
    print_status "done" "System Environment Sanitized"
}

bootstrap_network() {
    local ins_cmd=$1
    local log_file=$2
    
    print_status "work" "Upgrading router network engines & SSL certificates"
    $ins_cmd wget curl ca-bundle libustream-openssl >> "$log_file" 2>&1
    print_status "done" "Network Engines Ready"
}

run_environment_setup() {
    purge_conflicts "$1" "$2"
    bootstrap_network "$1" "$2"
}