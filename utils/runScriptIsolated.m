function runScriptIsolated(scriptName)
%RUNSCRIPTISOLATED Run a project script in its own workspace.
%
%   runScriptIsolated('test_lock_regression')
%   runScriptIsolated('exp10b_unified_matrix')
%
% Every experiment and test in this project is a SCRIPT, and a script runs
% in the workspace of whoever called it. Calling one with
% evalin('base', name) therefore drops all of its variables into the base
% workspace, on top of whatever the caller was keeping there.
%
% THE BUG THIS EXISTS TO PREVENT, WHICH ALREADY HAPPENED TWICE
%
%   1  tests/run_all_tests timed each test with t0 = tic. Its seventh
%      test, test_mismatch_semantics, legitimately assigns
%      t0 = generateExternalForceTrace(...). The next toc(t0) then got a
%      struct instead of a timer handle, raised, and the suite ABORTED
%      AFTER TEST 7 - printing no failure, because nothing had failed,
%      and no summary. Two tests silently never ran.
%
%   2  experiments/run_simulation_v1_validation holds its own run record
%      in expRun. Every experiment it invokes opens its own record into
%      the same variable, so the validation's manifest.json would have
%      been written into the last nested experiment's directory and its
%      INDEX.md row attributed to the wrong run.
%
% Both failures are silent in the sense that matters: the log looks
% plausible. That is worse than a crash, so isolation is enforced here
% rather than avoided by choosing unusual variable names, which only
% moves the collision somewhere less obvious.
%
% eval() inside a function body executes the script against THIS
% function's workspace. The script sees the project path, defines whatever
% it likes, and all of it is discarded on return. Errors propagate
% normally, so a caller's try/catch still works.

eval(scriptName);   %#ok<EVLDOT>

end
