# cmake -P tests/identity.cmake — the identity hash against values computed apart (Python, the registry tags)

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/FetchLayer/identity.cmake")

# the keys staging-push annotates packages with
set(FETCHLAYER_IDENTITY_REVISION_KEY   "org.opencontainers.image.revision")
set(FETCHLAYER_IDENTITY_DEPENDENCY_KEY "com.opendaq.dependencies.<name>.revision")
set(FETCHLAYER_IDENTITY_AXIS_KEY       "com.opendaq.package.<axis>")

set(_failed 0)
function(expect WHAT GOT WANT)
    if (GOT STREQUAL WANT)
        message(STATUS "ok    ${WHAT}")
    else()
        message(STATUS "FAIL  ${WHAT}\n        got  ${GOT}\n        want ${WANT}")
        set(_failed 1 PARENT_SCOPE)
    endif()
endfunction()

set(_core     3039ee6d068c6c5e6e4d3de367c91820088ab30e)
set(_opcua    ad11c59ad43348f7099b794d8d8c5c94b8e9ccf5)
set(_triplet  x86_64-macos-apple-clang-21-release)

# the core: no dependencies
set(core_NAME opendaq)
set(core_REVISION ${_core})
__FetchLayer_identity_hash(core idx _got)
expect("core, layer" "${_got}" "idx-371b0bd304e31a41c4d93940e84aa4630c7bbdb1ba1d5f9d6d3376c6e7930f1e")
set(core_VARIANT ${_triplet})
__FetchLayer_identity_hash(core pkg _got)
expect("core, build" "${_got}" "pkg-293b916ec80f1e85b403b0819e799ca6a873b109511e552f429ac56483db665c")

# a module against the core
set(opcua_NAME opcua-modules)
set(opcua_REVISION ${_opcua})
set(opcua_DEPENDS_REVISIONS "opendaq=${_core}")
__FetchLayer_identity_hash(opcua idx _got)
expect("module, layer" "${_got}" "idx-8bf766d81df141f0afbf3004975cb0996f54338dffeea01a05ac2a6ff8c3881e")
set(opcua_VARIANT ${_triplet})
__FetchLayer_identity_hash(opcua pkg _got)
expect("module, build" "${_got}" "pkg-e2337ceee0d7acbc2b20adc6e951948125d12f6ec737bc694ace919f142f6f0b")

# the order of the dependencies does not count
set(a_REVISION ${_opcua})
set(a_DEPENDS_REVISIONS "opendaq=${_core};libx=1111111")
set(b_REVISION ${_opcua})
set(b_DEPENDS_REVISIONS "libx=1111111;opendaq=${_core}")
__FetchLayer_identity_hash(a idx _a)
__FetchLayer_identity_hash(b idx _b)
expect("order of dependencies" "${_a}" "${_b}")

# another axis: a line of its own in the variant's hash; the staging's hash is the same
set(binding_NAME opendaq-python)
set(binding_REVISION ${_core})
set(binding_DEPENDS_REVISIONS "opendaq=${_core}")
__FetchLayer_identity_hash(binding idx _binding_idx)
set(binding_VARIANT "${_triplet}+python=3.12")
__FetchLayer_identity_hash(binding pkg _binding_312)
set(binding_VARIANT "${_triplet}+python=3.11")
__FetchLayer_identity_hash(binding pkg _binding_311)
if (_binding_312 STREQUAL _binding_311)
    expect("another python, another variant's hash" "${_binding_312}" "not ${_binding_311}")
else()
    expect("another python, another variant's hash" "" "")
endif()
set(_lines "com.opendaq.dependencies.opendaq.revision=${_core}\ncom.opendaq.package.python=3.12\ncom.opendaq.package.triplet=${_triplet}\norg.opencontainers.image.revision=${_core}")
string(SHA256 _want "${_lines}")
set(binding_VARIANT "${_triplet}+python=3.12")
__FetchLayer_identity_hash(binding pkg _got)
expect("a variant's hash is its annotations' lines" "${_got}" "pkg-${_want}")
set(binding_VARIANT "")
__FetchLayer_identity_hash(binding idx _got)
expect("a staging's hash leaves the variant out" "${_got}" "${_binding_idx}")

# the place in the store: the staging's hash, then the variant
set(FETCHLAYER_STORE /store)
__FetchLayer_identity_path(opcua _got)
expect("store path" "${_got}"
       "/store/opcua-modules/idx-8bf766d81df141f0afbf3004975cb0996f54338dffeea01a05ac2a6ff8c3881e/${_triplet}")

if (_failed)
    message(FATAL_ERROR "identity: some checks failed")
endif()
message(STATUS "identity: all checks passed")
