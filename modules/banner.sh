#!/bin/sh
# shellcheck shell=ash

generate_custom_banner() {
    clear

    echo ""
    echo -e "${CYAN} ____              ____                    "
    echo -e "|  _ \\  __ _ _   _|  _ \\  __ _ ___ ___     "
    echo -e "| | | |/ _\` | | | | |_) / _\` / __/ __|    "
    echo -e "| |_| | (_| | |_| |  __/ (_| \\__ \\__ \\    "
    echo -e "|____/ \\__,_|\\__, |_|   \\__,_|___/___/    "
    echo -e "             |___/                         ${NC}"
    echo -e "${GRAY}🕊️ Remembering the IRAN massacre on January 8 and 9, 2026 ... ${NC}"
    echo -e "${GRAY}🐱 github.com/Chamroosh98${NC}"
    echo -e "${PURPLE}───────────────────────────────────────────────────────${NC}"
}

draw_header() {
    local arch=$1
    local mgr=$2
    
    local router_model; router_model=$(ubus call system board 2>/dev/null | grep '"model":' | awk -F'"' '{print $4}')
    local os_release; os_release=$(ubus call system board 2>/dev/null | grep '"release":' | awk -F'"' '{print $4}')
    [ -z "$router_model" ] && router_model="Generic OpenWrt Device"
    [ -z "$os_release" ] && os_release="25.x (Bleeding Edge)"

    local public_ip; public_ip=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null)
    if [ -z "$public_ip" ]; then
        public_ip="${RED}No Internet / Blocked 🔒${NC}"
    else
        public_ip="${GREEN}${public_ip} 🌍${NC}"
    fi

    local total_mem used_mem free_mem
    total_mem=$(free -m | awk '/Mem:/ {print $2}')
    used_mem=$(free -m | awk '/Mem:/ {print $3}')
    free_mem=$(free -m | awk '/Mem:/ {print $4}')

    local rom_info rom_total rom_used rom_avail rom_percent
    rom_info=$(df -m / 2>/dev/null | tail -n 1)
    rom_total=$(echo "$rom_info" | awk '{print $2}')
    rom_used=$(echo "$rom_info" | awk '{print $3}')
    rom_avail=$(echo "$rom_info" | awk '{print $4}')
    rom_percent=$(echo "$rom_info" | awk '{print $5}')

    echo -e "${CYAN}SYSTEM TELEMETRY & RESOURCES:${NC}"
    echo -e "  💅 Router Model   : ${YELLOW}${router_model}${NC}"
    echo -e "  🩻 Firmware OS    : ${YELLOW}OpenWrt ${os_release}${NC}"
    echo -e "  🖥️ Core Arch      : ${arch}"
    echo -e "  🌍 Public WAN IP  : ${public_ip}"
    echo -e "  🧠 Memory (RAM)   : ${used_mem}MB Used / ${free_mem}MB Free (${total_mem}MB Total)"
    echo -e "  💾 Storage (ROM)  : ${rom_used}MB Used / ${rom_avail}MB Available (${rom_percent} Cache)"
    echo -e "  📦 Package Engine : ${GREEN}${mgr}${NC}"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    
    if [ -z "$(curl -s --connect-timeout 2 sourceforge.net 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️ SANCTION NOTICE :${NC} SourceForge connection throttled on this IP! 🫩🔫 "
        echo -e "  ${GRAY}🙂‍↔️ Bypass via Terminal :${NC} ssh -R 8090:localhost:10808 root@$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1")"
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    fi
}