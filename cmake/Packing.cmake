##
## The bundle's targets as packages. A package preset picks what goes in — stagings × components — and the
## generator and the name; see CPackOptions.cmake. The utils name the package <name>-<version>-<triplet>,
## as the core's and the modules', and write staging-meta.json next to it.
##
##   cpack --preset core       opendaq × Runtime, Development
##   cpack --preset modules    the four module stagings × Runtime
##

include_guard(GLOBAL)

set(BUNDLE_VERSION "${PROJECT_VERSION}" CACHE STRING "Version of the bundle, the version of its packages")

# each staging's install components, of this build's own variant, by what they are for: Runtime when the name
# says so, Development else — prebuilt, <staging>_Runtime/_Development; from sources, the names the layer gave
# (openDAQ_opcua_client_module_Runtime, External); for CPackOptions.cmake to pick from at cpack time
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
# a macOS package's receipts, io.opendaq.bundle.<component>; by default from the vendor, with its spaces and dots
set(CPACK_PRODUCTBUILD_IDENTIFIER "io.opendaq.bundle")

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

# NSIS: the core's installer as it is (its images, the PATH page, the old version removed first), under a name and a
# registry key of the bundle's own, so it neither replaces nor uninstalls the core's
set(CPACK_PACKAGE_INSTALL_DIRECTORY "openDAQ")
set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "openDAQ bundle")
set(CPACK_NSIS_PACKAGE_NAME "openDAQ bundle")
set(CPACK_NSIS_DISPLAY_NAME "openDAQ bundle ${BUNDLE_VERSION}")
set(CPACK_NSIS_WELCOME_TITLE "Welcome to openDAQ Setup")
set(CPACK_NSIS_BRANDING_TEXT "${CPACK_PACKAGE_VENDOR}")
set(CPACK_NSIS_MUI_ICON "${PROJECT_SOURCE_DIR}/packaging/nsis/opendaq.ico")
set(CPACK_NSIS_MUI_UNIICON "${PROJECT_SOURCE_DIR}/packaging/nsis/opendaq.ico")
file(TO_NATIVE_PATH "${PROJECT_SOURCE_DIR}/packaging/nsis/nsis_header.bmp" CPACK_NSIS_MUI_HEADERIMAGE)        # NSIS wants \
file(TO_NATIVE_PATH "${PROJECT_SOURCE_DIR}/packaging/nsis/nsis_welcome.bmp" CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP)
set(CPACK_NSIS_MANIFEST_DPI_AWARE ON)
set(CPACK_NSIS_MODIFY_PATH ON)
set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

# A silent install (/S) shows no page, so it never adds to PATH; /PATH=AllUsers|CurrentUser|No chooses it on the
# command line, as the page would, and records it for the uninstaller:
#   opendaq-bundle-<version>-<triplet>.exe /S /PATH=AllUsers /D=C:\openDAQ        (/D last, unquoted)
# (CPack sets CPACK_NSIS_DEFINES itself, so no FileFunc.nsh: the option is looked for in $CMDLINE by hand)
set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS [=[
  StrCpy $R1 ""
  StrCpy $R2 0
  bundle_path_scan:
    StrCpy $R3 $CMDLINE 14 $R2
    StrCmp $R3 "/PATH=AllUsers" 0 +3
      StrCpy $R1 "AllUsers"
      Goto bundle_path_found
    StrCpy $R3 $CMDLINE 17 $R2
    StrCmp $R3 "/PATH=CurrentUser" 0 +3
      StrCpy $R1 "CurrentUser"
      Goto bundle_path_found
    StrCpy $R3 $CMDLINE 8 $R2
    StrCmp $R3 "/PATH=No" 0 +3
      StrCpy $R1 "No"
      Goto bundle_path_found
    IntOp $R2 $R2 + 1
    StrCpy $R3 $CMDLINE 1 $R2
    StrCmp $R3 "" bundle_path_done bundle_path_scan
  bundle_path_found:
    StrCpy $DO_NOT_ADD_TO_PATH 1
    StrCpy $ADD_TO_PATH_ALL_USERS 0
    StrCpy $ADD_TO_PATH_CURRENT_USER 0
    StrCmp $R1 "AllUsers" 0 +3
      StrCpy $DO_NOT_ADD_TO_PATH 0
      StrCpy $ADD_TO_PATH_ALL_USERS 1
    StrCmp $R1 "CurrentUser" 0 +3
      StrCpy $DO_NOT_ADD_TO_PATH 0
      StrCpy $ADD_TO_PATH_CURRENT_USER 1
    Push "DoNotAddToPath"
    Push "$DO_NOT_ADD_TO_PATH"
    Call ConditionalAddToRegistry
    Push "AddToPathAllUsers"
    Push "$ADD_TO_PATH_ALL_USERS"
    Call ConditionalAddToRegistry
    Push "AddToPathCurrentUser"
    Push "$ADD_TO_PATH_CURRENT_USER"
    Call ConditionalAddToRegistry
  bundle_path_done:
]=])

# the layers and components, the name and the install prefix, at cpack time
set(CPACK_PROJECT_CONFIG_FILE "${CMAKE_CURRENT_LIST_DIR}/CPackOptions.cmake")

include(CPack)

# macOS has no uninstall: the package brings a script that removes its files by its receipts, a component of the
# bundle's own, which CPackOptions.cmake adds to a productbuild package
if (APPLE)
    install(PROGRAMS "${PROJECT_SOURCE_DIR}/packaging/productbuild/uninstall-opendaq-bundle.sh" DESTINATION bin COMPONENT bundle_Runtime)
    cpack_add_component(bundle_Runtime DISPLAY_NAME "uninstall script" REQUIRED)
endif()

# an installer's choices (NSIS, productbuild): each module a choice of its own in the group Modules, selected;
# the rest required. A prebuilt staging has <staging>_Runtime, <staging>_Development and a <module>_Runtime per
# module (FetchLayer/import.cmake); a layer built here has no choices of its own, all its components required
cpack_add_component_group(modules DISPLAY_NAME "Modules" DESCRIPTION "openDAQ modules" EXPANDED)
foreach(_staging IN LISTS BUNDLE_STAGINGS)
    string(TOLOWER "${_staging}" _name)
    string(MAKE_C_IDENTIFIER "${_name}" _c)
    foreach(_component IN LISTS ${_name}_INSTALL_COMPONENTS)
        if (${_name}_PREFIX AND _component MATCHES "^(.+)_Runtime$" AND NOT _component STREQUAL "${_c}_Runtime")
            cpack_add_component(${_component} DISPLAY_NAME "${CMAKE_MATCH_1}" GROUP modules)
        elseif (_component MATCHES "_Runtime$")
            cpack_add_component(${_component} DISPLAY_NAME "${_name} runtime" REQUIRED)
        else()
            cpack_add_component(${_component} DISPLAY_NAME "${_name} development" REQUIRED)
        endif()
    endforeach()
endforeach()
