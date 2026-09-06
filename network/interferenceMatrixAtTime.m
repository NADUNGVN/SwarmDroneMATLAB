function matrix=interferenceMatrixAtTime(baseMatrix,transitions,t)
%INTERFERENCEMATRIXATTIME Apply public interference-graph events due by t.

% transitions is a time-ordered struct array with fields timeSec and
% newMatrix.  This changes collision physics only; protocol decisions never
% read receiver outcomes through this interface.

matrix=logical(baseMatrix);
N=size(matrix,1);
if ~isequal(size(matrix),[N N]) || isempty(matrix)
    error('interferenceMatrixAtTime: invalid base matrix.');
end
if isempty(transitions), return; end
if ~isstruct(transitions) || ...
        ~all(isfield(transitions,{'timeSec','newMatrix'})) || ...
        ~isscalar(t) || ~isfinite(t)
    error('interferenceMatrixAtTime: invalid transition schedule.');
end
times=reshape([transitions.timeSec],[],1);
if any(~isfinite(times)) || any(times<0) || any(diff(times)<0)
    error('interferenceMatrixAtTime: transition times must be ordered.');
end
for k=1:numel(transitions)
    value=transitions(k).newMatrix;
    if ~isequal(size(value),[N N]) || any(~isfinite(value(:))) || ...
            any(value(:)~=0 & value(:)~=1)
        error('interferenceMatrixAtTime: invalid transition payload.');
    end
    if times(k)<=t+1e-12, matrix=logical(value); end
end

end
