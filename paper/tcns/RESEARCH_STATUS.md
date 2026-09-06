# TCNS research status

**Status:** Gates 0--3 complete; theory-review checkpoint next
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
| Gate 1: exact mathematical model | **complete** | exact real-step audit and corrected analytical-leader residual |
| Gate 2: staleness to uncertainty | **complete** | follower and analytical-leader bounds proved and validated |
| Gate 3: uncertainty to formation | **complete** | structured ISS/UUB theorem and numerical validation |
| Theory checkpoint | next | audit Gates 1--3 before trigger design |
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

## Gate-1 execution record

- Theory/model ledger: `paper/tcns/THEORY_NOTES.md`.
- Executable audit: `experiments/tcns_gate1_model_audit.m`.
- Result: `results/tcns_gate1_model_audit/2026-09-06_194134`.
- Source commit: `31ff907`.
- MATLAB R2025a; no stochastic input is used in the one-step fixtures.
- Exact exported plant matrices use semi-implicit Euler with input coefficient
  `h^2`, not `h^2/2`.
- `rho(Ah) = 0.983581750611` for the default fixed undirected grounded cell.
- Maximum real-controller versus matrix-controller residual:
  `2.776e-16`.
- Maximum real-integrator versus exact sampled-state residual: `9.237e-17`.
- The older `(Pi-I)*aL` sampled shorthand produces a nonzero residual
  `2.133e-06` under changing takeoff acceleration. The exact model now retains
  both analytical leader position-step and velocity-step residuals.
- Both fixtures are strictly below acceleration saturation; `maxSpeed` remains
  explicitly marked unenforced.
- `test_tcns_gate1_model_mapping` and the pre-existing formation certificate
  test pass. A directed fixture is correctly refused the symmetric theorem.

Gate 1 establishes the exact analytical subsystem and its limitations. It does
not claim the Gate-2 staleness envelope or Gate-3 ISS/UUB result.

## Gate-2 execution record

- Accepted run:
  `results/tcns_gate2_staleness_bound_diagnostic/2026-09-06_195924`.
- Source commit: `36bfb69`; MATLAB R2025a.
- Classification: development-only bound validation, not a policy comparison.
- Fixed seeds: 27020001--27020005; N=5; Stressed channel with 0.4 DATA loss
  and 0.12 s delay; exact-state semi-implicit double integrator.
- No policy/trigger parameter was searched. Frozen Causal-v3 supplied varied
  receiver ages only.
- Follower evidence: 45,030 directed-link samples, position and velocity
  coverage 1.0 for every link/seed, maximum excess $5.551\times10^{-17}$ m
  and $2.776\times10^{-17}$ m/s.
- Local accepted-payload-speed position bound: mean p95 tightness 0.7467.
- Global AoI-only position bound: mean p95 tightness 0.00746. It is valid but
  scientifically too loose because the only defensible 30 s velocity envelope
  is 60 m/s and the configured `maxSpeed` is not enforced.
- Ordinary leader and pin-stream P/V/A envelopes have coverage 1.0. Their
  dedicated proof includes the velocity and acceleration jumps at the
  analytical trajectory switch $t=3$ s.
- Timestamp convention and accepted-payload reconstruction have zero residual.
- Earlier runs `194936`, `195059`, and `195402` are retained as development
  history. `195924` is the first full run from committed source including the
  analytical-leader bound.

Gate 2 establishes a useful local age/state envelope and simultaneously
falsifies the usefulness of the current global AoI-only envelope. Gate 3 must
now map the local uncertainty budgets through the exact formation dynamics;
it must not substitute the loose global envelope merely because it is easier
to decentralize.

## Gate-3 execution record

- Accepted run:
  `results/tcns_gate3_formation_robustness_diagnostic/2026-09-07_003518`.
- Source commit: `6b92074`; MATLAB R2025a.
- Fixed development seeds 27020001--27020005, Stressed channel, exact-state
  N=5 DI subsystem, evaluation continuation from 8 s.
- No policy or threshold was tuned; the comparison is stale information
  versus a perfect-current-information counterfactual initialized at the same
  state, not Causal-v3 versus Periodic10.
- New causal mechanism: the sender's possible receiver-state set consists of
  the cumulatively ACK-confirmed payload plus every later outstanding payload.
  It provably contains receiver memory without reading delivery/drop outcomes.
- Exact degradation recurrence residual: at most
  $4.441\times10^{-16}$.
- Position/scaled-velocity/formation coverage: 1.0 for every seed.
- Propagation-only p95 tightness: 0.9981.
- Full causal bound p95 tightness: 0.4827, compared with 0.0859 for the
  Gate-2 hard-acceleration envelope.
- Mean degradation RMS: 0.1093 m actual versus 0.2421 m upper bound.
- Mean formation RMSE: 0.1169 m actual versus 0.2602 m upper bound.
- Mean structured UUB: 0.518 m. Applying the old generic Lyapunov gain to the
  same causal input budget gives 2246 m and is rejected as numerically useless.
- The theorem is conditional on the declared post-acquisition interval where
  both stale and perfect DI commands remain unsaturated. It does not prove the
  6-DOF, switching/directed graph, or estimator cases.

Gate 3 supplies the requested staleness/state uncertainty to closed-loop
formation connection. Gate 4 is not yet authorized until the theory checkpoint
confirms that its distributed link-budget construction does not reintroduce an
oracle or collapse to the existing state-event trigger.
