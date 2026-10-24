##
## The bundle's targets as packages. A package preset picks what goes in — stagings × components — and the
## generator and the name; see PackingProject.cmake. The utils name the package <name>-<version>-<triplet>,
## as the core's and the modules', and write staging-meta.json next to it.
##
##   cpack --preset core       opendaq × Runtime, Development
##   cpack --preset modules    the four module stagings × Runtime
##

include_guard(GLOBAL)

set(BUNDLE_VERSION "${PROJECT_VERSION}" CACHE STRING "Version of the bundle, the version of its packages")

# each staging's install components, of this build's own variant, by what they are for: Runtime when the name
# says so, Development else — prebuilt, <staging>_Runtime/_Development; from sources, the names the layer gave
# (openDAQ_opcua_client_module_Runtime, External); for PackingProject.cmake to pick from at cpack time
foreach(_staging IN LISTS BUNDLE_STAGINGS)
    FetchLayer_GetProperties(${_staging})
    string(TOLOWER "${_staging}" _name)
    string(MAKE_C_IDENTIFIER "${_name}" _c)
    set(CPACK_BUNDLE_${_c}_Runtime)
    set(CPACK_BUNDLE_${_c}_Development)
    foreach(_component IN LISTS ${_name}_INSTALL_COMPONENTS)
        if (_component MATCHES "_Runtime$")
            list(APPEND CPACK_BUNDLE_${_c}_Runtime ${_component})
        else()
            list(APPEND CPACK_BUNDLE_${_c}_Development ${_component})
        endif()
    endforeach()
endforeach()

# the name, the version and the triplet, by the utils; a package preset renames it
set(CPACK_OPENDAQ_META_PACKAGE_NAME "opendaq-bundle")
set(CPACK_OPENDAQ_META_PACKAGE_VERSION "${BUNDLE_VERSION}")
opendaq_detect_settings()
opendaq_detect_package()
__FetchLayer_axis_get(triplet NATIVE _triplet)                 # this build's own, BUNDLE_TRIPLET when given
opendaq_compose_package_triplet()
set(CPACK_OPENDAQ_META_PACKAGE_TRIPLET "${_triplet}")
opendaq_compose_package_file_name()

set(CPACK_PACKAGE_NAME "${CPACK_OPENDAQ_META_PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "openDAQ d.o.o.")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "openDAQ SDK with its modules")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://opendaq.io/")
set(CPACK_PACKAGE_CONTACT "info@opendaq.io")
set(CPACK_PACKAGE_VERSION "${BUNDLE_VERSION}")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/packages")

set(CPACK_GENERATOR TGZ)
set(CPACK_VERBATIM_VARIABLES ON)
set(CPACK_THREADS 0)

# the components picked go into one package
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_COMPONENTS_GROUPING ALL_COMPONENTS_IN_ONE)

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR} <${CPACK_PACKAGE_CONTACT}>")
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS_PRIVATE_DIRS "opt/opendaq/lib")

# the layers and components, the name and the install prefix, at cpack time
set(CPACK_PROJECT_CONFIG_FILE "${CMAKE_CURRENT_LIST_DIR}/PackingProject.cmake")

include(CPack)
