function ref = setpointFromAccel(pk, vk, accCmd, tau, yaw)
%SETPOINTFROMACCEL Reference for the inner loop, from one held acceleration.
%
%   ref = setpointFromAccel(pk, vk, accCmd, tau, yaw)
%
% What is held over the outer interval is the COMMANDED ACCELERATION. The
% position and velocity references are its analytic integrals from the outer
% sample (pk, vk):
%
%   ref.acc      = accCmd
%   ref.vel(tau) = vk + accCmd * tau
%   ref.pos(tau) = pk + vk * tau + 0.5 * accCmd * tau^2
%
% This is an ANALYTIC COMMAND-CONSISTENT REFERENCE. It is deliberately NOT
% described as bit-identical to the semi-implicit Euler update the locked
% double-integrator simulators use. Those advance the state as
%
%   v_{k+1} = v_k + dt*a_k ;  p_{k+1} = p_k + dt*v_{k+1}
%
% which places p_{k+1} at pk + vk*dt + dt^2*a_k, whereas the analytic
% reference reaches pk + vk*dt + 0.5*dt^2*a_k at the end of the interval.
% The two differ by 0.5*dt^2*a_k per step by construction. The reference is
% the exact trajectory the held command defines; the locked integrator is a
% first-order scheme. Claiming equivalence would misstate what the 6-DOF
% comparison measures.
%
% Freezing ref.pos at pk for the whole interval would be worse than
% inaccurate. The drone moves during the interval, so ep = ref.pos - p
% becomes the negative of its own displacement and KpPos*ep pulls back
% against the acceleration just commanded. The quad's outer loop would
% become a second position regulator fighting the formation policy, and the
% measured gap from the double-integrator would report an interface bug
% rather than 6-DOF dynamics.
%
% Inputs are row or column 3-vectors; outputs are columns, as the controller
% expects.

pk     = pk(:);
vk     = vk(:);
accCmd = accCmd(:);

ref.acc = accCmd;
ref.vel = vk + accCmd * tau;
ref.pos = pk + vk * tau + 0.5 * accCmd * tau^2;
ref.yaw = yaw;

end
