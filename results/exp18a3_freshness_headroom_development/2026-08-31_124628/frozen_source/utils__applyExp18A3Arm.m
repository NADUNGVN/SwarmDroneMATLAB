function [cfg,method,label,details,certificate]=applyExp18A3Arm(cfg)
%APPLYEXP18A3ARM Apply service certificate plus freshness-headroom value.

[cfg,method,~,details,certificate]=applyExp18A2Arm(cfg);
R=exp18a3Registry();
cfg.shared.contextAware.freshnessHeadroomEnabled=true;
cfg.shared.contextAware=contextAwarePolicyConfig(cfg);
label=R.arm.label;
details.route='context-aware-v3';
details.ackDesign=R.arm.ackDesign;
cfg.exp18.arm=R.arm.id;
cfg.exp18.ackDesign=R.arm.ackDesign;
cfg.exp18.route=details.route;
cfg.exp18a3.version=R.version;
cfg.exp18a3.freshnessHeadroom=true;
certificate=contextAwareServiceCertificate(cfg);

end
