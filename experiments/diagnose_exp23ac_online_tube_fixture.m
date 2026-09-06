function diagnose_exp23ac_online_tube_fixture()
%DIAGNOSE_EXP23AC_ONLINE_TUBE_FIXTURE Calibrate a safe causal stimulus.
%
% Development-only diagnostic. It does not create confirmation evidence.

startup;
expRun=startExperiment('exp23ac_receiver_lift_diagnostic', ...
    'Falsify one-sender locality under online receiver-lifted tubes.');
seed=16089999;
targets=[-1.20 .60 0; -1.10 .55 0; -1.05 .55 0; ...
    -1.05 .50 0; -1.00 .50 0];
rows=cell(size(targets,1),8);
selectedOut=[]; selectedCfg=[];
for q=1:size(targets,1)
    cfg=applyExp21dClosedLoopCell('n10-ring2-zero-loss',seed);
    cfg.swarm.offsetTransitions=struct('timeSec',6,'endTimeSec',10, ...
        'node',10,'newOffset',targets(q,:));
    cfg=periodicConfig(cfg,10);
    cfg.mac.residualLoss=.2; cfg.mac.dataResidualLoss=.2;
    cfg.mac=sharedMediumConfig(cfg);
    trace=generateSharedMediumTrace(cfg);
    out=simSwarmSharedMedium(cfg,'periodic',trace);
    metrics=computeSharedMediumMetrics(out,cfg);
    active=out.t>=6;
    accel=squeeze(out.A(active,10,:));
    speed=squeeze(out.V(active,10,:));
    distance=zeros(nnz(active),1);
    P=out.P(active,:,:);
    for k=1:size(P,1)
        now=squeeze(P(k,:,:));
        D=vecnorm(now-now(10,:),2,2); D(10)=inf;
        distance(k)=min(D);
    end
    rows(q,:)={q,targets(q,1),targets(q,2),metrics.formationRMSE, ...
        metrics.minSeparationEval,max(vecnorm(accel,2,2)), ...
        max(vecnorm(speed,2,2)),min(distance)};
    if q==3, selectedOut=out; selectedCfg=cfg; end
end
T=cell2table(rows,'VariableNames',{'candidate','targetX','targetY', ...
    'RMSE','minSepEval','maxNode10Accel','maxNode10Speed', ...
    'minNode10Distance'});
disp(T);
[F,C]=scanTubeEvents(selectedOut,selectedCfg);
writetable(T,fullfile(expRun.dir,'formation_candidates.csv'));
writetable(F,fullfile(expRun.dir,'admissible_local_events.csv'));
writetable(C,fullfile(expRun.dir,'receiver_lifted_graph_changes.csv'));
nonlocal=string(C.reason)=="nonlocal_graph_change";
status='ONE_SENDER_LOCALITY_NOT_EXERCISED';
if any(nonlocal)
    status='ONE_SENDER_LOCALITY_REJECTED_BY_RECEIVER_LIFT';
end
verdict=struct('status',status,'developmentDiagnostic',true, ...
    'seed',seed,'safeFormationCandidates',sum(T.minSepEval>0.4), ...
    'graphChangeRows',height(C),'nonlocalGraphChangeRows',nnz(nonlocal), ...
    'admissibleLocalMigrationRows',height(F), ...
    'onlinePlantCouplingPermitted',false, ...
    'requiredNextMechanism','receiver_lifted_dependency_closure');
writeJson(fullfile(expRun.dir,'receiver_lift_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','F','C','verdict');
fprintf('EXP23AC DIAGNOSTIC: %s\n',status);
finishExperiment(expRun);

end


function [F,C]=scanTubeEvents(out,cfg)

N=cfg.swarm.N; neighbor=logical(cfg.swarm.A);
management=logical((double(neighbor)+eye(N))^2);
management(1:N+1:end)=false;
packet=struct('maxDataSlots',10,'claimBytes',72, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'maxControlPacketBytes',96,'revokeBytes',24);
horizons=[.5 .75 1.0]; radii=[.20 .25 .30 .35 .40 .45];
accelerationBounds=[.35 .40 .50];
found=cell(0,10);
changed=cell(0,11);
for H=horizons
    for radius=radii
        for amax=accelerationBounds
            for k=find(out.t>=6 & out.t<=10)'
                if k<=1, continue; end
                nowP=squeeze(out.PHat(k,:,:)); nowV=squeeze(out.VHat(k,:,:));
                oldP=nowP; oldV=nowV;
                oldP(10,:)=squeeze(out.PHat(k-1,10,:));
                oldV(10,:)=squeeze(out.VHat(k-1,10,:));
                old=state(oldP,oldV,amax); fresh=state(nowP,nowV,amax);
                G=buildCausalLocalUnionGeometryMigration(old,fresh,H, ...
                    radius,neighbor,management,10,packet);
                M=G.migration;
                if (M.addedEdgeCount+M.removedEdgeCount)>0
                    changed(end+1,:)={H,radius,amax,out.t(k), ... %#ok<AGROW>
                        M.addedEdgeCount,M.removedEdgeCount, ...
                        M.oldSlot(10),M.newSlot,M.slotChanged, ...
                        M.admissible,string(M.reason)};
                end
                if M.admissible && M.slotChanged && ...
                        (M.addedEdgeCount+M.removedEdgeCount)>0
                    horizon=out.t>=out.t(k)-1e-12 & ...
                        out.t<=out.t(k)+H+1e-12;
                    maxA=max(vecnorm(reshape(out.A(horizon,:,:),[],3),2,2));
                    actualSubset=actualSubsetTube(out,nowP,nowV,k,H, ...
                        radius,amax,G.newPhysicalGraph);
                    found(end+1,:)={H,radius,amax,out.t(k), ... %#ok<AGROW>
                        M.addedEdgeCount,M.removedEdgeCount, ...
                        M.oldSlot(10),M.newSlot,maxA,actualSubset};
                    break;
                end
            end
        end
    end
end
if isempty(found)
    fprintf('No admissible online tube migration event found.\n');
    F=cell2table(cell(0,10),'VariableNames',{'horizon','radius', ...
        'accelBound','eventTime','added','removed','oldSlot','newSlot', ...
        'maxActualAccel','actualPhysicalSubset'});
else
    F=cell2table(found,'VariableNames',{'horizon','radius','accelBound', ...
        'eventTime','added','removed','oldSlot','newSlot','maxActualAccel', ...
        'actualPhysicalSubset'});
    disp(F);
end
if isempty(changed)
    fprintf('No sender-conflict graph change found.\n');
    C=cell2table(cell(0,11),'VariableNames',{'horizon','radius', ...
        'accelBound','eventTime','added','removed','oldSlot','newSlot', ...
        'slotChanged','admissible','reason'});
else
    C=cell2table(changed,'VariableNames',{'horizon','radius','accelBound', ...
        'eventTime','added','removed','oldSlot','newSlot','slotChanged', ...
        'admissible','reason'});
    fprintf('First graph-change rows (up to 30):\n');
    disp(C(1:min(30,height(C)),:));
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('exp23ac: cannot write JSON.'); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end


function S=state(p,v,amax)

N=size(p,1);
S=struct('p',p,'v',v,'positionError',1e-9*ones(N,1), ...
    'velocityError',1e-9*ones(N,1), ...
    'accelerationBound',amax*ones(N,1));

end


function valid=actualSubsetTube(out,p0,v0,k0,H,radius,amax,certified)

valid=true;
index=find(out.t>=out.t(k0)-1e-12 & out.t<=out.t(k0)+H+1e-12);
for k=reshape(index,1,[])
    tau=out.t(k)-out.t(k0);
    actual=squeeze(out.P(k,:,:));
    % Tube containment is checked independently of graph inclusion.
    bound=.5*amax*tau^2+1e-9*(1+tau);
    if any(vecnorm(actual-(p0+v0*tau),2,2)>bound+1e-10)
        valid=false; return;
    end
    physical=false(size(certified));
    for i=1:size(actual,1)
        for j=i+1:size(actual,1)
            physical(i,j)=norm(actual(i,:)-actual(j,:))<=radius;
            physical(j,i)=physical(i,j);
        end
    end
    if any(triu(physical&~certified,1),'all')
        valid=false; return;
    end
end

end


function cfg=periodicConfig(cfg,N)

cfg.net.commPeriod=.12;
cfg.mac.type='tdma'; cfg.mac.pAccess=1; cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-local-static-tdma','logDecisions',true, ...
    'tieBreak','fifo-node','reservationFrameSlots',N, ...
    'clockOffsetMaxSec',0.25e-3,'clockDriftMaxPpm',40, ...
    'continuousGuardTime',0.0015,'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',0.00073003, ...
    'continuousExactAirtime',true);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);

end
