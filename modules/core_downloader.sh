#!/bin/sh
# shellcheck shell=ash
# Core Downloader Orchestrator with Intelligent Auto-Fallback

download_package_smart() {
    local sub_folder=$1 local keyword=$2 local arch=$3 local ins_cmd=$4 local log_file=$5

    local remote_folder="$sub_folder"
    [ "$sub_folder" = "passwall_luci" ] && remote_folder="passwall2"

    local search_keyword="$keyword"
    [ "$keyword" = "xray-core" ] && search_keyword="xray-plugin"

    [ -z "$NET_MODE" ] && NET_MODE=2

    # امپورت داینامیک ماژول فیزیکی تفکیک‌شده
    if [ "$NET_MODE" -eq 1 ]; then
        . /tmp/sherpass_space/modules/network/direct.sh
        local engine_mode="direct"
    else
        . /tmp/sherpass_space/modules/network/proxy.sh
        local engine_mode="proxy"
    fi

    local folder_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-25.12/${arch}/${remote_folder}/"
    local tmp_html="/tmp/sf_folder.html"
    local exact_filename=""

    print_status "work" "Scanning SourceForge registry for latest $keyword [Engine: $engine_mode]..."

    if [ "$engine_mode" = "proxy" ]; then
        local html_content; html_content=$(fetch_proxy "$folder_url" "" "" "$log_file")
    else
        local html_content; html_content=$(fetch_direct "$folder_url" "" "" "$log_file")
    fi

    if [ $? -eq 0 ] && [ -n "$html_content" ]; then
        echo "$html_content" > "$tmp_html"
        exact_filename=$(grep -oE 'title="[^"]+\.apk"' "$tmp_html" | sed 's/title="//;s/"//' | grep -E "^${search_keyword}" | head -n 1)
        rm -f "$tmp_html"
    fi

    if [ -z "$exact_filename" ]; then
        echo -e "   ${YELLOW}⚠️ Registry scan blocked or Packet Loss detected! Activating static fallback...${NC}"
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
    echo -e "   ${GRAY}📥 Remote Link: $full_download_url${NC}"
    echo -e "   ${GRAY}💾 Local Destination: $tmp_target (RAM Storage)${NC}"

    local dl_status=1
    if [ "$engine_mode" = "proxy" ]; then
        fetch_proxy "" "$full_download_url" "$tmp_target" "$log_file"
        dl_status=$?
        
        if [ $dl_status -ne 0 ]; then
            echo -e "   ${YELLOW}⚠️ Proxy core dropped connection. Retrying immediately via Direct Connection...${NC}"
            . /tmp/sherpass_space/modules/network/direct.sh
            fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"
            dl_status=$?
        fi
    else
        fetch_direct "" "$full_download_url" "$tmp_target" "$log_file"
        dl_status=$?
    fi

    if [ $dl_status -eq 0 ]; then
        print_status "sub" "Injecting payload into local system core..."
        echo -e "   ${GRAY}⚙️ Engine Command: apk add --allow-untrusted $tmp_target${NC}"
        
        if apk add --allow-untrusted "$tmp_target" >> "$log_file" 2>&1; then
            print_status "success" "${BOLD}$keyword${NC} deployed flawlessly! 🔥"
            rm -f "$tmp_target"
            return 0
        else
            print_status "failed" "APK engine rejected $exact_filename Layout"
            rm -f "$tmp_target"
            return 1
        fi
    else
        print_status "failed" "Critical: Network execution failed to pull $exact_filename under all fallback modes!"
        return 1
    fi
}