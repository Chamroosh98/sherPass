#!/bin/sh

download_package_smart() {
    local sub_folder=$1
    local keyword=$2
    local arch=$3
    local ins_cmd=$4
    local log_file=$5
    local index_file="/tmp/sf_${sub_folder}_index.json"
    
    # اصلاح و ساخت دقیق آدرس URL سورس‌فورج
    local base_url="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/$arch"
    local target_url="$base_url/$sub_folder/index.json"
    
    print_status "work" "Resolving SourceForge metadata for ${BOLD}$keyword${NC}"
    echo -e "   ${GRAY}✉ Requesting Index: $target_url${NC}"
    
    # خروجی ارور wget رو به صورت زنده نمایش میدیم تا دلیل Fail شدن رو ببینی
    if ! wget -O "$index_file" "$target_url"; then
        print_status "failed" "Failed to fetch database index from SourceForge!"
        return 1
    fi

    if [ ! -s "$index_file" ]; then
        print_status "failed" "Fetched index file is empty!"
        return 1
    fi

    # پارس دقیق مقدار کلید
    local pkg_version=$(grep -o "\"$keyword\": \"[^\"]*" "$index_file" | cut -d'"' -f4)
    if [ -z "$pkg_version" ]; then
        print_status "failed" "Version mapping for '$keyword' not found inside index.json!"
        rm -f "$index_file"
        return 1
    fi
    print_status "done" "Version Resolution: v$pkg_version"
    
    # فرمت نام فایل apk بر اساس پکیج‌منیجر جدید اوپن‌ورت ۲۵
    local full_name="${keyword}_${pkg_version}_${arch}.apk"
    local dl_url="$base_url/$sub_folder/$full_name"
    
    print_status "sub" "Downloading Package: ${BOLD}$full_name${NC}"
    echo -e "   ${GRAY}📥 Pulling Package from: $dl_url${NC}"
    
    if wget -O "/tmp/$full_name" "$dl_url"; then
        print_status "sub" "Injecting package via APK into core OS"
        
        # لاگ زنده پکیج منیجر روی ترمینال برای رهگیری کامپوننت‌ها
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
        print_status "failed" "Download connection blocked or timed out!"
        rm -f "$index_file"
        return 1
    fi
}