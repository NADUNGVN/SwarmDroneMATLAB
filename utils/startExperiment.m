function R = startExperiment(expName, notes)
%STARTEXPERIMENT Begin a recorded experiment run.
%
%   R = startExperiment('exp06a_scalability')
%
% Creates results/<expName>/<runId>/, starts a diary so that every fprintf
% the experiment already emits is captured verbatim, snapshots the source
% file that is about to run, and records provenance.
%
% Pair with finishExperiment(R) at the end of the script:
%
%   R = startExperiment('exp06a_scalability');
%   ...
%   save(fullfile(R.dir,'workspace.mat'));
%   saveAllFigures(R);
%   finishExperiment(R);

if nargin < 2
    notes = '';
end


%% ============================================================
% Paths
% ============================================================

root = projectRoot();

R.name = expName;
R.notes = notes;

R.runId = char(datetime('now','Format','yyyy-MM-dd_HHmmss'));

R.expRoot = fullfile(root,'results',expName);
R.dir     = fullfile(R.expRoot, R.runId);
R.figDir  = fullfile(R.dir,'figures');

if ~exist(R.figDir,'dir')
    mkdir(R.figDir);
end


%% ============================================================
% Provenance
% ============================================================

v = ver('MATLAB');

R.meta.experiment    = expName;
R.meta.runId         = R.runId;
R.meta.startedAt     = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
R.meta.matlabVersion = sprintf('%s %s', v.Name, v.Version);
R.meta.matlabRelease = v.Release;
R.meta.computer      = computer;
R.meta.projectRoot   = root;
R.meta.gitCommit     = localGitCommit(root);
R.meta.notes         = notes;


%% ============================================================
% Source snapshot
%
% Records exactly which version of the script produced this run.
% ============================================================

srcPath = which(expName);

if ~isempty(srcPath) && exist(srcPath,'file')

    try
        copyfile(srcPath, R.dir);
        R.meta.sourceFile = srcPath;
    catch
        R.meta.sourceFile = '';
    end

else
    R.meta.sourceFile = '';
end


%% ============================================================
% Console capture
%
% Everything printed from here until finishExperiment lands in
% console.log, including all pre-existing result tables.
% ============================================================

R.logFile = fullfile(R.dir,'console.log');

diary(R.logFile);
diary on;


R.t0 = tic;


fprintf('\n');
fprintf('============================================================\n');
fprintf('RUN  : %s\n', expName);
fprintf('ID   : %s\n', R.runId);
fprintf('DIR  : %s\n', R.dir);
fprintf('WHEN : %s\n', R.meta.startedAt);
fprintf('============================================================\n\n');

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function commit = localGitCommit(root)

commit = '';

try
    [status, out] = system(sprintf('git -C "%s" rev-parse --short HEAD', root));

    if status == 0
        commit = strtrim(out);
    end
catch
    commit = '';
end

end
