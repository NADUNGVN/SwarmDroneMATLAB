function [net,candidates]=selectScheduledService( ...
    net,slot,tk,hasFrame,backgroundActive)
%SELECTSCHEDULEDSERVICE Collision-free round-robin or oracle DATA service.
%
% Oracle weights use only state already present at tk.  This function has no
% trace argument, so future access/loss uniforms cannot enter the decision.

N=net.N;
candidates=false(N,1);
S=net.serviceScheduler;
if ~S.config.enabled || backgroundActive || ~isempty(net.active)
    return;
end
eligible=find(hasFrame(:));
if isempty(eligible)
    return;
end

fifoNode=fifoChoice(net,eligible);
weights=nan(size(eligible));
selected=0;
switch S.config.mode
    case 'round-robin'
        owner=S.roundRobinCursor;
        S.roundRobinCursor=mod(owner,N)+1;
        if hasFrame(owner), selected=owner; end
    case 'deficit-maxweight'
        weights=S.virtualDeficit(eligible);
        selected=weightedChoice(net,eligible,weights);
    case 'urgency-maxweight'
        weights=urgencyWeights(net,eligible,tk,S.config);
        selected=weightedChoice(net,eligible,weights);
        S.receiverTruthReadCount=S.receiverTruthReadCount+numel(eligible);
    otherwise
        error('selectScheduledService: unsupported scheduled mode.');
end

if selected==0
    net.serviceScheduler=S;
    return;
end
candidates(selected)=true;
S.decisionCount=S.decisionCount+1;
if S.config.oracle && numel(eligible)>=2
    S.fifoComparableDecisionCount=S.fifoComparableDecisionCount+1;
    if selected~=fifoNode
        S.priorityDiffersFifoCount=S.priorityDiffersFifoCount+1;
    end
end
if S.config.logDecisions
    f=net.queues{selected}(1);
    d=struct('ordinal',S.decisionCount,'time',tk,'slot',slot, ...
        'mode',S.config.mode,'eligibleNodes',reshape(eligible,1,[]), ...
        'weights',reshape(weights,1,[]),'selectedNode',selected, ...
        'fifoNode',fifoNode,'differsFromFifo',selected~=fifoNode, ...
        'selectedFrameId',f.id,'selectedFrameGenTime',f.genTime, ...
        'futureRandomRead',false);
    net.logs.serviceDecisions(end+1,1)=d;
end
net.serviceScheduler=S;

end


function node=fifoChoice(net,eligible)

times=zeros(numel(eligible),1);
for k=1:numel(eligible)
    times(k)=net.queues{eligible(k)}(1).enqueueTime;
end
[~,order]=sortrows([times(:) eligible(:)],[1 2]);
node=eligible(order(1));

end


function node=weightedChoice(net,eligible,weights)

best=max(weights);
ties=eligible(abs(weights-best)<=1e-12);
node=fifoChoice(net,ties);

end


function weights=urgencyWeights(net,eligible,tk,C)

weights=zeros(numel(eligible),1);
for k=1:numel(eligible)
    sender=eligible(k);
    frame=net.queues{sender}(1);
    receivers=find(frame.dataReceiverMask);
    posInnovation=0;
    velInnovation=0;
    trueAge=0;
    if ~isempty(receivers)
        cachedPos=reshape(net.Pij(receivers,sender,:),numel(receivers),3);
        cachedVel=reshape(net.Vij(receivers,sender,:),numel(receivers),3);
        posInnovation=max(vecnorm(cachedPos-frame.pos,2,2));
        velInnovation=max(vecnorm(cachedVel-frame.vel,2,2));
        trueAge=max(tk-net.acceptedGenTime(receivers,sender));
    end
    queueAge=max(tk-frame.enqueueTime,0);
    silence=max(tk-net.serviceScheduler.lastServiceTime(sender),0);
    components=[posInnovation/C.posThreshold; ...
        velInnovation/C.velThreshold; trueAge/C.aoiThreshold; ...
        queueAge/C.aoiThreshold; silence/C.maxSilence];
    weights(k)=max(components);
end

end
