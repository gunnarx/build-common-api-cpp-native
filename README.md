Build CommonAPI (script)
========================

A bash script to automate building of Common API libraries.

[![Build Status](https://travis-ci.org/gunnarx/build-common-api-cpp-native.svg?branch=master)](https://travis-ci.org/gunnarx/build-common-api-cpp-native)

Originally this encoded the steps from two similar tutorials named:

"CommonAPI C++ **D-Bus** and **SOME/IP** and in 10 minutes (from scratch)"

You can find the tutorials on the [associated wiki](https://github.com/GENIVI/capicxx-core-tools/wiki)

The User Guide also provides similar and deeper information.
Please follow the links to that guide from the [main
documentation](https://genivi.github.io/capicxx-core-tools/)

The script includes D-Bus and SOME/IP versions of CommonAPI C++. After running the
compilation script you can choose to run either one of the simple
client/server ping-pong test.

**NOTE** Java versions above 8 are not guaranteed to work with the code generators.
Read KNOWN BUGS section.

Supported distros and container build
-------------------------------------

There is no significant testing on distros - you have to try for yourself.
It was developed originally on Fedora 29.

But to have a guaranteed repeatable setup, the run_in_docker.sh script runs
everything in a repeatable container setup using Docker.  It uses Ubuntu 18.04
as the base but explicitly requests OpenJDK 1.8.x (i.e. Java 8) instead of
what 18.04 otherwise uses by default.  This is because recent Java versions
seem unsupported by the current code generators and will fail with the message
about "An illegal reflective operation".

The Travis build test does not invoke our docker script and runs the build
script directly in whatever the environment is that Travis uses.  
The travis file specifies "xenial" setup, which should be Ubuntu 16.04.
I think 16.04 normally installs openjdk8 by default, but this is also
specified in the Travis file.

Usage
-----

I still recommend you go through the manual steps to learn how to do this
in general - that's the idea of the tutorial of course.  My purpose of
storing the FIDL example files in the repository and scripting all of this is

1. To prepare a simple automated test, repeatable, to quickly review
upgrades of these components.

2. To have a repeatable setup to use in other projects that develop using
CommonAPI C++ and vSomeIP.  This project can be used to set up the environment
that is then used by the other development project. (Not for final product
development really, but during the exploration/development of other individual
software parts using these technologies)

Historical links to the original instructions:

* [D-Bus](https://at.projects.genivi.org/wiki/pages/viewpage.action?pageId=5472316) -- replaced by [this](https://github.com/GENIVI/capicxx-dbus-tools/wiki/CommonAPI-C---D-Bus-in-10-minutes)
* [SomeIP](https://at.projects.genivi.org/wiki/pages/viewpage.action?pageId=5472320) -- replaced by [this](https://github.com/GENIVI/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes)

What this does in detail
------------------------

Everything is in one big script...  
Of course many other ways could be done to break this apart, use proper 
build/make tools, avoid rebuilding what has been done successfully and so on.
This is not intended for production use, in which all of those things would
be set up in the actual build system being used.

This is just a crude way to test all of these parts (with continuous
build/test in .travis) and get a repeatable setup:

The script does all of this:

1. Downloads and _compiles from source_:
- BOOST (vSomeIP dependency)
- vSomeIP
- D-Bus, libdbus (including applying some necessary patches)
- Common API Runtimes for Core, D-Bus, and SomeIP

2. Installs all results in a _local directory_!  This test environment tries hard to not
   affect your system installation at all if run natively (but using the
   container version is recommended in any case).

3. Downloads _binaries_ for the CommonAPI C++ code generators from the official releases.  Using the releases is recommended for these technologies.  (Of course a project for repeatable builds of the code generators could be useful too, but it is not in scope here)

_Each built/downloaded program is a fixed version, editable in the script itself when updates are needed.  Please refer to the top of the build-commonapi.sh script for the versions._

4. Provides a trivial HelloWorld client/server example for Franca IDL and simple "main.cpp" test-executables for each.

5. Generate CommonAPI binding code for the HelloWorld example with the included code generator versions (D-Bus and SomeIP).  _Note: CommonAPI-for-WAMP also exists but is not yet included here._

6. Compile the HelloWorld example code into test executables, by means of a provided simple cmake file, CMakeLists.txt

7. Run the tests.  (Notably, D-Bus is likely to fail -- see bugs section)


RUNNING EXAMPLES
-----------------

When you run the compiled HelloWorld examples, please note:

1. You might need to set the LD_LIBRARY_PATH variable to the location of the
   built libraries.  E.g. <project-dir>/install/lib Do it by:
```
   $ export LD_LIBRARY_PATH="$PWD/install/lib:$LD_LIBRARY_PATH"
```
($PWD will expand correctly assuming you are standing in the project directory)

or local environment for running the program only
```
   LD_LIBARY_PATH="..." ./HelloWorldSomeIPService
```

(and so on...)

2. If you run the docker build then the container exits after it is done
   building. You may want to find it in the docker list, start it, and execute
   a shell (or run tests directly) in the container. ALSO: READ THE BUGS
   SECTION! The project dir is at /workdir.

   The container is named on creation, so we can use this:  buildcapicxx

```
$ docker ps -a
$ docker start buildcapicxx
$ docker exec -ti buildcapcixx bash

   (in container)
# cd /workdir
```


KNOWN BUGS
----------

* Running the code generators with Java version above 8 either gives warning
or even error! No need to report that problem, check your java version and/or
try to fix the [upstream](https://github.com/GENIVI/capicxx-core-tools/).

* D-Bus test fails!   In the run_in_docker.sh version, everything compiles but
the DBus HelloWorld client program fails.  This could possibly be due to
docker container running unprivileged(?) or maybe the container lacks some
D-Bus configuration, or possibly the correct (patched) library is not being
picked up and instead the system-installed one.  I have little interest in the
D-Bus binding at the moment, and more in SOME/IP so if someone wants to
investigate the reason and fix or report, please do so!

TODO
----

Please refer to GitHub Tickets.

