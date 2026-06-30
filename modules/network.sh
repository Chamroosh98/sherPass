#!/bin/sh

# shellcheck shell=ash
# LAN IP Changer Module (OpenWrt UBUS Compliant)

change_lan_ip() {
    local target_ip="10.1.1.1"
    local current_ip
    current_ip=$(uci get network.lan.ipaddr 2>/dev/null)

    if [ "$current_ip" = "$target_ip" ]; then
        return 0
    fi

    echo -e "\n\033[1;35m➔ Migrating OpenWrt LAN IP address to $target_ip...\033[0m"
    
    uci set network.lan.ipaddr="$target_ip"
    uci commit network
    
    /etc/init.d/network restart >/dev/null 2>&1
    /etc/init.d/uhttpd restart >/dev/null 2>&1
}