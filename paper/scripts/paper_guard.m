function report = paper_guard(verbose)
%PAPER_GUARD Prove the paper branch has not touched frozen simulation source.
%
%   report = paper_guard()
%
% simulation-v1.0 is frozen. The paper package reads frozen results and
% writes only into paper/. This checks that claim against git rather than
% trusting it, and it is a BLOCKER for the audit: a figure that required
% editing a simulator is not a figure about the frozen campaign.
%
% THE ANCHOR IS THE SHA, NOT THE TAG
%
% Identity comes from paper/FROZEN_BASE.json. A tag is a movable label; the
% commit is not. Three cases, and the difference between them matters:
%
%   tag present, resolves to the expected sha
%       -> verify against the tag. Normal case.
%
%   tag absent
%       -> verify against the sha directly, and report
%          REMOTE_TAG_MISSING / OWNER_ACTION. The verification is just as
%          strong; what is missing is the published label. This is NOT
%          silently treated as "tag present".
%
%   tag present but resolves elsewhere
%       -> FAIL HARD. Something has re-pointed the release label, and no
%          result in this package can be trusted to describe what it says
%          it describes.
%
% An annotated tag resolves through 'git rev-parse <tag>' to the TAG OBJECT,
% not the commit: here that is ba8ddcc rather than 32858b1. Comparing the
% tag-object sha against a commit sha would report a mismatch on a perfectly
% healthy repository, so the tag is resolved with 'git rev-list -n1 <tag>',
% which yields the commit and, unlike '<tag>^{commit}', contains no caret to
% be eaten by cmd.exe.
%
% READ-ONLY AND WRITABLE PATHS are both read from FROZEN_BASE.json so that
% the guard and the anchor cannot disagree.
%
% If a table or figure appears to need a change under a read-only path, that
% is a STOP condition rather than something to slip in here: it means the
% frozen artefact does not contain what the manuscript wants to say, and the
% honest responses are to change the manuscript or to re-open the freeze
% deliberately.

if nargin < 1 || isempty(verbose)
    verbose = true;
end

root = projectRoot();


%% ============================================================
% Anchor
% ============================================================

anchorPath = fullfile(root,'paper','FROZEN_BASE.json');

if exist(anchorPath,'file') ~= 2
    error('paper_guard:noAnchor', ...
        'paper/FROZEN_BASE.json is missing; the frozen identity is undefined.');
end

anchor = jsondecode(fileread(anchorPath));

expectedSha = anchor.frozenRelease.sha;
frozenTag   = anchor.frozenRelease.tag;

readOnly = anchor.readOnlyPaths;

if ischar(readOnly)
    readOnly = {readOnly};
end

report.anchorFile  = 'paper/FROZEN_BASE.json';
report.frozenTag   = frozenTag;
report.expectedSha = expectedSha;
report.readOnly    = readOnly;


%% ============================================================
% 1  Does the expected commit exist at all?
% ============================================================

% NOTE: no '^{commit}' here. MATLAB's system() goes through cmd.exe on
% Windows, where '^' is the escape character, so 'sha^{commit}' arrives as
% 'sha{commit}' and every lookup fails. Every git invocation in this file
% therefore uses caret-free forms: 'cat-file -e <sha>' and
% 'rev-list -n1 <tag>'.
[st, ~] = system(sprintf('git -C "%s" cat-file -e %s', ...
    root, expectedSha));

report.shaExists = (st == 0);

if ~report.shaExists

    report.pass = false;
    report.tagState = 'SHA_MISSING';
    report.violations = {sprintf( ...
        'the frozen commit %s is not present in this repository', expectedSha)};

    if verbose
        fprintf('  [FAIL ] frozen commit %s not found\n', expectedSha);
    end

    return;

end


%% ============================================================
% 2  Tag state: present-and-correct, absent, or re-pointed
% ============================================================

% rev-list -n1 resolves an annotated tag straight to its commit and needs
% no caret, unlike 'rev-parse <tag>^{commit}'.
[stTag, tagOut] = system(sprintf('git -C "%s" rev-list -n1 %s', ...
    root, frozenTag));

tagCommit = strtrim(tagOut);

localTagPresent = (stTag == 0) && ~isempty(tagCommit);

report.localTagPresent = localTagPresent;
report.localTagCommit  = tagCommit;

% Compare on the shortest common prefix, so a 7-character anchor matches a
% 40-character rev-parse result without either being padded.
tagMatches = localTagPresent && localShaEq(tagCommit, expectedSha);

if localTagPresent && ~tagMatches

    % FAIL HARD. The release label has been re-pointed.
    report.pass = false;
    report.tagState = 'TAG_REPOINTED';
    report.violations = {sprintf( ...
        ['tag %s resolves to %s but the anchor requires %s: the release ' ...
         'label has been re-pointed'], ...
        frozenTag, localShort(tagCommit), expectedSha)};

    if verbose
        fprintf('\n  [FAIL ] %s\n', report.violations{1});
        fprintf(['          Do NOT re-create the tag to clear this. Find out ' ...
                 'why it moved.\n']);
    end

    return;

elseif localTagPresent

    report.tagState = 'TAG_OK';
    verifyRef = expectedSha;

else

    report.tagState = 'LOCAL_TAG_MISSING';
    verifyRef = expectedSha;

end


%% ============================================================
% 3  Remote tag: a publication blocker, not an audit failure
% ============================================================

[stRem, remOut] = system(sprintf('git -C "%s" ls-remote --tags origin %s', ...
    root, frozenTag));

report.remoteQueryOk = (stRem == 0);
report.remoteTagPresent = (stRem == 0) && ~isempty(strtrim(remOut));

if ~report.remoteQueryOk
    report.remoteState = 'REMOTE_UNREACHABLE';
elseif report.remoteTagPresent
    report.remoteState = 'REMOTE_TAG_OK';
else
    report.remoteState = 'REMOTE_TAG_MISSING';
end

% Deliberately NOT part of report.pass. A missing remote tag does not make
% a single number in this package wrong; it makes the release unpublished.
report.releaseBlocker = strcmp(report.remoteState,'REMOTE_TAG_MISSING');
report.ownerAction    = '';

if report.releaseBlocker
    report.ownerAction = sprintf('git push origin %s', frozenTag);
end


%% ============================================================
% 4  What has changed since the frozen commit?
% ============================================================

[~, out] = system(sprintf('git -C "%s" diff --name-only %s HEAD', ...
    root, verifyRef));

changed = localSplitLines(out);

% Uncommitted work counts too: a figure generated from an edited simulator
% is no better for the edit being unstaged.
[~, out2] = system(sprintf('git -C "%s" status --porcelain', root));

dirty = {};

lines = localSplitLines(out2);

for k = 1:numel(lines)

    ln = lines{k};

    if numel(ln) > 3
        dirty{end+1} = strtrim(ln(4:end));   %#ok<AGROW>
    end

end

allTouched = unique([changed(:)', dirty(:)']);

report.changedSinceFreeze = allTouched;
report.verifiedAgainst    = verifyRef;


%% ============================================================
% 5  Violations
% ============================================================

violations = {};

for k = 1:numel(allTouched)

    f = strrep(allTouched{k}, '\', '/');

    if isempty(f)
        continue;
    end

    for r = 1:numel(readOnly)

        pat = readOnly{r};

        if endsWith(pat, '/')
            hit = startsWith(f, pat);
        else
            hit = strcmp(f, pat);
        end

        if hit
            violations{end+1} = f;   %#ok<AGROW>
            break;
        end
    end

end

report.violations = unique(violations);

report.pass = isempty(report.violations) && ...
    ~strcmp(report.tagState,'TAG_REPOINTED') && report.shaExists;


%% ============================================================
% Report
% ============================================================

if verbose

    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('paper_guard: frozen simulation source\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('  anchor          : %s\n', report.anchorFile);
    fprintf('  frozen sha      : %s (present: %s)\n', ...
        expectedSha, localYesNo(report.shaExists));
    fprintf('  local tag       : %s\n', report.tagState);

    if localTagPresent
        fprintf('                    %s -> %s\n', frozenTag, localShort(tagCommit));
    end

    fprintf('  remote tag      : %s\n', report.remoteState);
    fprintf('  verified against: %s\n', verifyRef);
    fprintf('  paths touched   : %d\n', numel(allTouched));

    if report.pass
        fprintf('  [PASS ] no read-only path was modified\n');
    else
        fprintf('  [FAIL ] %d read-only path(s) modified:\n', ...
            numel(report.violations));
        for k = 1:numel(report.violations)
            fprintf('           %s\n', report.violations{k});
        end
        fprintf(['\n  This is a STOP condition. A paper-branch edit under ' ...
                 'these paths\n  changes what the frozen numbers mean.\n']);
    end

    if strcmp(report.tagState,'LOCAL_TAG_MISSING')
        fprintf(['  [NOTE ] the local tag is absent; verification used the ' ...
                 'sha directly,\n          which is equally strong. The tag ' ...
                 'was NOT assumed present.\n']);
    end

    if report.releaseBlocker
        fprintf('\n  [BLOCK] REMOTE_TAG_MISSING / OWNER_ACTION\n');
        fprintf('          %s\n', report.ownerAction);
        fprintf(['          Release-publication blocker only. No result in ' ...
                 'this package\n          depends on it, and the tag must ' ...
                 'not be moved to clear it.\n']);
    end

end

end


%% ============================================================
% LOCAL FUNCTIONS
% ============================================================

function tf = localShaEq(a, b)
%LOCALSHAEQ Compare two shas on their shortest common prefix.

a = strtrim(lower(a));
b = strtrim(lower(b));

n = min(numel(a), numel(b));

if n < 7
    tf = false;
    return;
end

tf = strcmp(a(1:n), b(1:n));

end


function s = localShort(sha)

sha = strtrim(sha);

if numel(sha) > 7
    s = sha(1:7);
else
    s = sha;
end

end


function c = localSplitLines(s)

s = strtrim(s);

if isempty(s)
    c = {};
    return;
end

c = strsplit(s, {sprintf('\n'), sprintf('\r')});

c = c(~cellfun(@isempty, c));

end


function s = localYesNo(tf)

if tf
    s = 'yes';
else
    s = 'no';
end

end
