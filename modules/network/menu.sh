#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Advanced Network UI Boot-Menu (BulletProof Edition)
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

show_network_menu() {
    # ایجاد فاصله استاندارد از بالای ترمینال برای زیبایی و خفه نشدن منو
    echo ""
    echo -e "${CYAN}📡 DAYPASS NETWORK GATEWAY${NC}"
    echo -e "${GRAY}Configure deployment routing before core synchronization${NC}"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"

    while true; do
        echo -e "  ${PURPLE}[1]${NC} Proxy Tunnel ${GRAY}(SOCKS5 127.0.0.1:8090)${NC}"
        echo -e "      ${GRAY}↳ Linux: ssh -R 8090:localhost:10808 | Win: netsh/v2ray${NC}"
        echo -e "  ${PURPLE}[2]${NC} Direct Connection ${GRAY}(No Proxy / Native System)${NC}"
        echo -e "      ${GRAY}↳ Standard network routing without bypass tunnel.${NC}"
        echo -e "  ${PURPLE}[3]${NC} Smart Resilient Fallback ${GRAY}(Recommended)${NC}"
        echo -e "      ${GRAY}↳ Auto-detects active proxies, falls back to native.${NC}"
        echo -e "  ${RED}[0]${NC} Abort & Exit"
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
        printf "  Select network routing [1-3, or 0 to exit]: "
        
        local net_choice; read -r net_choice </dev/tty
        
        # پاک کردن فاصله‌های احتمالی یا کاراکترهای مخفی ورودی
        net_choice=$(echo "$net_choice" | tr -d ' ')

        case "$net_choice" in
            1)
                NET_MODE=2 # حالت پروکسی خالص
                export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Proxy Tunnel]!${NC}"
                break
                ;;
            2)
                NET_MODE=1 # حالت دایرکت خالص
                export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Direct Connection]!${NC}"
                break
                ;;
            3)
                NET_MODE=3 # حالت هوشمند
                export NET_MODE
                echo -e "\n  ${GREEN}✔ Network configuration locked to [Smart Fallback]!${NC}"
                break
                ;;
            0)
                echo -e "\n${RED}[-] Deployment terminated by user. Goodbye!${NC}"
                exit 0
                ;;
            *)
                # ارور مقتدرانه سرخ‌رنگ در صورت وارد کردن هر چیزی به جز گزینه‌های مجاز
                echo -e "\n${RED}[!] Critical: Invalid input ('$net_choice'). Please type 1, 2, 3 or 0 only!${NC}\n"
                sleep 1.5
                ;;
        esac
    done
    
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    echo ""
    sleep 1
}