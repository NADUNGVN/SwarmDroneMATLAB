function [pass,audit] = tcnsO1PeriodicIdentityAudit( ...
    raw,scenarioIds,seeds)
%TCNSO1PERIODICIDENTITYAUDIT Compare O1 periodic rows to frozen Gate 6.

archivePath = fullfile(projectRoot(),'results', ...
    'tcns_gate6_nonstationary_frontiers','2026-09-07_012209','tidy.csv');
archive = readtable(archivePath,'TextType','string');
archive.scenarioId = string(archive.scenarioId);
archive.armId = string(archive.armId);
current = raw(raw.methodFamily=="Periodic" & ...
    ismember(raw.scenarioId,scenarioIds),:);
archive = archive(archive.methodFamily=="Periodic" & ...
    ismember(archive.scenarioId,scenarioIds) & ...
    ismember(archive.seed,seeds),:);
current = sortrows(current,{'scenarioId','armId','seed'});
archive = sortrows(archive,{'scenarioId','armId','seed'});
fields = ["formationRMSE_m","primaryFormationRMSE_m", ...
    "evaluationCost025PerChannel_Hz","txCount","traceHashExact"];
rows = repmat(struct('metric',"",'maxAbsoluteDifference',NaN, ...
    'tolerance',NaN,'pass',false),numel(fields),1);
sameKeys = height(current)==height(archive) && ...
    isequal(current.scenarioId,archive.scenarioId) && ...
    isequal(current.armId,archive.armId) && ...
    isequal(current.seed,archive.seed);
for q = 1:numel(fields)
    rows(q).metric = fields(q);
    if sameKeys
        rows(q).maxAbsoluteDifference = max(abs( ...
            double(current.(fields(q)))-double(archive.(fields(q)))));
    end
    if ismember(fields(q),["txCount","traceHashExact"])
        rows(q).tolerance = 0;
    else
        rows(q).tolerance = 5e-12;
    end
    rows(q).pass = sameKeys && ...
        rows(q).maxAbsoluteDifference<=rows(q).tolerance;
end
audit = struct2table(rows);
pass = sameKeys && all(audit.pass);

end
