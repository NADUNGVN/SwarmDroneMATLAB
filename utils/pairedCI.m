function S = pairedCI(a, b, nRequested)
%PAIREDCI Paired difference, mean and 95 % confidence interval.
%
%   S = pairedCI(metricA, metricB, nRequested)
%
% CRN makes the two arms of a comparison share a seed, a channel
% realization, a fault realization and a noise realization, so the right
% statistic is the paired difference, not a two-sample test:
%
%   d_s   = metricA(s) - metricB(s)
%   dbar  = mean(d)
%   CI95  = dbar +- t(0.975, nPairs-1) * std(d) / sqrt(nPairs)
%
% THE POINT OF THE nPairs BOOKKEEPING
%
% A pair is unusable when either arm diverged, because a diverged run has
% no finite RMSE to difference. Dropping such pairs silently and still
% calling the result a 50-seed paired CI would overstate it, so this
% function reports:
%
%   nRequested   the pre-registered pair count
%   nPairs       the pairs that were actually usable
%   nDropped     how many were lost, and to what
%   complete     nPairs == nRequested
%
% A caller whose result has complete == false must downgrade the claim
% and say so, rather than quoting the interval as if the full sample had
% been available.
%
% crossesZero is the pre-registered downgrade trigger: an interval that
% contains zero means the two arms are not distinguishable at this pair
% count, and the pre-registration forbids adding seeds until it stops
% containing zero, because choosing the sample size by looking at the
% interval is choosing it by the result.
%
% Deliberately NOT used for binary safety metrics. A safety failure rate
% is a proportion over an eligibility-filtered denominator, and forcing
% it through a t interval would both mis-state its distribution and hide
% the denominator that the source experiment's eligibility rule defines.

if nargin < 3 || isempty(nRequested)
    nRequested = numel(a);
end

a = a(:);
b = b(:);

if numel(a) ~= numel(b)
    error('pairedCI:lengthMismatch', ...
        'Paired arms have %d and %d entries.', numel(a), numel(b));
end

d = a - b;

usable = isfinite(d);

S.nRequested = nRequested;
S.nPairs     = nnz(usable);
S.nDropped   = numel(d) - S.nPairs;
S.complete   = (S.nPairs == nRequested);

S.nDroppedA = nnz(~isfinite(a));
S.nDroppedB = nnz(~isfinite(b));

d = d(usable);

if S.nPairs < 2

    S.meanD  = NaN;
    S.stdD   = NaN;
    S.seD    = NaN;
    S.tCrit  = NaN;
    S.lo     = NaN;
    S.hi     = NaN;

    S.crossesZero = true;
    S.verdict     = 'INSUFFICIENT PAIRS';

    return;

end

S.meanD = mean(d);
S.stdD  = std(d);
S.seD   = S.stdD / sqrt(S.nPairs);

S.tCrit = tinv(0.975, S.nPairs - 1);

half = S.tCrit * S.seD;

S.lo = S.meanD - half;
S.hi = S.meanD + half;

S.crossesZero = (S.lo <= 0) && (S.hi >= 0);

if S.crossesZero
    S.verdict = 'CI CONTAINS 0';
elseif S.hi < 0
    S.verdict = 'CI ENTIRELY BELOW 0';
else
    S.verdict = 'CI ENTIRELY ABOVE 0';
end

end
