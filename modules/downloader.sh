#!/bin/sh

# ================================================================
#  Smart Package Downloader — OpenWrt 25.x / APK
#  ورژن‌ها real-time از packages.adb خوانده می‌شن (بدون hardcode)
# ================================================================

# Release رو یه‌بار می‌خونیم
if [ -z "$PW_RELEASE" ]; then
    PW_RELEASE=$(. /etc/openwrt_release 2>/dev/null; echo "${DISTRIB_RELEASE%.*}")
    [ -z "$PW_RELEASE" ] && PW_RELEASE="25.12"
fi

# Cache برای هر folder (فقط یه بار دانلود)
_CACHE_passwall_packages=""
_CACHE_passwall2=""
_CACHE_passwall_luci=""

# ----------------------------------------------------------------
# map_folder <short_name>
#   نام کوتاه → نام واقعی folder روی SourceForge
#   "packages" → "passwall_packages"
#   "luci"     → "passwall_luci"
#   بقیه       → همونطور که هست
# ----------------------------------------------------------------
_map_folder() {
    case "$1" in
        packages) echo "passwall_packages" ;;
        luci)     echo "passwall_luci"     ;;
        *)        echo "$1"                ;;
    esac
}

# ----------------------------------------------------------------
# _fetch_apkindex <real_folder> <arch>
#   دانلود و cache کردن APKINDEX از packages.adb
# ----------------------------------------------------------------
_fetch_apkindex() {
    local folder="$1"
    local arch="$2"

    # چک cache
    local cache_var="_CACHE_${folder}"
    eval "local cached=\$$cache_var"
    if [ -n "$cached" ]; then
        echo "$cached"
        return 0
    fi

    local url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-${PW_RELEASE}/${arch}/${folder}/packages.adb/download"
    local tmp="/tmp/pw_${folder}.adb"

    if ! wget -q --timeout=20 -O "$tmp" "$url"; then
        rm -f "$tmp"
        return 1
    fi

    local content
    content=$(tar -xzf "$tmp" -O 2>/dev/null)
    rm -f "$tmp"

    [ -z "$content" ] && return 1

    eval "$cache_var=\"\$content\""
    echo "$content"
}

# ----------------------------------------------------------------
# _get_version <apkindex_content> <pkg_name>
# ----------------------------------------------------------------
_get_version() {
    echo "$1" | awk -v p="$2" '
        /^P:/ { name = substr($0,3) }
        /^V:/ { if (name == p) { print substr($0,3); exit } }
    '
}

# ----------------------------------------------------------------
# download_package_smart <folder> <pkg> <arch> <install_cmd> <log>
#
#   folder      : packages | luci | passwall2 | passwall_packages | passwall_luci
#   pkg         : نام پکیج مثل xray-core
#   arch        : معماری روتر
#   install_cmd : (استفاده نمی‌شه — برای سازگاری با caller نگه داشتیم)
#   log         : مسیر فایل لاگ
# ----------------------------------------------------------------
download_package_smart() {
    local folder="$1"
    local pkg="$2"
    local arch="$3"
    # $4 = install_cmd (ignored — ما مستقیم apk add می‌زنیم)
    local log_file="$5"

    # نگاشت folder
    local real_folder
    real_folder=$(_map_folder "$folder")

    print_status "work" "Resolving version for ${pkg}..."

    # دریافت index
    local index
    index=$(_fetch_apkindex "$real_folder" "$arch")
    if [ $? -ne 0 ] || [ -z "$index" ]; then
        print_status "failed" "Could not fetch packages.adb  [folder: $real_folder]"
        return 1
    fi

    # پیدا کردن ورژن
    local version
    version=$(_get_version "$index" "$pkg")
    if [ -z "$version" ]; then
        print_status "failed" "Package '$pkg' not found in packages.adb"
        return 1
    fi

    print_status "sub" "Found: ${pkg} => ${version}"

    # نام فایل — luci پکیج‌ها همیشه _all هستن
    local file_arch="$arch"
    case "$pkg" in luci-*) file_arch="all" ;; esac

    local apk_file="${pkg}-${version}_${file_arch}.apk"
    local url="https://sourceforge.net/projects/openwrt-passwall-build/files/releases/packages-${PW_RELEASE}/${arch}/${real_folder}/${apk_file}/download"
    local tmp="/tmp/${apk_file}"

    print_status "work" "Downloading ${apk_file}..."

    if ! wget -q --timeout=30 -O "$tmp" "$url"; then
        print_status "failed" "Download failed: $apk_file"
        rm -f "$tmp"
        return 1
    fi

    # چک سایز — جلوگیری از نصب صفحه HTML خطا
    local fsize
    fsize=$(wc -c < "$tmp" 2>/dev/null || echo 0)
    if [ "$fsize" -lt 1024 ]; then
        print_status "failed" "File too small (${fsize}B) — probably a 404 page"
        rm -f "$tmp"
        return 1
    fi

    print_status "sub" "Installing ${apk_file}..."
    if apk add --allow-untrusted "$tmp" >> "$log_file" 2>&1; then
        print_status "success" "${pkg} installed!"
        rm -f "$tmp"
        return 0
    else
        print_status "failed" "APK rejected: ${pkg}"
        rm -f "$tmp"
        return 1
    fi
}