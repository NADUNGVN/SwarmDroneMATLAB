%% TCNS R2 GENERALIZATION AND ACTUAL-ACTION WITNESS VALIDATION

startup;
close all;
R = startExperiment('tcns_r2_generalization_validation', ...
    ['New TCNS R2 theory/generalization study: deterministic cross-instance ' ...
     'information audit and all-action reachable-witness audit. No scheduler, ' ...
     'held-out evaluation, or simulation-v1 modification.']);

generalization = tcnsR2GeneralizationAudit();
[cfg,~] = tcnsGate6Scenario(27020001,'S1');
witness = tcnsInformationLimitsActualWitnessAudit(cfg,25,4);

writetable(generalization.registryTable, ...
    fullfile(R.dir,'configuration_registry.csv'));
writetable(generalization.actionTable, ...
    fullfile(R.dir,'generalization_actions.csv'));
writetable(generalization.toleranceTable, ...
    fullfile(R.dir,'generalization_tolerance_grid.csv'));
writetable(generalization.senderTable, ...
    fullfile(R.dir,'generalization_sender_multi_action.csv'));
writetable(generalization.vpaTable, ...
    fullfile(R.dir,'generalization_vpa_audit.csv'));
writetable(witness.actionCatalog,fullfile(R.dir,'actual_action_catalog.csv'));
writetable(witness.witnessTable,fullfile(R.dir,'actual_witness_audit.csv'));

summary.schemaVersion = 1;
summary.studyClass = 'NEW_TCNS_R2_THEORY_GENERALIZATION';
summary.gitCommit = R.meta.gitCommit;
summary.seed = 27022001;
summary.configurationCount = height(generalization.registryTable);
summary.admissibleConfigurationCount = nnz( ...
    generalization.registryTable.admissible);
summary.actionRowCount = height(generalization.actionTable);
summary.nonidentifiableActionRowCount = nnz( ...
    ~generalization.actionTable.identifiable);
summary.toleranceStableActionRowCount = nnz( ...
    generalization.actionTable.toleranceStable);
summary.compressedDirectAgreementCount = nnz( ...
    generalization.actionTable.compressedDirectAgree);
summary.vpaAttemptCount = nnz(generalization.actionTable.vpaAttempted);
summary.vpaSuccessfulCount = nnz( ...
    generalization.actionTable.vpaAttempted & ...
    generalization.actionTable.vpaFailure=="NONE");
summary.fullCoalitionFailureCount = nnz( ...
    ~generalization.senderTable.allAgentsIdentifyAllValues);
summary.baselineActionCount = witness.actionCount;
summary.baselineStructuralNonidentifiableCount = ...
    witness.structuralNonidentifiableCount;
summary.baselineActualResponseTestedCount = witness.actualResponseTestedCount;
summary.baselineReachableWitnessCount = witness.reachableWitnessCount;
summary.witnessFailureReasons = cellstr(witness.witnessTable.failureReason);
summary.noSchedulerImplemented = true;
summary.noHeldOutSeedsUsed = true;
summary.frozenSimulationV1Untouched = true;
if summary.admissibleConfigurationCount==summary.configurationCount && ...
        summary.fullCoalitionFailureCount==0 && ...
        summary.compressedDirectAgreementCount==summary.actionRowCount
    summary.structuralStudyIntegrity = 'PASS';
else
    summary.structuralStudyIntegrity = 'FAIL';
end

fid = fopen(fullfile(R.dir,'summary.json'),'w');
assert(fid>0,'TCNSR2: cannot create summary.json.');
fprintf(fid,'%s\n',jsonencode(summary,'PrettyPrint',true));
fclose(fid);
fid = fopen(fullfile(R.dir,'generalization_actions.json'),'w');
assert(fid>0,'TCNSR2: cannot create generalization_actions.json.');
fprintf(fid,'%s\n',jsonencode(table2struct( ...
    generalization.actionTable),'PrettyPrint',true));
fclose(fid);
fid = fopen(fullfile(R.dir,'actual_witness_audit.json'),'w');
assert(fid>0,'TCNSR2: cannot create actual_witness_audit.json.');
fprintf(fid,'%s\n',jsonencode(table2struct( ...
    witness.witnessTable),'PrettyPrint',true));
fclose(fid);

save(fullfile(R.dir,'workspace.mat'),'cfg','generalization','witness','summary');

fprintf('R2 configurations admissible : %d / %d\n', ...
    summary.admissibleConfigurationCount,summary.configurationCount);
fprintf('R2 structural action rows    : %d\n',summary.actionRowCount);
fprintf('R2 nonidentifiable rows       : %d\n', ...
    summary.nonidentifiableActionRowCount);
fprintf('R2 full-coalition failures    : %d\n', ...
    summary.fullCoalitionFailureCount);
fprintf('R2 actual witnesses           : %d / %d\n', ...
    summary.baselineReachableWitnessCount,summary.baselineActionCount);
disp(witness.witnessTable(:,{'actionId','reachableWitnessFound', ...
    'qMinus','qPlus','normalizedAmbiguity','failureReason'}));
finishExperiment(R);
