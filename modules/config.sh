#!/bin/sh

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;84m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;227m'
GRAY='\033[38;5;244m'
NC='\033[0m'
BOLD='\033[1m'

print_status() {
    local type=$1; local msg=$2
    case $type in
        "work")    echo -e "${CYAN}➔${NC} $msg ... " ;;
        "sub")     echo -e "   ${PURPLE}↳${NC} $msg ... " ;;
        "success") echo -e "   ${GREEN}✔ $msg${NC}\n" ;;
        "done")    echo -e "${GREEN}✔ $msg${NC}" ;;
        "failed")  echo -e "${RED}✘ $msg${NC}\n" ;;
    esac
}

draw_header() {
    clear
    echo -e "${PURPLE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}    ${BOLD}${CYAN}OpenWrt Passwall Pro Auto-Installer${NC}        ${PURPLE}│${NC}"
    echo -e "${PURPLE}├───────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  ${BOLD}Arch:${NC} $(echo -e "${YELLOW}$1${NC}")" | awk '{printf "%-59s %s\n", $0, " \033[38;5;141m│\033[0m"}'
    echo -e "${PURPLE}│${NC}  ${BOLD}Manager:${NC} $(echo -e "${YELLOW}$2${NC}")" | awk '{printf "%-59s %s\n", $0, " \033[38;5;141m│\033[0m"}'
    echo -e "${PURPLE}└───────────────────────────────────────────────┘${NC}"
}