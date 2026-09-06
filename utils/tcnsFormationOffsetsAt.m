function offsets = tcnsFormationOffsetsAt(cfg,tk)
%TCNSFORMATIONOFFSETSAT Desired formation offsets at physical time tk.
%
% With no cfg.tcns.formationSchedule this returns cfg.swarm.offsets exactly.
% A schedule contains tick-aligned knot times and a K-by-N-by-3 offset array;
% piecewise-linear interpolation provides continuous formation maneuvers.

offsets = cfg.swarm.offsets;
if ~isfield(cfg,'tcns') || ~isfield(cfg.tcns,'formationSchedule') || ...
        isempty(cfg.tcns.formationSchedule)
    return;
end

S = cfg.tcns.formationSchedule;
required = {'time_s','offsets'};
for q = 1:numel(required)
    if ~isfield(S,required{q})
        error('tcnsFormationOffsetsAt:MissingField', ...
            'formationSchedule.%s is required.',required{q});
    end
end

times = double(S.time_s(:));
values = double(S.offsets);
N = cfg.swarm.N;
if numel(times)<2 || any(~isfinite(times)) || any(diff(times)<=0) || ...
        ~isequal(size(values),[numel(times) N 3]) || ...
        any(~isfinite(values),'all')
    error('tcnsFormationOffsetsAt:InvalidSchedule', ...
        'Schedule must have increasing times and K-by-N-by-3 finite offsets.');
end
if any(abs(times/cfg.swarm.dt-round(times/cfg.swarm.dt))>1e-10)
    error('tcnsFormationOffsetsAt:OffGrid', ...
        'Every formation-schedule knot must lie on an outer control tick.');
end

if tk<=times(1)
    offsets = reshape(values(1,:,:),N,3);
    return;
end
if tk>=times(end)
    offsets = reshape(values(end,:,:),N,3);
    return;
end

left = find(times<=tk+1e-12,1,'last');
right = left+1;
lambda = (tk-times(left))/(times(right)-times(left));
offsets = (1-lambda)*reshape(values(left,:,:),N,3) + ...
    lambda*reshape(values(right,:,:),N,3);

end
