cmake_minimum_required(VERSION 3.1...3.12)

if(${CMAKE_VERSION} VERSION_LESS 3.12)
  cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

project(use_message LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


if(NOT message_DIR)
    message(FATAL_ERROR "Required message_DIR from user")
endif()
find_package(message REQUIRED)

get_target_property(_loc message::message_shared LOCATION)
message(STATUS "Found message::message_shared at: \n      ${_loc}")

add_executable(main use_message.cpp)
target_link_libraries(main PRIVATE message::message_shared)

enable_testing()
add_test(NAME can_external_program_run
          COMMAND $<TARGET_FILE:main>
          WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})