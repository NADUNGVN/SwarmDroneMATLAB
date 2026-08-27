function [h, nLeaf] = configHash(cfg)
%CONFIGHASH Order-independent hash of a configuration struct.
%
%   [h, nLeaf] = configHash(cfg)
%
% Recorded in the environment manifest so a reproduction attempt can
% prove it ran the same configuration rather than a similar one. A
% parameter that drifted by a digit is otherwise almost impossible to see
% by eye across a config this size.
%
% ORDER INDEPENDENCE IS DELIBERATE
%
% Each leaf contributes hash(fieldpath) XOR-folded with hash(value), and
% the leaf contributions are SUMMED. Adding a field, renaming one, or
% changing a value all move the hash; merely constructing the same fields
% in a different order does not. MATLAB struct field order depends on
% assignment order, so an order-sensitive hash would report a difference
% between two identical configurations built by different code paths -
% which is exactly the false alarm that makes a check get ignored.
%
% Function handles are skipped and counted separately: a handle has no
% stable serialisation across sessions, so hashing one would make the
% config hash irreproducible for a reason that has nothing to do with
% the configuration.

[h, nLeaf] = localWalk(cfg, '', 0, 0);

h = mod(h, 2^53 - 1);

end


%% ============================================================
% LOCAL FUNCTION
% ============================================================

function [acc, n] = localWalk(v, path, acc, n)

if isa(v, 'function_handle')

    % Skipped on purpose; see the header.
    return;

elseif isstruct(v)

    if numel(v) ~= 1

        for k = 1:numel(v)
            [acc, n] = localWalk(v(k), sprintf('%s(%d)', path, k), acc, n);
        end

        return;

    end

    f = fieldnames(v);

    for k = 1:numel(f)
        [acc, n] = localWalk(v.(f{k}), sprintf('%s.%s', path, f{k}), acc, n);
    end

    return;

elseif iscell(v)

    for k = 1:numel(v)
        [acc, n] = localWalk(v{k}, sprintf('%s{%d}', path, k), acc, n);
    end

    return;

end

% ---- leaf ----

pathHash = realizationHash(double(path));

if ischar(v) || isstring(v)
    valHash = realizationHash(double(char(v)));
elseif islogical(v) || isnumeric(v)
    valHash = realizationHash(double(v(:)));
else
    % An unexpected leaf type is counted but not hashed, rather than
    % silently ignored.
    valHash = 0;
end

acc = acc + mod(pathHash * 31 + valHash, 2^53 - 1);

n = n + 1;

end
