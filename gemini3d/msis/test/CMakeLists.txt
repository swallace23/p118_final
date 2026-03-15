if(msis_BUILD_UTILS)

add_executable(msis_generate test_gen_in.f90)
target_link_libraries(msis_generate PRIVATE h5fortran::h5fortran)

add_executable(msis_compare test_msis.f90 assert.f90)
target_link_libraries(msis_compare PRIVATE msis::msis)

# --- MSISE00 tests
set(msis00_in ${CMAKE_CURRENT_BINARY_DIR}/msis00_test_in.h5)
set(msis00_out ${CMAKE_CURRENT_BINARY_DIR}/msis00_test_out.h5)
set(msis00_ref ${CMAKE_CURRENT_SOURCE_DIR}/msis00_test_out.h5)

add_test(NAME msis00_generate
COMMAND msis_generate ${msis00_in} 0
)
set_property(TEST msis00_generate PROPERTY FIXTURES_SETUP msis00_gen_fxt)

add_test(NAME msis00_setup
COMMAND msis_setup ${msis00_in} ${msis00_out}
)
set_property(TEST msis00_setup PROPERTY FIXTURES_SETUP msis00_fxt)
set_property(TEST msis00_setup PROPERTY FIXTURES_REQUIRED msis00_gen_fxt)
set_property(TEST msis00_setup PROPERTY REQUIRED_FILES ${msis00_in})

add_test(NAME msis00_compare
COMMAND msis_compare ${msis00_out} ${msis00_ref}
)
set_property(TEST msis00_compare PROPERTY FIXTURES_REQUIRED msis00_fxt)
set_property(TEST msis00_compare PROPERTY REQUIRED_FILES "${msis00_out};${msis00_ref}")

endif()

# --- MSIS 2.x tests
if(msis2)
  add_executable(msis2test ${PROJECT_SOURCE_DIR}/src/msis2/msis2.1_test.f90)
  target_link_libraries(msis2test PRIVATE msis2mod)

  # to avoid writing output data in source dir during MSIS2 test, making it Git dirty
  configure_file(${PROJECT_SOURCE_DIR}/src/msis2/msis2.1_test_in.txt msis2.1_test_in.txt COPYONLY)
  configure_file(${msis2_parm_file} msis21.parm COPYONLY)

  add_test(NAME MSIS2 COMMAND msis2test WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

  if(msis_BUILD_UTILS)
  set(msis2_in ${CMAKE_CURRENT_BINARY_DIR}/msis2_test_in.h5)
  set(msis2_out ${CMAKE_CURRENT_BINARY_DIR}/msis2_test_out.h5)
  set(msis2_ref ${CMAKE_CURRENT_SOURCE_DIR}/msis2_test_out.h5)

  add_test(NAME msis2_generate
  COMMAND msis_generate ${msis2_in} 21
  )
  set_property(TEST msis2_generate PROPERTY FIXTURES_SETUP msis2_gen_fxt)

  add_test(NAME msis2_setup
  COMMAND msis_setup ${msis2_in} ${msis2_out}
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
endif(msis2)

get_property(_tests DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY TESTS)
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.22)
if(WIN32)
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../bin"
  )
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "LD_LIBRARY_PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../lib"
  )
elseif(APPLE)
  set_property(TEST ${_tests} PROPERTY
  ENVIRONMENT_MODIFICATION "DYLD_LIBRARY_PATH=path_list_append:${ZLIB_INCLUDE_DIRS}/../lib"
  )
endif()
endif()
