function h = realizationHash(v)
%REALIZATIONHASH Exact, order-independent checksum for a CRN realization.
%
%   h = realizationHash(v)
%
% Not cryptographic. Its only job is to detect that two runs used
% different realizations, and to make "same seed, same realization" an
% audited fact rather than an assertion.
%
% THREE PROPERTIES, EACH OF WHICH A NAIVE CHECKSUM LACKS
%
% 1  EXACT INTEGER ARITHMETIC, SO THE ORDER OF SUMMATION CANNOT MATTER.
%
%    Every term is reduced below 2^20 before it is summed, and the trace
%    arrays this hashes have at most a few tens of millions of elements,
%    so the running total stays under 2^53 and every addition is exact.
%    Exact integer addition is associative, so MATLAB is free to sum in
%    whatever order and with whatever thread count it likes and the
%    answer does not move.
%
%    This is not hypothetical. The private localHash inside
%    generateNetworkTrace sums ~7.6 million floats whose partial sums
%    exceed 2^53. MATLAB's sum() is multithreaded and pairwise, so its
%    grouping depends on the thread count - and a parallel-pool worker
%    runs single-threaded while the client does not. The identical
%    forward trace therefore hashed to 7.37428389003314e+15 in the client
%    and 7.37428389003311e+15 on a worker. The realization was the same
%    (the trajectories were bit-identical); only the checksum moved. A
%    serial-versus-parallel reproducibility check built on that hash
%    reports a failure that does not exist.
%
% 2  IT ROUND-TRIPS THROUGH TEXT.
%
%    The result stays below about 3e13, i.e. fourteen digits, so writing
%    it into tidy.csv with writetable's default %.15g and reading it back
%    is exact. The locked 2^53-scale hashes need sixteen digits and lose
%    their last one, which made a hash stored in a CSV compare unequal to
%    the same hash recomputed in memory.
%
% 3  IT WORKS ON LOGICALS AND ON LARGE INTEGERS.
%
%    The locked formula, mod(floor(abs(v)*1e12), 1e9), is exactly zero for
%    every logical input, because floor(1*1e12) is a multiple of 1e9. The
%    EXP10 realization set includes logical realizations - which links are
%    down, which node is dark - so that formula would have given every
%    fault pattern the same hash and the check would have passed on
%    non-matching realizations. Here the integer and fractional parts are
%    folded separately, so a logical, a small float and a 14-digit
%    integer are all hashed meaningfully.
%
% THE LOCKED GENERATORS KEEP THEIR OWN FORMULA. Their hashes appear in
% locked EXP07-EXP09 result tables and changing one would invalidate a
% stored value. They gain an ADDITIONAL hashExact field computed here;
% EXP10 gates on that one and reports theirs.
%
% Non-finite entries map to fixed sentinels rather than propagating NaN,
% because a permanent link fault legitimately carries tEnd = inf and a NaN
% hash would be indistinguishable from a broken hash.

v = double(v(:));

v(isnan(v))  = -7.5;
v(v ==  inf) = -8.5;
v(v == -inf) = -9.5;

n = numel(v);

if n == 0
    h = 0;
    return;
end

% Prime modulus below 2^20. Keeping every term under it is what bounds
% the running total and makes the sum exact.
P = 1048573;

a = abs(v);

% Integer part and fractional part folded separately, so the hash is
% meaningful for a logical (integer part 0 or 1), for a uniform draw in
% [0,1) (integer part 0, nine fractional digits) and for a 14-digit
% integer alike. Both halves are computed exactly at any magnitude:
% floor(a) is exact for a < 2^53, and round(frac*1e9) is exact because
% frac < 1.
intPart  = mod(floor(a), P);
fracPart = round(mod(a, 1) * 1e9);

% Sign folded in so that +x and -x cannot collide, and +7 so an all-zero
% input does not hash to zero.
q = mod(intPart + fracPart + 1e6*(v < 0) + 7, P);

% Position weight, so a permutation of the same values changes the hash.
w = mod((1:n)', 9973) + 1;

% q*w < 1048573 * 9974 ~ 1.05e10, exact in double; the mod brings each
% term back under P before it is summed.
t = mod(q .* w, P);

% Exact because n*(P-1) stays far below 2^53 for any realization this
% project produces: at 3e7 elements the bound is 3.1e13.
h = sum(t);

end
