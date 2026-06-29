#!/bin/sh
# shellcheck shell=ash

run_online_loader() {
    local github_url=$1
    shift
    
    if [ ! -f "./modules/config.sh" ] && [ "$1" != "--fallback-remote" ]; then
        mkdir -p /tmp/sherpass_space/modules
        
        # دانلود ماژول‌ها از گیت‌هاب
        wget -qO /tmp/sherpass_space/modules/config.sh "$github_url/modules/config.sh"
        wget -qO /tmp/sherpass_space/modules/cleaner.sh "$github_url/modules/cleaner.sh"
        wget -qO /tmp/sherpass_space/modules/downloader.sh "$github_url/modules/downloader.sh"
        wget -qO /tmp/sherpass_space/modules/iran_rules.sh "$github_url/modules/iran_rules.sh"
        wget -qO /tmp/sherpass_space/modules/cronjob.sh "$github_url/modules/cronjob.sh"
        wget -qO /tmp/sherpass_space/modules/validator.sh "$github_url/modules/validator.sh"
        wget -qO /tmp/sherpass_space/modules/banner.sh "$github_url/modules/banner.sh"
        wget -qO /tmp/sherpass_space/modules/network.sh "$github_url/modules/network.sh"
        wget -qO /tmp/sherpass_space/modules/passwd.sh "$github_url/modules/passwd.sh"
        wget -qO /tmp/sherpass_space/modules/loader.sh "$github_url/modules/loader.sh"
        wget -qO /tmp/sherpass_space/install.sh "$github_url/install.sh"
        
        cd /tmp/sherpass_space || exit 1
        exec sh install.sh --fallback-remote "$@"
    fi
}