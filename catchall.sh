#!/bin/bash
# Email Management (Catchall)

PID=""

function get_pid {
	PID=`pgrep -f "imapfilter -c catchall.lua"`
}	

function stop {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (catchall) is not running."
	else
		echo -n "Stopping Imapfilter (catchall)..."
		kill -9 $PID
		sleep 1
		echo "...Done."
	fi	
}	

function start {
	get_pid
	if [ -z $PID ]; then
		echo "Starting Imapfilter (catchall)..."
		imapfilter -c catchall.lua -l catchall.errors.log >> catchall.latest.log
		get_pid		
		echo "Done. PID=$PID"
	else
		echo "Imapfilter (catchall) is already running, PID=$PID"
	fi
}

function status {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (catchall) is not running."
	else
		echo "Imapfilter (catchall) is running, PID=$PID"
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