# android-debloater

>A minimal POSIX shell script to assist in debloating android devices.

**NOTE:**

*requires _POSIX-compliant_ shell!*

##
1) Install ADB

```
   curl --remote-name --location "https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
   mkdir "$HOME/.local"
   unzip "platform-tools-latest-linux.zip" -d "$HOME/.local"
   export PATH="$PATH:$HOME/.local/platform-tools"
   ```
##
2) Enable USB Debugging


- Entering the "Settings" app on your device
- Navigate to "About" > "Software Information"
- Tap "Build Number" 5 times, until Developer Mode is enabled
- Navigate to "Developer Settings"
- Toggle "USB Debugging" on


##
3) Curate your own debloat-list

- Do some research on which apk files are high-risk and/or unnecessary
- Find debloat-lists which others have created, for your device (be careful!)

*to transfer list of packages to a file:*

```
    (adb shell pm list packages) > "<path_to_pkg_list>"
```

Afterwards, you may leave **only** *_the packages you wish to delete_*,
commenting out ones you wish to save (if necessary) or removing them.

**NOTE:**

*packages within pkg_list file, must have the following format:*

[package:]com.android.chrome

...
##
4) Initiate a wireless/USB ADB connection between android device and computer

**after enabling USB Debugging**

- Connect android device to computer via USB cable
- Authorize connection to computer from your device
##
5) Run the script

```
    env pkg_list="<path-to-file>" android-debloater.sh [debloat|restore|help]
```


pkg_list - variable containing the path to packages file

debloat - debloats packages within pkg_list

restore - restores [deleted] packages within pkg_list

help    - displays a help-menu
