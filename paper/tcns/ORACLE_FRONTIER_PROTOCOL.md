# Centralized online-oracle frontier protocol

**Status:** frozen before result generation

**Label:** `centralized_state_oracle`

**Class:** privileged, centralized, online/non-anticipative diagnostic; not an
implementable distributed scheduler and not held-out evidence

## Frozen provenance

The counterfactual history through full commit
`0487e2a5f3e255f59eb0c824be430991eb8d7474` was pushed to
`origin/paper-v3-tcns` before this protocol or O1 code was created. Local and
remote were equal, the worktree was clean, and `tests/test_lock_regression.m`
passed after the push. Scientific history is not squashed or rewritten.

The periodic comparator is the exact Gate-6 family. Its archived audit copy
is run `results/tcns_gate6_nonstationary_frontiers/2026-09-07_012209`, created
at git commit `9d5d8c0`. Periodic arms are rerun in the O1 campaign for paired
traces and current row schema, but core metrics must reproduce that artifact.
This is verification, not refitting.

## Scientific question and scope

On S2 and S6, if a centralized scheduler knows exact **current** receiver
information, can the Gate-3 cross-term allocate DATA better than the frozen
periodic Pareto frontier? O1 tests scheduler headroom, not deployability.

The previous branch result has only this permitted interpretation: on the
preregistered S2/S6 counterfactual branch set, the cross-term predictor
exhibits materially stronger association with realized transmission benefit
than the isolated predictor and perfectly identifies beneficial actions
within the tested top-value quartile. It does not establish general
predictive validity.

## O1 information set

At decision sample (k), O1 may read:

- actual current plant states (P(k),V(k));
- the actual current receiver-held position, velocity and pinned-leader
  payload for each controller-relevant directed link;
- the exact current communication-induced command residual (d_c(k));
- current graph, controller, known channel distribution and current desired
  formation;
- its own past attempts and the deterministic Stage-A forward delay.

O1 may not read future packet outcomes, the pre-drawn drop mask, future
disturbances, future formation values, future leader trajectory or future
plant state. Packets due at (k) are delivered before the decision. The
current attempt's pre-drawn outcome is consumed only after selection and is
used only by the channel and passive logs.

## Exact value equation

Let (m=N-1), (y=[e^\top,(h\dot e)^\top]^\top), and use the exact Gate-3
sampled matrices (A_h,B_c). From current truth, construct the frozen-current
no-action prediction

\[
 y^{0}_{r+1}=A_hy^{0}_{r}+B_c
 \left[d_c(k)+(\pi-\mathbf 1)a_L(k)\right],\quad r=0,\ldots,H-1,
\]

holding only current (d_c(k)), current desired offsets and current leader
acceleration fixed. Let (Z(k)\in\mathbb R^{H\times m\times3}) contain the
predicted follower position-error rows. For a successful current payload on
link (j\to i), let (c_{ij}(k)) be its exact current command correction and
let (G_{ij}(k)) be the position response produced by the existing
`tcnsFiniteHorizonLinkValueKernel` after the declared channel delay. The
ranking value is

\[
 q_{ij}(k)=\frac{p_s}{m}
 \left(\lVert Z(k)\rVert_F^2-
 \lVert Z(k)+G_{ij}(k)\rVert_F^2\right)
 =-\frac{2p_s}{m}\langle Z,G_{ij}\rangle_F
 -\frac{p_s}{m}\lVert G_{ij}\rVert_F^2 .
\]

Here (p_s=1-p_{loss}) is the known current success probability, not the
realized outcome. This is exactly the validated cross-term decomposition; no
AoI/error weights, learned scalar, or retry bonus is added. (H=25) samples
(0.5 s) is frozen from the branch diagnostic.

The unsaturated command implied by the frozen prediction is logged using

\[
 u^0=-H_pe^0-H_v\dot e^0+\pi a_L(k)+d_c(k),
\]

so theorem-scope saturation is measured rather than approximated by residual
magnitude.

## Scheduling and network law

At every 0.02 s control tick, evaluate every active directed ordinary and
pinned-leader payload link. Transmit a link iff

\[
q_{ij}(k)>\lambda.
\]

The only swept resource variable is (lambda). After an attempt, that link
waits one deterministic forward-delay interval before reconsideration. This
is a fixed causal observation constraint: before that time the attempted
payload cannot yet be reflected in current receiver truth. It is not a
tuned retry parameter or score bonus. Existing queued delivery, loss trace,
link-failure and controller mechanics remain unchanged.

O1 obtains receiver truth centrally and therefore sends no ACK. ACK rate is
reported as zero. The cost definition is nevertheless unchanged:

\[
C_{0.25}=\frac{\text{DATA rate}+0.25\,\text{ACK rate}}
                 {\text{configured directed channels}}
\quad[\mathrm{Hz/channel}].
\]

DATA rate, ACK rate, (C_{0.25}), accepted useful deliveries, failed DATA,
and attempts adding no receiver information are reported separately.

## Stage-A frozen matrix

- scenarios: S2 Formation-switching and S6 Dynamic-excitation only;
- development seeds: 27020001--27020005;
- plant: exact double integrator, 30 s mission;
- general cost window: 8--30 s;
- existing scenario-specific performance windows, unchanged;
- periodic sample periods: `1, 2, 3, 4, 5, 8, 10, 15, 20, 25, 40`;
- O1 thresholds:
  `0, 1e-6, 3e-6, 1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 3e-1, 1`;
- five-seed means define operating points;
- weak lower-left Pareto filtering and 101-point matching over each complete
  shared observed domain, with linear interpolation and no extrapolation.

The logarithmic threshold grid was fixed from the previously observed
cross-term scale (approximately (10^{-6}) through (10^{-1})); the zero and
one endpoints capture maximum positive-value service and the silent limit.
No scenario-specific threshold is introduced and no point may be removed for
being unfavorable.

## Matched statistics

For the complete shared budget domain report

\[
\Delta E(B)=E_{O1}(B)-E_{periodic}(B),
\]

and for the complete shared performance domain report

\[
\Delta C(E)=C_{O1}(E)-C_{periodic}(E).
\]

Negative favors O1. For both arrays report fraction negative, mean, median,
minimum (maximum advantage), maximum (maximum disadvantage), zero-crossing
count and longest contiguous advantage. Meaningful pointwise advantage is
preregistered as at least 2% lower RMSE for budget matching and at least 5%
lower cost for performance matching. A nontrivial contiguous segment contains
at least 21 of the 101 ordered matching points (at least 20% of the domain).
A narrow segment contains 11--20 points. Exact zero is not favorable.

A scenario is **convincing** only if, in both matching directions:

1. the mean and median difference are negative;
2. more than half of the complete shared domain favors O1;
3. a meaningful contiguous segment has at least 21 points.

A scenario is **marginal/narrow** when it is not convincing but either:

- both matching directions contain at least 11 contiguous meaningful points;
  or
- both directions have negative mean and median with more than half of their
  domains favoring O1, while failing the 21-point magnitude condition.

Frozen Stage-A classification:

- `O1_STRONG_HEADROOM`: both S2 and S6 are convincing;
- `O1_PARTIAL_HEADROOM`: not strong, but at least one scenario is convincing
  or marginal/narrow;
- `O1_NO_HEADROOM`: neither scenario reaches either definition.

This prevents one isolated crossing from qualifying as headroom.

## Technical validity and mechanism diagnostics

Technical PASS requires all 250 scheduled runs (2 scenarios x 5 seeds x
[11 periodic + 14 O1]) to be finite and nondivergent; exact trace pairing
within scenario/seed; exact reproduction of archived Gate-6 periodic core
metrics; at least three frontier points per family and nonempty two-way
matching; zero O1 ACKs; O1 DATA count equal to scheduled-action count; every
O1 action satisfy its frozen threshold; and all information-privilege flags
remain non-anticipative. Saturation is reported and marks theory scope but
does not delete empirical frontier points.

For each O1 run record:

- event transmission concentration and
  (R_{event}=(\text{event transmission fraction})/
  (\text{event duration fraction}));
- scheduled-value distributions inside/outside event windows;
- accepted useful deliveries, failed attempts and attempts adding no receiver
  information;
- receiver residual before/after accepted updates;
- per-link scheduling frequency;
- stepwise maximum value and cumulative transmissions around events;
- predicted cross term and isolated energy before each action, arrival result,
  and receiver residual before/after delivery.

Realized short-horizon branch benefit is retained as `NaN` in a single O1
trajectory because it is not measurable without a separate counterfactual
rerun. The already frozen forced-branch experiment remains the relevant
measurement; diagnostics are not converted into tuning knobs here.
All thresholds and seeds are retained in the machine-readable traces. Any
compact trace figure uses the five-seed mean at the preselected
\(\lambda=10^{-3}\); it is explanatory and cannot affect classification.

## Post-Stage-A decision

- Strong: run unchanged O1 on S3, S4 and S5 before any distributed policy.
- Partial/no headroom: do not build a distributed policy; preregister and run
  the cheap O2 `noncausal_counterfactual_oracle` diagnostic with (H=25).
- O1 pass plus O2 pass, or O1 pass with little O2 increment:
  `GO_ACK_BELIEF_POLICY`.
- O1 weak/fail plus strong O2: `GO_PREDICTIVE_MODEL_REVIEW`.
- O1 fail plus O2 fail: `STOP_ADAPTIVE_SCHEDULING_DIRECTION`.

Held-out seeds, Gates 7--10, scalability and any ACK-belief scheduler remain
closed throughout this gate.
