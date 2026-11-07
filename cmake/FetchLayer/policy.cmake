##
## The policy: whether a staging is built from its layer's sources. One setting, as Conan's --build, for all
## layers and, overriding it, for one:
##
##   FETCHLAYER_BUILD          for all layers, MISSING by default
##   FETCHLAYER_BUILD_<LAYER>  for one layer, the layer's name upper-cased as FetchContent's <uppercaseName>
##                             (FETCHLAYER_BUILD_OPCUAMODULES)
##
##   NEVER    prebuilt stagings only; one missing is an error
##   MISSING  prebuilt where there is one, else built from sources
##   ALWAYS   built from sources, prebuilt ones not looked for
##
## A layer from a local checkout (FETCHCONTENT_SOURCE_DIR_<LAYER>) is always built from it, as the bundle spec
## says. A setting is a plain variable, as FetchContent's: set by a preset, -D, cmake -C or the project;
## __FetchLayer_policy_build reads it for a layer.
##
## Not the policy, a fact: only this build's own variant can be built here; another variant — another
## triplet, another Python — comes prebuilt or not at all.
##

include_guard(GLOBAL)

set(FETCHLAYER_BUILD "MISSING" CACHE STRING "Whether stagings are built from sources: NEVER, MISSING, ALWAYS")
set_property(CACHE FETCHLAYER_BUILD PROPERTY STRINGS NEVER MISSING ALWAYS)

# __FetchLayer_policy_build(<layer> <out>)
#   NEVER, MISSING or ALWAYS for <layer>: ALWAYS for a local checkout, else FETCHLAYER_BUILD_<LAYER>, else
#   FETCHLAYER_BUILD
function(__FetchLayer_policy_build LAYER OUT)
    string(TOUPPER "${LAYER}" _upper)
    if (FETCHCONTENT_SOURCE_DIR_${_upper})
        set(_build ALWAYS)
    elseif (DEFINED FETCHLAYER_BUILD_${_upper})
        set(_build "${FETCHLAYER_BUILD_${_upper}}")
    else()
        set(_build "${FETCHLAYER_BUILD}")
    endif()
    set(${OUT} "${_build}" PARENT_SCOPE)
endfunction()

# __FetchLayer_policy_layer_origin(<layer> <out>)
#   Where this build's own variants of the layer's stagings come from, decided once for the layer and kept as its
#   ORIGIN: git when FETCHLAYER_BUILD is ALWAYS (or the layer is a local checkout); system when it is NEVER; when
#   it is MISSING, system if the store has the own variant of every staging of the layer asked for, else git —
#   for all of them, as two copies of a layer's targets cannot live in one tree
function(__FetchLayer_policy_layer_origin LAYER OUT)
    __FetchLayer_layer_get("${LAYER}" ORIGIN _origin)
    if (NOT _origin)
        __FetchLayer_policy_build("${LAYER}" _build)
        if (_build STREQUAL "ALWAYS")
            set(_origin git)
        elseif (_build STREQUAL "NEVER")
            set(_origin system)
        else()
            set(_origin system)
            __FetchLayer_layer_get("${LAYER}" REQUESTED _requested)
            foreach(_staging IN LISTS _requested)
                __FetchLayer_variant_select("${_staging}" "" _variant)
                __FetchLayer_request("${_staging}" "${_variant}" _request)
                set(_candidate_REF "")
                __FetchLayer_system_resolve("${_staging}" "${_variant}" _request _candidate)
                if (NOT _candidate_REF)
                    message(STATUS "FetchLayer: ${LAYER} from its sources: no prebuilt ${_staging} for ${_variant}")
                    set(_origin git)
                    break()
                endif()
            endforeach()
        endif()
        __FetchLayer_layer_set("${LAYER}" ORIGIN "${_origin}")
    endif()
    set(${OUT} "${_origin}" PARENT_SCOPE)
endfunction()

# __FetchLayer_policy_lookup(<staging> <variant> <out-origins>)
#   The origin to ask: for this build's own variant, its layer's (__FetchLayer_policy_layer_origin); for another
#   variant, system — it cannot be built here
function(__FetchLayer_policy_lookup STAGING VARIANT OUT)
    __FetchLayer_variant_native("${VARIANT}" _native)
    if (_native)
        __FetchLayer_staging_get("${STAGING}" LAYER _layer)
        __FetchLayer_policy_layer_origin("${_layer}" _origin)
    else()
        set(_origin system)
    endif()
    set(${OUT} "${_origin}" PARENT_SCOPE)
endfunction()
