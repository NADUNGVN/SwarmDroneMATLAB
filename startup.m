function startup()
%STARTUP Add all project folders to the MATLAB path.
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
fprintf('SwarmDroneMATLAB ready. Root: %s\n', rootDir);
end
