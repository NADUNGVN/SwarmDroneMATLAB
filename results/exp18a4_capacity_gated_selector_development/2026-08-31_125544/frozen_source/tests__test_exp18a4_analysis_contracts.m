%% TEST_EXP18A4_ANALYSIS_CONTRACTS Synthetic exact-route audit.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp18a4_analysis_contracts\n');
fprintf('============================================================\n\n');

R=exp18a4Registry();
tmp=tempname; mkdir(tmp);
cleanup=onCleanup(@() rmdir(tmp,'s'));
T=syntheticCandidate(R);
writetable(T,fullfile(tmp,'tidy.csv'));
A=analyzeExp18A4Development(tmp);
positive=strcmp(A.verdict.status,'READY_TO_PREREGISTER_FRESH_SEED_HOLDOUT') && ...
    A.verdict.exactAliasRows==A.verdict.exactAliasTotal;

T.RMSE(1)=T.RMSE(1)+1e-5;
writetable(T,fullfile(tmp,'tidy.csv'));
B=analyzeExp18A4Development(tmp);
negative=strcmp(B.verdict.status,'REJECT_CAPACITY_GATED_SELECTOR') && ...
    any(B.gates.gate=="exact_fixed_route_alias" & B.gates.passed==0);

checks={positive,'exact capacity-gated synthetic selector passes'; ...
    negative,'one registered outcome mismatch rejects selector'};
flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags), error('test_exp18a4_analysis_contracts: failure.'); end
fprintf('\ntest_exp18a4_analysis_contracts: PASS (%d checks)\n',numel(flags));


function T=syntheticCandidate(R)

reference=readtable(fullfile(R.referenceRun,'tidy.csv'),'TextType','string');
parts=cell(numel(R.cells)*numel(R.macTypes),1); q=0;
for c=R.cells
    for m=1:numel(R.macTypes)
        q=q+1; mac=string(R.macTypes{m});
        base=applyExp18Cell(c.id,R.seeds(1));
        base.mac.type=char(mac); base.mac.pAccess=min(0.20,1/base.swarm.N);
        [~,~,~,~,cert]=applyExp18A4Arm(base);
        if cert.feasible && mac=="aloha"
            sourceArm="frame-adaptive";
        else
            sourceArm="frame-piggyback";
        end
        Q=reference(reference.scenario==string(c.id) & ...
            reference.macType==mac & reference.arm==sourceArm,:);
        Q.arm(:)="capacity-gated-selector";
        Q.method(:)="context-aware-broadcast";
        Q.feedbackMode(:)="adaptive";
        Q.route(:)="capacity-gated-selector";
        Q.ackDesign(:)="capacity-gated-mac";
        Q.calibrationSource(:)="declared-stationary-profile";
        if contains(c.id,'reverse')
            Q.calibrationSource(:)="nominal-moderate-mismatch";
        end
        n=height(Q);
        Q.serviceCertificateEnabled=ones(n,1);
        Q.serviceCertificateFeasible=repmat(double(cert.feasible),n,1);
        Q.serviceModel=repmat(string(cert.model),n,1);
        Q.successfulUpdateRateHz=repmat(cert.successfulUpdateRateHz,n,1);
        Q.requiredUpdateRateHz=repmat(cert.requiredUpdateRateHz,n,1);
        Q.serviceRatio=repmat(cert.serviceRatio,n,1);
        Q.backgroundSurvival=repmat(cert.backgroundSurvival,n,1);
        Q.dataSuccessEstimate=repmat(cert.dataSuccessEstimate,n,1);
        Q.routeRule=repmat("capacity-gated-mac",n,1);
        parts{q}=Q;
    end
end
T=vertcat(parts{:});

end
