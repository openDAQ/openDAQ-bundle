##
## The Instance: a variant of a staging made available, one per staging and variant. One global property per
## field, _FetchLayer_instance_<staging>_<variant>_<FIELD>, the name lower-cased:
##
##   ORIGIN              where it came from: system, git                                    find
##   REF                 the origin's reference: a store path, a sha, a local checkout       find
##   REVISION            the commit of its layer it is built from                            find
##   DEPENDS_REVISIONS   the commits it is built against, <staging>=<sha>…                   find
##   VARIANT             what it is built for, one value per axis (variant.cmake)            find
##   IDENTITY_MATCH      EXACT: its identity was read or it is built here; VERSION: guessed  find
##   PREFIX              prebuilt: its install prefix                                        populate
##   SOURCE_DIR          from source: its sources …                                          populate
##   BINARY_DIR          … and their build tree                                              populate
##   INSTALL_COMPONENTS  its install components, <staging>_Runtime / _Development            integration
##   POPULATED           made available                                                      MakeAvailable
##
## FetchLayer_GetProperties copies every field into <staging>_<FIELD>.
##

include_guard(GLOBAL)

set(_FETCHLAYER_INSTANCE_FIELDS
    POPULATED ORIGIN REF PREFIX SOURCE_DIR BINARY_DIR REVISION DEPENDS_REVISIONS VARIANT IDENTITY_MATCH INSTALL_COMPONENTS)

# __FetchLayer_instance_property(<staging> <variant> <field> <out>)
#   The name of the global property that holds <field> of the staging <staging> for <variant>
function(__FetchLayer_instance_property STAGING VARIANT FIELD OUT)
    string(TOLOWER "${STAGING}" _name)
    set(${OUT} "_FetchLayer_instance_${_name}_${VARIANT}_${FIELD}" PARENT_SCOPE)
endfunction()

# __FetchLayer_instance_set(<staging> <variant> <field> <value>)
function(__FetchLayer_instance_set STAGING VARIANT FIELD VALUE)
    __FetchLayer_instance_property("${STAGING}" "${VARIANT}" ${FIELD} _property)
    set_property(GLOBAL PROPERTY "${_property}" "${VALUE}")
endfunction()

# __FetchLayer_instance_get(<staging> <variant> <field> <out>)
function(__FetchLayer_instance_get STAGING VARIANT FIELD OUT)
    __FetchLayer_instance_property("${STAGING}" "${VARIANT}" ${FIELD} _property)
    get_property(_value GLOBAL PROPERTY "${_property}")
    set(${OUT} "${_value}" PARENT_SCOPE)
endfunction()
