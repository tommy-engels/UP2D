subroutine active_prolongation ( u, u_smooth )
  use share_vars
  use FieldExport
  implicit none
  real (kind=pr), dimension (0:nx-1, 0:ny-1,1:2), intent (in) :: u
  real (kind=pr), dimension (0:nx-1, 0:ny-1,1:2), intent (out) :: u_smooth
  real (kind=pr), dimension (0:nx-1, 0:ny-1) :: ux_x,ux_y, uy_x,uy_y
  real (kind=pr), dimension (0:nx-1, 0:ny-1,1:2) :: beta
  real(kind=pr) :: CFL_act, umax=1.d0, Tend, dt,R,R1
  integer :: ix,iy,nt2,it
  
  !----------------------------------------------------------------------------- 
  !-- compute beta field
  !-----------------------------------------------------------------------------
  !$omp parallel do private(ix)
  do ix=0,nx-1
     ux_x(ix,:) = (u(getindex(ix+1,nx),:,1)-u(getindex(ix-1,nx),:,1))/(2.d0*dx)
     uy_x(ix,:) = (u(getindex(ix+1,nx),:,2)-u(getindex(ix-1,nx),:,2))/(2.d0*dx)
  enddo  
  !$omp end parallel do
  
  !$omp parallel do private(iy)
  do iy=0,ny-1
     ux_y(:,iy) = (u(:,getindex(iy+1,ny),1)-u(:,getindex(iy-1,ny),1))/(2.d0*dy)
     uy_y(:,iy) = (u(:,getindex(iy+1,ny),2)-u(:,getindex(iy-1,ny),2))/(2.d0*dy)
  enddo  
  !$omp end parallel do
  
  !$omp parallel do private(iy)
  do iy=0,ny-1
      beta(:,iy,1) = (normals(:,iy,1)*ux_x(:,iy) + normals(:,iy,2)*ux_y(:,iy))
      beta(:,iy,2) = (normals(:,iy,1)*uy_x(:,iy) + normals(:,iy,2)*uy_y(:,iy))
      beta(:,iy,1) = beta(:,iy,1)*(1.d0-mask(:,iy)*eps)
      beta(:,iy,2) = beta(:,iy,2)*(1.d0-mask(:,iy)*eps)
  enddo  
  !$omp end parallel do
  
  !-----------------------------------------------------------------------------
  !-- prolongate beta field using advection/diffusion
  !-----------------------------------------------------------------------------
  CFL_act = 0.98d0
  umax = 1.d0
  dt = CFL_act*dx/umax
  Tend = 0.10d0
  nt2 = nint(Tend/dt)
  do it=1, nt2
    call RK4 ( beta(:,:,1), dt )
    call RK4 ( beta(:,:,2), dt )
  enddo
  
  
  !-----------------------------------------------------------------------------
  !-- construct u_smooth
  !-----------------------------------------------------------------------------  
  x0=xl/2.d0
  y0=yl/2.d0
  R1=0.50d0
  
  do ix=0,nx-1
  do iy=0,ny-1
    R = dsqrt( (dble(ix)*dx-x0)**2 + (dble(iy)*dy-y0)**2 ) 
    if (R<=1.25*R1) then
      u_smooth(ix,iy,1) = (mask(ix,iy)*eps)*phi(ix,iy)*beta(ix,iy,1)
      u_smooth(ix,iy,2) = (mask(ix,iy)*eps)*phi(ix,iy)*beta(ix,iy,2)
    else
      u_smooth(ix,iy,:) = 0.d0
    endif
  enddo
  enddo
end subroutine active_prolongation






subroutine RHS_central ( field, rhs,  dt )
  use share_vars
  use FieldExport
  implicit none
  real(kind=pr), dimension(0:nx-1,0:ny-1), intent(in) :: field
  real(kind=pr), dimension(0:nx-1,0:ny-1), intent(out) :: rhs
  real(kind=pr), intent(in) :: dt
  real(kind=pr) :: lambda, grad_x, grad_y, laplace, field_xx, field_yy
  integer :: ix,iy
  
  ! diffusion constant (experimental value)
  lambda = 0.5d0*0.5d0*dt
  
  !$omp parallel do private(iy,ix,grad_x,grad_y,field_xx,field_yy,laplace)
  do iy=0,ny-1
    do ix=0,nx-1
      if (mask(ix,iy)>0.d0) then
        !-- transport term
        grad_x = (field(getindex(ix+1,nx),iy)-field(getindex(ix-1,nx),iy))/(2.d0*dx)
        grad_y = (field(ix,getindex(iy+1,ny))-field(ix,getindex(iy-1,ny)))/(2.d0*dy)
        rhs(ix,iy) = normals(ix,iy,1)*grad_x + normals(ix,iy,2)*grad_y
        
        !-- diffusion 
        field_xx = field(getindex(ix-1,nx),iy)-2.d0*field(ix,iy)+field(getindex(ix+1,nx),iy) 
        field_yy = field(ix,getindex(iy-1,ny))-2.d0*field(ix,iy)+field(ix,getindex(iy+1,ny))
        laplace = field_xx/dx**2 + field_yy/dy**2
        
        rhs(ix,iy) = rhs(ix,iy) + lambda*laplace
      else
        rhs(ix,iy) = 0.d0
      endif      
    enddo
  enddo  
  !$omp end parallel do    
end subroutine RHS_central




subroutine RK4 ( field, dt )
  use share_vars
  use FieldExport
  implicit none
  real(kind=pr), dimension(0:nx-1,0:ny-1), intent(inout) :: field
  real(kind=pr), dimension(0:nx-1,0:ny-1):: k1,k2,k3,k4
  real(kind=pr), intent(in) :: dt
  real(kind=pr) :: lambda
  integer :: ix,iy
  
  call RHS_central( field, k1, dt)
  call RHS_central( field+0.5d0*dt*k1, k2, dt)
  call RHS_central( field+0.5d0*dt*k2, k3, dt)
  call RHS_central( field+dt*k3, k4, dt)

  !$omp parallel do private(iy)
  do iy=0,ny-1
    field(:,iy)=field(:,iy)+(dt/6.d0) *( k1(:,iy)+2.d0*k2(:,iy)+2.d0*k3(:,iy)+k4(:,iy) ) 
  enddo  
  !$omp end parallel do    
end subroutine RK4