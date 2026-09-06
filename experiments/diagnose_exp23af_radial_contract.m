function diagnose_exp23af_radial_contract()
%DIAGNOSE_EXP23AF_RADIAL_CONTRACT Posthoc theorem diagnosis of failed gate.

startup; runScriptIsolated('test_swept_radial_contraction_contracts');
R=exp23afOnlineClosureRegistry(); R.arms=R.arms(2:end);
expRun=startExperiment('exp23af_radial_contract_diagnostic', ...
    'Posthoc one-sided radial diagnosis of the frozen EXP23AF tube failure.');
rows=repmat(exp23afOnlineClosureEmptyRow(), ...
    numel(R.seeds)*numel(R.arms),1); q=0;
for seedIndex=1:numel(R.seeds)
    block=runExp23afOnlineClosureSeed(R.seeds(seedIndex),R);
    rows(q+(1:numel(block)))=block; q=q+numel(block);
    if mod(seedIndex,5)==0
        fprintf('  seed %2d / %2d; rows %3d\n', ...
            seedIndex,numel(R.seeds),q);
    end
end
T=struct2table(rows);
writetable(T,fullfile(expRun.dir,'radial_diagnostic_tidy.csv'));
noEmergency=string(T.arm)== ...
    "closure-response-blackout-no-emergency";
protected=~noEmergency;
[group,S]=findgroups(T(:,{'arm'}));
S.nRuns=splitapply(@numel,T.seed,group);
S.vectorTubePassRate=splitapply(@mean,T.criticalCapsuleBoundSatisfied,group);
S.radialContractPassRate=splitapply(@mean, ...
    T.criticalRadialBoundSatisfied,group);
S.maximumVectorRatio=splitapply(@max,T.criticalCapsuleMaximumRatio,group);
S.maximumRadialRatio=splitapply(@max,T.criticalRadialMaximumRatio,group);
S.minimumOmittedMargin=splitapply(@min,T.minimumOmittedEdgeMargin,group);
S.actualPhysicalSubsetRate=splitapply(@mean,T.actualPhysicalSubset,group);
writetable(S,fullfile(expRun.dir,'summary.csv'));
supported=all(T.radialConstructionPremise==1)&& ...
    all(T.radialTheoremCertified(protected)==1)&& ...
    any(T.criticalCapsuleBoundSatisfied(protected)==0)&& ...
    all(T.radialTheoremCertified(noEmergency)==0)&& ...
    all(T.actualPhysicalSubset(protected)==1);
status=ternary(supported,'RADIAL_CONTRACT_REPAIR_SUPPORTED', ...
    'RADIAL_CONTRACT_REPAIR_NOT_SUPPORTED');
verdict=struct('status',status,'rows',height(T), ...
    'parentExp23afStatus','ONLINE_SWEPT_RECEIVER_CLOSURE_INVALID', ...
    'posthocDiagnosis',true,'registeredConfirmation',false, ...
    'maximumProtectedVectorRatio', ...
    max(T.criticalCapsuleMaximumRatio(protected)), ...
    'maximumProtectedRadialRatio', ...
    max(T.criticalRadialMaximumRatio(protected)), ...
    'minimumProtectedOmittedMargin', ...
    min(T.minimumOmittedEdgeMargin(protected)), ...
    'submissionClaimPermitted',false, ...
    'next','preregister_fresh_seed_radial_contract_validation');
writeJson(fullfile(expRun.dir,'radial_diagnostic_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','verdict','R');
disp(S); fprintf('EXP23AF RADIAL DIAGNOSIS: %s\n',status);
finishExperiment(expRun);
if ~supported, error('exp23af radial diagnosis not supported.'); end

end


function writeJson(path,value)

fid=fopen(path,'w'); if fid<0, error('exp23af radial: cannot write.'); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function value=ternary(condition,a,b)
if condition, value=a; else, value=b; end
end
