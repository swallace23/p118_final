Tsim = 7200;
dtneu = 6;
lt = Tsim/dtneu;
lz = 15;
lx = 12;
velx = zeros(lt,lx,lz);
velz = zeros(lt,lx,lz);
temp = zeros(lt,lx,lz);
dox2s = zeros(lt,lx,lz);
dnit2s = zeros(lt,lx,lz);
doxs = zeros(lt,lx,lz);
neutral_temp = 890.111206;
delta_temp = 0.05*neutral_temp;
period = 10*60; %10 min period


function tp = temp_pert(t,delta_temp,period)
    tp = delta_temp*sin(2*pi*t/period);
end

for i=1:lt
    % index 7 is approx 320 km
    temp(i,4:8,7) = temp_pert(i*dtneu,delta_temp,period);
end
save("neutrals/velx.mat","velx")
save("neutrals/velz.mat","velz")
save("neutrals/temp.mat","temp")
save("neutrals/dox2s.mat","dox2s")
save("neutrals/dnit2s.mat","dnit2s")
save("neutrals/doxs.mat","doxs")




