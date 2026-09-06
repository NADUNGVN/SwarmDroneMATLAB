function [S,candidates]=distributedReservationStep( ...
    S,net,slot,tk,hasFrame,backgroundActive,mac,trace)
%DISTRIBUTEDRESERVATIONSTEP EXP21 local-clock and reservation projection.
%
% The routine deliberately exposes control-plane cost and imperfect local
% views.  It is an Aydin-inspired projection, not a bit-level reproduction.
% All stochastic choices use the present absolute slot index.

N=net.N;
C=S.config;
candidates=false(N,1);
required={'exp21ControlChoiceU','exp21RequestLossU', ...
    'exp21ResponseLossU','exp21CommitLossU', ...
    'exp21ClockOffsetU','exp21ClockDriftU'};
for k=1:numel(required)
    if ~isfield(trace,required{k})
        error('distributedReservationStep: trace lacks %s.',required{k});
    end
end
if slot>trace.K
    error('distributedReservationStep: trace is shorter than horizon.');
end

if ~S.reservationInitialized
    S.reservationClockOffsetSec=(2*trace.exp21ClockOffsetU(:)-1)* ...
        C.clockOffsetMaxSec;
    S.reservationClockDriftPpm=(2*trace.exp21ClockDriftU(:)-1)* ...
        C.clockDriftMaxPpm;
    if strcmp(C.mode,'local-static-tdma')
        S.reservationAssignedSlot=mod((1:N)'-1,C.reservationFrameSlots)+1;
        S.reservationSelfExpiry=inf(N,1);
        S.reservationKnownSlot=repmat( ...
            S.reservationAssignedSlot',N,1);
        S.reservationKnownExpiry=inf(N,N);
        S.reservationFirstConvergenceTime=0;
    end
    S.reservationInitialized=true;
end

activeSources=any(net.topology,1)';
if C.churnEnabled && ~S.reservationChurnApplied && ...
        tk>=C.churnTimeSec-1e-12
    node=C.churnNode;
    S.reservationAssignedSlot(node)=0;
    S.reservationSelfExpiry(node)=-inf;
    S.reservationKnownSlot(node,:)=0;
    S.reservationKnownExpiry(node,:)=-inf;
    S.reservationChurnApplied=true;
    S.reservationChurnAppliedTime=tk;
end

if strcmp(C.mode,'distributed-reservation')
    S=expireReservations(S,tk);
    if S.reservationControlBlockSlots>0
        S.reservationControlBlockSlots= ...
            S.reservationControlBlockSlots-1;
        return;
    end
    if tk>=S.reservationNextEpochTime-1e-12 && ...
            ~backgroundActive && isempty(net.active)
        S=runReservationEpoch(S,net,slot,tk,activeSources,mac,trace);
        while S.reservationNextEpochTime<=tk+1e-12
            S.reservationNextEpochTime= ...
                S.reservationNextEpochTime+C.reservationPeriod;
        end
        if S.reservationControlBlockSlots>0
            S.reservationControlBlockSlots= ...
                S.reservationControlBlockSlots-1;
        end
        S=sampleScheduleState(S,activeSources,tk);
        return;
    end
end

S=sampleScheduleState(S,activeSources,tk);
if backgroundActive || ~isempty(net.active) || ~any(hasFrame)
    return;
end

F=C.reservationFrameSlots;
phase=tk+S.reservationClockOffsetSec+ ...
    1e-6*S.reservationClockDriftPpm*tk;
localSlot=mod(floor((phase+1e-12)/mac.slotTime),F)+1;
assigned=S.reservationAssignedSlot;
candidates=hasFrame(:) & assigned>0 & localSlot==assigned;
S.reservationDataOpportunities=S.reservationDataOpportunities+ ...
    nnz(candidates);

end


function S=runReservationEpoch(S,net,slot,tk,activeSources,mac,trace)

C=S.config;
N=net.N;
F=C.reservationFrameSlots;
S.reservationEpochCount=S.reservationEpochCount+1;
oldAssigned=S.reservationAssignedSlot;

proposed=zeros(N,1);
for source=find(activeSources)'
    if S.reservationAssignedSlot(source)>0
        proposed(source)=S.reservationAssignedSlot(source);
        continue;
    end
    occupied=unique(S.reservationKnownSlot(source, ...
        S.reservationKnownSlot(source,:)>0));
    available=setdiff(1:F,occupied,'stable');
    if isempty(available), available=1:F; end
    u=trace.exp21ControlChoiceU(slot,source);
    index=min(numel(available),floor(u*numel(available))+1);
    proposed(source)=available(index);
end

heard=false(N,N); % observer, source
for source=find(activeSources)'
    recipients=find(C.controlReach(:,source));
    recipients(recipients==source)=[];
    if isempty(recipients), continue; end
    draws=reshape(trace.exp21RequestLossU(slot,recipients,source),[],1);
    success=draws<=1-C.controlLoss;
    heard(recipients(success),source)=true;
    S=chargeRecipients(S,numel(recipients),nnz(success));
end

positive=false(N,1);
negative=false(N,1);
responseFrames=0;
responseAirtime=0;
for observer=1:N
    sources=find(heard(observer,:));
    if isempty(sources), continue; end
    responseFrames=responseFrames+1;
    responseAirtime=responseAirtime+frameAirtime( ...
        C.responseBaseBytes+C.responseEntryBytes*numel(sources),mac);
    localSlots=proposed(sources);
    conflict=false(size(sources));
    for q=1:numel(sources)
        conflict(q)=nnz(localSlots==localSlots(q))>1;
    end
    for q=1:numel(sources)
        source=sources(q);
        delivered=C.controlReach(source,observer) && ...
            trace.exp21ResponseLossU(slot,source,observer)<=1-C.controlLoss;
        S=chargeRecipients(S,1,double(delivered));
        if delivered
            if conflict(q), negative(source)=true;
            else, positive(source)=true;
            end
        end
    end
end

accepted=false(N,1);
for source=find(activeSources)'
    if negative(source)
        S.reservationNackCount=S.reservationNackCount+1;
        if S.reservationAssignedSlot(source)>0
            S.reservationMigrationCount=S.reservationMigrationCount+1;
        end
        S.reservationAssignedSlot(source)=0;
        S.reservationSelfExpiry(source)=-inf;
    elseif positive(source)
        accepted(source)=true;
        S.reservationAssignedSlot(source)=proposed(source);
        S.reservationSelfExpiry(source)=tk+C.reservationLease;
    end
end

commitFrames=0;
for source=find(accepted)'
    commitFrames=commitFrames+1;
    S.reservationKnownSlot(source,source)=proposed(source);
    S.reservationKnownExpiry(source,source)=tk+C.reservationLease;
    recipients=find(C.controlReach(:,source));
    recipients(recipients==source)=[];
    if isempty(recipients), continue; end
    draws=reshape(trace.exp21CommitLossU(slot,recipients,source),[],1);
    success=draws<=1-C.controlLoss;
    delivered=recipients(success);
    S.reservationKnownSlot(delivered,source)=proposed(source);
    S.reservationKnownExpiry(delivered,source)=tk+C.reservationLease;
    S=chargeRecipients(S,numel(recipients),nnz(success));
end

requestFrames=nnz(activeSources);
S.reservationRequestFrames=S.reservationRequestFrames+requestFrames;
S.reservationResponseFrames=S.reservationResponseFrames+responseFrames;
S.reservationCommitFrames=S.reservationCommitFrames+commitFrames;
S.reservationControlFrames=S.reservationControlFrames+ ...
    requestFrames+responseFrames+commitFrames;
airtime=requestFrames*frameAirtime(C.requestBytes,mac)+ ...
    responseAirtime+ ...
    commitFrames*frameAirtime(C.commitBytes,mac);
S.reservationControlAirtime=S.reservationControlAirtime+airtime;
S.reservationControlBlockSlots=S.reservationControlBlockSlots+ ...
    ceil(airtime/mac.slotTime-1e-12);
S.reservationScheduleChanges=S.reservationScheduleChanges+ ...
    nnz(oldAssigned~=S.reservationAssignedSlot);

end


function S=expireReservations(S,tk)

expired=S.reservationKnownExpiry<tk-1e-12;
S.reservationKnownSlot(expired)=0;
S.reservationKnownExpiry(expired)=-inf;
selfExpired=S.reservationSelfExpiry<tk-1e-12;
S.reservationAssignedSlot(selfExpired)=0;

end


function S=sampleScheduleState(S,activeSources,tk)

assigned=S.reservationAssignedSlot(activeSources);
full=~isempty(assigned) && all(assigned>0) && ...
    numel(unique(assigned))==numel(assigned);
S.reservationScheduleSamples=S.reservationScheduleSamples+1;
S.reservationConflictSamples=S.reservationConflictSamples+double(~full);
if full && isnan(S.reservationFirstConvergenceTime)
    S.reservationFirstConvergenceTime=tk;
end
if full && S.reservationChurnApplied && isnan(S.reservationRecoveryTime)
    S.reservationRecoveryTime=tk-S.reservationChurnAppliedTime;
end

end


function S=chargeRecipients(S,attempts,successes)

S.reservationControlRecipientAttempts= ...
    S.reservationControlRecipientAttempts+attempts;
S.reservationControlRecipientSuccess= ...
    S.reservationControlRecipientSuccess+successes;
S.reservationControlRecipientLoss= ...
    S.reservationControlRecipientLoss+attempts-successes;

end


function value=frameAirtime(bytes,mac)

value=max(mac.slotTime,ceil((8*bytes/mac.phyRateBps)/mac.slotTime-1e-12)* ...
    mac.slotTime);

end

