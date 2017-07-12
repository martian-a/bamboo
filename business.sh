#!/bin/bash
# Email Management (Business)

PID=""

function get_pid {
	PID=`pgrep -f "imapfilter -c business.lua"`
}	

function stop {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (business) is not running."
	else
		echo -n "Stopping Imapfilter (business)..."
		kill -9 $PID
		sleep 1
		echo "... Done."
	fi	
}	

function start {
	get_pid
	if [ -z $PID ]; then
		echo "Starting Imapfilter (business)..."
		imapfilter -c business.lua -l business.errors.log >> business.latest.log
		get_pid		
		echo "Done. PID=$PID"
	else
		echo "Imapfilter (business) is already running, PID=$PID"
	fi
}

function status {
	get_pid
	if [ -z $PID ]; then
		echo "Imapfilter (business) is not running."
	else
		echo "Imapfilter (business) is running, PID=$PID"
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