%% TEST_EXP21A_ANALYSIS_CONTRACTS Synthetic frozen-decision branches.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp21a_analysis_contracts\n');
fprintf('============================================================\n\n');
R=exp21aRegistry();
folder=tempname;
mkdir(folder);
cleaner=onCleanup(@() cleanup(folder)); %#ok<NASGU>
T=syntheticTable(R);
G=table("synthetic_integrity",1,"all pass", ...
    'VariableNames',{'gate','passed','detail'});
writetable(G,fullfile(folder,'integrity_gates.csv'));

writetable(T,fullfile(folder,'trajectory_tidy.csv'));
A=analyzeExp21AResults(folder);
supported=strcmp(A.verdict.status,'DISTRIBUTED_SCHEDULING_PATH_SUPPORTED') && ...
    all(A.decisionGates.passed==1);

nominal=ismember(string(T.scenario),string(R.nominalCells)) & ...
    string(T.arm)==string(R.primaryArm);
T.RMSE(nominal)=1.20;
T.CHARGED_OFFERED_UTIL(nominal)=0.60;
writetable(T,fullfile(folder,'trajectory_tidy.csv'));
A=analyzeExp21AResults(folder);
artifact=strcmp(A.verdict.status,'IDEAL_SCHEDULING_ARTIFACT') && ...
    A.decisionGates.passed(2)==0;

T=syntheticTable(R);
primary=string(T.arm)==string(R.primaryArm);
T.CONTROL_OVERHEAD_FRACTION(primary)=0.20;
T.CHARGED_OFFERED_UTIL(primary)=T.OFFERED_UTIL(primary)+0.20;
writetable(T,fullfile(folder,'trajectory_tidy.csv'));
A=analyzeExp21AResults(folder);
fragile=strcmp(A.verdict.status,'SCHEDULING_GAIN_FRAGILE') && ...
    A.decisionGates.passed(2)==1 && A.decisionGates.passed(4)==0;

checks={supported,'all registered gates produce supported-path verdict'; ...
    artifact,'failed nominal dominance produces ideal-artifact verdict'; ...
    fragile,'post-nominal overhead failure produces fragile verdict'};
flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp21a_analysis_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp21a_analysis_contracts: PASS (%d checks)\n',numel(flags));


function T=syntheticTable(R)

rows=repmat(exp21aEmptyRow(),R.expectedRuns,1);
q=0;
for seed=R.seeds'
    for c=R.cells
        for a=R.arms
            q=q+1;
            row=exp21aEmptyRow();
            row.seed=seed;
            row.scenario=c.id;
            row.scenarioLabel=c.label;
            row.cellRole=c.role;
            row.arm=a.id;
            row.methodLabel=a.label;
            row.armKind=a.kind;
            row.schedulerMode=a.schedulerMode;
            row.RMSE=0.90;
            row.SAFEFAIL=0;
            row.DIVERGED=0;
            row.OFFERED_UTIL=0.30;
            row.CHARGED_OFFERED_UTIL=0.30;
            row.CONTROL_OVERHEAD_FRACTION=0;
            row.MEAN_TRUE_AOI=0.10;
            row.ENDOGENOUS_COLLISION_FRAMES=0;
            row.CONVERGED_BY_2SEC=1;
            row.RECOVERED_BY_2SEC=NaN;
            if strcmp(a.id,R.currentArm)
                row.RMSE=1.00;
                row.OFFERED_UTIL=0.50;
                row.CHARGED_OFFERED_UTIL=0.50;
            elseif strcmp(a.id,R.primaryArm)
                row.RMSE=0.80;
                row.OFFERED_UTIL=0.30;
                row.CHARGED_OFFERED_UTIL=0.40;
                row.CONTROL_OVERHEAD_FRACTION=0.10;
                if c.churnEnabled, row.RECOVERED_BY_2SEC=1; end
            elseif strcmp(a.id,R.idealArm)
                row.RMSE=0.75;
                row.OFFERED_UTIL=0.35;
                row.CHARGED_OFFERED_UTIL=0.35;
            end
            rows(q)=row;
        end
    end
end
T=struct2table(rows);

end


function cleanup(folder)

if isfolder(folder), rmdir(folder,'s'); end

end
