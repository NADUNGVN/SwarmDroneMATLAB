%% TEST_EXP17_ANALYSIS_CONTRACTS Synthetic full analysis-path test.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp17_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp17Registry();
rows=repmat(exp17EmptyRow(),R.expectedRuns,1); q=0;
for i=1:numel(R.seeds)
    seedNoise=(i-(numel(R.seeds)+1)/2)*1e-6;
    for c=R.cells
        contextOffset=1e-4*find(strcmp({R.cells.id},c.id));
        for arm=R.arms
            q=q+1; row=exp17EmptyRow();
            row.seed=R.seeds(i); row.scenario=c.id;
            row.scenarioLabel=c.label; row.arm=arm.id;
            row.methodLabel=arm.label; row.macType=arm.macType;
            row.route=arm.route; row.N=c.N;
            row.backgroundLoad=c.background;
            row.channelRegime=c.channel; row.contextModifier=c.modifier;
            row.coreFlag=double(strcmp(c.role,'core'));
            row.TRACE_HASH_EXACT=R.seeds(i)+1000*find(strcmp({R.cells.id},c.id));
            row.CHANNEL_STATE_HASH=row.TRACE_HASH_EXACT+1;
            row.DIVERGED=0; row.SAFEFAIL=0;
            base=0.05+contextOffset+seedNoise;
            switch arm.id
                case 'csma-adaptive'
                    row.RMSE=base+0.002; row.OFFERED_UTIL=0.31+contextOffset;
                case 'csma-piggyback'
                    row.RMSE=base; row.OFFERED_UTIL=0.30+contextOffset;
                case 'aloha-adaptive'
                    row.RMSE=base+0.005; row.OFFERED_UTIL=0.70+contextOffset;
                case 'aloha-piggyback'
                    row.RMSE=base+0.015; row.OFFERED_UTIL=0.75+contextOffset;
            end
            row.MEAN_TRUE_AOI=row.RMSE; row.CHANNEL_UTIL=min(row.OFFERED_UTIL,1);
            row.COLLISION_FRAMES=10; row.DATA_ATTEMPTED=100;
            row.ACK_ATTEMPTED=20;
            row.ACK_STANDALONE=double(strcmp(arm.route,'adaptive'))*10;
            rows(q)=row;
        end
    end
end

target=[tempname '_exp17_analysis_contract']; mkdir(target);
cleaner=onCleanup(@() safeCleanup(target));
writetable(struct2table(rows),fullfile(target,'tidy.csv'));
gates=table("synthetic_contract",1,"analysis-only fixture", ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(target,'gates.csv'));
A=analyzeExp17Results(target); close all;

checks={ ...
    height(A.primaryTests)==48 && all(A.primaryTests.rejectAfterHolm), ...
        'all 48 synthetic core tests reject after global Holm control'; ...
    height(A.cellClaims)==8 && all(A.cellClaims.cellSupported), ...
        'all eight synthetic core contexts satisfy the intersection rule'; ...
    height(A.boundaryEffects)==12 && ...
        all(isnan(A.boundaryEffects.oneSidedPRaw)), ...
        'two boundary contexts retain twelve descriptive effects without p-values'; ...
    A.continuationVerdict.passed && strcmp(A.continuationVerdict.status, ...
        'PROCEED_TO_SENSITIVITY_AND_MEASURED_CSMA'), ...
        'frozen continuation rule executes on the synthetic full envelope'; ...
    strcmp(A.claimVerdict.status,'SUPPORTED_FULL_REGISTERED_CORE_ENVELOPE'), ...
        'global claim verdict follows the frozen cell/intersection rules'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp17_analysis_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp17_analysis_contracts: PASS (%d checks)\n',numel(flags));


function safeCleanup(target)

target=char(target); tmp=char(tempdir);
if ~startsWith(lower(target),lower(tmp)) || ...
        ~contains(target,'_exp17_analysis_contract')
    error('test_exp17_analysis_contracts: refusing unsafe cleanup target.');
end
if exist(target,'dir')==7, rmdir(target,'s'); end

end

