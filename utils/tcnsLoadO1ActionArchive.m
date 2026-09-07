function actions = tcnsLoadO1ActionArchive(runDirectory)
%TCNSLOADO1ACTIONARCHIVE Read O1 action CSV or its lossless ZIP artifact.

csvPath = fullfile(runDirectory,'oracle_actions.csv');
if exist(csvPath,'file')==2
    actions = readtable(csvPath,'TextType','string');
    return;
end
zipPath = [csvPath '.zip'];
if exist(zipPath,'file')~=2
    error('tcnsLoadO1ActionArchive:Missing', ...
        'Neither %s nor its ZIP artifact exists.',csvPath);
end
temporaryDirectory = tempname;
mkdir(temporaryDirectory);
cleanup = onCleanup(@() rmdir(temporaryDirectory,'s'));
files = unzip(zipPath,temporaryDirectory);
match = files(endsWith(string(files),'oracle_actions.csv'));
if numel(match)~=1
    error('tcnsLoadO1ActionArchive:Archive', ...
        'Expected exactly one oracle_actions.csv member.');
end
actions = readtable(match{1},'TextType','string');
clear cleanup;

end
