cmake_minimum_required(VERSION 2.8)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -std=c++0x")
 
include_directories(
    src-gen
    ../capicxx-core-runtime/include
    ../capicxx-dbus-runtime/include
    ../dbus-1.8.20
)

# CMake needs the policy set to avoid warning about
# how to handle a relative path for linking.
# Then we set link search path relative to the source
# dir (thus reaching the locally built libraries we created)
# - Gunnar
cmake_policy(SET CMP0015 NEW)
link_directories(
    ../capicxx-core-runtime/build
    ../capicxx-dbus-runtime/build
    ../dbus-1.8.20/dbus/.libs
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

