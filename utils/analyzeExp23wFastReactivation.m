function analysis=analyzeExp23wFastReactivation(T,R)
%ANALYZEEXP23WFASTREACTIVATION Frozen primary and frontier analysis.

early=armRows(T,R.fastEarlyArm,R);
oldEarly=armRows(T,R.oldEarlyArm,R);
late=armRows(T,R.fastLateArm,R);
oldLate=armRows(T,R.oldLateArm,R);
static=armRows(T,R.staticArm,R);

P=table();
P=[P; testRow('H1','early RMSE repair',R.fastEarlyArm,R.oldEarlyArm, ...
    'RMSE',early.RMSE,oldEarly.RMSE,0,R,1)]; %#ok<AGROW>
P=[P; testRow('H2','late RMSE repair',R.fastLateArm,R.oldLateArm, ...
    'RMSE',late.RMSE,oldLate.RMSE,0,R,2)]; %#ok<AGROW>
P=[P; testRow('H3','early RMSE noninferiority',R.fastEarlyArm,R.staticArm, ...
    'RMSE',early.RMSE,(1+R.staticRmseNoninferiorityMargin)*static.RMSE, ...
    R.staticRmseNoninferiorityMargin,R,3)]; %#ok<AGROW>
P=[P; testRow('H4','early cost below static',R.fastEarlyArm,R.staticArm, ...
    'TOTAL_OFFERED_UTIL',early.TOTAL_OFFERED_UTIL, ...
    static.TOTAL_OFFERED_UTIL,0,R,4)]; %#ok<AGROW>
P=[P; testRow('H5','early cost-penalty ceiling',R.fastEarlyArm, ...
    R.oldEarlyArm,'TOTAL_OFFERED_UTIL',early.TOTAL_OFFERED_UTIL, ...
    (1+R.oldFenceCostPenaltyMargin)*oldEarly.TOTAL_OFFERED_UTIL, ...
    R.oldFenceCostPenaltyMargin,R,5)]; %#ok<AGROW>
P=[P; testRow('H6','late cost-penalty ceiling',R.fastLateArm, ...
    R.oldLateArm,'TOTAL_OFFERED_UTIL',late.TOTAL_OFFERED_UTIL, ...
    (1+R.oldFenceCostPenaltyMargin)*oldLate.TOTAL_OFFERED_UTIL, ...
    R.oldFenceCostPenaltyMargin,R,6)]; %#ok<AGROW>
if height(P)~=R.primaryFamilySize
    error('analyzeExp23w: primary family size changed.');
end
P.holmAdjustedP=holmAdjustP(P.oneSidedPRaw);
P.rejectAfterHolm=P.complete==1 & P.meanDelta<0 & ...
    P.holmAdjustedP<R.familywiseAlpha;

F=frontierAudit(T,R);
E=effectTable(T,R);
analysis=struct('primary',P,'frontier',F,'effects',E, ...
    'primaryPass',height(P)==R.primaryFamilySize && ...
    all(P.rejectAfterHolm==1), ...
    'frontierPass',all(F.referenceDominates==0));

end


function row=testRow(id,claim,arm,comparator,metric,a,b,margin,R,k)

boot=pairedBootstrapCI(a,b,R.bootstrapReplicates, ...
    R.bootstrapSeedBase+k,numel(R.seeds));
p=oneSidedP(a-b);
row=table(string(id),string(claim),string(arm),string(comparator), ...
    string(metric),margin,mean(a),mean(b),boot.meanD,boot.lo,boot.hi,p, ...
    NaN,false,boot.nPairs,double(boot.complete), ...
    'VariableNames',{'id','claim','arm','comparator','metric','margin', ...
    'candidateMean','testedReferenceMean','meanDelta','bootstrapLo', ...
    'bootstrapHi','oneSidedPRaw','holmAdjustedP','rejectAfterHolm', ...
    'nPairs','complete'});

end


function p=oneSidedP(d)

d=d(:); d=d(isfinite(d));
if numel(d)<2, p=NaN; return; end
mu=mean(d); sigma=std(d);
if sigma==0
    if mu<0, p=0; elseif mu==0, p=0.5; else, p=1; end
    return;
end
t=mu/(sigma/sqrt(numel(d)));
p=tcdf(t,numel(d)-1);

end


function F=frontierAudit(T,R)

candidate={R.fastEarlyArm,R.fastLateArm};
reference={R.staticArm,R.periodicArm};
rows=cell(4,8); q=0;
for a=1:numel(candidate)
    C=armRows(T,candidate{a},R);
    for b=1:numel(reference)
        Q=armRows(T,reference{b},R); q=q+1;
        dominates=mean(Q.RMSE)<=(1+R.epsilonRmse)*mean(C.RMSE) && ...
            mean(Q.TOTAL_OFFERED_UTIL)<= ...
            (1-R.requiredCostImprovement)*mean(C.TOTAL_OFFERED_UTIL);
        rows(q,:)={string(candidate{a}),string(reference{b}), ...
            mean(C.RMSE),mean(Q.RMSE),mean(C.TOTAL_OFFERED_UTIL), ...
            mean(Q.TOTAL_OFFERED_UTIL),double(dominates),numel(R.seeds)};
    end
end
F=cell2table(rows,'VariableNames',{'candidate','reference', ...
    'candidateMeanRMSE','referenceMeanRMSE','candidateMeanCost', ...
    'referenceMeanCost','referenceDominates','nPairs'});

end


function E=effectTable(T,R)

candidate={R.fastEarlyArm,R.fastLateArm,R.fastEarlyArm,R.fastLateArm};
reference={R.oldEarlyArm,R.oldLateArm,R.staticArm,R.staticArm};
rows=cell(4,15);
for k=1:4
    A=armRows(T,candidate{k},R); B=armRows(T,reference{k},R);
    rmse=pairedBootstrapCI(A.RMSE,B.RMSE,R.bootstrapReplicates, ...
        R.bootstrapSeedBase+20+2*k,numel(R.seeds));
    cost=pairedBootstrapCI(A.TOTAL_OFFERED_UTIL,B.TOTAL_OFFERED_UTIL, ...
        R.bootstrapReplicates,R.bootstrapSeedBase+21+2*k,numel(R.seeds));
    rows(k,:)={string(candidate{k}),string(reference{k}),numel(R.seeds), ...
        mean(A.RMSE),mean(B.RMSE),mean(A.RMSE)/mean(B.RMSE)-1, ...
        rmse.meanD,rmse.lo,rmse.hi,mean(A.TOTAL_OFFERED_UTIL), ...
        mean(B.TOTAL_OFFERED_UTIL), ...
        mean(A.TOTAL_OFFERED_UTIL)/mean(B.TOTAL_OFFERED_UTIL)-1, ...
        cost.meanD,cost.lo,cost.hi};
end
E=cell2table(rows,'VariableNames',{'candidate','reference','nPairs', ...
    'candidateMeanRMSE','referenceMeanRMSE','relativeRMSE','rmseDelta', ...
    'rmseCiLo','rmseCiHi','candidateMeanCost','referenceMeanCost', ...
    'relativeCost','costDelta','costCiLo','costCiHi'});

end


function A=armRows(T,arm,R)

A=sortrows(T(string(T.arm)==string(arm),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp23w: incomplete paired arm %s.',arm);
end

end
