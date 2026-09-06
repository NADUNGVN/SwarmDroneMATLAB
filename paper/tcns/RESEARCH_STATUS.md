# TCNS research status

**Status:** Gate 0 complete; Gate 1 authorized
**Scientific direction:** control-aware information freshness for distributed
multi-UAV formation control under unreliable communication

The exact implementation mapping, current experiment/policy inventory,
candidate assumptions, candidate statements, proof gaps, and minimum diagnostic
are recorded in `INITIAL_TECHNICAL_AUDIT.md`.

## Gate ledger

| Gate | State | Evidence |
|---|---|---|
| Initial audit | complete | commit `a4a49f3`; requested tree identified exactly |
| Gate 0: baseline reproduction | **complete** | full EXP10 and EXP11 reproductions plus post-repair regression |
| Gate 1: exact mathematical model | next | Gate 0 no longer blocks work |
| Gate 2: staleness to uncertainty | not started | blocked by Gate 1 |
| Gate 3: uncertainty to formation | not started | blocked by Gate 2 |
| Theory checkpoint | not started | blocked by Gate 3 |
| Gate 4: control-aware trigger | not started | blocked by checkpoint |

## Frozen canonical evidence

- EXP10: `results/exp10a_final_validation/2026-08-27_091546`, 3400 rows,
  50 paired seeds, MATLAB R2025a.
- EXP11: `results/exp11_dynamic_network/2026-08-27_174026`, 400 rows,
  50 paired seeds, MATLAB R2025a.
- EXP11 `LATEST.txt` currently identifies `2026-08-27_175335`, a separate
  24-row, 3-seed debug pass. It is preserved but is not canonical evidence.

## Current accepted negative/boundary findings

- In Clean, P10 has both lower nominal 6-DOF formation RMSE and lower
  `DATA+0.25 ACK` cost than Causal-v3.
- In Moderate and Stressed, Causal-v3 improves RMSE over P10 by purchasing
  substantially more ACK-inclusive traffic; this is not a matched-budget win.
- Under broadcast accounting in EXP11, Causal traffic is substantially larger
  than the fixed-period alternatives.
- Existing sampled ISS constants are too conservative for a meaningful
  numerical performance certificate.
- `cfg.swarm.maxSpeed` is not enforced and cannot support a theorem.
- The current linear proof excludes saturation, nonlinear 6-DOF dynamics, and
  directed/switching graphs.

## Gate-0 reproduction commands

From MATLAB R2025a at repository root:

```matlab
startup;
run('experiments/tcns_gate0_baseline_audit.m');
```

After the fail-fast audit passes, the mandatory full frozen reproduction is:

```matlab
startup;
v1ForceRun = true;
run('experiments/run_simulation_v1_validation.m');
```

EXP11 is reproduced independently with:

```matlab
startup;
run('experiments/exp11_dynamic_network.m');
```

## Gate-0 execution record

### Starting snapshot identity

- Requested object `954fbf22ee37039619b3dd4b04d4dc4b22f85f86`
  is the tree of commit `dbbb4197849694154cfec769d18fc4b38b05f0ad`.
- The initial audit and every later reproduction verify that this starting
  commit is an ancestor of the executing commit.

### Fail-fast selected replay

- Initial run: `results/tcns_gate0_baseline_audit/2026-09-06_140652`.
- Final post-repair run:
  `results/tcns_gate0_baseline_audit/2026-09-06_193337`.
- Both replay N=5 6-DOF, first frozen seed `25000001`, Clean/Moderate/Stressed,
  and P10/Causal-v3.
- Verdict: 6/6 rows match canonical RMSE, minimum separation, saturation,
  transmission counts, exact realization hashes, and invariant counts.

### Full EXP10 reproduction

- Validation: `results/simulation_v1_validation/2026-09-06_140912`.
- Reproduced dataset:
  `results/exp10a_final_validation/2026-09-06_141912`.
- Derived unified matrix:
  `results/exp10b_unified_matrix/2026-09-06_145037`.
- MATLAB R2025a, source commit `ddfd669475ee66656c280d07a08224eda1281293`.
- 3400 rows, 50 paired seeds, 68/68 tests, 10/10 required tags, 0
  realization-hash mismatch, serial/parallel trajectories and counters
  bit-identical, all seven validation stages PASS.
- Reproduced and canonical `tidy.csv` files are byte-identical with SHA-256
  `94076C0FE5996632041E42716D6361980F70A30D82C4514DAEBB7E5C5EADD727`.

### EXP11 packaging failure and repair

The first explicit rerun is preserved at
`results/exp11_dynamic_network/2026-09-06_191734`. It stopped before simulation
because the paper branch retained EXP11 data but omitted its executable source,
five schedule/method helpers, five additional utility helpers, its simulator
wrapper, seven regime hooks, and its semantics test.

Gate 0 restored the exact historical EXP11 code from commit `85ead26` and
registered `test_exp11_regime_semantics` in the current suite. This changes no
trigger parameter or scenario. After restoration:

- locked EXP05--EXP07 regression: PASS;
- causal invariants: PASS;
- EXP11 regime semantics: 24/24 PASS;
- final selected EXP10 replay: 6/6 PASS.

### Full EXP11 reproduction

- Reproduced dataset: `results/exp11_dynamic_network/2026-09-06_192155`.
- MATLAB R2025a, source commit `8e40d46`.
- 400 rows, 50 paired seeds, 7/7 gates, 24/24 semantics checks, zero
  divergence, zero causal invariant violations.
- Canonical and reproduced CSVs are character-identical after normalizing
  CRLF/LF. The normalized SHA-256 of `tidy.csv` is
  `0D1272D35820643771C007099455056976399EB5F66CA234D1873B9EB77F0561`.
  The only raw-file difference is Windows line-ending convention.

Gate 0 is therefore complete. No scientific result was selected or tuned in
this process, and every failed attempt remains preserved.
