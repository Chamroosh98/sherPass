#!/bin/sh
# shellcheck shell=ash
# Root Password Enforcement Module (Tunnel-Safe & Non-interactive)

enforce_root_password() {
    # چک کردن وضعیت پسورد روت
    local root_pass_status
    root_pass_status=$(grep '^root:' /etc/shadow | cut -d: -f2)

    if [ "$root_pass_status" != "!" ] && [ -n "$root_pass_status" ] && [ "$root_pass_status" != "*" ]; then
        return 0
    fi

    echo -e "\n${RED}${BOLD}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${RED}${BOLD}│ SECURITY ALERT: ROOT PASSWORD IS NOT DEFINED! │${NC}"
    echo -e "${RED}${BOLD}└───────────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}You must set a secure root password before proceeding with sherPass.${NC}"
    echo -e "${GRAY}(Tunnel-Safe Mode Active)${NC}\n"

    local new_pass=""
    
    while true; do
        # استفاده از read معمولی از طریق tty بدون درگیر کردن پروسه تعاملی سیستم
        printf "Enter NEW password for root: "
        read -r new_pass </dev/tty
        
        # حذف فضاها
        new_pass=$(echo "$new_pass" | tr -d ' ')
        
        if [ -z "$new_pass" ] || [ ${#new_pass} -lt 4 ]; then
            echo -e "${RED}[!] Error: Password cannot be empty and must be at least 4 characters!${NC}\n"
            continue
        fi
        
        printf "Confirm root password: "
        read -r confirm_pass </dev/tty
        confirm_pass=$(echo "$confirm_pass" | tr -d ' ')
        
        if [ "$new_pass" != "$confirm_pass" ]; then
            echo -e "${RED}[!] Error: Passwords do not match. Try again!${NC}\n"
            continue
        fi
        
        # تزریق نیتیو و خطی پسورد به سیستم بدون قفل کردن SSH Reverse Tunnel
        echo "root:$new_pass" | chpasswd
        
        if [ $? -eq 0 ]; then
            print_status "success" "Root password securely registered via chpasswd!"
            break
        else
            echo -e "${RED}[!] Underlying OS rejected the password. Try another combination!${NC}\n"
        fi
    done
}