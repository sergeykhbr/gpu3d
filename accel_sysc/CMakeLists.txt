cmake_minimum_required(VERSION 3.10)
project(accel LANGUAGES CXX)

set (CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
if (MSVC)
    add_compile_options(/vmg)
endif()

# Set paths
set(SYSTEMC_SOURCE_DIR ${CMAKE_SOURCE_DIR}/systemc)
set(SYSTEMC_BINARY_DIR ${CMAKE_BINARY_DIR}/systemc-build)
set(SYSTEMC_INSTALL_DIR ${CMAKE_BINARY_DIR}/systemc-install)
add_definitions(-DCMAKE_BINARY_DIR="${CMAKE_BINARY_DIR}")
add_definitions(-DCMAKE_CURRENT_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

# Build SystemC using CMake
include(ExternalProject)

ExternalProject_Add(SystemC
    SOURCE_DIR ${SYSTEMC_SOURCE_DIR}
    BINARY_DIR ${SYSTEMC_BINARY_DIR}
    INSTALL_DIR ${SYSTEMC_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${SYSTEMC_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_CXX_STANDARD=17
    BUILD_ALWAYS OFF
)

# === Define imported target AFTER build ===
add_library(SystemC::systemc STATIC IMPORTED GLOBAL)

if (MSVC)
    set(SYSTEMC_LIB ${SYSTEMC_INSTALL_DIR}/lib/systemc.lib)
else()
    set(SYSTEMC_LIB ${SYSTEMC_INSTALL_DIR}/lib/libsystemc.a)
endif()

set_target_properties(SystemC::systemc PROPERTIES
    IMPORTED_LOCATION "${SYSTEMC_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${SYSTEMC_INSTALL_DIR}/include"
)

# Ensure your app waits for SystemC to build
add_dependencies(SystemC::systemc SystemC)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/prj/common
    ${CMAKE_CURRENT_SOURCE_DIR}/app
)

file(GLOB_RECURSE _accel_src
    LIST_DIRECTORIES false
    ${CMAKE_CURRENT_SOURCE_DIR}/rtl/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/rtl/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/prj/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/prj/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/app/*.cpp
    )

if(UNIX)
else()
    foreach(_source IN ITEMS ${_accel_src})
        get_filename_component(_source_path "${_source}" PATH)
        # form proper filter name from the path to source file:
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" _group_path "${_source_path}")
        string(REPLACE "/" "\\" _group_path "${_group_path}")
        string(REPLACE "..\\" "" _group_path "${_group_path}")
 
        source_group("${_group_path}" FILES "${_source}")
    endforeach()
endif()


set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT accel)

add_executable(accel
               ${_accel_src}
              )

target_link_libraries(accel PRIVATE SystemC::systemc)

