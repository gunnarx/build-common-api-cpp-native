#!/bin/sh

# Support --rm flag optionally
rmflag=
[ "$1" = "--rm" ] && rmflag="--rm"

PROJ_URL="https://github.com/gunnarx/build-common-api-cpp-native"
DISTRO=ubuntu:16.04  # This has java version 8 by default
JAVA_PACKAGE=openjdk-8-jre

echo This will run the script in a controlled docker container environment

# If you wish to play around with the result the --rm (remove) flag
# should be avoided.
set -x
docker run $rmflag -i $DISTRO \
  bash -c "apt-get update ; apt-get install -y git $JAVA_PACKAGE ; git clone $PROJ_URL ; cd build-common-api-cpp-native ; ./build-commonapi.sh"

echo "---"
echo "Container has now exited.  To look at the results, find it among docker ps (not running), start it and then exec a shell in the container."
echo
