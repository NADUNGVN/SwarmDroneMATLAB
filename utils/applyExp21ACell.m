function cfg=applyExp21ACell(cellId,seedValue)
%APPLYEXP21ACELL Build one frozen EXP21A scheduling context.

R=exp21aRegistry();
cellId=lower(strtrim(char(cellId)));
idx=find(strcmp({R.cells.id},cellId),1);
if isempty(idx)
    error('applyExp21ACell: unknown context "%s".',cellId);
end
c=R.cells(idx);
cfg=applyExp20ACell(c.baseCell,seedValue);
N=cfg.swarm.N;
if strcmp(c.controlReach,'full')
    reach=true(N);
elseif strcmp(c.controlReach,'two-hop-ring')
    reach=ringReach(N,2);
else
    error('applyExp21ACell: unknown control reach "%s".',c.controlReach);
end

offsetMax=0;
driftMax=0;
if c.clockEnabled
    offsetMax=R.reservation.clockOffsetMaxSec;
    driftMax=R.reservation.clockDriftMaxPpm;
end
cfg.exp21a=struct( ...
    'version',R.version,'cell',c.id,'role',c.role, ...
    'baseCell',c.baseCell,'developmentFalsification',true, ...
    'candidateOptimizationAllowed',false, ...
    'controlLoss',c.controlLoss,'controlReach',reach, ...
    'controlReachName',c.controlReach, ...
    'clockOffsetMaxSec',offsetMax, ...
    'clockDriftMaxPpm',driftMax, ...
    'churnEnabled',logical(c.churnEnabled), ...
    'churnTimeSec',R.reservation.churnTimeSec, ...
    'churnNode',R.reservation.churnNode);

end


function A=ringReach(N,hops)

A=false(N);
for receiver=1:N
    for delta=-hops:hops
        sender=mod(receiver-1+delta,N)+1;
        A(receiver,sender)=true;
    end
end

end
