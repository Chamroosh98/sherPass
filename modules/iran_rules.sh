#!/bin/sh

# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh98
#  Dedicated to the immortal souls of 18-19 Dey 1404 🕊️
# ==============================================================================

# Smart routing rules module for Iran (DAT files)

URL_GEOSITE_IRAN="https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat"
URL_GEOIP_IRAN="https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat"
XRAY_ASSET_DIR="/usr/share/xray"

update_dat_files() {
    print_status "work" "Fetching latest Iran routing databases (DAT)"
    mkdir -p "$XRAY_ASSET_DIR"
    wget -qO /tmp/geosite.dat "$URL_GEOSITE_IRAN"
    wget -qO /tmp/geoip.dat "$URL_GEOIP_IRAN"

    if [ ! -s /tmp/geosite.dat ] || [ ! -s /tmp/geoip.dat ]; then
        print_status "failed" "Database download failed!"
        return 1
    fi
    print_status "done" "Databases Fetched"

    cp /tmp/geosite.dat "$XRAY_ASSET_DIR/geosite.dat"
    cp /tmp/geoip.dat "$XRAY_ASSET_DIR/geoip.dat"
    rm -f /tmp/geosite.dat /tmp/geoip.dat
    return 0
}

configure_uci_shunt() {
    print_status "work" "Injecting UCI Passwall Shunt structures"
    local rule_index=0
    local found_ir_rule=false
    
    while true; do
        local name=$(uci get passwall.@routing_rule[$rule_index].name 2>/dev/null)
        [ -z "$name" ] && break
        if [ "$name" = "Iran_Smart_Shunt" ]; then
            found_ir_rule=true
            break
        fi
        rule_index=$((rule_index + 1))
    done

    if [ "$found_ir_rule" = "false" ]; then
        uci add passwall routing_rule > /dev/null
        uci set passwall.@routing_rule[-1].name='Iran_Smart_Shunt'
        uci set passwall.@routing_rule[-1].enabled='1'
        uci set passwall.@routing_rule[-1].routing_mode='direct'
        rule_index=-1
    fi

    uci set passwall.@routing_rule[$rule_index].domain_list='geosite:ir'
    uci set passwall.@routing_rule[$rule_index].ip_list='geoip:ir'
    uci set passwall.main.dns_mode='xray'
    uci set passwall.main.remote_dns='1.1.1.1'
    uci set passwall.main.local_dns='178.22.122.100'
    
    uci commit passwall
    /etc/init.d/passwall restart >/dev/null 2>&1
    print_status "done" "Shunt Routing Live!"
}

run_iran_rules_module() {
    update_dat_files && configure_uci_shunt
}