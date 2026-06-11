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

# fetch the cmake utilities first, as they are used by the other modules
FetchContent_Declare(
    opendaq-cmake-utils
    GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
    GIT_TAG        v1.0.1
    GIT_PROGRESS   ON
)
FetchContent_MakeAvailable(opendaq-cmake-utils)

FetchContent_Declare(
    opendaq
    GIT_REPOSITORY https://github.com/openDAQ/openDAQ.git
    GIT_TAG        v3.40.0
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
    GIT_TAG        v4.0.1
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
    GIT_TAG        v0.2.0
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
    ltstreamingmoduleslegacy
    GIT_REPOSITORY https://github.com/openDAQ/LTStreamingModulesLegacy.git
    GIT_TAG        v4.0.0
    GIT_PROGRESS   ON
    GIT_SHALLOW    OFF
    SOURCE_SUBDIR  "INVALID"
    GIT_REMOTE_UPDATE_STRATEGY CHECKOUT
)

set(DAQMODULES_LT_STREAMING_ENABLE_TESTS  ${${REPO_OPTION_PREFIX}_ENABLE_TESTS} CACHE BOOL "" FORCE)
set(DAQMODULES_LT_STREAMING_ENABLE_EXAMPLE_APP OFF CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_CLIENT ON CACHE BOOL "")
set(DAQMODULES_LT_STREAMING_ENABLE_SERVER ON CACHE BOOL "")

FetchContent_MakeAvailable(ltstreamingmoduleslegacy)
include("${ltstreamingmoduleslegacy_SOURCE_DIR}/external/boost/Boost.cmake" OPTIONAL)
endif()

if (${REPO_OPTION_PREFIX}_ENABLE_ASAM_CMP_MODULE)
FetchContent_Declare(
    asamcmpmodules
    GIT_REPOSITORY https://github.com/openDAQ/ASAM-CMP-Modules.git
    GIT_TAG        v1.2.0
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
add_subdirectory(${ltstreamingmoduleslegacy_SOURCE_DIR} ${ltstreamingmoduleslegacy_BINARY_DIR})
add_subdirectory(${asamcmpmodules_SOURCE_DIR} ${asamcmpmodules_BINARY_DIR})

# Re-apply openDAQ's CPack config; ASAM-CMP-Modules' include(CPack) overrides it otherwise.
include("${opendaq_SOURCE_DIR}/cmake/Packing.cmake")

if(WIN32)
    # Packing.cmake pointed NSIS icons at ${CMAKE_CURRENT_SOURCE_DIR}/media/ (= bundle, no
    # such dir). Repoint at openDAQ's media and re-finalize CPack so makensis can find them.
    set(CPACK_NSIS_MUI_ICON "${opendaq_SOURCE_DIR}/media/opendaq.ico")
    set(CPACK_NSIS_MUI_UNIICON "${opendaq_SOURCE_DIR}\\media\\opendaq.ico")
    set(CPACK_NSIS_MUI_HEADERIMAGE "${opendaq_SOURCE_DIR}\\media\\nsis_header.bmp")
    set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${opendaq_SOURCE_DIR}\\media\\nsis_welcome.bmp")
    include(CPack)
endif()
