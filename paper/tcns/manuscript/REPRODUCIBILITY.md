# Reproducing the TCNS manuscript

This document separates the evidence needed for the submitted claims from the
longer historical research trail. Commands are run from the repository root.
MATLAB R2025a generated the authoritative artifacts. Later compatible MATLAB
versions may create numerically equivalent outputs but should record their
release.

## Essential paper reproduction

### 1. Exact affine map and reachable theorem witnesses

    matlab -batch "run('tests/test_tcns_information_limits.m'); run('experiments/tcns_information_limits_validation.m')"

The accepted machine-readable run is:

**results/tcns_information_limits_validation/2026-09-08_095209/**

It contains configuration/provenance, link identifiability, dynamic witnesses,
and validation logs. A new run is timestamped and does not overwrite it.

### 2. R1 minimax, multi-action, coalition, and high-precision audit

    matlab -batch "run('tests/test_tcns_r1_theory_depth.m'); run('experiments/tcns_r1_theory_depth_validation.m')"

The accepted run is:

**results/tcns_r1_theory_depth_validation/2026-09-08_103325/**

It contains witness regret, sender-wise missing ranks, singular values,
coalition enumeration, tolerance sweeps, and the 80-digit comparison.

### 3. R2 cross-instance and all-action witness audit

    matlab -batch "run('tests/test_tcns_r2_generalization.m'); run('tests/test_tcns_actual_witness_audit.m'); run('experiments/tcns_r2_generalization_validation.m')"

The authoritative run is:

**results/tcns_r2_generalization_validation/2026-09-08_161130/**

It contains the 72-cell configuration registry, 1320 action rows, tolerance
grid, sender-wise missing ranks, exhaustive coalitions, selected 80-digit
checks, all ten actual-action witness rows, JSON exports, MATLAB workspace,
source commit, and console log. The earlier `2026-09-08_155705` directory is
retained only to document an invalid mixed-unit practical-scale grid; its
`INVALID_PRACTICAL_DIAGNOSTIC.md` explains which columns must not be used.

The registry cells use seed `27022001`. The N=5 witness scenario in the
frozen driver was instantiated with `27020001`; its independent practical
reference directions use `27022001 + actionIndex`. The scenario seed does not
enter the deterministic held-memory witness dynamics, but the distinction is
recorded here because the historical R2 `summary.seed` field alone is
incomplete metadata.

### 4. R2.5 adversarial replay and rank audit

    matlab -batch "run('tests/test_tcns_r2_5_persisted_witness_replay.m'); run('tests/test_tcns_r2_5_adversarial_artifact.m'); run('experiments/tcns_r2_5_adversarial_validation.m')"

The authoritative run is:

**results/tcns_r2_5_adversarial_validation/2026-09-08_175427/**

It independently rebuilds the same 72 cells without expanding the registry,
records 6600 tolerance/action rank diagnostics, replays all ten witnesses from
persisted initial coordinates, checks fixed-response semantics, compares three
practical normalizations, and independently enumerates all 448 sender-cell
coalition results. Two earlier directories are explicitly marked invalid and
one complete earlier run is labeled development-only.

### 5. R2.6 decision-identifiability post-processing

    matlab -batch "run('tests/test_tcns_r2_6_decision_identifiability.m')"

The accepted artifact is:

**results/tcns_r2_6_decision_identifiability/2026-09-08_232116/**

It post-processes only the frozen R2 affine matrices and witness endpoints.
The 448 sender-cell table reports absolute and relative hidden ranks,
pairwise projection residuals, and the N=5 sender summary. The artifact source
is committed in `da97e01`; the exact rank-gap refinement is `d0edd2c`. No
trajectory, graph, seed, policy, scheduler, or noise model is added.

### 6. Principal paper figures

    matlab -batch "run('paper/tcns/manuscript/make_gm_figures.m')"

The script reads only frozen machine-readable evidence and writes all six
main figures to **paper/tcns/manuscript/figures/**. Scientific data are not
edited manually.

### 7. Build the paper

From **paper/tcns/manuscript/**:

    pdflatex tcns_information_limits.tex
    bibtex tcns_information_limits
    pdflatex tcns_information_limits.tex
    pdflatex tcns_information_limits.tex

An IEEEtran-capable installation is required. The SQ artifact was also built
with Tectonic; either route must produce no undefined reference/citation or
overfull-box warning.

## Frozen supporting diagnostics

These are motivating/counterexample evidence, not population-performance
claims.

### Negative uncertainty-bound trigger

    matlab -batch "run('tests/test_tcns_gate5_frontier_matching.m'); run('experiments/tcns_gate5_stationary_frontiers.m')"

Accepted evidence:
**results/tcns_gate5_stationary_frontiers/2026-09-07_010403/**.

### Centralized current-information O1 diagnostic

    matlab -batch "run('experiments/tcns_o1_oracle_frontier_stage_a.m'); run('experiments/tcns_o1_oracle_frontier_stage_b.m')"

Accepted evidence:

- **results/tcns_o1_oracle_frontier_stage_a/2026-09-07_160426/**
- **results/tcns_o1_oracle_frontier_stage_b/2026-09-07_162102/**

O1 is privileged, online, and nondeployable. It reads current receiver truth
but no future realization.

### Feedback-economics sensitivity

    matlab -batch "run('tests/test_tcns_fb0_feedback_economics.m'); run('experiments/tcns_fb0_feedback_economics.m')"

Accepted evidence:
**results/tcns_fb0_feedback_economics/2026-09-07_175224/**.

This is ACK-like packet-frequency accounting, not an implemented protocol for
acquiring the all-agent missing statistic.

## Provenance and scope

Every accepted result directory retains machine-readable tables, seed and
scenario data, configuration, source commit, MATLAB release, and logs. The
scientific baseline is tagged **tcns_internal_science_pass** at
**7c679610af2098acc2aa5e8f005e81a898435f29**. The submission-candidate commit
is recorded in the final TCNS submission QA report.

Historical AoI/trigger/ACK-belief artifacts remain in the repository but are
not required to reproduce the paper's analytical claims.
