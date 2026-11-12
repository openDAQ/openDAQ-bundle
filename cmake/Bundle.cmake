##
## The bundle's layers, each a prebuilt staging or its sources.
##
## A staging given as a prefix, BUNDLE_PREFIX_<STAGING> (the name upper-cased), is taken prebuilt: its files are
## installed under its install components, and the core's CMake package is found in it, so a module built here
## builds against it. Else its layer comes from its sources by FetchContent, at the revision bundle.json names
## (BUNDLE_REVISION_<LAYER> in place of one): every layer is fetched first, then each one's
## external/boost/Boost.cmake is included — Boost is built once, by the core, with what every layer needs — and
## then each is added, in the order declared.
##
## A staging's install components are kept for Packing.cmake: BUNDLE_COMPONENTS_<c>, and BUNDLE_PREBUILT_<c> when
## it is prebuilt, <c> the staging's name made a C identifier.
##
##   bundle_declare(<layer> STAGING <staging> [PACKAGE <name>])
##   bundle_make_available()
##

include_guard(GLOBAL)

include(FetchContent)

set(_BUNDLE_RUNTIME_PATTERNS "*.so" "*.so.*" "*.dylib" "*.dll")

# bundle_declare(<layer> STAGING <staging> [PACKAGE <name>])
#   A layer, named as its repository, and its staging; PACKAGE: the CMake package the staging installs (the core's)
function(bundle_declare LAYER)
    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "STAGING;PACKAGE" "")
    if (NOT _arg_STAGING IN_LIST BUNDLE_STAGINGS)
        return()
    endif()
    string(TOUPPER "${LAYER}" _layer)
    string(TOUPPER "${_arg_STAGING}" _staging)
    set(BUNDLE_PREFIX_${_staging} "" CACHE PATH "The prebuilt staging ${_arg_STAGING}; empty: built from ${LAYER}'s sources")

    set_property(GLOBAL APPEND PROPERTY BUNDLE_LAYERS "${LAYER}")
    set_property(GLOBAL PROPERTY BUNDLE_STAGING_${LAYER} "${_arg_STAGING}")
    set_property(GLOBAL PROPERTY BUNDLE_PACKAGE_${LAYER} "${_arg_PACKAGE}")
    if (NOT BUNDLE_PREFIX_${_staging})
        # download only: a SOURCE_SUBDIR that does not exist, so MakeAvailable adds nothing yet
        FetchContent_Declare(
            ${LAYER}
            GIT_REPOSITORY https://github.com/openDAQ/${LAYER}.git
            GIT_TAG        ${BUNDLE_REVISION_${_layer}}
            GIT_PROGRESS   ON
            SOURCE_SUBDIR  _not_added_by_fetchcontent_
        )
    endif()
endfunction()

# __bundle_module_stem(<file name> <out>)
#   A module's name from its file: libref_fb_module-64-3.module.so → ref_fb_module
function(__bundle_module_stem FILE OUT)
    string(REGEX REPLACE "^lib" "" _stem "${FILE}")
    string(REGEX REPLACE "(-[0-9]+-[0-9]+)?\\.module\\..*$" "" _stem "${_stem}")
    set(${OUT} "${_stem}" PARENT_SCOPE)
endfunction()

# __bundle_prebuilt(<staging> <prefix>)
#   The prefix's files under the staging's install components: a module (a *.module.* file in lib/modules or
#   bin/modules) under one of its own, <module>_Runtime, so an installer can offer it apart (no staging in the name:
#   NSIS makes variables of component names, 60 characters at most); other shared libraries under <c>_Runtime; the
#   rest — headers, CMake configs, static and import libraries — under <c>_Development. File by file, so no empty
#   directory lands in a component.
function(__bundle_prebuilt STAGING PREFIX)
    string(MAKE_C_IDENTIFIER "${STAGING}" _c)
    file(GLOB_RECURSE _files LIST_DIRECTORIES false RELATIVE "${PREFIX}" "${PREFIX}/*")
    set(_places)
    foreach(_f IN LISTS _files)
        get_filename_component(_n "${_f}" NAME)
        get_filename_component(_d "${_f}" DIRECTORY)
        set(_component ${_c}_Development)
        foreach(_p IN LISTS _BUNDLE_RUNTIME_PATTERNS)
            string(REPLACE "." "\\." _rx "${_p}")
            string(REPLACE "*" ".*" _rx "${_rx}")
            if (_n MATCHES "^${_rx}$")
                set(_component ${_c}_Runtime)
            endif()
        endforeach()
        if (_d MATCHES "^(lib|bin)/modules$" AND _n MATCHES "\\.module\\.")    # not an import library beside it
            __bundle_module_stem("${_n}" _stem)
            set(_component ${_stem}_Runtime)
        endif()
        string(MAKE_C_IDENTIFIER "${_component}_${_d}" _key)
        list(APPEND _files_${_key} "${PREFIX}/${_f}")
        list(APPEND _places "${_component}|${_d}")
    endforeach()

    set(_components)
    list(REMOVE_DUPLICATES _places)
    foreach(_e IN LISTS _places)
        string(REPLACE "|" ";" _e "${_e}")
        list(GET _e 0 _component)
        list(LENGTH _e _len)
        set(_d "")
        if (_len GREATER 1)
            list(GET _e 1 _d)
        endif()
        string(MAKE_C_IDENTIFIER "${_component}_${_d}" _key)
        if (_d STREQUAL "")
            set(_d .)
        endif()
        install(FILES ${_files_${_key}} DESTINATION "${_d}" COMPONENT ${_component})
        list(APPEND _components ${_component})
    endforeach()
    list(REMOVE_DUPLICATES _components)
    set_property(GLOBAL PROPERTY BUNDLE_COMPONENTS_${_c} "${_components}")
    set_property(GLOBAL PROPERTY BUNDLE_PREBUILT_${_c} TRUE)
endfunction()

# bundle_make_available()
#   Every layer declared: the prebuilt ones installed, the others fetched, their Boost.cmake included, then added
function(bundle_make_available)
    get_property(_layers GLOBAL PROPERTY BUNDLE_LAYERS)

    set(_sources)
    foreach(_layer IN LISTS _layers)
        get_property(_staging GLOBAL PROPERTY BUNDLE_STAGING_${_layer})
        get_property(_package GLOBAL PROPERTY BUNDLE_PACKAGE_${_layer})
        string(TOUPPER "${_staging}" _upper)
        set(_prefix "${BUNDLE_PREFIX_${_upper}}")
        if (_prefix)
            __bundle_prebuilt("${_staging}" "${_prefix}")
            if (_package)
                # found in the prefix only, so no other installation is taken; for the layers built here
                list(PREPEND CMAKE_PREFIX_PATH "${_prefix}")
                find_package(${_package} CONFIG REQUIRED GLOBAL PATHS "${_prefix}" NO_DEFAULT_PATH)
            endif()
        else()
            list(APPEND _sources ${_layer})
        endif()
    endforeach()
    if (NOT _sources)
        return()
    endif()

    FetchContent_MakeAvailable(${_sources})
    foreach(_layer IN LISTS _sources)
        string(TOLOWER "${_layer}" _lower)
        include("${${_lower}_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
    endforeach()

    # each layer's install components are those that appear while it is added; what it installs with no
    # COMPONENT goes to <c>_Development. SYSTEM, so its headers do not turn its warnings into the consumers' errors
    foreach(_layer IN LISTS _sources)
        get_property(_staging GLOBAL PROPERTY BUNDLE_STAGING_${_layer})
        string(MAKE_C_IDENTIFIER "${_staging}" _c)
        string(TOLOWER "${_layer}" _lower)
        get_cmake_property(_before COMPONENTS)
        set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "${_c}_Development")
        add_subdirectory("${${_lower}_SOURCE_DIR}" "${${_lower}_BINARY_DIR}" SYSTEM)
        get_cmake_property(_components COMPONENTS)
        if (_before)
            list(REMOVE_ITEM _components ${_before})
        endif()
        set_property(GLOBAL PROPERTY BUNDLE_COMPONENTS_${_c} "${_components}")
    endforeach()
endfunction()
