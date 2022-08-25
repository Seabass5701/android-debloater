#!/usr/bin/env sh


# a debloat script for android devices.
#
# please do research before debloating, as removing the wrong apks can result
# in data-loss/corruption and/or os-reinstallation. consequently, a backup is
# highly recommended before proceeding further.
#
# rather than having a predefined list of apks labeled as bloatware, this
# script allows the user to pass a text-file (containing the list of apks),
# or the name(s) of package(s) passed as the second argument to the script.
#
# if you are unfamiliar with the process of debloating, please do a web-search
# on suspect packages, before deleting them, as there are often explanations of
# (otherwise unknown) apks, which may be found on your android device.


completed=0			# no. of successful actions
missed=0			# no. of failed actions
script_dir="$(dirname $0)"	# in case sdk tools need to be installed


# silence output (to stdout(1) & stderr(2), or both)
no_stdout() { "$@" >/dev/null; }
no_stderr() { "$@" 2>/dev/null; }
no_out() { "$@" >/dev/null 2>&1; }


# by default, the "action" variable will be set to the first argument passed to script ($1).
: "${action:="$1"}"


# by default, the "apk_list" variable will be set to the second argument passed to script ($2).
#
# apks you wish to delete from your device, may be placed here within this file
#
# format: [package:]com.android.bluetooth
#         [package:]com.android.chrome
#         ...
#
# OR
#
# passed directly to the script as arguments
#
# format: android_debloater.sh debloat \
#                 com.android.bluetooth \
#                 com.android.chrome \
#                 ...


# if (at-least) two arguments
[ -n "$1" ] && [ -n "$2" ] && \
        # remove first arg + space after first arg
        : "${apk_list:=${@##"$1"[[:space:]]}}" || \
        # else (if < 2 args) only remove first arg
        : "${apk_list:=${@##"$1"}}"


# display help
display_help() {
        printf "%s\n\n%s\n%s\n%s\n%s\n\n%s\n%s\n" \
                "usage: { $0 [<action>] [<apk_list>]; }" \
                "actions:" \
                "debloat - remove packages" \
                "restore - restore [deleted] packages" \
                "help - display [this] help menu" \
                "apk_list - [path to a file containing list of apks] OR" \
                "           [list of apks passed as arguments to the script]"
        return 1
}


# return error when action is not recognized by the script
action_not_found() {
        printf "%s\n%s\n" \
                "invalid action (or no [first] argument was passed to script)" \
                "to view valid options: { $0 help; }" \
                >&2
        return 1
}


# return error when adb is not installed (or added to runtime exec-path)
adb_not_found() {
        printf "%s\n\n" \
                "adb could not be found" \
                >&2
	printf "%s\n" \
		"proceed with automatic installation of adb?"
		
	read install_status
	
	echo
	
	case "$install_status" in
		[Yy][Ee][Ss]|[Yy]) . "$script_dir/get_sdk_tools.sh" ;;
				*) return 1 ;;
	esac
}


# return error when no device is recognizable by, or connected to adb
dev_not_connected() {
        printf "%s\n\n%s\n%s\n%s\n" \
                "check that android device is:" \
                "1)turned on" \
                "2)plugged into your pc (via usb)" \
                "3)connected to your pc (via adb w/ usb debugging enabled)" \
                >&2
        exit 1
}


# return error when no apk list is found, containing the list of apk files to remove
apk_list_not_found() {
        printf "%s\n\n%s\n\n\n%s\n\n%s\n%s\n\n%s\n\n%s\n%s\n" \
                "no apk list was passed to the script" \
                "{ $0 ${action} [<apk_list>]; }" \
                "1)run (adb shell pm list packages) to fetch apk list," \
                "2)add those apks you wish to ${action} into an apk-file list (commenting out those you wish to exclude)," \
                "or pass them as arguments after [<action>] directly to the script" \
                "3)to add apks to a file, run: (adb shell pm list packages) > \"[<path_to_file>]\"" \
                "4)to pass as args, run: { $0 ${action} [apk [apk1] ... ]; }," \
                "where \"[apk]\" is an apk filename (i.e com.android.bluetooth, com.android.chrome, etc...)" \
                >&2
        return 1
}


# return error when package list file is improperly formatted
apk_list_invalid_format() {
        printf "%s\n\n\n%s\n\n%s\n%s\n%s\n\n%s\n\n%s\n" \
                "apk list found, however the file is likely improperly-formatted, or the apks passed were of an erroneous format." \
                "packages listed inside of [<apk_file>], should have the format:" \
                "[package:]com.android.chrome" \
                "[package:]com.android.bluetooth" \
                "..." \
                "packages passed as arguments should have the format:" \
                "com.android.chrome com.android.bluetooth ..." \
                >&2
        return 1
}


# return error when adb state is invalid
adb_state_invalid() {
        printf "%s\n" \
                "invalid adb-state: $state" \
                >&2
        return 1
}


# return error when apk can not be found (for de-installation)
apk_not_found() {
        printf "%s%u%c%u%s\n" \
                "[-] error [" \
                "$i" \
                "/" \
                "$linecount" \
                "]: $curr_apk not found.." \
                >&2
        return 1
}


# start the adb daemon
start_adb() {
        printf "%s\n" \
                "starting adb server..."
        sleep .5
        no_out adb start-server && printf "%s\n\n" \
                "success" && sleep .5
}


# shutdown the adb daemon
shutdown_adb() {
        printf "%s\n" \
                "shutting down adb server..."
        sleep .5
        no_stdout adb disconnect && adb kill-server && printf "%s\n\n" "success" && sleep .5
}


# check whether adb can be ran
check_adb() {
        [ -x "$(which adb)" ] || adb_not_found
}


# check adb (connection) state
check_adb_state() {
        [ -n "$(pgrep adb)" ] || start_adb

        no_out adb get-state || dev_not_connected

        no_stderr export state="$(adb get-state)"

        no_stderr [ "$(adb get-state)" = "device" ] || adb_state_invalid

        unset state
}


# check apk_list
check_apk_list() {
        [ -n "$apk_list" ] || apk_list_not_found
}


# obtain (all) apks included within apk list
get_apk_list() {
        (no_stderr cat "$apk_list" || echo "$apk_list") | \
                sed 's/[[:space:]]/\n/g' | \
                grep '^\(package:\)\?\([A-Z\*a-z\+\_\*0-9\*]\+[\.]\{1\}\)\+[A-Z\*a-z\+\_\*0-9\*]\+$' || \
                apk_list_invalid_format
}


# obtain (all) apks from the device itself
get_apk_list_dev() {
        case ${action} in
                debloat) adb shell pm list packages    ;;
                restore) adb shell pm list packages -u ;;
        esac
}


# check for validity of apk (before action)
check_apk() {
        get_apk_list_dev | grep "$curr_apk" || apk_not_found
}


# obtain the number of apks included within apk list
get_apk_list_linecount() {
        no_stderr export linecount="$(get_apk_list | uniq | wc --lines)"
}


# obtain the current apk in the list
get_apk_curr() {
        curr_apk="$(get_apk_list | uniq | sed --silent "$i"p)" && \
                export curr_apk="${curr_apk##package:}"
}


# check action being performed
check_action() {
        case ${action} in
                debloat|restore) return ;;
                           help) display_help ;;
                              *) action_not_found ;;
        esac
}


# perform [requested] action
do_action() {
        case ${action} in
                debloat) no_out adb shell pm uninstall "$curr_apk" || no_out adb shell pm uninstall --user 0 "$curr_apk" ;;
                restore) no_out adb shell cmd package install-existing "$curr_apk" ;;
        esac
}


# return success msg
action_success() {
        printf "%s%u%c%u%s\n" \
                "[+] successfully ${action%%e}ed [" \
                "$i" \
                "/" \
                "$linecount" \
                "]: $curr_apk"
}


# return error msg
action_error() {
        printf "%s%u%c%u%s\n" \
                "[-] error ${action%%e}ing [" \
                "$i" \
                "/" \
                "$linecount" \
                "]: $curr_apk" \
                >&2
}


# perform postrequisite actions
post_action() {
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
		read reboot_status
		
		echo
		
		case "$reboot_status" in
			[Yy][Ee][Ss]|[Yy])
				# reboot device
				printf "%s\n\n" "rebooting device.."
				sleep .5
				adb reboot
				;;
				        *)
				continue
				;;
		esac
        } || {
                printf "\n%s\n\n%s%u\n\n" \
                        "apks failed to ${action}.." \
                        "apks not ${action%%e}ed: " \
                        "$missed" \
                        >&2
        }

        shutdown_adb

        unset action linecount curr_apk apk_list missed completed i reboot_status

        printf "%s" "press [ENTER] to exit... "
        (read blank)
}


# perform action on each apk included within apk list, sequentially.
do_action_apks() {
        i=0

        until [ $i -eq "$linecount" ]; do
                i=$((i + 1))
                get_apk_curr
                no_stdout check_apk && (do_action && action_success || action_error) && \
                        export completed=$((completed + 1)) || \
                        export missed=$((missed + 1))
        done

        post_action
}


precheck() {
        (check_action && check_apk_list && no_stdout get_apk_list && check_adb && check_adb_state)
}


begin_action() {
        (get_apk_list_linecount && do_action_apks)
}


do_all() {
        (precheck && begin_action)
}

trap '[ -n "$(pgrep adb)" ] && shutdown_adb; unset action linecount curr_apk apk_list missed completed i reboot_status;' HUP INT

do_all
