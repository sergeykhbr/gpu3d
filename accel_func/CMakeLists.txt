# sergeykhbr@gmail.com
#
cmake_minimum_required(VERSION 3.16)

project(gpufunc VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
list(APPEND CMAKE_PREFIX_PATH $ENV{QT_PATH})

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
qt_standard_project_setup()

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src/include
)

file(GLOB_RECURSE _gpufunc_src
    LIST_DIRECTORIES false
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h
)

qt_add_executable(gpufunc
    ${_gpufunc_src}
)

file(GLOB_RECURSE _gpufunc_resources
    LIST_DIRECTORIES false
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "images/*.png"
)

qt_add_resources(gpufunc imageresources
    PREFIX "/"
    FILES ${_gpufunc_resources}
)


target_link_libraries(gpufunc PRIVATE Qt::Widgets)

set_target_properties(gpufunc PROPERTIES
    WIN32_EXECUTABLE OFF
)

set_target_properties(gpufunc PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_INSTALL_BINDIR}")
set_target_properties(gpufunc PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_INSTALL_BINDIR}")
set_target_properties(gpufunc PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_INSTALL_BINDIR}")


if(UNIX)
else()
    foreach(_source IN ITEMS ${_gpufunc_src})
        get_filename_component(_source_path "${_source}" PATH)
        # form proper filter name from the path to source file:
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" _group_path "${_source_path}")
        string(REPLACE "/" "\\" _group_path "${_group_path}")
        string(REPLACE "..\\" "" _group_path "${_group_path}")
 
        source_group("${_group_path}" FILES "${_source}")
    endforeach()

    add_custom_command(TARGET gpufunc
	        POST_BUILD
	        COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/qtdeploy.bat "${WINDEPLOYQT_EXECUTABLE}" "\"$(OutDir)$(TargetName)$(TargetExt)\""
	        )
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT gpufunc)
endif()
