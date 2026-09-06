function M=matchAckValueEvents(actualEvents,shadowEvents,horizon)
%MATCHACKVALUEEVENTS Match accepted standalone ACKs to a full shadow policy.
%
% For each accepted standalone confirmation in actualEvents, the match is
% the first confirmation on the same directed link in shadowEvents whose
% generation time is at least the actual confirmed generation.  Lead is
% horizon-capped and cannot be negative.  A missing shadow crossing is
% retained as a right-censored observation rather than discarded.

tol=1e-12;
validateEventLog(actualEvents,'actualEvents',tol);
validateEventLog(shadowEvents,'shadowEvents',tol);
if ~isscalar(horizon) || ~isfinite(horizon) || horizon<0
    error('matchAckValueEvents: horizon must be a finite nonnegative scalar.');
end

template=emptyMatch();
M=repmat(template,0,1);
if isempty(actualEvents)
    return;
end

standalone=find(strcmp(string({actualEvents.transport}),'ack'));
for k=1:numel(standalone)
    a=actualEvents(standalone(k));
    if a.time>horizon+tol
        error('matchAckValueEvents: actual event occurs after the horizon.');
    end

    sameLink=[shadowEvents.sourceReceiver]==a.sourceReceiver & ...
        [shadowEvents.targetSender]==a.targetSender;
    crosses=[shadowEvents.genTime]>=a.genTime-tol;
    idx=find(sameLink & crosses,1,'first');

    m=template;
    m.sourceReceiver=a.sourceReceiver;
    m.targetSender=a.targetSender;
    m.actualSeq=a.seq;
    m.actualGenTime=a.genTime;
    m.actualTime=a.time;
    m.actualFrameId=a.frameId;
    m.actualBytes=a.bytes;
    if isempty(idx)
        m.shadowSeq=NaN;
        m.shadowGenTime=NaN;
        m.shadowTime=NaN;
        m.leadSeconds=max(horizon-a.time,0);
        m.isEarlier=m.leadSeconds>tol;
        m.shadowEarlierOrEqual=false;
        m.censored=true;
    else
        s=shadowEvents(idx);
        m.shadowSeq=s.seq;
        m.shadowGenTime=s.genTime;
        m.shadowTime=s.time;
        m.leadSeconds=max(min(s.time,horizon)-a.time,0);
        m.isEarlier=s.time>a.time+tol;
        m.shadowEarlierOrEqual=s.time<=a.time+tol;
        m.censored=false;
    end
    M(end+1,1)=m; %#ok<AGROW>
end

end


function m=emptyMatch()

m=struct( ...
    'sourceReceiver',0, ...
    'targetSender',0, ...
    'actualSeq',0, ...
    'actualGenTime',NaN, ...
    'actualTime',NaN, ...
    'actualFrameId',0, ...
    'actualBytes',0, ...
    'shadowSeq',NaN, ...
    'shadowGenTime',NaN, ...
    'shadowTime',NaN, ...
    'leadSeconds',NaN, ...
    'isEarlier',false, ...
    'shadowEarlierOrEqual',false, ...
    'censored',false);

end


function validateEventLog(E,name,tol)

required={'time','sourceReceiver','targetSender','seq','genTime', ...
    'transport','frameId','frameSender','txStart','txEnd','bytes'};
if ~isstruct(E) || ~all(isfield(E,required))
    error('matchAckValueEvents: %s does not satisfy ACK-VALUE-EVENT-v1.',name);
end
if isempty(E)
    return;
end

numericFields={'time','sourceReceiver','targetSender','seq','genTime', ...
    'frameId','frameSender','txStart','txEnd','bytes'};
for f=1:numel(numericFields)
    values=[E.(numericFields{f})];
    if numel(values)~=numel(E) || any(~isfinite(values))
        error('matchAckValueEvents: %s has invalid %s values.', ...
            name,numericFields{f});
    end
end
if any(diff([E.time]) < -tol)
    error('matchAckValueEvents: %s is not time ordered.',name);
end
if any([E.time]<-tol) || any([E.genTime]>[E.time]+tol) || ...
        any([E.txStart]>[E.txEnd]+tol) || any([E.txEnd]>[E.time]+tol)
    error('matchAckValueEvents: %s violates temporal ordering.',name);
end
integerFields={'sourceReceiver','targetSender','seq','frameId','frameSender'};
for f=1:numel(integerFields)
    values=[E.(integerFields{f})];
    if any(values<1) || any(values~=floor(values))
        error('matchAckValueEvents: %s has invalid integer identities.',name);
    end
end
if any([E.bytes]<=0) || ...
        any(~ismember(string({E.transport}),["ack" "data"]))
    error('matchAckValueEvents: %s has invalid transport metadata.',name);
end

links=unique([[E.sourceReceiver]' [E.targetSender]'],'rows');
for k=1:size(links,1)
    idx=[E.sourceReceiver]'==links(k,1) & ...
        [E.targetSender]'==links(k,2);
    if any(diff([E(idx).genTime]) < -tol) || any(diff([E(idx).seq])<0)
        error('matchAckValueEvents: %s rolls back within a link.',name);
    end
end

end
