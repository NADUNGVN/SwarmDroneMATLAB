function R=exp23pCoherencePacketRegistry()
%EXP23PCOHERENCEPACKETREGISTRY Frozen geometry-to-packet kernel matrix.

R=exp23oBroadcastCoherenceRegistry();
R.version='EXP23P-COHERENCE-ELCS-W-PACKET-KERNEL-v1';
R.frozenDate='2026-09-04';
R.stage='coherence-packet-kernel-falsification';
R.seeds=(16077001:16077050)';
R.parentBroadcastRun='2026-09-04_172147';
R.parentBroadcastStatus='BROADCAST_COHERENCE_KERNEL_VALID';
R.maxFrames=400;
R.conditionsNetwork=struct( ...
    'id',{'zero','claim-iid5','response-iid5','joint-control-iid5', ...
        'iid-occupancy15','directed-response-blackout'}, ...
    'claimLoss',{0,.05,0,.05,0,0}, ...
    'responseLoss',{0,0,.05,.05,0,0}, ...
    'backgroundLoad',{0,0,0,0,.15,0});
R.blackoutCondition='directed-response-blackout';
R.backgroundCondition='iid-occupancy15';
R.backgroundSlotSec=1e-3;
R.backgroundHorizonSec=60;
R.maxOffsetSec=0.25e-3;
R.maxDriftPpm=40;
B=continuousTdmaGuardBound(R.maxOffsetSec,R.maxDriftPpm,12);
R.clockLeadTimeSec=B.maxBoundaryErrorSec;
R.missionSafeGuardSec=B.safeGuardSec;
R.requiredValidationContracts=20;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)* ...
    numel(R.conditions)*numel(R.conditionsNetwork);

end
