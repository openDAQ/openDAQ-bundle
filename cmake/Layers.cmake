##
## What the bundle is made of: the axes its stagings have variants by; one FetchLayer_Declare per layer — a
## repository, named as in the manifest — its stagings under it, and its settings — they matter only when the
## layer compiles here.
##
## From the cache (a preset or -D): the revisions, one per layer, BUNDLE_REVISION_<LAYER>, the name upper-cased —
## a full sha, a tag or a branch, main by default; and each axis's values, BUNDLE_AXIS_<AXIS>, and its own value where it can be
## given, BUNDLE_<AXIS>.
##

include_guard(GLOBAL)


# === the axes ================================================================================================

# triplet: this build's own, as the utils compose it; the ones made available, this build's own alone by default
set(BUNDLE_TRIPLET "" CACHE STRING "The triplet this build is for; empty: the one the utils compose")
set(BUNDLE_AXIS_TRIPLET "" CACHE STRING "The triplets to make available; empty: this build's own alone")
set(_triplet "${BUNDLE_TRIPLET}")
if (NOT _triplet)
    opendaq_compose_package_triplet(OUTPUT_VARIABLE _triplet)
endif()
FetchLayer_DeclareAxis(
    triplet
    NATIVE "${_triplet}"
    VALUES ${BUNDLE_AXIS_TRIPLET}
)


# === the layers ==============================================================================================

foreach(_layer openDAQ OpcUaModules MQTTStreamingModule LTStreamingModulesModern ASAM-CMP-Modules)
    string(TOUPPER "${_layer}" _upper)
    set(BUNDLE_REVISION_${_upper} "main" CACHE STRING "The revision of ${_layer} in the bundle: a full sha, a tag or a branch")
endforeach()


# === the core ================================================================================================

FetchLayer_Declare(
    openDAQ
    REVISION            "${BUNDLE_REVISION_OPENDAQ}"
    GIT_REPOSITORY      https://github.com/openDAQ/openDAQ.git
    POST_FETCH_INCLUDES <SOURCE_DIR>/external/boost/Boost.cmake
)
FetchLayer_DeclareStaging(
    opendaq
    LAYER             openDAQ
    FIND_PACKAGE_ARGS NAMES openDAQ
)

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
# the core's own modules, as main had them; built only when the core comes from sources — its staging has none,
# they are to be a staging of their own (opendaq-modules)
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

FetchLayer_Declare(
    OpcUaModules
    REVISION            "${BUNDLE_REVISION_OPCUAMODULES}"
    GIT_REPOSITORY      https://github.com/openDAQ/OpcUaModules.git
    POST_FETCH_INCLUDES <SOURCE_DIR>/external/boost/Boost.cmake
)
FetchLayer_DeclareStaging(
    opcua-modules
    LAYER   OpcUaModules
    DEPENDS opendaq
)

set(DAQMODULES_OPCUA_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_SERVER ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_GENERIC_CLIENT ON CACHE BOOL "")

FetchLayer_Declare(
    MQTTStreamingModule
    REVISION            "${BUNDLE_REVISION_MQTTSTREAMINGMODULE}"
    GIT_REPOSITORY      https://github.com/openDAQ/MQTTStreamingModule.git
    POST_FETCH_INCLUDES <SOURCE_DIR>/external/boost/Boost.cmake
)
FetchLayer_DeclareStaging(
    mqtt-module
    LAYER   MQTTStreamingModule
    DEPENDS opendaq
)

set(DAQMODULES_MQTT_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_SSL OFF CACHE BOOL "")

FetchLayer_Declare(
    LTStreamingModulesModern
    REVISION            "${BUNDLE_REVISION_LTSTREAMINGMODULESMODERN}"
    GIT_REPOSITORY      https://github.com/openDAQ/LTStreamingModulesModern.git
    POST_FETCH_INCLUDES <SOURCE_DIR>/external/boost/Boost.cmake
)
FetchLayer_DeclareStaging(
    lt-streaming-modules
    LAYER   LTStreamingModulesModern
    DEPENDS opendaq
)

set(DAQMODULES_LT_STREAMING_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_SERVER ON CACHE BOOL "")

FetchLayer_Declare(
    ASAM-CMP-Modules
    REVISION            "${BUNDLE_REVISION_ASAM-CMP-MODULES}"
    GIT_REPOSITORY      https://github.com/openDAQ/ASAM-CMP-Modules.git
    POST_FETCH_INCLUDES <SOURCE_DIR>/external/boost/Boost.cmake
)
FetchLayer_DeclareStaging(
    asam-cmp-modules
    LAYER   ASAM-CMP-Modules
    DEPENDS opendaq
)

set(ASAM_CMP_ENABLE_TESTS ${BUNDLE_ENABLE_TESTS} CACHE BOOL "")
set(ASAM_CMP_ENABLE_EXAMPLE OFF CACHE BOOL "")
set(ASAM_CMP_BUILD_DATA_SINK ON CACHE BOOL "")
set(ASAM_CMP_BUILD_CAPTURE_MODULE ON CACHE BOOL "")
