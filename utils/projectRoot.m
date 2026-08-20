function root = projectRoot()
%PROJECTROOT Absolute path of the SwarmDroneMATLAB project root.
%
% Resolved from the location of this file, so it is independent of the
% current working directory and of how the caller was launched.

root = fileparts(fileparts(mfilename('fullpath')));

end
