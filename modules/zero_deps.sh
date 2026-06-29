#!/bin/sh

deploy_system_dependencies() {
    local pkg_mgr=$1
    local ins_cmd=$2
    local log_file=$3

    # ۱. آپدیت کردن مخازن روتر (برای اینکه پکیج‌ها بدون ارور پیدا شوند)
    print_status "work" "Updating system package repositories..."
    if [ "$pkg_mgr" = "apk" ]; then
        apk update >> "$log_file" 2>&1
    else
        opkg update >> "$log_file" 2>&1
    fi

    # ۲. لیست پکیج‌های پایه و حیاتی (مثل curl) که اسکریپت برای زنده ماندن لازم دارد
    local core_deps="curl"
    
    # ۳. لیست ابزارهای کاربردی که خودت می‌خواهی (Manual Useful Tools)
    # اینجا هر ابزار جدیدی بخواهی را خیلی راحت ته لیست اضافه می‌کنی
    local user_tools="openssh-sftp-server dnsmasq-full kmod-nf-conntrack-netlink libatomic1"

    # ۴. پروسه تزریق هوشمند (فقط اگر از قبل نصب نباشند دانلود و نصب می‌شوند)
    print_status "work" "Injecting core dependencies & manual utility tools..."
    
    for pkg in $core_deps $user_tools; do
        # بررسی اینکه پکیج از قبل نصب هست یا نه (برای جلوگیری از اتلاف حجم و زمان)
        if ! apk info -e "$pkg" >/dev/null 2>&1; then
            echo -e "   ${GRAY}📥 Deploying tool: $pkg...${NC}"
            $ins_cmd "$pkg" >> "$log_file" 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "   ${GREEN}✔ $pkg is now fully active!${NC}"
            else
                echo -e "   ${YELLOW}⚠️ Failed to inject $pkg. Check logs for details.${NC}"
            fi
        else
            echo -e "   ${GREEN}✔ [Skipped] $pkg is already present in system storage.${NC}"
        fi
    done
}