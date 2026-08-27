# Reproducibility appendix

Everything in the manuscript is derived from one frozen state of the
simulation campaign. This file records what that state is, how to
reproduce it, and the four defects found during the freeze — including
why none of them changed a scientific metric.

---

## 1. The frozen state

| Item | Value |
|---|---|
| Tag | `simulation-v1.0` |
| Commit | `32858b1` |
| Paper branch | `paper-v1`, branched from the tag |
| Validation run recorded in the tag | `results/simulation_v1_validation/2026-08-27_094912` |
| Holdout dataset | `results/exp10a_final_validation/2026-08-27_091546` (3400 rows) |
| Unified matrix | `results/exp10b_unified_matrix/2026-08-27_095330` (68 rows) |

A second, independent pass of the validation was run against the tagged
tree itself and also reported 7/7; its log is committed after the tag,
because committing a validation log necessarily moves `HEAD` past the
commit the log describes.

## 2. Environment

| Item | Value |
|---|---|
| MATLAB | 25.1 (R2025a), 21-Nov-2024 |
| Platform | `PCWIN64`, Windows 10.0.26200 |
| Logical cores | 16 reported to MATLAB |
| Parallel pool | 16 workers, `Processes` profile |
| Toolboxes recorded | 111 (full list in `manifest.json`) |
| `defaultConfig` hash | 44647374 |
| Master trace-hash fold | 81947029 |

The manifest also records a per-point configuration hash and a per-`(N,
seed)` trace-hash table (`trace_hashes.csv`, 150 rows), so a reproduction
attempt can prove it ran the same configuration rather than a similar one.

Only the Statistics and Machine Learning Toolbox is required beyond base
MATLAB, for `tinv` in the paired confidence intervals. The Parallel
Computing Toolbox is used for throughput only: results are independent of
the worker count, which is verified rather than assumed (§6).

## 3. One-command reproduction

```matlab
run_simulation_v1_validation      % reload mode, minutes
```

Seven steps, each of which can fail independently:

1. **Test suite** — 9 files, including `test_lock_regression`, which
   re-derives stored EXP05C / EXP06A / EXP07A values bit-identically.
2. **Locked tags** — 10 tags present, SHAs recorded in the manifest.
3. **Dataset** — reload the holdout dataset, or regenerate with
   `v1ForceRun = true` (about 30 minutes).
4. **Rebuild** — EXP10B re-aggregated from the persisted dataset only.
5. **Realisation hashes** — the registry is redrawn in this session and
   compared against every row of the dataset.
6. **Serial versus parallel determinism** — one seed, four methods,
   bit-identical.
7. **Environment manifest** — written to the run directory.

Steps 1, 2, 5 and 6 are blockers. A scientific result being unfavourable
is not.

```matlab
run_clean_clone_check             % clones HEAD and reproduces it
```

Clones the repository into a temporary directory and, in a MATLAB process
that has never seen the working tree, runs the test suite, rebuilds the
unified matrix from persisted tidy files, and re-simulates one seed. The
rebuilt matrix must be identical and the re-simulated seed bit-identical.

## 4. Seed policy

The final validation used the holdout block `25000001:25000050`. Before
any simulation ran, `assertExp10Seeds` proved:

- no EXP10 seed appears in any EXP01–EXP09 seed family (enumerated from
  the seed expressions in the experiment scripts themselves, with index
  ranges taken deliberately *wider* than the loops that actually ran, so
  the test is stricter than necessary rather than looser);
- the seven per-realisation RNG streams of one seed are mutually
  disjoint.

Development experiments used 20 seeds each; those seed families are
disjoint from the holdout block.

**The seed count was fixed in advance and not revisited.** Adding seeds
after inspecting a confidence interval would be choosing the sample size
by the result.

## 5. Common random numbers and trace indexing

Sharing a seed is not sharing a realisation: each policy calls the
generator a different number of times, so two methods at one seed
desynchronise at the first transmission. Every stochastic input is
therefore pre-drawn and consumed by lookup.

| Realisation | Indexed by | RNG offset |
|---|---|---|
| forward channel | (link, timestep) | 20240001 |
| reverse ACK channel | (link, timestep) | 30240001 |
| link-fault pattern | graph | 50240001 |
| node blackout | graph | 60240001 |
| external-force trace | physical time | 70240001 |
| estimator-noise trace | physical time | 80240001 |
| transmission phase | (sender, payload class) | 90240001 |

Three properties follow, and all three are checked rather than asserted:

- **Traffic volume does not advance the realisation.** The four methods
  transmit substantially different numbers of packets at one seed and all
  four report the same forward-realisation hash.
- **Scenario changes thresholds, not draws.** In EXP10 the seed alone
  determines every realisation, so Clean, Moderate and Stressed at one
  seed share one set of channel uniforms. A scenario-to-scenario
  difference is therefore attributable to network quality, not to the
  draw — which is what makes the adaptivity result meaningful.
- **Physical-time indexing where dt varies.** The estimator-noise and
  external-force traces live on a fixed physical-time grid, so a run at a
  different outer timestep meets the *same* realisation at the same
  instant. Indexing those by outer step would have confounded the
  timestep study with a different random draw.

## 6. Locked-parameter policy

No parameter value differs between network conditions, between methods
where the parameter applies to both, or between the failing and working
variants of the design chain. The complete set is Table I of the
manuscript, generated from the configuration functions rather than typed.

The controller was never retuned per condition. Retuning would have
measured the quality of the retuning instead of the robustness of the
communication policy, which is why the mass-mismatch rejection is reported
as a controller limitation rather than repaired.

## 7. Result directory structure

```
results/<experiment>/<runId>/
    console.log      verbatim console output, including every gate verdict
    tidy.csv         one row per (seed, condition, method) — the dataset
    meta.json        git commit, MATLAB version, timing, inventory
    <experiment>.m   source snapshot of the script that produced the run
    figures/*.png    figures as generated at run time
    workspace.mat    full workspace (NOT version controlled)
results/<experiment>/LATEST.txt   the run id that counts
results/INDEX.md                  curated map + auto-appended run log
```

`*.mat` and `*.fig` are deliberately not version controlled; everything
needed to rebuild tables and figures is. That is what makes the
clean-clone rebuild possible.

## 8. How the paper's tables and figures are regenerated

```matlab
addpath('paper/scripts');
make_paper_metrics      % generated/headline_metrics.csv, metrics.tex, PROVENANCE.md
make_paper_tables       % tables/tableI..VI.tex
make_paper_figures      % figures/fig01..fig11 .pdf and .png
paper_guard             % proves no frozen source was modified
paper_audit             % consistency rules, writes AUDIT_REPORT.md
```

No script in `paper/` runs a simulation. Each reads persisted `tidy.csv`
files and writes only under `paper/generated`, `paper/tables` and
`paper/figures`. `paper_guard` checks that claim against `git diff` from
the tag and treats any modification under `simulation/`, `network/`,
`controllers/`, `swarm/`, `models/`, `experiments/`, `metrics/`,
`configs/`, `utils/` or `tests/` as a failure.

**Every headline number in the manuscript is a generated macro.** Nothing
numeric is typed into the prose, so a mismatch between the paper and the
data is a build error rather than a reader's problem.

## 9. Negative-result preservation policy

Rejected and partial results are first-class outputs:

- each carries its own git tag (`exp07c-locked-negative`,
  `exp08a-locked-partial`, and so on);
- `docs/FINAL_CLAIMS.md` lists all of them with the statistic that
  rejected them;
- the EXP10B report contains a fixed `LOCKED LIMITATIONS — NOT RE-TESTED
  AWAY` section that reprints each with its EXP10 evidence beside it;
- Table VI of the manuscript is a dedicated negative-results table, and
  `paper_audit` fails if a rejected claim appears as supported anywhere.

A favourable holdout number does not retract an earlier rejection. EXP10
ran **one** selected point per rejection; one point cannot retract a
sweep. Where EXP10 has no evidence — topologies other than ring, the
estimator point in the Clean condition, any timestep but 0.02 s — that is
stated rather than allowed to read as repaired.

## 10. Four silent defects found during the freeze

All four were found by the freeze machinery itself, and none changed a
scientific metric. They are recorded here because a reproduction attempt
should know what was wrong with the tooling and why the numbers survived.

### 10.1 The legacy transmission-phase flag never had any effect

`cfg.net.phaseOffset` computed a per-link offset matrix that the
transmission decision never read, so every locked result ran on a single
global clock regardless of the flag.

*Why no metric changed:* the flag was off in every locked experiment and
its "off" behaviour is what the code always did. The locked results'
`phase OFF` label is correct. The dead computation was removed and a real
per-sender phase model was added under a new flag, used only in EXP10.

### 10.2 The locked checksum collapsed logical inputs to zero

`localHash` computes `mod(floor(abs(v)*1e12), 1e9)`, which is exactly zero
for any logical input because `floor(1e12)` is a multiple of `1e9`.

*Why no metric changed:* the locked generators only ever hashed floating
point draws. The defect mattered only for the *new* EXP10 realisations
(link-fault and blackout patterns, which are logical), and those never
used it: `utils/realizationHash.m` was written for them. The locked
formula is untouched because its values appear in locked result tables.

### 10.3 The locked checksum was neither thread-stable nor text-exact

`localHash` sums ~7.6 million floats whose partial sums exceed `2^53`.
MATLAB's `sum` is multithreaded and pairwise, and a pool worker runs
single-threaded while the client does not, so the *same* realisation
hashed to `7.37428389003314e+15` in the client and `...11e+15` on a
worker. It also needs sixteen digits and loses one when written to CSV.

*How it was found:* the serial-versus-parallel determinism check reported
a failure. The trajectories and every counter were bit-identical and only
the checksum differed, which identified the checksum rather than the
simulation as the problem.

*Why no metric changed:* it is a checksum, read by no decision.
`realizationHash` is exact integer arithmetic below `2^53` throughout, so
summation order cannot move it and it round-trips through text. EXP10
gates on the exact hash and reports the locked one against a **stated**
relative tolerance of 1e-14 (worst observed 4.579e-15 over 3400 rows).
After the fix, serial and parallel execution agree bit-identically
including hashes.

*Evidence that no metric moved:* the dataset was regenerated after the
fix and compared row by row against the earlier independent 3400-run
execution. RMSE, minimum separation, safety, divergence, DATA, ACK,
broadcast, AoI, the forward and reverse hashes, invariants and maximum
deviation are **identical**. The only three columns that differ are the
three computed by `realizationHash`, whose formula changed by design.

### 10.4 Nested scripts shared one workspace

`run_all_tests` timed each test with `t0 = tic`. Its seventh test
legitimately assigns `t0 = generateExternalForceTrace(...)`, so the next
`toc(t0)` raised and the suite **aborted after test 7** — printing no
failure, because nothing had failed, and no summary. Two tests silently
never ran.

*Why no metric changed:* the two skipped files are semantics tests, and
both pass. No experiment result depends on the test runner.

*Fix:* `utils/runScriptIsolated.m` runs each script in its own function
workspace. Fixed by isolation rather than by renaming variables, which
would only move the collision somewhere less obvious. The same hazard
would have let a nested experiment overwrite the validation's own run
record and write its manifest into the wrong directory.

## 11. Known reporting hazards

Two conventions in the frozen data are easy to misread, and the
manuscript labels both at every point of use:

- **Two rate normalisations.** EXP07 reports DATA rate *per channel*
  (P10 = 10.00 Hz); EXP08 onward report *swarm totals* (P10 = 99.67 Hz at
  N = 5). They are never divided by one another.
- **Two graph conventions.** EXP07 kept in-links to the leader (12
  channels at N = 5); EXP08 onward remove them, since the leader reads its
  reference directly (10 channels at N = 5). Absolute traffic is therefore
  not comparable across the two eras, and the same caveat applies to
  N = 50 against EXP06A.
