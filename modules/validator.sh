#!/bin/sh

# ==============================================================================
#  DayPass Framework - Ultimate OpenWrt Deployment Engine
#  Architect: Chamroosh98
#  Dedicated to the immortal souls of 18-19 Dey 1404 🕊️
# ==============================================================================

# shellcheck shell=ash
# Input and Keyboard Layout Strict Validator Module

validate_ascii_input() {
    local user_input=$1
    
    # حذف فاصله‌های خالی احتمالی
    user_input=$(echo "$user_input" | tr -d ' ')
    
    # ۱. اگر ورودی خالی بود (کاربر مستقیم اینتر زد)
    if [ -z "$user_input" ]; then
        echo "empty"
        return 0
    fi

    # ۲. چک کردن زبان کیبورد (بررسی وجود کاراکترهای غیر انگلیسی یا مالتی‌بایت مثل فارسی)
    if echo "$user_input" | grep -q '[^a-zA-Z]'; then
        echo "non-ascii"
        return 0
    fi

    # ۳. اگر ورودی انگلیسی و معتبر بود، خود مقدار را پاس بده
    echo "$user_input"
}