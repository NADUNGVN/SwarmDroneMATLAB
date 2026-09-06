function trace=applyMarkovBackgroundStateTrace(trace,pOffToOn,pOnToOff)
%APPLYMARKOVBACKGROUNDSTATETRACE Create a stationary two-state load trace.
%
% The existing absolute backgroundU field drives every transition. State 1
% means that an exogenous transmission occupies the entire MAC quantum.

if ~isstruct(trace) || ~isfield(trace,'backgroundU') || ...
        ~isfield(trace,'hashExact')
    error('applyMarkovBackgroundStateTrace: invalid shared trace.');
end
for p=[pOffToOn pOnToOff]
    if ~isscalar(p) || ~isfinite(p) || p<0 || p>1
        error('applyMarkovBackgroundStateTrace: invalid transition.');
    end
end
if pOffToOn+pOnToOff<=0
    error('applyMarkovBackgroundStateTrace: chain cannot be static unknown.');
end
u=trace.backgroundU(:);
stationary=pOffToOn/(pOffToOn+pOnToOff);
state=false(size(u));
state(1)=u(1)<stationary;
for k=2:numel(u)
    if state(k-1)
        state(k)=u(k)>=pOnToOff;
    else
        state(k)=u(k)<pOffToOn;
    end
end
baseHash=trace.hashExact;
trace.backgroundBaseTraceHashExact=baseHash;
trace.measuredBackgroundActive=state;
trace.backgroundModel='two-state-markov-occupancy';
trace.backgroundOffToOn=pOffToOn;
trace.backgroundOnToOff=pOnToOff;
trace.backgroundStationaryFraction=stationary;
trace.backgroundRealizedFraction=mean(state);
trace.backgroundStateHashExact=realizationHash(double(state));
trace.hashExact=realizationHash([baseHash;pOffToOn;pOnToOff; ...
    double(state)]);

end
