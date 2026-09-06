function row=analyzeAckBranchPair(actual,shadow,cfg,selection)
%ANALYZEACKBRANCHPAIR Extract one prehistory-matched causal ACK intervention.

required=fieldnames(exp14gEmptyCandidateRow());
if ~isstruct(selection) || ~all(isfield(selection,required))
    error('analyzeAckBranchPair: selection schema mismatch.');
end
A=actual.ackAdmissionLog([actual.ackAdmissionLog.isTarget]);
S=shadow.ackAdmissionLog([shadow.ackAdmissionLog.isTarget]);
if ~isscalar(A) || ~isscalar(S)
    error('analyzeAckBranchPair: each branch must reach one target.');
end
if A.candidateOrdinal~=selection.candidateOrdinal || ...
        S.candidateOrdinal~=selection.candidateOrdinal || ...
        A.time~=S.time || A.node~=S.node || A.nEntries~=S.nEntries || ...
        ~isequal(A.targetSenders,S.targetSenders) || ...
        ~isequal(A.seqs,S.seqs) || ~isequal(A.genTimes,S.genTimes)
    error('analyzeAckBranchPair: target identity mismatch.');
end
if entryHash(A)~=selection.entryHash || entryHash(S)~=selection.entryHash
    error('analyzeAckBranchPair: target entry hash differs from selection.');
end
if A.preNetworkHash~=S.preNetworkHash || ...
        A.preContextHash~=S.preContextHash || ...
        A.preNetworkHash~=selection.preNetworkHash || ...
        A.preContextHash~=selection.preContextHash
    error('analyzeAckBranchPair: pre-decision state mismatch.');
end


function h=entryHash(e)

h=realizationHash(double([e.nEntries; e.targetSenders(:); -1; ...
    e.seqs(:); -2; e.genTimes(:)]));

end
if ~A.physicalAdmitted || S.physicalAdmitted || ...
        ~strcmp(A.intervention,'admit-target') || ...
        ~strcmp(S.intervention,'suppress-target') || ...
        S.suppressedEntries~=S.nEntries
    error('analyzeAckBranchPair: intervention semantics mismatch.');
end
if actual.traceHashExact~=shadow.traceHashExact || ...
        actual.channelStateHash~=shadow.channelStateHash
    error('analyzeAckBranchPair: branch traces differ.');
end

windowEnd=actual.t(end);
if abs(windowEnd-shadow.t(end))>1e-12 || ...
        windowEnd<A.time+cfg.shared.ackBranchReplay.localHorizon-1e-12
    error('analyzeAckBranchPair: local outcome horizon is invalid.');
end

leads=zeros(A.nEntries,1);
actualConfirmed=false(A.nEntries,1);
shadowConfirmed=false(A.nEntries,1);
for k=1:A.nEntries
    ea=firstCrossing(actual.ackValueLog,A.node,A.targetSenders(k), ...
        A.genTimes(k),A.time,windowEnd);
    es=firstCrossing(shadow.ackValueLog,A.node,A.targetSenders(k), ...
        A.genTimes(k),A.time,windowEnd);
    if ~isempty(ea), actualConfirmed(k)=true; tauA=ea.time; else, tauA=windowEnd; end
    if ~isempty(es)
        shadowConfirmed(k)=true; tauS=es.time;
        if ~strcmp(es.transport,'data')
            error(['analyzeAckBranchPair: protected shadow confirmation ' ...
                'did not use piggyback DATA.']);
        end
    else
        tauS=windowEnd;
    end
    leads(k)=max(tauS-tauA,0);
end

MA=computeSwarmMetrics(actual,cfg);
MS=computeSwarmMetrics(shadow,cfg);
idx=actual.t>=A.time-1e-12 & actual.t<=windowEnd+1e-12;
lossA=mean(MA.formationError(idx,2:cfg.swarm.N).^2,2);
lossS=mean(MS.formationError(idx,2:cfg.swarm.N).^2,2);
trueBenefit=trapz(actual.t(idx),shadow.meanAoI(idx)-actual.meanAoI(idx));
estBenefit=trapz(actual.t(idx), ...
    shadow.meanEstimatedAoI(idx)-actual.meanEstimatedAoI(idx));
controlBenefit=trapz(actual.t(idx),lossS-lossA);

ackCost=actual.netStats.ackAirtime-shadow.netStats.ackAirtime;
dataSaved=shadow.netStats.dataAirtime-actual.netStats.dataAirtime;
netBenefit=(shadow.netStats.dataAirtime+shadow.netStats.ackAirtime) ...
    -(actual.netStats.dataAirtime+actual.netStats.ackAirtime);

row=exp14gEmptyPairRow();
copy={'seed','scenario','scenarioLabel','N','candidateOrdinal', ...
    'selectionRank','node','nEntries','entryHash','pendingAge', ...
    'localBusy','forced','queueDepth','preNetworkHash','preContextHash'};
for k=1:numel(copy), row.(copy{k})=selection.(copy{k}); end
row.decisionTime=A.time; row.windowEnd=windowEnd;
row.realizedHorizon=windowEnd-A.time;
row.actualTargetReached=actual.ackBranchState.targetReached;
row.shadowTargetReached=shadow.ackBranchState.targetReached;
row.actualTargetAdmitted=A.physicalAdmitted;
row.shadowTargetAdmitted=S.physicalAdmitted;
row.suppressedEntries=S.suppressedEntries;
row.actualConfirmedEntries=sum(actualConfirmed);
row.shadowConfirmedEntries=sum(shadowConfirmed);
row.positiveLeadEntries=sum(leads>1e-12);
row.actualCensoredEntries=sum(~actualConfirmed);
row.shadowCensoredEntries=sum(~shadowConfirmed);
row.meanLeadSeconds=mean(leads); row.maxLeadSeconds=max(leads);
row.ackAirtimeCost=ackCost; row.dataAirtimeSaved=dataSaved;
row.netAirtimeBenefit=netBenefit;
row.accountingResidual=netBenefit-(dataSaved-ackCost);
row.dataAttemptsSaved=shadow.netStats.dataFramesAttempted ...
    -actual.netStats.dataFramesAttempted;
row.collisionsSaved=shadow.netStats.collisionFrames ...
    -actual.netStats.collisionFrames;
row.trueAoIIntegralBenefit=trueBenefit;
row.estimatedAoIIntegralBenefit=estBenefit;
row.controlLossIntegralBenefit=controlBenefit;
row.minimumSeparationBenefit=localMinSeparation(actual.P(idx,:,:)) ...
    -localMinSeparation(shadow.P(idx,:,:));
row.actualInvariantViolations=actual.invariantViolations;
row.shadowInvariantViolations=shadow.invariantViolations;
row.actualDiverged=double(any(~isfinite(actual.P(:))));
row.shadowDiverged=double(any(~isfinite(shadow.P(:))));
row.TRACE_HASH_EXACT=actual.traceHashExact;
row.CHANNEL_STATE_HASH=actual.channelStateHash;

end


function value=localMinSeparation(P)

N=size(P,2);
value=inf;
for i=1:N-1
    for j=i+1:N
        d=sqrt(sum((P(:,i,:)-P(:,j,:)).^2,3));
        value=min(value,min(d));
    end
end

end


function e=firstCrossing(E,source,target,generation,t0,t1)

if isempty(E), e=[]; return; end
idx=[E.sourceReceiver]==source & [E.targetSender]==target & ...
    [E.genTime]>=generation-1e-12 & [E.time]>=t0-1e-12 & ...
    [E.time]<=t1+1e-12;
q=find(idx,1,'first');
if isempty(q), e=[]; else, e=E(q); end

end
