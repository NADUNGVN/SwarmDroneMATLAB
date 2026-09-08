%% GM manuscript figures from frozen machine-readable evidence

startup;
close all;
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(fileparts(scriptDir)));
outDir = fullfile(scriptDir,'figures');
if ~isfolder(outDir), mkdir(outDir); end

blue = [0.12 0.35 0.63];
orange = [0.88 0.43 0.12];
red = [0.72 0.18 0.20];
green = [0.17 0.55 0.36];
gray = [0.38 0.40 0.43];

%% Figure 1: information architecture
[cfg,~] = tcnsGate6Scenario(27020001,'S1');
model = tcnsInformationLimitsModel(cfg,25,4,0);
xy = [0 0.88; -1.05 0.05; -0.36 -1.15; 0.52 -1.15; 1.12 0.05];
f = figure('Color','w','Position',[100 100 920 520]);
ax = axes(f); hold(ax,'on'); axis(ax,'equal'); axis(ax,[-1.55 1.65 -1.65 1.55]); axis(ax,'off');
for a = 1:model.nOrdinaryLinks
    i = model.edgeReceiver(a); j = model.edgeSender(a);
    localArrow(ax,xy(j,:),xy(i,:),[0.72 0.74 0.77],0.9);
end
for a = 1:model.nPinnedLinks
    i = model.pinReceiver(a);
    plot(ax,[xy(1,1) xy(i,1)],[xy(1,2) xy(i,2)],'--','Color',green,'LineWidth',1.7);
end
for i = 1:5
    if i==1, fc = [0.98 0.80 0.32]; else, fc = [0.82 0.90 0.98]; end
    scatter(ax,xy(i,1),xy(i,2),900,fc,'filled','MarkerEdgeColor',[0.15 0.18 0.22],'LineWidth',1.4);
    text(ax,xy(i,1),xy(i,2),sprintf('UAV %d',i),'HorizontalAlignment','center','FontWeight','bold');
end
localArrow(ax,xy(1,:),xy(5,:),red,2.8);
text(ax,-1.47,1.42,'Sender-local information','FontWeight','bold','Color',blue,'FontSize',12);
text(ax,-1.47,1.23,{'own state and controller memories';'sent-packet and time history';'known dynamics/channel law'},'Color',blue,'VerticalAlignment','top');
text(ax,0.56,1.42,'Exact action value also uses','FontWeight','bold','Color',red,'FontSize',12);
text(ax,0.56,1.23,{'receiver-held and remote residuals';'global no-action formation response'},'Color',red,'VerticalAlignment','top');
text(ax,0,-1.53,'Dashed green: pinned-leader memory   |   red: example candidate action 1 -> 5', ...
    'HorizontalAlignment','center','Color',gray);
title(ax,'Distributed formation information structure');
localSave(f,outDir,'fig1_information_architecture');

%% Figure 2: frozen bound-trigger mechanism falsification
p = readtable(fullfile(repoRoot,'results','tcns_gate5_stationary_frontiers','2026-09-07_010403','frontier_periodic.csv'));
b = readtable(fullfile(repoRoot,'results','tcns_gate5_stationary_frontiers','2026-09-07_010403','frontier_control_aware.csv'));
p = sortrows(p,'meanCost025PerChannel_Hz');
b = sortrows(b,'meanCost025PerChannel_Hz');
f = figure('Color','w','Position',[100 100 660 480]);
plot(p.meanCost025PerChannel_Hz,p.meanFormationRMSE_m,'-o','Color',blue,'LineWidth',2,'MarkerFaceColor',blue); hold on;
plot(b.meanCost025PerChannel_Hz,b.meanFormationRMSE_m,'-s','Color',orange,'LineWidth',2,'MarkerFaceColor',orange);
xlabel('DATA + 0.25 ACK [Hz/channel]'); ylabel('Formation RMSE [m]');
legend('Periodic frontier','bound\_trigger\_v1 frontier','Location','northeast'); grid on; box on;
title({'A valid uncertainty bound is not an economic scheduler';'frozen stationary development experiment'});
localSave(f,outDir,'fig2_bound_trigger_falsification');

%% Figure 3: centralized exact-value headroom and negative boundary
a = readtable(fullfile(repoRoot,'results','tcns_o1_oracle_frontier_stage_a','2026-09-07_160426','frontiers.csv'));
c = readtable(fullfile(repoRoot,'results','tcns_o1_oracle_frontier_stage_b','2026-09-07_162102','frontiers.csv'));
f = figure('Color','w','Position',[100 100 980 430]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
localOraclePanel(nexttile,a,'S2','Formation switching: headroom',blue,red);
localOraclePanel(nexttile,c,'S4','Time-varying congestion: boundary',blue,red);
sgtitle('Centralized current-state oracle versus the frozen periodic frontier');
localSave(f,outDir,'fig3_oracle_headroom_boundary');

%% Figure 4: frozen feedback economics
e = readtable(fullfile(repoRoot,'results','tcns_fb0_feedback_economics','2026-09-07_175224','scenario_summary.csv'));
f = figure('Color','w','Position',[100 100 760 460]);
x = 1:height(e);
lo = e.etaMedian-e.etaQ25; hi = e.etaQ75-e.etaMedian;
errorbar(x,e.etaMedian,lo,hi,'o','Color',blue,'MarkerFaceColor',blue,'LineWidth',1.8,'CapSize',10); hold on;
yline(0.25,'--','Frozen ACK price = 0.25','Color',red,'LineWidth',1.6,'LabelHorizontalAlignment','left');
yline(0,'-','Color',[0.2 0.2 0.2]);
xticks(x); xticklabels(e.scenarioId); ylabel('Break-even feedback price \eta^*');
xlabel('Development scenario'); grid on; box on;
title({'Cost of learning the information needed for value decisions';'median and interquartile range over matchable O1 points'});
localSave(f,outDir,'fig4_feedback_economics');

%% Figure 5: information-space geometry
f = figure('Color','w','Position',[100 100 720 470]);
ax = axes(f); hold(ax,'on'); axis(ax,'equal'); axis(ax,[-0.3 4.8 -0.5 3.8]); axis(ax,'off');
patch(ax,[-0.1 4.5 4.5 -0.1],[-0.15 -0.15 0.15 0.15],[0.78 0.87 0.97], ...
    'EdgeColor','none','FaceAlpha',0.8);
quiver(ax,0,0,3.4,0,0,'Color',blue,'LineWidth',3,'MaxHeadSize',0.16);
quiver(ax,0,0,0,2.6,0,'Color',gray,'LineWidth',2,'LineStyle','--','MaxHeadSize',0.18);
quiver(ax,0,0,2.8,2.25,0,'Color',red,'LineWidth',3,'MaxHeadSize',0.14);
quiver(ax,2.8,0,0,2.25,0,'Color',orange,'LineWidth',2.4,'LineStyle','--','MaxHeadSize',0.18);
text(ax,3.45,-0.22,'row(C)','Color',blue,'FontWeight','bold');
text(ax,-0.12,2.85,'ker(C)','Color',gray,'FontWeight','bold');
text(ax,2.95,2.35,'value coefficient l','Color',red,'FontWeight','bold');
text(ax,2.92,1.05,'missing l-perp','Color',orange,'FontWeight','bold','Rotation',90);
text(ax,1.03,-0.38,'locally reconstructable component l-parallel','Color',blue);
text(ax,0.15,3.48,{'Motion along ker(C) is invisible to the sender'; ...
    'but changes value when l-perp is nonzero'}, ...
    'FontSize',9,'FontWeight','bold','VerticalAlignment','top');
title(ax,'Geometry of exact action-value identifiability');
localSave(f,outDir,'fig5_information_geometry');

%% Figure 6: full reachable indistinguishable histories
root = fullfile(repoRoot,'results','tcns_information_limits_validation');
d = dir(fullfile(root,'*','workspace.mat'));
[~,ix] = max([d.datenum]);
S = load(fullfile(d(ix).folder,d(ix).name),'ordinaryWitness','pinWitness');
f = figure('Color','w','Position',[100 100 1040 690]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
localWitnessTrace(nexttile,S.ordinaryWitness,'Ordinary payload 1 -> 5',blue,orange);
localWitnessValue(nexttile,S.ordinaryWitness,'Ordinary value sign',blue,orange);
localWitnessTrace(nexttile,S.pinWitness,'Pinned-leader payload 1 -> 4',blue,orange);
localWitnessValue(nexttile,S.pinWitness,'Pinned-leader value sign',blue,orange);
sgtitle('Reachable histories: identical sender observations, opposite action-value signs');
localSave(f,outDir,'fig6_reachable_sign_witnesses');

fprintf('GM figures written to %s\n',outDir);

function localArrow(ax,p0,p1,color,width)
v = p1-p0; u = v/norm(v); p0 = p0+0.22*u; p1 = p1-0.22*u;
quiver(ax,p0(1),p0(2),p1(1)-p0(1),p1(2)-p0(2),0, ...
    'Color',color,'LineWidth',width,'MaxHeadSize',0.18);
end

function localOraclePanel(ax,T,scenario,titleText,blue,red)
rows = string(T.scenarioId)==scenario;
P = sortrows(T(rows & string(T.frontierFamily)=="Periodic",:),'meanEvaluationCost025PerChannel_Hz');
O = sortrows(T(rows & string(T.frontierFamily)~="Periodic",:),'meanEvaluationCost025PerChannel_Hz');
h1 = plot(ax,P.meanEvaluationCost025PerChannel_Hz,P.meanFormationRMSE_m,'-o','Color',blue,'LineWidth',2,'MarkerFaceColor',blue); hold(ax,'on');
h2 = plot(ax,O.meanEvaluationCost025PerChannel_Hz,O.meanFormationRMSE_m,'-s','Color',red,'LineWidth',2,'MarkerFaceColor',red);
xlabel(ax,'DATA + 0.25 ACK [Hz/channel]'); ylabel(ax,'Formation RMSE [m]');
title(ax,titleText); grid(ax,'on'); box(ax,'on'); legend(ax,[h1 h2],{'Periodic','centralized oracle'},'Location','best');
end

function localWitnessTrace(ax,W,titleText,blue,orange)
plot(ax,W.minus.time_s,W.minus.formationErrorNorm,'-','Color',blue,'LineWidth',2); hold(ax,'on');
plot(ax,W.plus.time_s,W.plus.formationErrorNorm,'--','Color',orange,'LineWidth',2);
xlabel(ax,'Time [s]'); ylabel(ax,'||e_f||_F [m]'); title(ax,titleText); grid(ax,'on'); box(ax,'on');
legend(ax,'history -','history +','Location','best');
text(ax,0.03,0.95,sprintf('max sender-observation difference = %.1e',W.senderObservationDifference), ...
    'Units','normalized','VerticalAlignment','top');
end

function localWitnessValue(ax,W,titleText,blue,orange)
bar(ax,1,W.minus.expectedValue,0.55,'FaceColor',blue); hold(ax,'on');
bar(ax,2,W.plus.expectedValue,0.55,'FaceColor',orange); yline(ax,0,'k-');
xticks(ax,[1 2]); xticklabels(ax,{'history -','history +'}); ylabel(ax,'Expected exact action value');
title(ax,titleText); grid(ax,'on'); box(ax,'on');
text(ax,0.03,0.95,sprintf('action-response difference = %.1e',W.actionResponseDifference), ...
    'Units','normalized','VerticalAlignment','top');
end

function localSave(f,outDir,name)
exportgraphics(f,fullfile(outDir,[name '.pdf']),'ContentType','vector');
exportgraphics(f,fullfile(outDir,[name '.png']),'Resolution',220);
close(f);
end
