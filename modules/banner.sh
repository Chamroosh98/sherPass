#!/bin/sh
# shellcheck shell=ash

generate_custom_banner() {
    local PURPLE="\033[38;5;141m"
    local CYAN="\033[1;38;5;51m"
    local GRAY="\033[90m"
    local GREEN="\033[32m"
    local NC="\033[0m"

    clear
    echo -e "${PURPLE}  ____              ____               ${NC}"
    echo -e "${PURPLE} |  _ \\  __ _ _   _|  _ \\ __ _ ___ ___ ${NC}"
    echo -e "${PURPLE} | | | |/ _\` | | | | |_) / _\` / __/ __|${NC}"
    echo -e "${PURPLE} | |_| | (_| | |_| |  __/ (_| \\__ \\__ \\${NC}"
    echo -e "${PURPLE} |____/ \\__,_|\\__, |_|   \\__,_|___/___/${NC}"
    echo -e "${PURPLE}              |___/                    ${NC}"
    echo -e "  ${CYAN}☀️ DayPass Framework Engine Active${NC}"
    echo -e "  ${GRAY}⭐ Deployed by Chamroosh98 ${NC}"
    echo -e "${PURPLE}---------------------------------------------------------${NC}"
    
    local ram_total ram_free ram_used
    ram_total=$(free -m | grep Mem | awk '{print $2}')
    ram_free=$(free -m | grep Mem | awk '{print $4}')
    ram_used=$((ram_total - ram_free))

    echo -e "  ${CYAN}SYSTEM TELEMETRY & RESOURCES:${NC}"
    echo -e "${PURPLE}---------------------------------------------------------${NC}"
    echo -e "  • Memory (RAM)  : ${ram_used}MB Used / ${ram_free}MB Free (${ram_total}MB Total)"
    
    if command -v df >/dev/null 2>&1; then
        local rom_info
        rom_info=$(df -h / | tail -n 1)
        local rom_used=$(echo "$rom_info" | awk '{print $3}')
        local rom_avail=$(echo "$rom_info" | awk '{print $4}')
        local rom_pct=$(echo "$rom_info" | awk '{print $5}')
        echo -e "  • Storage (ROM) : ${rom_used} Used / ${rom_avail} Available (${rom_pct})"
    fi
    echo -e "${PURPLE}---------------------------------------------------------${NC}"
}

draw_header() {
    local arch=$1
    local pkg_mgr=$2
    
    echo -e "\n${PURPLE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}    ${CYAN}DayPass Pro Auto-Installer Component${NC}       ${PURPLE}│${NC}"
    echo -e "${PURPLE}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  Arch: ${arch}    ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  Manager: ${pkg_mgr}                                 ${PURPLE}│${NC}"
    echo -e "${PURPLE}└───────────────────────────────────────────────┘${NC}"
}