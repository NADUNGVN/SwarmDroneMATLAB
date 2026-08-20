function eulDot = eulerRatesZYX(eul, omega)
%EULERRATESZYX Convert body angular rates to ZYX Euler angle rates.
phi = eul(1); theta = eul(2);
ct = cos(theta);
if abs(ct) < 1e-4
    ct = sign(ct + eps) * 1e-4;
end
T = [1, sin(phi)*tan(theta), cos(phi)*tan(theta); ...
     0, cos(phi),           -sin(phi); ...
     0, sin(phi)/ct,         cos(phi)/ct];
eulDot = T * omega;
end
