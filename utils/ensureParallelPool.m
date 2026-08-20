function pool = ensureParallelPool(maxWorkers)
%ENSUREPARALLELPOOL Start a parallel pool with the project on every worker.
%
%   pool = ensureParallelPool()
%   pool = ensureParallelPool(20)
%
% Workers do not inherit path changes that startup.m made after the pool
% was created, so the project path is pushed to every worker explicitly.
%
% Returns [] if no pool could be started; callers should then simply run
% the parfor serially, which MATLAB does automatically.

if nargin < 1 || isempty(maxWorkers)
    maxWorkers = 20;
end

pool = [];

try

    pool = gcp('nocreate');

    if isempty(pool)

        c = parcluster('Processes');

        n = min(maxWorkers, c.NumWorkers);

        fprintf('ensureParallelPool: starting pool with %d workers...\n', n);

        pool = parpool(c, n);

    end


    % Push the project path to every worker. parfevalOnAll is the
    % function-form equivalent of pctRunOnAll and needs no eval.

    p = genpath(projectRoot());

    f = parfevalOnAll(pool, @addpath, 0, p);

    wait(f);


    fprintf('ensureParallelPool: pool ready (%d workers).\n', pool.NumWorkers);

catch err

    fprintf('ensureParallelPool: unavailable (%s). Running serially.\n', ...
        err.message);

    pool = [];

end

end
