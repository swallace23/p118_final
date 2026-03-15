cmake_minimum_required(VERSION 3.20...4.3)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not allowed, please do:
  cmake -B build")
endif()

get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT is_multi_config AND NOT (CMAKE_BUILD_TYPE OR DEFINED ENV{CMAKE_BUILD_TYPE}))
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

project(msis
LANGUAGES C Fortran
VERSION 2.1.0.5
)

enable_testing()

include(GNUInstallDirs)

include(options.cmake)
include(cmake/compilers.cmake)

# to make more usable by external programs, put all Fortran .mod generated module files in a single directory.
set(CMAKE_Fortran_MODULE_DIRECTORY ${PROJECT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY})
# avoid parent project race

if(NOT TARGET h5fortran::h5fortran AND msis_BUILD_UTILS)
  include(cmake/GitSubmodule.cmake)
  git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/h5fortran)
  add_subdirectory(h5fortran)
endif()

add_library(msis_ifc src/msis_interface.f90)
target_include_directories(msis_ifc
PUBLIC
$<BUILD_INTERFACE:${CMAKE_Fortran_MODULE_DIRECTORY}>
$<INSTALL_INTERFACE:include>
)
target_link_libraries(msis_ifc PRIVATE msis00mod)
target_sources(msis_ifc PRIVATE $<$<NOT:$<BOOL:${msis2}>>:${CMAKE_CURRENT_SOURCE_DIR}/src/msis2_dummy.f90>)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/msis_interface.mod TYPE INCLUDE)

if(msis_BUILD_UTILS)
  add_executable(msis_setup app/main.f90)
  target_link_libraries(msis_setup PRIVATE msis_ifc h5fortran::h5fortran)
  set_property(TARGET msis_setup PROPERTY RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
  set_property(TARGET msis_setup PROPERTY DEBUG_POSTFIX .debug)
  set_property(TARGET msis_setup PROPERTY RELWITHDEBINFO_POSTFIX .debug)
  if(WIN32 AND CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    target_link_libraries(msis_setup PRIVATE shlwapi)
  endif()

  install(TARGETS msis_setup EXPORT msis-targets)
endif()

if(msis2)
  add_subdirectory(src/msis2)

  target_link_libraries(msis_ifc PUBLIC msis2mod)

  # MSIS 2.x needs this parm file.
  set(msis2_parm_file ${CMAKE_CURRENT_SOURCE_DIR}/src/msis2/msis21.parm)

  install(FILES ${msis2_parm_file} TYPE BIN)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/msis_init.mod TYPE INCLUDE)

endif()

add_library(msis00mod src/msis00_gfortran.f src/msise00_data.f)
target_compile_options(msis00mod PRIVATE ${legacy_flags})

install(TARGETS msis00mod msis_ifc EXPORT msis-targets)

add_library(msis::msis ALIAS msis_ifc)

if(msis_BUILD_TESTING)
  add_subdirectory(test)
endif()

include(cmake/install.cmake)

file(GENERATE OUTPUT .gitignore CONTENT "*")
