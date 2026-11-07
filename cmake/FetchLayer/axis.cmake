##
## Axes: what a staging has several variants by — triplet for every staging unless it says otherwise, python for
## the Python binding, and so on. A table, one row per axis:
##
##   axis      NATIVE                                VALUES
##   triplet   x86_64-macos-apple-clang-21-release   x86_64-macos-apple-clang-21-release;x86_64-linux-gcc-11-release
##   python    3.12                                  3.11;3.12
##
##   NATIVE  this build's own value: the variant whose every axis is native is the one built from source and installed
##   VALUES  the values made available; NATIVE when none is given
##
## One global property per cell, _FetchLayer_axis_<axis>_<COLUMN>; the rows, in _FetchLayer_axes. A row is added
## by FetchLayer_DeclareAxis; triplet, when nothing declared it, is declared from FETCHLAYER_TRIPLET.
##

include_guard(GLOBAL)

# what an axis is named: lower case, a letter first — it goes into a variant's string and an identity's key
set(_FETCHLAYER_AXIS_NAME "[a-z][a-z0-9_]*")

# __FetchLayer_axis_property(<axis> <column> <out>)
#   The name of the global property that holds <column> of the row <axis>
function(__FetchLayer_axis_property AXIS COLUMN OUT)
    set(${OUT} "_FetchLayer_axis_${AXIS}_${COLUMN}" PARENT_SCOPE)
endfunction()

# __FetchLayer_axis_get(<axis> <column> <out>)
#   NATIVE or VALUES of <axis>; triplet, when nothing declared it, declared from FETCHLAYER_TRIPLET first
function(__FetchLayer_axis_get AXIS COLUMN OUT)
    __FetchLayer_axis_property("${AXIS}" ${COLUMN} _property)
    get_property(_value GLOBAL PROPERTY "${_property}")
    if (NOT _value AND AXIS STREQUAL "triplet" AND FETCHLAYER_TRIPLET)
        FetchLayer_DeclareAxis(triplet NATIVE "${FETCHLAYER_TRIPLET}")
        get_property(_value GLOBAL PROPERTY "${_property}")
    endif()
    set(${OUT} "${_value}" PARENT_SCOPE)
endfunction()

# __FetchLayer_axis_check(<axis>…)
#   Fails on an axis not declared
function(__FetchLayer_axis_check)
    foreach(_axis IN LISTS ARGN)
        __FetchLayer_axis_get("${_axis}" NATIVE _native)
        if (NOT _native)
            message(FATAL_ERROR "FetchLayer: no axis ${_axis} is declared; FetchLayer_DeclareAxis(${_axis} NATIVE …)"
                                " (triplet: or set FETCHLAYER_TRIPLET)")
        endif()
    endforeach()
endfunction()
