function writeTableAtomic(T,path)
%WRITETABLEATOMIC Replace one table artifact only after a complete write.

if ~(istable(T) && (ischar(path) || isstring(path)))
    error('writeTableAtomic: require a table and destination path.');
end
path=char(path);
folder=fileparts(path);
if isempty(folder), folder=pwd; end
if ~isfolder(folder)
    error('writeTableAtomic: destination directory does not exist.');
end

temporary=[tempname(folder) '.csv'];
cleaner=onCleanup(@() cleanupTemporary(temporary)); %#ok<NASGU>
writetable(T,temporary);
[ok,message]=movefile(temporary,path,'f');
if ~ok
    error('writeTableAtomic: atomic replacement failed: %s',message);
end

end


function cleanupTemporary(path)

if isfile(path), delete(path); end

end
