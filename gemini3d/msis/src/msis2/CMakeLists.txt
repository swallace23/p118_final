add_library(msis2mod
msis_calc.f90
msis_constants.F90
msis_dfn.f90
msis_gfn.f90
msis_gtd8d.f90
msis_init.F90
msis_tfn.f90
msis_utils.f90
)

target_include_directories(msis2mod PRIVATE ${CMAKE_Fortran_MODULE_DIRECTORY})

set_property(SOURCE msis_init.F90 PROPERTY
COMPILE_OPTIONS $<$<Fortran_COMPILER_ID:GNU>:-ffree-line-length-none>
)

target_compile_definitions(msis2mod PRIVATE
$<BUILD_INTERFACE:msis_datadir="${CMAKE_CURRENT_SOURCE_DIR}">
$<INSTALL_INTERFACE:msis_datadir="${CMAKE_INSTALL_BINDIR}">
)

install(TARGETS msis2mod EXPORT msis-targets)
