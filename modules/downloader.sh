#!/bin/sh
# shellcheck shell=ash
# SourceForge index parser and dynamic package downloader

download_package_smart() {
    local sub_folder=$1
    local keyword=$2
    local arch=$3
    local ins_cmd=$4
    local log_file=$5
    local index_file="/tmp/sf_${sub_folder}_index.json"
    
    print_status "work" "Resolving SourceForge metadata for ${BOLD}$keyword${NC}"
    wget -qO "$index_file" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch/$sub_folder/index.json"
    
    if [ ! -s "$index_file" ]; then
        print_status "failed" "Failed to fetch database index!"
        return 1
    fi

    # پارس دقیق مقدار کلید بر اساس ساختار ارسالی شما
    local pkg_version=$(grep -o "\"$keyword\": \"[^\"]*" "$index_file" | cut -d'"' -f4)
    if [ -z "$pkg_version" ]; then
        print_status "failed" "Version mapping for '$keyword' not found!"
        rm -f "$index_file"
        return 1
    fi
    print_status "done" "Version Resolution: v$pkg_version"
    
    local full_name="${keyword}_${pkg_version}_${arch}.apk"
    print_status "sub" "Downloading ${BOLD}$full_name${NC}"
    
    if wget -qO "/tmp/$full_name" "https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch/$sub_folder/$full_name"; then
        print_status "sub" "Injecting package via APK into core OS"
        $ins_cmd "/tmp/$full_name" >> "$log_file" 2>&1
        local status=$?
        rm -f "/tmp/$full_name" "$index_file"
        
        if [ $status -eq 0 ]; then
            print_status "success" "${BOLD}$keyword${NC} deployed successfully!"
            return 0
        else
            print_status "failed" "Package delivery failure on target OS for $keyword"
            return 1
        fi
    else
        print_status "failed" "Download blocked or network timeout!"
        rm -f "$index_file"
        return 1
    fi
}