%% TEST_EXP16_CONTRACTS Frozen interaction design checks without holdout seeds.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp16_contracts\n');
fprintf('============================================================\n\n');
checks=cell(0,2);

R=exp16Registry();
[registryHash,registryLeaves]=configHash(R);
checks(end+1,:)={registryHash==89775929 && registryLeaves==56 && ...
    R.expectedRuns==600 && R.primaryFamilySize==6, ...
    'registry hash, leaves, matrix and six-test family are frozen'};

known=[exp14Registry().seeds; exp14cRegistry().seeds; ...
    exp14dRegistry().seeds; exp14eRegistry().seeds; exp14fRegistry().seeds; ...
    exp14gRegistry().seeds; exp14hRegistry().seeds; exp14iRegistry().seeds; ...
    (25000001:25000050)'];
checks(end+1,:)={numel(unique(R.seeds))==100 && ...
    isempty(intersect(R.seeds,known)) && ...
    ~ismember(R.developmentSeed,R.seeds), ...
    '100 holdout seeds are unique/disjoint and smoke seed is excluded'};

F=table(string({R.arms.macType})',string({R.arms.route})', ...
    logical([R.arms.primaryFactorial]'), ...
    'VariableNames',{'mac','route','primary'});
primary=F(F.primary,:);
expected=sortrows(table(["aloha";"aloha";"csma";"csma"], ...
    ["adaptive";"piggyback";"adaptive";"piggyback"], ...
    'VariableNames',{'mac','route'}));
checks(end+1,:)={height(F)==6 && height(primary)==4 && ...
    isequal(sortrows(primary(:,{'mac','route'})),expected) && ...
    R.expectedRuns==600 && R.primaryFamilySize==6, ...
    'registered arms contain one complete 2-by-2 plus two hybrid baselines'};

base=applyExp16Cell(R.developmentSeed);
[baseHash,baseLeaves]=configHash(base);
checks(end+1,:)={baseHash==105854169 && baseLeaves==105, ...
    'seed-fixed matched base configuration is frozen'};

% All arms use one supplied absolute trace. No holdout seed is opened.
base.swarm.T=0.40; base.shared.evalStart=0;
trace=generateSharedMediumTrace(base);
out=cell(numel(R.arms),1);
for k=1:numel(R.arms)
    [cfg,method]=applyExp16Arm(base,R.arms(k));
    out{k}=simSwarmSharedMedium(cfg,method,trace);
end
hashes=cellfun(@(x) x.traceHashExact,out);
states=cellfun(@(x) x.channelStateHash,out);
checks(end+1,:)={isscalar(unique(hashes)) && isscalar(unique(states)), ...
    'all six arms consume one absolute random/channel realization'};

for k=1:numel(R.arms)
    arm=R.arms(k); q=out{k};
    if strcmp(arm.route,'adaptive')
        routeOk=strcmp(q.feedbackMode,'adaptive');
    elseif strcmp(arm.route,'piggyback')
        routeOk=strcmp(q.feedbackMode,'piggyback') && ...
            q.netStats.ackFramesStandalone==0;
    else
        routeOk=strcmp(q.feedbackMode,'hybrid');
    end
    checks(end+1,:)={strcmp(q.method,ternary(strcmp(arm.route,'adaptive'), ...
        'mac-aware-broadcast','causal-broadcast')) && routeOk && ...
        abs(q.pAccess-0.20)<1e-12 && q.invariantViolations==0, ...
        sprintf('%s executes its exact MAC/route/access contract',arm.label)};
end

unknown=false;
try
    fake=R.arms(1); fake.route='post-hoc-route';
    applyExp16Arm(base,fake);
catch
    unknown=true;
end
checks(end+1,:)={unknown,'unknown feedback routes fail closed'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp16_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp16_contracts: PASS (%d checks)\n',numel(flags));


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
