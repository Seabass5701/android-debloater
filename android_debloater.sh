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


completed=0
missed=0


# silence output (to stdout(1) & stderr(2), or both)
no_stdout() { $@ 1>/dev/null; }
no_stderr() { $@ 2>/dev/null; }
no_out() { $@ 1>/dev/null 2>/dev/null; }


# by default, the "action" variable will be set to the first argument passed to script ($1).
no_stderr ${action:="$1"}


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
no_stderr ${apk_list:="`echo $@ | sed "s/$1 //"`"}




# display help
display_help() {
	echo "usage: { $0 [<action>] [<apk_list>]; }\n\nActions:\ndebloat - remove packages\nrestore - restore [deleted] packages\nhelp - display [this] help-menu"
	return 1
}


# return error when action is not recognized by the script
action_not_found() {
	echo "invalid action (or no [first] argument was passed to script)\nto view valid options: { $0 help; }" >&2
	return 1
}


# return error when adb is not installed (or added to runtime exec-path)
adb_not_found() {
	echo "adb could not be found" >&2
	return 1
}


# return error when no device is recognizable by, or connected to adb
dev_not_connected() {
	echo "check that android device is:\n\n1)turned on\n2)plugged into your pc (via usb)\n3)connected to your pc (via adb w/ usb debugging enabled)" >&2
	exit 1
}


# return error when no apk list is found, containing the list of apk files to remove
apk_list_not_found() {
	echo "invalid apk_list (or no apk list was passed to the script)\n\n{ $0 ${action} \$apk_list; }\n\n1)run (adb shell pm list packages) to fetch apk list,\n2)add those apks you wish to ${action} into an apk-file list, or pass [those] apks directly to the script\n\n3)to add them to a file, run:\n\nexport apk_list=\"<path_to_file>\"\n(adb shell pm list packages) > \"\$apk_list\"" >&2
	return 1
}


# return error when package list file is improperly formatted
apk_list_invalid_format() {
	echo "apk list found, however the file is likely improperly-formatted (or empty), or the apks passed were erroneous.\npackages listed inside of \"$pkg_file\", should have the format:\n[package:]com.android.chrome\n[package:]com.android.bluetooth\n...\n\npackages passed as arguments should have the format: com.android.chrome com.android.bluetooth ..." >&2
	return 1
}


# return error when adb state is invalid
adb_state_invalid() {
	echo "invalid adb-state: $state" >&2
	return 1
}


# return error when apk can not be found (for de-installation)
apk_not_found() {
	echo "[-] error [$i/$linecount]: $curr_apk not found.." >&2
	return 1
}


# return error when main action/process fails
do_action_failed() {
	echo "no apks were ${action%%e}ed.." >&2
	return 1
}


# start the adb daemon
start_adb() { no_out adb start-server; }


# shutdown the adb daemon
shutdown_adb() { no_stdout adb disconnect && adb kill-server; }


# check whether adb can be ran
check_adb() {
	[ -x "/usr/local/bin/adb" -o -x "/usr/bin/adb" -o -x "$HOME/.local/platform-tools/adb" ] || adb_not_found
}


# check adb (connection) state
check_adb_state() {
	start_adb

	no_out adb get-state || dev_not_connected

	no_stderr export state="`adb get-state`"
		
	no_stderr [ "`adb get-state`" = "device" ] || adb_state_invalid
	
	unset state
}


# check apk_list
check_apk_list() {
	[ -f "$apk_list" -o -n "$apk_list"  ] || apk_list_not_found
}


# obtain (all) apks included within apk list
get_apk_list() {
	cat $apk_list | grep '^[package:?.*$]' | sed "s/[[:space:]]/\n/g" || apk_list_invalid_format
}


# obtain (all) apks from the device itself
get_apk_list_dev() {
	case "$action" in
		debloat) adb shell pm list packages ;;
	        restore) adb shell pm list packages -u ;;	
	esac
}


# check for validity of apk (before action)
check_apk() {
	get_apk_list_dev | grep "$curr_apk" || apk_not_found
}


# obtain the number of apks included within apk list
get_apk_list_linecount() {
	no_stderr export linecount="`get_apk_list | wc --lines`"
}


# obtain the current apk in the list
get_apk_curr() {
	curr_apk="`get_apk_list | sed --silent "$i"p`" && \
		export curr_apk=${curr_apk##package:}
}


# check action being performed
check_action() {
	case "$action" in
		debloat|restore) continue ;;
		           help) display_help ;;
			      *) action_not_found ;;
	esac
}


# perform [requested] action
do_action() {
	case "$action" in
		debloat) no_out adb shell pm uninstall $curr_apk || no_out adb shell pm uninstall --user 0 $curr_apk ;;
		restore) no_out adb shell cmd package install-existing $curr_apk ;;
	esac
}


# return success msg
action_success() {
	echo "[+] successfully ${action%%e}ed [$i/$linecount]: $curr_apk"
}


# return error msg
action_error() {
	echo "[-] error ${action%%e}ing [$i/$linecount]: $curr_apk" >&2
}


# perform postrequisite actions
post_action() {
	[ $completed -gt 0 ] && {
		echo "${action} completed successfully!\n\napks ${action%%e}ed: $completed\napks not ${action%%e}ed: $missed\n\n"
		sleep 1

		# reboot device
		echo "rebooting device.."
		adb reboot
	} || { do_action_failed; }

	shutdown_adb

	unset action linecount curr_apk apk_list

	echo "press any key to exit..."
	read blank
}


# perform action on each apk included within apk list, sequentially.
do_action_apks() {
	i=0

	until [ $i -eq $linecount ]; do
		i=$((i + 1))
		get_apk_curr
		no_stdout check_apk && (do_action && action_success || action_error) && \
			export completed=$((completed + 1)) || \
			export missed=$((missed + 1))
	done

	post_action
}


precheck() {
	(check_action && check_apk_list && check_adb && check_adb_state)
}


begin_action() {
	(no_stdout get_apk_list && get_apk_list_linecount && do_action_apks)
}


do_all() {
	(precheck && begin_action)
}

trap 'post_action' HUP INT ILL ABRT KILL TRAP PWR

do_all
