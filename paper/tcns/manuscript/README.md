# TCNS GM manuscript source

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
```

Compile from this directory in an IEEEtran-capable TeX installation:

```text
pdflatex tcns_information_limits.tex
bibtex tcns_information_limits
pdflatex tcns_information_limits.tex
pdflatex tcns_information_limits.tex
```

The manuscript is intentionally anonymized for internal review.  It is not a
submission artifact.  Empirical figures use frozen development evidence and
must not be described as held-out population validation.

