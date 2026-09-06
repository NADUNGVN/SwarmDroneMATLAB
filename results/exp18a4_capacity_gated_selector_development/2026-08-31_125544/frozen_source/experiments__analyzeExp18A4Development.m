function analysis=analyzeExp18A4Development(runDir)
%ANALYZEEXP18A4DEVELOPMENT Audit exact routing and promotion conditions.

R=exp18a4Registry();
T=readtable(fullfile(runDir,'tidy.csv'),'TextType','string');
reference=readtable(fullfile(R.referenceRun,'tidy.csv'),'TextType','string');
auditRows=repmat(emptyAudit(),height(T),1);
for k=1:height(T)
    if T.serviceCertificateFeasible(k)==1 && T.macType(k)=="aloha"
        referenceArm="frame-adaptive";
    else
        referenceArm="frame-piggyback";
    end
    Q=reference(reference.seed==T.seed(k) & ...
        reference.scenario==T.scenario(k) & ...
        reference.macType==T.macType(k) & ...
        reference.arm==referenceArm,:);
    if height(Q)~=1
        error('analyzeExp18A4Development: reference row is not unique.');
    end
    d=0;
    for f=1:numel(R.aliasFields)
        name=R.aliasFields{f};
        d=max(d,abs(T.(name)(k)-Q.(name)));
    end
    auditRows(k)=struct('seed',T.seed(k),'context',char(T.scenario(k)), ...
        'macType',char(T.macType(k)),'serviceFeasible', ...
        T.serviceCertificateFeasible(k),'referenceArm',char(referenceArm), ...
        'maxAliasDifference',d);
end
aliasAudit=struct2table(auditRows);
writetable(aliasAudit,fullfile(runDir,'alias_audit.csv'));

coreMask=false(height(T),1);
for c=R.cells(strcmp({R.cells.role},'core'))
    coreMask=coreMask | T.scenario==string(c.id);
end
core=T(coreMask,:);
cellKeys=core.scenario+"|"+core.macType;
[uniqueKeys,ia]=unique(cellKeys);
cellRows=core(ia,:);
feasibleCells=cellRows(cellRows.serviceCertificateFeasible==1,:);
coverage=height(feasibleCells)>=R.minimumFeasibleCoreMacCells && ...
    numel(unique(feasibleCells.N))==2 && ...
    numel(unique(feasibleCells.macType))==2;
exactAlias=all(aliasAudit.maxAliasDifference==0);
infeasible=T.serviceCertificateFeasible==0;
abstention=all(T.ACK_STANDALONE(infeasible)==0) && ...
    all(T.CONTEXT_ACK_PERMITTED(infeasible)==0);
feasibleAloha=T(T.serviceCertificateFeasible==1 & T.macType=="aloha",:);
alohaActive=~isempty(feasibleAloha) && sum(feasibleAloha.ACK_STANDALONE)>0;

collisionRepair=true;
for c=R.cells(strcmp({R.cells.role},'core') & [R.cells.N]==10)
    C=T(T.scenario==string(c.id) & T.macType=="aloha",:);
    L=reference(reference.scenario==string(c.id) & ...
        reference.macType=="aloha" & reference.arm=="legacy-selector",:);
    reduction=(mean(L.COLLISION_FRAMES)-mean(C.COLLISION_FRAMES))/ ...
        max(abs(mean(L.COLLISION_FRAMES)),eps);
    collisionRepair=collisionRepair && ...
        reduction>=R.minimumCollisionFrameReduction-1e-12;
end
reverse=T(contains(T.scenario,"reverse"),:);
mismatch=~isempty(reverse) && ...
    all(reverse.calibrationSource=="nominal-moderate-mismatch");

gateNames={'exact_fixed_route_alias','feasible_coverage', ...
    'infeasible_exact_abstention','feasible_aloha_ack_activity', ...
    'n10_aloha_collision_frame_repair','reverse_mismatch_reported'}';
gatePassed=double([exactAlias;coverage;abstention;alohaActive; ...
    collisionRepair;mismatch]);
gateDetail={ ...
    sprintf('%d/%d rows have zero difference on %d registered fields', ...
        nnz(aliasAudit.maxAliasDifference==0),height(aliasAudit), ...
        numel(R.aliasFields)); ...
    sprintf('%d feasible core context--MAC cells with both N and access types', ...
        height(feasibleCells)); ...
    sprintf('%d infeasible trajectories emit zero standalone ACK',nnz(infeasible)); ...
    sprintf('%d standalone ACK attempts in feasible ALOHA trajectories', ...
        sum(feasibleAloha.ACK_STANDALONE)); ...
    sprintf('N10 ALOHA absolute collision reduction >= %.0f%%', ...
        100*R.minimumCollisionFrameReduction); ...
    'reverse boundary retains nominal ACK calibration mismatch'};
gates=table(gateNames,gatePassed,gateDetail, ...
    'VariableNames',{'gate','passed','detail'});
writetable(gates,fullfile(runDir,'development_decision_gates.csv'));

promote=all(gatePassed==1);
verdict=struct('status',ternary(promote, ...
    'READY_TO_PREREGISTER_FRESH_SEED_HOLDOUT', ...
    'REJECT_CAPACITY_GATED_SELECTOR'), ...
    'developmentOnly',true,'confirmatoryClaimPermitted',false, ...
    'gatesPassed',sum(gatePassed),'gatesTotal',numel(gatePassed), ...
    'exactAliasRows',nnz(aliasAudit.maxAliasDifference==0), ...
    'exactAliasTotal',height(aliasAudit), ...
    'feasibleCoreMacCells',height(feasibleCells), ...
    'futureHoldoutOpened',false,'hardwareClaimPermitted',false);
writeJson(fullfile(runDir,'development_verdict.json'),verdict);
analysis=struct('aliasAudit',aliasAudit,'gates',gates,'verdict',verdict);

end


function r=emptyAudit()

r=struct('seed',NaN,'context','','macType','', ...
    'serviceFeasible',NaN,'referenceArm','','maxAliasDifference',NaN);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp18A4Development: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
