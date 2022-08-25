#!/usr/bin/env sh


# Official Android SDK Platform Tools Repository
sdk_tools_url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"

# Directory wherein sdk tools will be placed
sdk_tools_dir="$HOME/.local"


# Check (existence of) sdk tools dir
[ -d "$sdk_tools_dir" ] || {
        printf "%s%s\n" "Default sdk-tools directory: " "\"$sdk_tools_dir\""
        mkdir "$sdk_tools_dir"
};


dl_sdk_tools() {
        printf "%s\n" "Downloading latest-release of android sdk platform-tools..."
        curl -sLo "$tmpfile" "$sdk_tools_url"
}


dl_sdk_tools_error() {
        printf "%s\n%s\n" \
                "Could not obtain latest-release of android sdk platform-tools..." \
                "Check Internet Connection (or try sudo \'to allow access to /tmp dir\')"
        return 1;
}


tmpfile="/tmp/platform-tools-latest-linux.zip"


[ -f "$tmpfile" ] || {
        dl_sdk_tools || dl_sdk_tools_error
};


unzip -qq -o -f "$tmpfile" -d "$sdk_tools_dir"


[ -d "$sdk_tools_dir/bin" ] || {
        printf "%s%s\n" "binaries for sdk-tools will be in: " "$sdk_tools_dir/bin"
        mkdir "$sdk_tools_dir/bin"
};


cd "$sdk_tools_dir/bin"


for bin \
        in \
        adb \
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


printf "%s\n" "Run (source \"\$HOME/.profile\") to apply changes..."
