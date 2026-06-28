#!/bin/sh
# LAN IP Changer Module

change_lan_ip() {
    local target_ip="10.1.1.1"
    local current_ip
    current_ip=$(uci get network.lan.ipaddr 2>/dev/null)

    if [ "$current_ip" = "$target_ip" ]; then
        return 0
    fi

    # استفاده از echo ساده به جای print_status تا اگر هنوز config.sh لود نشده بود اسکریپت کرش نکند
    echo "➔ Changing OpenWrt LAN IP to $target_ip..."
    uci set network.lan.ipaddr="$target_ip"
    uci commit network
    /etc/init.d/network restart >/dev/null 2>&1
}