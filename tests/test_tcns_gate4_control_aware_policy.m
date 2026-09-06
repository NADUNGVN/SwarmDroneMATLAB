%% TEST_TCNS_GATE4_CONTROL_AWARE_POLICY Derived budget and causal-policy contracts.

startup;

fprintf('\n=== TCNS Gate-4 control-aware policy checks ===\n\n');

sc = exp10Scenarios();
points = exp10Points();
pt = points(strcmp({points.id},'NOMINAL'));
cfg = applyExp10Point(pt,sc.STRESSED,27020001);
cfg.sixdof.enable = false;


%% The theorem-derived allocation satisfies the declared target.

epsilon = 0.20;
B = tcnsControlAwareBudget(cfg,epsilon);
assert(max(B.certifiedPositionBound)<=epsilon+1e-12, ...
    'Gate4: receiver disturbance allocation misses its position target.');
assert(B.conditional && strcmp(B.version,'gate4-equal-link-v1'), ...
    'Gate4: budget provenance/conditional status is missing.');

for i = 2:cfg.swarm.N
    active = cfg.swarm.A(i,:)~=0;
    allocated = sum(B.linkBudget(i,active));
    if cfg.swarm.pin(i)>0
        allocated = allocated+B.leaderBudget(i);
    end
    assert(abs(allocated-B.receiverCommandBudget)<1e-12, ...
        'Gate4: local allocations do not sum to receiver budget at i=%d.',i);
end
assert(all(isnan(B.linkBudget(1,:))), ...
    'Gate4: a theorem budget was assigned to the uncontrolled leader row.');


%% Pure policy branches are deterministic and have the frozen semantics.

policy = struct('minInterTx',0.02,'retryInterval',0.10);
[send,branch,info] = controlAwareFreshnessPolicy(0.9,0.8,1,0.2,0,policy);
assert(~send && branch==0 && ~info.budgetViolated, ...
    'Gate4: a within-budget contribution transmitted.');

[send,branch,info] = controlAwareFreshnessPolicy(1.2,1.1,1,0.2,1,policy);
assert(send && branch==1 && ~info.latestSentWouldSatisfy, ...
    'Gate4: new information did not bypass retry waiting.');

[send,branch,info] = controlAwareFreshnessPolicy(1.2,0.8,1,0.06,1,policy);
assert(~send && branch==0 && info.usefulInFlightSuppressed && ...
    info.retryWaiting, ...
    'Gate4: a useful in-flight payload was not suppressed before retry.');

[send,branch] = controlAwareFreshnessPolicy(1.2,0.8,1,0.10,1,policy);
assert(send && branch==3, ...
    'Gate4: conditional retry did not fire at its declared interval.');

[send,branch] = controlAwareFreshnessPolicy(1.2,0.8,1,0.10,0,policy);
assert(send && branch==2, ...
    'Gate4: recovery without an outstanding payload did not fire.');


%% Link contribution ignores the simulator-only DATA drop outcome.

candidate = struct('genTime',0.1,'seq',1,'pos',[1 0 0], ...
    'vel',[0.5 0 0],'acc',[NaN NaN NaN],'dropped',false);
L1 = tcnsControlAwareLinkState([2 0 0],[1 0 0],[0 0 0],[0 0 0], ...
    candidate,[1 0 0],[0.5 0 0],2,3,10);
candidate.dropped = true;
L2 = tcnsControlAwareLinkState([2 0 0],[1 0 0],[0 0 0],[0 0 0], ...
    candidate,[1 0 0],[0.5 0 0],2,3,10);
assert(isequaln(L1,L2) && ~L1.usesDropOutcome, ...
    'Gate4: local control risk used the hidden DATA drop outcome.');
assert(abs(L1.setContribution-7)<1e-14 && ...
    abs(L1.latestSentContribution-3.5)<1e-14, ...
    'Gate4: controller-weighted link contribution is incorrect.');


%% Enabling no new mode leaves the historical trajectory unchanged.

cfgLegacy = cfg;
cfgLegacy.swarm.T = 3;
outImplicit = simSwarmAoICausal(cfgLegacy);
cfgLegacy.causal.policyMode = 'legacy-v3';
outExplicit = simSwarmAoICausal(cfgLegacy);
legacyFields = {'P','V','A','txCountLog','ackCountLog','neighborAoI', ...
    'estimatedAoI','txCount','ackTxCount','dropCount','invariantViolations'};
for q = 1:numel(legacyFields)
    name = legacyFields{q};
    assert(isequaln(outImplicit.(name),outExplicit.(name)), ...
        'Gate4: explicit legacy mode changed field %s.',name);
end


%% Integrated policy is causal, deterministic, and exercises its branches.

cfgCA = cfg;
cfgCA.swarm.T = 8;
cfgCA.causal.policyMode = 'control-aware';
cfgCA.controlAware.epsilonPosition = epsilon;
cfgCA.controlAware.retryInterval = 0.10;
cfgCA.tcns.logReceiverState = true;
cfgCA.tcns.logCausalSetBound = true;

out1 = simSwarmAoICausal(cfgCA);
out2 = simSwarmAoICausal(cfgCA);

expectedChecksPerStep = nnz(cfgCA.swarm.A(2:end,:)) + ...
    nnz(cfgCA.swarm.pin(2:end));
assert(out1.controlAwareCheckCount==numel(out1.t)*expectedChecksPerStep, ...
    'Gate4: not every controller-relevant payload was checked exactly once.');
assert(out1.controlAwareActive && out1.invariantViolations==0, ...
    'Gate4: integrated mode is inactive or violates the ACK protocol.');
assert(out1.controlAwareViolationCount>0 && ...
    out1.controlAwareNewInformationCount>0 && ...
    out1.controlAwareUsefulInFlightSuppressedCount>0, ...
    'Gate4: integrated fixture does not exercise violation/send/suppression.');
assert(out1.controlAwareNewInformationCount + ...
    out1.controlAwareRecoveryCount + out1.controlAwareRetryCount <= ...
    out1.txCount, ...
    'Gate4: decision accounting exceeds actual DATA transmissions.');
assert(isequaln(out1.P,out2.P) && isequaln(out1.V,out2.V) && ...
    isequaln(out1.txCountLog,out2.txCountLog) && ...
    isequaln(out1.controlAwareViolationCountLog, ...
    out2.controlAwareViolationCountLog), ...
    'Gate4: fixed-seed integrated run is not deterministic.');

D = tcnsCommunicationDisturbanceBound(out1,cfgCA);
assert(all(D.causalSetCoverage(:)), ...
    'Gate4: integrated receiver payload escaped the causal sender set.');


%% Static transmitter-side files cannot read receiver truth.

root = projectRoot();
guarded = {
    fullfile(root,'network','enqueueCausalAoIPackets.m')
    fullfile(root,'network','controlAwareFreshnessPolicy.m')
    fullfile(root,'utils','tcnsControlAwareLinkState.m')
};
forbidden = {'net.genTime','net.leaderGenTime','net.Pij','net.Vij', ...
    'net.leaderPos','net.leaderVel','net.leaderAcc','net.valid'};
for f = 1:numel(guarded)
    src = fileread(guarded{f});
    lines = strsplit(src,newline);
    for lineIndex = 1:numel(lines)
        line = lines{lineIndex};
        comment = strfind(line,'%');
        if ~isempty(comment), line = line(1:comment(1)-1); end
        for q = 1:numel(forbidden)
            pattern = [regexptranslate('escape',forbidden{q}) ...
                '(?![A-Za-z0-9_])'];
            assert(isempty(regexp(line,pattern,'once')), ...
                'Gate4: %s reads forbidden receiver state %s.', ...
                guarded{f},forbidden{q});
        end
    end
end

fprintf('  epsilon / receiver command budget          %.3f m / %.4f m/s^2\n', ...
    epsilon,B.receiverCommandBudget);
fprintf('  certificate worst position coefficient     %.6f\n', ...
    B.worstPositionCoefficient);
fprintf('  violations / new / retry / suppressed      %d / %d / %d / %d\n', ...
    out1.controlAwareViolationCount, ...
    out1.controlAwareNewInformationCount,out1.controlAwareRetryCount, ...
    out1.controlAwareUsefulInFlightSuppressedCount);
fprintf('test_tcns_gate4_control_aware_policy: PASS\n');

