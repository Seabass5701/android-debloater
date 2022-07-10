# android-debloater

>A minimal POSIX shell script to assist in debloating android devices.

#### **\*NOTE:  _POSIX-compliant_ shell required!\*** ####
####


## Overall Scope

### This script aims to be:
   - small (written in a little over 200-lines)
   - simple (not overly complex, but gets the job done)
   - quick (written in dash, which runs faster than bash)
   - efficient (quite performant, given its size and simplicity)
###

### It simply does *_two_* things:
   - debloats
   - restores
###

### It can read apks:
   - from a file
   - passed as arguments to the script after [<action\>]
   
###

## Getting Started

####

<details><summary>1) Install ADB</summary>
   
   #####
   - Download ADB
   ```shell
      curl --remote-name --location "https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
   ```
   
   #####
   - Extract to an *_appropriate_* directory
   ```shell
      export adb_dir="$HOME/.local"
   
      mkdir --parents "$adb_dir"
      
      unzip "platform-tools-latest-linux.zip" -d "$adb_dir"
   ```
   
   #####
   - Adjust PATH variable (if necessary)
```shell
   export PATH="$PATH:$adb_dir:"
```
   
   ##
   
</details>

####
<details><summary>2) Enable USB Debugging</summary>
   
   #####
   - Go into the "Settings" app on your device
   #####
   - Go to "About" / "About-Phone
   #####
   - Go to "Software Information"
   #####
   - Tap "Build Number" 5 times consecutively, until Developer Mode is enabled
   #####
   - Go to "Developer Settings"
   #####
   - Toogle "USB Debugging" On
   #####
   
   ##
   
</details>

####
<details><summary>3) Initiate a Wireless/USB ADB-connection between android device and computer</summary>

   ### **after enabling USB Debugging**

   #####
   - Connect android device to computer via USB cable
   #####
   - Authorize connection to computer from your device
   
   ##
   
</details>

####
<details><summary>4) Clone the repo</summary>
   
   #####
   ```shell
      git clone https://github.com/Seabass5701/android-debloater
      
      cd android-debloater
   
      chmod u+x android_debloater.sh
   ```
   #####
</details>

## Usage

```
    android_debloater.sh [<action>] [<apk_list>]
```


apk_list - path to apk file list / apks passed to the script after action

debloat - debloats packages within apk_list

restore - restores [deleted] packages within apk_list

help    - displays a help-menu

## Optional (Create your own debloat-list)
   
   ### *to transfer list of apks to a file:*
   
   ```shell
    (adb shell pm list packages) > "<path_to_apk_list>"
   ```
   
   **NOTE:**
   
   *apks within apk_list file, must have the following format:*

   ```shell
      [package:]com.android.chrome
      [package:]com.android.bluetooth
      [...]
   ```
   
   Afterwards, you may leave **only** *_the packages you wish to delete_*,
   commenting out ones you wish to save (if necessary) or removing them.

   ##
   
   ### *to pass apks to the script as argument:*

   ```shell
    ./android_debloater.sh debloat \
            [package:]com.android.chrome \
            [package:]com.android.bluetooth \
            [...]
   ```
   
   **NOTE:**
   
   *apks passed as arguments to the script, must have the following format:*

   ```shell
      [package:]com.android.chrome [package:]com.android.bluetooth [...]
   ```

   ##
   
   ####
   - Do some research on which apk files are high-risk and/or unnecessary

   ####
   - Find debloat-lists which others have created, for your device (**be careful!**)
   
   ####





   

   
   
