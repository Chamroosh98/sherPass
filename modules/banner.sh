#!/bin/sh
# shellcheck shell=ash
# Advanced Post-Install SSH Banner Customizer Module

generate_custom_banner() {
    local banner_file="/etc/banner"
    
    local ram_total=$(free -m | awk '/Mem:/ {print $2}')
    local ram_used=$(free -m | awk '/Mem:/ {print $3}')
    local ram_free=$(free -m | awk '/Mem:/ {print $4}')
    
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_avail=$(df -h / | awk 'NR==2 {print $4}')
    local disk_percent=$(df -h / | awk 'NR==2 {print $5}')

    print_status "work" "Checking router's WAN public network identity"
    local public_ip=$(curl -s --connect-timeout 4 https://api.ipify.org 2>/dev/null)
    [ -z "$public_ip" ] && public_ip="No Internet / Blocked"

    print_status "work" "Injecting brand-new sherPass telemetry banner into /etc/banner"

    cat << EOF > "$banner_file"
       __                      ____                 
  ____/ /_  ___  _________ ___/ / /_  ____ ______ ___
 / ___/ __ \/ _ \/ ___/ __ \__  / __ \/ __ \/ ___// __ \\
(__  ) / / /  __/ /  / /_/ / / / /_/ / /_/ (__  )/ /_/ /
/____/_/ /_/\___/_/   \__,_/ /_/_.___/\__,_/____/ .___/ 
      ⭐ Deployed by Chamroosh                    /_/    
---------------------------------------------------------
  SYSTEM TELEMETRY & RESOURCES:
---------------------------------------------------------
  • Public WAN IP : $public_ip
  • Memory (RAM)  : ${ram_used}MB Used / ${ram_free}MB Free (${ram_total}MB Total)
  • Storage (ROM) : $disk_used Used / $disk_avail Available ($disk_percent)
---------------------------------------------------------
  ⚠️ SOURCEFORGE & BYPASS SANCTIONS NOTICE (IRAN):
---------------------------------------------------------
  If SourceForge downloads or updates hang/fail on your IP,
  it means your connection is throttled or sanctioned.
  
  👉 Linux Users / Pro Developers can bypass this via SSH 
     Remote Port Forwarding (SOCKS5 Proxy Tunneling):
     
     ssh -R 8090:localhost:10808 root@\$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1")
     
---------------------------------------------------------
EOF

    print_status "success" "Custom SSH system banner deployed flawlessly!"
}