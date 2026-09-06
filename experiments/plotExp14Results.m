function files = plotExp14Results(primaryDir,oodDir)
%PLOTEXP14RESULTS Reproducible publication figures from frozen EXP14 CSVs.

if nargin<2 || ~isfolder(primaryDir) || ~isfolder(oodDir)
    error('plotExp14Results: valid primaryDir and oodDir are required.');
end

frontierPath=fullfile(primaryDir,'analysis_frontier_summary.csv');
mechanismPath=fullfile(primaryDir,'analysis_mechanism_summary.csv');
oodPath=fullfile(oodDir,'analysis_ood_summary.csv');
if ~isfile(frontierPath) || ~isfile(mechanismPath) || ~isfile(oodPath)
    error('plotExp14Results: run analyzeExp14Results first.');
end

F=readtable(frontierPath,'TextType','string');
M=readtable(mechanismPath,'TextType','string');
O=readtable(oodPath,'TextType','string');
R=exp14Registry();

primaryFigDir=fullfile(primaryDir,'figures');
oodFigDir=fullfile(oodDir,'figures');
if ~isfolder(primaryFigDir), mkdir(primaryFigDir); end
if ~isfolder(oodFigDir), mkdir(oodFigDir); end

files=strings(0,1);
files(end+1)=makeFrontierFigure(F,primaryFigDir);
files(end+1)=makeMechanismFigure(M,primaryFigDir);
files(end+1)=makeOODFigure(O,R,oodFigDir);

end


function path=makeFrontierFigure(S,target)

scenarios=["Clean" "Moderate" "Stressed"];
families=unique(S.family,'stable');
colors=lines(numel(families));
f=figure('Name','EXP14 primary frontiers','Color','w','Visible','off', ...
    'Position',[50 50 1480 470]);
cleaner=onCleanup(@() close(f)); %#ok<NASGU>
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for i=1:numel(scenarios)
    ax=nexttile; hold(ax,'on');
    for j=1:numel(families)
        Q=S(S.scenarioLabel==scenarios(i) & S.family==families(j),:);
        Q=sortrows(Q,'pointIndex');
        isProposed=families(j)=="Causal-Broadcast";
        width=1.2+1.2*double(isProposed);
        marker=ternary(isProposed,'s','o');
        plot(ax,Q.meanOfferedUtil,Q.meanRMSE,['-' marker], ...
            'LineWidth',width,'MarkerSize',5+2*double(isProposed), ...
            'Color',colors(j,:),'DisplayName',families(j));
        unsafe=Q.safeFailures>0 | Q.divergences>0;
        if any(unsafe)
            plot(ax,Q.meanOfferedUtil(unsafe),Q.meanRMSE(unsafe),'x', ...
                'Color',colors(j,:),'LineWidth',1.8,'MarkerSize',9, ...
                'HandleVisibility','off');
        end
    end
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Offered airtime utilization');
    ylabel(ax,'Formation RMSE [m]');
    title(ax,scenarios(i));
    if i==1
        legend(ax,'Location','northwest','FontSize',8);
    end
end
sgtitle('EXP14 primary equal-budget frontiers (cross = any safety failure)');
path=fullfile(target,'exp14_primary_frontiers.png');
exportgraphics(f,path,'Resolution',300);
savefig(f,fullfile(target,'exp14_primary_frontiers.fig'));

end


function path=makeMechanismFigure(S,target)

scenarios=["Clean" "Moderate" "Stressed"];
arms=["causal-unicast" "broadcast-data-only" "broadcast-standalone" ...
    "broadcast-piggyback" "broadcast-hybrid"];
short=["Unicast" "DATA only" "Standalone" "Piggyback" "Hybrid"];
colors=lines(numel(arms));
f=figure('Name','EXP14 mechanism ablation','Color','w','Visible','off', ...
    'Position',[70 70 1420 450]);
cleaner=onCleanup(@() close(f)); %#ok<NASGU>
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for i=1:numel(scenarios)
    ax=nexttile; hold(ax,'on');
    for j=1:numel(arms)
        Q=S(S.scenarioLabel==scenarios(i) & S.arm==arms(j),:);
        if height(Q)~=1
            error('plotExp14Results: missing mechanism %s/%s.', ...
                scenarios(i),arms(j));
        end
        scatter(ax,Q.meanOfferedUtil,Q.meanRMSE,75,colors(j,:),'filled', ...
            'DisplayName',short(j));
        text(ax,Q.meanOfferedUtil,Q.meanRMSE,"  "+short(j), ...
            'FontSize',8,'VerticalAlignment','middle');
    end
    grid(ax,'on'); box(ax,'on');
    xlabel(ax,'Offered airtime utilization');
    ylabel(ax,'Formation RMSE [m]');
    title(ax,scenarios(i));
end
sgtitle('EXP14 mechanism ablation at frozen default thresholds');
path=fullfile(target,'exp14_mechanism_ablation.png');
exportgraphics(f,path,'Resolution',300);
savefig(f,fullfile(target,'exp14_mechanism_ablation.fig'));

end


function path=makeOODFigure(S,R,target)

points=string({R.oodPoints.label})';
arms=string({R.oodMethods.id});
labels=["P10" "P20" "State" "Belief" "Hybrid" "Piggyback"];
nPoint=numel(points); nArm=numel(arms);
rmse=zeros(nPoint,nArm); offered=zeros(nPoint,nArm); safety=zeros(nPoint,nArm);
for i=1:nPoint
    H=S(S.family==points(i) & S.arm=="proposed-hybrid",:);
    if height(H)~=1
        error('plotExp14Results: missing hybrid OOD reference %s.',points(i));
    end
    for j=1:nArm
        Q=S(S.family==points(i) & S.arm==arms(j),:);
        if height(Q)~=1
            error('plotExp14Results: missing OOD cell %s/%s.',points(i),arms(j));
        end
        rmse(i,j)=100*(Q.meanRMSE/H.meanRMSE-1);
        offered(i,j)=100*(Q.meanOfferedUtil/H.meanOfferedUtil-1);
        safety(i,j)=100*Q.safeFailures/Q.n;
    end
end

f=figure('Name','EXP14 OOD robustness','Color','w','Visible','off', ...
    'Position',[80 40 1480 920]);
cleaner=onCleanup(@() close(f)); %#ok<NASGU>
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
heatPanel(nexttile,rmse,points,labels, ...
    'RMSE relative to hybrid [%] (negative = better than hybrid)','%+.0f');
heatPanel(nexttile,offered,points,labels, ...
    'Offered airtime relative to hybrid [%] (negative = lower)','%+.0f');
heatPanel(nexttile,safety,points,labels, ...
    'Safety-failure rate [%]','%.0f');
sgtitle(['EXP14 secondary/OOD matrix; ratios are descriptive and ' ...
    'intervals remain in CSV artifacts']);
path=fullfile(target,'exp14_ood_robustness.png');
exportgraphics(f,path,'Resolution',300);
savefig(f,fullfile(target,'exp14_ood_robustness.fig'));

end


function heatPanel(ax,X,rowLabels,columnLabels,titleText,valueFormat)

imagesc(ax,X);
colormap(ax,turbo(256));
colorbar(ax);
xticks(ax,1:numel(columnLabels)); xticklabels(ax,columnLabels);
yticks(ax,1:numel(rowLabels)); yticklabels(ax,rowLabels);
title(ax,titleText); box(ax,'on');
for i=1:size(X,1)
    for j=1:size(X,2)
        text(ax,j,i,sprintf(valueFormat,X(i,j)), ...
            'HorizontalAlignment','center','FontSize',8,'Color','k');
    end
end

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
