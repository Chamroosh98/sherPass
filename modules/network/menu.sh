#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Advanced Network UI Boot-Menu (Pixel Perfect Edition)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

show_network_menu() {
    while true; do
        clear
        
        # 👑 رندر لوگوی اصلاح شده و بدون خط اضافه سقف (مطابق تراز تصویر day.png)
        echo ""
        echo -e "${CYAN} ____              ____                    "
        echo -e "|  _ \\  __ _ _   _|  _ \\  __ _ ___ ___     "
        echo -e "| | | |/ _\` | | | | |_) / _\` / __/ __|    "
        echo -e "| |_| | (_| | |_| |  __/ (_| \\__ \\__ \\    "
        echo -e "|____/ \\__,_|\\__, |_|   \\__,_|___/___/    "
        echo -e "             |___/                         ${NC}"
        echo -e " Remembering the IRAN massacre on January 8 and 9, 2026 🕊️"
        echo -e " ⭐️ Deployed by Chamroosh"
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
        
        echo -e "📡 ${CYAN}DAYPASS NETWORK GATEWAY${NC}"
        echo -e "${GRAY}Configure deployment routing before core synchronization${NC}"
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
        echo -e "  ${PURPLE}[1]${NC} Proxy Tunnel ${GRAY}(SOCKS5 127.0.0.1:8090)${NC}"
        echo -e "  ${PURPLE}[2]${NC} Direct Connection ${GRAY}(No Proxy / Native System)${NC}"
        echo -e "  ${PURPLE}[3]${NC} Smart Resilient Fallback ${GRAY}(Recommended)${NC}"
        echo -e "  ${YELLOW}[H]${NC} Help & Advanced Connection Guide"
        echo -e "  ${RED}[0]${NC} Abort & Exit"
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
        printf "  Select network routing [1-3, H for Help, 0 to exit]: "
        
        local net_choice; read -r net_choice </dev/tty
        net_choice=$(echo "$net_choice" | tr -d ' ')

        case "$net_choice" in
            1)
                NET_MODE=2; export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Proxy Tunnel]!${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            2)
                NET_MODE=1; export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Direct Connection]!${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            3)
                NET_MODE=3; export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Smart Fallback]!${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo ""; sleep 1; break ;;
            [hH])
                clear
                echo ""
                echo -e "${YELLOW}💡 DAYPASS PRO-DEVELOPER CONNECTION GUIDE:${NC}"
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                echo -e "  If GitHub/SourceForge is censored or throttled on your infrastructure,"
                echo -e "  you must route the router traffic through an active workstation proxy."
                echo ""
                echo -e "  ${CYAN}• Linux / macOS (Via Remote Port Forwarding):${NC}"
                echo -e "    Run this command from your local terminal BEFORE starting script:"
                echo -e "    ${GRAY}ssh -R 8090:localhost:10808 root@[router's ip for example 192.168.1.1]${NC}"
                echo ""
                echo -e "  ${CYAN}• Windows Users (Via v2rayN / netsh / Nekoray):${NC}"
                echo -e "    Enable 'Allow LAN' inside v2rayN settings, or map port 8090"
                echo -e "    directly to your Windows proxy server listener (default 10808)."
                echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
                printf "  Press Enter to return to the network selection menu..."
                read -r _unused </dev/tty
                ;;
            0)
                echo -e "\n${RED}[-] Deployment terminated by user. Goodbye!${NC}"
                exit 0 ;;
            *)
                echo -e "\n${RED}[!] Critical: Invalid input ('$net_choice'). Please type 1, 2, 3, H or 0!${NC}\n"
                sleep 1 ;;
        esac
    done
}