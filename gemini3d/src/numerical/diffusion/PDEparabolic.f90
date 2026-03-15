module PDEparabolic

!! a module for use for solving parabolic partial differential equations


!> banded and tridiagonal solvers, for now we just take everything to be banded...
use phys_consts, only: wp
use vendor_lapack95, only: gbsv!,gtsv

implicit none (type, external)

private
public :: TRBDF21D, backEuler1D, SDIRK21D


contains


function TRBDF21D(Ts,A,B,C,D,E,Tsminx1,Tsmaxx1,dt,BCtype,dx1,dx1i)

!! SOLVE A 1D DIFFUSION PROBLEM.  IT IS EXPECTED THAT
!! GHOST CELLS WILL HAVE BEEN TRIMMED FROM ARRAYS BEFORE
!! THEY ARE PASSED INTO THIS ROUTINE.
!!
!! FORM OF EQUATION SOLVED IS:
!!  dT/dt + A T + B dT/dx + C d/dx(D dT/dx) = E
!!
!!  NOTE: UPON FURTHER REVIEW I THINK THE FORM SOLVED IS ACTUALLY:
!!  dT/dt = A T + B dT/dx + C d/dx(D dT/dx) + E
!!
!! We assume the user is providing the type of boundary conditions and that
!! any Neumann boundary conditions are interpreted as diffs in state variable
!! to be solved (this avoids needing solvers to have to do additional calculations
!! using auxiliary variables not in scope.  

real(wp), dimension(:), intent(in) :: A,B,C,D,E
real(wp), dimension(:), intent(in) :: Ts
real(wp), intent(in) :: Tsminx1, Tsmaxx1, dt
integer, dimension(2), intent(in) :: BCtype  !=0 dirichlet; =1 neumann
real(wp), dimension(0:), intent(in) :: dx1   !ith backward difference
real(wp), dimension(:), intent(in) :: dx1i   !ith centered difference
integer, parameter :: ll=2                   !number of lower diagonals

real(wp), dimension(3*ll+1,size(Ts)) :: M    !note extra rows for lapack workspace
real(wp), dimension(size(Ts)) :: Dh
integer :: ix1,lx1

real(wp), dimension(size(Ts)) :: TR

real(wp), dimension(size(Ts)) :: TRBDF21D

!> ORGANIZE SIZES AND THERMAL CONDUCTIVITY
lx1=size(Ts)
Dh(1)=0
Dh(2:lx1)=0.5*(D(1:lx1-1)+D(2:lx1))         !ith left cell wall thermal conductivity
!    TR(:)=Ts(:)/dt+E(:)
!! boundaries to be overwritten later...  This is now done for each grid point in a separate statement


!! ## TR HALF STEP:  DEFINE A MATRIX USING BANDED STORAGE


! ZZZ - check whether diriclet or neumann...
!> MINX1 BOUNDARY (DIRICHLET)
ix1=1
if (BCtype(1)==0) then
  M(ll+3,ix1)=1
  M(ll+2,ix1+1)=0
  M(ll+1,ix1+2)=0
  TR(ix1)=Tsminx1
else
  M(ll+3,ix1)=1
  M(ll+2,ix1+1)=-1
  M(ll+1,ix1+2)=0
  TR(ix1)=Tsminx1 !used to be 0, but we change it since we are doing the difference. 
end if


!> FIRST INTERIOR GRID POINT
ix1=2

!> ix1-1
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2 &
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))/2

!> ix1
M(ll+3,ix1)=1/(dt/2)-A(ix1)/2 &
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2

!> ix1+1, super-diag.
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))/2
M(ll+1,ix1+2)=0
TR(ix1)=Ts(ix1)/(dt/2)+E(ix1) &
  -M(ll+4,ix1-1)*Ts(ix1-1) &
  -(-A(ix1)/2+C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2+C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2)*Ts(ix1) &
  -M(ll+2,ix1+1)*Ts(ix1+1) &
  -M(ll+1,ix1+2)*Ts(ix1+2)


!> INTERIOR GRID POINTS
do ix1=3,lx1-2
!! removed do concurrent to avoid oneAPI compiler ICE #5623
!! do concurrent OK because only indexing already defined things
  M(ll+5,ix1-2) = 0
  !! ix1-2 grid point, sub-diag.
  M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2 &        !ix1-1
             +B(ix1)/(dx1(ix1+1)+dx1(ix1))/2
  M(ll+3,ix1)=1/(dt/2)-A(ix1)/2 &                           !ix1
           +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &
           +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2
  M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &    !ix1+1, super-diag.
           -B(ix1)/(dx1(ix1+1)+dx1(ix1))/2
  M(ll+1,ix1+2) = 0
  !! ix1+2 grid point
  TR(ix1)=Ts(ix1)/(dt/2)+E(ix1) &
    -M(ll+5,ix1-2)*Ts(ix1-2) &
    -M(ll+4,ix1-1)*Ts(ix1-1) &
    -(-A(ix1)/2+C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2+C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2)*Ts(ix1) &
    -M(ll+2,ix1+1)*Ts(ix1+1) &
    -M(ll+1,ix1+2)*Ts(ix1+2)
end do


!> LAST INTERIOR GRID POINT
ix1=lx1-1
M(ll+5,ix1-2)=0
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2 &            !ix1-1
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))/2
M(ll+3,ix1)=1/(dt/2)-A(ix1)/2 &                               !ix1
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2 &        !ix1+1, super-diag.
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))/2
TR(ix1)=Ts(ix1)/(dt/2)+E(ix1) &
  -M(ll+5,ix1-2)*Ts(ix1-2) &
  -M(ll+4,ix1-1)*Ts(ix1-1) &
  -(-A(ix1)/2+C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1)/2+C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)/2)*Ts(ix1) &
  -M(ll+2,ix1+1)*Ts(ix1+1)


! ZZZ - check whether dirichlet or neumann...
!> MAXX1 BOUNDARY
ix1=lx1
if (BCtype(2)==0) then
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=0
  M(ll+3,ix1)=1
  TR(ix1)=Tsmaxx1
else
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=-1
  M(ll+3,ix1)=1
  TR(ix1)=Tsmaxx1
end if


!! ### TR HALF STEP MATRIX SOLUTION:  CALL LAPACK'S BANDED SOLVER

!> BANDED SOLVER (INPUT MATRIX MUST BE SHIFTED 'DOWN' BY KL ROWS)
call gbsv(M,TR,kl=2)



!! ## BDF2 STEP:  DEFINE A MATRIX USING BANDED STORAGE

!ZZZ - check whether D or N
!> MINX1 BOUNDARY (DIRICHLET)
ix1=1
if (BCtype(1)==0) then
  M(ll+3,ix1)=1
  M(ll+2,ix1+1)=0
  M(ll+1,ix1+2)=0
  TRBDF21D(ix1)=Tsminx1
else
  M(ll+3,ix1)=1
  M(ll+2,ix1+1)=-1
  M(ll+1,ix1+2)=0
  TRBDF21D(ix1)=Tsminx1
end if


!> FIRST INTERIOR GRID POINT
ix1=2
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &            !ix1-1
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+3,ix1)=1/(dt/3)-A(ix1) &                               !ix1
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &        !ix1+1, super-diag.
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+1,ix1+2)=0
TRBDF21D(ix1)=E(ix1) &
  -1/3._wp*Ts(ix1)/(dt/3) &
  +4/3._wp*TR(ix1)/(dt/3)


!> INTERIOR GRID POINTS
do ix1=3,lx1-2
!! removed do concurrent to avoid oneAPI compiler ICE #5623
  M(ll+5,ix1-2)=0                                               !ix1-2 grid point, sub-diag.
  M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &        !ix1-1
             +B(ix1)/(dx1(ix1+1)+dx1(ix1))
  M(ll+3,ix1)=1/(dt/3)-A(ix1) &                           !ix1
           +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
           +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
  M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &    !ix1+1, super-diag.
           -B(ix1)/(dx1(ix1+1)+dx1(ix1))
  M(ll+1,ix1+2)=0                                               !ix1+2 grid point
  TRBDF21D(ix1)=E(ix1) &
    -1/3._wp*Ts(ix1)/(dt/3) &
    +4/3._wp*TR(ix1)/(dt/3)
end do


!LAST INTERIOR GRID POINT
ix1=lx1-1
M(ll+5,ix1-2)=0
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &            !ix1-1
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+3,ix1)=1/(dt/3)-A(ix1) &                               !ix1
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &        !ix1+1, super-diag.
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))
TRBDF21D(ix1)=E(ix1) &
  -1/3._wp*Ts(ix1)/(dt/3) &
  +4/3._wp*TR(ix1)/(dt/3)

!check whether D or N
!> MAXX1 BOUNDARY
ix1=lx1
if (BCtype(2)==0) then
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=0
  M(ll+3,ix1)=1
  TRBDF21D(ix1)=Tsmaxx1
else
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=-1
  M(ll+3,ix1)=1
  TRBDF21D(ix1)=Tsmaxx1
end if


!! ## BDF2 STEP MATRIX SOLUTION:  CALL LAPACK'S BANDED SOLVER

!> BANDED SOLVER (INPUT MATRIX MUST BE SHIFTED 'DOWN' BY KL ROWS)
call gbsv(M,TRBDF21D,kl=2)

end function TRBDF21D


function backEuler1D(Ts,A,B,C,D,E,Tsminx1,Tsmaxx1,dt,BCtype,dx1,dx1i,coeffs,rhs)

!------------------------------------------------------------
!-------SOLVE A 1D DIFFUSION PROBLEM.  IT IS EXPECTED THAT
!-------GHOST CELLS WILL HAVE BEEN TRIMMED FROM ARRAYS BEFORE
!-------THEY ARE PASSED INTO THIS ROUTINE.  FORM OF EQUATION
!-------SOLVED IS:
!------- dT/dt + A T + B dT/dx + C d/dx(D dT/dx) = E
!------------------------------------------------------------

real(wp), dimension(:), intent(in) :: A,B,C,D,E
real(wp), dimension(:), intent(in) :: Ts
real(wp), intent(in) :: Tsminx1, Tsmaxx1, dt
integer, dimension(2), intent(in) :: BCtype
real(wp), dimension(0:), intent(in) :: dx1   !ith backward difference
real(wp), dimension(:), intent(in) :: dx1i   !ith centered difference
real(wp), dimension(:,:), intent(inout), optional :: coeffs
!! intent(out)
real(wp), dimension(:), intent(inout), optional :: rhs
!! intent(out)

integer, parameter :: ll=2                   !number of lower diagonals
real(wp), dimension(3*ll+1,size(Ts)) :: M    !note extra rows for lapack workspace
real(wp), dimension(size(Ts)) :: Dh
real(wp), dimension(size(Ts)) :: backEuler1D
integer :: ix1,lx1

!------------------------------------------------------------
!-------DEFINE A MATRIX USING BANDED STORAGE
!------------------------------------------------------------
lx1=size(Ts)
Dh(1)=0
Dh(2:lx1)=0.5*(D(1:lx1-1)+D(2:lx1))         !ith left cell wall thermal conductivity
backEuler1D(:)=Ts(:)/dt+E(:)                !boundaries to be overwritten later...


! check whether D or N
!> MINX1 BOUNDARY, Dirichlet BCS
ix1=1
if (BCtype(1)==0) then
  M(ll+3,ix1)=1       !main diagonal denoted temperature at this grid point... 1*Ts,i=Tsminx1
  M(ll+2,ix1+1)=0     !1st super diagonal
  M(ll+1,ix1+2)=0     !2nd super diagonal
  backEuler1D(ix1)=Tsminx1
else
  M(ll+3,ix1)=1       !main diagonal denoted temperature at this grid point... 1*Ts,i=Tsminx1
  M(ll+2,ix1+1)=-1    !1st super diagonal
  M(ll+1,ix1+2)=0     !2nd super diagonal
  backEuler1D(ix1)=0
end if

!> FIRST INTERIOR GRID POINT
ix1=2
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &            !ix1-1, sub-diaginal
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+3,ix1)=1/dt-A(ix1) &                                     !ix1
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &        !ix1+1, super-diag.
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+1,ix1+2)=0


!> INTERIOR GRID POINTS
do ix1=3,lx1-2
!! removed do concurrent to avoid oneAPI compiler ICE #5623
  M(ll+5,ix1-2) = 0
  !! ix1-2 grid point, sub-diag.
  M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &            !ix1-1
             +B(ix1)/(dx1(ix1+1)+dx1(ix1))
  M(ll+3,ix1)=1/dt-A(ix1) &                                     !ix1
           +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
           +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
  M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &        !ix1+1, super-diag.
           -B(ix1)/(dx1(ix1+1)+dx1(ix1))
  M(ll+1,ix1+2) = 0
  !! ix1+2 grid point
end do


!> LAST INTERIOR GRID POINT
ix1=lx1-1
M(ll+5,ix1-2)=0
M(ll+4,ix1-1)=-C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1) &            !ix1-1
           +B(ix1)/(dx1(ix1+1)+dx1(ix1))
M(ll+3,ix1)=1/dt-A(ix1) &                                     !ix1
         +C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &
         +C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
M(ll+2,ix1+1)=-C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) &        !ix1+1, super-diag.
         -B(ix1)/(dx1(ix1+1)+dx1(ix1))

! check whether D or N
!> MAXX1 BOUNDARY
ix1=lx1
if (BCtype(2)==0) then
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=0
  M(ll+3,ix1)=1
  backEuler1D(ix1)=Tsmaxx1
else
  M(ll+5,ix1-2)=0
  M(ll+4,ix1-1)=-1
  M(ll+3,ix1)=1
  backEuler1D(ix1)=0
end if

!> in case we want to output the right-hand side of the system; has to be done here before
!   the output argument (which stores rhs) is overwritten by the solution.
if (present(rhs)) then
  rhs(1:lx1)=backEuler1D(1:lx1)
end if

!! ## DO SOME STUFF TO CALL LAPACK'S BANDED SOLVER
!> BANDED SOLVER (INPUT MATRIX MUST BE SHIFTED 'DOWN' BY KL ROWS)
call gbsv(M,backEuler1D,kl=2)

!> this is for if one wants to output the matrix bands for testing purposes
if (present(coeffs)) then
  coeffs(1:lx1,1)=M(ll+2,1:lx1)
  coeffs(1:lx1,2)=M(ll+3,1:lx1)
  coeffs(1:lx1,3)=M(ll+4,1:lx1)
end if

end function backEuler1D

function SDIRK21D(Ts,A,B,C,D,E,Tsminx1,Tsmaxx1,dt,BCtype,dx1,dx1i) result(Tnew)
!! 2nd-order, L-stable SDIRK(2) integrator for linear parabolic operator
!!
!! Solves (conceptually):
!!   dT/dt = J*T + E
!! where J corresponds to the same spatial operator encoded in backEuler1D/TRBDF21D stencils.
!!
!! Stage equations (Alexander SDIRK2):
!!   (I - g*dt*J) Y1 = Tn + g*dt*E
!!   (I - g*dt*J) Y2 = Tn + dt*(1-2g)*(J*Y1 + E) + g*dt*E
!! Update:
!!   T^{n+1} = Tn + dt * 0.5 * ( (J*Y1+E) + (J*Y2+E) )

  use phys_consts, only: wp
  use vendor_lapack95, only: gbsv

  implicit none (type, external)

  real(wp), dimension(:), intent(in) :: Ts,A,B,C,D,E
  real(wp), intent(in) :: Tsminx1, Tsmaxx1, dt
  integer, dimension(2), intent(in) :: BCtype
  real(wp), dimension(0:), intent(in) :: dx1
  real(wp), dimension(:), intent(in) :: dx1i

  real(wp), dimension(size(Ts)) :: Tnew
  integer, parameter :: ll = 2
  integer :: lx1, ix1
  real(wp) :: g, dtg, denom

  real(wp), dimension(size(Ts)) :: Dh
  real(wp), dimension(size(Ts)) :: Y1, Y2
  real(wp), dimension(size(Ts)) :: F1, F2
  real(wp), dimension(size(Ts)) :: rhs

  real(wp), dimension(3*ll+1,size(Ts)) :: M

  lx1 = size(Ts)

  ! SDIRK2 parameter
  g  = 1._wp - 1._wp/sqrt(2._wp)
  dtg = g*dt

  ! conductivity averaged to left wall (same as existing code)
  Dh(1) = 0._wp
  Dh(2:lx1) = 0.5_wp*(D(1:lx1-1) + D(2:lx1))

  !-----------------------------------------
  ! helper: assemble matrix for (I/dtg - J)
  !-----------------------------------------
  call assemble_Ioverdt_minus_J(M, A,B,C,Dh, dtg, BCtype, dx1, dx1i, Tsminx1, Tsmaxx1)

  !-----------------------------------------
  ! Stage 1 solve: (I - dtg*J)Y1 = Ts + dtg*E
  !  -> (I/dtg - J)Y1 = Ts/dtg + E
  !-----------------------------------------
  rhs(:) = Ts(:)/dtg + E(:)
  call gbsv(M, rhs, kl=2)
  Y1(:) = rhs(:)

  call apply_J(F1, Y1, A,B,C,Dh, BCtype, dx1, dx1i)  ! F1 := J*Y1 (no +E)
  F1(:) = F1(:) + E(:)                               ! now F1 := J*Y1 + E

  !-----------------------------------------
  ! Stage 2 solve:
  ! (I - dtg*J)Y2 = Ts + dt*(1-2g)*F1 + dtg*E
  ! -> (I/dtg - J)Y2 = Ts/dtg + (dt/dtg)*(1-2g)*F1 + E
  !-----------------------------------------
  denom = dtg
  rhs(:) = Ts(:)/denom + (dt/denom)*(1._wp - 2._wp*g)*F1(:) + E(:)

  ! Need the same LHS matrix; reassemble because gbsv overwrites M
  call assemble_Ioverdt_minus_J(M, A,B,C,Dh, dtg, BCtype, dx1, dx1i, Tsminx1, Tsmaxx1)

  call gbsv(M, rhs, kl=2)
  Y2(:) = rhs(:)

  call apply_J(F2, Y2, A,B,C,Dh, BCtype, dx1, dx1i)
  F2(:) = F2(:) + E(:)

  !-----------------------------------------
  ! Update
  !-----------------------------------------
  Tnew(:) = Ts(:) + dt*0.5_wp*(F1(:) + F2(:))

  ! Enforce boundary values consistent with BCtype
  if (BCtype(1) == 0) Tnew(1) = Tsminx1
  if (BCtype(2) == 0) Tnew(lx1) = Tsmaxx1
  if (BCtype(1) == 1) Tnew(1) = Tnew(2) - Tsminx1   ! Neumann stored as diff (matches existing convention [3])
  if (BCtype(2) == 1) Tnew(lx1) = Tnew(lx1-1) + Tsmaxx1

contains

  subroutine assemble_Ioverdt_minus_J(M, A,B,C,Dh, dtloc, BCtype, dx1, dx1i, Tsminx1, Tsmaxx1)
    real(wp), dimension(:,:), intent(inout) :: M
    real(wp), dimension(:), intent(in) :: A,B,C,Dh
    real(wp), intent(in) :: dtloc, Tsminx1, Tsmaxx1
    integer, dimension(2), intent(in) :: BCtype
    real(wp), dimension(0:), intent(in) :: dx1
    real(wp), dimension(:), intent(in) :: dx1i

    integer :: ix1, lx1
    lx1 = size(A)

    M(:,:) = 0._wp

    ! MINX1 boundary row
    ix1 = 1
    if (BCtype(1) == 0) then
      M(ll+3,ix1)   = 1._wp
      M(ll+2,ix1+1) = 0._wp
      M(ll+1,ix1+2) = 0._wp
    else
      M(ll+3,ix1)   = 1._wp
      M(ll+2,ix1+1) = -1._wp
      M(ll+1,ix1+2) = 0._wp
    end if

    ! First interior
    ix1 = 2
    M(ll+4,ix1-1) = -C(ix1)*Dh(ix1)  /dx1i(ix1)/dx1(ix1) + B(ix1)/(dx1(ix1+1)+dx1(ix1))
    M(ll+3,ix1)   =  1._wp/dtloc - A(ix1) + C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) + C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
    M(ll+2,ix1+1) = -C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) - B(ix1)/(dx1(ix1+1)+dx1(ix1))
    M(ll+1,ix1+2) = 0._wp

    ! Interior
    do ix1 = 3, lx1-2
      M(ll+5,ix1-2) = 0._wp
      M(ll+4,ix1-1) = -C(ix1)*Dh(ix1)  /dx1i(ix1)/dx1(ix1) + B(ix1)/(dx1(ix1+1)+dx1(ix1))
      M(ll+3,ix1)   =  1._wp/dtloc - A(ix1) + C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) + C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
      M(ll+2,ix1+1) = -C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) - B(ix1)/(dx1(ix1+1)+dx1(ix1))
      M(ll+1,ix1+2) = 0._wp
    end do

    ! Last interior
    ix1 = lx1-1
    M(ll+5,ix1-2) = 0._wp
    M(ll+4,ix1-1) = -C(ix1)*Dh(ix1)  /dx1i(ix1)/dx1(ix1) + B(ix1)/(dx1(ix1+1)+dx1(ix1))
    M(ll+3,ix1)   =  1._wp/dtloc - A(ix1) + C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) + C(ix1)*Dh(ix1)/dx1i(ix1)/dx1(ix1)
    M(ll+2,ix1+1) = -C(ix1)*Dh(ix1+1)/dx1i(ix1)/dx1(ix1+1) - B(ix1)/(dx1(ix1+1)+dx1(ix1))

    ! MAXX1 boundary row
    ix1 = lx1
    if (BCtype(2) == 0) then
      M(ll+5,ix1-2) = 0._wp
      M(ll+4,ix1-1) = 0._wp
      M(ll+3,ix1)   = 1._wp
    else
      M(ll+5,ix1-2) = 0._wp
      M(ll+4,ix1-1) = -1._wp
      M(ll+3,ix1)   = 1._wp
    end if

  end subroutine assemble_Ioverdt_minus_J


  subroutine apply_J(Jy, y, A,B,C,Dh, BCtype, dx1, dx1i)
    real(wp), dimension(:), intent(out) :: Jy
    real(wp), dimension(:), intent(in)  :: y
    real(wp), dimension(:), intent(in)  :: A,B,C,Dh
    integer, dimension(2), intent(in)   :: BCtype
    real(wp), dimension(0:), intent(in) :: dx1
    real(wp), dimension(:), intent(in)  :: dx1i

    integer :: i, lx1
    real(wp) :: aL, a0, aU

    lx1 = size(y)
    Jy(:) = 0._wp

    ! Boundaries: treat as 0 contribution (BCs handled separately)
    Jy(1)   = 0._wp
    Jy(lx1) = 0._wp

    ! First interior
    i = 2
    aL =  C(i)*Dh(i)  /dx1i(i)/dx1(i) - B(i)/(dx1(i+1)+dx1(i))
    a0 =  A(i) - C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) - C(i)*Dh(i)/dx1i(i)/dx1(i)
    aU =  C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) + B(i)/(dx1(i+1)+dx1(i))
    Jy(i) = aL*y(i-1) + a0*y(i) + aU*y(i+1)

    ! Interior
    do i = 3, lx1-2
      aL =  C(i)*Dh(i)  /dx1i(i)/dx1(i) - B(i)/(dx1(i+1)+dx1(i))
      a0 =  A(i) - C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) - C(i)*Dh(i)/dx1i(i)/dx1(i)
      aU =  C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) + B(i)/(dx1(i+1)+dx1(i))
      Jy(i) = aL*y(i-1) + a0*y(i) + aU*y(i+1)
    end do

    ! Last interior
    i = lx1-1
    aL =  C(i)*Dh(i)  /dx1i(i)/dx1(i) - B(i)/(dx1(i+1)+dx1(i))
    a0 =  A(i) - C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) - C(i)*Dh(i)/dx1i(i)/dx1(i)
    aU =  C(i)*Dh(i+1)/dx1i(i)/dx1(i+1) + B(i)/(dx1(i+1)+dx1(i))
    Jy(i) = aL*y(i-1) + a0*y(i) + aU*y(i+1)

  end subroutine apply_J

end function SDIRK21D

end module PDEparabolic
