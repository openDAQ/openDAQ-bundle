set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
cmake_minimum_required(VERSION 3.25)

# the bundle's version, bundle.json's: the version of its packages and installers
file(READ "${CMAKE_CURRENT_LIST_DIR}/bundle.json" _bundle)
string(JSON _bundle_version GET "${_bundle}" version)
project(openDAQ-bundle VERSION ${_bundle_version} LANGUAGES CXX)

# The bundle: the stagings named, each from where the policy says — prebuilt from the store, or built from its
# layer's sources (cmake/FetchLayer.cmake). What the bundle is made of is cmake/Layers.cmake; how it is packed,
# cmake/Packing.cmake.
set(BUNDLE_STAGINGS "opendaq;opcua-modules;mqtt-module;lt-streaming-modules;asam-cmp-modules"
    CACHE STRING "The stagings to make available, dependencies first")
option(BUNDLE_ENABLE_TESTS "Build the layers' tests, for the layers built from sources" OFF)

include(FetchContent)

# the cmake utilities first: the triplet, Boost, and what the layers built here use; the tag the core takes
FetchContent_Declare(
    opendaq-cmake-utils
    GIT_REPOSITORY https://github.com/openDAQ/opendaq-cmake-utils.git
    GIT_TAG        v1.1.3
    GIT_PROGRESS   ON
)
FetchContent_MakeAvailable(opendaq-cmake-utils)

include(cmake/FetchLayer.cmake)
# the identity keys are the annotations staging-push writes
set(FETCHLAYER_IDENTITY_REVISION_KEY   "org.opencontainers.image.revision")
set(FETCHLAYER_IDENTITY_DEPENDENCY_KEY "com.opendaq.dependencies.<name>.revision")
set(FETCHLAYER_IDENTITY_AXIS_KEY       "com.opendaq.package.<axis>")

include(cmake/Layers.cmake)
FetchLayer_MakeAvailable(${BUNDLE_STAGINGS})
include(cmake/Packing.cmake)
