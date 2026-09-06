# EXP14 amendments after holdout opening

## Amendment 001 — deterministic resume after external interruption

- Run: `results/exp14a_holdout_primary/2026-08-29_155023`
- Holdout opened: 2026-08-29 15:50:23
- Interruption boundary: 160/300 complete seed--scenario groups,
  5,600/10,500 primary rows.
- Cause: the interactive execution session was interrupted externally; the
  MATLAB client and worker pool terminated without a MATLAB exception.
- Information inspected before the amendment: process presence, checkpoint
  row count, group count and console progress only. No RMSE, airtime, AoI,
  safety, Pareto or method-comparison value was read.

The recovery-only change adds an optional existing-run directory to
`exp14a_holdout_primary`. It validates the original `holdout_opened.json`,
registry hash, complete 35-row group boundaries, unique declared cell keys and
paired trace/state hashes. It then evaluates only missing groups in their
original frozen order and appends them to the same checkpoint.

No seed, channel parameter, plant, policy, baseline, frontier point, OOD point,
metric, contrast, exclusion rule, integrity gate or inference rule changed.
The pre-opening source remains preserved in the run's `frozen_source/` and in
the root-level copied runner. The copied pre-opening runner SHA-256 is
`44b717acad1a218b4200af73ad877172c4276fdaf54e63cb4af186128ce5c5d0`;
the recovery runner SHA-256 is
`d5fd0016d1d5d455c2ccc35190665f8623d27c65f06ef563affe8db74dbbef57`.
This amendment is operational recovery, not a
scientific-design amendment.

## Amendment 002 — terminal right-censoring in physical accounting

- Trigger: EXP14A completed all 10,500 rows but `physical_accounting` was the
  only failed integrity gate (10/11 passed).
- Information inspected: only the four accounting identities and their
  residual counts. No RMSE, airtime ranking, AoI comparison, safety contrast
  or Pareto result was inspected.
- Cause: an attempt is counted when a frame starts. With four-slot DATA and
  variable multi-slot ACK frames, work started just before `T=12 s` can remain
  active at the finite horizon. Such a recipient has neither success nor loss
  yet; the two-state gate inherited from the one-slot study omitted this
  right-censored third state.

The output contract is extended additively with terminal active-frame, DATA-
recipient and ACK-recipient counts. The accounting identity is now
`attempts = success + loss + terminal-in-flight`. Existing success/loss fields
are unchanged, and no in-flight frame is relabeled as a synthetic loss or
success. A deterministic test holds a four-slot frame across the horizon and
checks this contract.

For the already completed EXP14A output, exact terminal recipient counts are
the nonnegative integer residuals of the original counters. The original CSV,
gate and verdict files are preserved under
`*_pre_terminal_accounting_amendment.*`; the corrected artifacts add the new
columns and an audit JSON. No simulation or policy decision is rerun. EXP14B
will log the three terminal fields directly because it had not been opened at
the time of this amendment.

## Amendment 003 — source snapshots removed from executable MATLAB path

During validation of Amendment 002, `which -all simSwarmSharedMedium` showed
that the source copy under the completed EXP14A run's `frozen_source/` preceded
the workspace implementation. The cause was `startup.m` applying `genpath` to
the entire project, including `results/`.

This did not create mixed EXP14A behavior: the initial run executed before the
snapshot directory was added to that MATLAB session, and the resume session
resolved to the immutable pre-opening snapshot, which is the intended frozen
implementation. However, leaving the path unchanged would make future runs,
including not-yet-opened EXP14B, execute stale snapshots.

`startup.m` now removes the full `results/` subtree from the path immediately
after adding project source. Result snapshots remain immutable provenance data
but can no longer shadow executable modules. No scientific configuration,
simulation algorithm or completed result was changed by this path-hygiene fix.

## Amendment 004 — divergence is an outcome, not a performance gate

Before EXP14B was opened, an audit found that both runners named
`plant_stability` as an integrity gate requiring zero divergences. This
contradicted the frozen plan's explicit rules that negative OOD outcomes must
be retained and no performance outcome may decide whether the experiment
passes.

The gate is renamed `divergence_accounting`. It checks only that divergence is
binary, reported, and counted as a safety failure. A divergent row may carry
non-finite continuous metrics; summaries exclude only those non-finite values
and expose the divergence numerator. Paired-CI utilities already report the
requested, usable and dropped pair counts. No divergent EXP14A run existed, so
the primary result or denominator is unchanged. This correction was completed
before any EXP14B seed was consumed.
