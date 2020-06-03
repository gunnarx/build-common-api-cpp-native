#!/bin/sh

# Support --rm flag optionally
rmflag=
[ "$1" = "--rm" ] && rmflag="--rm"

PROJ_URL="https://github.com/gunnarx/build-common-api-cpp-native"
BRANCH="vsomeip_2.14.16"
DISTRO=ubuntu:19.04  # This has java version 8 available (not default)
JAVA_PACKAGE=openjdk-8-jre

echo This will run the script in a controlled docker container environment

# If you wish to play around with the result the --rm (remove) flag
# should be avoided.
set -x
docker run $rmflag -i $DISTRO \
  bash -c "apt-get update ; apt-get install -y git $JAVA_PACKAGE ; git clone $PROJ_URL -b $BRANCH; cd build-common-api-cpp-native ; ./build-commonapi.sh ; echo SLEEPING... ; sleep 1000000"

echo "---"
echo "Container has now exited.  To look at the results, find it among docker ps (not running), start it and then exec a shell in the container."
echo
