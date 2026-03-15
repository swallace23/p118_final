# This mostly duplicates the "test" directory, but is important to be sure the
# CMake installed MSIS package is working properly, particularly for MSIS 2.x parm file finding
# via lib_path()

cmake_minimum_required(VERSION 3.22...3.27)

project(MSISexample LANGUAGES C Fortran)

enable_testing()

message(STATUS "${PROJECT_NAME} CMake ${CMAKE_VERSION}")

find_package(msis CONFIG REQUIRED)
message(STATUS "Found h5fortran version ${h5fortran_VERSION} in ${h5fortran_DIR}")
message(STATUS "Found MSIS version ${msis_VERSION} in ${msis_DIR}")

get_filename_component(root_dir ${CMAKE_CURRENT_SOURCE_DIR}/.. ABSOLUTE)
set(test_dir ${root_dir}/test)

add_executable(msis_generate ${test_dir}/test_gen_in.f90)
target_link_libraries(msis_generate PRIVATE h5fortran::h5fortran)

add_executable(msis_compare ${test_dir}/test_msis.f90 ${test_dir}/assert.f90)
target_link_libraries(msis_compare PRIVATE msis::msis_ifc
h5fortran::h5fortran
)

# --- MSISE00 tests
set(msis00_in ${CMAKE_CURRENT_BINARY_DIR}/msis00_test_in.h5)
set(msis00_out ${CMAKE_CURRENT_BINARY_DIR}/msis00_test_out.h5)
set(msis00_ref ${test_dir}/msis00_test_out.h5)

add_test(NAME msis00_generate
COMMAND msis_generate ${msis00_in} 0
)
set_property(TEST msis00_generate PROPERTY FIXTURES_SETUP msis00_gen_fxt)

add_test(NAME msis00_setup
COMMAND msis::msis_setup ${msis00_in} ${msis00_out}
)
set_property(TEST msis00_setup PROPERTY FIXTURES_SETUP msis00_fxt)
set_property(TEST msis00_setup PROPERTY FIXTURES_REQUIRED msis00_gen_fxt)
set_property(TEST msis00_setup PROPERTY REQUIRED_FILES ${msis00_in})

add_test(NAME msis00_compare
COMMAND msis_compare ${msis00_out} ${msis00_ref}
)
set_property(TEST msis00_compare PROPERTY FIXTURES_REQUIRED msis00_fxt)
set_property(TEST msis00_compare PROPERTY REQUIRED_FILES "${msis00_out};${msis00_ref}")


# --- MSIS 2.x tests
if(msis_MSIS2_FOUND)
  add_executable(msis2test ${root_dir}/src/msis2/msis2.1_test.f90)
  target_link_libraries(msis2test PRIVATE msis::msis_ifc)

  add_test(NAME MSIS2 COMMAND msis2test)
  set_property(TEST MSIS2 PROPERTY WORKING_DIRECTORY ${root_dir}/src/msis2)

  set(msis2_in ${CMAKE_CURRENT_BINARY_DIR}/msis2_test_in.h5)
  set(msis2_out ${CMAKE_CURRENT_BINARY_DIR}/msis2_test_out.h5)
  set(msis2_ref ${test_dir}/msis2_test_out.h5)

  add_test(NAME msis2_generate
  COMMAND msis_generate ${msis2_in} 21
  )
  set_property(TEST msis2_generate PROPERTY FIXTURES_SETUP msis2_gen_fxt)

  add_test(NAME msis2_setup
  COMMAND msis::msis_setup ${msis2_in} ${msis2_out}
  )
  set_property(TEST msis2_setup PROPERTY FIXTURES_SETUP msis2_fxt)
  set_property(TEST msis2_setup PROPERTY FIXTURES_REQUIRED msis2_gen_fxt)
  set_property(TEST msis2_setup PROPERTY REQUIRED_FILES ${msis2_in})

  add_test(NAME msis2_compare
  COMMAND msis_compare ${msis2_out} ${msis2_ref}
  )
  set_property(TEST msis2_compare PROPERTY FIXTURES_REQUIRED msis2_fxt)
  set_property(TEST msis2_compare PROPERTY REQUIRED_FILES "${msis2_out};${msis2_ref}")
endif()

# shared lib paths
get_property(_tests DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)
if(WIN32)
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../bin;PATH=path_list_append:${h5fortran_DIR}/../bin;PATH=path_list_append:${msis_DIR}/../lib"
  )
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "LD_LIBRARY_PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../lib;LD_LIBRARY_PATH=path_list_append:${h5fortran_DIR}/../lib;LD_LIBRARY_PATH=path_list_append:${msis_DIR}/../lib"
  )
elseif(APPLE)
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "DYLD_LIBRARY_PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../lib;DYLD_LIBRARY_PATH=path_list_append:${h5fortran_DIR}/../lib;DYLD_LIBRARY_PATH=path_list_append:${msis_DIR}/../lib"
  )
endif()

file(GENERATE OUTPUT .gitignore CONTENT "*")
