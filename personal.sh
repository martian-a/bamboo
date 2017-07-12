#!/bin/bash
# Email Management (Personal)

PID=""

function get_pid {
	PID=`pgrep -f "imapfilter -c personal.lua"`
}	

function stop {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (personal) is not running."
	else
		echo -n "Stopping Imapfilter (personal)..."
		kill -9 $PID
		sleep 1
		echo "... Done."
	fi	
}	

function start {
	get_pid
	if [ -z $PID ]; then
		echo "Starting Imapfilter (personal)..."
		imapfilter -c personal.lua -l personal.errors.log >> personal.latest.log 
		get_pid		
		echo "Done. PID=$PID"
	else
		echo "Imapfilter (personal) is already running, PID=$PID"
	fi
}

function status {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (personal) is not running."
	else
		echo "Imapfilter (personal) is running, PID=$PID"
	fi
}

case "$1" in
	start)
		start
	;;
	stop)
		stop
	;;
	status)
		status
	;;
	*)
	echo "Usage: $0 {start|stop|status}"
esac