#!/bin/sh

download_package_smart() {
    local sub_folder=$1   # این مقدار یا 'packages' هست یا 'luci'
    local keyword=$2      # نام پکیج مثل 'xray-core'
    local arch=$3         # معماری مثل arm_cortex-a7_neon-vfpv4
    local ins_cmd=$4
    local log_file=$5
    
    local index_file="/tmp/gh_${sub_folder}_index.json"
    
    # سوییچ کردن کامل به آینه‌ی پایدار گیت‌هاب (Rage-ac/Passwall2) برای دور زدن فیلترینگ/تحریم سورس‌فورج
    local base_url="https://github.com/Rage-ac/Passwall2/releases/download/25.12"
    local target_url="$base_url/${sub_folder}.json"
    
    print_status "work" "Resolving GitHub Mirror metadata for ${BOLD}$keyword${NC}"
    echo -e "   ${GRAY}✉ Requesting Stable Index: $target_url${NC}"
    
    # دانلود زنده ایندکس جی‌سان مربوطه از گیت‌هاب
    if ! wget -O "$index_file" "$target_url"; then
        print_status "failed" "Failed to fetch database index from GitHub Mirror!"
        return 1
    fi

    if [ ! -s "$index_file" ]; then
        print_status "failed" "Fetched GitHub index file is empty!"
        return 1
    fi

    # استخراج ورژن دقیق کامپوننت بر اساس ساختار معماری روتر شما
    # از اونجایی که ساختار فایل جی‌سان گیت‌هاب ممکنه تخت باشه یا کلایدری، سرچ رو منعطف‌تر می‌کنیم
    local pkg_version=$(grep -o "\"$keyword\": \"[^\"]*" "$index_file" | cut -d'"' -f4)
    if [ -z "$pkg_version" ]; then
        print_status "failed" "Version mapping for '$keyword' not found inside Github mirror index!"
        rm -f "$index_file"
        return 1
    fi
    print_status "done" "Version Resolution: v$pkg_version"
    
    # فرمت نهایی نام فایل طبق معماری دیوایس شما
    local full_name="${keyword}_${pkg_version}_${arch}.apk"
    local dl_url="$base_url/$full_name"
    
    print_status "sub" "Downloading Package: ${BOLD}$full_name${NC}"
    echo -e "   ${GRAY}📥 Pulling Package from GitHub: $dl_url${NC}"
    
    if wget -O "/tmp/$full_name" "$dl_url"; then
        print_status "sub" "Injecting package via APK into core OS"
        
        # نصب زنده پکیج و نمایش خروجی مستقیم روی صفحه
        if $ins_cmd "/tmp/$full_name"; then
            print_status "success" "${BOLD}$keyword${NC} deployed successfully!"
            rm -f "/tmp/$full_name" "$index_file"
            return 0
        else
            print_status "failed" "OS Package Manager rejected the APK installation!"
            rm -f "/tmp/$full_name" "$index_file"
            return 1
        fi
    else
        print_status "failed" "Download from GitHub Mirror blocked or timed out!"
        rm -f "$index_file"
        return 1
    fi
}