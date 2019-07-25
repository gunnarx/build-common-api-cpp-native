A bash script encoding of all the steps in:

"CommonAPI C++ **D-Bus** and **SOME/IP** and in 10 minutes (from scratch)"

The script is now building both D-Bus and SOME/IP versions in one go.  The
original individual instruction pages are linked above.  After running the
compilation script you can choose to run either one of the simple
client/server ping-pong test.

**NOTE** Java versions above 8 are not guaranteed to work with the code generators.
Read KNOWN BUGS section.

In order to "prove" a repeatable setup, the run_in_docker.sh script will run
everything in a repeatable docker container setup.  It uses Ubuntu 16.04 as the base
which causes OpenJDK 1.8.x (i.e. Java 8) to be installed by default.

I still recommend you go through the manual steps to learn how to do this
in general - that's the idea of the tutorial of course.  The purpose of
storing the FIDL example files in the repository and scripting the compilation
is mostly to prepare a simple automated test.

Historical links to the original instructions:

* [D-Bus](https://at.projects.genivi.org/wiki/pages/viewpage.action?pageId=5472316) -- replaced by [this](https://github.com/GENIVI/capicxx-dbus-tools/wiki/CommonAPI-C---D-Bus-in-10-minutes)
* [SomeIP](https://at.projects.genivi.org/wiki/pages/viewpage.action?pageId=5472320) -- replaced by [this](https://github.com/GENIVI/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes)

RUNNING EXAMPLES
-----------------

When you run the compiled HelloWorld examples, please note:

1. You might need to set the LD_LIBRARY_PATH variable to the location of the
   built libraries.  Primarily <project-dir>/vsomeip/build.  Do it by:
```
   $ export LD_LIBRARY_PATH="$PWD/vsomeip/build:$LD_LIBRARY_PATH"
```
($PWD will expand correctly assuming you are standing in the project directory)

or local environment for running the program only
```
   LD_LIBARY_PATH="..." ./HelloWorldSomeIPService
```

(and so on...)

2. If you run the docker build then the container exits after it is done
   building. You need to find it in the docker list, start it, and execute a
   shell to run them in the container. ALSO: READ THE BUGS SECTION! The
   project dir will be found directly under the root.  For example:

```
$ docker ps -a
$ docker start <ID>
$ docker exec -ti <ID> bash

   (in container)
# cd /build-common-api-cpp-native
```


KNOWN BUGS
----------

* Running the code generators with Java version above 8 either gives warning
or error (generation fails). No need to report that problem, check your java
version and/or try to fix the [upstream](https://github.com/GENIVI/capicxx-core-tools/).

* In the run_in_docker.sh version, everything compiles but the DBus HelloWorld
client program fails.  Possibly due to docker container running unprivileged(?)
or maybe the container lacks some D-Bus configuration.  I have not
investigated the reason - if you know, please report your findings.

