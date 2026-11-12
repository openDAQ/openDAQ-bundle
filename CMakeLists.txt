set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
cmake_minimum_required(VERSION 3.25)

# the bundle's version, bundle.json's: the version of its packages and installers
file(READ "${CMAKE_CURRENT_LIST_DIR}/bundle.json" _bundle)
string(JSON _bundle_version GET "${_bundle}" version)
project(openDAQ-bundle VERSION ${_bundle_version} LANGUAGES CXX)

# The bundle: what it is made of (cmake/Layers.cmake); every layer built from its sources (cmake/Sources.cmake) or
# every staging taken prebuilt (cmake/Stagings.cmake), never a mix; how it is packed (cmake/Packing.cmake).
set(BUNDLE_FROM SOURCES CACHE STRING "Where the layers come from: SOURCES, built here; STAGINGS, prebuilt from BUNDLE_PREFIX_<STAGING>")
set_property(CACHE BUNDLE_FROM PROPERTY STRINGS SOURCES STAGINGS)
if (NOT BUNDLE_FROM MATCHES "^(SOURCES|STAGINGS)$")
    message(FATAL_ERROR "BUNDLE_FROM is SOURCES or STAGINGS, not ${BUNDLE_FROM}")
endif()
set(BUNDLE_STAGINGS "opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules"
    CACHE STRING "The stagings the bundle has")
option(BUNDLE_ENABLE_TESTS "Build the layers' tests, when they are built from sources" OFF)

include(FetchContent)

# the cmake utilities first: the triplet, Boost, and what the layers built here use; the tag the core takes
FetchContent_Declare(
    opendaq-cmake-utils
    GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
    GIT_TAG        v1.1.3
    GIT_PROGRESS   ON
)
FetchContent_MakeAvailable(opendaq-cmake-utils)

include(cmake/Layers.cmake)
if (BUNDLE_FROM STREQUAL "SOURCES")
    include(cmake/Sources.cmake)
else()
    include(cmake/Stagings.cmake)
endif()
include(cmake/Packing.cmake)
