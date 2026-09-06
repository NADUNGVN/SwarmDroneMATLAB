%% TEST_EXP14D_FACTORIAL_CONTRACTS Closed interface checks before opening EXP14D.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp14d_factorial_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

R=exp14dRegistry();
F=[[R.arms.adaptiveAck]' [R.arms.loadGuard]' [R.arms.accessScaling]'];
checks(end+1,:)={R.contractHash==8052507 && R.expectedRuns==384, ...
    'registry hash and 384-run matrix are frozen'};
C=exp14cRegistry();
checks(end+1,:)={size(unique(F,'rows'),1)==8 && ...
    isequal(sortrows(double(F)),sortrows(dec2bin(0:7)-'0')), ...
    'factor registry contains the complete binary cube exactly once'};
checks(end+1,:)={isempty(intersect(R.seeds,C.seeds)), ...
    'EXP14D seeds are disjoint from EXP14C development'};

base=applyExp14DCell('n10-ring2',R.seeds(1));
methods=strings(numel(R.arms),1);
modes=strings(numel(R.arms),1);
for k=1:numel(R.arms)
    [cfg,method]=applyExp14DArm(base,R.arms(k));
    methods(k)=method;
    modes(k)=cfg.shared.feedbackMode;
end
checks(end+1,:)={all(modes(logical(F(:,1)))=="adaptive") && ...
    all(modes(~logical(F(:,1)))=="hybrid"), ...
    'factor A maps exactly to adaptive versus hybrid feedback'};
checks(end+1,:)={all(methods(logical(F(:,1)))=="mac-aware-broadcast") && ...
    all(methods(~logical(F(:,1)) & logical(F(:,2)))== ...
    "load-guarded-broadcast") && all(methods(~logical(F(:,1)) & ...
    ~logical(F(:,2)))=="causal-broadcast"), ...
    'method enum exposes guard-only cells without changing legacy methods'};

badMode=false;
try
    x=base; x.swarm.T=0.1; x.shared.feedbackMode='adaptive';
    x.shared.macAware=macAwarePolicyConfig(x);
    simSwarmSharedMedium(x,'load-guarded-broadcast');
catch
    badMode=true;
end
badGuard=false;
try
    x=base; x.swarm.T=0.1; x.shared.feedbackMode='hybrid';
    x.shared.macAware=macAwarePolicyConfig(x);
    x.shared.macAware.loadGuardEnabled=false;
    simSwarmSharedMedium(x,'load-guarded-broadcast');
catch
    badGuard=true;
end
checks(end+1,:)={badMode && badGuard, ...
    'load-guarded method rejects wrong feedback and disabled guard'};

% Setting the additive MAC-aware flags cannot alter causal-broadcast unless
% the caller selects the new method enum.
x0=applyExp14DCell('n5-csma',R.seeds(1)); x0.swarm.T=0.4;
x0.shared.macAware=macAwarePolicyConfig(x0);
x0.shared.macAware.loadGuardEnabled=false;
x0.shared.macAware.accessScalingEnabled=false;
x1=x0; x1.shared.macAware.loadGuardEnabled=true;
x1.shared.macAware.accessScalingEnabled=true;
trace=generateSharedMediumTrace(x0);
o0=simSwarmSharedMedium(x0,'causal-broadcast',trace);
o1=simSwarmSharedMedium(x1,'causal-broadcast',trace);
checks(end+1,:)={isequaln(o0.P,o1.P) && isequaln(o0.V,o1.V) && ...
    isequaln(o0.netStats,o1.netStats) && isequaln(o0.netLogs,o1.netLogs), ...
    'legacy causal-broadcast ignores additive guard/scaling flags'};

% At N5, p_configured already equals 1/N. All four S pairs must therefore
% produce identical physical behavior on the same trace.
base5=applyExp14DCell('n5-csma',R.seeds(2)); base5.swarm.T=0.4;
trace5=generateSharedMediumTrace(base5);
n5Exact=true;
for A=0:1
    for G=0:1
        arm0=findArm(R,A,G,0); arm1=findArm(R,A,G,1);
        [c0,m0]=applyExp14DArm(base5,arm0);
        [c1,m1]=applyExp14DArm(base5,arm1);
        q0=simSwarmSharedMedium(c0,m0,trace5);
        q1=simSwarmSharedMedium(c1,m1,trace5);
        n5Exact=n5Exact && isequaln(q0.P,q1.P) && ...
            isequaln(q0.V,q1.V) && isequaln(q0.netStats,q1.netStats) && ...
            isequaln(q0.netLogs,q1.netLogs) && ...
            q0.pAccess==q1.pAccess;
    end
end
checks(end+1,:)={n5Exact, ...
    'N5 access-scaling negative controls are bit-identical'};

% Both adaptive and hybrid-guarded paths expose the same scaled access at N10.
[ca,ma]=applyExp14DArm(base,findArm(R,1,0,1)); ca.swarm.T=0.2;
[ch,mh]=applyExp14DArm(base,findArm(R,0,1,1)); ch.swarm.T=0.2;
ta=generateSharedMediumTrace(ca);
oa=simSwarmSharedMedium(ca,ma,ta);
oh=simSwarmSharedMedium(ch,mh,ta);
checks(end+1,:)={abs(oa.pAccess-0.1)<1e-12 && ...
    abs(oh.pAccess-0.1)<1e-12 && strcmp(oh.feedbackMode,'hybrid') && ...
    all(isfinite(oh.P(:))) && oh.invariantViolations==0, ...
    'scaled adaptive and guarded-hybrid paths run at p=1/N'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp14d_factorial_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp14d_factorial_contracts: PASS (%d checks)\n',numel(flags));


function arm=findArm(R,A,G,S)

idx=[R.arms.adaptiveAck]'==logical(A) & ...
    [R.arms.loadGuard]'==logical(G) & ...
    [R.arms.accessScaling]'==logical(S);
if nnz(idx)~=1, error('test_exp14d: factor lookup is not unique.'); end
arm=R.arms(idx);

end
