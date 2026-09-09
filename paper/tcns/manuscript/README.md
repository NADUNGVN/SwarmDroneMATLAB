# TCNS submission-candidate manuscript source

Main source:

`tcns_information_limits.tex`

Regenerate every main figure from frozen machine-readable evidence in MATLAB:

```matlab
run('paper/tcns/manuscript/make_gm_figures.m')
```

Re-run the theorem validation used by the manuscript:

```matlab
run('tests/test_tcns_information_limits.m')
run('experiments/tcns_information_limits_validation.m')
run('tests/test_tcns_r2_generalization.m')
run('tests/test_tcns_actual_witness_audit.m')
run('experiments/tcns_r2_generalization_validation.m')
run('tests/test_tcns_r2_5_persisted_witness_replay.m')
run('tests/test_tcns_r2_5_adversarial_artifact.m')
run('experiments/tcns_r2_5_adversarial_validation.m')
run('tests/test_tcns_r2_6_decision_identifiability.m')
run('tests/test_tcns_r2_7_common_fiber.m')
```

The accepted theory-only R2.6 post-processing artifact is
`results/tcns_r2_6_decision_identifiability/2026-09-08_232116/`. It reads the
frozen R2 registry and witnesses and does not run a new simulation.

The accepted R2.7 common-fiber replay artifact is
`results/tcns_r2_7_common_fiber/2026-09-09_121641/`. Its protocol and result
commits are `55340bff657d8881482810b9ca457d736951c0b5` and
`105183e255df2849dbc6d00f35f312ce5d4d5f7a`; it reads only the ten persisted
N=5 centers and runs no new simulation.

Compile from this directory in an IEEEtran-capable TeX installation:

```text
pdflatex tcns_information_limits.tex
bibtex tcns_information_limits
pdflatex tcns_information_limits.tex
pdflatex tcns_information_limits.tex
```

The source now loads the separate submission metadata file. That file contains
explicit human-input placeholders because no verified
author/affiliation/contact metadata exists in the repository. Replace those
fields before portal upload; do not infer them.

Empirical figures use frozen development evidence and must not be described as
held-out population validation. See REPRODUCIBILITY.md for the minimal public
workflow and the submission README for the package manifest.
