function R=exp22ElcsKernelRegistry()
%EXP22ELCSKERNELREGISTRY Frozen ELCS-F kernel falsification matrix.

R.version='EXP22-ELCS-F-KERNEL-v1';
R.frozenDate='2026-09-01';
R.stage='candidate-kernel-falsification';
R.policyOptimizationAllowed=false;
R.closedLoopClaimPermitted=false;
R.newMethodPromotionAllowed=false;
R.submissionClaimPermitted=false;
R.seeds=(16040001:16040100)';
R.maxFrames=400;
R.cells=struct( ...
    'id',{'n5-6dof','n10-ring2'}, ...
    'label',{'N5 6-DOF graph','N10 ring2 graph'}, ...
    'exp21dCell',{'n5-6dof-zero-loss','n10-ring2-zero-loss'});
R.conditions=struct( ...
    'id',{'zero','data-erasure-5','management-erasure-5', ...
        'local-management','directed-grant-blackout', ...
        'state-loss','owner-reconfiguration'}, ...
    'label',{'Zero loss','DATA erasure 5%', ...
        'Management erasure 5%','Local management reach', ...
        'Directed GRANT blackout','Local client state loss', ...
        'Owner tuple reconfiguration'}, ...
    'kind',{'native','data-separation','control-loss', ...
        'visibility-boundary','grant-loss-witness', ...
        'rejoin-boundary','lease-fence-boundary'});
R.zeroCondition='zero';
R.dataLossCondition='data-erasure-5';
R.managementLossCondition='management-erasure-5';
R.localCondition='local-management';
R.blackoutCondition='directed-grant-blackout';
R.stateLossCondition='state-loss';
R.reconfigurationCondition='owner-reconfiguration';
R.dataErasureProbability=0.05;
R.managementErasureProbability=0.05;
R.blackoutDrawThreshold=0.5;
R.stateLossFrame=200;
R.stateLossNode=2;
R.reconfigurationFrame=200;
R.reconfigurationNode=2;
R.reconfigurationSlotRule='N';
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.conditions);
R.requiredDeterministicContracts=12;

end
