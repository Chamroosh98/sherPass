#!/bin/sh
clear

echo -e "\033[38;5;141m┌───────────────────────────────────────────────┐\033[0m"
echo -e "\033[38;5;141m│\033[0m   \033[1;38;5;51m⚡ sherPass Framework Engine Loading...     \033[0m\033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m├───────────────────────────────────────────────┤\033[0m"
echo -e "\033[38;5;141m│\033[0m \033[38;5;244mPlease wait, pulling core modules from repo... \033[0m\033[38;5;141m│\033[0m"
echo -e "\033[38;5;141m└───────────────────────────────────────────────┘\033[0m"

LOG_FILE="/tmp/passwall_install.log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/sherPass/main"

if command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"; INSTALL_CMD="apk add --allow-untrusted"; REMOVE_CMD="apk del"
else
    PKG_MGR="opkg"; INSTALL_CMD="opkg install"; REMOVE_CMD="opkg remove"
fi

if [ "$PKG_MGR" = "apk" ]; then
    ARCH=$(apk info -o kernel 2>/dev/null | grep -E -o 'arm_.*|mips_.*|x86_64|aarch64' | head -n 1)
else
    ARCH=$(opkg info kernel | grep Architecture | awk '{print $2}')
fi
[ -z "$ARCH" ] && ARCH="arm_cortex-a7_neon-vfpv4"

if [ ! -f "./modules/config.sh" ] && [ "$1" != "--fallback-remote" ]; then
    mkdir -p /tmp/sherpass_space/modules
    
    wget -qO /tmp/sherpass_space/modules/config.sh "$GITHUB_RAW_URL/modules/config.sh"
    wget -qO /tmp/sherpass_space/modules/cleaner.sh "$GITHUB_RAW_URL/modules/cleaner.sh"
    wget -qO /tmp/sherpass_space/modules/downloader.sh "$GITHUB_RAW_URL/modules/downloader.sh"
    wget -qO /tmp/sherpass_space/modules/iran_rules.sh "$GITHUB_RAW_URL/modules/iran_rules.sh"
    wget -qO /tmp/sherpass_space/modules/cronjob.sh "$GITHUB_RAW_URL/modules/cronjob.sh"
    wget -qO /tmp/sherpass_space/modules/validator.sh "$GITHUB_RAW_URL/modules/validator.sh"
    wget -qO /tmp/sherpass_space/modules/banner.sh "$GITHUB_RAW_URL/modules/banner.sh"
    wget -qO /tmp/sherpass_space/install.sh "$GITHUB_RAW_URL/install.sh"
    
    cd /tmp/sherpass_space || exit 1
    exec sh install.sh --fallback-remote "$@"
fi

. ./modules/config.sh
. ./modules/cleaner.sh
. ./modules/downloader.sh
. ./modules/iran_rules.sh
. ./modules/cronjob.sh
. ./modules/validator.sh
. ./modules/banner.sh

[ "$1" = "--fallback-remote" ] && shift

run_optimized_installation() {
    local raw_input=""
    local check_result=""
    local install_singbox="n"
    
    echo -e "\n${YELLOW}⚡ Optimization Prompt:${NC}"
    
    while true; do
        printf "Do you want to install ${BOLD}sing-box${NC} core? (Heavy on low-end devices) [y/n]: "
        read raw_input </dev/tty
        
        check_result=$(validate_ascii_input "$raw_input")
        
        if [ "$check_result" = "non-ascii" ]; then
            echo -e "${RED}[!] Error: Invalid characters detected. Please switch your keyboard to English!${NC}\n"
            continue
        fi
        
        if [ "$check_result" = "empty" ]; then
            install_singbox="n"
            break
        fi

        case "$check_result" in
            [yY]) install_singbox="y"; break ;;
            [nN]) install_singbox="n"; break ;;
            *) echo -e "${RED}[!] Error: Invalid choice. Please enter only 'y' for Yes or 'n' for No.${NC}\n" ;;
        esac
    done
    
    run_environment_setup "$INSTALL_CMD" "$REMOVE_CMD" "$LOG_FILE"
    
    echo -e "\n${BOLD}${CYAN}[Phase 1/2: Deploying Micro Proxy Cores]${NC}"
    download_package_smart "packages" "xray-core" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "packages" "tcping" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "packages" "geoview" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    if [ "$install_singbox" = "y" ]; then
        download_package_smart "packages" "sing-box" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    fi

    echo -e "${BOLD}${CYAN}[Phase 2/2: Injecting LuCI User Interfaces]${NC}"
    download_package_smart "luci" "luci-app-passwall2" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    download_package_smart "luci" "luci-i18n-passwall2-fa" "$ARCH" "$INSTALL_CMD" "$LOG_FILE" || return 1
    
    generate_custom_banner
    
    echo -e "${GREEN}${BOLD}✔ Deployment flawless! Passwall 2 Pro is fully running. 🔥${NC}"
}

if [ "$1" = "--update-rules" ]; then
    run_iran_rules_module
    exit 0
fi

while true; do
    draw_header "$ARCH" "$PKG_MGR"
    echo -e "  ${PURPLE}[1]${NC} Optimized Installation ${GRAY}(Xray + Core UI + Clean-up)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Apply/Update Iran Smart Routing ${GRAY}(DAT files)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Enable Daily Auto-Update ${GRAY}(CronJob)${NC}"
    echo -e "  ${PURPLE}[4]${NC} Exit"
    echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
    printf "  Select an option [1-4]: "
    read choice </dev/tty
    
    case $choice in
        1) run_optimized_installation ;;
        2) run_iran_rules_module ;;
        3) setup_auto_update "$LOG_FILE" ;;
        4) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
    esac
    echo -e "\nPress Enter to return to main menu..."
    read _unused </dev/tty
done