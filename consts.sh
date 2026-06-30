#!/bin/sh
# shellcheck shell=ash

# 📌 مسیرهای مرجع و فایل لاگ
export LOG_FILE="/tmp/DayPass.log"
export GITHUB_RAW_URL="https://raw.githubusercontent.com/Chamroosh98/DayPass/main"
export BASE_MODULES="/tmp/daypass_space/modules"

# 🎨 کدهای رنگی استاندارد برای خروجی مینیمال ترمینال
export CYAN="\033[1;38;5;51m"
export PURPLE="\033[38;5;141m"
export GREEN="\033[32m"
export YELLOW="\033[33m"
export GRAY="\033[90m"
export RED="\033[31m"
export NC="\033[0m"