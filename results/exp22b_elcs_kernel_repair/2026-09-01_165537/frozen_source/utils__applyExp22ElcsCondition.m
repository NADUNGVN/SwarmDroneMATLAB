function [C,T,meta]=applyExp22ElcsCondition(base,condition,baseTrace,R)
%APPLYEXP22ELCSCONDITION Map one frozen ELCS-F kernel condition.

if nargin<4 || isempty(R), R=exp22ElcsKernelRegistry(); end
id=char(condition.id);
if ~any(strcmp({R.conditions.id},id))
    error('applyExp22ElcsCondition: condition is not registered.');
end
N=base.swarm.N;
neighbor=logical(base.swarm.A);
interference=logical(base.mac.interferenceMatrix);
C=elcsKernelConfig(N,R.maxFrames);
C.neighborGraph=neighbor;
C.interferenceMatrix=interference;
C.conflictGraph=buildSenderConflictGraph(neighbor,interference);
C.managementReach=true(N)-eye(N)>0;
C.stateLossFrame=R.stateLossFrame;
C.stateLossNode=min(R.stateLossNode,N);
C.reconfigurationFrame=R.reconfigurationFrame;
C.reconfigurationNode=min(R.reconfigurationNode,N);
C.reconfigurationSlot=N;
T=baseTrace;
blackoutOwner=NaN;
blackoutClient=NaN;

switch id
    case R.zeroCondition
    case R.dataLossCondition
        C.dataErasureProbability=R.dataErasureProbability;
    case R.managementLossCondition
        C.managementErasureProbability=R.managementErasureProbability;
    case R.localCondition
        C.managementReach=neighbor;
    case R.blackoutCondition
        edge=find(triu(C.conflictGraph,1),1,'first');
        [blackoutOwner,blackoutClient]=ind2sub([N N],edge);
        if blackoutOwner>blackoutClient
            [blackoutOwner,blackoutClient]=deal( ...
                blackoutClient,blackoutOwner);
        end
        C.managementErasureProbability=R.blackoutDrawThreshold;
        T.statusDeliveryU(:)=1;
        T.grantDeliveryU(:)=1;
        T.grantDeliveryU(:,blackoutClient,blackoutOwner)=0;
        T.hashExact=traceHash(T);
    case R.stateLossCondition
        C.stateLossEnabled=true;
    case R.reconfigurationCondition
        C.reconfigurationEnabled=true;
    otherwise
        error('applyExp22ElcsCondition: unsupported condition %s.',id);
end
meta=struct('condition',id,'kind',char(condition.kind), ...
    'baseTraceHashExact',baseTrace.hashExact, ...
    'conditionTraceHashExact',T.hashExact, ...
    'blackoutOwner',blackoutOwner,'blackoutClient',blackoutClient);

end


function value=traceHash(T)

value=realizationHash([T.statusSlotU(:);T.grantSlotU(:); ...
    T.statusDeliveryU(:);T.grantDeliveryU(:); ...
    T.scheduledDeliveryU(:);T.fallbackAccessU(:); ...
    T.fallbackDeliveryU(:)]);

end
