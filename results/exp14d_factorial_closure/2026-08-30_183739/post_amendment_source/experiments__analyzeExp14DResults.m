function [contrasts,safety]=analyzeExp14DResults(runDir)
%ANALYZEEXP14DRESULTS Descriptive paired contrasts for completed EXP14D.
%
%   [contrasts,safety] = analyzeExp14DResults(runDir)
%
% The complete-factorial effects and candidate selection remain the registered
% analyses. This helper adds transparent post-selection descriptive contrasts;
% it cannot change the selected arm or permit a confirmatory claim.

if nargin~=1 || ~(ischar(runDir) || (isstring(runDir) && isscalar(runDir)))
    error('analyzeExp14DResults: runDir must be char or scalar string.');
end
runDir=char(runDir);
tidyPath=fullfile(runDir,'tidy.csv');
gatePath=fullfile(runDir,'gates.csv');
if exist(tidyPath,'file')~=2 || exist(gatePath,'file')~=2
    error('analyzeExp14DResults: completed tidy and gate artifacts are required.');
end
T=readtable(tidyPath,'TextType','string','Delimiter',',');
G=readtable(gatePath,'TextType','string','Delimiter',',');
R=exp14dRegistry();
if height(T)~=R.expectedRuns || ~all(G.passed==1)
    error('analyzeExp14DResults: EXP14D matrix or integrity gates are incomplete.');
end

pairs=struct( ...
    'id',{'selected_vs_access','selected_vs_full','selected_vs_frozen', ...
    'guard_at_adaptive_scaled','guard_at_hybrid_scaled'}, ...
    'armA',{'a1-g0-s1','a1-g0-s1','a1-g0-s1','a1-g1-s1','a0-g1-s1'}, ...
    'armB',{'a0-g0-s1','a1-g1-s1','a0-g0-s0','a1-g0-s1','a0-g0-s1'});
metrics={'RMSE','MEAN_TRUE_AOI','OFFERED_UTIL','CHANNEL_UTIL', ...
    'COLLISION_FRAMES','DATA_ATTEMPTED','ACK_ATTEMPTED'};
contrasts=table(); safety=table();
for c=R.cells
    for p=pairs
        A=armRows(T,R,c.id,p.armA);
        B=armRows(T,R,c.id,p.armB);
        if ~isequal(A.TRACE_HASH_EXACT,B.TRACE_HASH_EXACT) || ...
                ~isequal(A.CHANNEL_STATE_HASH,B.CHANNEL_STATE_HASH)
            error('analyzeExp14DResults: non-CRN pair for %s/%s.',c.id,p.id);
        end
        for m=1:numel(metrics)
            metric=metrics{m};
            ci=pairedCI(A.(metric),B.(metric),numel(R.seeds));
            meanA=mean(A.(metric),'omitnan');
            meanB=mean(B.(metric),'omitnan');
            relativePct=NaN;
            if meanB~=0, relativePct=100*(meanA-meanB)/abs(meanB); end
            row=table(string(c.id),string(p.id),string(p.armA), ...
                string(p.armB),string(metric),meanA,meanB,relativePct, ...
                ci.meanD,ci.lo,ci.hi,ci.nPairs,ci.nDropped,ci.crossesZero, ...
                'VariableNames',{'cell','contrast','armA','armB','metric', ...
                'meanA','meanB','relativePct','difference','pairedTLo', ...
                'pairedTHi','nPairs','nDropped','crossesZero'});
            contrasts=[contrasts; row]; %#ok<AGROW>
        end
        failA=logical(A.SAFEFAIL); failB=logical(B.SAFEFAIL);
        row=table(string(c.id),string(p.id),string(p.armA),string(p.armB), ...
            sum(failA),sum(failB),sum(~failA & failB), ...
            sum(failA & ~failB),sum(failA==failB),numel(failA), ...
            'VariableNames',{'cell','contrast','armA','armB','failuresA', ...
            'failuresB','seedsImproved','seedsWorsened','seedsEqual','nPairs'});
        safety=[safety; row]; %#ok<AGROW>
    end
end

writetable(contrasts,fullfile(runDir,'descriptive_pairwise_contrasts.csv'));
writetable(safety,fullfile(runDir,'descriptive_pairwise_safety.csv'));
manifest=struct('source','tidy.csv','registryVersion',R.version, ...
    'registeredAnalysis','factorial_effects.csv and candidate_audit.csv', ...
    'postSelectionDescriptive',true,'confirmatoryClaimPermitted',false, ...
    'createdAt',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeJson(fullfile(runDir,'descriptive_analysis_manifest.json'),manifest);

end


function A=armRows(T,R,cellId,armId)

A=sortrows(T(T.scenario==string(cellId) & T.arm==string(armId),:),'seed');
if height(A)~=numel(R.seeds) || ~isequal(A.seed,R.seeds)
    error('analyzeExp14DResults: incomplete %s/%s arm.',cellId,armId);
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('analyzeExp14DResults: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end
