function ideal = tcnsPerfectInformationContinuation(out,cfg,startIndex)
%TCNSPERFECTINFORMATIONCONTINUATION Counterfactual Gate-3 DI continuation.
%
%   ideal = tcnsPerfectInformationContinuation(out,cfg,startIndex)
%
% Starting from the recorded true state at STARTINDEX, propagate the exact
% double-integrator plant with the same analytical leader and controller but
% perfect current neighbor/leader information. This is a deterministic
% counterfactual used to measure communication-induced formation degradation.
% It is not the historical "ideal ACK" policy, which still uses stale DATA.

validateattributes(startIndex,{'numeric'}, ...
    {'real','finite','integer','positive','scalar'},mfilename,'startIndex',3);

if isfield(cfg,'sixdof') && isfield(cfg.sixdof,'enable') ...
        && cfg.sixdof.enable
    error('tcnsPerfectInformationContinuation:SixDofOutOfScope', ...
        'The Gate-3 counterfactual is defined for the DI subsystem.');
end
if isfield(cfg,'estimator') && ~isempty(cfg.estimator)
    error('tcnsPerfectInformationContinuation:EstimatorOutOfScope', ...
        'The first Gate-3 counterfactual requires exact local state.');
end

Kfull = numel(out.t);
if startIndex>Kfull
    error('tcnsPerfectInformationContinuation:StartIndex', ...
        'startIndex exceeds the recorded trajectory length.');
end

t = out.t(startIndex:end);
K = numel(t);
N = cfg.swarm.N;
P = reshape(out.P(startIndex,:,:),N,3);
V = reshape(out.V(startIndex,:,:),N,3);

Plog = zeros(K,N,3);
Vlog = zeros(K,N,3);
Alog = zeros(K,N,3);
six = [];

for k = 1:K
    tk = t(k);
    leader = leaderReference(tk);
    P(1,:) = leader.pos';
    V(1,:) = leader.vel';
    accCmd = distributedFormationPolicy(P,V,leader,cfg);

    Plog(k,:,:) = P;
    Vlog(k,:,:) = V;
    Alog(k,:,:) = accCmd;

    if k<K
        [P,V,six] = integrateFollowers(P,V,accCmd,six,cfg,tk);
    end
end

ideal.t = t;
ideal.P = Plog;
ideal.V = Vlog;
ideal.A = Alog;
ideal.startIndex = startIndex;
ideal.initialStateCopiedExactly = ...
    isequaln(Plog(1,:,:),out.P(startIndex,:,:)) && ...
    isequaln(Vlog(1,:,:),out.V(startIndex,:,:));
ideal.maxFollowerAcceleration = max(vecnorm( ...
    reshape(Alog(:,2:end,:),[],3),2,2));
ideal.scope = 'perfect-current-information DI continuation';

end
