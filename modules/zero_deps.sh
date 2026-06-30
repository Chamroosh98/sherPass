#!/bin/sh

deploy_system_dependencies() {
    local pkg_mgr=$1
    local ins_cmd=$2
    local log_file=$3

    print_status "work" "Updating system package repositories..."
    if [ "$pkg_mgr" = "apk" ]; then
        apk update >> "$log_file" 2>&1
    else
        opkg update >> "$log_file" 2>&1
    fi

    local core_deps="curl"
 
    local user_tools="openssh-sftp-server dnsmasq-full kmod-nf-conntrack-netlink libatomic1"

    print_status "work" "Injecting core dependencies & manual utility tools..."
    
    for pkg in $core_deps $user_tools; do
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