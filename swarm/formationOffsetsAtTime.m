function offsets=formationOffsetsAtTime(baseOffsets,transitions,t)
%FORMATIONOFFSETSATTIME Apply public formation-offset commands due by t.

% transitions is a time-ordered struct array with fields timeSec, node and
% newOffset.  A finite optional endTimeSec linearly ramps from the base
% offset to newOffset; otherwise the change is a step.  These are commanded
% references, not sampled plant future.

offsets=double(baseOffsets);
if isempty(transitions), return; end
if ~isstruct(transitions) || ...
        ~all(isfield(transitions,{'timeSec','node','newOffset'})) || ...
        ~isscalar(t) || ~isfinite(t)
    error('formationOffsetsAtTime: invalid transition schedule.');
end
times=reshape([transitions.timeSec],[],1);
if any(~isfinite(times)) || any(times<0) || any(diff(times)<0)
    error('formationOffsetsAtTime: transition times must be ordered.');
end
N=size(offsets,1); D=size(offsets,2);
for k=1:numel(transitions)
    node=transitions(k).node;
    value=reshape(double(transitions(k).newOffset),1,[]);
    if ~isscalar(node) || node<1 || node>N || node~=floor(node) || ...
            numel(value)~=D || any(~isfinite(value))
        error('formationOffsetsAtTime: invalid transition payload.');
    end
    if times(k)<=t+1e-12
        if isfield(transitions,'endTimeSec') && ...
                ~isempty(transitions(k).endTimeSec)
            finish=transitions(k).endTimeSec;
            if ~isscalar(finish) || ~isfinite(finish) || finish<=times(k)
                error('formationOffsetsAtTime: invalid ramp end time.');
            end
            alpha=min(1,max(0,(t-times(k))/(finish-times(k))));
            offsets(node,:)=(1-alpha)*baseOffsets(node,:)+alpha*value;
        else
            offsets(node,:)=value;
        end
    end
end

end
