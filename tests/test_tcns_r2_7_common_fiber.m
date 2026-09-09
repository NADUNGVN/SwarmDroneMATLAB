%% TEST_TCNS_R2_7_COMMON_FIBER Joint-response and set-valued decision checks.

startup;
fprintf('\n=== TCNS R2.7 common multi-action fiber checks ===\n\n');

workspacePath = fullfile(projectRoot(),'results', ...
    'tcns_r2_generalization_validation','2026-09-08_161130', ...
    'workspace.mat');
A = tcnsR27CommonFiberAudit(workspacePath);
assert(height(A.candidateTable)==30 && all(A.candidateTable.sourceEligible), ...
    'R27: deterministic 10-center by 3-sender enumeration is incomplete.');
assert(height(A.dimensionTable)==30 && ...
    all(A.dimensionTable.commonDimension>0), ...
    'R27: common-fiber dimension rows are missing or invalid.');
assert(all(A.dimensionTable.jointResponseDimension>= ...
    A.dimensionTable.commonDimension), ...
    'R27: joint response constraints were not applied before semantics.');
assert(max(A.dimensionTable.maximumResponseJacobianResidual)<=1e-9, ...
    'R27: an action-response affine map failed its joint check.');

ambiguous = find(A.argmaxTable.outcome== ...
    "COMMON_FIBER_ARGMAX_AMBIGUOUS",1);
assert(~isempty(ambiguous), ...
    'R27: no replayed ambiguous case is available for validator tests.');
[sourceIndex,senderIndex] = ind2sub(size(A.details),ambiguous);
D = A.details{sourceIndex,senderIndex}.decision;
left = D.leftRun;
right = D.rightRun;
V = tcnsR27ValidateCommonFiber(left,right);
assert(V.passCommonFiber && V.disjointArgmax && ...
    numel(V.actionResponseResiduals)==height(left.catalog), ...
    'R27: jointly preserved disjoint-argmax witness was not recognized.');
assert(left.qAugmented(1)==0 && right.qAugmented(1)==0 && V.q0Included, ...
    'R27: the genuine q0=0 action is missing.');

% Every response is checked: corrupting one candidate must invalidate the pair.
badResponse = right;
badResponse.actionResponses{end}(1) = ...
    badResponse.actionResponses{end}(1)+1e-7;
Vbad = tcnsR27ValidateCommonFiber(left,badResponse);
assert(~Vbad.passCommonFiber && contains(Vbad.failureReason, ...
    "JOINT_RESPONSE_MISMATCH"), ...
    'R27: changing one candidate response was not rejected.');

% Complete sender information and reachability are independently enforced.
badInformation = right;
badInformation.senderObservation(1) = ...
    badInformation.senderObservation(1)+1e-7;
Vbad = tcnsR27ValidateCommonFiber(left,badInformation);
assert(~Vbad.passCommonFiber && contains(Vbad.failureReason, ...
    "INFORMATION_MISMATCH"), ...
    'R27: sender-information corruption was not rejected.');
badDynamics = right;
badDynamics.affineTrajectoryResidual = 1e-7;
Vbad = tcnsR27ValidateCommonFiber(left,badDynamics);
assert(~Vbad.passCommonFiber && contains(Vbad.failureReason, ...
    "DYNAMIC_MISMATCH"), ...
    'R27: dynamic/reachability corruption was not rejected.');

% Set-valued argmax logic retains ties.
tieLeft = left;
tieRight = left;
tieLeft.qAugmented(:) = -1;
tieRight.qAugmented(:) = -1;
tieLeft.qAugmented(1:2) = 0;
tieRight.qAugmented(1:2) = 0;
Vtie = tcnsR27ValidateCommonFiber(tieLeft,tieRight);
assert(isequal(Vtie.leftArgmax,[0;1]) && ...
    isequal(Vtie.argmaxIntersection,[0;1]) && ~Vtie.disjointArgmax, ...
    'R27: set-valued argmax tie was silently broken.');

% Disjoint and common-winner logic are distinct.
disjointLeft = left;
disjointRight = left;
disjointLeft.qAugmented(:) = -1;
disjointRight.qAugmented(:) = -1;
disjointLeft.qAugmented(1) = 0;
disjointRight.qAugmented(1) = 0;
disjointRight.qAugmented(2) = 1;
Vdisjoint = tcnsR27ValidateCommonFiber(disjointLeft,disjointRight);
assert(Vdisjoint.disjointArgmax && isempty(Vdisjoint.argmaxIntersection), ...
    'R27: disjoint argmax sets were not detected.');
winnerLeft = left;
winnerRight = left;
winnerLeft.qAugmented(:) = -1;
winnerRight.qAugmented(:) = -1;
winnerLeft.qAugmented(1) = 0;
winnerRight.qAugmented(1) = 0;
Vwinner = tcnsR27ValidateCommonFiber(winnerLeft,winnerRight);
assert(~Vwinner.disjointArgmax && isequal(Vwinner.argmaxIntersection,0), ...
    'R27: common winner was not detected.');

fprintf('  deterministic common-state attempts    %d / 30\n', ...
    height(A.candidateTable));
fprintf('  joint-response negative control        rejected\n');
fprintf('  information negative control           rejected\n');
fprintf('  reachability negative control          rejected\n');
fprintf('  tie/disjoint/common-winner logic        PASS\n');

% R2.7 must not regress the complete approved R2.6 theory suite.
run(fullfile(projectRoot(),'tests', ...
    'test_tcns_r2_6_decision_identifiability.m'));
fprintf('test_tcns_r2_7_common_fiber: PASS\n');
