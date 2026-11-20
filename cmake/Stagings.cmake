##
## Every staging taken prebuilt (BUNDLE_FROM=STAGINGS): unpacked into the directory BUNDLE_PREFIX_<STAGING> gives
## (the name upper-cased), one for every staging BUNDLE_LAYERS has, else an error. Nothing is fetched or compiled:
## a staging's files are installed under its install components.
##
## A staging's install components are kept for Packing.cmake as BUNDLE_COMPONENTS_<c>, and BUNDLE_PREBUILT_<c>,
## <c> the staging's name made a C identifier.
##

include_guard(GLOBAL)

set(_BUNDLE_RUNTIME_PATTERNS "*.so" "*.so.*" "*.dylib" "*.dll")

# bundle_install_prefix(<staging> <prefix>)
#   The prefix's files under the staging's install components: a module (a *.module.* file in lib/modules or
#   bin/modules) under one of its own, <module>_Runtime, so an installer can offer it apart (no staging in the name:
#   NSIS makes variables of component names, 60 characters at most); other shared libraries under <c>_Runtime; the
#   rest — headers, CMake configs, static and import libraries — under <c>_Development. File by file, so no empty
#   directory lands in a component.
function(bundle_install_prefix STAGING PREFIX)
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
            # a module's name from its file: libref_fb_module-64-3.module.so → ref_fb_module
            string(REGEX REPLACE "^lib" "" _stem "${_n}")
            string(REGEX REPLACE "(-[0-9]+-[0-9]+)?\\.module\\..*$" "" _stem "${_stem}")
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

set(_missing)
foreach(_entry IN LISTS BUNDLE_LAYERS)
    string(REPLACE "=" ";" _pair "${_entry}")
    list(GET _pair 1 _staging)
    string(TOUPPER "${_staging}" _upper)
    set(BUNDLE_PREFIX_${_upper} "" CACHE PATH "The prebuilt staging ${_staging}, unpacked")
    if (NOT IS_DIRECTORY "${BUNDLE_PREFIX_${_upper}}")
        list(APPEND _missing "BUNDLE_PREFIX_${_upper}")
    endif()
endforeach()
if (_missing)
    list(JOIN _missing ", " _missing)
    message(FATAL_ERROR "BUNDLE_FROM=STAGINGS takes every staging prebuilt; no directory given as ${_missing}")
endif()

foreach(_entry IN LISTS BUNDLE_LAYERS)
    string(REPLACE "=" ";" _pair "${_entry}")
    list(GET _pair 1 _staging)
    string(TOUPPER "${_staging}" _upper)
    bundle_install_prefix("${_staging}" "${BUNDLE_PREFIX_${_upper}}")
endforeach()
