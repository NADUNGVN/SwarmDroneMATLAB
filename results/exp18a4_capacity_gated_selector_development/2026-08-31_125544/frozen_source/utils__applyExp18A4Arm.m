function [cfg,method,label,details,certificate]=applyExp18A4Arm(cfg)
%APPLYEXP18A4ARM Apply capacity abstention followed by a fixed route map.

[cfg,method,~,details,certificate]=applyExp18A2Arm(cfg);
R=exp18a4Registry();
cfg.shared.contextAware.routeRule='capacity-gated-mac';
cfg.shared.contextAware.freshnessHeadroomEnabled=false;
cfg.shared.contextAware=contextAwarePolicyConfig(cfg);
label=R.arm.label;
details.route='capacity-gated-selector';
details.ackDesign=R.arm.ackDesign;
cfg.exp18.arm=R.arm.id;
cfg.exp18.ackDesign=R.arm.ackDesign;
cfg.exp18.route=details.route;
cfg.exp18a4.version=R.version;
cfg.exp18a4.routeRule=cfg.shared.contextAware.routeRule;
certificate=contextAwareServiceCertificate(cfg);

end
