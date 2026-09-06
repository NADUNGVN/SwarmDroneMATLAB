function R=exp14dRegistry()
%EXP14DREGISTRY Fixed complete-factorial development matrix.

R.version='EXP14D-FACTORIAL-DEVELOPMENT-v1';
R.seeds=(16017001:16017012)';
R.cells=struct( ...
    'id',{'n5-csma','n5-aloha','n10-ring2','n20-ring2'}, ...
    'label',{'N5 CSMA','N5 ALOHA','N10 ring2','N20 ring2'});

% Registry order is also the final deterministic tie-break order.
[A,G,S]=ndgrid(0:1,0:1,0:1);
A=A(:); G=G(:); S=S(:);
R.arms=repmat(struct('id','','label','','adaptiveAck',false, ...
    'loadGuard',false,'accessScaling',false),numel(A),1);
for k=1:numel(A)
    R.arms(k).id=sprintf('a%d-g%d-s%d',A(k),G(k),S(k));
    R.arms(k).label=sprintf('A%d G%d S%d',A(k),G(k),S(k));
    R.arms(k).adaptiveAck=logical(A(k));
    R.arms(k).loadGuard=logical(G(k));
    R.arms(k).accessScaling=logical(S(k));
end
R.expectedRuns=numel(R.seeds)*numel(R.cells)*numel(R.arms);
R.confirmatoryClaimPermitted=false;
R.n20OfferedUtilCeiling=1.2;
R.regretTieMargin=0.01;
factorTable=[[R.arms.adaptiveAck]' [R.arms.loadGuard]' ...
    [R.arms.accessScaling]'];
payload=[R.seeds; double(char(strjoin({R.cells.id},'|')))'; ...
    double(char(strjoin({R.arms.id},'|')))'; factorTable(:); ...
    R.expectedRuns; R.n20OfferedUtilCeiling; R.regretTieMargin];
R.contractHash=realizationHash(payload);
R.expectedContractHash=8052507;
if R.contractHash~=R.expectedContractHash
    error('exp14dRegistry: frozen contract hash changed.');
end

end
