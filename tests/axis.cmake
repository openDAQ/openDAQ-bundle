# Axes and variants, without a store:  cmake -P tests/axis.cmake
cmake_minimum_required(VERSION 3.25)
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/FetchLayer.cmake")

set(_failed FALSE)
function(expect WHAT GOT WANT)
    if (GOT STREQUAL WANT)
        message(STATUS "ok    ${WHAT}: ${GOT}")
    else()
        message(SEND_ERROR "FAIL  ${WHAT}: ${GOT}, not ${WANT}")
    endif()
endfunction()

set(A x86_64-macos-apple-clang-21-release)
set(B x86_64-linux-gcc-11-release)

# triplet, declared from FETCHLAYER_TRIPLET when nothing declared it
set(FETCHLAYER_TRIPLET ${A})
__FetchLayer_axis_get(triplet NATIVE _native)
expect("triplet from FETCHLAYER_TRIPLET" "${_native}" "${A}")
FetchLayer_DeclareAxis(triplet NATIVE ${B})                       # ignored: first wins
__FetchLayer_axis_get(triplet NATIVE _native)
expect("first declaration wins" "${_native}" "${A}")

FetchLayer_DeclareAxis(python NATIVE 3.12 VALUES 3.11 3.12)
__FetchLayer_axis_get(python VALUES _values)
expect("values" "${_values}" "3.11;3.12")

# variants: the triplet first, then the others by name; values back
__FetchLayer_variant_format(_variant python=3.12 triplet=${A})
expect("variant, triplet and python" "${_variant}" "${A}+python=3.12")
__FetchLayer_variant_format(_variant triplet=${A})
expect("variant, triplet alone: the triplet" "${_variant}" "${A}")
__FetchLayer_variant_format(_variant python=3.12)
expect("variant, no triplet" "${_variant}" "python=3.12")
__FetchLayer_variant_format(_variant)
expect("variant, no axis" "${_variant}" "any")
__FetchLayer_variant_parse("${A}+python=3.12" _pairs)
expect("values of a variant" "${_pairs}" "triplet=${A};python=3.12")
__FetchLayer_variant_extract("${A}+python=3.12" python _python)
expect("value of an axis" "${_python}" "3.12")

# native: every axis at its native value
__FetchLayer_variant_native("${A}+python=3.12" _native)
expect("native" "${_native}" "TRUE")
__FetchLayer_variant_native("${A}+python=3.11" _native)
expect("another python is not native" "${_native}" "FALSE")
__FetchLayer_variant_native("${B}" _native)
expect("another triplet is not native" "${_native}" "FALSE")
__FetchLayer_variant_native("any" _native)
expect("no axis is native" "${_native}" "TRUE")

# stagings: the variants to make available; a dependency's variant by its own axes
FetchLayer_Declare(core REVISION 0000000000000000000000000000000000000000)
FetchLayer_DeclareStaging(runtime LAYER core)                                       # triplet by default
FetchLayer_DeclareStaging(binding LAYER core AXES triplet python DEPENDS runtime)
FetchLayer_DeclareStaging(schema  LAYER core AXES)                                  # none
__FetchLayer_staging_get(runtime AXES _axes)
expect("axes by default" "${_axes}" "triplet")
__FetchLayer_staging_get(binding AXES _axes)
expect("axes declared" "${_axes}" "triplet;python")
__FetchLayer_staging_get(binding DEPENDS _depends)
expect("DEPENDS after AXES" "${_depends}" "runtime")
__FetchLayer_staging_get(schema AXES _axes)
expect("axes declared empty" "${_axes}" "")
__FetchLayer_variant_list(runtime _variants)
expect("variants, triplet" "${_variants}" "${A}")
__FetchLayer_variant_list(binding _variants)
expect("variants, triplet × python" "${_variants}" "${A}+python=3.11;${A}+python=3.12")
__FetchLayer_variant_list(schema _variants)
expect("variants, no axis" "${_variants}" "any")
__FetchLayer_variant_select(runtime "${A}+python=3.11" _dependency)
expect("a dependency by its own axes" "${_dependency}" "${A}")
__FetchLayer_variant_select(binding "${A}" _variant)
expect("an axis missing takes its native value" "${_variant}" "${A}+python=3.12")
__FetchLayer_variant_select(schema "${A}+python=3.11" _variant)
expect("a dependency without axes" "${_variant}" "any")
