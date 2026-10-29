##
## Read by cpack for every generator (CPACK_PROJECT_CONFIG_FILE): an installer puts the bundle
## under /opt/opendaq, where the core installs itself; an archive holds the tree as it is.
##
## The package preset picks the stagings, BUNDLE_PACK_STAGINGS, and their components, BUNDLE_PACK_COMPONENTS
## (Runtime, Development): the install components Packing.cmake recorded for each, CPACK_BUNDLE_<staging>_<component>,
## the staging's name made a C identifier. The utils' config then names the package by CPACK_OPENDAQ_META_PACKAGE_NAME and writes its
## staging-meta.json.
##

if (CPACK_GENERATOR MATCHES "^(DEB|RPM|productbuild)$")
    set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/opendaq")
else()
    set(CPACK_PACKAGING_INSTALL_PREFIX "/")
endif()

if (NOT BUNDLE_PACK_STAGINGS OR NOT BUNDLE_PACK_COMPONENTS)
    message(FATAL_ERROR "cpack: pick what to pack, -D BUNDLE_PACK_STAGINGS=<staging>… -D BUNDLE_PACK_COMPONENTS=Runtime… "
                        "(a package preset does); the build has: ${CPACK_COMPONENTS_ALL}")
endif()
set(_picked)
foreach(_staging IN LISTS BUNDLE_PACK_STAGINGS)
    string(MAKE_C_IDENTIFIER "${_staging}" _c)
    set(_found FALSE)
    foreach(_component IN LISTS BUNDLE_PACK_COMPONENTS)
        if (CPACK_BUNDLE_${_c}_${_component})
            list(APPEND _picked ${CPACK_BUNDLE_${_c}_${_component}})
            set(_found TRUE)
        endif()
    endforeach()
    if (NOT _found)
        message(FATAL_ERROR "cpack: nothing of ${_staging} to pack (${BUNDLE_PACK_COMPONENTS}); the build has: ${CPACK_COMPONENTS_ALL}")
    endif()
endforeach()
# a macOS package carries the bundle's uninstall script (Packing.cmake)
if (CPACK_GENERATOR STREQUAL "productbuild")
    list(APPEND _picked bundle_Runtime)
endif()
set(CPACK_COMPONENTS_ALL ${_picked})

include("${CPACK_OPENDAQ_PROJECT_CONFIG}")
set(CPACK_PACKAGE_NAME "${CPACK_OPENDAQ_META_PACKAGE_NAME}")
set(CPACK_DEBIAN_FILE_NAME "${CPACK_PACKAGE_FILE_NAME}.deb")
