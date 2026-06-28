#!/bin/sh
# shellcheck shell=ash
# LAN IP Changer Module

change_lan_ip() {
    local target_ip="10.1.1.1"
    local current_ip
    current_ip=$(uci get network.lan.ipaddr 2>/dev/null)

    if [ "$current_ip" = "$target_ip" ]; then
        print_status "done" "LAN IP is already configured to $target_ip"
        return 0
    fi

    print_status "work" "Changing OpenWrt LAN IP from $current_ip to $target_ip"
    uci set network.lan.ipaddr="$target_ip"
    uci commit network
    
    print_status "sub" "Applying network changes (Your local connection will adapt)"
    /etc/init.d/network restart >/dev/null 2>&1
    print_status "success" "LAN IP successfully migrated to $target_ip!"
}