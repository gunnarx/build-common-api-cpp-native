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

cd "$MYDIR/project/build"
client="./HelloWorldSomeIPClient"
server="./HelloWorldSomeIPService"

[ -x "$client" ] || { echo "$0 : Executable not found ($client)" ; exit 1 ; }
[ -x "$server" ] || { echo "$0 : Executable not found ($server)" ; exit 1 ; }

stop_server() { kill $server_pid ;}
success() { echo Success ; stop_server ; exit 0 ;}

export LD_LIBRARY_PATH="$MYDIR/install/lib:$LD_LIBRARY_PATH"

# Run server
exec 4<> <($server 2>&1) && server_pid=$! &&  echo "Testscript: Started server with PID=$server_pid"

# Run client in background check for messages
exec 3<> <($client 2>&1) && client_pid=$! && echo "Testscript: Started client with PID=$client_pid"

# Give the process a maximum time to succeed
end=$((SECONDS+5))
while [ $SECONDS -lt $end ] ; do
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


