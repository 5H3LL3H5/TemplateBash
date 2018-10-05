#!/usr/bin/env bash
#
# Copyright (C) 2018 Christian Stenzel <christianstenzel@linux.com>
#
# This code is released under WTFPL Version 2
# (httpCOLON//wwwDOTwtfplDOTnet/)


# our fabulous main function				    	MAIN()
######################################################################
main()
{
	local -r tobehashed="0123456789"		# used payload

	echo "TEST0 --- PARAMETER PASSING"
	crc32 "$tobehashed" "$tobehashed"		#   call crc32

	echo "TEST1 --- PIPING PAYLOAD"
	echo "$tobehashed" "$tobehashed" | crc32	#   call crc32

	echo "TEST2 --- USE OF PROCESS SUBSTITUTION"
	crc32 <(echo -n "$tobehashed" "$tobehashed")	#   call crc32
	
	return 0	      # indicating exit success by returning 0
}

# function						        CRC32()
#
# computes crc32 hash for all passed space separated args
# input read from unnamed pipe (by stdin) and 
# named pipes (by process substitution)
#######################################################################
crc32()
{
	local -a in			        # declare as local arr
	
	if (( "$#" == 0 ));			#           no args ->
	then
		in=("$(</dev/stdin)")		#      read from stdin
	else
		if [[ -p $1 ]];			#           named pipe
		then
			in=("$(<"$1")"); 	# process substitution 
		else
			in=("$@")		#    parameter passing
		fi
	fi
	
	declare -p in				#            verify in
	
	# "compute crc32" by use of gzip 
	for par in ${in[@]}; do			#    ! no doble qouting
		echo -n "$par" | gzip -c | tail -c8 | od -t x4 -N 4 -;
	done
}

#								   BODY
#######################################################################

# declare functions
declare -F crc32
declare -F main

# pass whole parameter list to main
if main "$@"; then
	echo "TESTS SUCCESSFUL FINISHED"
else
	echo "ERROR RUNNING TESTS"
fi
#							     THE END :)
#######################################################################
