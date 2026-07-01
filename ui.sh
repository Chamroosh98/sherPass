#!/bin/sh
# shellcheck shell=ash

export LOG_FILE="/tmp/DayPass.log"
export GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"
export BASE_MODULES="/tmp/daypass_space/modules"
export NET_MODE=3

export CYAN="\033[1;38;5;51m"; export PURPLE="\033[38;5;141m"; export GREEN="\033[32m"
export YELLOW="\033[33m"; export GRAY="\033[90m"; export RED="\033[31m"; export NC="\033[0m"

# 🛠️ منوی انتخاب نسخه پاسوال و استراتژی نصب
render_installation_wizard() {
    local p_version_var=$1 local i_mode_var=$2
    
    # 1️⃣ انتخاب ورژن Passwall
    echo -e "\n${YELLOW}🛠️ Passwall Generation Choice :${NC}"
    echo -e "  ${PURPLE}[1]${NC} Passwall 1 ${GRAY}(Classic Stable)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Passwall 2 ${GRAY}(Modern Advanced)${NC}"
    while true; do
        printf "  Select Framework Version [1-2]: "
        read -r v_choice </dev/tty
        case "$v_choice" in
            1) eval "$p_version_var='passwall_luci'"; break ;;
            2) eval "$p_version_var='passwall2'"; break ;;
            *) echo -e "${RED}[!] Invalid Choice!${NC}" ;;
        esac
    done

    # 2️⃣ انتخاب نوع دپلویمنت
    echo -e "\n${YELLOW}🚀 Installation Strategy :${NC}"
    echo -e "  ${PURPLE}[1]${NC} Recommended Mode ${GREEN}(Essentials + Persian Pack)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Expert Custom Menu ${YELLOW}(Live Matrix Menu)${NC}"
    while true; do
        printf "  Select Strategy [1-2]: "
        read -r m_choice </dev/tty
        case "$m_choice" in
            1|2) eval "$i_mode_var='$m_choice'"; break ;;
            *) echo -e "${RED}[!] Invalid Choice!${NC}" ;;
        esac
    done
}

# 🧙‍♂️ ماتریس انتخاب پیشرفته پکیج‌ها (Expert Mode Menu)
render_expert_matrix() {
    local full_list="$1" local target_pkgs_var=$2
    local selected_pkgs=""

    while true; do
        clear
        [ -n "$(command -v generate_custom_banner)" ] && generate_custom_banner
        echo -e "${YELLOW}🎯 Expert Deployment Matrix (Select/Toggle Packages):${NC}"
        echo -e "${GRAY}Enter number to Select/Deselect. Type ${GREEN}'i'${GRAY} to start Installation.${NC}\n"
        
        local idx=1
        for item in $full_list; do
            local status_flag="[ ]"
            if echo "$selected_pkgs" | grep -q "\<$item\>"; then
                status_flag="${GREEN}[✓]${NC}"
            fi
            echo -e "  ${PURPLE}[$idx]${NC} $status_flag $item"
            idx=$((idx + 1))
        done
        
        echo -e "${PURPLE}─────────────────────────────────────────────────${NC}"
        printf "⌨️ Enter Option Number or 'i' to install: "
        read -r exp_input </dev/tty
        
        if [ "$exp_input" = "i" ] || [ "$exp_input" = "I" ]; then
            [ -z "$selected_pkgs" ] && { echo -e "${RED}Please select at least one package!${NC}"; sleep 1; continue; }
            break
        fi
        
        local selected_item
        selected_item=$(echo "$full_list" | awk -v target="$exp_input" '{print $target}')
        
        if [ -n "$selected_item" ]; then
            if echo "$selected_pkgs" | grep -q "\<$selected_item\>"; then
                selected_pkgs=$(echo "$selected_pkgs" | sed "s/\<$selected_item\>//g")
            else
                selected_pkgs="${selected_pkgs} ${selected_item}"
            fi
        else
            echo -e "${RED}Invalid Selection!${NC}"; sleep 0.5
        fi
    done

    eval "$target_pkgs_var='$selected_pkgs'"
}