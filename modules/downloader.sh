#!/bin/sh

# ================================================================
#  Smart Package Downloader — OpenWrt 25.x / APK
#  ورژن‌ها به‌صورت real-time از packages.adb خوانده می‌شن
# ================================================================

# cache محتوای APKINDEX برای هر subfolder (جلوگیری از دانلود مکرر)
_CACHE_passwall_packages=""
_CACHE_passwall2=""
_CACHE_passwall_luci=""

# ----------------------------------------------------------------
# _fetch_apkindex <sub_folder> <arch> <release>
#   دانلود و cache کردن محتوای APKINDEX از packages.adb
# ----------------------------------------------------------------
_fetch_apkindex() {
    local folder="$1"
    local arch="$2"
    local release="$3"

    # اگه قبلاً دانلود شده، همون رو برگردون
    local cache_var="_CACHE_${folder}"
    eval "local cached=\$$cache_var"
    if [ -n "$cached" ]; then
        echo "$cached"
        return 0
    fi

    local adb_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-${release}/${arch}/${folder}/packages.adb/download"
    local tmp_adb="/tmp/pw_${folder}.adb"

    # دانلود packages.adb
    if ! wget -q --timeout=20 -O "$tmp_adb" "$adb_url"; then
        return 1
    fi

    # استخراج APKINDEX از داخل tar.gz
    local content
    content=$(tar -xzf "$tmp_adb" -O 2>/dev/null)
    rm -f "$tmp_adb"

    if [ -z "$content" ]; then
        return 1
    fi

    # cache در متغیر مربوطه
    eval "$cache_var=\"\$content\""
    echo "$content"
    return 0
}

# ----------------------------------------------------------------
# _get_version_from_index <apkindex_content> <pkg_name>
#   استخراج ورژن یک پکیج از محتوای APKINDEX
# ----------------------------------------------------------------
_get_version_from_index() {
    local content="$1"
    local pkg="$2"

    echo "$content" | awk -v p="$pkg" '
        /^P:/ { name = substr($0, 3) }
        /^V:/ { if (name == p) { print substr($0, 3); exit } }
    '
}

# ----------------------------------------------------------------
# download_package_smart <sub_folder> <pkg_name> <arch> <release> <log_file>
#
#   sub_folder : passwall_packages | passwall2 | passwall_luci
#   pkg_name   : نام پکیج مثل xray-core یا luci-app-passwall2
#   arch       : معماری روتر (از /etc/openwrt_release)
#   release    : نسخه openwrt مثل 25.12
#   log_file   : مسیر فایل لاگ
# ----------------------------------------------------------------
download_package_smart() {
    local sub_folder="$1"
    local pkg_name="$2"
    local arch="$3"
    local release="$4"
    local log_file="$5"

    print_status "work" "Resolving version for ${pkg_name}..."

    # ---- گام ۱: دریافت APKINDEX ----
    local index_content
    index_content=$(_fetch_apkindex "$sub_folder" "$arch" "$release")
    if [ $? -ne 0 ] || [ -z "$index_content" ]; then
        print_status "failed" "Could not fetch packages.adb for folder: $sub_folder"
        return 1
    fi

    # ---- گام ۲: پیدا کردن ورژن ----
    local version
    version=$(_get_version_from_index "$index_content" "$pkg_name")
    if [ -z "$version" ]; then
        print_status "failed" "Package '$pkg_name' not found in packages.adb"
        return 1
    fi

    print_status "sub" "Found: ${pkg_name} => ${version}"

    # ---- گام ۳: ساخت نام فایل ----
    # luci و all-arch پکیج‌ها: _all.apk
    # بقیه: _<arch>.apk
    local file_arch="$arch"
    case "$pkg_name" in
        luci-*|luci_*) file_arch="all" ;;
    esac

    local apk_file="${pkg_name}-${version}_${file_arch}.apk"
    local base_url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-${release}/${arch}/${sub_folder}"
    local download_url="${base_url}/${apk_file}/download"
    local tmp_apk="/tmp/${apk_file}"

    print_status "work" "Downloading ${apk_file}..."

    # ---- گام ۴: دانلود ----
    if ! wget -q --timeout=30 -O "$tmp_apk" "$download_url"; then
        print_status "failed" "Download failed: $apk_file"
        rm -f "$tmp_apk"
        return 1
    fi

    # بررسی اینکه فایل واقعاً APK هست (نه صفحه HTML خطا)
    local fsize
    fsize=$(wc -c < "$tmp_apk" 2>/dev/null || echo 0)
    if [ "$fsize" -lt 1024 ]; then
        print_status "failed" "Downloaded file too small (${fsize}B) — likely a 404 page"
        rm -f "$tmp_apk"
        return 1
    fi

    # ---- گام ۵: نصب ----
    print_status "sub" "Installing ${apk_file}..."
    if apk add --allow-untrusted "$tmp_apk" >> "$log_file" 2>&1; then
        print_status "success" "${pkg_name} installed successfully!"
        rm -f "$tmp_apk"
        return 0
    else
        print_status "failed" "APK rejected installation of ${pkg_name}"
        rm -f "$tmp_apk"
        return 1
    fi
}

# ================================================================
# نمونه استفاده (برای تست — در اسکریپت اصلی حذف بشه)
# ================================================================
# . /etc/openwrt_release
# ARCH="$DISTRIB_ARCH"
# REL="${DISTRIB_RELEASE%.*}"
#
# download_package_smart "passwall_packages" "xray-core"   "$ARCH" "$REL" "/tmp/install.log"
# download_package_smart "passwall_packages" "sing-box"    "$ARCH" "$REL" "/tmp/install.log"
# download_package_smart "passwall_packages" "tcping"      "$ARCH" "$REL" "/tmp/install.log"
# download_package_smart "passwall_luci"     "luci-app-passwall2" "$ARCH" "$REL" "/tmp/install.log"