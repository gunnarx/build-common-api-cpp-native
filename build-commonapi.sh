#!/bin/bash -xe 

# This script is based on the detailed instructions from GENIVI public wiki
# written by Juergen Gehring.
# "CommonAPI C++ D-Bus in 10 minutes (from scratch)"
# https://at.projects.genivi.org/wiki/pages/viewpage.action?pageId=5472316
#
# (C) 2016,2018 Gunnar Andersson <gand@acm.org>
# Purpose: Download and native compilation of CommonAPI C++ DBus
#
# License: http://creativecommons.org/licenses/by-sa/4.0/
# ( since the material was taken from GENIVI Public Wiki:
#  "Except where otherwise noted, content on this site is licensed under a
#  Creative Commons Attribution-ShareAlike 4.0 International License" )

# For CI build we can't log every step
if [ "$QUIET" = "true" ] ; then
  set +x
else
  QUIET=false
fi

# According to web page:
# "Valid for CommonAPI 3.1.3 and vsomeip 1.3.0"

# SETTINGS

CORE_TOOLS_VERSION=3.1.12.4
DBUS_TOOLS_VERSION=3.1.12.2
SOMEIP_TOOLS_VERSION=3.1.12.2

CORE_RUNTIME_VERSION=3.1.12.6
DBUS_RUNTIME_VERSION=3.1.12.11
SOMEIP_RUNTIME_VERSION=3.1.12.17
VSOMEIP_VERSION=2.14.16
BOOST_DL_DIR_VERSION=1.65.0
BOOST_TAR_VERSION=1_65_0

ARCH=$(uname -m)

# Get absolute path to base dir
MYDIR=$(dirname "$0")
cd "$MYDIR"
BASEDIR="$PWD"

try() { $@ || fail "Command $* failed -- check above for details" ;}

# Either sudo must exist, or script must run as root
set +e
which sudo >/dev/null
if [ $? -ne 0 ] ; then
   if [ $(id -u) -ne 0 ] ; then
      fail "No sudo command exists in your system.  (You could install it (recommended) or run as root instead)"
   else
      # Running as root - define sudo as empty
      sudo=
   fi
else
   # sudo exists
   sudo=sudo
fi
set -e


fail() {
   set +x # Turn off command listing now, if it's on
   echo "FAILED!  Message follows:"
   echo $@
   echo "Halted, hit return to continue, or give up..."
   read x
}

git_clone() {
   # This is so we don't fail if directory already exists
   # but still, if a new clone is attempted and fails, then fail
   d="$(basename $1)" # repo/directory name
   d="${d%.git}"      # Strip off ".git" if it is there
   if [ -d $d ] ; then
      echo "Directory $d exists, no git clone attempted"
   else
      try git clone $1
   fi
}

check_expected() {
for f in $@ ; do
   [ -e $f ] || fail "Expected result file $f not present (not built)!"
done
}

check_os(){
    # From less specific to more specific.
    fgrep -qi fedora /etc/os-release && os=fedora
    fgrep -qi debian /etc/os-release && os=debian
    fgrep -qi ubuntu /etc/os-release && os=ubuntu
    fgrep -qi centos /etc/os-release && os=centos
    fgrep -qi apertis /etc/os-release && os=apertis
 
    if [[ $os =~ "ubuntu" || $os =~ "debian" || $os =~ "apertis" || $os =~ "centos" || $os =~ "redhat" || $os =~ "fedora" ]] ; then
      echo "OK, recognized distro as $os ..."
    else
      echo "***"
      echo "*** WARNING: Unsupported OS/distro.  This might fail later on."
      echo "***"
    fi
}

install_prerequisites() {
  check_os

  java -version || {
    echo "Java not installed?  (Could not check version)"
    echo "Please install a Java interpreter (JRE)"
    echo "This is not done by the script because it would need to force the java version and this may interfere with the system"
    echo "In addition, the java packages have different names"
    fail "No java JRE is installed"
  }

  # This is very rough, but just the bare minimum to support
  # different distros.  Might be buggy on some, try and see.
  dnf -v >/dev/null 2>&1 && dnf=true || dnf=false
  $dnf || yum -v >/dev/null 2>&1 && yum=true || yum=false
  apt-get -v >/dev/null 2>&1 && apt=true || apt=false

  if [ ! -f .installed_packages ] ; then
    $dnf && $sudo dnf install -y unzip java-1.8.0-openjdk openjdk git make jexpat-devel cmake gcc gcc-c++ automake autoconf wget pkg-config
    $yum && $sudo yum install -y unzip java-1.8.0-openjdk openjdk git make jexpat-devel cmake gcc gcc-c++ automake autoconf wget pkg-config
    $apt && $sudo apt-get update && apt-get install -y unzip openjdk-8-jre git make libexpat1-dev cmake gcc g++ automake autoconf wget pkg-config
  fi
  touch .installed_packages
}

apply_patch() {
  # Use forward to avoid questions if patch had been applied already (second run)
  # Answer proposed by Tom Hale, reference:
  # https://stackoverflow.com/questions/21928344/how-to-not-break-the-makefile-if-patch-skips-the-patch
  if patch -p1 --dry-run --reverse --force < "$1" >/dev/null 2>&1; then
    echo "Patch already applied - skipping."
  else # patch not yet applied
    echo "Patching..."
    patch -p1 -N < "$1" || echo "Patch failed" >&2 && return 1
  fi
}

echo Installing prerequisites
pause() {
  if [ -n "$PAUSE" ] ; then
    echo "paused -- hit return"
    read x
  fi
}

install_prerequisites

# All artifacts are installed locally within the project tree:
INSTALL_PREFIX="$BASEDIR/install"
mkdir -p "$INSTALL_PREFIX"

# Build Common API C++ Runtime
echo Building CommonAPI Core Runtime
cd "$BASEDIR" || fail
git_clone https://github.com/GENIVI/capicxx-core-runtime.git
cd capicxx-core-runtime/ || fail
git checkout $CORE_RUNTIME_VERSION || fail "capicxx-core: Failed git checkout of $CORE_RUNTIME_VERSION"
mkdir -p build
cd build/ || fail
try cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} ..
if $QUIET ; then
  try make -j$(nproc) >/dev/null
  try make install >/dev/null
else
  try make -j$(nproc)
  try make install
fi
check_expected libCommonAPI.so
check_expected "${INSTALL_PREFIX}/lib/libCommonAPI.so"

# Build Common API C++ DBus Runtime
echo Building D-Bus
# first patched D-Bus library...
cd "$BASEDIR" || fail
git_clone https://github.com/GENIVI/capicxx-dbus-runtime.git
try wget -c http://dbus.freedesktop.org/releases/dbus/dbus-1.10.10.tar.gz
try tar -xzf dbus-1.10.10.tar.gz
cd dbus-1.10.10/ || fail
set +e
apply_patch ../capicxx-dbus-runtime/src/dbus-patches/capi-dbus-add-send-with-reply-set-notify.patch
apply_patch ../capicxx-dbus-runtime/src/dbus-patches/capi-dbus-add-support-for-custom-marshalling.patch
apply_patch ../capicxx-dbus-runtime/src/dbus-patches/capi-dbus-correct-dbus-connection-block-pending-call.patch
set -e
if $QUIET ; then
  try ./configure --prefix=${INSTALL_PREFIX} --without-systemdsystemunitdir >/dev/null
  try make -j$(nproc) >/dev/null
  try make install >/dev/null
else
  try ./configure --prefix=${INSTALL_PREFIX} --without-systemdsystemunitdir
  try make -j$(nproc)
  try make install
fi

check_expected dbus/.libs/libdbus-1.so.3
check_expected "${INSTALL_PREFIX}/lib/libdbus-1.so.3"
check_expected "${INSTALL_PREFIX}/include/dbus-1.0"

# ... then Common API DBus Runtime
echo Building CommonAPI D-Bus Runtime
cd "$BASEDIR" || fail
cd capicxx-dbus-runtime/ || fail
git checkout $DBUS_RUNTIME_VERSION || fail "capicxx-dbus: Failed git checkout of $DBUS_RUNTIME_VERSION"
mkdir -p build
cd build || fail
export PKG_CONFIG_PATH="$BASEDIR/dbus-1.10.10"
try cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DUSE_INSTALLED_COMMONAPI=OFF -DUSE_INSTALLED_DBUS=OFF ..
if $QUIET ; then
  try make -j$(nproc) >/dev/null
  try make install >/dev/null
else
  try make -j$(nproc)
  try make install
fi
check_expected libCommonAPI-DBus.so
check_expected $BASEDIR/install/lib/libCommonAPI-DBus.so

# Build Boost
echo Building Boost
cd "$BASEDIR" || fail
try wget -c https://dl.bintray.com/boostorg/release/${BOOST_DL_DIR_VERSION}/source/boost_${BOOST_TAR_VERSION}.tar.gz
try tar -xzf boost_${BOOST_TAR_VERSION}.tar.gz
# OK, so it's now under boost_ and the version in the same way it is written in the *TAR* file
cd boost_${BOOST_TAR_VERSION} || fail "Expected boost to be in $BOOST_TAR_VERSION/ after unpacking!"
try ./bootstrap.sh
BOOST_ROOT=`realpath $PWD/../install`
mkdir -p $BOOST_ROOT
if $QUIET ; then
  try ./b2 -d+2 --prefix=$BOOST_ROOT link=shared threading=multi toolset=gcc -j$(nproc) install >/dev/null
else
  try ./b2 -d+2 --prefix=$BOOST_ROOT link=shared threading=multi toolset=gcc -j$(nproc) install
fi

# Build vsomeip
echo Building vsomeip
cd "$BASEDIR" || fail
VSOMEIP_LIBS=`realpath $PWD/install/lib`
VSOMEIP_INC=`realpath $PWD/install/include`
git_clone https://github.com/GENIVI/vsomeip.git
cd vsomeip
git checkout $VSOMEIP_VERSION || fail "vsomeip: Failed git checkout of $VSOMEIP_VERSION"
mkdir -p build
cd build || fail
try cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBOOST_ROOT=${BOOST_ROOT} -DENABLE_SIGNAL_HANDLING=1 ..
if $QUIET ; then
  try make -j$(nproc) >/dev/null
  try make install >/dev/null
else
  try make -j$(nproc)
  try make install
fi
check_expected $BASEDIR/install/lib/libvsomeip.so

# build SomeIP CommonAPI Runtime
echo CommonAPI SOME/IP Runtime
cd "$BASEDIR" || fail
git_clone https://github.com/GENIVI/capicxx-someip-runtime.git
cd capicxx-someip-runtime
git checkout $SOMEIP_RUNTIME_VERSION || fail "capicxx-dbus: Failed git checkout of $SOMEIP_RUNTIME_VERSION"
mkdir -p build
cd build || fail
try cmake -D BOOST_ROOT=${BOOST_ROOT} \
	  -D CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
	  -D CMAKE_PREFIX_PATH=${INSTALL_PREFIX}/lib/cmake/ \
	  -D CMAKE_MODULE_PATH=${INSTALL_PREFIX}/lib/cmake/ \
	  -D USE_INSTALLED_COMMONAPI=ON ..
if $QUIET ; then
  try make -j$(nproc) >/dev/null
  try make install >/dev/null
else
  try make -j$(nproc)
  try make install
fi
check_expected $BASEDIR/install/lib/libCommonAPI-SomeIP.so

# Create application
echo Prepare application
cd "$BASEDIR" || fail
mkdir project
cd project/ || fail
mkdir fidl
cp "$BASEDIR/examples/HelloWorld.fidl" fidl/
cp "$BASEDIR/examples/HelloWorld.fdepl" fidl/

# Ready! A service which instantiates the interface HelloWorld provides the
# function sayHello which can be called. The next step is to generate code.
# For that we need the code generators. We copy them into the new
# subdirectory cgen of our project directory:

# Get Code Generators
echo Downloading code generators
cd "$BASEDIR/project" || fail
mkdir -p cgen
cd cgen/ || fail

try wget -c https://github.com/GENIVI/capicxx-core-tools/releases/download/$CORE_TOOLS_VERSION/commonapi-generator.zip
try wget -c https://github.com/GENIVI/capicxx-dbus-tools/releases/download/$DBUS_TOOLS_VERSION/commonapi_dbus_generator.zip
try wget -c https://github.com/GENIVI/capicxx-someip-tools/releases/download/$SOMEIP_TOOLS_VERSION/commonapi_someip_generator.zip
try unzip -u commonapi-generator.zip -d commonapi-generator
try unzip -u commonapi_dbus_generator.zip -d commonapi_dbus_generator
try unzip -u commonapi_someip_generator.zip -d commonapi_someip_generator
try chmod +x ./commonapi-generator/commonapi-generator-linux-$ARCH
try chmod +x ./commonapi_dbus_generator/commonapi-dbus-generator-linux-$ARCH
try chmod +x ./commonapi_someip_generator/commonapi-someip-generator-linux-$ARCH

# Now you find the executables of the code generators in
# cgen/commonapi-generator and cgen/commonapi_dbus_generator, respectively.
# There are four versions (Linux, Windows and 64bit variants). Type uname
# -m if you don't know if you have a 32bit or 64bit version of Linux (you
# get i686 or x86_64). For the further description we assume that you have
# the 32bit version.
# Do not complain about details, such as that you have to call chmod or that
# the names contain sometimes underscores and sometimes hyphen. It will
# change in future versions.

#Finally you can generate code (CommonAPI code with the commonapi-generator and CommonAPI D-Bus code with the commonapi-dbus-generator):
#Generate Code
echo Generating code from examples
cd "$BASEDIR/project" || fail
check_expected "$BASEDIR/project/fidl/HelloWorld.fidl"
try ./cgen/commonapi-generator/commonapi-generator-linux-$ARCH -sk ./fidl/HelloWorld.fidl
try ./cgen/commonapi_dbus_generator/commonapi-dbus-generator-linux-$ARCH ./fidl/HelloWorld.fidl
try ./cgen/commonapi_someip_generator/commonapi-someip-generator-linux-$ARCH ./fidl/HelloWorld.fdepl

# Dirname for generated filesseems to have changed...
case $PATCHVERSION in
  3.1.3)
    versiondir=v1_0
    ;;
  3.1.5p2)
    versiondir=v1
    ;;
  *)
    # Assuming it won't change from now on...
    versiondir=v1
    ;;
esac

cd src-gen/$versiondir/commonapi || fail

echo Checking if code was generated
check_expected HelloWorldDBusDeployment.cpp HelloWorldDBusProxy.cpp\
      HelloWorldDBusStubAdapter.cpp HelloWorld.hpp HelloWorldProxy.hpp\
      HelloWorldStubDefault.hpp HelloWorldDBusDeployment.hpp\
      HelloWorldDBusProxy.hpp  HelloWorldDBusStubAdapter.hpp\
      HelloWorldProxyBase.hpp  HelloWorldStubDefault.cpp  HelloWorldStub.hpp
cd - || fail

#If everything worked, the generated code will be in the new directory src-gen. The option -sk generates a default implementation of your interface instance in the service.
#Step 5: Write the client and the service application
check_expected src-gen/

# Now we can start to write the Hello World application. Create new subdirectories src and build in the project directory and change to src.
# Create src and build directories
cd "$BASEDIR/project" || fail
mkdir src
mkdir build
check_expected build  cgen  fidl  src  src-gen


echo Organizing generated files

# Now we have to create 4 files: The client code (HelloWorldClient.cpp), one file for the main-function of the service (HelloWorldService.cpp) and 2 files (header and source) for the implementation of the generated skeleton for the stub (we call it HelloWorldStubImpl.hpp and HelloWorldStubImpl.cpp).

# Let's begin with the client. Create a new file HelloWorldClient.cpp with the editor of your choice and type:

try cp "$BASEDIR/examples/HelloWorldClient.cpp" src/

#At the beginning of each CommonAPI application it is necessary to get a pointer to the generic runtime object. The runtime is necessary to create proxies and stubs. A client application has to call functions of an instance of an interface in the service application. In order to be able to call these functions we must build a proxy for this interface in the client. The interface name is the template parameter of the buildProxy method; furthermore we build the proxy for a certain instance; the instance name is the second parameter in the buildProxy method. In principle there is the possibility to distinguish between instances in different so-call domains (first parameter), but we don't want to discuss this in depth at the moment and take always the domain "local".

#The proxy provides the API function isAvailable; if the we start the service first then isAvailable returns always true. It is also possible to register a callback which is called when the service becomes available; but we try to keep it here as simple as possible.

#Now we call the function sayHello which we have defined in our fidl-file. The function has one in-parameter (string) and one out-parameter (also string). Have a look into HelloWorldPorxy.hpp to get the information how exactly the function sayHello must be called. Here it is important to know that it is possible to call the synchronous variant of this function (what we do here) or to call the asynchronous variant (sayHelloAsync) which is slightly more complicated. One return value is the so-called CallStatus, which gives us the information if the call was successful or not. Again, to keep it simple we do not check the CallStatus and hope that everthing worked fine.

#We continue now to write the service. Create a new file HelloWorldService.cpp:
try cp "$BASEDIR/examples/HelloWorldService.cpp" src/

# The main function of the service is even simpler as the main function of
# the client because the implementation of the interface functions is in
# the stub implementation. Again we need the pointer to the runtime
# environment; then we instantiate our implementation of the stub and
# register this instance of the interface by calling registerService with
# an instance name. The service shall run forever and answer to function
# calls until it becomes killed; therefore we need the while loop at the
# end of the main function.

# At the end we need the stub implementation; we realize it by creating a
# stub-implementation class which is inherited from the stub-default
# implementation. The header file is:

try cp "$BASEDIR/examples/HelloWorldStubImpl.hpp" src/
try cp "$BASEDIR/examples/HelloWorldStubImpl.cpp" src/

# If the function sayHello is called it gets the name (which is supposed to
# be the name of the developer of this application) and returns it with an
# added "Hello" in front. The return parameter is not directly the string
# as it is defined in the fidl-file; it is a standard function object with
# the return parameters as in-parameters. The reason for this is to provide
# the possibility to answer not synchronously in the implementation of this
# function but to delegate the answer to a different thread.

# Step 6: Build and run

# Since you must have installed CMake in order to build the CommonAPI
# runtime libraries, the fastest way to compile and build our applications
# is to write a simple CMake file. Create a new file CMakeLists.txt
# directly in the project directory: CMakeLists.txt

try cp "$BASEDIR/examples/CMakeLists.txt" .

echo Compiling generated example code

# As include paths we need the include directories of CommonAPI and bindings and D-Bus; the directory of the generated code must be also added. We link everything together and do not discuss here questions concerning the configuration with different bindings. Therefore we tell CMake where to find the CommonAPI libraries and libdbus (replace the absolute paths with the paths on your machine). At the end we build two executables, one for the service and one for the client.
# Now call CMake (remember that we created the build directory before:
# Build everything
cd "$BASEDIR/project" || fail
cd build || fail
try cmake ..
try make -j$(nproc)

# Your output should look similiar. In the build direcory there should be two executables now: HelloWorldClient and HelloWorldService.
echo "For DBus HelloWorld"
echo "You may now run $PWD/HelloWorldService &"
echo "and $PWD/HelloWorldClient"
# ./HelloWorldService &
# ./HelloWorldClient
echo "For SomeIP HelloWorld, you may now run $PWD/HelloWorldSomeIPService &"
echo "and after that $PWD/HelloWorldSomeIPClient"
echo 'NOTE: Before that you may need to set the LD_LIBRARY_PATH variable to find the built libraries.'
echo 'For example:'
echo 'export LD_LIBRARY_PATH="$PWD/vsomeip/build:$LD_LIBRARY_PATH"'
echo '(Please check the paths - $PWD will expand correctly if you are standing in the project directory)'
echo 'Please refer to README.md for more information!!'

cd "$BASEDIR" || fail
echo "Checking a few results (were libraries compiled and installed?)"
test -f install/lib/libboost_log.so|| fail "Could not find libboost_log.so in install/lib?  Something probably went wrong"
test -f install/lib/libvsomeip.so  || fail "Could not find libvsomeip.so in install/lib?  Something probably went wrong"

