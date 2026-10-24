##
## The origin system: a staging already on the disk.
##
## resolve looks first in the store, <FETCHLAYER_STORE>/<staging>/idx-<hash>/<variant>, by the hash of the identity
## requested (its revision a full sha: find turns a tag or a branch into one first). A directory there is the
## variant requested by construction — its path is its identity — so the identity is exact; and it is complete,
## renamed into place once unpacked. Else FETCHLAYER_PREFIX_<NAME>, a directory named by hand for the staging (its
## name upper-cased): taken for what was asked, as asked for, its identity a version.
## Whatever the prefix holds is taken: Runtime always, Development when the staging's CMake config is there.
## populate brings nothing: the prefix is where it was found.
##

include_guard(GLOBAL)

# __FetchLayer_system_config(<staging> <prefix> <out>)
#   The staging's CMake config in <prefix>, by the package name FIND_PACKAGE_ARGS gives (NAMES …), else the staging's
function(__FetchLayer_system_config STAGING PREFIX OUT)
    __FetchLayer_staging_get("${STAGING}" FIND_PACKAGE_ARGS _args)
    cmake_parse_arguments(_F "" "" "NAMES" ${_args})
    set(_pkgs ${_F_NAMES})
    if (NOT _pkgs)
        set(_pkgs "${STAGING}")
    endif()
    set(_found "")
    foreach(_p IN LISTS _pkgs)
        string(TOLOWER "${_p}" _lp)
        foreach(_dir lib/cmake/${_p} lib/cmake/${_lp} lib/${_p}/cmake share/cmake/${_p} CMake cmake)
            foreach(_f ${_p}Config.cmake ${_lp}-config.cmake)
                if (EXISTS "${PREFIX}/${_dir}/${_f}")
                    set(_found "${PREFIX}/${_dir}/${_f}")
                    break()
                endif()
            endforeach()
            if (_found)
                break()
            endif()
        endforeach()
        if (_found)
            break()
        endif()
    endforeach()
    set(${OUT} "${_found}" PARENT_SCOPE)
endfunction()

# __FetchLayer_system_resolve(<staging> <variant> <request> <candidate>)
function(__FetchLayer_system_resolve STAGING VARIANT REQUEST CANDIDATE)
    string(TOUPPER "${STAGING}" _upper)
    set(_prefix "")
    set(_match VERSION)

    # the store, by the hash of the identity requested: exact
    if (FETCHLAYER_STORE)
        __FetchLayer_identity_path(${REQUEST} _path)
        if (IS_DIRECTORY "${_path}")
            set(_prefix "${_path}")
            set(_match EXACT)
        endif()
    endif()

    # else a prefix named by hand for the staging: taken for what was asked, as a version
    if (NOT _prefix AND FETCHLAYER_PREFIX_${_upper})
        set(_prefix "${FETCHLAYER_PREFIX_${_upper}}")
    endif()

    if (NOT _prefix OR NOT IS_DIRECTORY "${_prefix}")
        return()
    endif()
    set(${CANDIDATE}_ORIGIN system PARENT_SCOPE)
    set(${CANDIDATE}_REF "${_prefix}" PARENT_SCOPE)
    set(${CANDIDATE}_REVISION "${${REQUEST}_REVISION}" PARENT_SCOPE)
    set(${CANDIDATE}_DEPENDS_REVISIONS "${${REQUEST}_DEPENDS_REVISIONS}" PARENT_SCOPE)
    set(${CANDIDATE}_VARIANT "${VARIANT}" PARENT_SCOPE)
    set(${CANDIDATE}_IDENTITY_MATCH ${_match} PARENT_SCOPE)
endfunction()

# __FetchLayer_system_populate(<staging> <variant>)
#   The Instance's REF is its prefix already
function(__FetchLayer_system_populate STAGING VARIANT)
    __FetchLayer_instance_get("${STAGING}" "${VARIANT}" REF _ref)
    __FetchLayer_instance_set("${STAGING}" "${VARIANT}" PREFIX "${_ref}")
endfunction()
