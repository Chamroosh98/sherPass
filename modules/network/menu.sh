#!/bin/sh
# shellcheck shell=ash

show_network_menu() {
    while true; do
        clear
        
        echo ""
        echo -e "${CYAN} ____              ____                    "
        echo -e "|  _ \\  __ _ _   _|  _ \\  __ _ ___ ___     "
        echo -e "| | | |/ _\` | | | | |_) / _\` / __/ __|    "
        echo -e "| |_| | (_| | |_| |  __/ (_| \\__ \\__ \\    "
        echo -e "|____/ \\__,_|\\__, |_|   \\__,_|___/___/    "
        echo -e "             |___/                         ${NC}"
        echo -e "${GRAY}Remembering the IRAN massacre on January 8 and 9, 2026 🕊️ ${NC}"
        echo -e "${GRAY}🐱 github.com/Chamroosh98${NC}"        
        echo -e "${PURPLE}───────────────────────────────────────────────────────${NC}"
        
        echo -e "${PURPLE} 📡 NETWORK GATEWAY ${NC}"
        echo -e "${NC}Choose one of way for Connection : ${NC}"
        echo -e "${PURPLE}-------------------------------------------------${NC}"
        echo -e "  ${PURPLE}[1]${NC} Proxy Tunnel ${GRAY}(SOCKS5 127.0.0.1:8090)${NC}"
        echo -e "  ${PURPLE}[2]${NC} Direct Connection ${GRAY}(No Proxy / Native System)${NC}"
        echo -e "  ${PURPLE}[3]${NC} Smart Resilient Fallback ${GRAY}(Recommended)${NC}"
        echo -e "  ${YELLOW}[H]${NC} Help & Advanced Connection Guide"
        echo -e "  ${RED}[0]${NC} Abort & Exit"
        echo -e ""
        printf "  Select network routing [1-3, H for Help, 0 to exit]: "
        
        local net_choice; read -r net_choice </dev/tty
        net_choice=$(echo "$net_choice" | tr -d ' ')

        case "$net_choice" in
            1)
                NET_MODE=2; export NET_MODE
                export http_proxy="socks5h://127.0.0.1:8090"
                export https_proxy="socks5h://127.0.0.1:8090"
                export HTTP_PROXY="socks5h://127.0.0.1:8090"
                export HTTPS_PROXY="socks5h://127.0.0.1:8090"
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Proxy Tunnel]!${NC}"
                echo -e "     ${GRAY}System proxies mapped to socks5h://127.0.0.1:8090${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            2)
                NET_MODE=1; export NET_MODE
                unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Direct Connection]!${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            3)
                NET_MODE=3; export NET_MODE
                export http_proxy="socks5h://127.0.0.1:8090"
                export https_proxy="socks5h://127.0.0.1:8090"
                export HTTP_PROXY="socks5h://127.0.0.1:8090"
                export HTTPS_PROXY="socks5h://127.0.0.1:8090"
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Smart Fallback]!${NC}"
                echo -e "     ${GRAY}Initial proxy handshake routed through SOCKS5 tunnel${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            [hH])
                clear
                echo ""
                echo -e "${YELLOW}💡 DAYPASS CONNECTION GUIDE:${NC}"
                echo -e "${PURPLE}-------------------------------------------------${NC}"
                echo -e "  If GitHub/SourceForge is censored or throttled on your infrastructure,"
                echo -e "  you must route the router traffic through an active workstation proxy ;D"
                echo ""
                echo -e "  ${CYAN}• 🐧 Linux Users (Via Hiddify | V2rayN | Throne | ...) :${NC}"
                echo -e "    Run this command from your local terminal [Konsole] BEFORE starting script for use of Remote Port Forwarding :"
                echo -e "    ssh -R 8090:localhost:10808 root@[router's ip ${GRAY} for example: 192.168.1.1${NC}]"
                echo ""
                echo -e "  ${CYAN}• 🪟 Windows Users (Via Hiddify | V2rayN | Throne | Nekoray | ...) :${NC}"
                echo -e "    1. Enable 'Allow LAN' inside v2rayN settings"
                echo -e "    2. Select any ssh application (like Putty, Bitvise, or ..)"
                echo -e "    3. Set 127.0.0.1:10808 for SOCKS/HTTP Proxy Forwarding in Network section!"
                echo -e "    4. Finally! Create a ssh session that use of this proxy!"
                echo -e "    "
                echo -e "${GRAY} Press Enter to return to the network selection menu ! ${NC}"
                read -r _unused </dev/tty
                ;;
            0)
                echo -e "\n${GREEN} Goodbye!${NC}"
                exit 0 ;;
            *)
                echo -e "\n${RED}[!] Critical: Invalid input ('$net_choice'). Please type 1, 2, 3, H or 0!${NC}\n"
                sleep 1 ;;
        esac
    done
}