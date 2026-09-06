%% TEST_EXP18_CONTRACTS Development matrix and decomposition contracts.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp18_contracts\n');
fprintf('============================================================\n\n');

checks=cell(0,2);
R=exp18Registry();
checks(end+1,:)={strcmp(R.stage,'development') && ...
    R.expectedRuns==1600 && ~R.confirmatory && ...
    ~R.futureHoldoutSeedsPermitted && ...
    max(R.seeds)<R.futureHoldoutMinimumSeed, ...
    'registry separates 1,600 development runs from every future holdout'};


%% Arm identities and access geometry

for macCell={'csma','aloha'}
    macType=macCell{1};
    base=applyExp18Cell('n5-moderate-bg0',R.seeds(1));
    base.mac.type=macType;
    base.mac.pAccess=1/base.swarm.N;
    base.mac=sharedMediumConfig(base);
    for k=1:numel(R.arms)
        arm=R.arms(k);
        [cfg,method,~,d]=applyExp18Arm(base,arm);
        if strcmp(macType,'aloha') && ~strcmp(arm.id,'legacy-selector')
            pOk=abs(cfg.mac.pAccess-1/35)<1e-12;
        else
            pOk=abs(cfg.mac.pAccess-1/5)<1e-12;
        end
        switch arm.id
            case 'legacy-selector'
                if strcmp(macType,'aloha')
                    semanticOk=strcmp(method,'mac-aware-broadcast') && ...
                        strcmp(cfg.shared.feedbackMode,'adaptive') && ...
                        strcmp(d.route,'adaptive');
                else
                    semanticOk=strcmp(method,'causal-broadcast') && ...
                        strcmp(cfg.shared.feedbackMode,'piggyback') && ...
                        strcmp(d.route,'piggyback');
                end
            case 'frame-piggyback'
                semanticOk=strcmp(method,'causal-broadcast') && ...
                    strcmp(cfg.shared.feedbackMode,'piggyback');
            case 'frame-adaptive'
                semanticOk=strcmp(method,'mac-aware-broadcast') && ...
                    strcmp(cfg.shared.feedbackMode,'adaptive');
            case 'context-aware'
                semanticOk=strcmp(method,'context-aware-broadcast') && ...
                    cfg.shared.contextAware.enabled && ...
                    strcmp(cfg.shared.contextAware.accessRule,'frame-aware');
        end
        checks(end+1,:)={pOk && semanticOk, ...
            sprintf('%s/%s arm has exact method, route and access semantics', ...
            macType,arm.id)};
    end
end


%% Reverse calibration mismatch is intentional and visible

reverse=applyExp18Cell('n5-moderate-reverse',R.seeds(1));
reverse.mac.type='aloha';
actual=reverse;
actual.shared.contextAware=struct('enabled',true);
actualPolicy=contextAwarePolicyConfig(actual);
contextArm=R.arms(strcmp({R.arms.id},'context-aware'));
[configured,~,~,~]=applyExp18Arm(reverse,contextArm);
mismatch=mean(configured.shared.contextAware.ackSuccessEstimate(:));
actualMean=mean(actualPolicy.ackSuccessEstimate(:));
checks(end+1,:)={strcmp( ...
    configured.shared.contextAware.calibrationSource, ...
    'nominal-moderate-mismatch') && mismatch>actualMean+1e-3, ...
    'reverse-asymmetric boundary carries an explicit optimistic mismatch'};


%% One absolute trace across MAC and policy arms

hashes=zeros(8,1); states=zeros(8,1); contextCounts=zeros(8,1);
q=0;
base=applyExp18Cell('n5-moderate-bg0',R.seeds(1));
base.swarm.T=0.3; base.shared.evalStart=0; base.sixdof.enable=false;
trace=generateSharedMediumTrace(base);
for macCell={'csma','aloha'}
    x=base;
    x.mac.type=macCell{1};
    x.mac.pAccess=1/x.swarm.N;
    x.mac=sharedMediumConfig(x);
    for k=1:numel(R.arms)
        q=q+1;
        [cfg,method,~,~]=applyExp18Arm(x,R.arms(k));
        out=simSwarmSharedMedium(cfg,method,trace);
        hashes(q)=out.traceHashExact;
        states(q)=out.channelStateHash;
        contextCounts(q)=out.netStats.contextAckEvaluated;
    end
end
checks(end+1,:)={isscalar(unique(hashes)) && ...
    isscalar(unique(states)), ...
    'both MAC types and all arms consume one absolute random realization'};
checks(end+1,:)={all(contextCounts([1:3 5:7])==0) && ...
    all(contextCounts([4 8])>=0), ...
    'context decision counters are inert outside the context-aware arm'};


%% Verdict

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp18_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp18_contracts: PASS (%d checks)\n',numel(flags));
