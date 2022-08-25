#!/usr/bin/env sh


# Linux Distribution in use
distro_id="$(grep ^ID /etc/os-release | cut -d '=' -f2)"


# command for checking if distro is compatible with script
distro_check() {
        [ "$distro_id" = "debian" ] || [ "$distro_id" = "fedora" ] || [ "$distro_id" = "arch" ]
}


# command for installing sdk-tools from common distro
# package managers
distro_install() {
        distro_check || {
                printf "%s\n%s\n" \
                        "Unrecognized Linux Distribution" \
                        "Install from distro package manager, or build android sdk-tools from source-code..." \
                        >&2
                return 1
        };
        
        printf "%s\n" "Performing $distro_id distro sdk-tools installation..."
        
        case "$distro_id" in
                "debian") sudo apt-get --quiet --assume-yes install adb        ;;
                "fedora") sudo dnf --quiet --assumeyes install android-tools   ;;
                  "arch") sudo pacman --sync --noconfirm --quiet android-tools ;;
        esac
}


# command for installing sdk-tools directly from
# google android repo
repo_install() {

        # Google only packages pre-compiled binaries for sdk tools,
        # for x86_64, and not aarch64 or arm...

        # Official Android SDK Platform Tools Repository
        sdk_tools_url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
        
        # Directory wherein sdk tools will be placed
        sdk_tools_dir="$HOME/.local"
        
        # Check (existence of) sdk tools dir
        [ -d "$sdk_tools_dir" ] || {
                printf "%s%s\n" "Default sdk-tools directory: " "\"$sdk_tools_dir\""
                mkdir "$sdk_tools_dir"
        };
        
        # Platform Tools zip-file
        tmpfile="/tmp/platform-tools-latest-linux.zip"
        
        [ -f "$tmpfile" ] || {
                printf "%s\n" "Downloading latest-release of android sdk platform-tools..."
                curl --silent --location --output "$tmpfile" "$sdk_tools_url"
        } || {
                printf "%s\n%s\n" \
                        "Could not obtain latest-release of android sdk platform-tools..." \
                        "Check Internet Connection (or try sudo \'to allow access to /tmp dir\')"
                return 1
        };
        
        # extract to sdk_tools_dir
        unzip -qq -o "$tmpfile" -d "$sdk_tools_dir"

        [ -d "$sdk_tools_dir/bin" ] || {
                printf "%s%s\n" "binaries for sdk-tools will be in: " "$sdk_tools_dir/bin"
                mkdir "$sdk_tools_dir/bin"
        };
        
        cd "$sdk_tools_dir/bin"
        
        for bin in adb \
                   dmtracedump \
                   e2fsdroid \
                   etc1tool \
                   fastboot \
                   hprof-conv \
                   make_f2fs \
                   make_f2fs_casefold \
                   mke2fs \
                   sload_f2fs \
                   sqlite3
        do
                [ -h "$bin" ] || ln -s "../platform-tools/$bin" "$bin"
        done
}


# command for obtaining method of installing sdk-tools
get_install_method() {


        case "$(arch)" in
                # default to a repo install (for compatibility reasons)
                "x86_64") repo_install   ;;
                # default to a distro package-manager installation
                       *) distro_install ;;
        esac
}

get_install_method
