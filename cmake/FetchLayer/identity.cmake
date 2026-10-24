##
## The identity of a staging and of a variant of it, its hash and its place in the store.
##
## An identity is variables with one prefix, <id>_*:
##
##   <id>_NAME               the staging                            opcua-modules
##   <id>_REVISION           the commit it is built from            ad11c59ad433…
##   <id>_DEPENDS_REVISIONS  the commits it is built against        opendaq=3039ee6d…;libx=…
##   <id>_VARIANT            what it is built for (variant.cmake); empty for the identity of the staging itself
##
## Its hash is that of its key=value lines — the revision, one per dependency, one per axis of the variant —
## sorted bytewise and joined by \n, sha256, after a prefix: idx-<hash> for a staging, pkg-<hash> for a variant.
## The keys are those the registry annotates its packages with, so the hash names the tags there too; whoever
## names them sets them:
##
##   FETCHLAYER_IDENTITY_REVISION_KEY     the revision
##   FETCHLAYER_IDENTITY_DEPENDENCY_KEY   a dependency's revision, <name> standing for the dependency
##   FETCHLAYER_IDENTITY_AXIS_KEY         the value of an axis, <axis> standing for the axis
##
## Only stagings (DEPENDS) and axes enter an identity: what else a package is annotated with must use other keys.
## A variant lies in the store at <FETCHLAYER_STORE>/<name>/idx-<hash>/<variant>.
##

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/variant.cmake")

set(FETCHLAYER_IDENTITY_REVISION_KEY   "revision"              CACHE STRING "Key of the revision in an identity")
set(FETCHLAYER_IDENTITY_DEPENDENCY_KEY "dependency.<name>.revision" CACHE STRING "Key of a dependency's revision in an identity; <name> is the dependency")
set(FETCHLAYER_IDENTITY_AXIS_KEY       "<axis>"                CACHE STRING "Key of an axis's value in an identity; <axis> is the axis")

# __FetchLayer_identity_hash(<id> <prefix> <out>)
#   <prefix>-<sha256> of the identity <id>; with the variant left out for a staging's own hash
function(__FetchLayer_identity_hash ID PREFIX OUT)
    if (NOT ${ID}_REVISION)
        message(FATAL_ERROR "FetchLayer: the identity ${ID} has no revision")
    endif()
    set(_lines "${FETCHLAYER_IDENTITY_REVISION_KEY}=${${ID}_REVISION}")
    foreach(_pair IN LISTS ${ID}_DEPENDS_REVISIONS)
        if (NOT _pair MATCHES "^([^=]+)=(.+)$")
            message(FATAL_ERROR "FetchLayer: not a <dependency>=<revision> pair in ${ID}: ${_pair}")
        endif()
        string(REPLACE "<name>" "${CMAKE_MATCH_1}" _key "${FETCHLAYER_IDENTITY_DEPENDENCY_KEY}")
        list(APPEND _lines "${_key}=${CMAKE_MATCH_2}")
    endforeach()
    if (${ID}_VARIANT)
        __FetchLayer_variant_parse("${${ID}_VARIANT}" _axes)
        foreach(_pair IN LISTS _axes)
            string(REGEX MATCH "^([^=]+)=(.*)$" _ "${_pair}")
            string(REPLACE "<axis>" "${CMAKE_MATCH_1}" _key "${FETCHLAYER_IDENTITY_AXIS_KEY}")
            list(APPEND _lines "${_key}=${CMAKE_MATCH_2}")
        endforeach()
    endif()
    list(SORT _lines)
    list(JOIN _lines "\n" _text)
    string(SHA256 _hash "${_text}")
    set(${OUT} "${PREFIX}-${_hash}" PARENT_SCOPE)
endfunction()

# __FetchLayer_identity_path(<id> <out>)
#   Where the variant <id> lies in the store: <FETCHLAYER_STORE>/<staging>/idx-<hash>/<variant>
function(__FetchLayer_identity_path ID OUT)
    if (NOT FETCHLAYER_STORE)
        message(FATAL_ERROR "FetchLayer: FETCHLAYER_STORE is not set")
    endif()
    if (NOT ${ID}_NAME OR NOT ${ID}_VARIANT)
        message(FATAL_ERROR "FetchLayer: the identity ${ID} needs a name and a variant for a place in the store")
    endif()
    # the staging's own hash: the same revisions, without the variant
    set(_staging_NAME "${${ID}_NAME}")
    set(_staging_REVISION "${${ID}_REVISION}")
    set(_staging_DEPENDS_REVISIONS "${${ID}_DEPENDS_REVISIONS}")
    set(_staging_VARIANT "")
    __FetchLayer_identity_hash(_staging idx _idx)
    set(${OUT} "${FETCHLAYER_STORE}/${${ID}_NAME}/${_idx}/${${ID}_VARIANT}" PARENT_SCOPE)
endfunction()
