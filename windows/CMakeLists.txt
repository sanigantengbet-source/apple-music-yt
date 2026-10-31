cmake_minimum_required(VERSION 3.14)
project(apple_music_yt LANGUAGES CXX)

set(BINARY_NAME "apple_music_yt")

cmake_policy(SET CMP0069 NEW)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory("flutter")
add_subdirectory("runner")
