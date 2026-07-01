#!/bin/sh
# shellcheck shell=ash
# ==============================================================================
#  DayPass Framework - Central Orchestrator & Smart Package Delivery Engine
#  Architect: Chamroosh (ch4mr0sh)
# ==============================================================================

# تزریق توابع پایه برای چاپ استاتوس در صورتی که در سورس‌های موازی لود نشده باشند
print_status() {
    local type=$1 local msg=$2
    case "$type" in
        "work") echo -e "   ${YELLOW}➔${NC} $msg" ;;
        "success") echo -e "   ${GREEN}✔${NC} $msg" ;;
        "failed") echo -e "   ${RED}❌${NC} $msg" ;;
        "sub") echo -e "     ${GRAY}⚙️ $msg${NC}" ;;
    esac
}

initialize_daypass_feeds() {
    local log_file=$1
    local key_destination="/etc/apk/keys/apk.pub"
    local feed_file="/etc/apk/repositories.d/customfeeds.list"
    
    local c_opts="-sS -L --insecure --connect-timeout 10"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"
    local apk_proxy=""
    [ "$NET_MODE" -ne 1 ] && apk_proxy="ALL_PROXY=socks5h://127.0.0.1:8090"

    mkdir -p /etc/apk/keys /etc/apk/repositories.d

    if [ ! -f "$key_destination" ]; then
        echo -e "🔑 ${YELLOW}Injecting Passwall Trusted Public Key ...${NC}"
        eval curl $c_opts -o "$key_destination" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/apk.pub" >> "$log_file" 2>&1
    fi

    cat /dev/null > "$feed_file"

    local core_feeds="passwall_packages passwall_luci passwall2"
    for feed in $core_feeds; do
        local repo_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${feed}"
        echo -e "📡 ${YELLOW}Registering Feed [${feed}] into Custom Feeds ...${NC}"
        echo "$repo_url" >> "$feed_file"
    done

    echo -e "🔄 ${CYAN}Updating APK system indexes under Proxy tunnel ...${NC}"
    eval "$apk_proxy apk update --allow-untrusted" >> "$log_file" 2>&1
}

fetch_feed_packages_json() {
    local repo_folder=$1
    local output_var=$2
    
    local json_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${ARCH}/${repo_folder}/index.json"
    local c_opts="-sS -L --insecure --connect-timeout 8"
    [ "$NET_MODE" -ne 1 ] && c_opts="$c_opts --socks5-hostname 127.0.0.1:8090"

    local raw_json
    raw_json=$(eval curl $c_opts "$json_url" 2>/dev/null)
    
    if [ -z "$raw_json" ]; then
        return 1
    fi

    local parsed_list
    parsed_list=$(echo "$raw_json" | awk '
        /"packages":/ {flag=1; next}
        /}/ && flag {flag=0}
        flag {
            gsub(/[",:]/, "", $1);
            print $1
        }
    ')

    eval "$output_var=\"$parsed_list\""
    return 0
}

download_package_smart() {
    local sub_folder=$1 local keyword=$2 local arch=$3 local ins_cmd=$4 local log_file=$5
    local space_path="/tmp/daypass_space/modules/network"

    if apk info -e "$keyword" >/dev/null 2>&1 || { [ "$keyword" = "xray-core" ] && apk info -e "xray-plugin" >/dev/null 2>&1; }; then
        echo -e "   ${GREEN}✔ [Skipped] $keyword is already deployed flawlessly!🦧 No re-download needed! ✨${NC}"
        return 0
    fi

    if [ -z "$NET_MODE" ]; then
        . "$space_path/menu.sh"
        show_network_menu
    fi

    local remote_folder="$sub_folder"
    [ "$sub_folder" = "passwall_luci" ] && remote_folder="passwall2"
    local search_keyword="$keyword"
    [ "$keyword" = "xray-core" ] && search_keyword="xray-plugin"

    if [ "$NET_MODE" -eq 1 ]; then
        . "$space_path/direct.sh" 2>/dev/null || true
        local engine_mode="direct"
    else
        . "$space_path/proxy.sh" 2>/dev/null || true
        local engine_mode=$([ "$NET_MODE" -eq 2 ] && echo "proxy" || echo "smart-proxy")
    fi

    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html" local exact_filename=""

    print_status "work" "Scanning SourceForge registry for latest $keyword [Engine: $engine_mode]..."
    
    local html_content
    if [ "$engine_mode" = "direct" ]; then
        html_content=$(fetch_direct "$folder_url" "" "" "$log_file")
    else
        html_content=$(fetch_proxy "$folder_url" "" "" "$log_file")
    fi

    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        echo "$html_content" > "$tmp_html"
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Registry scan blocked! Activating static fallback...${NC}"
        case "$keyword" in
            "xray-core") exact_filename="xray-plugin-1.8.24-r1.apk" ;;
            "tcping")    exact_filename="tcping-0.3-r1.apk" ;;
            "geoview")   exact_filename="geoview-2.0.2-r1.apk" ;;
            "sing-box")  exact_filename="sing-box-1.9.3-r1.apk" ;;
            "luci-app-passwall2")     exact_filename="luci-app-passwall2-4.77-r3.apk" ;;
            "luci-i18n-passwall2-fa") exact_filename="luci-i18n-passwall2-fa-4.77-r3.apk" ;;
        esac
    fi

    local full_download_url="https://downloads.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/${arch}/${remote_folder}/${exact_filename}"
    local tmp_target="/tmp/${exact_filename}"

    print_status "work" "Fetching $keyword directly from SourceForge..."
    echo -e "   ${GRAY}📥 Remote Link : $full_download_url${NC}"
    echo -e "   ${GRAY}💾 Local Destination : $tmp_target (RAM Storage)${NC}"

    local dl_status=1
    if [ "$engine_mode" = "direct" ]; then
        fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
    else
        fetch_proxy "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
        if [ $dl_status -ne 0 ] && [ "$engine_mode" = "smart-proxy" ]; then
            echo -e "   ${YELLOW}⚠️ Proxy dropped connection. Retrying via Direct Connection! ${NC}"
            . "$space_path/direct.sh" 2>/dev/null || true
            fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"; dl_status=$?
        fi
    fi

    if [ $dl_status -eq 0 ]; then
        print_status "sub" "Injecting payload into local system core..."
        echo -e "   ${GRAY}⚙️ Engine Command: apk add --allow-untrusted $tmp_target${NC}"
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly! 🔥"
            rm -f "$tmp_target" && return 0
        fi
    fi
    print_status "failed" "❌ Critical : Network execution failed for $keyword" && rm -f "$tmp_target" && return 1
}