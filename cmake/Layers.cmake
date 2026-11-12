##
## What the bundle is made of: its layers — repositories, named as in bundle.json — each with its staging, in the
## order they are taken, the core first (BUNDLE_LAYERS, <layer>=<staging>). How they are built is Sources.cmake's;
## how they are taken prebuilt, Stagings.cmake's.
##
## The revisions, one per layer — a full sha, a tag or a branch — from bundle.json; BUNDLE_REVISION_<LAYER>, the
## name upper-cased, in place of one (a preset or -D). BUNDLE_STAGINGS leaves layers out.
##

include_guard(GLOBAL)


# === the layers ==============================================================================================

# a layer's revision: BUNDLE_REVISION_<LAYER> when given, else bundle.json's — read at every configure, so an edit
# of it is taken without clearing the cache
set(_bundle_json "${CMAKE_CURRENT_LIST_DIR}/../bundle.json")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_bundle_json}")
file(READ "${_bundle_json}" _bundle)
foreach(_layer openDAQ OpcUaModules MQTTStreamingModule LTStreamingModulesModern ASAM-CMP-Modules)
    string(TOUPPER "${_layer}" _upper)
    set(BUNDLE_REVISION_${_upper} "" CACHE STRING "The revision of ${_layer}: a full sha, a tag or a branch; empty: bundle.json's")
    if (NOT BUNDLE_REVISION_${_upper})
        string(JSON BUNDLE_REVISION_${_upper} ERROR_VARIABLE _error GET "${_bundle}" layers "${_layer}")
        if (_error)
            message(FATAL_ERROR "bundle.json names no revision of ${_layer}: ${_error}")
        endif()
    endif()
endforeach()


# the layers, the core first, each with its staging; those BUNDLE_STAGINGS names. The core is always there: the
# modules are built against it, and every package has it
set(BUNDLE_LAYERS)
set(_known)
foreach(_entry
        openDAQ=opendaq
        OpcUaModules=opcua-modules
        MQTTStreamingModule=mqtt-module
        LTStreamingModulesModern=lt-streaming-modules
        ASAM-CMP-Modules=asam-cmp-modules)
    string(REPLACE "=" ";" _pair "${_entry}")
    list(GET _pair 1 _staging)
    list(APPEND _known ${_staging})
    if (_staging IN_LIST BUNDLE_STAGINGS)
        list(APPEND BUNDLE_LAYERS "${_entry}")
    endif()
endforeach()
if (NOT "opendaq" IN_LIST BUNDLE_STAGINGS)
    message(FATAL_ERROR "BUNDLE_STAGINGS leaves out opendaq, the core: the modules are built against it")
endif()
foreach(_staging IN LISTS BUNDLE_STAGINGS)
    if (NOT _staging IN_LIST _known)
        list(JOIN _known ", " _known)
        message(FATAL_ERROR "BUNDLE_STAGINGS names ${_staging}, which the bundle has not; it has ${_known}")
    endif()
endforeach()
