function rows=runExp23tStaticCoherenceSeed(seedValue,R)
%RUNEXP23TSTATICCOHERENCESEED Execute paired periodic/short/target arms.

c=R.cells(1); condition=R.conditions(1);
base=applyExp21dClosedLoopCell(c.id,seedValue);
base.mac.backgroundLoad=condition.targetLoad;
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base);
N=base.swarm.N;
offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)*R.maxOffsetSec;
drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
clockSpec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'leadTimeSec',R.clockLeadTimeSec);
rows=repmat(exp23tStaticCoherenceClosedLoopEmptyRow(),numel(R.arms),1);

for k=1:numel(R.arms)
    arm=R.arms(k);
    selector=[]; binding=[]; C=[];
    if strcmp(arm.family,'periodic-static')
        local=arm; local.periodicRateHz=c.lowerCostRateHz;
        [cfg,method,label,details]=applyExp22fStaticArm(base,local,R);
    else
        C=elcsWitnessKernelConfig(N,R.elcsMaxFrames);
        C.guardSec=R.missionSafeGuardSec;
        C.dataBytes=base.mac.dataBytes;
        C.phyRateBps=base.mac.phyRateBps;
        C.neighborGraph=logical(base.swarm.A);
        C.managementReach=C.neighborGraph;
        C.interferenceMatrix=logical(base.mac.interferenceMatrix);
        C.claimBytes=R.claimBytes;
        C.certificateHeaderBytes=R.certificateHeaderBytes;
        C.certificateEntryBytes=R.certificateEntryBytes;
        C.maxControlPacketBytes=R.maxControlPacketBytes;
        selectorConfig=struct('maxDataSlots',N, ...
            'claimBytes',R.claimBytes, ...
            'certificateHeaderBytes',R.certificateHeaderBytes, ...
            'certificateEntryBytes',R.certificateEntryBytes, ...
            'maxControlPacketBytes',R.maxControlPacketBytes);
        selector=buildStaticBroadcastCoherenceSelector( ...
            C.neighborGraph,C.interferenceMatrix,C.managementReach, ...
            arm.horizonSec,selectorConfig);
        [C,binding]=applyCoherenceLeaseConfig(C,selector);
        if ~binding.admissible
            error('exp23t: registered static topology is inadmissible.');
        end
        elcsTrace=generateElcsWitnessTrace(seedValue,C);
        [elcsTrace,backgroundCertificate]= ...
            applySharedBackgroundToElcsWitnessTrace( ...
            elcsTrace,C,trace,clockSpec,condition.targetLoad);
        nativeQ=buildElcsWitnessContinuousSchedule(C,elcsTrace,base.swarm.T);
        nativeQ.backgroundOverlay=backgroundCertificate;
        nativeQ.hashExact=realizationHash([ ...
            nativeQ.hashExact;backgroundCertificate.hashExact]);
        [cfg,method,label,details]=applyExp23cWitnessClockArm( ...
            base,arm,nativeQ,trace,R);
        details.kind=char(arm.kind);
        details.retryMode='coherence-cumulative-static';
    end
    meta=struct('stage',R.stage,'scenario',c.id, ...
        'scenarioLabel',c.label,'family','EXP23T static coherence', ...
        'arm',arm.id,'pointIndex',k,'parameterValue',arm.horizonSec);
    [src,~]=runExp23fWitnessBackgroundCell( ...
        cfg,method,label,meta,trace,details,arm.family,condition);
    row=exp23tStaticCoherenceClosedLoopEmptyRow();
    fields=fieldnames(src);
    for f=1:numel(fields), row.(fields{f})=src.(fields{f}); end
    if ~isempty(selector)
        row.STATIC_SELECTOR_HASH_EXACT=selector.hashExact;
        row.STATIC_GRAPH_HASH_EXACT=selector.selectedGraph.hashExact;
        row.STATIC_SELECTED_HORIZON_SEC=selector.selectedHorizonSec;
        row.STATIC_SELECTED_HORIZON_FRAMES=binding.selectedHorizonFrames;
        row.STATIC_BINDING_ADMISSIBLE=double(binding.admissible);
        row.STATIC_CONFLICT_EDGES=selector.selectedGraph.edgeCount;
        row.STATIC_MAX_WITNESS_LOAD=binding.maxWitnessLoad;
        row.STATIC_CLAIM_PACKET_BYTES=C.claimBytes;
        row.STATIC_CERTIFICATE_HEADER_BYTES=C.certificateHeaderBytes;
        row.STATIC_CERTIFICATE_ENTRY_BYTES=C.certificateEntryBytes;
        row.STATIC_REVOKE_PACKET_BYTES=C.coherenceRevokeBytes;
        row.STATIC_MAX_RESPONSE_PACKET_BYTES=max( ...
            nativeQ.kernel.debug.certificateBytes,[],'all');
    end
    rows(k)=row;
end

end
