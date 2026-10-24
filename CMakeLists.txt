set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
cmake_minimum_required(VERSION 3.25)

set(REPO_NAME ReleaseRepo)
set(REPO_OPTION_PREFIX RELEASE_REPO)
set(CMAKE_FOLDER "${CMAKE_FOLDER}/${REPO_NAME}")


list(APPEND CMAKE_MESSAGE_CONTEXT ${REPO_NAME})

project(${REPO_NAME} VERSION "1.0.0" LANGUAGES CXX)

option(${REPO_OPTION_PREFIX}_ENABLE_TESTS "Enable testing" OFF)
option(${REPO_OPTION_PREFIX}_ENABLE_OPCUA_MODULE "Enable OPC UA module" ON)
option(${REPO_OPTION_PREFIX}_ENABLE_MQTT_MODULE "Enable MQTT module" ON)
option(${REPO_OPTION_PREFIX}_ENABLE_LT_MODULE "Enable LT streaming module" ON)
option(${REPO_OPTION_PREFIX}_ENABLE_ASAM_CMP_MODULE "Enable ASAM-CMP modules" ON)

include(FetchContent)

# the cmake utilities first: the triplet, Boost, and what the layers built here use; the tag the core takes
FetchContent_Declare(
    opendaq-cmake-utils
    GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
    GIT_TAG        v1.1.3
    GIT_PROGRESS   ON
)
FetchContent_MakeAvailable(opendaq-cmake-utils)

# The bundle by FetchLayer: the stagings named, from where the policy says; prebuilt only for now, the source
# build below stays until FetchLayer compiles
set(BUNDLE_STAGINGS "" CACHE STRING "The stagings to make available, dependencies first; empty: the source build below")
if (BUNDLE_STAGINGS)
    include(cmake/FetchLayer.cmake)
    # the identity keys are the annotations staging-push writes
    set(FETCHLAYER_IDENTITY_REVISION_KEY   "org.opencontainers.image.revision")
    set(FETCHLAYER_IDENTITY_DEPENDENCY_KEY "com.opendaq.dependencies.<name>.revision")
    set(FETCHLAYER_IDENTITY_AXIS_KEY       "com.opendaq.package.<axis>")

    include(cmake/Layers.cmake)
    FetchLayer_MakeAvailable(${BUNDLE_STAGINGS})
    include(cmake/Packing.cmake)
    return()
endif()

FetchContent_Declare(
    opendaq
    GIT_REPOSITORY https://github.com/openDAQ/openDAQ.git
    GIT_TAG main
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(OPENDAQ_ENABLE_OPCUA OFF CACHE BOOL "")
set(OPENDAQ_ENABLE_OPCUA_INTEGRATION_TESTS OFF CACHE BOOL "")

set(OPENDAQ_GENERATE_DELPHI_BINDINGS OFF CACHE BOOL "" FORCE)
set(OPENDAQ_GENERATE_PYTHON_BINDINGS ON CACHE BOOL "")
set(OPENDAQ_GENERATE_CSHARP_BINDINGS ON CACHE BOOL "")
set(OPENDAQ_GENERATE_C_BINDINGS ON CACHE BOOL "")

set(OPENDAQ_ENABLE_TESTS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_TEST_UTILS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_OPTIONAL_TESTS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_COVERAGE OFF CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_REGRESSION_TESTS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_UNSTABLE_TEST_LABELS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)

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

set(OPENDAQ_ENABLE_NATIVE_STREAMING ON CACHE BOOL "")
set(OPENDAQ_ENABLE_WEBSOCKET_STREAMING OFF CACHE BOOL "")

set(OPENDAQ_DOCUMENTATION_TESTS OFF CACHE BOOL "" FORCE)
set(OPENDAQ_ENABLE_PYTHON_BINDINGS_TESTS OFF CACHE BOOL "" FORCE)
set(APP_ENABLE_WEBPAGE_EXAMPLES OFF CACHE BOOL "")

FetchContent_MakeAvailable(opendaq)
include("${opendaq_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)

if (${REPO_OPTION_PREFIX}_ENABLE_OPCUA_MODULE)
FetchContent_Declare(
    opcuamodules
    GIT_REPOSITORY https://github.com/openDAQ/OpcUaModules.git
    GIT_TAG        main
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(DAQMODULES_OPCUA_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_TESTS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(DAQMODULES_OPCUA_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_SERVER ON CACHE BOOL "")
set(DAQMODULES_OPCUA_ENABLE_GENERIC_CLIENT ON CACHE BOOL "")

FetchContent_MakeAvailable(opcuamodules)
include("${opcuamodules_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endif()

if (${REPO_OPTION_PREFIX}_ENABLE_MQTT_MODULE)
FetchContent_Declare(
    mqttmodule
    GIT_REPOSITORY https://github.com/openDAQ/MQTTStreamingModule.git
    GIT_TAG        main
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(DAQMODULES_MQTT_ENABLE_TESTS ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(DAQMODULES_MQTT_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_MQTT_ENABLE_SSL OFF CACHE BOOL "")

FetchContent_MakeAvailable(mqttmodule)
include("${mqttmodule_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endif()


if (${REPO_OPTION_PREFIX}_ENABLE_LT_MODULE)
FetchContent_Declare(
    ltstreamingmodulesmodern
    GIT_REPOSITORY https://github.com/openDAQ/LTStreamingModulesModern.git
    GIT_TAG        main
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(DAQMODULES_LT_STREAMING_ENABLE_TESTS  ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(DAQMODULES_LT_STREAMING_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_SERVER ON CACHE BOOL "")

FetchContent_MakeAvailable(ltstreamingmodulesmodern)
include("${ltstreamingmodulesmodern_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endif()

if (${REPO_OPTION_PREFIX}_ENABLE_ASAM_CMP_MODULE)
FetchContent_Declare(
    asamcmpmodules
    GIT_REPOSITORY https://github.com/openDAQ/ASAM-CMP-Modules.git
    GIT_TAG        main
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(ASAM_CMP_ENABLE_TESTS  ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(ASAM_CMP_ENABLE_EXAMPLE OFF CACHE BOOL "")
set(ASAM_CMP_BUILD_DATA_SINK ON CACHE BOOL "")
set(ASAM_CMP_BUILD_CAPTURE_MODULE ON CACHE BOOL "")

FetchContent_MakeAvailable(asamcmpmodules)
include("${asamcmpmodules_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endif()

# add the subdirectories for the core and modules
add_subdirectory(${opendaq_SOURCE_DIR} ${opendaq_BINARY_DIR})
add_subdirectory(${opcuamodules_SOURCE_DIR} ${opcuamodules_BINARY_DIR})
add_subdirectory(${mqttmodule_SOURCE_DIR} ${mqttmodule_BINARY_DIR})
add_subdirectory(${ltstreamingmodulesmodern_SOURCE_DIR} ${ltstreamingmodulesmodern_BINARY_DIR})
add_subdirectory(${asamcmpmodules_SOURCE_DIR} ${asamcmpmodules_BINARY_DIR})
