##
## The Layer: a repository at a revision, as FetchLayer_Declare was given it — what FetchContent knows. One
## global property per field, _FetchLayer_layer_<name>_<FIELD>, the name lower-cased:
##
##   REVISION   a full sha, a tag or a branch; a tag or a branch is replaced by its commit when one of its
##              stagings is first looked for (__FetchLayer_git_commit)
##   ARGUMENTS  the rest, as given — FetchContent's content options; origins parse their own keywords from it
##              (GIT_REPOSITORY, …)
##   POST_FETCH_INCLUDES  scripts of its sources to include once fetched, before any layer is integrated
##   STAGINGS   the stagings it gives, as FetchLayer_DeclareStaging adds them
##   REQUESTED  those of its stagings FetchLayer_MakeAvailable was asked for
##   ORIGIN     where this build's own variants of its stagings come from, decided once for the layer:
##              system, all prebuilt, or git, all from its sources (__FetchLayer_policy_layer_origin)
##   INCLUDED   its POST_FETCH_INCLUDES included, once (compile.cmake)
##   COMPILED   its sources added to this build, once (compile.cmake)
##   COMPONENTS the install components its sources gave
##

include_guard(GLOBAL)

# __FetchLayer_layer_property(<layer> <field> <out>)
#   The name of the global property that holds <field> of the layer <layer>
function(__FetchLayer_layer_property LAYER FIELD OUT)
    string(TOLOWER "${LAYER}" _name)
    set(${OUT} "_FetchLayer_layer_${_name}_${FIELD}" PARENT_SCOPE)
endfunction()

# __FetchLayer_layer_set(<layer> <field> <value>)
function(__FetchLayer_layer_set LAYER FIELD VALUE)
    __FetchLayer_layer_property("${LAYER}" ${FIELD} _property)
    set_property(GLOBAL PROPERTY "${_property}" "${VALUE}")
endfunction()

# __FetchLayer_layer_get(<layer> <field> <out>)
function(__FetchLayer_layer_get LAYER FIELD OUT)
    __FetchLayer_layer_property("${LAYER}" ${FIELD} _property)
    get_property(_value GLOBAL PROPERTY "${_property}")
    set(${OUT} "${_value}" PARENT_SCOPE)
endfunction()
