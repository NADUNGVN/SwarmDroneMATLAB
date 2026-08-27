function h = realizationHash(v)
%REALIZATIONHASH Cheap order-sensitive checksum for a CRN realization.
%
%   h = realizationHash(v)
%
% Not cryptographic. Its only job is to detect that two runs used
% different realizations, and to make "same seed, same realization" an
% audited fact rather than an assertion.
%
% WHY THIS IS NOT THE SAME FORMULA AS THE ONE INSIDE
% generateNetworkTrace / generateAckTrace
%
% Those two carry a private localHash of the form
%
%   mod(floor(abs(v)*1e12), 1e9)
%
% which is fine for the uniform and normal draws they hash, but collapses
% to exactly zero for a logical or integer input: floor(1*1e12) is a
% multiple of 1e9. The EXP10 realization set includes LOGICAL realizations
% - which links are down, which node is dark - so hashing them with that
% formula would have produced the same hash for every fault pattern and
% the hash check would have silently passed on non-matching realizations.
%
% The locked generators keep their own formula untouched, because their
% hashes appear in locked EXP07-EXP09 result tables and changing them
% would invalidate a stored value. This function is used for the trace
% types EXP10 adds: phase, link fault, node blackout, and the combined
% master hash.
%
% Non-finite entries are mapped to fixed sentinels rather than propagating
% NaN, because a permanent link fault legitimately carries tEnd = inf and
% a NaN hash would be indistinguishable from a broken hash.

v = double(v(:));

% Sentinels for the non-finite values a realization may legitimately
% contain. Distinct from each other and from any finite input.
v(isnan(v))       = -7.5;
v(v ==  inf)      = -8.5;
v(v == -inf)      = -9.5;

n = numel(v);

if n == 0
    h = 0;
    return;
end

% floor(abs(x)*1e9) keeps nine significant digits of magnitude, the sign
% is folded in separately so +x and -x cannot collide, and the +7 keeps
% an all-zero input from hashing to zero.
q = mod(floor(abs(v)*1e9) + 1e6*(v < 0) + 7, 2^31);

idx = (1:n)';

h = mod(sum(q .* mod(idx, 9973)), 2^53 - 1);

end
