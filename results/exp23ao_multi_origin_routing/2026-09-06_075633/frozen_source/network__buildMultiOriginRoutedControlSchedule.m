function S=buildMultiOriginRoutedControlSchedule( ...
    routePlans,repetitionsPerPacket,packetId)
%BUILDMULTIORIGINROUTEDCONTROLSCHEDULE Precedence-safe route compaction.
%
% Each (packet, tree transmitter) pair is a non-preemptive repetition block.
% A feasible serial composition of the validated single-packet schedules is
% constructed first. Tasks are then left-shifted in deterministic serial
% order without moving any task later than its incumbent position. This
% preserves a feasible upper bound while enabling cross-packet spatial reuse.

if ~iscell(routePlans)||isempty(routePlans)||~isvector(routePlans)
    error('buildMultiOriginRoutedControlSchedule: routePlans must be a cell vector.');
end
K=numel(routePlans); repetitions=reshape(double(repetitionsPerPacket),[],1);
ids=reshape(string(packetId),[],1);
if numel(repetitions)~=K||numel(ids)~=K||numel(unique(ids))~=K|| ...
        any(strlength(ids)==0)||any(~isfinite(repetitions))|| ...
        any(repetitions<1)||any(repetitions~=floor(repetitions))
    error('buildMultiOriginRoutedControlSchedule: invalid packet metadata.');
end
required={'N','admissible','source','directReach','physicalInterference', ...
    'children','parent','depth','transmitterMask','transmitterSlot', ...
    'plannedTransmitterCount','reservedSlotCount','recipientMask','hashExact'};
for k=1:K
    P=routePlans{k};
    if ~isstruct(P)||~isscalar(P)||~all(isfield(P,required))||~P.admissible
        error('buildMultiOriginRoutedControlSchedule: invalid route plan.');
    end
end
N=routePlans{1}.N; direct=logical(routePlans{1}.directReach);
physical=logical(routePlans{1}.physicalInterference);
for k=1:K
    P=routePlans{k};
    if P.N~=N||~isequal(logical(P.directReach),direct)|| ...
            ~isequal(logical(P.physicalInterference),physical)
        error('buildMultiOriginRoutedControlSchedule: routes must share one PHY.');
    end
end

taskCount=sum(cellfun(@(P) P.plannedTransmitterCount,routePlans));
taskPacket=zeros(taskCount,1); taskSender=zeros(taskCount,1);
taskChildren=false(N,taskCount); taskRepetitions=zeros(taskCount,1);
taskOriginalStart=zeros(taskCount,1); taskParent=zeros(taskCount,1);
taskIndex=zeros(K,N); q=0; serialOffset=0;
for k=1:K
    P=routePlans{k}; senders=find(P.transmitterMask);
    [~,order]=sortrows([P.transmitterSlot(senders) senders],[1 2]);
    senders=senders(order);
    for sender=reshape(senders,1,[])
        q=q+1; taskPacket(q)=k; taskSender(q)=sender;
        taskChildren(:,q)=P.children(:,sender);
        taskRepetitions(q)=repetitions(k);
        taskOriginalStart(q)=serialOffset+ ...
            (P.transmitterSlot(sender)-1)*repetitions(k)+1;
        taskIndex(k,sender)=q;
    end
    serialOffset=serialOffset+P.reservedSlotCount*repetitions(k);
end
if q~=taskCount, error('buildMultiOriginRoutedControlSchedule: task count.'); end
for task=1:taskCount
    k=taskPacket(task); sender=taskSender(task); P=routePlans{k};
    if sender~=P.source
        taskParent(task)=taskIndex(k,P.parent(sender));
        if taskParent(task)==0
            error('buildMultiOriginRoutedControlSchedule: missing parent task.');
        end
    end
end

conflict=false(taskCount);
detectable=physical|direct;
for a=1:taskCount
    senderA=taskSender(a); receiversA=taskChildren(:,a);
    for b=a+1:taskCount
        senderB=taskSender(b); receiversB=taskChildren(:,b);
        edge=senderA==senderB||receiversA(senderB)||receiversB(senderA)|| ...
            any(detectable(receiversA,senderB))|| ...
            any(detectable(receiversB,senderA));
        conflict(a,b)=edge; conflict(b,a)=edge;
    end
end

startSlot=nan(taskCount,1); endSlot=nan(taskCount,1);
[~,scheduleOrder]=sortrows([(1:taskCount)' taskOriginalStart ...
    taskPacket taskSender],[2 3 4]);
for task=reshape(scheduleOrder,1,[])
    earliest=1; parentTask=taskParent(task);
    if parentTask>0
        if isnan(endSlot(parentTask))
            error('buildMultiOriginRoutedControlSchedule: parent order.');
        end
        earliest=endSlot(parentTask)+1;
    end
    placed=false;
    for candidate=earliest:taskOriginalStart(task)
        candidateEnd=candidate+taskRepetitions(task)-1;
        prior=find(~isnan(startSlot));
        overlap=startSlot(prior)<=candidateEnd&endSlot(prior)>=candidate;
        if ~any(conflict(task,prior(overlap)))
            startSlot(task)=candidate; endSlot(task)=candidateEnd;
            placed=true; break;
        end
    end
    if ~placed
        error('buildMultiOriginRoutedControlSchedule: serial incumbent lost.');
    end
end

slotCount=max(endSlot); slotTask=false(slotCount,taskCount);
for task=1:taskCount
    slotTask(startSlot(task):endSlot(task),task)=true;
end
conflictFree=true;
for slot=1:slotCount
    active=find(slotTask(slot,:));
    conflictFree=conflictFree&& ...
        ~any(triu(conflict(active,active),1),'all');
end
precedenceExact=true;
for task=find(taskParent>0)'
    precedenceExact=precedenceExact&& ...
        startSlot(task)>endSlot(taskParent(task));
end
[idHash,~]=configHash(cellstr(ids));
planHash=reshape(cellfun(@(P) P.hashExact,routePlans),[],1);
S=struct('version','MULTI-ORIGIN-ROUTED-CONTROL-SCHEDULE-v1', ...
    'N',N,'packetCount',K,'packetId',ids, ...
    'packetIdHash',idHash,'routePlans',{reshape(routePlans,[],1)}, ...
    'routePlanHash',planHash,'repetitionsPerPacket',repetitions, ...
    'directReach',direct,'physicalInterference',physical, ...
    'taskCount',taskCount,'taskPacket',taskPacket, ...
    'taskSender',taskSender,'taskChildren',taskChildren, ...
    'taskRepetitions',taskRepetitions,'taskParent',taskParent, ...
    'taskConflictGraph',conflict,'taskOriginalStartSlot', ...
    taskOriginalStart,'taskStartSlot',startSlot,'taskEndSlot',endSlot, ...
    'slotTaskMask',slotTask,'serialSlotCount',serialOffset, ...
    'reservedSlotCount',slotCount,'compactionSlotSavings', ...
    serialOffset-slotCount,'maximumConcurrentTasks',max(sum(slotTask,2)), ...
    'conflictFree',double(conflictFree), ...
    'precedenceExact',double(precedenceExact), ...
    'admissible',double(conflictFree&&precedenceExact&& ...
    slotCount<=serialOffset), ...
    'hashExact',realizationHash([idHash;planHash;repetitions;taskPacket; ...
    taskSender;double(taskChildren(:));taskRepetitions;taskParent; ...
    double(conflict(:));taskOriginalStart;startSlot;endSlot; ...
    double(slotTask(:));serialOffset;slotCount]));

end
