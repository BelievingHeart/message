find_package(PkgConfig QUIET REQUIRED)
pkg_search_module(UUID uuid IMPORTED_TARGET)
if(TARGET PkgConfig::UUID)
    message(STATUS "Found libuuid!")
    set(HAVE_UUID TRUE)
else()
    message(STATUS "libuuid not found, uuid support will be remove from message library")
endif()

# shared library                         
add_library(message_shared SHARED)

# Solve symbol visibility issues
include(GenerateExportHeader)
generate_export_header( message_shared
                        EXPORT_FILE_NAME "${CMAKE_BINARY_DIR}/${INSTALL_INCLUDEDIR}/messageExport.h"
                        EXPORT_MACRO_NAME "message_EXPORT"
                        STATIC_DEFINE "message_STATIC"
                        )

target_sources(message_shared
    PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/Message.cpp
)
target_include_directories(message_shared
                            PUBLIC
                                $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/${INSTALL_INCLUDEDIR}>
                                $<INSTALL_INTERFACE:${INSTALL_INCLUDEDIR}>
                            )       
target_compile_definitions(message_shared 
                                PRIVATE $<$<BOOL:${HAVE_UUID}>:HAVE_UUID>
                                INTERFACE $<INSTALL_INTERFACE:USING_MESSAGE>
                                )             
                                
set_target_properties(message_shared
                        PROPERTIES 
                            POSITION_INDEPENDENT_CODE TRUE
                            CXX_VISIBILITY_PRESET "hidden"
                            VISIBILITY_INLINES_HIDDEN TRUE
                            LIBRARY_OUTPUT_NAME "message"
                            DEBUG_POSTFIX "_d"
                            SOVERSION ${PROJECT_VERSION}
                            PUBLIC_HEADER "Message.hpp;${CMAKE_BINARY_DIR}/${INSTALL_INCLUDEDIR}/messageExport.h"
                            )                                
target_link_libraries(message_shared PRIVATE $<$<BOOL:${HAVE_UUID}>:PkgConfig::UUID>)


 # STAIC library                         
add_library(message_static STATIC)

target_sources(message_static
    PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/Message.cpp
)
target_include_directories(message_static
                            PUBLIC
                                $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/${INSTALL_INCLUDEDIR}>
                                $<INSTALL_INTERFACE:${INSTALL_INCLUDEDIR}>
                            )       
target_compile_definitions(message_static 
                                PRIVATE $<$<BOOL:${HAVE_UUID}>:HAVE_UUID>
                                PRIVATE "message_STATIC"
                                INTERFACE $<INSTALL_INTERFACE:USING_MESSAGE>
                                )             
                                
set_target_properties(message_static
                        PROPERTIES 
                            POSITION_INDEPENDENT_CODE TRUE
                            ARCHIVE_OUTPUT_NAME "message"
                            DEBUG_POSTFIX "_d"
                            SOVERSION ${PROJECT_VERSION}
                            PUBLIC_HEADER "Message.hpp;${CMAKE_BINARY_DIR}/${INSTALL_INCLUDEDIR}/messageExport.h"
                            )                                
target_link_libraries(message_static PRIVATE $<$<BOOL:${HAVE_UUID}>:PkgConfig::UUID>)

# set rpath
file(RELATIVE_PATH _rel ${CMAKE_INSTALL_PREFIX}/${INSTALL_BINDIR} ${CMAKE_INSTALL_PREFIX}/${INSTALL_LIBDIR})
if(APPLE)
  set(_rpath "@loader_path/${_rel}")
else()
  set(_rpath "\$ORIGIN/${_rel}")
endif()

# two respective executables
add_executable(exe_shared hello-world.cpp)
target_link_libraries(exe_shared PRIVATE message_shared)
set_target_properties(exe_shared 
                        PROPERTIES
                            BUILD_WITH_INSTALL_RPATH OFF
                            INSTALL_RPATH ${_rpath}
                            INSTALL_RPATH_USE_LINK_PATH ON
                        )

add_executable(exe_static hello-world.cpp)
target_link_libraries(exe_static PRIVATE message_static)
set_target_properties(exe_static 
                        PROPERTIES
                            BUILD_WITH_INSTALL_RPATH OFF
                            INSTALL_RPATH ${_rpath}
                            INSTALL_RPATH_USE_LINK_PATH ON
                        )


# install library targets                       
install(TARGETS 
            message_shared message_static exe_shared exe_static
        EXPORT 
            message_target
        ARCHIVE
            DESTINATION ${INSTALL_LIBDIR} 
            COMPONENT dev 
        LIBRARY
            DESTINATION ${INSTALL_LIBDIR}
            COMPONENT dev 
        RUNTIME
            DESTINATION ${INSTALL_LIBDIR}
            COMPONENT bin 
        PUBLIC_HEADER                        
            DESTINATION ${INSTALL_INCLUDEDIR}/message #NOTE: message is required 
            COMPONENT dev
            )

# install library as a whole
install(EXPORT "message_target"
            DESTINATION ${INSTALL_CMAKEDIR}
            NAMESPACE "message::"
            )

include(CMakePackageConfigHelpers)
write_basic_package_version_file("${CMAKE_CURRENT_BINARY_DIR}/messageConfigVersion.cmake"
                                VERSION ${PROJECT_VERSION}
                                COMPATIBILITY SameMajorVersion
                                )

configure_package_config_file("${CMAKE_SOURCE_DIR}/cmake/messageConfig.cmake.in"
                                "${CMAKE_CURRENT_BINARY_DIR}/messageConfig.cmake"
                                INSTALL_DESTINATION ${INSTALL_CMAKEDIR}
                                )

install(FILES 
            "${CMAKE_CURRENT_BINARY_DIR}/messageConfigVersion.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/messageConfig.cmake"
        DESTINATION
            ${INSTALL_CMAKEDIR}
            )

