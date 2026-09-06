function C=buildExp21dBoundaryKernelConfig(cfg,R,condition)
%BUILDEXP21DBOUNDARYKERNELCONFIG Apply one declared D-STR boundary.

C=buildExp21dClosedLoopKernelConfig(cfg,R);
C.dataErasureProbability=0;
C.managementErasureProbability=0;
C.churnEnabled=false;
C.churnFrame=R.churnFrame;
C.churnNode=min(R.churnNode,C.N);
condition=lower(strtrim(char(condition)));
switch condition
    case 'zero'
    case 'beacon-loss'
        C.dataErasureProbability=R.beaconErasureProbability;
    case 'restricted-management'
        C.managementReach=C.neighborGraph;
    case 'churn-rejoin'
        C.churnEnabled=true;
    otherwise
        error(['buildExp21dBoundaryKernelConfig: unknown condition ' ...
            '"%s".'],condition);
end

end
