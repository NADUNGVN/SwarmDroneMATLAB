%% TEST_TCNS_AF2_RESIDUAL_MOMENTS Exact belief-moment contracts.

startup;

belief = struct();
belief.candidatePos = [0 0 0;1 0 0];
belief.candidateVel = [0 0 0;0 2 0];
belief.candidateAcc = [0 0 0;0 0 3];
belief.probability = [0.25;0.75];

M = tcnsAckFreeResidualMoments( ...
    [2 1 0],[1 1 0],[0 0 4],belief,2,0.5,1);
expectedCandidates = [4.5 2.5 4;2.5 1.5 1];
expectedMean = belief.probability'*expectedCandidates;
expectedSquare = belief.probability'*sum(expectedCandidates.^2,2);
assert(max(abs(M.candidateCorrection-expectedCandidates),[],'all')<1e-14, ...
    'AF2Moments: candidate corrections are incorrect.');
assert(max(abs(M.expectedCorrection-expectedMean))<1e-14, ...
    'AF2Moments: posterior mean correction is incorrect.');
assert(abs(M.expectedSquaredNorm-expectedSquare)<1e-14 && ...
    M.identityResidual<1e-13, ...
    'AF2Moments: second-moment identity is incorrect.');
assert(min(eig(M.covariance))>-1e-12, ...
    'AF2Moments: covariance is not positive semidefinite.');

% Ordinary-link mode must ignore NaN acceleration payloads exactly.
belief.candidateAcc(:) = NaN;
Mordinary = tcnsAckFreeResidualMoments( ...
    [2 1 0],[1 1 0],[],belief,2,0.5,0);
expectedOrdinary = [4.5 2.5 0;2.5 1.5 0];
assert(max(abs(Mordinary.candidateCorrection-expectedOrdinary),[],'all') ...
    <1e-14, ...
    'AF2Moments: ordinary mode consumed unavailable acceleration.');

fprintf('test_tcns_af2_residual_moments: PASS\n');

