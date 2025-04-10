cmake_minimum_required(VERSION 3.6)
project(khbr_userapp)

add_definitions(-D_UNICODE)
add_definitions(-DUNICODE)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MTd")

if(GOOGLE_UNIT_TEST)
    include(FetchContent)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/03597a01ee50ed33e9dfd640b249b4be3799d395.zip
    )
    # For Windows: Prevent overriding the parent project's compiler/linker settings
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
    enable_testing()
endif()

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

file(GLOB_RECURSE _khbr_userapp_src
    LIST_DIRECTORIES false
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/unit_tests/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/unit_tests/*.h
)


if(UNIX)
else()
    foreach(_source IN ITEMS ${_khbr_userapp_src})
        get_filename_component(_source_path "${_source}" PATH)
        # form proper filter name from the path to source file:
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" _group_path "${_source_path}")
        string(REPLACE "/" "\\" _group_path "${_group_path}")
        string(REPLACE "..\\" "" _group_path "${_group_path}")
 
        source_group("${_group_path}" FILES "${_source}")
    endforeach()

    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT khbr_userapp)
endif()

add_executable(
   khbr_userapp
   ${_khbr_userapp_src}
)

if(GOOGLE_UNIT_TEST)
    target_link_libraries(
      khbr_userapp
      GTest::gtest_main
    )

    include(GoogleTest)
    gtest_discover_tests(khbr_userapp)
endif()
