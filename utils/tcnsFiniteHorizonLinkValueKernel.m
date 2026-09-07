function K = tcnsFiniteHorizonLinkValueKernel(cfg,horizonSamples,delaySamples)
%TCNSFINITEHORIZONLINKVALUEKERNEL Exact isolated link-update output kernel.
%
%   K = tcnsFiniteHorizonLinkValueKernel(cfg,H,D)
%
% Consider the exact Gate-3 degradation recurrence
%
%   delta_y(k+1) = Ah*delta_y(k) + Bc*d(k),
%
% and two unsaturated continuations that differ only because one payload
% update changes follower receiver i's command by a constant 3-D vector c
% from sample k+D onward. With zero initial difference and no later update
% on that link, the accumulated squared follower-position separation over
% the next H samples is
%
%   kappa_i(H,D) * ||c||_2^2.
%
% This function computes kappa exactly from the implemented sampled model.
% It is an isolated-action kernel, not a claim about total multi-link VoI:
% other simultaneous disturbances create cross terms, and saturation lies
% outside the identity.

validateattributes(horizonSamples,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'}, ...
    mfilename,'horizonSamples',2);
validateattributes(delaySamples,{'numeric'}, ...
    {'real','finite','integer','nonnegative','scalar'}, ...
    mfilename,'delaySamples',3);

certificate = tcnsFormationRobustnessCertificate(cfg);
A = certificate.Ah;
B = certificate.Bc;
m = numel(certificate.followers);
C = [eye(m),zeros(m)];

response = zeros(horizonSamples,m,m);
positionEnergyGain = zeros(m,1);

for inputFollower = 1:m
    state = zeros(2*m,1);
    for r = 1:horizonSamples
        active = (r-1)>=delaySamples;
        state = A*state+B(:,inputFollower)*double(active);
        position = C*state;
        response(r,:,inputFollower) = position;
        positionEnergyGain(inputFollower) = ...
            positionEnergyGain(inputFollower)+sum(position.^2);
    end
end

K.scope = [ ...
    'fixed symmetric grounded, exact-state, unsaturated DI subsystem; ' ...
    'one isolated persistent link-command correction'];
K.horizonSamples = double(horizonSamples);
K.delaySamples = double(delaySamples);
K.horizon_s = horizonSamples*cfg.swarm.dt;
K.delay_s = delaySamples*cfg.swarm.dt;
K.followers = certificate.followers;
K.positionResponse = response;
K.positionEnergyGain = positionEnergyGain;
K.positionMseGain = positionEnergyGain/m;
K.identity = [ ...
    'sum_{r=1}^H ||delta e(k+r)||_F^2 = ' ...
    'positionEnergyGain(i)*||c_i||_2^2 for the isolated correction'];

end
