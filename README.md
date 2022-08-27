# android-debloater

>A minimal POSIX shell script to assist in debloating android devices.

#### **\*NOTE:  _POSIX-compliant_ shell required!\*** ####
####


## Overall Scope

###
   - portability (POSIX-compliance provides greater conformity)
   - automation (automate the task of <b>debloating</b> or <b>restoring</b> apks)
   - simplicity (does _two_ things: <b>debloats</b> & <b>restores</b>)</b>
###

## Getting Started

#### Before anything else, perform the following steps:

####
<details><summary><b>1) [Enable Developer Mode]</b></summary>
   
   #####
   1) Go into the "Settings" app on your Android Device
   #####
   2) Search for: "Build Number"
   ```
   (usually located somewhere in Settings -> About)
   ```
   #####
   3) Tap "Build Number" 5 times consecutively (agreeing/responding to any prompts as required)
   #####
   <b>After performing these steps, you should receive a notification that Developer Mode was enabled</b>
   ##
   
</details>

####
<details><summary><b>2) [Enable USB Debugging]</b></summary>

   #####
   1) Go into the "Settings" app on your Android Device
   #####
   2) Search for: "Developer Settings"
   ```
   (usually located in the root of the settings menu, otherwise in Settings -> System)
   ```
   #####
   3) Toggle "USB Debugging" to on (continue, if given a warning)
   #####
   <b>IMPORTANT NOTE:</b>
   
   Do not leave USB Debugging on for longer than you intend to keep your device connected!
   ##
   
</details>

#### Next, obtain sources
#####
```shell
git clone https://github.com/Seabass5701/android-debloater.git
cd android-debloater
chmod u+x ./*.sh
```
#####
####
## Usage

```
    android_debloater.sh { [<action>] [<apk_list>] || help }
```

#### Parameters

action   - action to perform on [<apk_list>] (debloat / restore)

apk_list - [list of] apks to perform [<action>] upon

help     - display help menu

#### [action]
```shell
debloat - debloat packages
restore - restore [deleted] packages
```
#### [apk_list]
- may be passed as a file, which contains list of apks (comments allowed)
```shell
# file should be formatted as follows:

# here is a test comment
[package:]com.android.chrome        # Google Chrome APK
[package:]com.android.bluetooth     # Bluetooth APK
[...]                               # Etc..
```

- may be passed as actual apk name[s]
```shell
./android_debloater.sh [<action>] \
       com.android.chrome \
       com.android.bluetooth \
       [...]
```

##
