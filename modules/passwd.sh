#!/bin/sh

enforce_root_password() {
    # چک کردن اینکه آیا پسورد روت خالیه یا خیر (در لینوکس علامت ! یا خالی بودن یعنی پسورد ندارد)
    local root_pass_status
    root_pass_status=$(grep '^root:' /etc/shadow | cut -d: -f2)

    if [ "$root_pass_status" != "!" ] && [ -n "$root_pass_status" ] && [ "$root_pass_status" != "*" ]; then
        # کاربر از قبل پسورد دارد، بدون مزاحمت عبور میکنیم
        return 0
    fi

    echo -e "\n${RED}${BOLD}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${RED}${BOLD}│ SECURITY ALERT: ROOT PASSWORD IS NOT DEFINED! │${NC}"
    echo -e "${RED}${BOLD}└───────────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}You must set a secure root password before proceeding with sherPass.${NC}\n"

    # حلقه اجبار تا زمانی که کاربر پسورد را با موفقیت ست کند
    while true; do
        passwd root
        if [ $? -eq 0 ]; then
            print_status "success" "Root password securely registered!"
            break
        else
            echo -e "\n${RED}[!] Password update failed or mismatched. Try again!${NC}\n"
        fi
    done
}