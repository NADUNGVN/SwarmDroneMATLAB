function rows=runExp23uDynamicClosedLoopSeed(seedValue,R)
%RUNEXP23UDYNAMICCLOSEDLOOPSEED Execute one paired operating-envelope seed.

c=R.cells(1); condition=R.conditions(1);
base=applyExp21dClosedLoopCell(c.id,seedValue);
base.mac.backgroundLoad=condition.targetLoad;
base.mac=sharedMediumConfig(base);
trace=generateSharedMediumTrace(base); N=base.swarm.N;
offset=(2*reshape(trace.exp21cClockOffsetU(1,:),[],1)-1)*R.maxOffsetSec;
drift=(2*reshape(trace.exp21cClockDriftU,[],1)-1)*R.maxDriftPpm;
clockSpec=struct('clockOffsetSec',offset,'clockDriftPpm',drift, ...
    'leadTimeSec',R.clockLeadTimeSec);
rows=repmat(exp23uDynamicClosedLoopEnvelopeEmptyRow(),numel(R.arms),1);

for k=1:numel(R.arms)
    arm=R.arms(k); selector=[]; binding=[]; C=[]; nativeQ=[];
    eventFrame=NaN; eligibleFrame=NaN; baseKernelHash=NaN;
    eventTraceHash=NaN; blockedWitnesses=0;
    if strcmp(arm.family,'periodic-static')
        local=arm; local.periodicRateHz=c.lowerCostRateHz;
        [cfg,method,label,details]=applyExp22fStaticArm(base,local,R);
    else
        C=elcsWitnessKernelConfig(N,R.elcsMaxFrames);
        C.guardSec=R.missionSafeGuardSec;
        C.dataBytes=base.mac.dataBytes; C.phyRateBps=base.mac.phyRateBps;
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
        selector=buildStaticBroadcastCoherenceSelector(C.neighborGraph, ...
            C.interferenceMatrix,C.managementReach,6.8,selectorConfig);
        [C,binding]=applyCoherenceLeaseConfig(C,selector);
        if ~binding.admissible, error('exp23u: static graph inadmissible.'); end
        C.dynamicRevocationEnabled=logical(arm.dynamicEnabled);
        fast=isfield(arm,'fastReactivation') && ...
            logical(arm.fastReactivation);
        if fast
            C.witnessConfirmedEarlyReactivation=true;
            C.migrationUnionGraphCertified=true;
        end
        elcsTrace=generateElcsWitnessTrace(seedValue,C);
        baseKernelHash=elcsTrace.hashExact;
        if arm.dynamicEnabled
            stream=RandStream('mrg32k3a','Seed', ...
                mod(seedValue+42173+1000*N,2^32));
            stream.Substream=8;
            elcsTrace.revokeDeliveryU=rand(stream,C.maxFrames,N,N);
            eventFrame=max(2,floor(arm.eventTimeSec/ ...
                binding.physicalFrameDurationSec)+1);
            eligibleFrame=eventFrame+ceil( ...
                R.reacquireEligibilityDelaySec/binding.physicalFrameDurationSec);
            elcsTrace.selfRevoke=false(C.maxFrames,N);
            elcsTrace.selfRevoke(eventFrame,R.revokeNode)=true;
            elcsTrace.reacquireEligible=false(C.maxFrames,N);
            elcsTrace.reacquireEligible(eligibleFrame,R.revokeNode)=true;
            elcsTrace.actualInterference=repmat(reshape( ...
                C.interferenceMatrix,1,N,N),C.maxFrames,1,1);
            if arm.revokeBlackout
                elcsTrace.revokeDeliveryU(eventFrame,:,R.revokeNode)=0;
            end
            if arm.responseBlackout
                W=buildConflictWitnessMap(C.conflictGraph,C.managementReach);
                [a,b]=find(triu(C.conflictGraph,1));
                for e=1:numel(a)
                    if a(e)==R.revokeNode || b(e)==R.revokeNode
                        witness=W.witness(a(e),b(e));
                        if witness~=R.revokeNode
                            elcsTrace.certificateDeliveryU(eligibleFrame:end, ...
                                R.revokeNode,witness)=0;
                            blockedWitnesses=blockedWitnesses+1;
                        end
                    end
                end
            end
            elcsTrace.hashExact=elcsWitnessTraceHash(elcsTrace);
            eventTraceHash=elcsTrace.hashExact;
        end
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
        details.retryMode='coherence-cumulative-dynamic';
    end
    familyLabel='EXP23U dynamic envelope';
    if isfield(R,'studyFamilyLabel'), familyLabel=R.studyFamilyLabel; end
    meta=struct('stage',R.stage,'scenario',c.id,'scenarioLabel',c.label, ...
        'family',familyLabel,'arm',arm.id, ...
        'pointIndex',k,'parameterValue',arm.eventTimeSec);
    [src,~]=runExp23fWitnessBackgroundCell( ...
        cfg,method,label,meta,trace,details,arm.family,condition);
    row=exp23uDynamicClosedLoopEnvelopeEmptyRow();
    fields=fieldnames(src);
    for f=1:numel(fields), row.(fields{f})=src.(fields{f}); end
    row.DYNAMIC_ENABLED=double(arm.dynamicEnabled);
    row.REVOKE_FORCED_BLACKOUT=double(arm.revokeBlackout);
    row.REACQUIRE_BLOCKED_WITNESSES=blockedWitnesses;
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
        row.BASE_KERNEL_TRACE_HASH_EXACT=baseKernelHash;
        row.DYNAMIC_EVENT_TRACE_HASH_EXACT=eventTraceHash;
        row.FINAL_KERNEL_TRACE_HASH_EXACT=nativeQ.kernel.traceHash;
    end
    if arm.dynamicEnabled
        K=nativeQ.kernel; used=nativeQ.physicalFrameCount;
        eventIncluded=eventFrame<=used;
        reacquired=find(K.debug.reacquired(1:used,R.revokeNode),1);
        if isempty(reacquired), reacquired=NaN; end
        row.EVENT_TIME_SEC=arm.eventTimeSec;
        row.EVENT_FRAME=eventFrame;
        row.REACQUIRE_ELIGIBLE_FRAME=eligibleFrame;
        row.PHYSICAL_FRAME_COUNT_DYNAMIC=used;
        row.PHYSICAL_EVENT_INCLUDED=double(eventIncluded);
        row.PHYSICAL_PRE_EVENT_ACTIVE=double( ...
            eventFrame>1 && K.debug.active(eventFrame-1,R.revokeNode));
        row.PHYSICAL_EVENT_SUPPRESSED=double(eventIncluded && ...
            K.debug.suppressed(eventFrame,R.revokeNode) && ...
            ~K.debug.active(eventFrame,R.revokeNode));
        row.PHYSICAL_REACQUIRED=double(isfinite(reacquired));
        row.FIRST_PHYSICAL_REACQUIRED_FRAME=reacquired;
        row.PHYSICAL_FINAL_SUPPRESSED=double( ...
            K.debug.suppressed(used,R.revokeNode));
        row.CAPTURED_FENCE_FRAME=K.revokeFenceUntilFrame(R.revokeNode);
        physicalRevoke=nativeQ.controlKind=="revoke";
        row.PHYSICAL_REVOKE_ATTEMPTS=nnz(physicalRevoke);
        row.PHYSICAL_REVOKE_BYTES=sum( ...
            nativeQ.controlAttemptBytes(physicalRevoke));
        row.PHYSICAL_REVOKE_AIRTIME=sum( ...
            nativeQ.controlAttemptAirtimeSec(physicalRevoke));
        row.PHYSICAL_SUPPRESSION_HASH_EXACT=realizationHash(double( ...
            K.debug.suppressed(1:used,R.revokeNode)));
        row.PHYSICAL_REACQUIRED_HASH_EXACT=realizationHash(double( ...
            K.debug.reacquired(1:used,R.revokeNode)));
    end
    rows(k)=row;
end

end
