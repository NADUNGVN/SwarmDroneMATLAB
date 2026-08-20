function n = saveAllFigures(R)
%SAVEALLFIGURES Export every open figure into the run's figures/ folder.
%
%   n = saveAllFigures(R)
%
% Each figure is written twice: a 300 dpi PNG for immediate use and a .fig
% so it can still be edited later for the manuscript.
%
% Figures are numbered in creation order. The numeric prefix matters
% because several experiments create figures inside a loop and therefore
% produce repeated figure names.

figs = findobj(groot,'Type','figure');

if isempty(figs)
    n = 0;
    fprintf('saveAllFigures: no open figures.\n');
    return;
end


[~,order] = sort([figs.Number]);

figs = figs(order);

n = numel(figs);


for k = 1:n

    f = figs(k);

    name = strtrim(f.Name);

    if isempty(name)
        base = sprintf('fig%02d', k);
    else
        base = sprintf('fig%02d_%s', k, matlab.lang.makeValidName(name));
    end

    pngPath = fullfile(R.figDir, [base '.png']);
    figPath = fullfile(R.figDir, [base '.fig']);

    try
        exportgraphics(f, pngPath, 'Resolution', 300);
    catch err
        fprintf('saveAllFigures: PNG failed for %s (%s)\n', base, err.message);
    end

    try
        savefig(f, figPath);
    catch err
        fprintf('saveAllFigures: FIG failed for %s (%s)\n', base, err.message);
    end

end


fprintf('saveAllFigures: %d figure(s) written to %s\n', n, R.figDir);

end
