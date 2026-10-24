##
## The origin git: a layer's sources at a commit, by FetchContent.
##
## A layer is git's when its declaration names GIT_REPOSITORY; the other content options pass to
## FetchContent_Declare as they are, but GIT_TAG and SOURCE_SUBDIR, which are git's own: the commit resolved,
## and a subdirectory that does not exist, so FetchContent downloads only and adds nothing. The layer is the
## content FetchContent knows, under the layer's name; its stagings come from that one tree.
##
## Before any origin is asked, find turns the declared revision into a commit, __FetchLayer_git_commit: a
## full sha as it is, a tag or a branch by git ls-remote; a short sha is refused — no ref names it, and
## finding it needs the history. The commit replaces the declared revision, so the next triplet takes it as
## it is, and every triplet gets the same one; every origin then looks for it.
##
## resolve, for a staging: sources are built for this build's own variant only, so another variant gets nothing.
## The identity is exact: the staging is built here against what is available.
## populate downloads its layer: the Instance's SOURCE_DIR and BINARY_DIR. FetchContent's own variables hold,
## among them FETCHCONTENT_SOURCE_DIR_<LAYER> (the layer's name upper-cased, as FetchContent does), a local
## checkout taken as it is — its HEAD is the revision, and one other than declared, or with changes, is
## warned about.
##

include_guard(GLOBAL)

include(FetchContent)
find_package(Git QUIET)

set(_FETCHLAYER_GIT_NO_SUBDIR "__fetchlayer_download_only__")

# __FetchLayer_git_repository(<layer> <out>)
#   The GIT_REPOSITORY of the layer, empty when none
function(__FetchLayer_git_repository LAYER OUT)
    __FetchLayer_layer_get("${LAYER}" ARGUMENTS _arguments)
    cmake_parse_arguments(_git "" "GIT_REPOSITORY;GIT_TAG;SOURCE_SUBDIR" "" ${_arguments})
    if (DEFINED _git_GIT_TAG OR DEFINED _git_SOURCE_SUBDIR)
        message(FATAL_ERROR "FetchLayer_Declare(${LAYER}): GIT_TAG and SOURCE_SUBDIR are FetchLayer's; "
                            "the commit is REVISION")
    endif()
    set(${OUT} "${_git_GIT_REPOSITORY}" PARENT_SCOPE)
endfunction()

# __FetchLayer_git_run(<out> <arg>…)
#   git <arg>…, its output stripped; fails with git's error
function(__FetchLayer_git_run OUT)
    if (NOT GIT_EXECUTABLE)
        message(FATAL_ERROR "FetchLayer: git is not found")
    endif()
    execute_process(COMMAND "${GIT_EXECUTABLE}" ${ARGN}
                    OUTPUT_VARIABLE _out ERROR_VARIABLE _err RESULT_VARIABLE _rc
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (NOT _rc EQUAL 0)
        list(JOIN ARGN " " _command)
        message(FATAL_ERROR "FetchLayer: git ${_command}:\n${_err}")
    endif()
    set(${OUT} "${_out}" PARENT_SCOPE)
endfunction()

# __FetchLayer_git_commit(<layer> <out>)
#   The declared revision of <layer> as a full sha: as it is, or a tag (an annotated one by the commit it points
#   to) or a branch of its GIT_REPOSITORY by git ls-remote, then written over the declared REVISION: once per
#   layer, every variant the same commit, though the branch moves meanwhile
function(__FetchLayer_git_commit LAYER OUT)
    __FetchLayer_layer_get("${LAYER}" REVISION _revision)
    string(LENGTH "${_revision}" _length)
    if (_revision MATCHES "^[0-9a-f]+$" AND _length EQUAL 40)
        set(_sha "${_revision}")
    else()
        __FetchLayer_git_repository("${LAYER}" _repository)
        if (NOT _repository)
            message(FATAL_ERROR "FetchLayer: ${LAYER} revision ${_revision} is not a full sha, and the layer has no "
                                "GIT_REPOSITORY to resolve it by")
        endif()
        if (FETCHCONTENT_FULLY_DISCONNECTED)
            message(FATAL_ERROR "FetchLayer: ${LAYER} revision ${_revision} is not a full sha, and "
                                "FETCHCONTENT_FULLY_DISCONNECTED forbids asking ${_repository}")
        endif()
        __FetchLayer_git_run(_lines ls-remote "${_repository}"
                             "refs/tags/${_revision}" "refs/tags/${_revision}^{}" "refs/heads/${_revision}")
        # <sha>\t<ref> lines, as a <ref>=<sha> list
        string(REPLACE "\n" ";" _lines "${_lines}")
        set(_refs)
        foreach(_line IN LISTS _lines)
            string(REPLACE "\t" ";" _fields "${_line}")
            list(GET _fields 0 _line_sha)
            list(GET _fields 1 _line_ref)
            list(APPEND _refs "${_line_ref}=${_line_sha}")
        endforeach()
        foreach(_ref_name "refs/tags/${_revision}^{}" "refs/tags/${_revision}" "refs/heads/${_revision}")
            foreach(_entry IN LISTS _refs)
                if (_entry MATCHES "^(.*)=([0-9a-f]+)$" AND CMAKE_MATCH_1 STREQUAL _ref_name)
                    set(_sha "${CMAKE_MATCH_2}")
                endif()
            endforeach()
            if (_sha)
                break()
            endif()
        endforeach()
        if (NOT _sha)
            message(FATAL_ERROR "FetchLayer: ${LAYER} revision ${_revision} is neither a full sha nor a tag or a branch "
                                "of ${_repository}; a short sha is not resolved, give the full one")
        endif()
        message(STATUS "FetchLayer: ${LAYER} ${_revision} is ${_sha}")
        __FetchLayer_layer_set("${LAYER}" REVISION "${_sha}")
    endif()
    set(${OUT} "${_sha}" PARENT_SCOPE)
endfunction()

# __FetchLayer_git_resolve(<staging> <variant> <request> <candidate>)
function(__FetchLayer_git_resolve STAGING VARIANT REQUEST CANDIDATE)
    __FetchLayer_variant_native("${VARIANT}" _native)
    if (NOT _native)
        return()
    endif()
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_git_repository("${_layer}" _repository)
    if (NOT _repository)
        message(WARNING "FetchLayer: ${STAGING} is to be built from sources, and its layer ${_layer} has no "
                        "GIT_REPOSITORY to build from")
        return()
    endif()
    set(_wanted "${${REQUEST}_REVISION}")
    string(TOUPPER "${_layer}" _upper)
    set(_local "${FETCHCONTENT_SOURCE_DIR_${_upper}}")

    if (_local)
        # a local checkout, as it is: its HEAD
        __FetchLayer_git_run(_sha -C "${_local}" rev-parse HEAD)
        __FetchLayer_git_run(_changes -C "${_local}" status --porcelain --untracked-files=no)
        if (NOT _sha STREQUAL _wanted OR _changes)
            set(_with "")
            if (_changes)
                set(_with " with changes")
            endif()
            message(WARNING "FetchLayer: ${_layer} from the local checkout ${_local}: ${_sha}${_with}, "
                            "not the declared ${_wanted}")
        endif()
        set(_ref "${_local}")
    else()
        set(_sha "${_wanted}")
        set(_ref "${_sha}")
    endif()

    set(${CANDIDATE}_ORIGIN git PARENT_SCOPE)
    set(${CANDIDATE}_REF "${_ref}" PARENT_SCOPE)
    set(${CANDIDATE}_REVISION "${_sha}" PARENT_SCOPE)
    set(${CANDIDATE}_DEPENDS_REVISIONS "${${REQUEST}_DEPENDS_REVISIONS}" PARENT_SCOPE)
    set(${CANDIDATE}_VARIANT "${VARIANT}" PARENT_SCOPE)
    set(${CANDIDATE}_IDENTITY_MATCH EXACT PARENT_SCOPE)
endfunction()

# __FetchLayer_git_populate(<staging> <variant>)
#   Downloads the Instance's REVISION of its layer, once for the layer; the Instance's SOURCE_DIR and BINARY_DIR
function(__FetchLayer_git_populate STAGING VARIANT)
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_layer_get("${_layer}" ARGUMENTS _arguments)
    __FetchLayer_instance_get("${STAGING}" "${VARIANT}" REVISION _sha)
    FetchContent_Declare(${_layer} ${_arguments} GIT_TAG "${_sha}" SOURCE_SUBDIR "${_FETCHLAYER_GIT_NO_SUBDIR}")
    FetchContent_MakeAvailable(${_layer})
    FetchContent_GetProperties(${_layer} SOURCE_DIR _source_dir BINARY_DIR _binary_dir)
    __FetchLayer_instance_set("${STAGING}" "${VARIANT}" SOURCE_DIR "${_source_dir}")
    __FetchLayer_instance_set("${STAGING}" "${VARIANT}" BINARY_DIR "${_binary_dir}")
endfunction()
