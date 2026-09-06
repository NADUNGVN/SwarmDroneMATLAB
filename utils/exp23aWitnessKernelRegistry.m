function R=exp23aWitnessKernelRegistry()
%EXP23AWITNESSKERNELREGISTRY Frozen local-witness kernel matrix.

base=exp22iElcsKernelRegistry();
R.version='EXP23A-LOCAL-WITNESS-KERNEL-FALSIFICATION-v1';
R.frozenDate='2026-09-01';
R.stage='local-witness-kernel-falsification';
R.policyOptimizationAllowed=false;
R.closedLoopClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16057001:16057100)';
R.maxFrames=400;
R.cells=base.cells;
R.conditions=struct( ...
    'id',{'zero','claim-erasure-5','certificate-erasure-5', ...
        'data-erasure-5','directed-certificate-blackout'}, ...
    'label',{'Zero loss','CLAIM erasure 5%', ...
        'CERT erasure 5%','DATA erasure 5%', ...
        'Directed transmitted-CERT blackout'}, ...
    'kind',{'nominal','claim-loss','certificate-loss', ...
        'data-separation','fail-silent-boundary'});
R.zeroCondition='zero';
R.claimLossCondition='claim-erasure-5';
R.certificateLossCondition='certificate-erasure-5';
R.dataLossCondition='data-erasure-5';
R.blackoutCondition='directed-certificate-blackout';
R.claimErasureProbability=0.05;
R.certificateErasureProbability=0.05;
R.dataErasureProbability=0.05;
R.blackoutDrawThreshold=0.5;
R.minimumLossCertificationFraction=0.95;
R.claimBytes=24;
R.certificateHeaderBytes=16;
R.certificateEntryBytes=8;
R.maxControlPacketBytes=96;
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);

end
