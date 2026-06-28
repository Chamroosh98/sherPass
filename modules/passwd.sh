#!/bin/sh
# Root Password Enforcement Module

enforce_root_password() {
    local root_pass_status
    root_pass_status=$(grep '^root:' /etc/shadow | cut -d: -f2)

    if [ "$root_pass_status" != "!" ] && [ -n "$root_pass_status" ] && [ "$root_pass_status" != "*" ]; then
        return 0
    fi

    echo "⚠️ SECURITY ALERT: ROOT PASSWORD IS NOT DEFINED!"
    local new_pass=""
    
    while true; do
        printf "Enter NEW password for root: "
        read -r new_pass </dev/tty
        new_pass=$(echo "$new_pass" | tr -d ' ')
        
        if [ -z "$new_pass" ] || [ ${#new_pass} -lt 4 ]; then
            echo "[!] Error: Password too short!"
            continue
        fi
        
        echo "root:$new_pass" | chpasswd
        if [ $? -eq 0 ]; then
            echo "✔ Root password securely registered!"
            break
        fi
    done
}