% TEST_EXP23W_FAST_REACTIVATION_ANALYSIS_CONTRACTS Synthetic analysis test.
startup;
fprintf('\n============================================================\n');
fprintf('test_exp23w_fast_reactivation_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp23wFastReactivationHoldoutRegistry();
R.seeds=(1:20)'; R.bootstrapReplicates=200;
n=numel(R.seeds); noise=(0:n-1)'*1e-5;
arms=string({R.arms.id}); T=table();
for k=1:numel(arms)
    rmse=0.11+noise; cost=0.31+noise;
    if arms(k)==string(R.staticArm), rmse=0.10+noise; cost=0.30+noise; end
    if arms(k)==string(R.periodicArm), rmse=0.095+noise; cost=0.32+noise; end
    if arms(k)==string(R.oldEarlyArm), rmse=0.12+noise; cost=0.27+noise; end
    if arms(k)==string(R.fastEarlyArm), rmse=0.10+noise; cost=0.282+noise; end
    if arms(k)==string(R.fastRevokeBlackoutArm)
        rmse=0.10+noise; cost=0.282+noise;
    end
    if arms(k)==string(R.oldLateArm), rmse=0.14+noise; cost=0.27+noise; end
    if arms(k)==string(R.fastLateArm), rmse=0.105+noise; cost=0.282+noise; end
    if arms(k)==string(R.fastResponseBlackoutArm)
        rmse=0.16+noise; cost=0.34+noise;
    end
    block=table(R.seeds,repmat(arms(k),n,1),rmse,cost, ...
        'VariableNames',{'seed','arm','RMSE','TOTAL_OFFERED_UTIL'});
    T=[T;block]; %#ok<AGROW>
end

A=analyzeExp23wFastReactivation(T,R);
assert(height(A.primary)==6 && all(A.primary.rejectAfterHolm==1) && ...
    A.primaryPass && height(A.frontier)==4 && A.frontierPass && ...
    height(A.effects)==4);
fprintf('    ok   favorable frozen contrasts confirm with four frontier checks\n');

bad=T; index=string(bad.arm)==string(R.fastEarlyArm);
bad.RMSE(index)=0.13+noise;
B=analyzeExp23wFastReactivation(bad,R);
assert(~B.primaryPass && any(B.primary.rejectAfterHolm==0));
fprintf('    ok   adverse registered contrast cannot confirm\n');

fprintf('\ntest_exp23w_fast_reactivation_analysis_contracts: PASS (2 checks)\n');
