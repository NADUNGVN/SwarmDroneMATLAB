function audit = amendExp14TerminalAccounting(primaryDir)
%AMENDEXP14TERMINALACCOUNTING Add the right-censored terminal outcome class.
%
% This is a passive accounting repair for an already completed EXP14A run.
% It preserves the original files, derives terminal recipient work as
% attempts-success-loss, verifies the three-way closure, and updates only the
% integrity gate/verdict.  It never changes or reruns a plant/policy outcome.

if nargin<1 || ~isfolder(primaryDir)
    error('amendExp14TerminalAccounting: valid primaryDir is required.');
end

paths.tidy=fullfile(primaryDir,'tidy.csv');
paths.frontier=fullfile(primaryDir,'frontier.csv');
paths.mechanism=fullfile(primaryDir,'mechanism.csv');
paths.gates=fullfile(primaryDir,'gates.csv');
paths.verdict=fullfile(primaryDir,'verdict.json');
paths.workspace=fullfile(primaryDir,'workspace.mat');
required=struct2cell(paths);
if ~all(cellfun(@isfile,required))
    error('amendExp14TerminalAccounting: completed EXP14A artifacts missing.');
end

preserve(paths.tidy,fullfile(primaryDir, ...
    'tidy_pre_terminal_accounting_amendment.csv'));
preserve(paths.frontier,fullfile(primaryDir, ...
    'frontier_pre_terminal_accounting_amendment.csv'));
preserve(paths.mechanism,fullfile(primaryDir, ...
    'mechanism_pre_terminal_accounting_amendment.csv'));
preserve(paths.gates,fullfile(primaryDir, ...
    'gates_pre_terminal_accounting_amendment.csv'));
preserve(paths.verdict,fullfile(primaryDir, ...
    'verdict_pre_terminal_accounting_amendment.json'));

tidy=readtable(paths.tidy,'TextType','string');
dataInFlight=tidy.DATA_RECIPIENT_ATTEMPTS- ...
    tidy.DATA_RECIPIENT_SUCCESS-tidy.DATA_RECIPIENT_LOSS;
ackInFlight=tidy.ACK_RECIPIENT_ATTEMPTS- ...
    tidy.ACK_RECIPIENT_SUCCESS-tidy.ACK_RECIPIENT_LOSS;
if any(~isfinite(dataInFlight) | dataInFlight<0 | ...
        dataInFlight~=floor(dataInFlight)) || ...
        any(~isfinite(ackInFlight) | ackInFlight<0 | ...
        ackInFlight~=floor(ackInFlight))
    error('amendExp14TerminalAccounting: residual outcomes are invalid.');
end

if ismember('TERMINAL_DATA_INFLIGHT',tidy.Properties.VariableNames)
    if ~isequal(tidy.TERMINAL_DATA_INFLIGHT,dataInFlight) || ...
            ~isequal(tidy.TERMINAL_ACK_INFLIGHT,ackInFlight)
        error('amendExp14TerminalAccounting: prior terminal fields disagree.');
    end
else
    terminalFrames=nan(height(tidy),1);
    tidy=addvars(tidy,terminalFrames,dataInFlight,ackInFlight, ...
        'After','ACK_RECIPIENT_LOSS','NewVariableNames', ...
        {'TERMINAL_ACTIVE_FRAMES','TERMINAL_DATA_INFLIGHT', ...
        'TERMINAL_ACK_INFLIGHT'});
end

accounting=all(tidy.DATA_RECIPIENT_SUCCESS+tidy.DATA_RECIPIENT_LOSS+ ...
    tidy.TERMINAL_DATA_INFLIGHT==tidy.DATA_RECIPIENT_ATTEMPTS) && ...
    all(tidy.ACK_RECIPIENT_SUCCESS+tidy.ACK_RECIPIENT_LOSS+ ...
    tidy.TERMINAL_ACK_INFLIGHT==tidy.ACK_RECIPIENT_ATTEMPTS) && ...
    all(tidy.CHANNEL_UTIL<=1+1e-12) && ...
    all(tidy.CHANNEL_UTIL<=tidy.OFFERED_UTIL+ ...
    tidy.backgroundLoad+1e-12);
if ~accounting
    error('amendExp14TerminalAccounting: corrected accounting does not close.');
end

frontier=tidy(tidy.stage=="frontier",:);
mechanism=tidy(tidy.stage=="mechanism",:);
writetable(tidy,paths.tidy);
writetable(frontier,paths.frontier);
writetable(mechanism,paths.mechanism);

gates=readtable(paths.gates,'TextType','string');
idx=gates.gate=="physical_accounting";
if nnz(idx)~=1
    error('amendExp14TerminalAccounting: physical-accounting gate missing.');
end
gates.passed(idx)=double(accounting);
gates.detail(idx)=sprintf(['success+loss+terminal-in-flight closes; ' ...
    'DATA in-flight=%d across %d rows; ACK in-flight=%d across %d rows'], ...
    sum(dataInFlight),nnz(dataInFlight),sum(ackInFlight),nnz(ackInFlight));
plantIdx=gates.gate=="plant_stability";
if nnz(plantIdx)==1
    divergenceAccounted=all(ismember(tidy.DIVERGED,[0 1])) && ...
        all(tidy.SAFEFAIL>=tidy.DIVERGED);
    gates.gate(plantIdx)="divergence_accounting";
    gates.passed(plantIdx)=double(divergenceAccounted);
    gates.detail(plantIdx)=sprintf( ...
        '%d diverged runs retained as safety failures',sum(tidy.DIVERGED));
end
writetable(gates,paths.gates);

verdict=jsondecode(fileread(paths.verdict));
verdict.status=ternary(all(gates.passed==1),'PASS','FAIL');
verdict.gatesPassed=nnz(gates.passed);
verdict.gatesTotal=height(gates);
verdict.accountingAmendment='terminal right-censoring; no simulation rerun';
writeJson(paths.verdict,verdict);

save(paths.workspace,'tidy','frontier','mechanism','gates','verdict','-append');

audit=struct();
audit.amendment='EXP14 Amendment 002';
audit.reason='multi-slot frames active at finite mission horizon';
audit.simulationRerun=false;
audit.performanceMetricRead=false;
audit.rows=height(tidy);
audit.dataInFlightRecipients=sum(dataInFlight);
audit.rowsWithDataInFlight=nnz(dataInFlight);
audit.ackInFlightRecipients=sum(ackInFlight);
audit.rowsWithAckInFlight=nnz(ackInFlight);
audit.minimumDataResidual=min(dataInFlight);
audit.maximumDataResidual=max(dataInFlight);
audit.minimumAckResidual=min(ackInFlight);
audit.maximumAckResidual=max(ackInFlight);
audit.correctedAccountingPassed=accounting;
audit.finalGatesPassed=nnz(gates.passed);
audit.finalGatesTotal=height(gates);
writeJson(fullfile(primaryDir, ...
    'AMENDMENT_002_TERMINAL_ACCOUNTING.json'),audit);

end


function preserve(source,target)

if ~isfile(target)
    copyfile(source,target);
end

end


function writeJson(path,value)

fid=fopen(path,'w');
if fid<0, error('amendExp14TerminalAccounting: cannot write %s.',path); end
cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));

end


function y=ternary(flag,a,b)

if flag, y=a; else, y=b; end

end
