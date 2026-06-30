#!/bin/sh
# shellcheck shell=ash

deploy_system_dependencies() {
    local pkg_mgr=$1
    local ins_cmd=$2
    local log_file=$3

    echo -e "${YELLOW}➔ Updating system package repositories (${pkg_mgr}) ♻️ ... ${NC}"
    if [ "$pkg_mgr" = "apk" ]; then
        apk update >> "$log_file" 2>&1
    else
        opkg update >> "$log_file" 2>&1
    fi

    local core_deps="curl"
    local user_tools="openssh-sftp-server dnsmasq-full kmod-nf-conntrack-netlink libatomic1"

    echo -e "${YELLOW}➔ Injecting core dependencies & manual utility tools! 💉 ${NC}"
    
    for pkg in $core_deps $user_tools; do
        local is_installed=1
        if [ "$pkg_mgr" = "apk" ]; then
            apk info -e "$pkg" >/dev/null 2>&1 && is_installed=0
        else
            opkg list-installed | grep -q "^$pkg " && is_installed=0
        fi

        if [ "$is_installed" -ne 0 ]; then
            echo -e "   ${GRAY}📥 Deploying tool : $pkg ...${NC}"
            $ins_cmd "$pkg" >> "$log_file" 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "   ${GREEN}✔ $pkg is now fully active!${NC}"
            else
                echo -e "   ${YELLOW}⚠️ Failed to inject $pkg. Check logs for details! 🥱 ${NC}"
            fi
        else
            echo -e "   ${GREEN}✔ [Skipped] $pkg is already present in system storage! ${NC}"
        fi
    done
}