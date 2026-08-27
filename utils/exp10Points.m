function pts = exp10Points()
%EXP10POINTS The pre-registered EXP10 final matrix, as data.
%
%   pts = exp10Points()
%
% One entry per SELECTED POINT. EXP10A runs them, EXP10B aggregates the
% dataset EXP10A produced, and run_simulation_v1_validation re-derives
% both from here, so no stage can quietly run a different matrix than
% another. The matrix is frozen: see docs/EXP10_PLAN.md sections 3 and
% 15. Nothing here is chosen after looking at a result.
%
% WHY THESE POINTS
%
% Each robustness point is a point that ALREADY EXPOSED A LIMIT in its
% source experiment, not the most flattering cell of that experiment:
%
%   LINK       where EXP08B's absolute safety gate failed
%   NODE       where EXP08C's 5 s outage safety gate failed
%   MISMATCH   where EXP09B's G2 absolute-RMSE gate failed
%   ESTIMATOR  where EXP09C's C3 DATA-rate gate failed
%
% and the coverage spans the three things the campaign claims about:
%
%   N = 5    physical realism (6-DOF followers)
%   N = 20   connectivity faults
%   N = 50   scalability anchor
%
% Fields:
%
%   id          short key used in every table and file
%   label       human-readable name
%   N           swarm size
%   plant       '6dof' or 'di' (double integrator)
%   topology    graph, built by applyTopologyConfig
%   kind        which perturbation applyExp10Point installs
%   scenarios   indices into exp10Scenarios()
%   family      Pareto point-family key (section 10 of the plan)
%   source      the locked experiment this point is inherited from
%   sourceTag   that experiment's git tag, or '-' where it has none
%   note        why the point is in the matrix
%
% N = 50 uses the EXP08 graph convention (applyTopologyConfig, which
% removes in-links to the leader because the leader reads the reference
% directly). EXP06A used applyScalableSwarmConfig, which keeps them. The
% two therefore have different channel counts at the same N, so ABSOLUTE
% traffic at N = 50 must never be compared back to EXP06A. Ratios
% between methods within EXP10 are unaffected, because every method here
% runs on the same graph.

sc = exp10Scenarios();

MOD_STR = [sc.MODERATE; sc.STRESSED];
ALL_SCN = [sc.CLEAN; sc.MODERATE; sc.STRESSED];

k = 0;

k = k + 1;
pts(k) = localPoint('NOMINAL', 'Nominal 6-DOF N=5', 5, '6dof', 'ring2', ...
    'nominal', ALL_SCN, 'NOMINAL', 'EXP09A', 'exp09a-locked', ...
    ['Main nominal point. Clean is included because the final ' ...
     'adaptivity criterion (plan section 11) needs three network ' ...
     'qualities to order DATA against.']);

k = k + 1;
pts(k) = localPoint('ACK', 'ACK impairment 10 % loss', 5, '6dof', 'ring2', ...
    'ack', MOD_STR, 'ACK', 'EXP07B', 'exp07b-locked', ...
    ['Reverse-channel impairment from EXP07B. Only Causal-v3 has an ' ...
     'ACK channel, so the three baselines must come out BIT-IDENTICAL ' ...
     'to their NOMINAL runs at the same seed. That is checked as a ' ...
     'protocol invariant rather than assumed.']);

k = k + 1;
pts(k) = localPoint('MISMATCH', 'B7 plant mismatch', 5, '6dof', 'ring2', ...
    'mismatch', MOD_STR, 'MISMATCH', 'EXP09B', 'exp09b-locked-partial', ...
    ['EXP09B arm B7: external-force proxy 0.5 m/s^2, true mass +10 %, ' ...
     'true drag +20 %, no actuator lag. The point where EXP09B G2 ' ...
     'failed on a controller limit.']);

k = k + 1;
pts(k) = localPoint('ESTIMATOR', 'C3 synthetic estimator', 5, '6dof', 'ring2', ...
    'estimator', MOD_STR, 'ESTIMATOR', 'EXP09C', 'exp09c-locked-partial', ...
    ['EXP09C arm C3: sigmaP 0.03 m, sigmaV 0.05 m/s, latency 50 ms. ' ...
     'The point where EXP09C G3 failed on noise-driven hard triggers.']);

k = k + 1;
pts(k) = localPoint('LINK', 'Permanent 20 % link removal', 20, 'di', 'ring2', ...
    'link', MOD_STR, 'LINK', 'EXP08B', 'exp08b-locked-partial', ...
    ['EXP08B permanent directed-link removal at 20 %, where the ' ...
     'absolute safety gate failed for every method alike.']);

k = k + 1;
pts(k) = localPoint('NODE', '1-node 5 s blackout', 20, 'di', 'ring2', ...
    'node', MOD_STR, 'NODE', 'EXP08C', 'exp08c-locked-partial', ...
    ['EXP08C single-follower communication blackout, 5 s from t = 12 s, ' ...
     'where the safety gate failed for every method alike.']);

k = k + 1;
pts(k) = localPoint('N20REF', 'N=20 no-fault reference', 20, 'di', 'ring2', ...
    'nominal', MOD_STR, 'N20REF', 'EXP08C', 'exp08c-locked-partial', ...
    ['REQUIRED DENOMINATOR, not an extra result. EXP08C judges safety ' ...
     'against MATCHED NO-FAULT ELIGIBILITY: a seed counts only if the ' ...
     'same method, scenario, topology, N and seed was already safe ' ...
     'WITHOUT the fault. Plan section 7 keeps the source experiment''s ' ...
     'eligibility rule, and that rule is unevaluable without this ' ...
     'point. It is also the reference the LINK point''s connectivity ' ...
     'classification is read against.']);

k = k + 1;
pts(k) = localPoint('SCALE', 'Scalability anchor N=50', 50, 'di', 'ring2', ...
    'nominal', MOD_STR, 'SCALE', 'EXP06A', '-', ...
    ['Scalability anchor, so the final matrix does not lose N = 50. ' ...
     'EXP08 graph convention; absolute traffic here is NOT comparable ' ...
     'to EXP06A.']);

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function p = localPoint(id, label, N, plant, topology, kind, scenarios, ...
    family, source, sourceTag, note)

p.id        = id;
p.label     = label;
p.N         = N;
p.plant     = plant;
p.topology  = topology;
p.kind      = kind;
p.scenarios = scenarios(:);
p.family    = family;
p.source    = source;
p.sourceTag = sourceTag;
p.note      = note;

end
