# Predictive-VoI online-policy sanity result

**Technical verdict:** `PASS`

**Scientific verdict:** `STOP_PREDICTIVE_MECHANISM`

**Accepted run:**
`results/tcns_predictive_voi_small_sanity/2026-09-07_110535`

**Source commit:** `7c876ec`; MATLAB R2025a.

## Technical evidence

All 56 preregistered runs completed: two scenarios, 11 periodic arms, 15
predictive-VoI price arms, and two retained reference arms on one development
seed. Every result is finite, no run diverges, all causal/protocol invariants
are zero, and all arms within a scenario consume the same exact forward
trace.

The price sweep produces 15 distinct communication costs in S2 and 13 in S6.
There are 13 and 14 unsaturated predictive points, respectively. Three sparse
points touch command saturation and remain in all raw/frontier data. Periodic
has 11 frontier points in each scenario; predictive VoI has 11 in S2 and 12
in S6, with valid 101-point shared matching domains.

The causal belief mechanics genuinely act. Posterior support reaches eight
candidates, known-failed outstanding records are detected, and the mean
in-flight correction-energy discount is 0.462 in S2 and 0.458 in S6. These
numbers show that the implementation is not merely the ACK-only state-error
boundary.

## Frozen scientific decision

All differences are predictive VoI minus periodic; positive is unfavorable.

| Scenario | Mean budget-matched RMSE difference [m] | Budget overlap favoring predictive | Mean performance-matched cost difference [Hz/channel] | Performance overlap favoring predictive | Predictive-action event allocation |
|---|---:|---:|---:|---:|---:|
| S2 Formation switching | +0.00131 | 7.92% | +0.166 | 66.34% | 1.065 |
| S6 Dynamic excitation | +0.00322 | 5.94% | +0.332 | 37.62% | 1.059 |

The weak headroom clause is met because some performance-matched subdomains
favor predictive VoI. However, both complete-domain mean differences remain
unfavorable, and the mandatory event-concentration threshold of 1.15 fails in
both scenarios. The preregistered conjunction therefore gives
`STOP_PREDICTIVE_MECHANISM`.

No price is selected from the sweep. In particular, isolated high-price
points with larger event-allocation ratios are not promoted: doing so would
discard the frozen complete-grid decision after viewing results.

## Mechanism diagnosis

The preceding receiver-truth diagnostic found that isolated packet value
under Periodic-10 was concentrated at 1.303 in S2 and 1.329 in S6. Thresholding
the causal score does not preserve that concentration in the endogenous
closed loop. Low prices generate nearly continuous actions with allocation
near or below one; intermediate prices increase concentration only modestly;
sparse high-price arms are noisy and have large formation error.

A plausible explanation, supported but not proved by the sweep, is renewal
feedback: after each update the score falls, then smooth leader/follower
motion makes it grow back to an approximately stationary crossing time. Event
amplitude changes the crossing time less than needed to overcome this regular
renewal pattern. The score also measures isolated response energy and omits
the cross term between the action response and the global formation-error /
other-link response. Thus high local information novelty need not equal high
total control benefit.

## Scientific consequence

The five-seed predictive frontier authorized only by a promising sanity result
must not run. Gate 7, scalability and held-out evaluation remain closed. The
following results survive unchanged:

- Gates 1--3 exact model, staleness bounds and conditional robustness
  certificate;
- the exact narrow-scope ACK-conditioned receiver posterior;
- the exact isolated persistent-update energy identity;
- the oracle finding that time-varying state relevance exists;
- two independent negative results showing that a valid local uncertainty or
  isolated-value signal does not automatically produce useful adaptive
  traffic.

Before any third policy is written, the next theory question is whether the
sign of total quadratic marginal value is identifiable from sender-local
information at all. Algebraically, if the no-action predicted formation
response is \(z\) and the action-induced change is \(g\), then the benefit is

\[
\|z\|^2-\|z+g\|^2=-2z^Tg-\|g\|^2.
\]

The implemented score knows \(\|g\|^2\) but not the cross term \(z^Tg\). A
formal indistinguishability/identifiability checkpoint should now determine
whether sender-local data can ever fix its sign. If not, the defensible routes
are either (a) a theory/limitations contribution built around Gates 1--3 and
this information barrier, or (b) an explicitly richer information
architecture that communicates a receiver/control residual. A third local
threshold variation is not authorized.

