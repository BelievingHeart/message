# This module has some assumptions:
# 1. The API of your library can be find_package uinsg config mode
# 2. Your library have a 'tests' folder under PROJECT_SOURCE_DIR
# 3. Your 'tests' folder contain only one thing: a external project folder containing at leasting one cpp file and one CMakeLists.txt that utilizes the library just installed

function(library_tests_gen)
    set(options)
    set(oneValueArgs 
            LIBRARY_NAME 
            CMAKE_CONFIG_FILE_DIR 
            )
    set(multiValueArgs LIBRARY_EXECUTABLES)
    cmake_parse_arguments(MY "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

    set(MY_INPUT_FILE ${CMAKE_BINARY_DIR}/test_library_template.txt.in)
    set(MY_OUTPUT_FILE ${CMAKE_SOURCE_DIR}/tests/CMakeLists.txt)
    
  if(NOT EXISTS ${MY_OUTPUT_FILE})
       
    file(WRITE  ${MY_INPUT_FILE}
    "@test_exe_list@



    add_test(
        NAME use-target_configure
        COMMAND
        \${CMAKE_COMMAND} -H@MY_TEST_CPP_DIR@
                        -B@MY_TEMP_BINARY_DIR@
                        -G\${CMAKE_GENERATOR}
                        -D@MY_LIBRARY_NAME@_DIR=@MY_CMAKE_CONFIG_FILE_DIR@
                        -DCMAKE_BUILD_TYPE=\$<CONFIG>
        )
    
    
    set_tests_properties(use-target_configure
        PROPERTIES
        FIXTURES_SETUP use-target
        )
    
    add_test(
        NAME use-target_build
        COMMAND
        \${CMAKE_COMMAND} --build @MY_TEMP_BINARY_DIR@
                        --config \$<CONFIG>
        )
    set_tests_properties(use-target_build
        PROPERTIES
        FIXTURES_REQUIRED use-target
        )
    
    set(_test_target)
    if(MSVC)
        set(_test_target \"RUN_TESTS\")
    else()
        set(_test_target \"test\")
    endif()
    add_test(
        NAME use-target_test
        COMMAND
        \${CMAKE_COMMAND} --build @MY_TEMP_BINARY_DIR@
                        --target \${_test_target}
                        --config \$<CONFIG>
        )
    set_tests_properties(use-target_test
        PROPERTIES
        FIXTURES_REQUIRED use-target
        )
    unset(_test_target)
    
    add_test(
        NAME use-target_cleanup
        COMMAND
        \${CMAKE_COMMAND} -E remove_directory @MY_TEMP_BINARY_DIR@
        )
    set_tests_properties(use-target_cleanup
        PROPERTIES
        FIXTURES_CLEANUP use-target
        )
    "
    )

    if(NOT EXISTS ${CMAKE_SOURCE_DIR}/tests)
    message(FATAL_ERROR "A directory named 'tests' under PROJECT_SOURCE_DIR is required.")   
    endif()   

    file(GLOB _test_dir ${CMAKE_SOURCE_DIR}/tests/*)
    foreach(file_name_ ${_test_dir})
    if(NOT file_name_ MATCHES "CMakeLists.txt")
        set(MY_TEST_CPP_DIR ${file_name_})
    endif()
    endforeach()
    message(STATUS "Found TEST_CPP_DIR=${MY_TEST_CPP_DIR}")

    set(MY_TEMP_BINARY_DIR ${CMAKE_BINARY_DIR}/test_for_install)
    execute_process(COMMAND
                    ${CMAKE_COMMAND} -E make_directory ${MY_TEMP_BINARY_DIR}
    )

    if(NOT MY_TEST_CPP_DIR)
    message(FATAL_ERROR "A TEST_CPP_DIR under 'tests' is required")
    endif()   
    file(GLOB HAVE_CPP ${MY_TEST_CPP_DIR}/*.cpp)
    if(NOT EXISTS ${MY_TEST_CPP_DIR})
    message(FATAL_ERROR "${MY_TEST_CPP_DIR} not found")
    elseif(NOT EXISTS ${MY_TEST_CPP_DIR}/CMakeLists.txt)
    message(FATAL_ERROR "A 'CMakeLists.txt' is required to be inside ${MY_TEST_CPP_DIR}")
    elseif(NOT HAVE_CPP)
    message(FATAL_ERROR "A cpp file is required to be inside ${MY_TEST_CPP_DIR}")
    endif()

    set(exe_list "")
    set(index 0)
    foreach(exe ${MY_LIBRARY_EXECUTABLES})
    math(EXPR index "${index}+1")
    list(APPEND exe_list 
    "add_test(
        NAME test_exe_${index}
        COMMAND \"${exe}\"
        )
        "
    )
    endforeach()
    string(REPLACE ";" "\n" test_exe_list ${exe_list})

    configure_file(${MY_INPUT_FILE}
            ${MY_OUTPUT_FILE}
            @ONLY
            )

    # remove the generated template file
    file(REMOVE ${MY_INPUT_FILE})

  endif()
  
    
endfunction()
