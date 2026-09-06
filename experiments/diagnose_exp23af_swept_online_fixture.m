function diagnose_exp23af_swept_online_fixture()
%DIAGNOSE_EXP23AF_SWEPT_ONLINE_FIXTURE Calibrate causal command capsules.

startup;
expRun=startExperiment('exp23af_swept_online_diagnostic', ...
    'Causal online command-sweep closure calibration.');
seeds=(16093001:16093005)'; radii=.25:.05:.55;
tracking=[.02 .04 .06 .08 .10]; target=[-1.05 .55 0];
rows=cell(0,15);
for seed=seeds'
    cfg=applyExp21dClosedLoopCell('n10-ring2-zero-loss',seed);
    cfg=periodicConfig(cfg); trace=generateSharedMediumTrace(cfg);
    out=simSwarmSharedMedium(cfg,'periodic',trace);
    k=find(out.t>=6-1e-12,1); N=cfg.swarm.N;
    p=squeeze(out.PHat(k,:,:))-out.LeaderPos(k,:);
    proposed=p; proposed(10,:)=p(10,:)+target-cfg.swarm.offsets(10,:);
    neighbor=logical(cfg.swarm.A);
    management=logical((double(neighbor)+eye(N))^2);
    management(1:N+1:end)=false;
    packet=packetConfig(N);
    for radius=radii
        for tube=tracking
            G=buildCausalSweptReceiverClosure(p,proposed,tube,radius, ...
                neighbor,management,10,packet);
            M=G.migration;
            nonincident=nnz(M.changedEdgeA~=10&M.changedEdgeB~=10);
            protectedFree=~any(M.oldSlot==N)&& ...
                ~any(M.candidateSlot==N);
            rows(end+1,:)={seed,radius,tube,M.admissible, ... %#ok<AGROW>
                string(M.reason),M.changedEdgeCount,nonincident, ...
                M.affectedCount,M.changedSlotCount,max(M.oldSlot), ...
                max(M.candidateSlot),M.prepareBytes,M.maxResponseBytes, ...
                protectedFree,G.hashExact};
        end
    end
end
T=cell2table(rows,'VariableNames',{'seed','interferenceRadius', ...
    'trackingRadius','admissible','reason','changedSenderEdges', ...
    'nonincidentSenderEdges','affectedCount','changedSlotCount', ...
    'oldColors','newColors','prepareBytes','maxResponseBytes', ...
    'protectedSlotFree','geometryHash'});
writetable(T,fullfile(expRun.dir,'swept_fixture_scan.csv'));
valid=T.admissible==1&T.changedSlotCount>0& ...
    T.nonincidentSenderEdges>0&T.protectedSlotFree==1;
[group,S]=findgroups(T(:,{'interferenceRadius','trackingRadius'}));
S.nSeeds=splitapply(@numel,T.seed,group);
S.validSeeds=splitapply(@sum,double(valid),group);
S.meanAffected=splitapply(@mean,T.affectedCount,group);
S.maxPrepareBytes=splitapply(@max,T.prepareBytes,group);
S.maxResponseBytes=splitapply(@max,T.maxResponseBytes,group);
writetable(S,fullfile(expRun.dir,'swept_fixture_summary.csv'));
disp(S(S.validSeeds==numel(seeds),:));
verdict=struct('status','SWEPT_ONLINE_FIXTURE_DIAGNOSTIC_COMPLETE', ...
    'rows',height(T),'fullyValidParameterCells', ...
    nnz(S.validSeeds==numel(seeds)), ...
    'confirmationEvidence',false,'next','freeze_online_coupled_matrix');
writeJson(fullfile(expRun.dir,'diagnostic_verdict.json'),verdict);
save(fullfile(expRun.dir,'workspace.mat'),'T','S','verdict');
finishExperiment(expRun);

end


function cfg=periodicConfig(cfg)

cfg.net.commPeriod=.12; cfg.mac.type='tdma'; cfg.mac.pAccess=1;
cfg.mac.maxRetries=0; cfg.mac.lossModel='iid'; cfg.mac.residualLoss=.2;
cfg.mac.dataResidualLoss=.2; cfg.mac.ackResidualLoss=0;
cfg.shared.feedbackMode='none'; cfg.shared.serviceScheduler=struct( ...
    'mode','continuous-local-static-tdma','logDecisions',true, ...
    'tieBreak','fifo-node','reservationFrameSlots',cfg.swarm.N, ...
    'clockOffsetMaxSec',.25e-3,'clockDriftMaxPpm',40, ...
    'continuousGuardTime',.0015,'continuousSyncPeriod',inf, ...
    'continuousEpochLeadTime',.00073003, ...
    'continuousExactAirtime',true);
cfg.mac=sharedMediumConfig(cfg);
cfg.shared.serviceScheduler=serviceSchedulerConfig(cfg);

end


function packet=packetConfig(N)

packet=struct('maxDataSlots',N,'maxAffectedNodes',N, ...
    'prepareHeaderBytes',32,'affectedEntryBytes',4,'claimBytes',72, ...
    'quietBytes',24,'lockProofBytes',28, ...
    'certificateHeaderBytes',16,'certificateEntryBytes',10, ...
    'commitBytes',28,'maxControlPacketBytes',96,'revokeBytes',24);

end


function writeJson(path,value)

fid=fopen(path,'w'); if fid<0, error('exp23af diagnostic: write.'); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(value,'PrettyPrint',true));

end
