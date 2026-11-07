# The first iteration of FetchLayer against a filled store: the core and the four module layers,
# prebuilt, for this machine's triplet.
#   cmake -S tests/fetchlayer -B build/fetchlayer -G Ninja -DFETCHLAYER_STORE=$PWD/build/store \
#         -DFETCHLAYER_TRIPLET=x86_64-macos-apple-clang-21-release
cmake_minimum_required(VERSION 3.25)
project(fetchlayer_test LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/FetchLayer.cmake")
set(FETCHLAYER_IDENTITY_REVISION_KEY   "org.opencontainers.image.revision")
set(FETCHLAYER_IDENTITY_DEPENDENCY_KEY "com.opendaq.dependencies.<name>.revision")
set(FETCHLAYER_IDENTITY_AXIS_KEY       "com.opendaq.package.<axis>")

FetchLayer_Declare(openDAQ                  REVISION 3039ee6d068c6c5e6e4d3de367c91820088ab30e)
FetchLayer_Declare(OpcUaModules             REVISION ad11c59ad43348f7099b794d8d8c5c94b8e9ccf5)
FetchLayer_Declare(MQTTStreamingModule      REVISION 892f654d11a1dac7b18f9f21265c148010568c59)
FetchLayer_Declare(LTStreamingModulesModern REVISION caa7a57c3a6f838bcf1477b96937073ef4b2b0e3)
FetchLayer_Declare(ASAM-CMP-Modules         REVISION 2f643a2c83f59ade54c156900e1f1088268429bb)
FetchLayer_Declare(openDAQ                  REVISION 0000000000000000000000000000000000000000)   # ignored: first wins

FetchLayer_DeclareStaging(opendaq              LAYER openDAQ FIND_PACKAGE_ARGS NAMES openDAQ)
FetchLayer_DeclareStaging(opcua-modules        LAYER OpcUaModules             DEPENDS opendaq)
FetchLayer_DeclareStaging(mqtt-module          LAYER MQTTStreamingModule      DEPENDS opendaq)
FetchLayer_DeclareStaging(lt-streaming-modules LAYER LTStreamingModulesModern DEPENDS opendaq)
FetchLayer_DeclareStaging(asam-cmp-modules     LAYER ASAM-CMP-Modules         DEPENDS opendaq)
FetchLayer_DeclareStaging(opendaq              LAYER OpcUaModules)   # ignored: first wins

FetchLayer_MakeAvailable(opendaq opcua-modules mqtt-module lt-streaming-modules asam-cmp-modules)

foreach(_l opendaq opcua-modules mqtt-module lt-streaming-modules asam-cmp-modules)
    FetchLayer_GetProperties(${_l})
    message(STATUS "${_l}: ${${_l}_ORIGIN} ${${_l}_IDENTITY_MATCH} rev=${${_l}_REVISION} deps=${${_l}_DEPENDS_REVISIONS}")
    message(STATUS "    components=${${_l}_INSTALL_COMPONENTS}")
endforeach()
foreach(_t daq::opendaq opcua-modules::opcua_client_module asam-cmp-modules::asam_cmp_capture_module)
    if (TARGET ${_t})
        message(STATUS "target ${_t}: yes")
    else()
        message(SEND_ERROR "target ${_t}: missing")
    endif()
endforeach()

# links against the core from the store and loads the modules from it
add_executable(smoke smoke.cpp)
target_link_libraries(smoke PRIVATE daq::opendaq)
FetchLayer_GetProperties(opcua-modules)
get_filename_component(_modules "${opcua-modules_PREFIX}/lib/modules" ABSOLUTE)
target_compile_definitions(smoke PRIVATE MODULES_DIR="${_modules}")
FetchLayer_GetProperties(opendaq)
set_target_properties(smoke PROPERTIES BUILD_RPATH "${opendaq_PREFIX}/lib")
