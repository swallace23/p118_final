if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  add_compile_options(
  "$<$<COMPILE_LANGUAGE:Fortran>:-Werror=line-truncation;-fimplicit-none>"
  $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-fno-backtrace>
  )
  set(legacy_flags "$<$<COMPILE_LANGUAGE:Fortran>:-std=legacy;-fno-implicit-none>")
endif()
