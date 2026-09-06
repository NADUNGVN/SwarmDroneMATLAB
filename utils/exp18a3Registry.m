function R=exp18a3Registry()
%EXP18A3REGISTRY Development-only freshness-headroom amendment.

A2=exp18a2Registry();
R=A2;
R.version='EXP18A3-FRESHNESS-HEADROOM-DEVELOPMENT-v1';
R.stage='development-amendment-3';
R.arm=struct('id','context-aware-v3', ...
    'label','Context-aware service and freshness headroom', ...
    'accessDesign','frame-aware', ...
    'ackDesign','service-certificate-freshness-value');
R.maxJointlyWorseFeasibleCells=1;
R.requireExactCsmaPiggybackAlias=true;
R.requireFeasibleAlohaAckActivity=true;

end
