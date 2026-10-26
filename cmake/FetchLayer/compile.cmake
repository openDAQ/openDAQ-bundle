##
## The strategy compile: a layer's sources added to this build, as FetchContent_MakeAvailable adds them.
##
## Once per layer, at its first staging: add_subdirectory(<sources> <build tree> SYSTEM) — SYSTEM, so the layer's
## headers do not turn its warnings into the consumers' errors; never EXCLUDE_FROM_ALL, so its install() rules
## pack. Its settings are the set(... CACHE ...) before MakeAvailable. Its install components are those that
## appear while it is added (get_cmake_property(COMPONENTS) before and after); what it installs without a
## COMPONENT goes to <staging>_Development. They go to the staging of the layer; a layer whose several stagings
## come from its sources would have to split them between them, which is not done yet.
##
## Before that, once every staging asked for is fetched, the layer's POST_FETCH_INCLUDES are included
## (__FetchLayer_compile_post_fetch). Only this build's own variant is compiled: the policy never sends another
## one here.
##

include_guard(GLOBAL)

# __FetchLayer_compile_post_fetch(<variant> <staging>)
#   Includes the POST_FETCH_INCLUDES of the staging's layer, once for the layer: <SOURCE_DIR> and <BINARY_DIR>
#   replaced by the layer's directories, OPTIONAL; with <layer>_SOURCE_DIR and _BINARY_DIR set, lower-cased
function(__FetchLayer_compile_post_fetch VARIANT STAGING)
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_layer_get("${_layer}" INCLUDED _included)
    if (_included)
        return()
    endif()
    __FetchLayer_layer_set("${_layer}" INCLUDED TRUE)
    __FetchLayer_layer_get("${_layer}" POST_FETCH_INCLUDES _scripts)
    __FetchLayer_instance_get("${STAGING}" "${VARIANT}" SOURCE_DIR _source_dir)
    __FetchLayer_instance_get("${STAGING}" "${VARIANT}" BINARY_DIR _binary_dir)
    string(TOLOWER "${_layer}" _lower)
    set(${_lower}_SOURCE_DIR "${_source_dir}")
    set(${_lower}_BINARY_DIR "${_binary_dir}")
    foreach(_script IN LISTS _scripts)
        string(REPLACE "<SOURCE_DIR>" "${_source_dir}" _script "${_script}")
        string(REPLACE "<BINARY_DIR>" "${_binary_dir}" _script "${_script}")
        include("${_script}" OPTIONAL)
    endforeach()
endfunction()

# __FetchLayer_compile_make_available(<variant> <staging>)
function(__FetchLayer_compile_make_available VARIANT STAGING)
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_layer_get("${_layer}" COMPILED _compiled)
    if (NOT _compiled)
        __FetchLayer_layer_get("${_layer}" REQUESTED _requested)
        list(LENGTH _requested _count)
        if (_count GREATER 1)
            message(FATAL_ERROR "FetchLayer: ${_layer} is built from its sources for ${_requested}; giving its "
                                "install components to several stagings is not done yet")
        endif()
        __FetchLayer_instance_get("${STAGING}" "${VARIANT}" SOURCE_DIR _source_dir)
        __FetchLayer_instance_get("${STAGING}" "${VARIANT}" BINARY_DIR _binary_dir)
        string(MAKE_C_IDENTIFIER "${STAGING}" _c)

        get_cmake_property(_before COMPONENTS)
        set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "${_c}_Development")
        add_subdirectory("${_source_dir}" "${_binary_dir}" SYSTEM)
        get_cmake_property(_components COMPONENTS)
        if (_before)
            list(REMOVE_ITEM _components ${_before})
        endif()

        __FetchLayer_layer_set("${_layer}" COMPONENTS "${_components}")
        __FetchLayer_layer_set("${_layer}" COMPILED TRUE)
    endif()
    __FetchLayer_layer_get("${_layer}" COMPONENTS _components)
    __FetchLayer_instance_set("${STAGING}" "${VARIANT}" INSTALL_COMPONENTS "${_components}")
endfunction()
