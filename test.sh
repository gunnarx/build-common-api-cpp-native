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
success() { echo Success ; stop_server ; exit 0 ;}

# Run server
$server &
server_pid=$!
echo server_pid=$server_pid

# Run client in background check for messages
exec 3< <($client 2>/dev/null)

# Give the process up to 3 seconds to succeed
for x in 1 2 3 ; do
   read -t 1 line <&3
   echo "$line"
   echo "$line" | egrep -q "Got message:.*Hello Bob" && success
done

# Timed out
echo "HelloWorldClient failed sending/receiving"
exit -1


