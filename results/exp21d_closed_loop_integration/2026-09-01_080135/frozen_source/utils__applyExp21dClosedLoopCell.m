function cfg=applyExp21dClosedLoopCell(cellId,seedValue)
%APPLYEXP21DCLOSEDLOOPCELL Build a frozen zero-loss integration context.

R=exp21dClosedLoopRegistry();
cellId=lower(strtrim(char(cellId)));
index=find(strcmp({R.cells.id},cellId),1);
if isempty(index)
    error('applyExp21dClosedLoopCell: unknown cell "%s".',cellId);
end
cfg=applyExp21CCell(R.cells(index).exp21cCell,seedValue);
N=cfg.swarm.N;
graph=logical(cfg.swarm.A);
graph(logical(cfg.swarm.pin(:)),1)=true;
cfg.swarm.A=double(graph | graph');
cfg.mac.lossModel='iid';
cfg.mac.separateAckTrace=false;
cfg.mac.residualLoss=0;
cfg.mac.dataResidualLoss=0;
cfg.mac.ackResidualLoss=0;
cfg.mac.backgroundLoad=0;
cfg.mac.interferenceMatrix=logical(cfg.swarm.A);
cfg.mac.carrierSenseMatrix=true(N);
cfg.mac.maxRetries=0;
cfg.shared.feedbackMode='none';
cfg.exp21dcl=struct('version',R.version,'cell',cellId, ...
    'stage',R.stage,'policyOptimizationAllowed',false, ...
    'submissionClaimPermitted',false);
cfg.mac=sharedMediumConfig(cfg);

end
