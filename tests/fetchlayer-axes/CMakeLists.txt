# Variants by two axes, triplet and python, against a store this test lays out itself; no network.
#   cmake -S tests/fetchlayer-axes -B build/fetchlayer-axes
# The layer's decision: -DWITHOUT_OWN_BINDING=ON leaves binding for python 3.12, this build's own, out of the
# store, so the layer core is to come from its sources — core too — or, with -DFETCHLAYER_BUILD=NEVER, fails.
cmake_minimum_required(VERSION 3.25)
project(fetchlayer_axes_test NONE)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/FetchLayer.cmake")

function(expect WHAT GOT WANT)
    if (GOT STREQUAL WANT)
        message(STATUS "ok    ${WHAT}: ${GOT}")
    else()
        message(SEND_ERROR "FAIL  ${WHAT}: ${GOT}, not ${WANT}")
    endif()
endfunction()

set(_triplet x86_64-macos-apple-clang-21-release)
set(_commit 1111111111111111111111111111111111111111)

FetchLayer_DeclareAxis(triplet NATIVE ${_triplet})
FetchLayer_DeclareAxis(python  NATIVE 3.12 VALUES 3.11 3.12)

FetchLayer_Declare(core REVISION ${_commit})
FetchLayer_DeclareStaging(core    LAYER core)
FetchLayer_DeclareStaging(binding LAYER core AXES triplet python DEPENDS core)

# the store: core for the triplet, binding for python 3.11 and 3.12 — each a directory with a library in it
set(FETCHLAYER_STORE "${CMAKE_BINARY_DIR}/store")
file(REMOVE_RECURSE "${FETCHLAYER_STORE}")
function(lay NAME VARIANT DEPENDS LIBRARY)
    set(r_NAME "${NAME}")
    set(r_REVISION "${_commit}")
    set(r_DEPENDS_REVISIONS "${DEPENDS}")
    set(r_VARIANT "${VARIANT}")
    __FetchLayer_identity_path(r _path)
    file(WRITE "${_path}/lib/${LIBRARY}" "")
endfunction()
lay(core    "${_triplet}"             ""                "libcore.dylib")
lay(binding "${_triplet}+python=3.11" "core=${_commit}" "binding.cpython-311-darwin.so")
if (NOT WITHOUT_OWN_BINDING)
    lay(binding "${_triplet}+python=3.12" "core=${_commit}" "binding.cpython-312-darwin.so")
endif()

FetchLayer_MakeAvailable(core binding)

# the layer's decision: every own variant asked for is in the store, so all prebuilt
__FetchLayer_layer_get(core ORIGIN _origin)
expect("the layer, prebuilt" "${_origin}" "system")

# the variants: one of core, two of binding — binding found in the store only if core, its dependency, was
# taken by its own axis alone: the path is the hash of core's commit
FetchLayer_GetProperties(core)
expect("core, its variants" "${core_VARIANTS}" "${_triplet}")
FetchLayer_GetProperties(binding)
expect("binding, its variants" "${binding_VARIANTS}" "${_triplet}+python=3.11;${_triplet}+python=3.12")

# binding by default: the own variant, python 3.12, installed
expect("binding, own variant" "${binding_VARIANT}" "${_triplet}+python=3.12")
expect("binding, own: python" "${binding_PYTHON}" "3.12")
expect("binding, own: triplet" "${binding_TRIPLET}" "${_triplet}")
expect("binding, own: exact" "${binding_IDENTITY_MATCH}" "EXACT")
expect("binding, own: installed" "${binding_INSTALL_COMPONENTS}" "binding_Runtime")
expect("binding, own: against core" "${binding_DEPENDS_REVISIONS}" "core=${_commit}")

# binding for python 3.11, by its axis: found, files only
FetchLayer_GetProperties(binding AXES python=3.11)
expect("binding 3.11, variant" "${binding_VARIANT}" "${_triplet}+python=3.11")
expect("binding 3.11, populated" "${binding_POPULATED}" "TRUE")
expect("binding 3.11, files only" "${binding_INSTALL_COMPONENTS}" "")
if (NOT EXISTS "${binding_PREFIX}/lib/binding.cpython-311-darwin.so")
    message(SEND_ERROR "FAIL  binding 3.11, prefix: ${binding_PREFIX}")
endif()

# by its string, as one of binding_VARIANTS
FetchLayer_GetProperties(binding VARIANT "${_triplet}+python=3.12")
expect("binding by its string" "${binding_PYTHON}" "3.12")
