function cfg = applyPlantPerturbation(cfg, arm)
%APPLYPLANTPERTURBATION Build the TRUE plant for one EXP09B arm.
%
%   cfg = applyPlantPerturbation(cfg, arm)
%
% arm is a struct with fields wind, massFactor, dragFactor, lagTau.
%
% Only the TRUE plant changes. cfg.quad stays nominal and is what the
% controller reads, which is the entire point of the mismatch study: a
% controller retuned to the perturbed plant would measure the quality of
% the retuning rather than the robustness of the communication policy.
%
% maxThrust and maxTorque are NOT scaled with mass. They are properties of
% the motors, not of the payload, and scaling them would quietly change the
% actuator authority at the same time as the inertia - two effects that
% could not then be separated.
%
% Inertia J is left nominal as well: the pre-registered sweep perturbs mass
% and drag only.

cfg.quadTrue = cfg.quad;

cfg.quadTrue.m = cfg.quad.m * arm.massFactor;

cfg.quadTrue.linearDrag = cfg.quad.linearDrag * arm.dragFactor;

cfg.actuator.tau = arm.lagTau;

cfg.extForce = generateExternalForceTrace(cfg, arm.wind);

end
