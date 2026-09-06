%% TEST_EXP20A_DELTA_CONTRACTS Native information-structure micro-contracts.

startup;
fprintf('\n============================================================\n');
fprintf('test_exp20a_delta_contracts\n');
fprintf('============================================================\n\n');

R=exp20aRegistry();
c=R.nativeCells(1);
cfg=struct('N',c.N,'rho',c.rho,'epsilon',c.epsilon, ...
    'slots',400,'burnIn',50,'feedbackLoss',R.privateFeedbackLoss, ...
    'feedbackDelaySlots',R.privateFeedbackDelaySlots);

arms=R.nativeArms;
rows=repmat(exp20aNativeEmptyRow(),numel(arms),1);
for k=1:numel(arms)
    o=simulateDeltaInformationStructure(cfg,arms{k},16027101);
    names=fieldnames(o);
    row=exp20aNativeEmptyRow();
    row.cell=c.id;
    for q=1:numel(names)
        if isfield(row,names{q})
            row.(names{q})=o.(names{q});
        end
    end
    rows(k)=row;
end
T=struct2table(rows);

checks=cell(0,2);
checks(end+1,:)={numel(unique(T.DRAW_HASH_EXACT))==1, ...
    'all arms use the same absolute stochastic draws'};
checks(end+1,:)={all(isfinite(T.MEAN_AOII)) && all(T.MEAN_AOII>=0), ...
    'all native AoII outcomes are finite and nonnegative'};
checks(end+1,:)={all(T.ATTEMPTS>=T.SUCCESSES) && ...
    all(T.ATTEMPTS>=T.COLLISIONS), ...
    'attempt/success/collision accounting is ordered'};
pub=T(string(T.arm)=='delta-public',:);
priv=T(string(T.arm)=='delta-private-delayed',:);
checks(end+1,:)={pub.FEEDBACK_GENERATED>0 && ...
    priv.FEEDBACK_GENERATED>=priv.FEEDBACK_DELIVERED && ...
    priv.FEEDBACK_DROPPED>0, ...
    'public and private feedback paths are active and private loss is realized'};
checks(end+1,:)={priv.MAX_FEEDBACK_QUEUE>0 && ...
    priv.FUTURE_FEEDBACK_READS==0, ...
    'private delayed queue is exercised without future feedback reads'};
checks(end+1,:)={all(T.SUCCESS_RATE<=1+1e-12) && ...
    all(T.COLLISION_SLOT_RATE<=1+1e-12), ...
    'native rates remain within slot-level bounds'};

a=simulateDeltaInformationStructure(cfg,'delta-private-delayed',16027101);
b=simulateDeltaInformationStructure(cfg,'delta-private-delayed',16027101);
checks(end+1,:)={isequaln(a,b), ...
    'private delayed execution is deterministic under a fixed seed'};

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp20a_delta_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp20a_delta_contracts: PASS (%d checks)\n',numel(flags));

