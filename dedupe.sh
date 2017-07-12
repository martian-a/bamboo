#!/bin/bash
# Email Management (De-duping)

PID=""

function get_pid {
	PID=`pgrep -f "imapfilter -c dedupe.lua"`
}	

function stop {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (dedupe) is not running."
	else
		echo -n "Stopping Imapfilter (dedupe)..."
		kill -9 $PID
		sleep 1
		echo "...Done."
	fi	
}	

function start {
	get_pid
	if [ -z $PID ]; then
		echo "Starting Imapfilter (dedupe)..."
		imapfilter -c dedupe.lua -l dedupe.errors.log &
		get_pid		
		echo "Done. PID=$PID"
	else
		echo "Imapfilter (dedupe) is already running, PID=$PID"
	fi
}

function status {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (dedupe) is not running."
	else
		echo "Imapfilter (dedupe) is running, PID=$PID"
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