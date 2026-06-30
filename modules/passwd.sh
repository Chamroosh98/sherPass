#!/bin/sh

# shellcheck shell=ash
# Root Password Enforcement Module (BusyBox Compliant)

enforce_root_password() {
    local root_pass_status
    root_pass_status=$(grep '^root:' /etc/shadow | cut -d: -f2)

    if [ "$root_pass_status" != "!" ] && [ -n "$root_pass_status" ] && [ "$root_pass_status" != "*" ]; then
        return 0
    fi

    echo -e "\n\033[1;31m⚠️ SECURITY ALERT : ROOT PASSWORD IS NOT DEFINED!\033[0m"
    local new_pass=""
    
    while true; do
        printf "🫣 Enter NEW password for root : "
        read -r new_pass </dev/tty
        new_pass=$(echo "$new_pass" | tr -d ' ')
        
        if [ -z "$new_pass" ] || [ ${#new_pass} -lt 4 ]; then
            echo -e "❌ Error : Password must be at least 4 characters long!\n"
            continue
        fi
        
        (echo "$new_pass"; sleep 1; echo "$new_pass") | passwd root >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "\033[1;32m✅ Root password securely registered! \033[0m\n"
            break
        fi
        echo -e "❌ Error : Failed to set password. Try again! \n"
    done
}