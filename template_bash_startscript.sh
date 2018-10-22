#!/usr/bin/env bash
#################################################################################
#################################################################################
#										#
#		-			   Copyright (C) Christian Stenzel, 2018#
#										#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# editor settings								#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	indent		tabs							#
#	tabwidth	8							#
#################################################################################
#################################################################################


#							      declare error codes
#################################################################################
declare -i _ok=0
declare -i _error__invalid_device_file=1
declare -i _error__mount=2
declare -i _error__umount=3
declare -i _error__file_not_found=4
declare -i _error__file_not_executable=5
declare -i _error__file_remove=6
declare -i _error__dir_remove=7
declare -i _error__dir_not_found=8
declare -i _error__script_execution=9
declare -i _error__binary_not_found=10
declare -i _error__usage=11
declare -i _retmain

#################################################################################
#									  START	#
#///////////////////////////////////////////////////////////////////////////////#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# no params									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# return									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	ok									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# errors									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	invalid_device_file							#
#	file_remove								#
#	file_not_found								#
#	file_not_executable							#
#	file_remove								#
#	mount									#
#	script_execution							#
#	umount									#
#################################################################################
start()
{
	#							    script locals
	#########################################################################
	local _fstype="ext4"			# file system of "$MP"
	local _devfile="/dev/mmcblk0p1"		# device file containing boot-
						# loader postinstall files
	local _postinst="$MP/postinstall.sh"	# abs script path

	#								   verify
	#########################################################################
	[ ! -b "$_devfile"	]	&& return $_error__invalid_device_file

	#								    mount
	#########################################################################
	if ! $MOUNT -t "$_fstype" -nsv -o "nodev" "$_devfile" "$MP";
	then
		return $_error__mount
	fi

	#								   verify
	#########################################################################
	[ ! -f "$_postinst"	]	&& return $_error__file_not_found
	[ ! -x "$_postinst"	]	&& return $_error__file_not_executable

	#							      exec script
	#########################################################################
	"$_postinst"			|| return $_error__script_execution

	#								 clean up
	#########################################################################
	$RM "$_postinst"		|| return $_error__file_remove
	$UMOUNT "$MP"			|| return $_error__umount
	
	return $_ok
}

#################################################################################
#									   STOP	#
#///////////////////////////////////////////////////////////////////////////////#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# no params									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# return									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	_ok									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# errors									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	dir_remove								#
#	umount									#
#################################################################################
stop() 
{
	[ ! -d "$MP"		]	&& return $_ok	 # do nothing return true

	#								 clean up
	#########################################################################
	$UMOUNT "$MP"			|| return $_error__umount
	$RM -rf "$MP"			|| return $_error__dir_remove

	return $_ok 
}

#################################################################################
#									   MAIN	#
#///////////////////////////////////////////////////////////////////////////////#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# params									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	$1	(start|stop)							#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# return									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	_ok									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# errors									#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#	binary_not_found							#
#	dir_not_found								#
#	dir_remove								#
#	umount									#
#	usage									#
#################################################################################
main()
{
	# 							 script externals
	#########################################################################
	declare MOUNT					# location of mount
	declare	UMOUNT					# location of umount
	declare RM					# location of rm
	declare BASENAME				# location of basename
	declare PRINTF					# location of printf

	#							   script globals
	#########################################################################
	declare TMP="/tmp"				# tmpdir
	declare MP="$TMP/BLPART"			# mountpoint of image

	#							    script locals
	#########################################################################
	local _scriptname				# current name of script

	#							 assign externals
	#########################################################################
	MOUNT="$(command -v mount)"			# get mount
	UMOUNT="$(command -v umount)"			# get umount
	RM="$(command -v rm)"				# get rm
	BASENAME="$(command -v basename)"		# get basename
	PRINTF="$(command -v printf)"			# get printf

	#							 verify externals
	#########################################################################
	[ -z ${MOUNT+0}		]	&& return $_error__binary_not_found
	[ -z ${UMOUNT+0}	]	&& return $_error__binary_not_found
	[ -z ${RM+0}		]	&& return $_error__binary_not_found
	[ -z ${BASENAME+0}	]	&& return $_error__binary_not_found
	[ -z ${PRINTF+0}	]	&& return $_error__binary_not_found

	#							   verify globals
	#########################################################################
	[ ! -d "$TMP"		]	&& return $_error__dir_not_found
	[ ! -d "$MP"		]	&& mkdir "$MP"	# exists mp

	#							    assign locals
	#########################################################################
	_scriptname="$("$BASENAME" "$0")"

	#								     exec
	#########################################################################
	case "$1" in
	start)
		$PRINTF "=== %s: Starting\\n" "$_scriptname"
		start			|| return $?
		;;
	stop)
		$PRINTF "=== %s Stopping\\n" "$_scriptname"
		stop 			|| return $?
		;;
	*)
		return $_error__usage	
		;;
	esac
}

#								     calling main
#################################################################################
main "$@"
_retmain=$?
case $_retmain in
	$_error__invalid_device_file)
		$PRINTF "=== %s: File is not a block device.\\n"\
			"$_scriptname" 1>&2
	;;
	$_error__mount)
		$PRINTF "=== %s: Error mount.\\n" "$_scriptname" 1>&2
	;;
	$_error__umount)
		$PRINTF "=== %s: Error umount.\\n" "$_scriptname" 1>&2
	;;
	$_error__file_not_found)
		$PRINTF "=== %s: File not found.\\n" "$_scriptname" 1>&2
	;;
	$_error__file_not_executable)
		$PRINTF "=== %s: File is not executable.\\n"\
			"$_scriptname" 1>&2
	;;
	$_error__file_remove)
		$PRINTF "=== %s: Error removing file.\\n"\
			"$_scriptname" 1>&2
	;;
	$_error__dir_remove)
		$PRINTF "=== %s: Error removing directory.\\n"\
			"$_scriptname" 1>&2
	;;
	$_error__dir_not_found)
		$PRINTF "=== %s: Directory not found.\\n" "$_scriptname" 1>&2
	;;
	$_error__script_execution)
		$PRINTF "=== %s: Execution error.\\n" "$_scriptname" 1>&2
	;;
	$_error__binary_not_found)
		$PRINTF "=== %s: Binary not found.\\n" "$_scriptname" 1>&2
	;;
	$_error__usage)
		$PRINTF "=== %s: {start|stop}\\n" "$_scriptname" 1>&2
	;;
	$_ok)
	;;
	*)
		$PRINTF "=== %s: Unknown error\\n" "$_scriptname" 1>&2
	;;
esac
exit $_retmain
