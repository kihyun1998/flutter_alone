# Standalone test target for the pure-POSIX lock-file seam.
#
# This is intentionally independent of the Flutter/GTK plugin build: the seam
# (lock_file.cc) has no Flutter or GTK dependencies, so it can be compiled and
# run on any Linux runner with just a C++17 toolchain. Build and run with:
#
#   cmake -S linux/test -B build/linux-test -G Ninja
#   cmake --build build/linux-test
#   ctest --test-dir build/linux-test --output-on-failure
#
cmake_minimum_required(VERSION 3.14)
project(flutter_alone_linux_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz
)
FetchContent_MakeAvailable(googletest)

enable_testing()

add_executable(lock_file_test
  lock_file_test.cc
  ../lock_file.cc
)
target_include_directories(lock_file_test PRIVATE ..)
target_link_libraries(lock_file_test PRIVATE GTest::gtest_main)

# Pure C++ (no POSIX), so this target also builds on non-Linux hosts.
add_executable(message_text_test
  message_text_test.cc
  ../message_text.cc
)
target_include_directories(message_text_test PRIVATE ..)
target_link_libraries(message_text_test PRIVATE GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(lock_file_test)
gtest_discover_tests(message_text_test)
