function [cfg,method,label]=applyExp14GCell(cellId,seedValue)
%APPLYEXP14GCELL Build the fixed selected-policy EXP14G pilot cell.

R=exp14gRegistry();
cfg=applyExp14FCell(cellId,seedValue);
F=exp14fRegistry();
arm=F.arms(strcmp({F.arms.id},R.pilotArm));
[cfg,method,label]=applyExp14FArm(cfg,arm);
cfg.shared.ackBranchReplay=struct( ...
    'enabled',true,'schema',R.eventSchema,'mode','observe', ...
    'targetOrdinal',0,'localHorizon',R.localHorizon);
cfg.exp14g.version=R.version;
cfg.exp14g.cell=lower(strtrim(char(cellId)));
cfg.exp14g.arm=R.pilotArm;
cfg.mac=sharedMediumConfig(cfg);

end
