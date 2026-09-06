function cfg=applyExp17Cell(cellId,seedValue)
%APPLYEXP17CELL Build one frozen operating-envelope context.

if ~isscalar(seedValue) || ~isfinite(seedValue) || ...
        seedValue<0 || seedValue~=floor(seedValue)
    error('applyExp17Cell: seedValue must be a nonnegative integer.');
end
R=exp17Registry();
cellId=lower(strtrim(char(cellId)));
idx=find(strcmp({R.cells.id},cellId),1);
if isempty(idx)
    error('applyExp17Cell: unknown cell "%s".',cellId);
end
c=R.cells(idx);
cfg=study2Exp14Config(seedValue,c.channel);
if c.N==10
    cfg=applyTopologyConfig(cfg,10,'ring2');
    cfg.sixdof.enable=false;
    cfg.mac.interferenceMatrix=true(10);
    cfg.mac.carrierSenseMatrix=true(10);
elseif c.N~=5
    error('applyExp17Cell: registry N must be 5 or 10.');
end
cfg.mac.backgroundLoad=c.background;

switch c.modifier
    case 'nominal'
    case 'reverse-asymmetric'
        cfg.mac.burst.ackGoodLoss=0.15;
        cfg.mac.burst.ackBadLoss=0.95;
        cfg.mac.burst.ackGoodToBad=0.008;
        cfg.mac.burst.ackBadToGood=0.022;
    case 'hidden-terminal'
        cfg.mac.carrierSenseMatrix=ringCarrierSense(cfg.swarm.N);
    otherwise
        error('applyExp17Cell: unknown modifier "%s".',c.modifier);
end

cfg.mac.type='csma';
cfg.mac.pAccess=min(cfg.mac.pAccess,1/cfg.swarm.N);
cfg.exp17.version=R.version;
cfg.exp17.cell=c.id;
cfg.exp17.role=c.role;
cfg.exp17.channel=c.channel;
cfg.exp17.modifier=c.modifier;
cfg.mac=sharedMediumConfig(cfg);

end


function C=ringCarrierSense(N)

C=eye(N)>0;
for node=1:N
    C(node,mod(node-2,N)+1)=true;
    C(node,mod(node,N)+1)=true;
end

end

