%% Regression tests for the authoritative TCNS FB0 feedback-economics result.

startup;
runDir = fullfile(projectRoot(),'results', ...
    'tcns_fb0_feedback_economics','2026-09-07_175224');
assert(isfolder(runDir));

P = readtable(fullfile(runDir,'feedback_economics_points.csv'), ...
    'TextType','string');
S = readtable(fullfile(runDir,'scenario_summary.csv'),'TextType','string');
J = jsondecode(fileread(fullfile(runDir,'summary.json')));

assert(height(P)==70);
assert(nnz(P.eligibility=="ELIGIBLE")==48);
assert(all(P.seedCount==5));
assert(all(P.failedRuns==0));
assert(strcmp(J.technicalStatus,'PASS'));
assert(J.trajectoryRerunCount==0);
assert(J.sourceChecks.rowCount && J.sourceChecks.o1RowCount);
assert(J.sourceChecks.c1EqualsC2 && J.sourceChecks.nonnegativeAck);
assert(J.costReconstructionPass && J.algebraPass);

expectedEligible = [4;11;11;11;11];
expectedFull = [1;3/11;0;1/11;4/11];
S = sortrows(S,'scenarioId');
assert(isequal(S.scenarioId,["S2";"S3";"S4";"S5";"S6"]));
assert(isequal(S.eligiblePointCount,expectedEligible));
assert(max(abs(S.fractionFullFeedbackAffordable-expectedFull))<1e-12);

eligible = P.eligibility=="ELIGIBLE";
assert(all(isfinite(P.etaCritical(eligible))));
assert(max(abs(P.allowableFeedbackFractionRawAt025(eligible)- ...
    P.etaCritical(eligible)/0.25))<1e-12);
assert(all(P.etaCritical(P.scenarioId=="S2" & eligible)>=0.25));
assert(all(P.etaCritical(P.scenarioId=="S4" & eligible)<0));

fprintf('test_tcns_fb0_feedback_economics: PASS\n');
