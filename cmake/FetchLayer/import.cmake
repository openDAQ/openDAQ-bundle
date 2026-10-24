##
## The strategy import: a prefix made available to this build.
##
## For this build's own variant, the prefix is installed under the staging's install components,
## <staging>_Runtime — shared libraries and modules — and <staging>_Development — the rest: headers, CMake
## configs, static and import libraries. When the prefix holds the staging's CMake package, it is found from
## the prefix only (find_package … GLOBAL), so its targets exist. Each module file becomes an imported MODULE
## target, <staging>::<module>.
## For another variant nothing is installed or imported: the prefix is only recorded, files for whoever
## lays them out (a multi-variant target).
##
## <staging> in a component name is the staging's name made a C identifier (opcua_modules_Runtime).
##

include_guard(GLOBAL)

set(_FETCHLAYER_RUNTIME_PATTERNS "*.so" "*.so.*" "*.dylib" "*.dll")

# __FetchLayer_import_make_available(<variant> <staging>…)
function(__FetchLayer_import_make_available VARIANT)
    foreach(_name IN LISTS ARGN)
        __FetchLayer_instance_get("${_name}" "${VARIANT}" PREFIX _prefix)
        __FetchLayer_variant_native("${VARIANT}" _native)
        if (NOT _native)
            __FetchLayer_instance_set("${_name}" "${VARIANT}" INSTALL_COMPONENTS "")
            continue()
        endif()
        string(MAKE_C_IDENTIFIER "${_name}" _c)
        set(_components)

        # the prefix's files, split: shared libraries and modules are Runtime, the rest Development;
        # file by file, so no empty directory lands in a component
        file(GLOB_RECURSE _files LIST_DIRECTORIES false RELATIVE "${_prefix}" "${_prefix}/*")
        set(_dirs)
        foreach(_f IN LISTS _files)
            get_filename_component(_n "${_f}" NAME)
            get_filename_component(_d "${_f}" DIRECTORY)
            set(_kind Development)
            foreach(_p IN LISTS _FETCHLAYER_RUNTIME_PATTERNS)
                string(REPLACE "." "\\." _rx "${_p}")
                string(REPLACE "*" ".*" _rx "${_rx}")
                if (_n MATCHES "^${_rx}$")
                    set(_kind Runtime)
                endif()
            endforeach()
            string(MAKE_C_IDENTIFIER "${_kind}_${_d}" _key)
            list(APPEND _files_${_key} "${_prefix}/${_f}")
            list(APPEND _dirs "${_kind}|${_d}")
        endforeach()
        list(REMOVE_DUPLICATES _dirs)
        foreach(_e IN LISTS _dirs)
            string(REPLACE "|" ";" _e "${_e}")
            list(GET _e 0 _kind)
            list(LENGTH _e _len)
            set(_d "")
            if (_len GREATER 1)
                list(GET _e 1 _d)
            endif()
            string(MAKE_C_IDENTIFIER "${_kind}_${_d}" _key)
            if (_d STREQUAL "")
                set(_d .)
            endif()
            install(FILES ${_files_${_key}} DESTINATION "${_d}" COMPONENT ${_c}_${_kind})
            list(APPEND _components ${_c}_${_kind})
        endforeach()
        list(REMOVE_DUPLICATES _components)

        # a module file → an imported MODULE target
        file(GLOB _modules "${_prefix}/lib/modules/*" "${_prefix}/bin/modules/*")
        foreach(_m IN LISTS _modules)
            get_filename_component(_file "${_m}" NAME)
            string(REGEX REPLACE "^lib" "" _stem "${_file}")
            string(REGEX REPLACE "(-[0-9]+-[0-9]+)?\\.module\\..*$" "" _stem "${_stem}")
            set(_target "${_name}::${_stem}")
            if (NOT TARGET ${_target})
                add_library(${_target} MODULE IMPORTED GLOBAL)
                set_target_properties(${_target} PROPERTIES IMPORTED_LOCATION "${_m}")
            endif()
        endforeach()

        # the staging's package, when the prefix holds it, found from the prefix only
        __FetchLayer_system_config("${_name}" "${_prefix}" _config)
        if (_config)
            __FetchLayer_staging_get("${_name}" FIND_PACKAGE_ARGS _args)
            cmake_parse_arguments(_find "" "" "NAMES" ${_args})
            set(_package "${_name}")
            if (_find_NAMES)
                list(GET _find_NAMES 0 _package)
            endif()
            list(PREPEND CMAKE_PREFIX_PATH "${_prefix}")   # for the package's own dependencies
            find_package(${_package} CONFIG REQUIRED GLOBAL BYPASS_PROVIDER PATHS "${_prefix}" NO_DEFAULT_PATH)
        endif()

        __FetchLayer_instance_set("${_name}" "${VARIANT}" INSTALL_COMPONENTS "${_components}")
    endforeach()
endfunction()
