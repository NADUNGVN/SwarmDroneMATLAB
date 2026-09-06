function [cfg,method,label]=applyExp14HCell(seedValue)
%APPLYEXP14HCELL Build one fixed N20 support-closure pilot.

[cfg,method,label]=applyExp14GCell('n20-ring2',seedValue);
R=exp14hRegistry();
cfg.shared.ackBranchReplay=struct( ...
    'enabled',true,'schema',R.eventSchema,'mode','observe', ...
    'targetOrdinal',0,'localHorizon',R.localHorizon);
cfg.exp14h.version=R.version;
cfg.exp14h.cell='n20-ring2';
cfg.exp14h.arm=R.pilotArm;

end
