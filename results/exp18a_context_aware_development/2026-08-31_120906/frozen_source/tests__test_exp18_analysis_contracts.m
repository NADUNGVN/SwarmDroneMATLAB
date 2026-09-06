%% TEST_EXP18_ANALYSIS_CONTRACTS Synthetic promotion-gate checks.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp18_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp18Registry();
tmp=tempname;
mkdir(tmp); mkdir(fullfile(tmp,'figures'));
cleanup=onCleanup(@() rmdir(tmp,'s'));
T=syntheticTable(R);
writetable(T,fullfile(tmp,'tidy.csv'));
A=analyzeExp18ADevelopment(tmp);
passPositive=strcmp(A.verdict.status,'CANDIDATE_READY_TO_PREREGISTER') && ...
    A.verdict.gatesPassed==A.verdict.gatesTotal;

idx=T.arm=="context-aware" & T.scenario==string(R.cells(1).id) & ...
    T.macType=="csma";
first=find(idx,1);
T.SAFEFAIL(first)=1;
writetable(T,fullfile(tmp,'tidy.csv'));
B=analyzeExp18ADevelopment(tmp);
passNegative=strcmp(B.verdict.status,'REJECT_OR_REVISE_CANDIDATE') && ...
    any(B.gates.gate=="failure_nonincrease" & B.gates.passed==0);

checks={passPositive, ...
    'synthetic qualifying candidate is promotion-ready'; ...
    passNegative, ...
    'one candidate-only failure rejects the development candidate'};
flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp18_analysis_contracts: contract failure.');
end
fprintf('\ntest_exp18_analysis_contracts: PASS (%d checks)\n',numel(flags));


function T=syntheticTable(R)

n=R.expectedRuns;
scenario=strings(n,1); macType=strings(n,1); arm=strings(n,1);
calibrationSource=strings(n,1);
RMSE=zeros(n,1); OFFERED_UTIL=zeros(n,1); MEAN_TRUE_AOI=zeros(n,1);
COLLISION_RATE=zeros(n,1); SAFEFAIL=zeros(n,1); pAccess=zeros(n,1);
ACK_STANDALONE=zeros(n,1); CONTEXT_ACK_EVALUATED=zeros(n,1);
CONTEXT_ACK_PERMITTED=zeros(n,1);
CONTEXT_ACK_BLOCKED_FEASIBILITY=zeros(n,1);
CONTEXT_ACK_BLOCKED_VALUE=zeros(n,1);
q=0;
for seed=R.seeds' %#ok<NASGU>
    for c=R.cells
        for m=1:numel(R.macTypes)
            mac=string(R.macTypes{m});
            for a=R.arms
                q=q+1;
                scenario(q)=string(c.id); macType(q)=mac; arm(q)=string(a.id);
                MEAN_TRUE_AOI(q)=0.1;
                if strcmp(a.id,'legacy-selector')
                    RMSE(q)=0.12; OFFERED_UTIL(q)=1.0;
                    COLLISION_RATE(q)=0.8;
                elseif strcmp(a.id,'context-aware')
                    RMSE(q)=0.10; OFFERED_UTIL(q)=0.4;
                    COLLISION_RATE(q)=0.3;
                    CONTEXT_ACK_EVALUATED(q)=2;
                    CONTEXT_ACK_PERMITTED(q)=1;
                    CONTEXT_ACK_BLOCKED_VALUE(q)=1;
                    if contains(c.id,'reverse')
                        calibrationSource(q)="nominal-moderate-mismatch";
                    else
                        calibrationSource(q)="declared-stationary-profile";
                    end
                else
                    RMSE(q)=0.11; OFFERED_UTIL(q)=0.5;
                    COLLISION_RATE(q)=0.4;
                end
                if mac=="aloha" && ~strcmp(a.id,'legacy-selector')
                    pAccess(q)=1/(c.N*7);
                else
                    pAccess(q)=1/c.N;
                end
            end
        end
    end
end
T=table(scenario,macType,arm,RMSE,OFFERED_UTIL,MEAN_TRUE_AOI, ...
    COLLISION_RATE,SAFEFAIL,pAccess,ACK_STANDALONE, ...
    CONTEXT_ACK_EVALUATED,CONTEXT_ACK_PERMITTED, ...
    CONTEXT_ACK_BLOCKED_FEASIBILITY,CONTEXT_ACK_BLOCKED_VALUE, ...
    calibrationSource);

end
