#!/usr/bin/env sh


# a debloat script for android devices.
#
# please do research before debloating, as removing the wrong apks can result
# in data-loss/corruption and/or os-reinstallation. consequently, a backup is
# highly recommended before proceeding further.
#
# rather than having a predefined list of apks labeled as bloatware, this
# script allows the user to pass a text-file in the working directory of the
# script, with the name pkg.list (or with the value of var: pkg_list)
#
# if you are unfamiliar with the process of debloating, please do a web-search
# on suspect packages, before deleting them, as there are often explanations of
# (otherwise unknown) apks, which may be found on your Android device.



# silence output (to stdout(1) & stderr(2), or both)
no_stdout() { $@ 1>/dev/null; }
no_stderr() { $@ 2>/dev/null; }
no_out() { $@ 1>/dev/null 2>/dev/null; }


# by default, the "action" variable will be
# set to the first argument passed to script ($1).
no_stderr ${action:=$1}


# all apk files (which are to be removed)
# will be kept here, in the following format:
#
# package:com.android.bluetooth
# etc ...
#
# by default, pkg_list file will be located in
# the $HOME directory, however this can be changed
# by setting env variable "pkg_list"
[ -n "$pkg_list" ] || pkg_list="$HOME/pkg.list"



# display help
display_help() {
	echo "usage: \`env [pkg_list=\"<uri-path to file>\"] $0 [<action>]\`\n\nenv variables:\npkg_list - path to pkg_list file\n\nActions:\ndebloat - remove packages\nrestore - restore [deleted] packages\nhelp - display this menu"
	return 1
}


# return error when action is not recognized
# by the script
action_not_found() {
	echo "invalid action [or no argument was passed to command-line]\nvalid actions: <debloat|restore|help>" >&2
	return 1
}


# return error when adb is not installed
# (or added to runtime exec-path)
adb_not_found() {
	echo "adb could not be found" >&2
	return 1
}


# return error when no device is recognizable
# by, or connected to adb
dev_not_connected() {
	echo "check that android device is:\n\n1): turned on\n2): plugged into your pc (via usb)\n3): connected to your pc (via adb w/ usb debugging enabled)" >&2
	exit 1
}


# return error when no package list is found,
# containing the list of apk files to remove
pkg_list_not_found() {
	echo "a package list containing the list of apks you wish to remove/restore has not been found:\n\n1): run \`adb shell pm list packages\` to obtain apk list\n2): add the apks you wish to remove/restore to \"$pkg_list\"\n\n(to change package list filename, \`env pkg_list=\"<path-to-file>\" $0 [restore|debloat]\`)\n(to fetch the package list from a device directly, and transfer it to a textfile, \`(adb shell pm list packages) > \"<path-to-file>\"\`)" >&2
	return 1
}


# return error when package list file is
# improperly formatted
pkg_list_invalid_format() {
	echo "package list found, however the file is likely improperly-formatted (or empty).\npackages listed inside of \"$pkg_file\", should have the format:\n[package:]com.android.chrome" >&2
	return 1
}


# return error when adb state is invalid
adb_state_invalid() {
	echo "invalid adb-state: $state" >&2
	return 1
}


# check whether adb can be ran
check_adb() {
	[ -e "$HOME/.local/platform-tools/adb" ] || [ -e "/usr/local/bin/adb" ] || [ -e "/usr/bin/adb" ] || adb_not_found
}


# check adb (connection) state
check_adb_state() {
	# start the adb daemon
	no_out adb start-server

	no_out adb get-state || dev_not_connected

	no_stderr export state="`adb get-state`"

	no_stderr [ "`adb get-state`" = "device" ] || adb_state_invalid
	
	unset state
}


# check pkg_list
check_pkg_list() {
	[ -f "$pkg_list" ] || pkg_list_not_found
}


# obtain (all) apks included within apk list
get_apk_all() {
	no_stderr grep '^[package:?.*$]' $pkg_list || pkg_list_invalid_format
}


# obtain the number of apks included within apk list
get_linecount() {
	no_stderr export linecount="`get_apk_all | wc -l`"
}


# obtain the current apk in the list
get_apk_curr() {
	curr_apk="`get_apk_all | sed -n "$i"p`" && \
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
	echo "[+] successfully ${action%%e}ed: $curr_apk [$i/$linecount]"
}


# return error msg
action_error() {
	echo "[-] error ${action%%e}ing: $curr_apk [$i/$linecount]" >&2
}


# perform action on each apk included within apk list,
# sequentially.
do_action_apks() {
	i=0 && {
		until [ $i -eq $linecount ]; do
			i=$((i + 1))
			get_apk_curr && do_action && action_success || action_error
		done
	};
	
	unset action linecount curr_apk pkg_list
}


precheck() {
	(check_action && check_adb && check_adb_state && check_pkg_list)
}


begin_action() {
	(no_stdout get_apk_all && get_linecount && do_action_apks)
}


do_all() {
	(precheck && begin_action)
}
do_all
