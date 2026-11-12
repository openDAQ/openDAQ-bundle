##
## What the bundle is made of: one bundle_declare per layer — a repository, named as in bundle.json — with its
## staging, and its settings, which matter only when the layer is built here (cmake/Bundle.cmake).
##
## The revisions, one per layer — a full sha, a tag or a branch — from bundle.json; BUNDLE_REVISION_<LAYER>, the
## name upper-cased, in place of one (a preset or -D).
##

include_guard(GLOBAL)


# === the layers ==============================================================================================

# a layer's revision: BUNDLE_REVISION_<LAYER> when given, else bundle.json's — read at every configure, so an edit
# of it is taken without clearing the cache
set(_bundle_json "${CMAKE_CURRENT_LIST_DIR}/../bundle.json")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_bundle_json}")
file(READ "${_bundle_json}" _bundle)
foreach(_layer openDAQ OpcUaModules MQTTStreamingModule LTStreamingModulesModern ASAM-CMP-Modules)
    string(TOUPPER "${_layer}" _upper)
    set(BUNDLE_REVISION_${_upper} "" CACHE STRING "The revision of ${_layer}: a full sha, a tag or a branch; empty: bundle.json's")
    if (NOT BUNDLE_REVISION_${_upper})
        string(JSON BUNDLE_REVISION_${_upper} ERROR_VARIABLE _error GET "${_bundle}" layers "${_layer}")
        if (_error)
            message(FATAL_ERROR "bundle.json names no revision of ${_layer}: ${_error}")
        endif()
    endif()
endforeach()


# === the core ================================================================================================

bundle_declare(openDAQ STAGING opendaq)

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

bundle_declare(OpcUaModules STAGING opcua-modules)

set(DAQMODULES_OPCUA_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_SERVER ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_GENERIC_CLIENT ON CACHE BOOL "")

bundle_declare(MQTTStreamingModule STAGING mqtt-module)

set(DAQMODULES_MQTT_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_SSL OFF CACHE BOOL "")

bundle_declare(LTStreamingModulesModern STAGING lt-streaming-modules)

set(DAQMODULES_LT_STREAMING_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_SERVER ON CACHE BOOL "")

bundle_declare(ASAM-CMP-Modules STAGING asam-cmp-modules)

set(ASAM_CMP_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(ASAM_CMP_ENABLE_EXAMPLE OFF CACHE BOOL "")
set(ASAM_CMP_BUILD_DATA_SINK ON CACHE BOOL "")
set(ASAM_CMP_BUILD_CAPTURE_MODULE ON CACHE BOOL "")
