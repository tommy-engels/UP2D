subroutine init_fields (u, uk, p, vor, nlk)
  use share_vars
  use FieldExport
  implicit none
  real(kind=pr), dimension(0:nx-1,0:ny-1,1:2), intent (inout) :: u, uk, nlk
  real(kind=pr), dimension(0:nx-1,0:ny-1), intent (inout) :: vor, p
  real(kind=pr), dimension(0:nx-1,0:ny-1) :: vortk
  real(kind=pr) :: r0,we,d,r1,r2
  integer :: ix,iy
  
  u = 0.0
  uk = 0.0
  vor = 0.0
  p = 0.0
   
!   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!   ! dipole-walls collision
!   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! 
!     x0 = 0.5*xl
!     y0 = 0.5*yl
!     r0 = 0.1
!     we = 299.528385375226
!     d = 0.1
!     
!     do ix=0,nx-1
!     do iy=0,ny-1
!        r1 = sqrt( (real(ix)*dx-x0)**2 + (real(iy)*dy-y0-d)**2 ) / r0
!        r2 = sqrt( (real(ix)*dx-x0)**2 + (real(iy)*dy-y0+d)**2 ) / r0
!        vor(ix,iy) = we * (1.0-r1**2)*exp(-r1**2) - we * (1.0-r2**2)*exp(-r2**2)
!     enddo
!     enddo
!     
!     call SaveGIF(vor,trim(dir_name)//'/'//'inicond.vor')
!     call coftxy (vor, vortk)
!     
!     call vorticity2velocity ( vortk, u )
!     
!     call coftxy( u(:,:,1), uk(:,:,1))
!     call coftxy( u(:,:,2), uk(:,:,2))
!     
!     call SaveGIF(u(:,:,1),trim(dir_name)//'/'//'inicond.ux')
!     call SaveGIF(u(:,:,2),trim(dir_name)//'/'//'inicond.uy')
end subroutine 