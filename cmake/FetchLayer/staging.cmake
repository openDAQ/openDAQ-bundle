##
## The Staging: what a layer gives as one whole — declared, made available and published with one identity;
## its builds are its Instances. One global property per field, _FetchLayer_staging_<name>_<FIELD>, the name
## lower-cased:
##
##   LAYER              the layer that gives it, its revision and its sources
##   AXES               what it has variants by: triplet by default, none when declared empty (axis.cmake)
##   DEPENDS            the stagings it is built against
##   FIND_PACKAGE_ARGS  how to find it as a package
##

include_guard(GLOBAL)

# __FetchLayer_staging_property(<staging> <field> <out>)
#   The name of the global property that holds <field> of the staging <staging>
function(__FetchLayer_staging_property STAGING FIELD OUT)
    string(TOLOWER "${STAGING}" _name)
    set(${OUT} "_FetchLayer_staging_${_name}_${FIELD}" PARENT_SCOPE)
endfunction()

# __FetchLayer_staging_set(<staging> <field> <value>)
function(__FetchLayer_staging_set STAGING FIELD VALUE)
    __FetchLayer_staging_property("${STAGING}" ${FIELD} _property)
    set_property(GLOBAL PROPERTY "${_property}" "${VALUE}")
endfunction()

# __FetchLayer_staging_get(<staging> <field> <out>)
function(__FetchLayer_staging_get STAGING FIELD OUT)
    __FetchLayer_staging_property("${STAGING}" ${FIELD} _property)
    get_property(_value GLOBAL PROPERTY "${_property}")
    set(${OUT} "${_value}" PARENT_SCOPE)
endfunction()
