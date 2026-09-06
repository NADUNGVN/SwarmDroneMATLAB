function [cfg,method,label,details,certificate]=applyExp18A2Arm(cfg)
%APPLYEXP18A2ARM Apply the service-certificate context candidate.

E=exp18Registry();
arm=E.arms(strcmp({E.arms.id},'context-aware'));
[cfg,method,~,details]=applyExp18Arm(cfg,arm);
R=exp18a2Registry();
label=R.arm.label;
details.route='context-aware-v2';
details.ackDesign=R.arm.ackDesign;
cfg.exp18.arm=R.arm.id;
cfg.exp18.ackDesign=R.arm.ackDesign;
cfg.exp18.route=details.route;
cfg.exp18a2.version=R.version;
cfg.exp18a2.serviceCertificate=true;
certificate=contextAwareServiceCertificate(cfg);
if ~cfg.shared.contextAware.serviceCertificateEnabled
    error('applyExp18A2Arm: service certificate must be enabled.');
end

end
