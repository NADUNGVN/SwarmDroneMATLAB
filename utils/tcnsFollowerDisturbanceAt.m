function acceleration = tcnsFollowerDisturbanceAt(cfg,tk)
%TCNSFOLLOWERDISTURBANCEAT Deterministic DI excitation at physical time.
%
% Output is N-by-3 acceleration [m/s^2]. With no explicit Gate-6 schedule,
% it is exactly zero. Each configured episode is a full sine acceleration
% pulse, independent of the communication method and sampled by physical
% time rather than transmission events.

N = cfg.swarm.N;
acceleration = zeros(N,3);
if ~isfield(cfg,'tcns') || ~isfield(cfg.tcns,'diDisturbance') || ...
        isempty(cfg.tcns.diDisturbance)
    return;
end

D = cfg.tcns.diDisturbance;
required = {'tStart_s','duration_s','amplitude_mps2','axis','nodeMask'};
for q = 1:numel(required)
    if ~isfield(D,required{q})
        error('tcnsFollowerDisturbanceAt:MissingField', ...
            'diDisturbance.%s is required.',required{q});
    end
end

tStart = double(D.tStart_s(:));
duration = double(D.duration_s(:));
amplitude = double(D.amplitude_mps2(:));
axis = double(D.axis);
nodeMask = double(D.nodeMask);
nEpisode = numel(tStart);
if numel(duration)~=nEpisode || numel(amplitude)~=nEpisode || ...
        ~isequal(size(axis),[nEpisode 3]) || ...
        ~isequal(size(nodeMask),[nEpisode N]) || ...
        any(~isfinite([tStart;duration;amplitude]),'all') || ...
        any(duration<=0) || any(amplitude<0) || ...
        any(~isfinite(axis),'all') || any(~isfinite(nodeMask),'all')
    error('tcnsFollowerDisturbanceAt:InvalidSchedule', ...
        'Malformed deterministic follower-disturbance schedule.');
end
axisNorm = vecnorm(axis,2,2);
if any(abs(axisNorm-1)>1e-12) || any(nodeMask(:)<0)
    error('tcnsFollowerDisturbanceAt:InvalidDirection', ...
        'Episode axes must be unit vectors and node masks nonnegative.');
end

for q = 1:nEpisode
    tau = tk-tStart(q);
    if tau<0 || tau>duration(q)
        continue;
    end
    wave = amplitude(q)*sin(2*pi*tau/duration(q));
    acceleration = acceleration + nodeMask(q,:)'*(wave*axis(q,:));
end

% Agent 1 is analytical and cannot be disturbed by the follower integrator.
acceleration(1,:) = 0;

end
