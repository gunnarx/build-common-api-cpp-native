#!/bin/sh

DISTRO=ubuntu:16.04  # This has java version 8 by default
JAVA_PACKAGE=openjdk-8-jre

echo This will run the script in a controlled docker container environment

# If you wish to play around with the result the --rm (remove) flag
# should be avoided.
set -x
docker run --rm -i $DISTRO \
  bash -c "apt-get update ; apt-get install -y git $JAVA_PACKAGE ; git clone https://github.com//gunnarx/build-common-api-cpp-native ; cd build-common-api-cpp-native ; ./build-commonapi.sh"

