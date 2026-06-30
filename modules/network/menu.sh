#!/bin/sh
# shellcheck shell=ash

show_network_menu() {
    clear
    echo -e "${CYAN}🌐 SELECT NETWORK DEPLOYMENT MODE${NC}"
    echo -e "  ${PURPLE}[1]${NC} Proxy Tunnel ${GRAY}(SOCKS5 127.0.0.1:8090)${NC}"
    echo -e "      ↳ Best if GitHub/SourceForge is blocked."
    echo -e "  ${PURPLE}[2]${NC} Direct Connection ${GRAY}(No Proxy)${NC}"
    echo -e "      ↳ Native router network bypass."
    echo -e "  ${PURPLE}[3]${NC} Smart Resilient Fallback ${GRAY}(Recommended)${NC}"
    echo -e "      ↳ Tries Proxy first, drops to Direct on loss."
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select network routing [1-3] (Default 3): "
    
    local net_choice; read -r net_choice </dev/tty
    case "$net_choice" in
        1) NET_MODE=2 ;;
        2) NET_MODE=1 ;;
        *) NET_MODE=3 ;;
    esac
    export NET_MODE
    echo -e "   ${GREEN}✔ Network configuration locked!${NC}\n"
    sleep 1
}