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

### 3. Principal paper figures

    matlab -batch "run('paper/tcns/manuscript/make_gm_figures.m')"

The script reads only frozen machine-readable evidence and writes all six
main figures to **paper/tcns/manuscript/figures/**. Scientific data are not
edited manually.

### 4. Build the paper

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
