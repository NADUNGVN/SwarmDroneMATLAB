function startup()
%STARTUP Add all project folders to the MATLAB path.
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

% Results contain immutable source snapshots for provenance.  They are data,
% not executable code: adding them lets an old snapshot shadow current source
% in a later MATLAB session.  Remove the complete results subtree immediately
% after adding project code so `which` always resolves to the workspace source.
resultsDir = fullfile(rootDir,'results');
if isfolder(resultsDir)
    rmpath(genpath(resultsDir));
end
fprintf('SwarmDroneMATLAB ready. Root: %s\n', rootDir);
end
