FROM ubuntu:18.04

RUN apt-get update ; apt-get install -y git openjdk-8-jre

RUN git clone -b docker https://github.com/gunnarx/build-common-api-cpp-native /workdir

# This is done in one single step to minimize the size of the resulting
# layer.  We want to remove all intermediate files before the layer is
# committed
RUN /workdir/build-commonapi.sh && /workdir/remove_source_code.sh || echo "FAIL CONTAINER BUILD!"

