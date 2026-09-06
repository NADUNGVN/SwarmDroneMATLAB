%% TEST_EXP16_ANALYSIS_CONTRACTS Synthetic test of the frozen analysis path.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp16_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp16Registry();
rows=repmat(exp16EmptyRow(),R.expectedRuns,1);
q=0;
for i=1:numel(R.seeds)
    seedNoise=(i-(numel(R.seeds)+1)/2)*1e-6;
    for k=1:numel(R.arms)
        arm=R.arms(k); q=q+1;
        row=exp16EmptyRow();
        row.seed=R.seeds(i);
        row.arm=arm.id;
        row.methodLabel=arm.label;
        row.macType=arm.macType;
        row.route=arm.route;
        row.primaryFactorialFlag=double(arm.primaryFactorial);
        row.TRACE_HASH_EXACT=R.seeds(i)+100;
        row.CHANNEL_STATE_HASH=R.seeds(i)+200;
        row.DIVERGED=0;
        row.SAFEFAIL=0;
        switch arm.id
            case 'csma-adaptive'
                row.RMSE=0.052+seedNoise;
                row.OFFERED_UTIL=0.31+seedNoise;
            case 'csma-piggyback'
                row.RMSE=0.050+seedNoise;
                row.OFFERED_UTIL=0.30+seedNoise;
            case 'csma-fixed-hybrid'
                row.RMSE=0.051+seedNoise;
                row.OFFERED_UTIL=0.305+seedNoise;
            case 'aloha-adaptive'
                row.RMSE=0.055+seedNoise;
                row.OFFERED_UTIL=0.70+seedNoise;
            case 'aloha-piggyback'
                row.RMSE=0.065+seedNoise;
                row.OFFERED_UTIL=0.75+seedNoise;
            case 'aloha-fixed-hybrid'
                row.RMSE=0.060+seedNoise;
                row.OFFERED_UTIL=0.73+seedNoise;
        end
        row.MEAN_TRUE_AOI=row.RMSE;
        row.CHANNEL_UTIL=min(row.OFFERED_UTIL,1);
        row.COLLISION_FRAMES=10;
        row.DATA_ATTEMPTED=100;
        row.ACK_ATTEMPTED=20;
        row.ACK_STANDALONE=double(~strcmp(arm.route,'piggyback'))*10;
        rows(q)=row;
    end
end

target=[tempname '_exp16_analysis_contract'];
mkdir(target);
cleaner=onCleanup(@() safeCleanup(target));
writetable(struct2table(rows),fullfile(target,'tidy.csv'));
gates=table("synthetic_contract",1,"analysis-only fixture", ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(target,'gates.csv'));

A=analyzeExp16Results(target);
close all;
checks={ ...
    height(A.primaryTests)==6 && all(A.primaryTests.rejectAfterHolm), ...
        'six oriented primary tests reject after Holm'; ...
    height(A.metricClaims)==2 && all(A.metricClaims.reversalSupported), ...
        'both synthetic metric reversals are supported'; ...
    strcmp(A.claimVerdict.status, ...
        'SUPPORTED_REGISTERED_FACTORIAL_INTERACTION'), ...
        'global claim verdict follows the frozen intersection rule'; ...
    height(A.hybridContrasts)==32, ...
        'two MACs by two routes by eight hybrid contrasts are retained'; ...
    all(A.safetyGuards.observedGuardPassed), ...
        'registered observed safety guards are evaluated'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp16_analysis_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp16_analysis_contracts: PASS (%d checks)\n',numel(flags));


function safeCleanup(target)

target=char(target);
tmp=char(tempdir);
if ~startsWith(lower(target),lower(tmp)) || ...
        ~contains(target,'_exp16_analysis_contract')
    error('test_exp16_analysis_contracts: refusing unsafe cleanup target.');
end
if exist(target,'dir')==7
    rmdir(target,'s');
end

end

