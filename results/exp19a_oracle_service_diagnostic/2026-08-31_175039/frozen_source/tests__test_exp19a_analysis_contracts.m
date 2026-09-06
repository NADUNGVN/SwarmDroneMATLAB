%% TEST_EXP19A_ANALYSIS_CONTRACTS Synthetic promotion/negative gates.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp19a_analysis_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);
R=exp19aRegistry();
S=syntheticSummary(R);
D=evaluateExp19Promotion(S,R,true);
checks(end+1,:)={D.promote && all(D.gates.passed==1), ...
    'promotion requires all five frozen mechanism gates'};
checks(end+1,:)={height(D.oracle)==2 && height(D.periodic)==8 && ...
    all(ismember({'boundaryParetoGate','failureReductionGate', ...
    'priorityActionGate'},D.oracle.Properties.VariableNames)), ...
    'oracle and periodic diagnostics retain the complete comparison set'};

bad=S;
idx=bad.scenario==string(R.boundaryCell) & ...
    bad.arm==string(R.periodicArms{1});
bad.meanRMSE(idx)=0.70;
bad.meanOfferedUtil(idx)=0.70;
bad.safeFailures(idx)=0;
for id=string(R.oracleArms)
    q=bad.arm==id;
    bad.priorityDiffersFifo(q)=0;
end
N=evaluateExp19Promotion(bad,R,true);
checks(end+1,:)={~N.promote && ...
    N.gates.passed(N.gates.gate== ...
    "not_reproduced_by_periodic_tdma")==0 && ...
    N.gates.passed(N.gates.gate== ...
    "semantic_priority_changes_fifo")==0, ...
    'periodic reproduction and inert priority force a negative verdict'};

I=evaluateExp19Promotion(S,R,false);
checks(end+1,:)={~I.promote && ...
    I.gates.passed(I.gates.gate=="all_integrity_gates")==0, ...
    'performance cannot override a failed integrity audit'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp19a_analysis_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp19a_analysis_contracts: PASS (%d checks)\n',numel(flags));


function S=syntheticSummary(R)

scenarios=string({R.boundaryCell,R.failureCell});
arms=string([{R.baselineArm},R.oracleArms,R.periodicArms]);
n=numel(scenarios)*numel(arms);
scenario=strings(n,1); arm=strings(n,1);
meanRMSE=zeros(n,1); safeFailures=zeros(n,1);
meanOfferedUtil=zeros(n,1); priorityDiffersFifo=zeros(n,1);
fifoComparableDecisions=zeros(n,1); q=0;
for c=1:numel(scenarios)
    for a=1:numel(arms)
        q=q+1; scenario(q)=scenarios(c); arm(q)=arms(a);
        meanRMSE(q)=1.10; meanOfferedUtil(q)=1.10;
        if arms(a)==string(R.baselineArm)
            meanRMSE(q)=1.0; meanOfferedUtil(q)=1.0;
            safeFailures(q)=5;
        elseif ismember(arms(a),string(R.oracleArms))
            meanRMSE(q)=0.90; meanOfferedUtil(q)=0.85;
            safeFailures(q)=2;
            priorityDiffersFifo(q)=20;
            fifoComparableDecisions(q)=100;
        else
            meanRMSE(q)=0.88; meanOfferedUtil(q)=0.95;
            safeFailures(q)=3;
        end
    end
end
S=table(scenario,arm,meanRMSE,safeFailures,meanOfferedUtil, ...
    priorityDiffersFifo,fifoComparableDecisions);

end
