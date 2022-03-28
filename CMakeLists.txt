# cmake_minimum_required(VERSION 3.21)
cmake_minimum_required(VERSION 3.16)

# Make sure the user doesn't play dirty with symlinks
get_filename_component(srcdir "${CMAKE_SOURCE_DIR}" REALPATH)
get_filename_component(bindir "${CMAKE_BINARY_DIR}" REALPATH)

# Disallow in-source builds
if(${srcdir} STREQUAL ${bindir})
  message(
    FATAL_ERROR
      "In-source builds are not allowed. "
      "Please create a directory and run cmake from there, passing the path "
      "to this source directory as the last argument. This process created "
      "the file `CMakeCache.txt' and the directory `CMakeFiles' in ${srcdir}. "
      "Please remove them.")
endif(${srcdir} STREQUAL ${bindir})

# Use NEW behavior with newer CMake releases
foreach(p CMP0025 # CMake 3.0: Compiler id for Apple Clang is now AppleClang
)
  if(POLICY ${p})
    cmake_policy(SET ${p} NEW)
  endif()
endforeach()

# Define project name and language
project(GMTSAR C)

# Where to find our CMake modules (this variable is visible in subdirectories).
set(CMAKE_MODULE_PATH
    "${CMAKE_SOURCE_DIR}/cmake/modules/"
    CACHE INTERNAL "Location of our custom CMake modules." FORCE)

# Include configuration options (default options and options overridden by
# user).
include(ConfigCMake)

# Find UNIX commands
include(FindUnixCommands)
find_program(SVN svn)
find_program(GS gs gswin64)

# Make sure install on Windows
if(WIN32)
  set(CMAKE_INSTALL_PREFIX C:/GMTSAR)
  set(SHARE_DIR C:/GMTSAR/share)
  # Find dependent libraries
  set(TIFF_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/tiff/include")
  set(TIFF_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/lib/tiff/lib/libtiff.dll")
  find_package(TIFF REQUIRED)

  set(LAPACK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/lapack_windows/x64")
  find_package(LAPACK CONFIG REQUIRED)

  set(GMT_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/gmt6/include")
  set(GMT_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/lib/gmt6/lib/gmt.lib")
  find_package(GMT REQUIRED)
  file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/lib/tiff/lib/libtiff.dll
       DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/lib/tiff/lib/libtiff.dll.a
       DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/snaphu/bin/snaphu.exe
       DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
else()
  set(CMAKE_INSTALL_PREFIX /usr/local/gmtsar)
  set(SHARE_DIR /usr/local/gmtsar/share)
  find_package(TIFF REQUIRED)
  find_package(LAPACK REQUIRED)
  find_package(GMT REQUIRED)
  add_subdirectory(snaphu/src)
endif()

# check for math and POSIX functions
include(ConfigureChecks)

# Add subdirectories
add_subdirectory(gmtsar)
add_subdirectory(preproc/S1A_preproc)

# Configuration done

message(
  "*  Options:\n"
  "*  GMT library                : ${GMT_LIBRARY}\n"
  "*  GMT include dir            : ${GMT_INCLUDE_DIR}\n"
  "*  TIFF library               : ${TIFF_LIBRARY}\n"
  "*  TIFF include dir           : ${TIFF_INCLUDE_DIR}\n"
  "*  LAPACK library             : ${LAPACK_LIBRARIES} ${LAPACK_lapack_LIBRARY}\n"
  "*\n"
  "*  Locations:\n"
  "*  Installing GMTSAR in       : ${CMAKE_INSTALL_PREFIX}\n")

# For debugging: print all set variables get_cmake_property(_variableNames
# VARIABLES) foreach (_variableName ${_variableNames}) message(STATUS
# "${_variableName}=${${_variableName}}") endforeach()
