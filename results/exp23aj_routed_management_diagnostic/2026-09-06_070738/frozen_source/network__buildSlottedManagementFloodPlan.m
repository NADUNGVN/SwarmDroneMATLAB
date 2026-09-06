function P=buildSlottedManagementFloodPlan( ...
    directReach,physicalInterference,source,recipients,maxHops)
%BUILDSLOTTEDMANAGEMENTFLOODPLAN Deterministic causal multicast tree.
%
% directReach(receiver,sender) is a directed one-hop decode edge. Shortest
% paths use lexicographic BFS parents. The union of recipient paths forms a
% one-parent tree, so a node can forward at most once. Forwarders at the same
% depth are colored on the receiver-level sender-conflict graph; depths are
% serialized to preserve receive-before-forward causality.

N=size(directReach,1); reach=logical(directReach);
interference=logical(physicalInterference);
if ~isequal(size(reach),[N N])||~isequal(size(interference),[N N])|| ...
        any(diag(reach))||any(diag(interference))|| ...
        ~isequal(interference,interference')||N<2
    error('buildSlottedManagementFloodPlan: invalid graphs.');
end
if ~isscalar(source)||~isfinite(source)||source<1||source>N|| ...
        source~=floor(source)
    error('buildSlottedManagementFloodPlan: invalid source.');
end
if nargin<5||isempty(maxHops), maxHops=N-1; end
if ~isscalar(maxHops)||~isfinite(maxHops)||maxHops<0|| ...
        maxHops~=floor(maxHops)
    error('buildSlottedManagementFloodPlan: invalid hop limit.');
end
recipientMask=false(N,1);
if islogical(recipients)&&numel(recipients)==N
    recipientMask=reshape(recipients,[],1);
elseif isnumeric(recipients)&&isvector(recipients)&& ...
        all(isfinite(recipients))&&all(recipients>=1&recipients<=N)&& ...
        all(recipients==floor(recipients))
    recipientMask(unique(recipients))=true;
else
    error('buildSlottedManagementFloodPlan: invalid recipients.');
end
recipientMask(source)=false;

depth=inf(N,1); parent=zeros(N,1); depth(source)=0;
frontier=source;
while ~isempty(frontier)
    next=zeros(0,1);
    for sender=reshape(sort(frontier),1,[])
        if depth(sender)>=maxHops, continue; end
        candidates=find(reach(:,sender)&isinf(depth));
        for receiver=reshape(sort(candidates),1,[])
            depth(receiver)=depth(sender)+1;
            parent(receiver)=sender;
            next(end+1,1)=receiver; %#ok<AGROW>
        end
    end
    frontier=unique(next,'sorted');
end
unreachable=recipientMask&isinf(depth);
admissible=~any(unreachable);

active=false(N,1); active(source)=any(recipientMask);
for receiver=reshape(find(recipientMask&~unreachable),1,[])
    node=receiver; active(node)=true;
    while node~=source
        node=parent(node);
        if node==0, error('buildSlottedManagementFloodPlan: parent gap.'); end
        active(node)=true;
    end
end
children=false(N); % children(receiver,parent)
for node=reshape(find(active&parent>0),1,[])
    children(node,parent(node))=true;
end
transmitterMask=any(children,1)';
senderConflict=buildSenderConflictGraph(children,interference);
slot=zeros(N,1); slotOffset=0;
maxDepth=max([0;depth(transmitterMask&isfinite(depth))]);
for d=0:maxDepth
    transmitters=find(transmitterMask&depth==d);
    if isempty(transmitters), continue; end
    localConflict=senderConflict(transmitters,transmitters);
    localSlot=elcsWitnessPriorityColor(localConflict);
    slot(transmitters)=slotOffset+localSlot;
    slotOffset=slotOffset+max(localSlot);
end

proper=true;
for s=1:slotOffset
    tx=find(slot==s);
    if numel(tx)>1
        proper=proper&&~any(triu(senderConflict(tx,tx),1),'all');
    end
end
treeEdgeCount=nnz(children);
P=struct('version','SLOTTED-MANAGEMENT-FLOOD-PLAN-v1', ...
    'N',N,'source',source,'directReach',reach, ...
    'physicalInterference',interference,'recipientMask',recipientMask, ...
    'maxHops',maxHops,'depth',depth,'parent',parent, ...
    'activeNodeMask',active,'children',children, ...
    'transmitterMask',transmitterMask,'transmitterSlot',slot, ...
    'senderConflictGraph',senderConflict, ...
    'treeEdgeCount',treeEdgeCount, ...
    'plannedTransmitterCount',nnz(transmitterMask), ...
    'reservedSlotCount',slotOffset,'maximumRecipientDepth', ...
    max([0;depth(recipientMask&~unreachable)]), ...
    'unreachableRecipientMask',unreachable, ...
    'unreachableRecipientCount',nnz(unreachable), ...
    'slotColoringProper',double(proper), ...
    'admissible',double(admissible&&proper), ...
    'hashExact',realizationHash([double(reach(:)); ...
    double(interference(:));source;double(recipientMask);maxHops; ...
    replaceInf(depth,N+1);parent;double(active);double(children(:)); ...
    slot;double(senderConflict(:));double(admissible);double(proper)]));

end


function value=replaceInf(value,replacement)
value(isinf(value))=replacement;
end
