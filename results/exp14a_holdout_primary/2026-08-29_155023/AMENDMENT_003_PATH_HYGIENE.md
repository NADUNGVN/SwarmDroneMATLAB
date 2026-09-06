# Amendment 003 — results snapshots are non-executable

`startup.m` previously added `results/` recursively, allowing this run's frozen
source snapshots to shadow workspace code in later MATLAB sessions. The fresh
EXP14A process ran before the snapshot path existed, while the resumed process
used the immutable pre-opening snapshot, so primary behavior remained frozen.

The results subtree is now removed from MATLAB's executable path. This prevents
stale snapshots from affecting the not-yet-opened EXP14B or later tests; no
completed simulation output is changed.
