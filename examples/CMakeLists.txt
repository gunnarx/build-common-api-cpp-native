cmake_minimum_required(VERSION 2.8)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -std=c++0x")

# Include symbols, just in case we need to debug a crash
set(CMAKE_BUILD_TYPE Debug)

include_directories(
    src-gen
    ../install/include
    ../install/include/CommonAPI-3.1
    ../install/include/CommonAPI-3.1/DBus
    ../install/include/CommonAPI-3.1/SomeIP
    ../install/include/dbus-1.0
    # A few header files seem to not be installed now - need to get them from the source directory.
    ../dbus-1.10.10
)

# CMake needs the policy set to avoid warning about
# how to handle a relative path for linking.
# Then we set link search path relative to the source
# dir (thus reaching the locally built libraries we created)
# - Gunnar
cmake_policy(SET CMP0015 NEW)
link_directories(
    ../install/lib
)

add_executable(HelloWorldClient
    src/HelloWorldClient.cpp
    src-gen/v1/commonapi/HelloWorldDBusProxy.cpp
    src-gen/v1/commonapi/HelloWorldDBusDeployment.cpp
)
target_link_libraries(HelloWorldClient CommonAPI CommonAPI-DBus dbus-1)

add_executable(HelloWorldService
    src/HelloWorldService.cpp
    src/HelloWorldStubImpl.cpp
    src-gen/v1/commonapi/HelloWorldDBusStubAdapter.cpp
    src-gen/v1/commonapi/HelloWorldStubDefault.cpp
    src-gen/v1/commonapi/HelloWorldDBusDeployment.cpp
)
target_link_libraries(HelloWorldService CommonAPI CommonAPI-DBus dbus-1)

#SOMEIP examples
add_executable(HelloWorldSomeIPClient
	src/HelloWorldClient.cpp
	src-gen/v1/commonapi/HelloWorldSomeIPProxy.cpp
	src-gen/v1/commonapi/HelloWorldSomeIPDeployment.cpp
)
target_link_libraries(HelloWorldSomeIPClient CommonAPI CommonAPI-SomeIP vsomeip)
add_executable(HelloWorldSomeIPService
	src/HelloWorldService.cpp
	src/HelloWorldStubImpl.cpp
	src-gen/v1/commonapi/HelloWorldSomeIPStubAdapter.cpp
	src-gen/v1/commonapi/HelloWorldStubDefault.cpp
	src-gen/v1/commonapi/HelloWorldSomeIPDeployment.cpp
)
target_link_libraries(HelloWorldSomeIPService CommonAPI CommonAPI-SomeIP vsomeip)

install(PROGRAMS build/HelloWorldService build/HelloWorldSomeIPService DESTINATION ../install/bin/)
