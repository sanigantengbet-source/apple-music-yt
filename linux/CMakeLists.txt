cmake_minimum_required(VERSION 3.10)
project(apple_music_yt LANGUAGES CXX)

set(BINARY_NAME "apple_music_yt")
set(APPLICATION_ID "com.applemusic.ytmusic")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root directory of flutter application
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Flutter library & plugins
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app PkgConfig::GTK)
