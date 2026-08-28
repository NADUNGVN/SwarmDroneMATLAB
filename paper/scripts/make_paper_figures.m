function make_paper_figures()
%MAKE_PAPER_FIGURES Generate every manuscript figure from frozen results.
%
% Writes paper/figures/figNN_*.pdf and .png. RUNS NO SIMULATION: every
% panel is drawn from a persisted tidy.csv of simulation-v1.0, except
% Figures 1 and 2, which are schematics of the architecture and the
% protocol timeline and contain no measured quantity at all.
%
% Deterministic by construction - no random draw, no layout that depends
% on figure order - so regenerating gives byte-comparable content for the
% same frozen inputs.
%
% Every figure here exists to carry a specific claim. There are no
% decorative panels; if a plot did not change what a reader could
% conclude, it is not in this file.

startup;

root = projectRoot();

figDir = fullfile(root,'paper','figures');

if ~exist(figDir,'dir')
    mkdir(figDir);
end

close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('make_paper_figures\n');
fprintf('============================================================\n\n');

% One consistent visual language across the paper.
S = struct();
S.col = struct( ...
    'P10',        [0.30 0.45 0.75], ...
    'P20',        [0.15 0.25 0.50], ...
    'Event',      [0.85 0.55 0.15], ...
    'Causal',     [0.70 0.15 0.20], ...
    'Oracle',     [0.45 0.45 0.45], ...
    'Accent',     [0.20 0.55 0.35]);
S.mk = {'o','s','^','d'};
S.fs = 9;
S.lw = 1.3;

fig01_architecture(figDir, S);
fig02_protocol_timeline(figDir, S);
fig03_design_evolution(figDir, S);
fig04_adaptive_rate(figDir, S);
fig05_cost_pareto(figDir, S);
fig06_ack_impairment(figDir, S);
fig07_topology(figDir, S);
fig08_fault_response(figDir, S);
fig09_di_vs_6dof(figDir, S);
fig10_mismatch_estimator(figDir, S);
fig11_paired_holdout(figDir, S);

fprintf('\nmake_paper_figures: done.\n');

end


%% ============================================================
% FIG 1 - system architecture (schematic)
% ============================================================

function fig01_architecture(figDir, S)

f = localFig(7.0, 2.5);

ax = axes('Position',[0 0 1 1]); hold(ax,'on');
axis(ax,[0 100 0 36]); axis(ax,'off');

boxes = { ...
     2, 12, 15, 'Plant', sprintf('6-DOF quadrotor\nor double integrator'); ...
    21, 12, 15, 'Estimator', sprintf('state estimate\n(noise, latency)'); ...
    40, 12, 17, 'Causal-AoI', sprintf('trigger: innovation\n+ estimated freshness'); ...
    61, 12, 14, 'Network', sprintf('loss, delay\nfaults'); ...
    80, 12, 17, 'Swarm policy', sprintf('formation law\n-> setpoint')};

for k = 1:size(boxes,1)
    x = boxes{k,1}; y = boxes{k,2}; w = boxes{k,3};
    rectangle('Position',[x y w 11],'Curvature',0.15, ...
        'FaceColor',[0.96 0.96 0.98],'EdgeColor',[0.25 0.25 0.3],'LineWidth',1.0);
    text(x+w/2, y+8.2, boxes{k,4}, 'HorizontalAlignment','center', ...
        'FontWeight','bold','FontSize',S.fs);
    text(x+w/2, y+3.4, boxes{k,5}, 'HorizontalAlignment','center', ...
        'FontSize',S.fs-1.5,'Color',[0.3 0.3 0.35]);
end

arrows = [17 17.5 21 17.5; 36 17.5 40 17.5; 57 17.5 61 17.5; 75 17.5 80 17.5];

for k = 1:size(arrows,1)
    localArrow(arrows(k,1), arrows(k,2), arrows(k,3), arrows(k,4), [0.2 0.2 0.25], 1.1);
end

% Setpoint feedback into the plant: the control loop.
plot([88.5 88.5 9.5 9.5],[12 5 5 12],'-','Color',[0.2 0.2 0.25],'LineWidth',1.1);
localArrow(9.5, 8, 9.5, 12, [0.2 0.2 0.25], 1.1);
text(49, 3.0, 'setpoint \rightarrow cascaded attitude / thrust controller', ...
    'HorizontalAlignment','center','FontSize',S.fs-1.5,'Color',[0.3 0.3 0.35]);

% The ACK path is the contribution: draw it explicitly and label it.
plot([88.5 88.5 48.5 48.5],[23 31 31 23],'-','Color',S.col.Causal,'LineWidth',1.4);
localArrow(48.5, 27, 48.5, 23, S.col.Causal, 1.4);
text(68.5, 33.0, 'cumulative ACK (delayed, lossy)', ...
    'HorizontalAlignment','center','FontSize',S.fs-1,'Color',S.col.Causal, ...
    'FontWeight','bold');

text(50, 0.6, ['The ACK path is the only channel through which the sender ' ...
    'learns what the receiver holds.'], ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Color',[0.35 0.35 0.4]);

localSave(f, figDir, 'fig01_architecture');

end


%% ============================================================
% FIG 2 - causal protocol timeline (schematic)
% ============================================================

function fig02_protocol_timeline(figDir, S)

f = localFig(7.0, 3.0);

ax = axes('Position',[0.06 0.12 0.90 0.78]); hold(ax,'on');

ylim([0 3]); xlim([0 10]);

set(ax,'YTick',[1 2],'YTickLabel',{'receiver $j$','sender $i$'}, ...
    'TickLabelInterpreter','latex','FontSize',S.fs);

xlabel('time','FontSize',S.fs);

plot([0 10],[2 2],'-','Color',[0.6 0.6 0.65]);
plot([0 10],[1 1],'-','Color',[0.6 0.6 0.65]);

% DATA k, delivered and acknowledged.
localArrow2(1.0, 2, 2.6, 1, S.col.P10, 1.3);
text(1.6, 1.62, 'DATA, seq $k$', 'FontSize',S.fs-1.5, ...
    'Interpreter','latex','Color',S.col.P10);

plot(1.0, 2, 'o','MarkerFaceColor',S.col.P10,'MarkerEdgeColor','none','MarkerSize',5);
plot(2.6, 1, 'o','MarkerFaceColor',S.col.P10,'MarkerEdgeColor','none','MarkerSize',5);

text(1.0, 2.5, sprintf('generate\nsentGenTime $\\leftarrow t$'), ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Interpreter','latex');
text(2.6, 0.42, sprintf('accept if newer\nacceptedSeq $\\leftarrow k$'), ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Interpreter','latex');

localArrow2(2.9, 1, 4.4, 2, S.col.Causal, 1.3);
text(3.35, 1.62, 'ACK($k$)', 'FontSize',S.fs-1.5, ...
    'Interpreter','latex','Color',S.col.Causal);
text(4.4, 2.5, sprintf('ackGenTime $\\leftarrow$ genTime($k$)\nretire seq $\\le k$'), ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Interpreter','latex');

% DATA k+1 lost: never acknowledged, stays outstanding.
localArrowDashed(5.2, 2, 6.4, 1.35, [0.55 0.55 0.6], 1.2);
plot(6.4, 1.35, 'x','Color',[0.75 0.2 0.2],'MarkerSize',8,'LineWidth',1.6);
text(5.15, 2.5, 'DATA, seq $k{+}1$', 'FontSize',S.fs-2,'Interpreter','latex');
text(6.75, 1.35, 'lost', 'FontSize',S.fs-2,'Color',[0.75 0.2 0.2]);

text(5.2, 0.42, sprintf('no ACK is ever emitted:\nseq $k{+}1$ stays outstanding'), ...
    'HorizontalAlignment','left','FontSize',S.fs-2,'Interpreter','latex', ...
    'Color',[0.4 0.4 0.45]);

% Refresh blocked, then the max-silence backstop fires.
plot([7.4 7.4],[1.85 2.15],'-','Color',[0.5 0.5 0.55],'LineWidth',1.0);
text(7.4, 2.5, sprintf('refresh BLOCKED\n(outstanding $>0$)'), ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Interpreter','latex', ...
    'Color',[0.5 0.5 0.55]);

localArrow2(8.8, 2, 9.8, 1, S.col.Accent, 1.4);
text(8.35, 2.5, sprintf('max-silence\nbackstop'), ...
    'HorizontalAlignment','center','FontSize',S.fs-2,'Color',S.col.Accent, ...
    'FontWeight','bold');

title(['Loss recovery needs no retransmission timer: an unacknowledged ' ...
       'packet blocks refresh until max silence fires'], ...
    'FontSize',S.fs-1,'FontWeight','normal');

box on;

localSave(f, figDir, 'fig02_protocol_timeline');

end


%% ============================================================
% FIG 3 - design evolution, Stressed RMSE against DATA rate
% ============================================================

function fig03_design_evolution(figDir, S)

E7 = localTidy('exp07a_causal_ack');

f = localFig(5.2, 4.0);

ax = axes; hold(ax,'on'); grid(ax,'on');

items = { ...
    'A2c Fixed-OL',  'A2c fixed, open loop',      S.col.Oracle,  'v'; ...
    'A3c Adapt-OL',  'A3c adaptive, open loop',   [0.55 0.4 0.6],'^'; ...
    'A4c Dual-mem',  'A4c dual memory',           [0.3 0.55 0.7],'s'; ...
    'A5c Innov-pri', 'A5c = Causal-AoI-v3',       S.col.Causal,  'o'; ...
    'Ideal-AoI',     'ideal-feedback (non-causal)', [0.35 0.35 0.4],'p'; ...
    'P10',           'P10',                       S.col.P10,     'x'; ...
    'P20',           'P20',                       S.col.P20,     '+'; ...
    'A1 State-event','state-event',               S.col.Event,   '*'};

for k = 1:size(items,1)

    idx = strcmp(E7.method,items{k,1}) & strcmp(E7.scenario,'Stressed');

    x = mean(E7.TXRATE(idx),'omitnan');
    y = mean(E7.RMSE(idx),'omitnan');
    e = std(E7.RMSE(idx),'omitnan');

    errorbar(x, y, e, 'Marker',items{k,4},'Color',items{k,3}, ...
        'MarkerFaceColor',items{k,3},'MarkerSize',8,'LineWidth',1.2, ...
        'DisplayName',items{k,2});

end

% The chain, in order, to make the trajectory legible.
chain = {'A2c Fixed-OL','A3c Adapt-OL','A4c Dual-mem','A5c Innov-pri'};
cx = zeros(1,4); cy = zeros(1,4);

for k = 1:4
    idx = strcmp(E7.method,chain{k}) & strcmp(E7.scenario,'Stressed');
    cx(k) = mean(E7.TXRATE(idx),'omitnan');
    cy(k) = mean(E7.RMSE(idx),'omitnan');
end

plot(cx, cy, ':', 'Color',[0.5 0.5 0.55],'LineWidth',1.0, ...
    'HandleVisibility','off');

for k = 1:3
    localArrow(cx(k), cy(k), cx(k+1), cy(k+1), [0.5 0.5 0.55], 0.9);
end

xlabel('DATA rate per channel [Hz], Stressed','FontSize',S.fs);
ylabel('formation RMSE [m], Stressed','FontSize',S.fs);

legend('Location','northeast','FontSize',S.fs-2.5,'Box','off');

title(sprintf('Design evolution: v3 reaches lower RMSE than the\nnon-causal ideal-feedback reference, by transmitting more'), ...
    'FontSize',S.fs-0.5,'FontWeight','normal');

set(ax,'FontSize',S.fs-1);

localSave(f, figDir, 'fig03_design_evolution');

end


%% ============================================================
% FIG 4 - adaptive rate response across network quality
% ============================================================

function fig04_adaptive_rate(figDir, S)

U = localTidy('exp10b_unified_matrix');

scN = {'Clean','Moderate','Stressed'};
mN  = {'P10','P20','State-event','Causal-v3'};
cols = [S.col.P10; S.col.P20; S.col.Event; S.col.Causal];

f = localFig(7.0, 3.0);

% Left: DATA only. Right: DATA + 0.25 ACK.
for panel = 1:2

    subplot(1,2,panel); hold on; grid on;

    D = zeros(3,4);

    for iS = 1:3
        for iM = 1:4
            r = localURow(U,'NOMINAL',scN{iS},mN{iM});
            if panel == 1
                D(iS,iM) = r.DATA;
            else
                D(iS,iM) = r.Total_w025;
            end
        end
    end

    b = bar(D, 'grouped');

    for iM = 1:4
        b(iM).FaceColor = cols(iM,:);
        b(iM).EdgeColor = 'none';
    end

    set(gca,'XTick',1:3,'XTickLabel',scN,'FontSize',S.fs-1);

    if panel == 1
        ylabel('DATA rate [Hz], swarm total','FontSize',S.fs);
        title('DATA only','FontSize',S.fs,'FontWeight','normal');
        legend(mN,'Location','northwest','FontSize',S.fs-2.5,'Box','off');
    else
        ylabel('DATA + 0.25 ACK [Hz]','FontSize',S.fs);
        title('ACK-inclusive cost','FontSize',S.fs,'FontWeight','normal');
    end

    ylim([0 260]);

end

localSave(f, figDir, 'fig04_adaptive_rate');

end


%% ============================================================
% FIG 5 - accuracy against communication cost, with the reversal
% ============================================================

function fig05_cost_pareto(figDir, S)

U = localTidy('exp10b_unified_matrix');

mN  = {'P10','P20','State-event','Causal-v3'};
cols = [S.col.P10; S.col.P20; S.col.Event; S.col.Causal];

f = localFig(7.0, 3.2);

scN = {'Moderate','Stressed'};

for panel = 1:2

    subplot(1,2,panel); hold on; grid on;

    for iM = 1:4

        r = localURow(U,'NOMINAL',scN{panel},mN{iM});

        % DATA-only cost, hollow; ACK-inclusive cost, filled.
        plot(r.DATA, r.RMSEmean, S.mk{iM}, 'MarkerSize',9, ...
            'MarkerEdgeColor',cols(iM,:),'MarkerFaceColor','none', ...
            'LineWidth',1.4,'DisplayName',[mN{iM} ' (DATA)']);

        plot(r.Total_w025, r.RMSEmean, S.mk{iM}, 'MarkerSize',9, ...
            'MarkerEdgeColor',cols(iM,:),'MarkerFaceColor',cols(iM,:), ...
            'LineWidth',1.0,'DisplayName',[mN{iM} ' (+ACK)']);

        % The reversal, drawn: how far pricing ACKs moves each method.
        if r.Total_w025 > r.DATA + 1e-9
            localArrow(r.DATA, r.RMSEmean, r.Total_w025, r.RMSEmean, ...
                cols(iM,:), 1.1);
        end

    end

    xlabel('communication cost [Hz]','FontSize',S.fs);

    if panel == 1
        ylabel('formation RMSE [m]','FontSize',S.fs);
        legend('Location','northeast','FontSize',S.fs-3,'Box','off','NumColumns',2);
    end

    title(scN{panel},'FontSize',S.fs,'FontWeight','normal');

    set(gca,'FontSize',S.fs-1);

end

localSave(f, figDir, 'fig05_cost_pareto');

end


%% ============================================================
% FIG 6 - ACK impairment: adaptation, then saturation
% ============================================================

function fig06_ack_impairment(figDir, S)

E = localTidy('exp07b_ack_impairment');

cells = {'reliable','L10 D0','L10 D40','L10 D80','L20 D0','L20 D40', ...
         'L20 D80','L20 D=fwd'};

f = localFig(7.0, 3.2);

for panel = 1:2

    subplot(1,2,panel); hold on; grid on;

    scen = {'Moderate','Stressed'};
    scen = scen{panel};

    rate = nan(1,numel(cells));
    scale = nan(1,numel(cells));

    for k = 1:numel(cells)
        idx = strcmp(E.method,'Causal-v3') & strcmp(E.scenario,scen) & ...
              strcmp(E.ackCell,cells{k});
        if any(idx)
            rate(k)  = mean(E.TXRATE(idx),'omitnan');
            scale(k) = mean(E.MEANSCALE(idx),'omitnan');
        end
    end

    yyaxis left;
    plot(1:numel(cells), rate, '-o','Color',S.col.Causal, ...
        'MarkerFaceColor',S.col.Causal,'LineWidth',S.lw);
    ylabel('DATA rate per channel [Hz]','FontSize',S.fs);
    ylim([0 22]);
    set(gca,'YColor',S.col.Causal);

    yyaxis right;
    plot(1:numel(cells), scale, '-s','Color',S.col.Accent, ...
        'MarkerFaceColor',S.col.Accent,'LineWidth',S.lw);
    yline(0.20,'--','Color',[0.5 0.5 0.55],'LineWidth',1.0);
    ylabel('mean adaptive scale','FontSize',S.fs);
    ylim([0.15 0.45]);
    set(gca,'YColor',S.col.Accent);

    text(numel(cells)*0.55, 0.215, 'floor $s_{\min}=0.20$', ...
        'Interpreter','latex','FontSize',S.fs-2,'Color',[0.4 0.4 0.45]);

    set(gca,'XTick',1:numel(cells),'XTickLabel',cells, ...
        'XTickLabelRotation',40,'FontSize',S.fs-2.5);

    title(scen,'FontSize',S.fs,'FontWeight','normal');

end

localSave(f, figDir, 'fig06_ack_impairment');

end


%% ============================================================
% FIG 7 - topology generalization
% ============================================================

function fig07_topology(figDir, S)

E = localTidy('exp08a_topology');

f = localFig(7.0, 3.0);

topos = unique(E.topology);

mN   = {'P10','P20','State-event','Causal-v3'};
cols = [S.col.P10; S.col.P20; S.col.Event; S.col.Causal];

for panel = 1:2

    subplot(1,2,panel); hold on; grid on;

    scen = {'Moderate','Stressed'};
    scen = scen{panel};

    for iM = 1:4

        deg = []; rm = [];

        for t = 1:numel(topos)
            for Nv = {'10','20','50'}

                idx = strcmp(E.method,mN{iM}) & strcmp(E.scenario,scen) & ...
                      strcmp(E.topology,topos{t}) & strcmp(E.N,Nv{1});

                if ~any(idx)
                    continue;
                end

                deg(end+1) = mean(E.meanDegree(idx),'omitnan');   %#ok<AGROW>
                rm(end+1)  = mean(E.RMSE(idx),'omitnan');          %#ok<AGROW>

            end
        end

        [deg, o] = sort(deg);
        rm = rm(o);

        plot(deg, rm, ['-' S.mk{iM}], 'Color',cols(iM,:), ...
            'MarkerFaceColor',cols(iM,:),'MarkerSize',5,'LineWidth',1.1, ...
            'DisplayName',mN{iM});

    end

    xlabel('mean consensus in-degree','FontSize',S.fs);

    if panel == 1
        ylabel('formation RMSE [m]','FontSize',S.fs);
        legend('Location','northwest','FontSize',S.fs-2.5,'Box','off');
    end

    title(scen,'FontSize',S.fs,'FontWeight','normal');

    set(gca,'FontSize',S.fs-1);

end

localSave(f, figDir, 'fig07_topology');

end


%% ============================================================
% FIG 8 - fault response: traffic before, during and after
% ============================================================

function fig08_fault_response(figDir, S)

E = localTidy('exp08c_node_blackout');

mN   = {'P10','P20','State-event','Causal-v3'};
cols = [S.col.P10; S.col.P20; S.col.Event; S.col.Causal];

f = localFig(7.0, 3.0);

subplot(1,2,1); hold on; grid on;

sel = strcmp(E.fault,'1node 5s') & strcmp(E.topology,'ring2') & ...
      strcmp(E.N,'N20') & strcmp(E.scenario,'Stressed');

W = zeros(3,4);

for iM = 1:4
    idx = sel & strcmp(E.method,mN{iM});
    W(1,iM) = mean(E.DATAPRE(idx),'omitnan');
    W(2,iM) = mean(E.DATADUR(idx),'omitnan');
    W(3,iM) = mean(E.DATAPOST(idx),'omitnan');
end

b = bar(W,'grouped');

for iM = 1:4
    b(iM).FaceColor = cols(iM,:);
    b(iM).EdgeColor = 'none';
end

set(gca,'XTick',1:3,'XTickLabel',{'before','during','after'},'FontSize',S.fs-1);
ylabel('DATA rate in window [Hz]','FontSize',S.fs);
title('5 s node blackout, N=20, Stressed','FontSize',S.fs-0.5,'FontWeight','normal');
legend(mN,'Location','northwest','FontSize',S.fs-2.5,'Box','off');

subplot(1,2,2); hold on; grid on;

R = nan(1,4);
Rs = nan(1,4);

for iM = 1:4
    idx = sel & strcmp(E.method,mN{iM});
    v = E.RECOVERY(idx);
    v = v(isfinite(v));
    if ~isempty(v)
        R(iM)  = mean(v);
        Rs(iM) = std(v);
    end
end

for iM = 1:4
    bar(iM, R(iM), 'FaceColor',cols(iM,:),'EdgeColor','none');
    if isfinite(Rs(iM))
        errorbar(iM, R(iM), Rs(iM), 'Color',[0.25 0.25 0.3],'LineWidth',1.0);
    end
end

set(gca,'XTick',1:4,'XTickLabel',mN,'XTickLabelRotation',20,'FontSize',S.fs-1.5);
ylabel('recovery time [s]','FontSize',S.fs);
title('Return to the pre-fault error band','FontSize',S.fs-0.5,'FontWeight','normal');

localSave(f, figDir, 'fig08_fault_response');

end


%% ============================================================
% FIG 9 - double integrator against 6-DOF
% ============================================================

function fig09_di_vs_6dof(figDir, S)

E = localTidy('exp09a_multiuav_6dof');

mN   = {'P10','P20','State-event','Causal-v3'};
cols = [S.col.P10; S.col.P20; S.col.Event; S.col.Causal];
scN  = {'Clean','Moderate','Stressed'};

f = localFig(7.0, 3.0);

subplot(1,2,1); hold on; grid on;

for iM = 1:4

    di = zeros(1,3); sx = zeros(1,3);

    for iS = 1:3
        di(iS) = mean(E.RMSE(strcmp(E.mode,'DI') & strcmp(E.method,mN{iM}) & ...
            strcmp(E.scenario,scN{iS})),'omitnan');
        sx(iS) = mean(E.RMSE(strcmp(E.mode,'6DOF') & strcmp(E.method,mN{iM}) & ...
            strcmp(E.scenario,scN{iS})),'omitnan');
    end

    plot(di, sx, S.mk{iM}, 'MarkerSize',8,'MarkerEdgeColor',cols(iM,:), ...
        'MarkerFaceColor',cols(iM,:),'LineWidth',1.0,'DisplayName',mN{iM});

end

lim = [0 0.30];
plot(lim, lim, '--','Color',[0.55 0.55 0.6],'HandleVisibility','off');

xlabel('RMSE, double integrator [m]','FontSize',S.fs);
ylabel('RMSE, 6-DOF quadrotor [m]','FontSize',S.fs);
legend('Location','southeast','FontSize',S.fs-2.5,'Box','off');
title('Every method degrades; the ordering does not change', ...
    'FontSize',S.fs-1,'FontWeight','normal');
axis equal; xlim(lim); ylim(lim);

subplot(1,2,2); hold on; grid on;

D = zeros(3,4);

for iM = 1:4
    for iS = 1:3
        D(iS,iM) = mean(E.DATARATE(strcmp(E.mode,'6DOF') & ...
            strcmp(E.method,mN{iM}) & strcmp(E.scenario,scN{iS})),'omitnan');
    end
end

b = bar(D,'grouped');

for iM = 1:4
    b(iM).FaceColor = cols(iM,:);
    b(iM).EdgeColor = 'none';
end

set(gca,'XTick',1:3,'XTickLabel',scN,'FontSize',S.fs-1);
ylabel('DATA rate [Hz], 6-DOF','FontSize',S.fs);
title('Adaptation survives the plant change','FontSize',S.fs-1,'FontWeight','normal');

localSave(f, figDir, 'fig09_di_vs_6dof');

end


%% ============================================================
% FIG 10 - mismatch and estimator boundaries
% ============================================================

function fig10_mismatch_estimator(figDir, S)

B = localTidy('exp09b_physical_mismatch');
C = localTidy('exp09c_synthetic_estimator');

f = localFig(7.0, 3.2);

subplot(1,2,1); hold on; grid on;

arms = {'B0 nominal','B1 wind 0.5','B3 mass +10%','B5 drag +20%','B7 combined'};

v = zeros(1,numel(arms)); e = zeros(1,numel(arms));

for k = 1:numel(arms)
    idx = strcmp(B.arm,arms{k}) & strcmp(B.method,'Causal-v3') & ...
          strcmp(B.scenario,'Moderate');
    v(k) = mean(B.RMSE(idx),'omitnan');
    e(k) = std(B.RMSE(idx),'omitnan');
end

bar(1:numel(arms), v, 'FaceColor',S.col.Causal,'EdgeColor','none');
errorbar(1:numel(arms), v, e, 'k','LineStyle','none','LineWidth',1.0);

set(gca,'XTick',1:numel(arms),'XTickLabel',arms,'XTickLabelRotation',35, ...
    'FontSize',S.fs-2.5);
ylabel('formation RMSE [m]','FontSize',S.fs);
title(sprintf('Plant mismatch: the mass arm dominates,\nand no policy can remove a steady offset'), ...
    'FontSize',S.fs-1.5,'FontWeight','normal');

subplot(1,2,2); hold on; grid on;

carms = {'N0 noiseless','N1 .01/.02','N2 .03/.05','N3 .05/.10','C3 combined'};

d = zeros(1,numel(carms)); rr = zeros(1,numel(carms));

for k = 1:numel(carms)
    idx = strcmp(C.arm,carms{k}) & strcmp(C.method,'Causal-v3') & ...
          strcmp(C.scenario,'Clean');
    d(k)  = mean(C.DATARATE(idx),'omitnan');
    rr(k) = mean(C.RMSE(idx),'omitnan');
end

yyaxis left;
bar(1:numel(carms), d, 'FaceColor',[0.35 0.5 0.7],'EdgeColor','none');
ylabel('DATA rate [Hz], Clean','FontSize',S.fs);
set(gca,'YColor',[0.25 0.35 0.55]);

yline(2*d(1),'--','Color',[0.75 0.2 0.2],'LineWidth',1.2);
text(1.4, 2*d(1)*1.03, 'pre-registered $2\times$ bound', ...
    'Interpreter','latex','FontSize',S.fs-2,'Color',[0.75 0.2 0.2]);

yyaxis right;
plot(1:numel(carms), rr, '-o','Color',S.col.Causal, ...
    'MarkerFaceColor',S.col.Causal,'LineWidth',S.lw);
ylabel('RMSE [m]','FontSize',S.fs);
set(gca,'YColor',S.col.Causal);

set(gca,'XTick',1:numel(carms),'XTickLabel',carms,'XTickLabelRotation',35, ...
    'FontSize',S.fs-2.5);
title(sprintf('Estimator noise buys traffic, not accuracy:\nfalse triggers cross the bound'), ...
    'FontSize',S.fs-1.5,'FontWeight','normal');

localSave(f, figDir, 'fig10_mismatch_estimator');

end


%% ============================================================
% FIG 11 - holdout paired differences
% ============================================================

function fig11_paired_holdout(figDir, S)

A = localTidy('exp10a_final_validation');

nS = numel(unique(A.seed));

sel = strcmp(A.point,'NOMINAL') & strcmp(A.scenario,'Stressed');

pull = @(m,c) localSorted(A, sel & strcmp(A.method,m), c);

d1 = pull('Causal-v3','RMSE')     - pull('P10','RMSE');
d2 = pull('Causal-v3','DATARATE') - pull('P20','DATARATE');
d3 = pull('Causal-v3','TOTAL025') - pull('P20','TOTAL025');

K1 = pairedCI(pull('Causal-v3','RMSE'),     pull('P10','RMSE'),     nS);
K2a= pairedCI(pull('Causal-v3','DATARATE'), pull('P20','DATARATE'), nS);
K2b= pairedCI(pull('Causal-v3','TOTAL025'), pull('P20','TOTAL025'), nS);

f = localFig(7.0, 3.0);

panels = {d1, K1, 'K1: RMSE vs P10 [m]', S.col.Causal; ...
          d2, K2a,'K2a: DATA vs P20 [Hz]', S.col.P20; ...
          d3, K2b,'K2b: DATA+0.25ACK vs P20 [Hz]', S.col.Event};

for p = 1:3

    subplot(1,3,p); hold on; grid on;

    d = panels{p,1};
    K = panels{p,2};

    plot(1:numel(d), d, '.', 'Color',panels{p,4},'MarkerSize',9);

    yline(0,'-','Color',[0.3 0.3 0.35],'LineWidth',1.1);
    yline(K.meanD,'-','Color',panels{p,4},'LineWidth',1.4);

    yl = ylim;
    patch([0 numel(d)+1 numel(d)+1 0], [K.lo K.lo K.hi K.hi], ...
        panels{p,4}, 'FaceAlpha',0.15,'EdgeColor','none');
    ylim(yl);

    xlim([0 numel(d)+1]);

    xlabel('seed index','FontSize',S.fs-1);
    title(panels{p,3},'FontSize',S.fs-1.5,'FontWeight','normal');

    if p == 1
        ylabel('paired difference','FontSize',S.fs);
    end

    text(0.04, 0.06, sprintf('mean %+.3g\nCI [%+.3g, %+.3g]\nn=%d', ...
        K.meanD, K.lo, K.hi, K.nPairs), 'Units','normalized', ...
        'FontSize',S.fs-3,'VerticalAlignment','bottom');

    set(gca,'FontSize',S.fs-2);

end

localSave(f, figDir, 'fig11_paired_holdout');

end


%% ============================================================
% LOCAL HELPERS
% ============================================================

function T = localTidy(expName)

r = projectRoot();

runId = strtrim(fileread(fullfile(r,'results',expName,'LATEST.txt')));

T = readtable(fullfile(r,'results',expName,runId,'tidy.csv'),'TextType','char');

end


function r = localURow(U, point, scen, method)

idx = strcmp(U.point,point) & strcmp(U.scenario,scen) & strcmp(U.method,method);

r = U(idx,:);

end


function v = localSorted(A, sel, col)

T = A(sel,:);
T = sortrows(T,'seed');
v = T.(col);

end


function f = localFig(wIn, hIn)

f = figure('Units','inches','Position',[1 1 wIn hIn], ...
    'Color','w','PaperPositionMode','auto');

end


function localSave(f, figDir, name)

pdfPath = fullfile(figDir, [name '.pdf']);
pngPath = fullfile(figDir, [name '.png']);

try
    exportgraphics(f, pdfPath, 'ContentType','vector','BackgroundColor','white');
    exportgraphics(f, pngPath, 'Resolution',200,'BackgroundColor','white');
catch err
    fprintf(2, '  %s: export failed (%s)\n', name, err.message);
end

close(f);

fprintf('  %s\n', name);

end


function localArrow(x1, y1, x2, y2, col, lw)

annotation('arrow', 'HeadStyle','vback2','HeadLength',5,'HeadWidth',5, ...
    'Color',col,'LineWidth',lw, ...
    'Position', localToNorm(x1,y1,x2-x1,y2-y1));

end


function localArrow2(x1, y1, x2, y2, col, lw)

plot([x1 x2],[y1 y2],'-','Color',col,'LineWidth',lw);

dx = x2-x1; dy = y2-y1;
L  = hypot(dx,dy);
ux = dx/L; uy = dy/L;

hl = 0.16*L;

px = -uy; py = ux;

plot([x2, x2-hl*ux+0.35*hl*px, x2-hl*ux-0.35*hl*px, x2], ...
     [y2, y2-hl*uy+0.35*hl*py, y2-hl*uy-0.35*hl*py, y2], ...
     '-','Color',col,'LineWidth',lw);

end


function localArrowDashed(x1, y1, x2, y2, col, lw)

plot([x1 x2],[y1 y2],'--','Color',col,'LineWidth',lw);

end


function pos = localToNorm(x, y, dx, dy)

ax = gca;

xl = xlim(ax); yl = ylim(ax);

p = get(ax,'Position');

nx = p(1) + (x - xl(1))/diff(xl)*p(3);
ny = p(2) + (y - yl(1))/diff(yl)*p(4);

ndx = dx/diff(xl)*p(3);
ndy = dy/diff(yl)*p(4);

pos = [nx ny ndx ndy];

end
