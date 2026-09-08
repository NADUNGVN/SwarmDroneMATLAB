function catalog = tcnsInformationLimitsActionCatalog(model,commandCorrection)
%TCNSINFORMATIONLIMITSACTIONCATALOG Enumerate controller-relevant actions.
%
% Each row is backed by tcnsInformationLimitsActionMap.  The default
% correction [1 0 0] and zero payload define the structural functional used
% by the information-identifiability audit; they are not claimed to be a
% trajectory-realized scheduling action.

if nargin<2 || isempty(commandCorrection)
    commandCorrection = [1 0 0];
end
commandCorrection = double(commandCorrection(:)');
if numel(commandCorrection)~=3 || any(~isfinite(commandCorrection))
    error('tcnsInformationLimitsActionCatalog:Correction', ...
        'commandCorrection must be a finite three-vector.');
end

count = model.nOrdinaryLinks+model.nPinnedLinks;
actionId = strings(count,1);
linkClass = strings(count,1);
sender = zeros(count,1);
receiver = zeros(count,1);
targetDimension = zeros(count,1);
maps = cell(count,1);
payload = struct('pos',[0 0 0],'vel',[0 0 0],'acc',[0 0 0]);

row = 0;
for a = 1:model.nOrdinaryLinks
    row = row+1;
    linkClass(row) = "ordinary";
    sender(row) = model.edgeSender(a);
    receiver(row) = model.edgeReceiver(a);
    actionId(row) = sprintf('ordinary_%d_to_%d',sender(row),receiver(row));
    maps{row} = tcnsInformationLimitsActionMap(model,"ordinary", ...
        receiver(row),sender(row),commandCorrection,payload);
    targetDimension(row) = numel(maps{row}.targetIndex);
end
for a = 1:model.nPinnedLinks
    row = row+1;
    linkClass(row) = "pinned-leader";
    sender(row) = 1;
    receiver(row) = model.pinReceiver(a);
    actionId(row) = sprintf('pinned_leader_1_to_%d',receiver(row));
    maps{row} = tcnsInformationLimitsActionMap(model,"pinned-leader", ...
        receiver(row),1,commandCorrection,payload);
    targetDimension(row) = numel(maps{row}.targetIndex);
end

catalog = table(actionId,linkClass,sender,receiver,targetDimension,maps, ...
    'VariableNames',{'actionId','linkClass','sender','receiver', ...
    'targetDimension','actionMap'});

end
