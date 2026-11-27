##
## Every layer built here from its sources (BUNDLE_FROM=SOURCES), in the order BUNDLE_LAYERS gives, the core first:
## where each layer's sources are (FetchContent_Declare, at its revision), its settings, and how it is added.
##
## FetchContent_MakeAvailable downloads them only (they are declared with a SOURCE_SUBDIR that does not exist). Then
## each layer's external/boost/Boost.cmake is included: Boost is built once, by the core, with the components every
## layer has asked for by then, so all of them ask before the core is added. Then each layer is added, SYSTEM, so its
## headers do not turn its warnings into the consumers' errors.
##
## A layer's install components are those that appear while it is added; what it installs with no COMPONENT goes to
## <c>_Development. They are kept for Packing.cmake as BUNDLE_COMPONENTS_<c>, <c> the staging's name made a C
## identifier.
##

include_guard(GLOBAL)


# === the sources =============================================================================================

# each layer's sources, downloaded only by FetchContent_MakeAvailable: a SOURCE_SUBDIR that does not exist, so they
# are added below, after every layer's Boost.cmake
FetchContent_Declare(openDAQ                  GIT_REPOSITORY https://github.com/openDAQ/openDAQ.git                  GIT_TAG ${BUNDLE_REVISION_OPENDAQ}                  SOURCE_SUBDIR _download_only_)
FetchContent_Declare(OpcUaModules             GIT_REPOSITORY https://github.com/openDAQ/OpcUaModules.git             GIT_TAG ${BUNDLE_REVISION_OPCUAMODULES}             SOURCE_SUBDIR _download_only_)
FetchContent_Declare(MQTTStreamingModule      GIT_REPOSITORY https://github.com/openDAQ/MQTTStreamingModule.git      GIT_TAG ${BUNDLE_REVISION_MQTTSTREAMINGMODULE}      SOURCE_SUBDIR _download_only_)
FetchContent_Declare(LTStreamingModulesModern GIT_REPOSITORY https://github.com/openDAQ/LTStreamingModulesModern.git GIT_TAG ${BUNDLE_REVISION_LTSTREAMINGMODULESMODERN} SOURCE_SUBDIR _download_only_)
FetchContent_Declare(ASAM-CMP-Modules         GIT_REPOSITORY https://github.com/openDAQ/ASAM-CMP-Modules.git         GIT_TAG ${BUNDLE_REVISION_ASAM-CMP-MODULES}         SOURCE_SUBDIR _download_only_)


# === the core ================================================================================================

set(OPENDAQ_ENABLE_OPCUA OFF CACHE BOOL "")
set(OPENDAQ_GENERATE_DELPHI_BINDINGS OFF CACHE BOOL "")
set(OPENDAQ_GENERATE_PYTHON_BINDINGS ON CACHE BOOL "")
set(OPENDAQ_GENERATE_CSHARP_BINDINGS ON CACHE BOOL "")
set(OPENDAQ_GENERATE_C_BINDINGS ON CACHE BOOL "")
set(OPENDAQ_ENABLE_NATIVE_STREAMING ON CACHE BOOL "")
set(OPENDAQ_ENABLE_WEBSOCKET_STREAMING OFF CACHE BOOL "")
set(OPENDAQ_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(OPENDAQ_DOCUMENTATION_TESTS OFF CACHE BOOL "")
set(APP_ENABLE_WEBPAGE_EXAMPLES OFF CACHE BOOL "")
# the core's own modules, as its staging has them; built only when the core comes from sources
set(DAQMODULES_EMPTY_MODULE ON CACHE BOOL "")
set(DAQMODULES_OPENDAQ_CLIENT_MODULE ON CACHE BOOL "")
set(DAQMODULES_OPENDAQ_SERVER_MODULE ON CACHE BOOL "")
set(DAQMODULES_REF_DEVICE_MODULE ON CACHE BOOL "")
set(DAQMODULES_SIMULATOR_DEVICE_MODULE ON CACHE BOOL "")
set(DAQMODULES_REF_FB_MODULE ON CACHE BOOL "")
set(DAQMODULES_AUDIO_DEVICE_MODULE ON CACHE BOOL "")
set(DAQMODULES_BASIC_CSV_RECORDER_MODULE ON CACHE BOOL "")
set(DAQMODULES_LICENSING_MODULE ON CACHE BOOL "")
set(DAQMODULES_PARQUET_RECORDER_MODULE OFF CACHE BOOL "")


# === the modules =============================================================================================

# OpcUaModules
set(DAQMODULES_OPCUA_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_SERVER ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_GENERIC_CLIENT ON CACHE BOOL "")

# MQTTStreamingModule
set(DAQMODULES_MQTT_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_SSL OFF CACHE BOOL "")

# LTStreamingModulesModern
set(DAQMODULES_LT_STREAMING_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_SERVER ON CACHE BOOL "")

# ASAM-CMP-Modules
set(ASAM_CMP_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(ASAM_CMP_ENABLE_EXAMPLE OFF CACHE BOOL "")
set(ASAM_CMP_BUILD_DATA_SINK ON CACHE BOOL "")
set(ASAM_CMP_BUILD_CAPTURE_MODULE ON CACHE BOOL "")


# === built here ==============================================================================================

set(_layers)
foreach(_entry IN LISTS BUNDLE_LAYERS)
    string(REPLACE "=" ";" _pair "${_entry}")
    list(GET _pair 0 _layer)
    list(APPEND _layers ${_layer})
endforeach()
FetchContent_MakeAvailable(${_layers})

foreach(_layer IN LISTS _layers)
    string(TOLOWER "${_layer}" _lower)
    include("${${_lower}_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endforeach()

foreach(_entry IN LISTS BUNDLE_LAYERS)
    string(REPLACE "=" ";" _pair "${_entry}")
    list(GET _pair 0 _layer)
    list(GET _pair 1 _staging)
    string(TOLOWER "${_layer}" _lower)
    string(MAKE_C_IDENTIFIER "${_staging}" _c)

    get_cmake_property(_before COMPONENTS)
    set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "${_c}_Development")
    add_subdirectory("${${_lower}_SOURCE_DIR}" "${${_lower}_BINARY_DIR}" SYSTEM)
    get_cmake_property(_components COMPONENTS)
    if (_before)
        list(REMOVE_ITEM _components ${_before})
    endif()
    set_property(GLOBAL PROPERTY BUNDLE_COMPONENTS_${_c} "${_components}")
endforeach()
unset(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME)
