#!/bin/sh

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;84m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;227m'
GRAY='\033[38;5;244m'
NC='\033[0m'
BOLD='\033[1m'

# Pure Shell Live Spinner Animation
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-'
    echo -n "   "
    while [ -d "/proc/$pid" ]; do
        local temp=${spinstr#?}
        printf "${PURPLE}\b%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\b\b" # Clean spinner characters up after finish
}

# ASCII Box Border Header Menu
draw_header() {
    clear
    echo -e "${PURPLE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}    ${BOLD}${CYAN}OpenWrt Passwall Pro Auto-Installer${NC}        ${PURPLE}│${NC}"
    echo -e "${PURPLE}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  ${BOLD}Arch:${NC} $(echo -e "${YELLOW}$1${NC}")" | awk '{printf "%-59s %s\n", $0, " \033[38;5;141m│\033[0m"}'
    echo -e "${PURPLE}│${NC}  ${BOLD}Manager:${NC} $(echo -e "${YELLOW}$2${NC}")" | awk '{printf "%-59s %s\n", $0, " \033[38;5;141m│\033[0m"}'
    echo -e "${PURPLE}└───────────────────────────────────────────────┘${NC}"
}