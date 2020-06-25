#!/bin/bash
# ------------------------------------------------------------------------
# Common-API test script
# (C) 2016 Gunnar Andersson
# License: CC-BY-SA-4.0 or MPLv2 or GPLv2 or GPLv3 (your choice)
# ------------------------------------------------------------------------

# A very rudimentary automated test - run the generated and compiled hello
# world binaries and see that they are communicating. Return the standard
# result codes:
# 0 = success,
# non-zero = failure
#
# (First you must have run build-commonapi.sh successfully)
# ------------------------------------------------------------------------

# Get a fixed point in the directories (this script's directory)
D=$(dirname "$0")
cd "$D"
MYDIR="$PWD"

client="$MYDIR/project/build/HelloWorldClient"
server="$MYDIR/project/build/HelloWorldService"

[ -x "$client" ] || { echo "$0 : Executable not found ($client)" ; exit 1 ; }
[ -x "$server" ] || { echo "$0 : Executable not found ($server)" ; exit 1 ; }

stop_server() { kill $server_pid ;}
success() { echo TEST OK. ; stop_server ; exit 0 ;}

export LD_LIBRARY_PATH="$MYDIR/install/lib:$LD_LIBRARY_PATH"

# Run server
exec 4<> <($server)
server_pid=$!
echo "Testscript: Started server with PID=$server_pid"

# Run client in background check for messages
exec 3<> <($client 2>&1) && echo "Testscript: Started client with PID=$!"

# Give the process some time to succeed
for x in 1 2 3 4 5 6 ; do
   read -t 1 serveroutput <&4 
   [ -n "$serveroutput" ] && echo "Server: $serveroutput"
   echo "Testscript: Waiting to read, 1s"
   read -t 1 line <&3
   [ -n "$line" ] && echo "Client: $line"
   echo "$line" | egrep -q "Got message:.*Hello Bob" && success
done

# Timed out
echo "TestScript:  FAILED.  It seems client failed sending/receiving"
stop_server
exit 1


