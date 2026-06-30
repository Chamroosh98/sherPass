#!/bin/sh

# shellcheck shell=ash
# Automation Update and CronJob Scheduler Module

setup_auto_update() {
    local log_file=$1
    print_status "work" "🔁 Binding cron synchronization configurations"
    
    # آدرس اجرای خودکار مستقیم از روت مخزن گیت‌هاب شما
    local github_cmd="wget -qO- https://raw.githubusercontent.com/Chamroosh98/DayPass/main/install.sh | sh -s -- --update-rules"
    local cron_cmd="0 4 * * * $github_cmd"
    
    (crontab -l 2>/dev/null | grep -v "update-rules"; echo "$cron_cmd") | crontab -
    /etc/init.d/cron restart
    print_status "done!✔️" "🔁 Cronjob bound at 04:00 AM"
}