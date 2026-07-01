# Standalone test target for the pure Win32 mutex seam.
#
# Independent of the Flutter plugin build: mutex_guard.cpp has no Flutter
# dependency (only the Win32 API), so it compiles and runs with just a C++17
# toolchain plus the Windows SDK. Build and run with:
#
#   cmake -S windows/test -B build/win-test -G Ninja
#   cmake --build build/win-test
#   ctest --test-dir build/win-test --output-on-failure
#
cmake_minimum_required(VERSION 3.14)
project(flutter_alone_windows_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz
)
# Match gtest's CRT to the test target under MSVC.
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

enable_testing()

add_executable(mutex_guard_test
  mutex_guard_test.cpp
  ../mutex_guard.cpp
)
target_include_directories(mutex_guard_test PRIVATE ..)
target_link_libraries(mutex_guard_test PRIVATE GTest::gtest_main)
# Advapi32 provides the SDDL security-descriptor helpers used by MutexGuard.
target_link_libraries(mutex_guard_test PRIVATE Advapi32)

add_executable(message_utils_test
  message_utils_test.cpp
  ../message_utils.cpp
)
target_include_directories(message_utils_test PRIVATE ..)
target_link_libraries(message_utils_test PRIVATE GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(mutex_guard_test)
gtest_discover_tests(message_utils_test)
