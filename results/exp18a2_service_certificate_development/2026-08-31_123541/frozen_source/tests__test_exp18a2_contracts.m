%% TEST_EXP18A2_CONTRACTS Service-certificate amendment contracts.

startup;

fprintf('\n============================================================\n');
fprintf('test_exp18a2_contracts\n');
fprintf('============================================================\n\n');

checks=cell(0,2);
R=exp18a2Registry();
checks(end+1,:)={R.expectedRuns==400 && ~R.confirmatory && ...
    ~R.futureHoldoutOpened && exist(fullfile(R.referenceRun,'tidy.csv'), ...
    'file')==2 && max(R.seeds)<R.futureHoldoutMinimumSeed, ...
    '400-run amendment is development-only and points to canonical v1'};


%% Frozen analytical coverage before performance

certRows=struct('context',{},'role',{},'N',{},'macType',{}, ...
    'feasible',{},'ratio',{});
for c=R.cells
    for m=1:numel(R.macTypes)
        base=applyExp18Cell(c.id,R.seeds(1));
        base.mac.type=R.macTypes{m};
        base.mac.pAccess=min(0.20,1/base.swarm.N);
        [~,~,~,~,cert]=applyExp18A2Arm(base);
        certRows(end+1)=struct('context',c.id,'role',c.role, ...
            'N',c.N,'macType',R.macTypes{m}, ...
            'feasible',cert.feasible,'ratio',cert.serviceRatio); %#ok<SAGROW>
    end
end
core=certRows(strcmp({certRows.role},'core'));
feasible=core([core.feasible]);
checks(end+1,:)={numel(feasible)>=R.minimumFeasibleCoreMacCells && ...
    numel(unique([feasible.N]))==2 && ...
    numel(unique({feasible.macType}))==2, ...
    'analytical screen retains preregistered minimum N/MAC coverage'};

n5A=certRows(strcmp({certRows.context},'n5-moderate-bg0') & ...
    strcmp({certRows.macType},'aloha'));
n10A=certRows(strcmp({certRows.context},'n10-moderate-bg0') & ...
    strcmp({certRows.macType},'aloha'));
n5Bg=certRows(strcmp({certRows.context},'n5-moderate-bg30') & ...
    strcmp({certRows.macType},'aloha'));
checks(end+1,:)={n5A.feasible && ~n10A.feasible && ~n5Bg.feasible && ...
    n5A.ratio>1 && n10A.ratio<1, ...
    'capacity boundary is fixed by service rate rather than observed failure'};


%% Infeasible arm abstains and preserves row schema

base=applyExp18Cell('n10-moderate-bg0',R.seeds(1));
base.mac.type='aloha'; base.mac.pAccess=1/base.swarm.N;
base.swarm.T=0.8; base.shared.evalStart=0; base.sixdof.enable=false;
trace=generateSharedMediumTrace(base);
[cfg,method,label,details,cert]=applyExp18A2Arm(base);
meta=struct('stage','development-amendment', ...
    'scenario','n10-moderate-bg0', ...
    'scenarioLabel','N10 Moderate bg0', ...
    'family','EXP18A2 test','arm',R.arm.id,'pointIndex',1, ...
    'parameterValue',0,'role','core','channel','moderate', ...
    'modifier','nominal','basePAccess',1/10);
row=runExp18A2Cell(cfg,method,label,meta,trace,details,cert);
checks(end+1,:)={~cert.feasible && row.ACK_STANDALONE==0 && ...
    row.CONTEXT_ACK_PERMITTED==0 && ...
    isequal(fieldnames(row),fieldnames(exp18a2EmptyRow())), ...
    'certificate-infeasible N10 ALOHA abstains with exact row schema'};


%% Verdict

flags=cellfun(@logical,checks(:,1));
for k=1:size(checks,1)
    if flags(k), tag='ok'; else, tag='FAIL'; end
    fprintf('    %-4s %s\n',tag,checks{k,2});
end
if ~all(flags)
    error('test_exp18a2_contracts: %d of %d checks failed.', ...
        nnz(~flags),numel(flags));
end
fprintf('\ntest_exp18a2_contracts: PASS (%d checks)\n',numel(flags));
