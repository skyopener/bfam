max = math.max
min = math.min
abs = math.abs
sqrt = math.sqrt
-- refinement parameters
max_level = 30000

output_prefix = "TPV29_base_larger"
data_directory = "data"
elem_order = 4
h1_targ   = 4*0.1
r_targ    = 5
D_targ    = 30
hmax_targ = elem_order*2
-- hmax_targ = h1_targ

-- connectivity info
connectivity = "brick"
BUF = 2
brick =
{
  nx = 2+2*BUF,
  ny = 1+1*BUF,
  nz = 2+2*BUF,
  periodic_x = 0,
  periodic_y = 0,
  periodic_z = 0,
  bc0 = 1,
  bc1 = 1,
  bc2 = 2,
  bc3 = 1,
  bc4 = 1,
  bc5 = 1,
}

-- set up the domain
Lx = 20
Ly = 20
Lz = 20

Cx = brick.nx/2
Cy = 0
Cz = brick.nz/2

function connectivity_vertices(x, y, z)
  xout = Lx*(x-Cx)
  yout = Ly*(y-Cy)
  zout = Lz*(z-Cz)
  return xout,yout,zout
end

--REFINEMENT FUNCTION
function fault_distance(x,y,z)
  xf = max(0,abs(x)-20)
  zf = abs(z)
  yf = max(0,abs(y)-20)
  r  = xf^2 + yf^2 + zf^2
  return sqrt(r)
end

function element_size(
  x0,y0,z0,x1,y1,z1,
  x2,y2,z2,x3,y3,z3,
  x4,y4,z4,x5,y5,z5,
  x6,y6,z6,x7,y7,z7)


  h = (x0-x1)^2+(y0-y1)^2+(z0-z1)^2
  hmin = h
  hmax = h

  h = (x0-x2)^2+(y0-y2)^2+(z0-z2)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x0-x4)^2+(y0-y4)^2+(z0-z4)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x1-x3)^2+(y1-y3)^2+(z1-z3)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x1-x5)^2+(y1-y5)^2+(z1-z5)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x2-x3)^2+(y2-y3)^2+(z2-z3)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x2-x6)^2+(y2-y6)^2+(z2-z6)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x3-x7)^2+(y3-y7)^2+(z3-z7)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x4-x5)^2+(y4-y5)^2+(z4-z5)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x4-x6)^2+(y4-y6)^2+(z4-z6)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x5-x7)^2+(y5-y7)^2+(z5-z7)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  h = (x6-x7)^2+(y6-y7)^2+(z6-z7)^2
  hmax = max(hmax,h)
  hmin = min(hmin,h)

  return sqrt(hmin), sqrt(hmax)

end

function refinement_function(
  x0,y0,z0,x1,y1,z1,
  x2,y2,z2,x3,y3,z3,
  x4,y4,z4,x5,y5,z5,
  x6,y6,z6,x7,y7,z7,
  level, treeid)

  if(level >= max_level) then
    return 0
  end

  r = fault_distance(x0,y0,z0)
  r = min(r,fault_distance(x1,y1,z1))
  r = min(r,fault_distance(x2,y2,z2))
  r = min(r,fault_distance(x3,y3,z3))
  r = min(r,fault_distance(x4,y4,z4))
  r = min(r,fault_distance(x5,y5,z5))
  r = min(r,fault_distance(x6,y6,z6))
  r = min(r,fault_distance(x7,y7,z7))

  hmin, hmax = element_size( x0,y0,z0,x1,y1,z1,
                             x2,y2,z2,x3,y3,z3,
                             x4,y4,z4,x5,y5,z5,
                             x6,y6,z6,x7,y7,z7)

  D = (min(D_targ,max(r_targ,r))-r_targ)/(D_targ-r_targ)
  if hmax > h1_targ*(1-D) + hmax_targ*D then
    return 1
  end

  return 0
end

function element_order(
  x0,y0,z0,x1,y1,z1,
  x2,y2,z2,x3,y3,z3,
  x4,y4,z4,x5,y5,z5,
  x6,y6,z6,x7,y7,z7,
  level, treeid)


  return elem_order, "elastic"
end

function transform_nodes(x, y, z)
  dz = interp_fault(fault,x,y)
  z = z + dz*max(0,1-abs(z/Lz))
  return x,y,z
end

-- material properties
cs = 3.464
cp = 6
rho = 2.670
mu  = rho*cs^2
lam = rho*cp^2-2*mu

-- field conditions
S11 = 0
S22 = 0
S33 = 0
S12 = 0
S13 = 0
S23 = 0
v1  = 0
v2  = 0
v3  = 0

-- plasticity parameters
-- plastic = {
--   tag = "Duvaut-Lions",
--   c  = 1.18,   -- plastic cohesion
--   Tr = 0.05,   -- viscoplastic relaxation time
--   nu = 0.1680, -- bulk friction
--   phi = math.atan(0.1680),  -- angle of friction: atan(nu)
--   S11_0  = "S11_0_function",
--   S12_0  = 0,
--   S13_0  = "S13_0_function",
--   S22_0  = "S22_0_function",
--   S23_0  = 0,
--   S33_0  = "S33_0_function",
--   pf     = "pf_0_function",
-- }

-- time stepper to use
lsrk_method  = "KC54"

tend       = 20
-- tout       = 1
-- tfout      = 0.01
tout       = -1
tfout      = -1
tdisp      = 0.01
tstations  = 0.01
nerr       = 0
output_file_fault = 1

function time_step_parameters(dt)
  dt      = 0.5*dt

  T       = tstations
  n       = math.ceil(T / dt)
  dt      = T / n

  noutput    = tout      / dt
  ndisp      = tdisp     / dt
  nsteps     = tend      / dt
  nstations  = tstations / dt
  nfoutput   = tfout     / dt
  -- nsteps     = 1
  -- noutput    = 1
  -- nfoutput   = 1

  --- return dt,1, 1, 1, 1, 1
  return dt,nsteps, ndisp, noutput, nfoutput, nstations
end


-- faults
b11 =  1.025837
b33 =  0.974162
b13 = -0.158649
function Omega_function(x,y,z,t)
  if y < 17 then
    return 1
  elseif y < 22 then
    return (22.0-y)/5.0
  else
    return 0
  end
  -- return min(1.0, max(0.0, (20.0-y)/5.0))
end
function pf_0_function(x,y,z,t)
  return 9.8*y -- in MPa
end
function S22_0_function(x,y,z,t)
  return -2.670*9.8*y -- in MPa
end
function S11_0_function(x,y,z,t)
  W     = Omega_function(x,y,z,t)
  pf    = pf_0_function(x,y,z,t)
  S22   = S22_0_function(x,y,z,t)
  return W*(b11*(S22+pf)-pf)+(1-W)*S22
end
function S33_0_function(x,y,z,t)
  W     = Omega_function(x,y,z,t)
  pf    = pf_0_function(x,y,z,t)
  S22   = S22_0_function(x,y,z,t)
  return W*(b33*(S22 + pf) - pf) + (1 - W)*S22
end
function S13_0_function(x,y,z,t)
  W     = Omega_function(x,y,z,t)
  pf    = pf_0_function(x,y,z,t)
  S22   = S22_0_function(x,y,z,t)
  return W*b13*(S22+pf)
end
function c0_function(x,y,z,t)
  return 0.4 + 0.20*max(0.0,4-y)
end
function Tforce_function(x,y,z,t)
  rcrit = 4
  r = sqrt((x+5)^2+(y-10)^2)
  -- r = sqrt(x^2+(y-Ly/2)^2)
  Vr = 0.7*cs
  if r < rcrit then
    return r/Vr + (0.081*rcrit/Vr)*(1/(1-(r/rcrit)^2) - 1)
  else
    return 1e9
  end
end

fault = {
  type   = "friction",
  tag    = "slip weakening",
  fs     = 0.18,
  fd     = 0.12,
  Dc     = 0.3,
  pf_0   = "pf_0_function",
  S11_0  = "S11_0_function",
  S12_0  = 0,
  S13_0  = "S13_0_function",
  S22_0  = "S22_0_function",
  S23_0  = 0,
  S33_0  = "S33_0_function",
  c0     = "c0_function",
  Tforce = "Tforce_function",
  Tforce_0 = 0.5,
}

bc_free = {
  type = "boundary",
  tag  = "free surface",
}

bc_nonreflect = {
  type = "boundary",
  tag  = "non-reflecting",
}

bc_rigid = {
  type = "boundary",
  tag  = "rigid wall",
}

glue_info = {
  bc_nonreflect,
  bc_free,
  bc_rigid,
  fault,
}

-- friction stuff
glueid_treeid_faceid = {
  4, (Cx-1) + (0)*brick.nx + (Cz-1)*brick.nx*brick.ny, 5,
  4, (Cx-1) + (0)*brick.nx + (Cz  )*brick.nx*brick.ny, 4,
  4, (Cx  ) + (0)*brick.nx + (Cz-1)*brick.nx*brick.ny, 5,
  4, (Cx  ) + (0)*brick.nx + (Cz  )*brick.nx*brick.ny, 4,
}

-- Read the fault data
function read_fault(filename)
  local f = io.open(filename,"r")

  local l = f:read("*line")
  local l = f:read("*line")
  local Nx, Ny, lx, ly = string.match(l, "(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")

  local scale = 1e3

  local A = {
    dx = {},
    dy = {},
    dz = {},
    fx = {},
    fy = {},
    hx = lx/Nx/scale,
    hy = ly/Ny/scale,
    Nx = Nx,
    Ny = Ny,
  }

  local r = -1
  for l in f:lines() do
    local ix, iy, dx, dy, dz, fx, fy = string.match(l, "(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
    ix = ix+1
    iy = iy+1
    dx = dx+0
    dy = dy+0
    dz = dz+0
    fx = fx+0
    fy = fy+0
    if(r < ix) then
      A.dx[ix] = {}
      A.dy[ix] = {}
      A.dz[ix] = {}
      A.fx[ix] = {}
      A.fy[ix] = {}
      r = ix
    end
    A.dx[ix][iy] = dx/scale
    A.dy[ix][iy] = dy/scale
    A.dz[ix][iy] = dz/scale
    A.fx[ix][iy] = fx/scale
    A.fy[ix][iy] = fy/scale
  end
  io.close(f)

  return A
end

-- Linear
-- function interp_basis(x,dx)
--    local l0 = 1-x
--    local d0 = 0
--    local l1 = x
--    local d1 = 0
--
--    return l0,d0,l1,d1
-- end

-- Hermite
function interp_basis(x,dx)
   local l0 =     1     - 3*x^2 + 2*x^3
   local d0 = dx*(    x - 2*x^2 +   x^3)
   local l1 =             3*x^2 - 2*x^3
   local d1 = dx*(         -x^2 +   x^3)

   return l0,d0,l1,d1
end

function interp_fault(A,dx,dy)
  -- Find the ix and iy on the lower corner
  local ax = (dx-A.dx[1][1])/A.hx
  local ay = (dy-A.dy[1][1])/A.hy

  -- bounding grid points
  local ix = math.floor(ax)+1
  local iy = math.floor(ay)+1

  -- percent between grid points
  ax = ax-(ix-1)
  ay = ay-(iy-1)

  local lx0
  local dx0
  local lx1
  local dx1
  local ly0
  local dy0
  local ly1
  local dy1

  lx0,dx0,lx1,dx1 = interp_basis(ax,A.hx)
  ly0,dy0,ly1,dy1 = interp_basis(ay,A.hy)

  local jx = ix + 1
  local jy = iy + 1

  ix = max(1,min(ix,A.Nx+1))
  iy = max(1,min(iy,A.Ny+1))
  jx = max(1,min(jx,A.Nx+1))
  jy = max(1,min(jy,A.Ny+1))

  local f00 = A.dz[ix][iy]
  local f01 = A.dz[ix][jy]
  local f11 = A.dz[jx][jy]
  local f10 = A.dz[jx][iy]

  local fx00 = A.fx[ix][iy]
  local fx01 = A.fx[ix][jy]
  local fx11 = A.fx[jx][jy]
  local fx10 = A.fx[jx][iy]

  local fy00 = A.fy[ix][iy]
  local fy01 = A.fy[ix][jy]
  local fy11 = A.fy[jx][jy]
  local fy10 = A.fy[jx][iy]

  dz = lx0*ly0*f00 + dx0*ly0*fx00 + lx0*dy0*fy00 +
       lx1*ly0*f10 + dx1*ly0*fx10 + lx1*dy0*fy10 +
       lx0*ly1*f01 + dx0*ly1*fx01 + lx0*dy1*fy01 +
       lx1*ly1*f11 + dx1*ly1*fx11 + lx1*dy1*fy11

  return dz
end

fault = read_fault("tpv29_tpv30_geometry_25m_data.txt")

fault_stations = {
  "faultst-042dp061",  -4.2,  6.1, interp_fault(fault,  -4.2,  6.1), 0.0, 0.0, 1.0, 0.1,
  "faultst-050dp000",  -5.0,  0.0, interp_fault(fault,  -5.0,  0.0), 0.0, 0.0, 1.0, 0.1,
  "faultst-050dp100",  -5.0, 10.0, interp_fault(fault,  -5.0, 10.0), 0.0, 0.0, 1.0, 0.1,
  "faultst-050dp160",  -5.0, 16.0, interp_fault(fault,  -5.0, 16.0), 0.0, 0.0, 1.0, 0.1,
  "faultst-089dp101",  -8.9, 10.1, interp_fault(fault,  -8.9, 10.1), 0.0, 0.0, 1.0, 0.1,
  "faultst-110dp014", -11.0,  1.4, interp_fault(fault, -11.0,  1.4), 0.0, 0.0, 1.0, 0.1,
  "faultst-150dp050", -15.0,  5.0, interp_fault(fault, -15.0,  5.0), 0.0, 0.0, 1.0, 0.1,
  "faultst-150dp120", -15.0, 12.0, interp_fault(fault, -15.0, 12.0), 0.0, 0.0, 1.0, 0.1,
  "faultst-180dp156", -18.0, 15.6, interp_fault(fault, -18.0, 15.6), 0.0, 0.0, 1.0, 0.1,
  "faultst000dp120" ,   0.0, 12.0, interp_fault(fault,   0.0, 12.0), 0.0, 0.0, 1.0, 0.1,
  "faultst043dp062" ,   4.3,  6.2, interp_fault(fault,   4.3,  6.2), 0.0, 0.0, 1.0, 0.1,
  "faultst046dp060" ,   4.6,  6.0, interp_fault(fault,   4.6,  6.0), 0.0, 0.0, 1.0, 0.1,
  "faultst050dp000" ,   5.0,  0.0, interp_fault(fault,   5.0,  0.0), 0.0, 0.0, 1.0, 0.1,
  "faultst050dp120" ,   5.0, 12.0, interp_fault(fault,   5.0, 12.0), 0.0, 0.0, 1.0, 0.1,
  "faultst051dp057" ,   5.1,  5.7, interp_fault(fault,   5.1,  5.7), 0.0, 0.0, 1.0, 0.1,
  "faultst059dp047" ,   5.9,  4.7, interp_fault(fault,   5.9,  4.7), 0.0, 0.0, 1.0, 0.1,
  "faultst090dp153" ,   9.0, 15.3, interp_fault(fault,   9.0, 15.3), 0.0, 0.0, 1.0, 0.1,
  "faultst093dp153" ,   9.3, 15.3, interp_fault(fault,   9.3, 15.3), 0.0, 0.0, 1.0, 0.1,
  "faultst100dp050" ,  10.0,  5.0, interp_fault(fault,  10.0,  5.0), 0.0, 0.0, 1.0, 0.1,
  "faultst100dp110" ,  10.0, 11.0, interp_fault(fault,  10.0, 11.0), 0.0, 0.0, 1.0, 0.1,
  "faultst150dp000" ,  15.0,  0.0, interp_fault(fault,  15.0,  0.0), 0.0, 0.0, 1.0, 0.1,
  "faultst150dp130" ,  15.0, 13.0, interp_fault(fault,  15.0, 13.0), 0.0, 0.0, 1.0, 0.1,
  "faultst167dp105" ,  16.7, 10.5, interp_fault(fault,  16.7, 10.5), 0.0, 0.0, 1.0, 0.1,
  "faultst170dp045" ,  17.0,  4.5, interp_fault(fault,  17.0,  4.5), 0.0, 0.0, 1.0, 0.1,
}

volume_stations = {
  "body-030st-150dp000", -15.0, 0.0,  -3.0,
  "body-030st000dp000" ,   0.0, 0.0,  -3.0,
  "body-030st150dp000" ,  15.0, 0.0,  -3.0,
  "body-200st-200dp000", -20.0, 0.0, -20.0,
  "body-200st000dp000" ,   0.0, 0.0, -20.0,
  "body-200st200dp000" ,  20.0, 0.0, -20.0,
  "body030st-150dp000" , -15.0, 0.0,   3.0,
  "body030st000dp000"  ,   0.0, 0.0,   3.0,
  "body030st150dp000"  ,  15.0, 0.0,   3.0,
  "body200st-200dp000" , -20.0, 0.0,  20.0,
  "body200st000dp000"  ,   0.0, 0.0,  20.0,
  "body200st200dp000"  ,  20.0, 0.0,  20.0,
}
