#!/bin/sh

if [ $# -lt 2 ] ; then
   echo "usage: $0 <executable> <src-files...>"
   exit 1
fi

# Normalize dir
SCRIPTDIR="$(readlink -f "$(dirname "$0")")"
BASEDIR="$SCRIPTDIR"

# preamble
cat <<EOT

cmake_minimum_required(VERSION 2.8)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -std=c++0x")

# Include symbols, just in case we need to debug a crash
set(CMAKE_BUILD_TYPE Debug)

include_directories(
   src-gen
   "$BASEDIR/install/include"
   "$BASEDIR/install/include/CommonAPI-3.1"
   "$BASEDIR/install/include/CommonAPI-3.1/DBus"
   "$BASEDIR/install/include/CommonAPI-3.1/SomeIP"
   "$BASEDIR/install/include/dbus-1.0"
   # A few header files seem to not be installed now - need to get them from the source directory.
   "$BASEDIR/dbus-1.10.10"
)

# CMake needs the policy set to avoid warning about
# how to handle a relative path for linking.
# Then we set link search path relative to the source
# dir (thus reaching the locally built libraries we created)
# - Gunnar
cmake_policy(SET CMP0015 NEW)

link_directories(
    "$BASEDIR/install/lib"
)

EOT

executable="$1"
shift

echo -n "add_executable($executable "
for f in "$@" ; do
   echo "$f"
done
echo ")"

echo "target_link_libraries($executable CommonAPI CommonAPI-SomeIP vsomeip)"

