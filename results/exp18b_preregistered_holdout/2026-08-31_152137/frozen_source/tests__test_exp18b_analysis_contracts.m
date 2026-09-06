%% TEST_EXP18B_ANALYSIS_CONTRACTS Synthetic analysis without simulations.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp18b_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp18bRegistry();
tmp=tempname; mkdir(tmp);
cleanup=onCleanup(@() rmdir(tmp,'s'));
T=syntheticTidy(R);
writetable(T,fullfile(tmp,'tidy.csv'));
writetable(table("synthetic_contract",1, ...
    'VariableNames',{'gate','passed'}),fullfile(tmp,'gates.csv'));
A=analyzeExp18BResults(tmp);
positive=strcmp(A.claimVerdict.status,'SUPPORTED_WITHIN_REGISTERED_SCOPE') && ...
    A.claimVerdict.holmTestsRejected==9 && ...
    A.claimVerdict.exactAliasGatePassed && ...
    height(A.primaryTests)==9;

% Reverse H6 while preserving the candidate/piggyback exact alias.
boundary=string(T.scenario)==string(R.abstentionCell) & ...
    string(T.macType)==string(R.abstentionMac);
for seed=R.seeds'
    adaptive=T.RMSE(boundary & T.seed==seed & ...
        string(T.arm)=="frame-adaptive");
    idx=boundary & T.seed==seed & ismember(string(T.arm), ...
        ["capacity-gated-selector","frame-piggyback"]);
    T.RMSE(idx)=adaptive+0.2;
end
writetable(T,fullfile(tmp,'tidy.csv'));
B=analyzeExp18BResults(tmp);
negative=strcmp(B.claimVerdict.status,'PARTIAL_OR_NOT_SUPPORTED') && ...
    ~B.primaryTests.rejectAfterHolm(B.primaryTests.id=="H6") && ...
    B.claimVerdict.exactAliasGatePassed;

checks={positive,'all nine synthetic registered hypotheses support verdict'; ...
    negative,'one registered reversal rejects complete verdict without breaking alias'};
flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags), error('test_exp18b_analysis_contracts: failure.'); end
fprintf('\ntest_exp18b_analysis_contracts: PASS (%d checks)\n',numel(flags));


function T=syntheticTidy(R)

A4=readtable(fullfile(projectRoot(),'results', ...
    'exp18a4_capacity_gated_selector_development', ...
    '2026-08-31_125544','tidy.csv'),'TextType','string');
E=readtable(fullfile(exp18a4Registry().referenceRun,'tidy.csv'), ...
    'TextType','string');
parts=cell(numel(R.seeds)*numel(R.cells)*numel(R.macTypes)* ...
    numel(R.arms),1);
q=0;
for s=1:numel(R.seeds)
    sourceSeed=exp18a4Registry().seeds(mod(s-1,20)+1);
    for c=R.cells
        for m=1:numel(R.macTypes)
            mac=string(R.macTypes{m});
            candidate=A4(A4.seed==sourceSeed & ...
                A4.scenario==string(c.id) & A4.macType==mac,:);
            if height(candidate)~=1
                error('test_exp18b_analysis_contracts: missing candidate.');
            end
            candidate.candidateFlag=1;
            if candidate.serviceCertificateFeasible==1 && mac=="aloha"
                routedReference="frame-adaptive";
            else
                routedReference="frame-piggyback";
            end
            candidate.routedReference=routedReference;
            candidate.seed=R.seeds(s);
            candidate.stage="synthetic-contract";
            q=q+1; parts{q}=candidate;
            templateNames=candidate.Properties.VariableNames;

            for k=2:numel(R.arms)
                armId=string(R.arms(k).id);
                Q=E(E.seed==sourceSeed & E.scenario==string(c.id) & ...
                    E.macType==mac & E.arm==armId,:);
                if height(Q)~=1
                    error('test_exp18b_analysis_contracts: missing comparator.');
                end
                serviceFields={'serviceCertificateEnabled', ...
                    'serviceCertificateFeasible','serviceModel', ...
                    'successfulUpdateRateHz','requiredUpdateRateHz', ...
                    'serviceRatio','backgroundSurvival','dataSuccessEstimate'};
                for f=1:numel(serviceFields)
                    name=serviceFields{f}; Q.(name)=candidate.(name);
                end
                Q.routeRule="fixed-comparator";
                if armId=="legacy-selector"
                    Q.routeRule="legacy-mac-only";
                end
                Q.candidateFlag=0;
                Q.routedReference=routedReference;
                Q.seed=R.seeds(s);
                Q.stage="synthetic-contract";
                Q=Q(:,templateNames);
                q=q+1; parts{q}=Q;
            end
        end
    end
end
T=vertcat(parts{:});
T=sortrows(T,{'seed','scenario','macType','arm'});

end
