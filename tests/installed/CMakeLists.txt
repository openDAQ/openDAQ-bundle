##
## A smoke check of an installed bundle: built against an installed prefix (an installer's, or one unpacked),
## not against the build tree. The C++ API and the C binding each load every module of the prefix.
##
##   cmake -S tests/installed -B build/installed [-DOPENDAQ_PREFIX=/opt/opendaq] [-DEXPECT_MODULES=14]
##   cmake --build build/installed && ctest --test-dir build/installed --output-on-failure
##

cmake_minimum_required(VERSION 3.25)
project(installed-smoke C CXX)

set(OPENDAQ_PREFIX "/opt/opendaq" CACHE PATH "Where the bundle is installed")
set(EXPECT_MODULES "" CACHE STRING "How many modules must load; empty: at least one")

find_package(openDAQ REQUIRED PATHS "${OPENDAQ_PREFIX}" NO_DEFAULT_PATH)

if (WIN32)
    set(_modules "${OPENDAQ_PREFIX}/bin/modules")
else()
    set(_modules "${OPENDAQ_PREFIX}/lib/modules")
endif()

# the C++ API: an instance loads the modules
add_executable(modules modules.cpp)
target_link_libraries(modules PRIVATE daq::opendaq)
set(_expect 0)
if (EXPECT_MODULES)
    set(_expect ${EXPECT_MODULES})
endif()
target_compile_definitions(modules PRIVATE MODULES_DIR="${_modules}" EXPECT_MODULES=${_expect})

# the C binding: the same, through copendaq
add_executable(c_binding c_binding.c)
target_link_libraries(c_binding PRIVATE daq::copendaq)
target_compile_definitions(c_binding PRIVATE MODULES_DIR="${_modules}" EXPECT_MODULES=${_expect})

set_target_properties(modules c_binding PROPERTIES BUILD_RPATH "${OPENDAQ_PREFIX}/lib")

enable_testing()
add_test(NAME modules COMMAND modules)
add_test(NAME c_binding COMMAND c_binding)
if (WIN32)
    set_tests_properties(modules c_binding PROPERTIES ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:${OPENDAQ_PREFIX}/bin")
endif()
