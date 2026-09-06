function [effects,safety]=analyzeExp14CDevelopment(runDir)
%ANALYZEEXP14CDEVELOPMENT Paired mechanism attribution for completed EXP14C.
%
%   [effects,safety] = analyzeExp14CDevelopment(runDir)
%
% Reads the immutable simulation rows in RUNDir/tidy.csv and writes two
% explicitly exploratory artifacts:
%
%   development_effects.csv        paired continuous-outcome diagnostics
%   development_safety_effects.csv paired binary safety counts
%
% This function does not select a method, change an EXP14C gate, or permit a
% confirmatory claim. It fails closed when the registered matrix or CRN
% pairing is incomplete.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14CDevelopment: runDir must be a character vector or scalar string.');
end
runDir=char(runDir);
tidyPath=fullfile(runDir,'tidy.csv');
if exist(tidyPath,'file')~=2
    error('analyzeExp14CDevelopment: missing %s.',tidyPath);
end

R=exp14cRegistry();
T=readtable(tidyPath,'TextType','string');
validateMatrix(T,R);

comparisons=struct( ...
    'id',{'adaptive_ack_vs_piggyback','load_guard_given_adaptive', ...
    'access_scaling_given_hybrid','access_scaling_given_guarded_adaptive', ...
    'adaptive_guard_given_scaled_access','full_v2_vs_hybrid'}, ...
    'armA',{'adaptive-only','guarded-adaptive','access-only','full-v2', ...
    'full-v2','full-v2'}, ...
    'armB',{'frozen-piggyback','adaptive-only','frozen-hybrid', ...
    'guarded-adaptive','access-only','frozen-hybrid'});
metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED'};

effects=table();
safety=table();
for c=R.cells
    for comparison=comparisons
        A=armRows(T,R,c.id,comparison.armA);
        B=armRows(T,R,c.id,comparison.armB);
        validatePair(A,B,c.id,comparison.id);
        for k=1:numel(metrics)
            metric=metrics{k};
            ci=pairedCI(A.(metric),B.(metric),numel(R.seeds));
            meanA=mean(A.(metric),'omitnan');
            meanB=mean(B.(metric),'omitnan');
            if meanB==0
                relativePct=NaN;
            else
                relativePct=100*(meanA-meanB)/abs(meanB);
            end
            row=table(string(c.id),string(comparison.id), ...
                string(comparison.armA),string(comparison.armB),string(metric), ...
                meanA,meanB,relativePct,ci.meanD,ci.lo,ci.hi,ci.nPairs, ...
                ci.nDropped,ci.crossesZero,'VariableNames', ...
                {'cell','effect','armA','armB','metric','meanA','meanB', ...
                'relativePct','difference','pairedTLo','pairedTHi','nPairs', ...
                'nDropped','crossesZero'});
            effects=[effects; row]; %#ok<AGROW>
        end

        failureA=logical(A.SAFEFAIL);
        failureB=logical(B.SAFEFAIL);
        row=table(string(c.id),string(comparison.id), ...
            string(comparison.armA),string(comparison.armB),sum(failureA), ...
            sum(failureB),sum(~failureA & failureB),sum(failureA & ~failureB), ...
            sum(failureA==failureB),numel(failureA),'VariableNames', ...
            {'cell','effect','armA','armB','failuresA','failuresB', ...
            'seedsImproved','seedsWorsened','seedsEqual','nPairs'});
        safety=[safety; row]; %#ok<AGROW>
    end
end

writetable(effects,fullfile(runDir,'development_effects.csv'));
writetable(safety,fullfile(runDir,'development_safety_effects.csv'));
manifest=struct('source','tidy.csv','registryVersion',R.version, ...
    'rows',height(T),'pairedEffects',height(effects), ...
    'pairedSafetyEffects',height(safety),'postHocDescriptive',true, ...
    'confirmatoryClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'development_analysis_manifest.json'),manifest);

end


function validateMatrix(T,R)

required={'seed','scenario','arm','RMSE','MEAN_TRUE_AOI','OFFERED_UTIL', ...
    'CHANNEL_UTIL','COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED', ...
    'SAFEFAIL','TRACE_HASH_EXACT','CHANNEL_STATE_HASH'};
missing=setdiff(required,T.Properties.VariableNames);
if ~isempty(missing)
    error('analyzeExp14CDevelopment: missing columns: %s.',strjoin(missing,', '));
end
if height(T)~=R.expectedRuns
    error('analyzeExp14CDevelopment: expected %d rows, found %d.', ...
        R.expectedRuns,height(T));
end
keys=string(T.seed)+"|"+T.scenario+"|"+T.arm;
if numel(unique(keys))~=height(T)
    error('analyzeExp14CDevelopment: seed/cell/arm keys are not unique.');
end

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp14CDevelopment: incomplete %s/%s arm.',cellId,armId);
end

end


function validatePair(A,B,cellId,effectId)

if ~isequal(A.seed,B.seed) || ...
        ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
        ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH)
    error('analyzeExp14CDevelopment: non-CRN pair for %s/%s.', ...
        cellId,effectId);
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14CDevelopment: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
