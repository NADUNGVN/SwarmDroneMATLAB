function R=exp23sDynamicRevocationRegistry()
%EXP23SDYNAMICREVOCATIONREGISTRY Frozen dynamic lifecycle matrix.

R.version='EXP23S-DYNAMIC-REVOCATION-KERNEL-v1';
R.frozenDate='2026-09-04';
R.stage='dynamic-revocation-kernel-falsification';
R.parentPacketRun='2026-09-04_174126';
R.parentPacketStatus='COHERENCE_ELCS_W_GRAPH_REPAIR_PACKET_KERNEL_VALID';
R.policyOptimizationAllowed=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16080001:16080100)';
R.nodeCounts=[5 10];
R.maxFrames=70;
R.revokeNode=3;
R.revokeFrameBase=24;
R.reacquireDelayFrames=8;
R.claimBytes=28;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=10;
R.revokeBytes=24;
R.maxControlPacketBytes=96;
R.conditions=struct( ...
    'id',{'zero-delivered','revoke-blackout','joint-control-revoke-iid5', ...
        'reacquire-response-blackout'}, ...
    'claimLoss',{0,0,.05,0},'responseLoss',{0,0,.05,0}, ...
    'revokeLoss',{0,1,.05,0}, ...
    'blockReacquireResponse',{false,false,false,true});
R.revokeBlackoutCondition='revoke-blackout';
R.responseBlackoutCondition='reacquire-response-blackout';
R.requiredValidationContracts=25;
R.expectedRuns=numel(R.seeds)*numel(R.nodeCounts)*numel(R.conditions);

end
