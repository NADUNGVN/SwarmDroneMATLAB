# TCNS research status

**Status:** Gate 0 in progress  
**Scientific direction:** control-aware information freshness for distributed
multi-UAV formation control under unreliable communication

The exact implementation mapping, current experiment/policy inventory,
candidate assumptions, candidate statements, proof gaps, and minimum diagnostic
are recorded in `INITIAL_TECHNICAL_AUDIT.md`.

## Gate ledger

| Gate | State | Evidence |
|---|---|---|
| Initial audit | complete | commit `a4a49f3`; requested tree identified exactly |
| Gate 0: baseline reproduction | in progress | selected replay and full EXP10 reproduction pending |
| Gate 1: exact mathematical model | not started | blocked by Gate 0 |
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

The status of Gate 0 must not be changed to complete until both commands pass
and their machine-readable result directories are recorded here.
