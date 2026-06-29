#!/bin/sh
# shellcheck shell=ash
# Network UI Menu Module

show_network_menu() {
    clear
    echo -e "${PURPLE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}       ${BOLD}🌐 SELECT NETWORK DEPLOYMENT MODE${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[1] Proxy Tunnel (SOCKS5 127.0.0.1:8090)${NC}    ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Best if GitHub/SourceForge is blocked.${NC} ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[2] Direct Connection (No Proxy)${NC}            ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Native router network bypass.${NC}          ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}[3] Smart Resilient Fallback (Recommended)${NC}   ${PURPLE}│${NC}"
    echo -e "${PURPLE}│      ${GRAY}↳ Tries Proxy first, drops to Direct on loss.${NC}${PURPLE}│${NC}"
    echo -e "${PURPLE}└───────────────────────────────────────────────┘${NC}"
    printf "  Select network routing [1-3] (Default 3): "
    
    local net_choice; read -r net_choice </dev/tty
    case "$net_choice" in
        1) NET_MODE=2 ;; # پروکسی خالص
        2) NET_MODE=1 ;; # دایرکت خالص
        *) NET_MODE=3 ;; # هوشمند
    esac
    export NET_MODE
    echo -e "   ${GREEN}✔ Network configuration locked!${NC}\n"
    sleep 1
}