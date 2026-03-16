Tsim = 86400;
dtneu = 6;
lt = Tsim/dtneu + 1;

lz = 15; lx = 12;
velx = zeros(lt,lx,lz);
velz = zeros(lt,lx,lz);
temp = zeros(lt,lx,lz);
dox2s = zeros(lt,lx,lz);
dnit2s = zeros(lt,lx,lz);
doxs = zeros(lt,lx,lz);

neutral_temp = 890.111206;
delta_temp = 0.05*neutral_temp;
delta_frac = 0.02;      % 2% density perturbation
delta_vz = 30;          % m/s
period = 600;           % 10 min

for i = 1:lt
    s = sin(2*pi*(i-1)*dtneu/period);
    temp(i,4:8,7)   = delta_temp*s;
    velz(i,4:8,7)   = delta_vz*s;
    doxs(i,4:8,7)   = delta_frac*s;
    dox2s(i,4:8,7)  = delta_frac*s;
    dnit2s(i,4:8,7) = delta_frac*s;
end