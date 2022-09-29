#!/usr/bin/env sh
# vim: ts=2:sw=2:sts=2:


#========================================================#
# a debloat script for android devices.                  #
#                                                        #
# ( WARNING ! )                                          #
#                                                        #
# apk-removal can result in data-loss, or in requiring   #
# os reinstallation; consequently, a backup is highly-   #
# recommended                                            #
#                                                        #
# if you are unsure of certain packages you come across, #
# do a web-search on them, as explanations already exist #
# often, as to the package's purpose, permissions, etc.. #
#                                                        #
# Arguments:                                             #
#   $1 - action                                          #
#   $2 - apk_list                                        #
#                                                        #
# place apks you wish to delete within "apk_list"        #
#                                                        #
# format: [package:]com.android.bluetooth                #
#         [package:]com.android.chrome                   #
#                                                        #
# OR                                                     #
#                                                        #
# pass them directly as the second[..] argument          #
#                                                        #
# format: android_debloater.sh debloat \                 #
#                 com.android.bluetooth \                #
#                 com.android.chrome                     #
#========================================================#


# help function
help() (
  printf "%s\n\n%s\n%s\n%s\n\n%s\n%s\n%s\n" "usage: { $script [<action>] [<apk_list>]; }" \
                                            "action:" \
                                            "debloat - remove packages" \
                                            "restore - restore packages" \
                                            "apk_list:" \
                                            "<path> - path to a file containing list of apks" \
                                            "<string> - apk(s) passed as an argument to the script"
)


# help suggestion function
suggest_help() ( printf "%s\n" "To view valid options: { $script help; }" )


				      # regular expression to search for, and validate apks
apk_regexp='^\(package:\)\?\([A-Z\*a-z\+\_\*0-9\*]\+[\.]\{1\}\)\+[A-Z\*a-z\+\_\*0-9\*]\+$'
completed=0                           # no. of successful actions
missed=0                              # no. of failed actions
script=$0                             # for help-related functions
script_dir="$(dirname $script)"       # if installing sdk-tools
: "${parameters:="${@}"}"             # "parameters" to access later
: "${action:="${1}"}"                 # first parameter
				      # second[..?] parameter
[ ${#} -gt 2 ] && shift 1 && : "${apk_list:="${@}"}" || : "${apk_list:="${2}"}"


# error function
error() {
  case "${1}" in
    invalid_action)
      # exit if action is unrecognized by script
      [ -n "${action}" ] && \
        printf "%s\n" "invalid action: ${action}" >&2 || \
        printf "%s\n" "no action passed!" >&2
      suggest_help
      exit 1
      ;;
    invalid_apk_list)
      # exit if apk_list is unrecognized by script
      [ -n "${apk_list}" ] && \
        printf "%s\n" "invalid apk_list [format]: ${apk_list}" >&2 || \
        printf "%s\n" "no apk_list passed!" >&2
      suggest_help
      exit 1
      ;;
    adb_not_installed)
      # [attempt to] install adb if not found (else exit)
      printf "%s\n\n" "adb not found" >&2
      ( . "$script_dir/get_sdk_tools.sh" & wait $! ) || exit $?
      ;;
    device_not_connected)
      # exit if no device is recognized by, or connected to adb
      printf "%s\n\n%s\n%s\n%s\n" "check that android device is:" \
                                  "1)turned on" \
                                  "2)plugged into your pc (via usb)" \
                                  "3)connected to your pc (via adb w/ usb debugging enabled)" \
                                  >&2
      exit 1
      ;;
    invalid_adb_state)
      # exit if adb state is invalid
      printf "%s\n" "invalid adb-state: $state" >&2
      exit 1
      ;;
    apk_not_found)
      # return error if apk can not be found
      printf "%s\n" "[-] error [$i/$linecount]: $current_apk not found.." >&2
      return 1
      ;;
    action_failure)
      # return error if the action failed
      printf "%s\n" "[-] error ${action%%e}ing [$i/$linecount]: $current_apk" >&2
      return 1
      ;;
  esac
}


# check action parameter
check_action() {
  case ${action} in
    debloat|restore)                      ;;
               help) help; exit 0         ;;
                  *) error invalid_action ;;
  esac
}


# get [contents of] apk_list
get_apk_list() (
  (cat "${apk_list}" 2>/dev/null || echo "${apk_list}") | sed 's/[[:space:]]/\n/g' | grep $apk_regexp | uniq
)


# obtain the number of apks included within apk list
get_apk_list_linecount() {
  export linecount="$(get_apk_list | wc --lines)" 2>/dev/null
}


# get apk_list contents from device itself
get_device_apk_list() (
  case ${action} in
    debloat) adb shell pm list packages    ;;
    restore) adb shell pm list packages -u ;;
  esac
)


# check apk_list file/parameter
check_apk_list() (
  get_apk_list >/dev/null 2>&1 || error invalid_apk_list
)


# obtain the current apk in the list
get_current_apk() {
  current_apk="$(get_apk_list | sed --silent "$i"p)" && \
    export current_apk="${current_apk##package:}"
}


# check for validity of apk (before action)
check_current_apk() (
  get_device_apk_list | grep "$current_apk" || error apk_not_found
)


# start the adb daemon
start_adb() (
  printf "%s\n" "starting adb server..."
  sleep .5
  adb start-server >/dev/null 2>&1 && printf "%s\n\n" "success" && sleep .5
)


# shutdown the adb daemon
shutdown_adb() (
  printf "%s\n" "shutting down adb server..."
  sleep .5
  adb disconnect >/dev/null 2>&1 && adb kill-server && printf "%s\n\n" "success" && sleep .5
)


check_adb() (
  # check whether adb can be ran
  [ -x "$(command -v adb)" ] || error adb_not_installed
  # check adb (connection) state
  [ -n "$(pgrep adb)" ] || start_adb
  adb get-state >/dev/null 2>&1 || error device_not_connected
  export state="$(adb get-state)" 2>/dev/null
  [ "$(adb get-state)" = "device" ] 2>/dev/null || error invalid_adb_state
  unset state
)


# ensure correctness of parameters
check_parameters() {
  case ${#} in
    0) help; exit 1                                                           ;;
    1) check_action && [ "${action}" != "help" ] && error invalid_apk_list    ;;
    *) check_action && [ "${action}" != "help" ] && check_apk_list >/dev/null ;;
  esac
}


# perform [requested] action
do_action() (
  case ${action} in
    debloat) adb shell pm uninstall "$current_apk" >/dev/null 2>&1 || adb shell pm uninstall --user 0 "$current_apk" >/dev/null 2>&1 ;;
    restore) adb shell cmd package install-existing "$current_apk" >/dev/null 2>&1                                                   ;;
  esac
)


# return success msg
action_success() (
  printf "%s\n" "[+] successfully ${action%%e}ed [$i/$linecount]: $current_apk"
)


# perform postrequisite actions
post_action() (
  [ $completed -gt 0 ] && {
    printf "\n%s\n\n%s%u\n%s%u\n\n" \
           "${action} completed successfully!" \
           "apks ${action%%e}ed: " \
           "$completed" \
           "apks not ${action%%e}ed: " \
           "$missed"
    sleep 1
    printf "%s\n%s\n" \
           "reboot device?" \
           "(NOTE: reboot must take place for change(s) to take effect!)"
    read response
    echo
    case ${response} in
      [Yy][Ee][Ss]|[Yy])
        # reboot device
        printf "%s\n\n" "rebooting device.."
        sleep .5
        adb reboot
        ;;
                      *)
        ;;
    esac
  } || {
    printf "\n%s\n\n%s\n\n" "apks failed to ${action}.." \
                            "apks not ${action%%e}ed: $missed" \
                            >&2
  }
  shutdown_adb
  unset action linecount current_apk apk_list missed completed i reboot_status
  printf "%s" "press [ENTER] to exit... "
  (read blank)
)


# perform action on each apk included within apk list, sequentially.
do_action_apks() (
  i=0
  until [ $i -eq "$linecount" ]; do
    i=$((i + 1))
    get_current_apk
    check_current_apk >/dev/null && (do_action && action_success || error action_failure) && \
      export completed=$((completed + 1)) || \
      export missed=$((missed + 1))
  done
  post_action
)


precheck() (
  (check_parameters ${parameters} && check_adb)
)


begin_action() (
  (get_apk_list_linecount && do_action_apks)
)


do_all() (
  (precheck && begin_action)
)

trap '[ -n "$(pgrep adb)" ] && shutdown_adb; unset action linecount current_apk apk_list missed completed i reboot_status;' HUP INT

do_all
