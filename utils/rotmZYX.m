function R = rotmZYX(eul)
%ROTMZYX Rotation matrix from body to world using ZYX yaw-pitch-roll.
phi = eul(1); theta = eul(2); psi = eul(3);
cr = cos(phi);  sr = sin(phi);
cp = cos(theta); sp = sin(theta);
cy = cos(psi);  sy = sin(psi);
R = [cy*cp, cy*sp*sr - sy*cr, cy*sp*cr + sy*sr; ...
     sy*cp, sy*sp*sr + cy*cr, sy*sp*cr - cy*sr; ...
       -sp,               cp*sr,               cp*cr];
end
