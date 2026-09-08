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
```

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
