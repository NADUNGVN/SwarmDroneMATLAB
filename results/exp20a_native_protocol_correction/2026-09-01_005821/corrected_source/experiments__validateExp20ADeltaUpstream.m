function V=validateExp20ADeltaUpstream(referenceDir,outputDir)
%VALIDATEEXP20ADELTAUPSTREAM Descriptive clean-room/upstream aggregate check.
%
% The GPLv3 reference implementation remains outside this repository. This
% function invokes it from REFERENCE_DIR and stores only numerical outputs and
% provenance. The comparison is diagnostic, not an EXP20A decision gate.

arguments
    referenceDir (1,:) char
    outputDir (1,:) char
end

R=exp20aRegistry();
expectedCommit=R.upstreamDeltaCommit;
[status,commit]=system(sprintf('git -C "%s" rev-parse HEAD',referenceDir));
commit=strtrim(commit);
if status~=0 || ~strcmp(commit,expectedCommit)
    error('validateExp20ADeltaUpstream: expected commit %s, found %s.', ...
        expectedCommit,commit);
end
if exist(fullfile(referenceDir,'montecarlo.m'),'file')~=2
    error('validateExp20ADeltaUpstream: montecarlo.m is missing.');
end
if ~isfolder(outputDir), mkdir(outputDir); end

cells=R.nativeCells([R.nativeCells.rho]==0.50);
seeds=(16027801:16027805)';
n=numel(cells)*numel(seeds);
cellId=strings(n,1); seed=zeros(n,1); N=zeros(n,1);
rho=zeros(n,1); epsilon=zeros(n,1);
upstreamMeanAoII=zeros(n,1); cleanRoomMeanAoII=zeros(n,1);
q=0;

addpath(referenceDir,'-begin');
pathCleanup=onCleanup(@() rmpath(referenceDir));
for cellIndex=1:numel(cells)
    c=cells(cellIndex);
    cfg=struct('N',c.N,'rho',c.rho,'epsilon',c.epsilon, ...
        'slots',R.nativeSlots,'burnIn',R.nativeBurnIn, ...
        'feedbackLoss',R.privateFeedbackLoss, ...
        'feedbackDelaySlots',R.privateFeedbackDelaySlots);
    for seedIndex=1:numel(seeds)
        q=q+1;
        rng(seeds(seedIndex),'twister');
        [~,theta]=montecarlo(R.nativeSlots+R.nativeBurnIn,c.N, ...
            ones(1,c.N)*(c.rho/c.N),c.epsilon,'delta', ...
            2.5*c.N,0.17,0.13);
        upstream=mean(theta(:,R.nativeBurnIn+1:end),'all');
        clean=simulateDeltaInformationStructure( ...
            cfg,'delta-public',seeds(seedIndex));
        cellId(q)=string(c.id);
        seed(q)=seeds(seedIndex);
        N(q)=c.N;
        rho(q)=c.rho;
        epsilon(q)=c.epsilon;
        upstreamMeanAoII(q)=upstream;
        cleanRoomMeanAoII(q)=clean.MEAN_AOII;
    end
end
clear pathCleanup;

relativeDifference=(cleanRoomMeanAoII-upstreamMeanAoII)./ ...
    max(upstreamMeanAoII,eps);
rows=table(cellId,seed,N,rho,epsilon,upstreamMeanAoII, ...
    cleanRoomMeanAoII,relativeDifference);
[group,summary]=findgroups(rows(:,{'cellId','N','rho','epsilon'}));
summary.n=splitapply(@numel,rows.seed,group);
summary.upstreamMeanAoII=splitapply(@mean,rows.upstreamMeanAoII,group);
summary.cleanRoomMeanAoII=splitapply(@mean,rows.cleanRoomMeanAoII,group);
summary.relativeDifferenceOfMeans=(summary.cleanRoomMeanAoII- ...
    summary.upstreamMeanAoII)./max(summary.upstreamMeanAoII,eps);

writetable(rows,fullfile(outputDir,'upstream_validation_rows.csv'));
writetable(summary,fullfile(outputDir,'upstream_validation_summary.csv'));
provenance=struct('referenceUrl',R.upstreamDeltaUrl, ...
    'referenceCommit',commit,'referenceDirectory',referenceDir, ...
    'cleanRoomImplementation','network/simulateDeltaInformationStructure.m', ...
    'seeds',seeds,'cells',{cellstr(string({cells.id}))}, ...
    'descriptiveOnly',true,'decisionGate',false, ...
    'upstreamSourceCopiedIntoRepository',false, ...
    'upstreamLicense','GPLv3');
writeJson(fullfile(outputDir,'upstream_validation_provenance.json'),provenance);
V=struct('rows',rows,'summary',summary,'provenance',provenance);

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('validateExp20ADeltaUpstream: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
