function [row,out]=runExp21dBoundaryCell( ...
    cfg,method,label,meta,trace,details,Q,arm)
%RUNEXP21DBOUNDARYCELL Execute and flatten one boundary trajectory.

[base,out]=runExp21dClosedLoopCell( ...
    cfg,method,label,meta,trace,details);
row=exp21dBoundaryEmptyRow();
names=fieldnames(base);
for k=1:numel(names), row.(names{k})=base.(names{k}); end
K=Q.kernel;
row.BOUNDARY_CONDITION=char(arm.condition);
row.PHYSICAL_REPLAY_VALID=double(Q.prefixFrameAgreement);
row.KERNEL_PREFIX_MAX_FRAME_DISAGREEMENT= ...
    Q.maxPrefixFrameDisagreement;
row.WARM_REFERENCE=double(arm.warm);
row.KERNEL_CHURN_APPLIED=double(K.churnApplied);
row.KERNEL_DATA_ATTEMPTS=K.dataAttempts;
row.KERNEL_DATA_RECIPIENT_ATTEMPTS=K.dataRecipientAttempts;
row.KERNEL_DATA_RECIPIENT_SUCCESS=K.dataRecipientSuccess;
row.KERNEL_DATA_RECIPIENT_ERASURE=K.dataRecipientErasure;
row.KERNEL_DATA_RECIPIENT_COLLISION=K.dataRecipientCollision;
row.KERNEL_MANAGEMENT_ATTEMPTS=K.managementAttempts;
row.KERNEL_MANAGEMENT_RECIPIENT_ATTEMPTS= ...
    K.managementRecipientAttempts;
row.KERNEL_MANAGEMENT_RECIPIENT_SUCCESS= ...
    K.managementRecipientSuccess;
row.KERNEL_MANAGEMENT_RECIPIENT_ERASURE= ...
    K.managementRecipientErasure;
row.KERNEL_MANAGEMENT_RECIPIENT_COLLISION= ...
    K.managementRecipientCollision;

end
