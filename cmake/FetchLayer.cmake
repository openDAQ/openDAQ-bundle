##
## FetchLayer — FetchContent for layers, its sources swapped for prebuilt stagings where they exist. A layer is a
## repository at a revision; a staging is what a layer gives as one whole, with its own dependencies and identity.
## Stagings are made available, for one or more triplets, from where the policy says — prebuilt (System, later
## OCI) or built from their layer's sources (Git).
##
##   FetchLayer_Declare(<layer> REVISION <ref> [<FetchContent content options>…])
##   FetchLayer_DeclareStaging(<staging> LAYER <layer> [AXES <axis>…] [DEPENDS <staging>…] [FIND_PACKAGE_ARGS …])
##   FetchLayer_DeclareAxis(<axis> NATIVE <value> [VALUES <value>…])
##   FetchLayer_MakeAvailable(<staging>…)
##   FetchLayer_GetProperties(<staging> [VARIANT <variant> | AXES <axis>=<value>…])
##
## Declare records a Layer, DeclareStaging a Staging of a layer declared before it, DeclareAxis a row of the
## axes table; the first declaration of a name wins, a layer's and a staging's taken without case.
## MakeAvailable makes an Instance of each variant of each staging, in the order given — the variants the axes
## table names, each combination of the VALUES of the staging's axes: the policy, resolve, populate, integrate;
## a staging's DEPENDS must be available first. It sets nothing in the caller's scope. GetProperties copies one
## Instance into <staging>_* in the caller's scope.
##
## The axis triplet, when nothing declared it, is declared from FETCHLAYER_TRIPLET, the triplet this build is
## configured for. Only this build's own variant — each axis at its NATIVE value — is built from sources and
## installed; another comes prebuilt, files only. A variable for one layer or staging ends in its name
## upper-cased, as FetchContent's do (FETCHLAYER_PREFIX_OPCUA-MODULES, FETCHCONTENT_SOURCE_DIR_OPCUAMODULES).
##

include_guard(GLOBAL)

set(_FETCHLAYER_DIR "${CMAKE_CURRENT_LIST_DIR}/FetchLayer")
include("${_FETCHLAYER_DIR}/layer.cmake")
include("${_FETCHLAYER_DIR}/staging.cmake")
include("${_FETCHLAYER_DIR}/axis.cmake")
include("${_FETCHLAYER_DIR}/variant.cmake")
include("${_FETCHLAYER_DIR}/instance.cmake")
include("${_FETCHLAYER_DIR}/identity.cmake")
include("${_FETCHLAYER_DIR}/policy.cmake")
include("${_FETCHLAYER_DIR}/system.cmake")
include("${_FETCHLAYER_DIR}/git.cmake")
include("${_FETCHLAYER_DIR}/import.cmake")
include("${_FETCHLAYER_DIR}/compile.cmake")

set(FETCHLAYER_TRIPLET "" CACHE STRING "The triplet this build is configured for")
set(FETCHLAYER_STORE "" CACHE PATH "The store of prebuilt stagings: <store>/<staging>/idx-<hash>/<variant>")


# === FetchLayer_Declare ======================================================================================

# FetchLayer_Declare(<layer> REVISION <ref> [<FetchContent content options>…])
#   Records the layer; the first declaration of a name wins
function(FetchLayer_Declare NAME)
    __FetchLayer_layer_get("${NAME}" REVISION _known)
    if (_known)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "REVISION" "DEPENDS;FIND_PACKAGE_ARGS")
    if (NOT _arg_REVISION)
        message(FATAL_ERROR "FetchLayer_Declare(${NAME}): REVISION is required")
    endif()
    if (DEFINED _arg_DEPENDS OR DEFINED _arg_FIND_PACKAGE_ARGS)
        message(FATAL_ERROR "FetchLayer_Declare(${NAME}): DEPENDS and FIND_PACKAGE_ARGS are a staging's, "
                            "FetchLayer_DeclareStaging(<staging> LAYER ${NAME} …)")
    endif()

    __FetchLayer_layer_set("${NAME}" REVISION  "${_arg_REVISION}")
    __FetchLayer_layer_set("${NAME}" ARGUMENTS "${_arg_UNPARSED_ARGUMENTS}")
endfunction()

# FetchLayer_DeclareStaging(<staging> LAYER <layer> [AXES <axis>…] [DEPENDS <staging>…] [FIND_PACKAGE_ARGS …])
#   Records the staging of a layer declared before it; the first declaration of a name wins. AXES are what it has
#   variants by: triplet when not given, none when given empty; they are checked when it is made available, so
#   an axis may be declared after it
function(FetchLayer_DeclareStaging NAME)
    __FetchLayer_staging_get("${NAME}" LAYER _known)
    if (_known)
        return()
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "LAYER" "AXES;DEPENDS;FIND_PACKAGE_ARGS")
    if (_arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "FetchLayer_DeclareStaging(${NAME}): unknown arguments ${_arg_UNPARSED_ARGUMENTS}")
    endif()
    __FetchLayer_layer_get("${_arg_LAYER}" REVISION _layer_known)
    if (NOT _arg_LAYER OR NOT _layer_known)
        message(FATAL_ERROR "FetchLayer_DeclareStaging(${NAME}): LAYER must name a layer declared before it")
    endif()

    set(_axes triplet)
    if (DEFINED _arg_AXES OR "AXES" IN_LIST _arg_KEYWORDS_MISSING_VALUES)
        set(_axes ${_arg_AXES})
    endif()

    __FetchLayer_staging_set("${NAME}" LAYER             "${_arg_LAYER}")
    __FetchLayer_staging_set("${NAME}" AXES              "${_axes}")
    __FetchLayer_staging_set("${NAME}" DEPENDS           "${_arg_DEPENDS}")
    __FetchLayer_staging_set("${NAME}" FIND_PACKAGE_ARGS "${_arg_FIND_PACKAGE_ARGS}")
    __FetchLayer_layer_get("${_arg_LAYER}" STAGINGS _stagings)
    list(APPEND _stagings "${NAME}")
    __FetchLayer_layer_set("${_arg_LAYER}" STAGINGS "${_stagings}")
endfunction()


# FetchLayer_DeclareAxis(<axis> NATIVE <value> [VALUES <value>…])
#   Adds the row of <axis> to the axes table: its native value, and the values made available (the native one
#   when none is given); the first declaration of an axis wins
function(FetchLayer_DeclareAxis AXIS)
    __FetchLayer_axis_property("${AXIS}" NATIVE _property)
    get_property(_known GLOBAL PROPERTY "${_property}")
    if (_known)
        return()
    endif()
    if (NOT AXIS MATCHES "^${_FETCHLAYER_AXIS_NAME}$")
        message(FATAL_ERROR "FetchLayer_DeclareAxis(${AXIS}): an axis is named in lower case, a letter first")
    endif()

    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "NATIVE" "VALUES")
    if (_arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "FetchLayer_DeclareAxis(${AXIS}): unknown arguments ${_arg_UNPARSED_ARGUMENTS}")
    endif()
    if (NOT _arg_NATIVE)
        message(FATAL_ERROR "FetchLayer_DeclareAxis(${AXIS}): NATIVE, this build's value, is required")
    endif()
    set(_values ${_arg_VALUES})
    if (NOT _values)
        set(_values "${_arg_NATIVE}")
    endif()
    list(REMOVE_DUPLICATES _values)
    foreach(_value IN LISTS _arg_NATIVE _values)
        if (_value MATCHES "[+=]")
            message(FATAL_ERROR "FetchLayer_DeclareAxis(${AXIS}): a value has no + or =: ${_value}")
        endif()
    endforeach()

    set_property(GLOBAL PROPERTY "${_property}" "${_arg_NATIVE}")
    __FetchLayer_axis_property("${AXIS}" VALUES _property)
    set_property(GLOBAL PROPERTY "${_property}" "${_values}")
    set_property(GLOBAL APPEND PROPERTY _FetchLayer_axes "${AXIS}")
endfunction()


# === FetchLayer_MakeAvailable ================================================================================

# FetchLayer_MakeAvailable(<staging>…)
#   Makes an Instance of each variant of each staging, in the order given, with all it has: its Runtime, and
#   its Development when it has a CMake package. The variants are those the axes table names for the staging
#   (__FetchLayer_variant_list). As FetchContent_MakeAvailable it takes no components and no ordering of its
#   own: a staging's DEPENDS must be available before it, so they are named first.
function(FetchLayer_MakeAvailable)
    if (ARGN MATCHES "^TRIPLETS$|;TRIPLETS;|;TRIPLETS$")
        message(FATAL_ERROR "FetchLayer_MakeAvailable: TRIPLETS is gone; the triplets are the VALUES of the axis "
                            "triplet, FetchLayer_DeclareAxis(triplet NATIVE … VALUES …)")
    endif()
    foreach(_name IN LISTS ARGN)
        __FetchLayer_staging_get("${_name}" LAYER _layer)
        if (NOT _layer)
            message(FATAL_ERROR "FetchLayer_MakeAvailable: no staging ${_name} is declared")
        endif()
        __FetchLayer_staging_get("${_name}" AXES _axes)
        __FetchLayer_axis_check(${_axes})
        # what of its layer is asked for: the layer's decision looks at these
        __FetchLayer_layer_get("${_layer}" REQUESTED _requested)
        string(TOLOWER "${_name}" _lower)
        if (NOT _lower IN_LIST _requested)
            list(APPEND _requested "${_lower}")
            __FetchLayer_layer_set("${_layer}" REQUESTED "${_requested}")
        endif()
    endforeach()

    foreach(_name IN LISTS ARGN)
        __FetchLayer_variant_list("${_name}" _variants)
        foreach(_variant IN LISTS _variants)
            __FetchLayer_instance_get("${_name}" "${_variant}" POPULATED _populated)
            if (_populated)
                continue()
            endif()

            __FetchLayer_find("${_name}" "${_variant}")

            __FetchLayer_instance_get("${_name}" "${_variant}" ORIGIN _origin)
            cmake_language(CALL __FetchLayer_${_origin}_populate "${_name}" "${_variant}")
            # integrate: a prefix is imported, sources are compiled
            __FetchLayer_instance_get("${_name}" "${_variant}" PREFIX _prefix)
            __FetchLayer_instance_get("${_name}" "${_variant}" SOURCE_DIR _source_dir)
            if (_prefix)
                __FetchLayer_import_make_available("${_variant}" "${_name}")
                set(_where "${_prefix}")
            elseif (_source_dir)
                __FetchLayer_compile_make_available("${_variant}" "${_name}")
                set(_where "${_source_dir}")
            else()
                message(FATAL_ERROR "FetchLayer: ${_name} from ${_origin} brought neither a prefix nor sources")
            endif()
            __FetchLayer_instance_set("${_name}" "${_variant}" POPULATED TRUE)
            __FetchLayer_instance_get("${_name}" "${_variant}" REVISION _revision)
            __FetchLayer_instance_get("${_name}" "${_variant}" IDENTITY_MATCH _match)
            message(STATUS "FetchLayer: ${_name}@${_revision} ${_variant} from ${_origin} (${_match}): ${_where}")
        endforeach()
    endforeach()
endfunction()

# __FetchLayer_find(<staging> <variant>)
#   The first origin that has it, of those the policy names, in order, recorded in the Instance;
#   <staging> must be declared and its DEPENDS available for <variant>; none fails, with the facts the policy
#   went by
function(__FetchLayer_find STAGING VARIANT)
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    if (NOT _layer)
        message(FATAL_ERROR "FetchLayer: no staging ${STAGING} is declared")
    endif()
    __FetchLayer_request("${STAGING}" "${VARIANT}" _request)

    # the first origin that has it, of those the policy names
    __FetchLayer_policy_lookup("${STAGING}" "${VARIANT}" _origins)
    foreach(_origin IN LISTS _origins)
        set(_candidate_REF "")
        cmake_language(CALL __FetchLayer_${_origin}_resolve "${STAGING}" "${VARIANT}" _request _candidate)
        if (_candidate_REF)
            foreach(_field ORIGIN REF REVISION DEPENDS_REVISIONS VARIANT IDENTITY_MATCH)
                __FetchLayer_instance_set("${STAGING}" "${VARIANT}" ${_field} "${_candidate_${_field}}")
            endforeach()
            return()
        endif()
    endforeach()

    # none has it: the facts the policy went by
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_policy_build("${_layer}" _build)
    __FetchLayer_variant_select("${STAGING}" "" _own)
    list(JOIN _origins ", " _asked)
    message(FATAL_ERROR "FetchLayer: no ${STAGING}@${_request_REVISION} for ${VARIANT} (depends "
                        "${_request_DEPENDS_REVISIONS}; asked ${_asked}; FETCHLAYER_BUILD for ${_layer}: ${_build}; "
                        "this build's own variant: ${_own})")
endfunction()


# __FetchLayer_request(<staging> <variant> <request>)
#   The identity asked for, <request>_*: its layer's revision as a commit, the revisions of its DEPENDS for the
#   variants that go with <variant>, the variant. A dependency of another layer must be available already; one
#   of the same layer is at the layer's commit, available or not
function(__FetchLayer_request STAGING VARIANT REQUEST)
    __FetchLayer_staging_get("${STAGING}" LAYER _layer)
    __FetchLayer_git_commit("${_layer}" _revision)
    __FetchLayer_staging_get("${STAGING}" DEPENDS _depends)
    set(_pairs)
    foreach(_dependency IN LISTS _depends)
        string(TOLOWER "${_dependency}" _dependency)
        # the dependency's variant that goes with this one: by its own axes
        __FetchLayer_variant_select("${_dependency}" "${VARIANT}" _dependency_variant)
        __FetchLayer_instance_get("${_dependency}" "${_dependency_variant}" REVISION _dependency_revision)
        __FetchLayer_staging_get("${_dependency}" LAYER _dependency_layer)
        if (NOT _dependency_revision AND _dependency_layer STREQUAL _layer)
            set(_dependency_revision "${_revision}")
        endif()
        if (NOT _dependency_revision)
            message(FATAL_ERROR "FetchLayer: ${STAGING} depends on ${_dependency}, which is not available for "
                                "${_dependency_variant} yet; make it available first")
        endif()
        list(APPEND _pairs "${_dependency}=${_dependency_revision}")
    endforeach()
    list(SORT _pairs)
    set(${REQUEST}_NAME "${STAGING}" PARENT_SCOPE)
    set(${REQUEST}_REVISION "${_revision}" PARENT_SCOPE)
    set(${REQUEST}_DEPENDS_REVISIONS "${_pairs}" PARENT_SCOPE)
    set(${REQUEST}_VARIANT "${VARIANT}" PARENT_SCOPE)
endfunction()


# === FetchLayer_GetProperties ================================================================================

# FetchLayer_GetProperties(<staging> [VARIANT <variant> | AXES <axis>=<value>…])
#   Copies one Instance of <staging> into <staging>_<FIELD> in the caller's scope: this build's own variant; the
#   variant given, as a string of <staging>_VARIANTS; or the one with these axes' values, its other axes at their
#   native values. With it, each axis's value, <staging>_<AXIS> (opcua-modules_TRIPLET), and the variants made
#   available, <staging>_VARIANTS
function(FetchLayer_GetProperties NAME)
    cmake_parse_arguments(PARSE_ARGV 1 _arg "" "VARIANT" "AXES")
    if (_arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "FetchLayer_GetProperties(${NAME}): unknown arguments ${_arg_UNPARSED_ARGUMENTS}")
    endif()
    if (DEFINED _arg_VARIANT AND DEFINED _arg_AXES)
        message(FATAL_ERROR "FetchLayer_GetProperties(${NAME}): VARIANT or AXES, not both")
    endif()
    if (DEFINED _arg_VARIANT)
        set(_variant "${_arg_VARIANT}")
    else()
        __FetchLayer_variant_format(_given ${_arg_AXES})
        if (_given STREQUAL "any")
            set(_given "")
        endif()
        __FetchLayer_variant_select("${NAME}" "${_given}" _variant)
    endif()

    string(TOLOWER "${NAME}" _name)
    foreach(_field IN LISTS _FETCHLAYER_INSTANCE_FIELDS)
        __FetchLayer_instance_get("${_name}" "${_variant}" ${_field} _value)
        set(${_name}_${_field} "${_value}" PARENT_SCOPE)
    endforeach()
    __FetchLayer_staging_get("${_name}" AXES _axes)
    foreach(_axis IN LISTS _axes)
        __FetchLayer_variant_extract("${_variant}" "${_axis}" _value)
        string(TOUPPER "${_axis}" _upper)
        set(${_name}_${_upper} "${_value}" PARENT_SCOPE)
    endforeach()
    __FetchLayer_variant_list("${_name}" _variants)
    set(${_name}_VARIANTS "${_variants}" PARENT_SCOPE)
endfunction()
