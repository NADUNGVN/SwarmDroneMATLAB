function report = paper_audit()
%PAPER_AUDIT Publication consistency audit. Writes paper/AUDIT_REPORT.md.
%
% Rules are PASS or FAIL, each with the reason it exists. The audit
% is the last line of defence between a frozen result set and a manuscript
% that overstates it, so a rule that cannot be checked mechanically is
% marked MANUAL rather than quietly passed.
%
% RUNS NO SIMULATION and writes only paper/AUDIT_REPORT.md. On systems
% where MATLAB execution is prohibited, paper/scripts/paper_audit.ps1 is
% the static entry point and also verifies the separately frozen EXP11
% artifacts.

startup;

root = projectRoot();

paperDir = fullfile(root,'paper');

R = struct('id',{},'name',{},'status',{},'detail',{},'why',{});

    function addRule(id, name, pass, detail, why)
        if ischar(pass)
            st = pass;
        elseif pass
            st = 'PASS';
        else
            st = 'FAIL';
        end
        R(end+1) = struct('id',id,'name',name,'status',st, ...
            'detail',detail,'why',why);
    end

fprintf('\n');
fprintf('============================================================\n');
fprintf('paper_audit\n');
fprintf('============================================================\n\n');


%% ============================================================
% Load the manuscript text and the generated artefacts
% ============================================================

texFiles = [ ...
    {fullfile(paperDir,'main.tex')}; ...
    localList(fullfile(paperDir,'sections'),'*.tex')];

prose = '';

for k = 1:numel(texFiles)
    prose = [prose newline fileread(texFiles{k})];   %#ok<AGROW>
end

genTex = fullfile(paperDir,'generated','metrics.tex');
genCsv = fullfile(paperDir,'generated','headline_metrics.csv');

haveGen = exist(genTex,'file')==2 && exist(genCsv,'file')==2;


%% ============================================================
% RULE 1 - every numeric headline is a generated macro
%
% A number typed into prose is a number nobody can check. The rule
% tolerates small structural integers (swarm sizes, section counts,
% timesteps written inside math) and looks for the shape that matters:
% a multi-decimal figure sitting in the text.
% ============================================================

if haveGen

    macroDefs = regexp(fileread(genTex), 'newcommand\{\\([A-Za-z]+)\}', ...
        'tokens');

    macroNames = cellfun(@(c) c{1}, macroDefs, 'UniformOutput', false);

    % Strip everything a stray decimal may legitimately live in.
    %
    % The LaTeX preamble goes first: a margin of 0.75in or a 10pt class
    % option is typography, not a result, and flagging it would train a
    % reader to ignore this rule.
    stripped = regexprep(prose, '.*?\\begin\{document\}', '', 'once');
    stripped = regexprep(stripped, '%[^\n]*', '');              % comments
    stripped = regexprep(stripped, '\\input\{[^}]*\}', '');      % table pulls
    stripped = regexprep(stripped, '\\label\{[^}]*\}', '');
    stripped = regexprep(stripped, '\\ref\{[^}]*\}', '');
    stripped = regexprep(stripped, '\\includegraphics[^\n]*', '');
    stripped = regexprep(stripped, '\\Metric[A-Za-z]+', '');     % macros
    stripped = regexprep(stripped, '\\eqref\{[^}]*\}', '');

    % A "hard-coded result" is a number with two or more decimals, or any
    % number with a decimal point next to a unit we report in.
    hits = regexp(stripped, '(?<![\\A-Za-z0-9])\d+\.\d\d+', 'match');

    % Allowed literals are DEFINITIONS, not measurements: a locked
    % parameter, a cost weight, a network condition, or the exact rate a
    % periodic baseline transmits at by construction. Each is a number the
    % method or protocol fixes in advance, so there is no frozen result
    % for it to drift away from.
    %
    %   0.99             the 1 % Pareto dominance margin
    %   0.10 0.25 0.50   ACK cost weights
    %   0.20 0.40        packet loss in the Moderate and Stressed conditions
    %   0.08 0.12        network delay in those conditions
    %   0.01 0.02 0.04   outer timesteps of the dt diagnostic
    %   0.05 1.00        trigger threshold and adaptation range
    %   0.975            the two-sided 95 % quantile level
    %   10.00 20.00      per-channel rates of P10 and P20, by definition
    allow = {'0.99','0.25','0.50','0.10','0.20','0.40','0.02','0.01', ...
             '0.04','0.05','1.00','0.12','0.08','0.975','10.00','20.00'};

    hits = hits(~ismember(hits, allow));

    addRule('A1','every numeric headline is a generated macro', ...
        isempty(hits), ...
        sprintf('%d hard-coded numeric literal(s) outside the allow list%s', ...
            numel(hits), localFirstFew(hits)), ...
        ['A number typed into prose cannot be checked against the ' ...
         'frozen data and will silently go stale when a dataset is ' ...
         'regenerated.']);

else

    addRule('A1','every numeric headline is a generated macro', false, ...
        'generated/metrics.tex or headline_metrics.csv is missing', ...
        'The audit cannot verify traceability without the generated files.');

end


%% ============================================================
% RULE 2 - every macro used is defined
% ============================================================

if haveGen

    used = regexp(prose, '\\(Metric[A-Za-z]+)', 'tokens');
    used = unique(cellfun(@(c) c{1}, used, 'UniformOutput', false));

    undef = setdiff(used, macroNames);

    addRule('A2','every metric macro used in the text is defined', ...
        isempty(undef), ...
        sprintf('%d used, %d defined, %d undefined%s', ...
            numel(used), numel(macroNames), numel(undef), ...
            localFirstFew(undef)), ...
        'An undefined macro is a LaTeX build failure, or worse, an empty gap.');

else
    addRule('A2','every metric macro used in the text is defined', false, ...
        'generated files missing', 'see A1');
end


%% ============================================================
% RULE 3 - macro names are LaTeX-legal
% ============================================================

if haveGen

    bad = macroNames(~cellfun(@(n) all(isletter(n)), macroNames));

    addRule('A3','generated macro names are letters-only', ...
        isempty(bad), ...
        sprintf('%d illegal name(s)%s', numel(bad), localFirstFew(bad)), ...
        'LaTeX rejects digits and underscores in a command name.');

else
    addRule('A3','generated macro names are letters-only', false, ...
        'generated files missing', 'see A1');
end


%% ============================================================
% RULE 4 - every figure and table referenced exists
% ============================================================

figRefs = regexp(prose, '\\includegraphics\[[^\]]*\]\{([A-Za-z0-9_]+)\}', ...
    'tokens');
figRefs = unique(cellfun(@(c) c{1}, figRefs, 'UniformOutput', false));

missingFig = {};

for k = 1:numel(figRefs)
    p = fullfile(paperDir,'figures',[figRefs{k} '.pdf']);
    if exist(p,'file') ~= 2
        missingFig{end+1} = figRefs{k};   %#ok<AGROW>
    end
end

tabRefs = regexp(prose, '\\input\{(tables/[A-Za-z0-9_]+)\}', 'tokens');
tabRefs = unique(cellfun(@(c) c{1}, tabRefs, 'UniformOutput', false));

missingTab = {};

for k = 1:numel(tabRefs)
    p = fullfile(paperDir,[tabRefs{k} '.tex']);
    if exist(p,'file') ~= 2
        missingTab{end+1} = tabRefs{k};   %#ok<AGROW>
    end
end

addRule('A4','every referenced figure and table file exists', ...
    isempty(missingFig) && isempty(missingTab), ...
    sprintf('%d figure(s) and %d table(s) referenced; %d missing%s%s', ...
        numel(figRefs), numel(tabRefs), ...
        numel(missingFig)+numel(missingTab), ...
        localFirstFew(missingFig), localFirstFew(missingTab)), ...
    'A missing artefact becomes a blank box that a reader reads as an omission.');


%% ============================================================
% RULE 5 - no REJECTED claim appears as supported
%
% Checked as forbidden phrasings rather than as semantics: each pattern
% is a sentence shape that would assert a rejected claim.
% ============================================================

forbidden = { ...
    'Pareto superior',              'R1 Stressed ACK-inclusive Pareto superiority was rejected'; ...
    'universally superior',         'no universal superiority is claimed'; ...
    'universal superiority over',   'no universal superiority is claimed'; ...
    'safety is guaranteed',         'R3/R4 absolute safety under fault was rejected'; ...
    'guarantees safety',            'R3/R4 absolute safety under fault was rejected'; ...
    'robust to plant mismatch',     'R5 absolute mismatch robustness was rejected'; ...
    'invariant to the timestep',    'R7 DATA-rate dt invariance was rejected'; ...
    'dt-invariant',                 'R7 DATA-rate dt invariance was rejected'; ...
    'fully decentralized without feedback', 'the policy depends on the ACK reverse channel'; ...
    'fully decentralised without feedback', 'the policy depends on the ACK reverse channel'; ...
    'without feedback',             'the policy is ACK-assisted; "without feedback" is false'; ...
    'validated on hardware',        'R1 no hardware validation exists'; ...
    'hardware validation confirms',  'R1 no hardware validation exists'};

% Scoped to the SENTENCE, and denial-aware. Every one of these phrases
% legitimately appears in this manuscript inside a sentence that denies
% or reports the rejection of the claim -- "we do not claim universal
% superiority over...", "a claim of Stressed Pareto superiority was
% tested and rejected". A bare substring search flags exactly the
% sentences that are doing the right thing, so the rule has to read the
% sentence around the phrase.
viol5 = {};

sent5 = localSentences(prose);

for k = 1:size(forbidden,1)

    for s5 = 1:numel(sent5)

        snt = sent5{s5};

        if ~contains(lower(snt), lower(forbidden{k,1}))
            continue;
        end

        if localDenies(snt, forbidden{k,1})
            continue;
        end

        viol5{end+1} = sprintf('"%s" asserted in: %s', ...
            forbidden{k,1}, localTrim(snt));   %#ok<AGROW>

    end

end

addRule('A5','no rejected claim appears as supported', ...
    isempty(viol5), ...
    sprintf('%d forbidden phrasing(s)%s', numel(viol5), localFirstFew(viol5)), ...
    ['Seven claims were pre-registered, tested and rejected. A phrasing ' ...
     'that asserts one of them turns a recorded negative result into a ' ...
     'false positive.']);


%% ============================================================
% RULE 6 - no unqualified communication-saving claim
%
% The campaign's central honesty requirement: DATA falls against P20 and
% the ACK-inclusive total rises, both with intervals excluding zero.
% ============================================================

savingPhrases = { ...
    'reduces communication', 'reduction in communication', ...
    'communication saving', 'communication savings', ...
    'saves communication', 'lower communication cost', ...
    'reduces traffic', 'traffic reduction', 'more efficient communication'};

qualifiers = {'DATA', 'ACK-inclusive', 'ACK inclusive', 'DATA-packet', ...
              'DATA-only'};

viol6 = {};

sentences = localSentences(prose);

for s = 1:numel(sentences)

    snt = sentences{s};

    hasSaving = any(cellfun(@(p) contains(lower(snt), lower(p)), savingPhrases));

    if ~hasSaving
        continue;
    end

    hasQual = any(cellfun(@(q) contains(snt, q), qualifiers));

    % A sentence that explicitly denies the claim is fine.
    denies = contains(lower(snt), {'not a reduction','no reduction', ...
        'not the cheapest','must not','never','do not claim','not a saving'});

    if ~hasQual && ~denies
        viol6{end+1} = localTrim(snt);   %#ok<AGROW>
    end

end

addRule('A6','no unqualified communication-saving claim', ...
    isempty(viol6), ...
    sprintf('%d unqualified saving sentence(s)%s', ...
        numel(viol6), localFirstFew(viol6)), ...
    ['DATA falls against P20 by 16.73 Hz while the ACK-inclusive total ' ...
     'rises by 10.67 Hz, both intervals excluding zero. An unqualified ' ...
     'saving claim is contradicted by the frozen data.']);


%% ============================================================
% RULE 7 - the ACK-impairment result carries its saturation qualifier
% ============================================================

mentionsAckImp = contains(prose, 'ACK impairment') || ...
                 contains(prose, 'reverse-channel impairment') || ...
                 contains(prose, 'ACK loss');

hasSaturation = contains(lower(prose), 'saturat');

addRule('A7','ACK-impairment tolerance is qualified as saturation', ...
    ~mentionsAckImp || hasSaturation, ...
    sprintf('mentions impairment: %s; explains saturation: %s', ...
        localYesNo(mentionsAckImp), localYesNo(hasSaturation)), ...
    ['EXP07B shows identical Stressed error and rate with and without ' ...
     '20 %% ACK loss because the adaptive scale is pinned at its floor. ' ...
     'Reporting flatness as robustness would invert the mechanism.']);


%% ============================================================
% RULE 8 - the mismatch failure is not attributed to communication
% ============================================================

mentionsMismatch = contains(prose, 'mismatch');

hasAttribution = contains(lower(prose), 'integral action') || ...
                 contains(lower(prose), 'controller limitation');

% Denial-aware for the same reason as A5: the discussion says "calling
% this a communication failure would be wrong", which is the correct
% attribution and must not be flagged as the wrong one.
badAttrib = false;

sent8 = localSentences(prose);

for s8 = 1:numel(sent8)
    if contains(lower(sent8{s8}), 'communication failure') && ...
            ~localDenies(sent8{s8}, 'communication failure')
        badAttrib = true;
    end
end

addRule('A8','plant-mismatch failure attributed to the controller', ...
    (~mentionsMismatch || hasAttribution) && ~badAttrib, ...
    sprintf('mentions mismatch: %s; states controller attribution: %s; uses "communication failure": %s', ...
        localYesNo(mentionsMismatch), localYesNo(hasAttribution), ...
        localYesNo(badAttrib)), ...
    ['The B7 degradation is a steady offset from a proportional loop with ' ...
     'no integral term, identical across all four methods. Calling it a ' ...
     'communication failure would misattribute it.']);


%% ============================================================
% RULE 9 - claim ledger covers FINAL_CLAIMS, and rejected claims survive
% ============================================================

ledgerPath = fullfile(paperDir,'CLAIM_LEDGER.md');
finalPath  = fullfile(root,'docs','FINAL_CLAIMS.md');

if exist(ledgerPath,'file')==2 && exist(finalPath,'file')==2

    ledger = fileread(ledgerPath);

    needGroups = {'SUPPORTED','LIMITED / CONDITIONAL','REJECTED'};

    haveGroups = all(cellfun(@(g) contains(ledger,g), needGroups));

    % Every rejection named in FINAL_CLAIMS must appear in the ledger.
    % Each entry is a set of accepted spellings for one rejection topic;
    % the topic counts as present if any spelling appears. The campaign
    % uses "link fault" and "link-fault" interchangeably.
    rejKeys = { ...
        {'pareto superiority'}, ...
        {'topology'}, ...
        {'link-fault','link fault','link failure'}, ...
        {'blackout'}, ...
        {'mismatch'}, ...
        {'noise'}, ...
        {'dt'}};

    present = cellfun(@(alts) any(cellfun(@(a) contains(lower(ledger), a), alts)), ...
        rejKeys);

    missingRej = cellfun(@(alts) alts{1}, rejKeys(~present), ...
        'UniformOutput', false);

    nRejRows = numel(regexp(ledger, '\| R\d+ \|', 'match'));

    addRule('A9','claim ledger has all three groups and preserves rejections', ...
        haveGroups && isempty(missingRej) && nRejRows >= 7, ...
        sprintf('groups present: %s; rejection rows: %d; missing topics: %d%s', ...
            localYesNo(haveGroups), nRejRows, numel(missingRej), ...
            localFirstFew(missingRej)), ...
        ['The ledger is what a reader checks a claim against. A rejection ' ...
         'missing from it is a rejection that has quietly disappeared.']);

else
    addRule('A9','claim ledger has all three groups and preserves rejections', ...
        false, 'CLAIM_LEDGER.md or docs/FINAL_CLAIMS.md missing', ...
        'see above');
end


%% ============================================================
% RULE C1..C5 - citation integrity
%
% Added for paper-v2, when the bibliography stopped being empty. An
% unverified or dangling citation is the one manuscript defect a reader
% cannot detect and cannot forgive.
% ============================================================

bibPath   = fullfile(paperDir,'references.bib');
auditPath = fullfile(paperDir,'REFERENCE_AUDIT.csv');

haveBib = exist(bibPath,'file')==2 && exist(auditPath,'file')==2;

if haveBib

    bibTxt = fileread(bibPath);

    bibKeys = regexp(bibTxt, '@(?:article|inproceedings|book|inbook|misc)\{([A-Za-z0-9_]+),', 'tokens');
    bibKeys = unique(cellfun(@(c) c{1}, bibKeys, 'UniformOutput', false));

    citeRaw = regexp(prose, '\cite\{([^}]*)\}', 'tokens');

    citeKeys = {};

    for k = 1:numel(citeRaw)
        parts = strsplit(citeRaw{k}{1}, ',');
        for q = 1:numel(parts)
            key = strtrim(parts{q});
            if ~isempty(key)
                citeKeys{end+1} = key;   %#ok<AGROW>
            end
        end
    end

    citeKeys = unique(citeKeys);

    % ---- C1: every \cite key exists in the bib ----
    dangling = setdiff(citeKeys, bibKeys);

    addRule('C1','every cite key exists in references.bib', ...
        isempty(dangling), ...
        sprintf('%d keys cited, %d defined, %d dangling%s', ...
            numel(citeKeys), numel(bibKeys), numel(dangling), ...
            localFirstFew(dangling)), ...
        ['A dangling citekey renders as a bold [?] and tells a reviewer ' ...
         'the bibliography was never built.']);

    % ---- C2: DOIs unique ----
    doiTok = regexp(bibTxt, 'doi\s*=\s*\{([^}]*)\}', 'tokens');
    dois = lower(cellfun(@(c) strtrim(c{1}), doiTok, 'UniformOutput', false));

    [uq, ~, idx] = unique(dois);
    counts = accumarray(idx(:), 1);
    dupDoi = uq(counts > 1);

    addRule('C2','bibliography DOIs are unique', ...
        isempty(dupDoi), ...
        sprintf('%d DOIs, %d duplicated%s', numel(dois), numel(dupDoi), ...
            localFirstFew(dupDoi)), ...
        ['A duplicated DOI means the same work is cited twice under two ' ...
         'keys, which inflates the reference count and misleads a reader ' ...
         'about coverage.']);

    % ---- C3: no placeholder citation anywhere ----
    placeholders = {'\cite{}', 'TODO citation', 'CITATION NEEDED', ...
                    'RELATED_WORK_NEEDS', 'CITE?', '\cite{TODO}', ...
                    '\cite{xxx}', 'FIXME'};

    foundPh = {};

    for k = 1:numel(placeholders)
        if contains(prose, placeholders{k})
            foundPh{end+1} = placeholders{k};   %#ok<AGROW>
        end
    end

    addRule('C3','no placeholder citation or TODO marker in the manuscript', ...
        isempty(foundPh), ...
        sprintf('%d placeholder marker(s)%s', numel(foundPh), ...
            localFirstFew(foundPh)), ...
        ['A placeholder that survives to submission is indistinguishable ' ...
         'from an oversight, and RELATED_WORK_NEEDS is a planning file ' ...
         'that must never appear in the prose.']);

    % ---- C4: every cited paper is in REFERENCE_AUDIT.csv ----
    A = readtable(auditPath, 'TextType','char', 'Delimiter',',');

    auditKeys = A.citekey;

    if ~iscell(auditKeys)
        auditKeys = cellstr(auditKeys);
    end

    notAudited  = setdiff(citeKeys, auditKeys);
    notInBib    = setdiff(auditKeys', bibKeys);

    addRule('C4','every cited and every bib entry appears in REFERENCE_AUDIT.csv', ...
        isempty(notAudited) && isempty(notInBib), ...
        sprintf('%d audit rows; %d cited-but-unaudited, %d audited-but-absent-from-bib%s%s', ...
            numel(auditKeys), numel(notAudited), numel(notInBib), ...
            localFirstFew(notAudited), localFirstFew(notInBib)), ...
        ['The audit CSV is where the verification status and the supported ' ...
         'claim live. A reference missing from it has neither.']);

    % ---- C5: every audit row is VERIFIED ----
    stat = A.verificationStatus;

    if ~iscell(stat)
        stat = cellstr(stat);
    end

    notVerified = auditKeys(~startsWith(stat, 'VERIFIED'));

    if ~iscell(notVerified)
        notVerified = cellstr(notVerified);
    end

    addRule('C5','every bibliography entry has verificationStatus VERIFIED', ...
        isempty(notVerified), ...
        sprintf('%d of %d rows not VERIFIED%s', numel(notVerified), ...
            numel(auditKeys), localFirstFew(notVerified)), ...
        ['An unverified reference is a reference whose author list, year, ' ...
         'venue or DOI nobody has checked against the publisher record. ' ...
         'Nine given names were wrong before this check existed.']);

    % ---- C6: unused verified references WARN, never FAIL ----
    unusedRef = setdiff(bibKeys, citeKeys);

    if isempty(unusedRef)
        st6 = 'PASS';
    else
        st6 = 'WARN';
    end

    addRule('C6','no verified reference is left uncited', st6, ...
        sprintf('%d verified but uncited%s', numel(unusedRef), ...
            localFirstFew(unusedRef)), ...
        ['A verified-but-uncited entry is bibliography padding rather than ' ...
         'an error, so this warns and does not fail.']);

    % ---- C7: no "first" claim ----
    firstClaims = {};

    sentF = localSentences(prose);

    % Precise priority phrasings only. An earlier version matched
    % 'the first ' and flagged "the first two numbers" and "on the first
    % transmission", neither of which is a priority claim. A rule that
    % cries wolf on ordinary ordinals gets switched off, so it is narrowed
    % to constructions that actually assert precedence.
    firstPatterns = {'first-ever', 'first ever', ...
                     'we are the first', 'are the first to', ...
                     'is the first to', 'the first work', ...
                     'the first paper', 'the first method', ...
                     'the first policy', 'the first approach', ...
                     'for the first time'};

    for s7 = 1:numel(sentF)
        for k = 1:numel(firstPatterns)
            if contains(lower(sentF{s7}), firstPatterns{k}) && ...
                    ~localDenies(sentF{s7}, firstPatterns{k})
                firstClaims{end+1} = localTrim(sentF{s7});   %#ok<AGROW>
            end
        end
    end

    addRule('C8','no priority ("first") claim', ...
        isempty(firstClaims), ...
        sprintf('%d priority claim(s)%s', numel(firstClaims), ...
            localFirstFew(firstClaims)), ...
        ['A Crossref-indexed, English-language keyword search cannot ' ...
         'support a priority claim, and NOVELTY_GAP_REVIEW.md records that ' ...
         'explicitly.']);

else

    addRule('C1','citation integrity', false, ...
        'references.bib or REFERENCE_AUDIT.csv is missing', ...
        'Citation integrity cannot be checked without both files.');

end


%% ============================================================
% RULE 10 - the frozen simulation source is untouched
% ============================================================

g = paper_guard(false);

addRule('A10','frozen simulation source untouched on this branch', ...
    g.pass, ...
    sprintf('%d path(s) changed since simulation-v1.0, %d under read-only paths%s', ...
        numel(g.changedSinceFreeze), numel(g.violations), ...
        localFirstFew(g.violations)), ...
    ['A figure or table that required editing a simulator is not a ' ...
     'statement about the frozen campaign.']);


%% ============================================================
% RULE 11 - rate normalisation is labelled wherever it is used
% ============================================================

mentionsPerChannel = contains(prose,'per channel');
mentionsSwarmTotal = contains(prose,'swarm total') || contains(prose,'swarm totals');

addRule('A11','both rate normalisations are labelled', ...
    mentionsPerChannel && mentionsSwarmTotal, ...
    sprintf('"per channel" present: %s; "swarm total" present: %s', ...
        localYesNo(mentionsPerChannel), localYesNo(mentionsSwarmTotal)), ...
    ['EXP07 reports per-channel Hz (P10 = 10.00) and EXP08 onward report ' ...
     'swarm totals (P10 = 99.67 at N=5), on different channel counts. ' ...
     'An unlabelled rate invites a false comparison.']);


%% ============================================================
% Manual rules - stated, not silently passed
% ============================================================

addRule('M1','no fabricated citation', 'MANUAL', ...
    ['51 references, each verified against publisher-deposited metadata ' ...
     '(REFERENCE_AUDIT.csv); C1-C5 check integrity mechanically, but ' ...
     '"this record describes a real paper" needs a human'], ...
    ['A plausible-looking reference is worse than an absent one: a reader ' ...
     'cannot tell it from a real one. Nine given names were wrong before ' ...
     'the verification pass, which is why this stays a MANUAL rule even ' ...
     'though the mechanical checks pass.']);

addRule('M2','figure content matches its caption claim', 'MANUAL', ...
    '13 figures generated from frozen files; visual review required', ...
    'No mechanical check can confirm a plot shows what its caption says.');


%% ============================================================
% Verdict
% ============================================================

nPass = nnz(strcmp({R.status},'PASS'));
nFail = nnz(strcmp({R.status},'FAIL'));
nMan  = nnz(strcmp({R.status},'MANUAL'));

for k = 1:numel(R)
    fprintf('  [%-6s] %-52s %s\n', R(k).status, R(k).name, R(k).detail);
end

fprintf('\n  %d PASS, %d FAIL, %d MANUAL\n', nPass, nFail, nMan);

report.rules = R;
report.pass  = (nFail == 0);
report.nPass = nPass;
report.nFail = nFail;
report.nManual = nMan;


%% ============================================================
% AUDIT_REPORT.md
% ============================================================

fid = fopen(fullfile(paperDir,'AUDIT_REPORT.md'),'w');

fprintf(fid, '# Publication consistency audit\n\n');
fprintf(fid, 'Generated by `paper/scripts/paper_audit.m`. ');
fprintf(fid, 'Re-run after any change to the manuscript or the generated artefacts.\n\n');

if report.pass
    fprintf(fid, '**VERDICT: PASS** — %d rules passed, %d require manual review.\n\n', ...
        nPass, nMan);
else
    fprintf(fid, '**VERDICT: FAIL** — %d of %d mechanical rules failed.\n\n', ...
        nFail, nPass + nFail);
end

fprintf(fid, '| Rule | Check | Status | Detail |\n|---|---|---|---|\n');

for k = 1:numel(R)
    fprintf(fid, '| %s | %s | **%s** | %s |\n', ...
        R(k).id, R(k).name, R(k).status, localEscape(R(k).detail));
end

fprintf(fid, '\n## Why each rule exists\n\n');

for k = 1:numel(R)
    fprintf(fid, '**%s — %s**\n\n%s\n\n', R(k).id, R(k).name, R(k).why);
end

fprintf(fid, '## Scope\n\n');
fprintf(fid, 'This audit checks *consistency between the manuscript and the\n');
fprintf(fid, 'frozen result set*. It does not check that the results are\n');
fprintf(fid, 'correct — that is what the pre-registered gates, the holdout\n');
fprintf(fid, 'validation and the reproduction checks of `simulation-v1.0` do.\n\n');
fprintf(fid, 'Rules marked MANUAL cannot be expressed mechanically and are\n');
fprintf(fid, 'listed so that they are not mistaken for having passed.\n');

fclose(fid);

fprintf('\n  AUDIT_REPORT.md written.\n');

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function c = localList(dirPath, pat)

d = dir(fullfile(dirPath, pat));

c = cell(numel(d),1);

for k = 1:numel(d)
    c{k} = fullfile(dirPath, d(k).name);
end

end


function s = localFirstFew(c)

if isempty(c)
    s = '';
    return;
end

n = min(3, numel(c));

s = sprintf(' [e.g. %s]', strjoin(c(1:n), ' | '));

s = strrep(s, newline, ' ');

end


function out = localSentences(txt)

txt = regexprep(txt, '%[^\n]*', '');
txt = regexprep(txt, '\s+', ' ');

out = strsplit(txt, '. ');

end


function tf = localDenies(snt, phrase)
%LOCALDENIES Does this sentence deny, forbid, or report the rejection of
% the claim whose phrase it mentions?
%
% Without this, every honest disclaimer in the manuscript trips the rule
% it was written to satisfy: "we do not claim universal superiority",
% "a claim of Pareto superiority was rejected", "calling this a
% communication failure would be wrong".
%
% TWO TESTS, IN ORDER
%
% 1  Sentence-wide cues that the sentence is REPORTING or FORBIDDING a
%    claim rather than making it.
%
% 2  A negation in the 60 characters immediately BEFORE the phrase. This
%    is the precise test and it is what catches constructions a marker
%    list keeps missing -- "several failures ... are NOT communication
%    failures", where the negation is adjacent and the sentence carries
%    no other cue. Scoping it to a window before the phrase, rather than
%    accepting any "not" anywhere in the sentence, keeps the rule from
%    being defeated by an unrelated negation elsewhere.

low = lower(snt);

strong = { ...
    'do not claim', 'does not claim', 'we do not', 'not a claim', ...
    'was rejected', 'were rejected', 'is rejected', 'rejection', ...
    'would be wrong', 'must not', 'forbidden', 'not permitted', ...
    'no acceptance gate', 'no evidence', 'does not hold', 'did not hold'};

if any(cellfun(@(m) contains(low, m), strong))
    tf = true;
    return;
end

if nargin >= 2 && ~isempty(phrase)

    at = strfind(low, lower(phrase));

    negations = {'no ', 'not ', 'never ', 'without ', 'nor ', ...
                 'nothing ', 'none ', 'neither '};

    for k = 1:numel(at)

        a = max(1, at(k) - 60);

        pre = low(a : max(a, at(k)-1));

        if any(cellfun(@(m) contains(pre, m), negations))
            tf = true;
            return;
        end

    end

end

tf = false;

end


function s = localTrim(s)

s = strtrim(s);

if numel(s) > 90
    s = [s(1:90) '...'];
end

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'no';
end

end


function s = localEscape(s)

s = strrep(s, '|', '\|');
s = strrep(s, newline, ' ');

end
