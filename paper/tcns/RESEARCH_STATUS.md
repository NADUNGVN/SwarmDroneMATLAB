# TCNS research status

**Status:** Gates 0--6 complete; current mechanism stopped by Gate-6 evidence
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
| Theory checkpoint | **complete** | Gate 4 authorized with explicit conditions |
| Gate 4: control-aware trigger | **complete** | implementation contracts and one-seed sanity pass |
| Gate 5: matched Pareto frontiers | **complete** | stationary periodic frontier dominates |
| Gate 6: nonstationary regimes | **complete** | `STOP_CURRENT_MECHANISM`, 0/5 support |
| Gate 7+: robustness/scalability | **not authorized** | mechanism failed frozen Gate-6 rule |

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
formation connection. The independent checkpoint in
`paper/tcns/THEORY_REVIEW_CHECKPOINT.md` authorizes Gate 4 with conditions. It
closes the distributed-allocation design gap using an equal offline allocation
of a theorem-derived receiver disturbance budget. It also records that a new
transmission does not contract the sender's possible receiver-state set until
an ACK returns, so the policy cannot claim deterministic instantaneous bound
enforcement under stochastic loss. Novelty relative to ACK-state event and
VoI policies remains an explicit unresolved threat.

## Gate-4 execution record

- Policy implementation commit: `10e100c`; preregistered sanity script commit:
  `53eac10`; plot-only correction commit: `4384589`.
- Accepted run: `results/tcns_gate4_small_sanity/2026-09-07_005719`, MATLAB
  R2025a, source commit `4384589`.
- Classification: one fixed development seed and stationary Stressed DI;
  mechanics/falsification only, not evidence of superiority.
- The requested position-degradation budget is the only policy sweep variable:
  \(\epsilon_d=\{0.10,0.20,0.40,0.80\}\) m. The retry interval remains the
  declared inherited 0.10 s value and is not searched.
- Budget algebra, causal set containment, ACK/protocol invariants,
  unsaturated evaluation, common forward trace, branch activity, distinct
  operating points, and monotone traffic ordering all pass.
- P10 gives RMSE 0.1484 m at 9.92 `DATA+0.25 ACK` Hz/channel. Frozen
  Causal-v3 gives 0.1154 m at 23.56 Hz/channel.
- The control-aware sweep goes from 0.1457 m at 18.17 Hz/channel
  (\(\epsilon_d=0.10\) m) to 0.2902 m at 5.67 Hz/channel
  (\(\epsilon_d=0.80\) m).
- At the point below P10's cost, \(\epsilon_d=0.40\) m, control-aware RMSE is
  worse (0.1891 m at 8.71 Hz/channel). Near P10's performance, the
  control-aware point uses substantially more traffic. Thus this stationary
  one-seed run supplies no efficiency advantage over P10.
- The causal local budget is exceeded for 99.8%, 99.7%, 73.5%, and 48.1% of
  controller-relevant link checks across the ordered sweep. This does not
  contradict the conditional theorem, but it shows that the stochastic policy
  does not enforce the premise and that tight \(\epsilon_d\) values saturate
  into near-continuous violation exposure.
- The earlier `005609` run is preserved. It has identical numeric data but a
  plot legend defect; `005719` is the accepted script-generated figure.

Gate 4 therefore passes as an implementation and falsification gate, not as a
performance win. It is scientifically consistent with the hypothesis that a
periodic schedule can be near-optimal in a stationary regime. Gate 5 must now
replace the single P10 comparison with automated frontier and matched-cost /
matched-performance analysis. No \(\epsilon_d\) value from this run is selected
as the proposed operating point.

## Gate-5 execution record

- Frozen protocol: `paper/tcns/GATE5_FRONTIER_PROTOCOL.md`.
- Accepted run:
  `results/tcns_gate5_stationary_frontiers/2026-09-07_010403`.
- Source commit: `88b6705`; MATLAB R2025a; five fixed paired development
  seeds; stationary Stressed DI.
- All 115 runs completed, all control-aware causal invariants are zero, seed
  trace pairing passes, and no run diverges. Two Periodic-40-step runs briefly
  touch saturation and remain explicitly flagged.
- Both periodic and control-aware families contribute 11 Pareto points. Common
  overlap is 2.862--25.975 Hz/channel and 0.1119--0.4924 m RMSE.
- On all 101 automatically budget-matched points, periodic has lower RMSE;
  mean control-aware-minus-periodic difference is `+0.03023 m`.
- On all 101 automatically performance-matched points, periodic has lower
  cost; mean control-aware-minus-periodic difference is
  `+2.092 Hz/channel`.
- No \(\epsilon_d\) or periodic period is selected. Complete raw grids and
  dominated/saturation information are preserved.

The current control-aware mechanism is therefore dominated in the stationary
development regime. This is not a reason to tune it against P10. Gate 6 is the
predeclared decisive test of the separate time-varying-information-value
hypothesis. If automatic frontier matching also finds consistent periodic
dominance there, the current mechanism must stop or be reframed. Full details
and limitations are in `paper/tcns/GATE5_RESULT.md`.

## Gate-6 execution record and stop condition

- Frozen protocol: `paper/tcns/GATE6_NONSTATIONARY_PROTOCOL.md`.
- Accepted run:
  `results/tcns_gate6_nonstationary_frontiers/2026-09-07_012209`.
- Source commit: `9d5d8c0`; MATLAB R2025a; 690 complete runs, six scenarios,
  23 arms and five paired development seeds.
- Technical result: all rows finite, zero divergence, zero control-aware
  causal violations, exact trace pairing, valid frontiers and complete
  101-point bidirectional matching for every scenario.
- Scientific result: every matched RMSE and matched-cost difference is
  unfavorable over every shared-domain grid point in S1--S6. The frozen
  support count is 0/5 nonstationary scenarios versus the required 2/5.
- Mean budget-matched RMSE penalties in S2--S6 range from +0.0111 to
  +0.0196 m. Mean performance-matched cost penalties range from +1.081 to
  +1.456 Hz/channel.
- Event-allocation diagnostics remain close to one rather than showing strong
  concentration: 1.032 in S2, 1.002 in S4, 0.967 in S5 and 1.071 in S6 when
  averaged over control-aware sweep arms.
- Forty-nine saturated runs are retained and flagged, predominantly in the S5
  topology outage; they are empirical results outside the linear theorem.

The current Gate-4 mechanism is stopped exactly as preregistered. Gate 7,
scalability and held-out evaluation must not run until an explicit scientific
redirection is chosen. Gates 1--3 remain valid theory results; the trigger's
performance hypothesis does not. Full evidence and permitted next directions
are documented in `paper/tcns/GATE6_RESULT.md`.

## Post-Gate-6 mechanism-reset record

- Frozen protocol:
  `paper/tcns/POST_GATE6_VOI_DIAGNOSTIC_PROTOCOL.md` at commit `74487c8`.
- Accepted run:
  `results/tcns_post_gate6_oracle_value_diagnostic/2026-09-07_093357`.
- Source commit: `f5fc880`; MATLAB R2025a; 15 Periodic-10 development runs
  over S1/S2/S6 and seeds 27020001--27020005.
- The exact isolated persistent-update kernel follows directly from the
  Gate-3 sampled recurrence. Its independent three-axis reconstruction has
  maximum numerical residual `1.735e-17`.
- All evaluated trajectories are unsaturated, and optional periodic
  receiver-memory logging is behaviorally inert.
- S2 formation switching has mean event-value allocation ratio 1.3033 and
  mean paired temporal-CV ratio to S1 1.3196.
- S6 dynamic excitation has corresponding ratios 1.3294 and 1.5200.
- Both exceed both thresholds frozen at 1.25, giving the preregistered
  decision `SIGNAL_PRESENT`.
- The lowest per-seed event allocation ratios are 1.1763 and 1.1688, so the
  evidence is mean-level headroom rather than a universal per-run result.

This does not reverse the Gate-6 falsification. It shows only that an oracle
receiver-content signal contains time concentration that the stopped policy
failed to exploit. The authorized next step is a causal receiver-belief and
in-flight marginal-value derivation. Until that derivation passes algebraic
and causality tests, no new online policy, large grid, scalability campaign or
held-out evaluation is authorized. Full interpretation and proof gaps are in
`paper/tcns/POST_GATE6_VOI_DIAGNOSTIC_RESULT.md`.

## Causal one-shot VoI checkpoint and online sanity

- `paper/tcns/CAUSAL_VOI_BELIEF_CHECKPOINT.md` proves an exact
  sender-side receiver-payload posterior under static IID DATA loss,
  deterministic sampled DATA/ACK delays, reliable ACKs and complete
  outstanding history.
- The corresponding isolated expected action value credits useful in-flight
  packets and maps their directional controller correction through the exact
  Gate-3 finite-horizon kernel. Unit tests verify posterior probabilities
  `[0.04, 0.16, 0.80]`, an exact 0.2 residual value when a current-state
  packet has 0.8 success probability, and invariance to hidden simulator drop
  flags.
- Online policy implementation commit: `0b81877`; preregistered sanity
  protocol/script commit: `7c876ec`.
- Accepted run:
  `results/tcns_predictive_voi_small_sanity/2026-09-07_110535`, MATLAB
  R2025a; 56 complete one-seed development runs in S2 and S6.
- Technical status is PASS: finite complete matrix, exact trace pairing, zero
  divergence/protocol violations, 15/13 distinct predictive cost points and
  valid automatic frontiers/matching. Three saturated sparse points remain
  retained and flagged.
- Causal belief support reaches eight candidates; mean in-flight discount is
  0.462 in S2 and 0.458 in S6, so the mechanism is distinct from its ACK-only
  state-error boundary.
- Mean matched results remain unfavorable: predictive-minus-periodic RMSE is
  +0.00131 m (S2) and +0.00322 m (S6); matched cost is +0.166 and +0.332
  Hz/channel.
- Predictive-action event allocation is only 1.065 and 1.059, failing the
  frozen 1.15 threshold in both scenarios.

The scientific decision is `STOP_PREDICTIVE_MECHANISM`. No five-seed expansion
or price selection is permitted. The next authorized work is an
information-identifiability analysis of the missing global quadratic cross
term, not another local trigger variation. Full evidence and interpretation
are in `paper/tcns/PREDICTIVE_VOI_SANITY_RESULT.md`.

## Sender-local value-identifiability checkpoint

`paper/tcns/LOCAL_VOI_IDENTIFIABILITY_CHECKPOINT.md` gives an exact
finite-horizon quadratic decomposition and proves the conditional criterion
for deciding an action's marginal-benefit sign from a sender information set.
The benefit depends on
\(-2\langle Z,G\rangle-\|G\|^2\): the stopped predictive policy computes the
isolated response energy but does not observe the global baseline-response
cross term.

An executable witness constructs \(G\) from the exact Gate-3 sampled matrices.
The hidden baselines \(Z=-G\) and \(Z=+G\) produce respectively
\(+\|G\|^2\) and \(-3\|G\|^2\) benefit with the same action response. This
establishes the algebraic information barrier, while full reachability of two
dynamically consistent indistinguishable swarm histories remains explicitly
marked `PROOF GAP IV.1`.

Decision: `LOCAL_VALUE_SIGN_NOT_IDENTIFIED`. The next authorized work is a
small offline centralized cross-term oracle audit. No new sender-local scalar
threshold is authorized before that audit establishes whether total
marginal-value headroom exists.
