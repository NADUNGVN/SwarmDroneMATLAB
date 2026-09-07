function A = tcnsO1OfflineAckCounts(actions,cfg,scenario)
%TCNSO1OFFLINEACKCOUNTS C1/C2 ACK counts from immutable O1 action logs.
%
% C1 charges every accepted DATA. C2 reproduces the causal simulator's two
% deliverDataWithAck calls per tick: one cumulative ACK per link in the
% pre-scheduling phase and one in the post-scheduling zero-delay phase.

required = {'time_s','arrivalTime_s','accepted','receiver','sender', ...
    'linkClass'};
for q = 1:numel(required)
    if ~ismember(required{q},actions.Properties.VariableNames)
        error('tcnsO1OfflineAckCounts:ActionSchema', ...
            'actions.%s is required.',required{q});
    end
end
h = cfg.swarm.dt;
deliveryTick = ceil((actions.arrivalTime_s-1e-12)/h);
deliveryTime = deliveryTick*h;
acceptedEvaluation = logical(actions.accepted) & ...
    deliveryTime>=scenario.evaluationStart_s-1e-12 & ...
    deliveryTime<scenario.horizon_s-1e-12;

% A packet generated at the delivery tick can only be consumed by the
% post-scheduling delivery call. Every other due accepted packet is consumed
% by the pre-scheduling call.
deliveryPhase = repmat("pre-scheduling",height(actions),1);
post = acceptedEvaluation & ...
    abs(actions.time_s-deliveryTime)<=1e-10 & ...
    actions.arrivalTime_s<=actions.time_s+1e-12;
deliveryPhase(post) = "post-scheduling";

A.c1Count = nnz(acceptedEvaluation);
if A.c1Count==0
    A.c2Count = 0;
else
    tuples = table(deliveryTick(acceptedEvaluation), ...
        deliveryPhase(acceptedEvaluation), ...
        actions.receiver(acceptedEvaluation), ...
        actions.sender(acceptedEvaluation), ...
        string(actions.linkClass(acceptedEvaluation)), ...
        'VariableNames',{'deliveryTick','deliveryPhase','receiver', ...
        'sender','linkClass'});
    A.c2Count = height(unique(tuples,'rows'));
end
A.deliveryTick = deliveryTick;
A.deliveryTime_s = deliveryTime;
A.deliveryPhase = deliveryPhase;
A.acceptedEvaluation = acceptedEvaluation;
A.twoPhaseSemantics = true;
A.c2AtMostC1 = A.c2Count<=A.c1Count;

end
