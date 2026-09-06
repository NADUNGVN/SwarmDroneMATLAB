function [C,A]=applyCoherenceLeaseConfig(C,selector)
%APPLYCOHERENCELEASECONFIG Bind selected motion horizon to ELCS-W config.

requiredC={'N','frameLength','fallbackSlots','dataBytes','phyRateBps', ...
    'guardSec','refreshLeadFrames','leaseFenceFrames', ...
    'managementReach','maxControlPacketBytes'};
requiredS={'selectedIndex','selectedHorizonSec','selectedGraph', ...
    'selectedWitnessMap','hashExact','futureRandomReads', ...
    'receiverTruthDecisionReads'};
if ~isstruct(C) || ~all(isfield(C,requiredC)) || ...
        ~isstruct(selector) || ~all(isfield(selector,requiredS))
    error('applyCoherenceLeaseConfig: incomplete input.');
end
if selector.futureRandomReads~=0 || selector.receiverTruthDecisionReads~=0
    error('applyCoherenceLeaseConfig: selector is not causal.');
end

C.cumulativeReceiptRetry=true;
C.coherenceLeaseEnabled=true;
C.coherenceClaimBytes=28;
C.coherenceCertificateHeaderBytes=16;
C.coherenceCertificateEntryBytes=10;
C.coherenceRevokeBytes=24;
C.claimBytes=C.coherenceClaimBytes;
C.certificateHeaderBytes=C.coherenceCertificateHeaderBytes;
C.certificateEntryBytes=C.coherenceCertificateEntryBytes;
C.coherenceSelectorHash=selector.hashExact;
C.coherenceSelectedHorizonSec=selector.selectedHorizonSec;
C.coherenceSelectedGraphHash=0;
C.coherenceLeaseAdmissible=false;
C.coherenceHorizonFrames=0;

reason='selector-issued-no-horizon';
frameDuration=NaN; selectedFrames=0; maxWitnessLoad=0;
if selector.selectedIndex>0
    graph=logical(selector.selectedGraph.potentialGraph);
    physicalInterference=graph;
    if isfield(selector.selectedGraph,'senderConflictGraph')
        graph=logical(selector.selectedGraph.senderConflictGraph);
        physicalInterference=logical( ...
            selector.selectedGraph.potentialInterferenceGraph);
    end
    W=buildConflictWitnessMap(graph,C.managementReach);
    entriesPerPacket=floor((C.maxControlPacketBytes- ...
        C.certificateHeaderBytes)/C.certificateEntryBytes);
    maxWitnessLoad=max(W.responseEntryLoad);
    payloadFits=W.allCovered && maxWitnessLoad<=entriesPerPacket;
    frameDuration=physicalFrameDuration(C,W);
    selectedFrames=floor(selector.selectedHorizonSec/frameDuration+1e-12);
    minimumFrames=C.refreshLeadFrames+C.leaseFenceFrames+1;
    if W.allCovered && payloadFits && selectedFrames>=minimumFrames
        C.conflictGraph=graph;
        C.interferenceMatrix=physicalInterference;
        C.leaseFrames=selectedFrames;
        C.renewalPeriodFrames=selectedFrames-C.refreshLeadFrames- ...
            C.leaseFenceFrames;
        C.coherenceLeaseAdmissible=true;
        C.coherenceHorizonFrames=selectedFrames;
        C.coherenceSelectedGraphHash=selector.selectedGraph.hashExact;
        reason='admissible';
    elseif ~W.allCovered
        reason='witness-cover-incomplete';
    elseif ~payloadFits
        reason='coherence-response-exceeds-mtu';
    else
        reason='horizon-shorter-than-renewal-slack';
    end
end
if ~C.coherenceLeaseAdmissible
    % No positive certificate graph enters the scheduler. Physical
    % interference remains available to the fallback delivery model.
    C.conflictGraph=false(C.N);
end

A=struct('version','COHERENCE-ELCS-CONFIG-BINDING-v1', ...
    'admissible',C.coherenceLeaseAdmissible,'reason',reason, ...
    'selectedHorizonSec',selector.selectedHorizonSec, ...
    'physicalFrameDurationSec',frameDuration, ...
    'selectedHorizonFrames',selectedFrames, ...
    'renewalPeriodFrames',C.renewalPeriodFrames, ...
    'leaseFrames',C.leaseFrames,'maxWitnessLoad',maxWitnessLoad, ...
    'claimBytes',C.claimBytes, ...
    'certificateEntryBytes',C.certificateEntryBytes, ...
    'revokeBytes',C.coherenceRevokeBytes, ...
    'selectorHashExact',selector.hashExact, ...
    'futureRandomReads',0,'receiverTruthDecisionReads',0);
A.hashExact=realizationHash([double(A.admissible); ...
    A.selectedHorizonSec;A.physicalFrameDurationSec; ...
    A.selectedHorizonFrames;A.renewalPeriodFrames;A.leaseFrames; ...
    A.maxWitnessLoad;A.claimBytes;A.certificateEntryBytes; ...
    A.revokeBytes;A.selectorHashExact]);

end


function duration=physicalFrameDuration(C,W)
Ddata=8*C.dataBytes/C.phyRateBps;
Dclaim=8*C.claimBytes/C.phyRateBps;
claimPhase=C.N*(Dclaim+C.guardSec);
responseBytes=C.certificateHeaderBytes+ ...
    W.responseEntryLoad*C.certificateEntryBytes;
responseBytes(W.responseEntryLoad==0)=0;
responsePhase=0;
for node=1:C.N
    if responseBytes(node)>0
        responsePhase=responsePhase+8*responseBytes(node)/C.phyRateBps+ ...
            C.guardSec;
    end
end
dataPhase=(C.fallbackSlots+C.frameLength)*(Ddata+C.guardSec);
duration=claimPhase+responsePhase+dataPhase;
end
