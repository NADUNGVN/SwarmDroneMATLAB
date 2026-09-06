# Post-EXP18B scientific audit — research decision before manuscript work

**Audit status:** post-hoc and descriptive; no new confirmatory claim.  
**Frozen source result:** `exp18b_preregistered_holdout/2026-08-31_152137`.  
**Research decision:** `CURRENT_CANDIDATE_NOT_SUBMISSION_READY`.

## Why this audit exists

EXP18B passed its registered contract: 8,000/8,000 simulations, 21/21
integrity gates, 9/9 Holm-adjusted hypotheses, exact fixed-route aliasing and
the registered boundary safety guard. Those facts remain valid.

Passing the protocol is not the same as showing that the complete candidate is
a strong communication policy. This audit asks the stricter submission-level
question: after correcting access geometry, does the selected standalone-ACK
route add value over the simplest frame-aware piggyback comparator?

No p-value from this audit is promoted. Paired 95% intervals are descriptive
diagnostics used only to choose the next development question.

## Finding 1 — the selected adaptive route fails in every feasible ALOHA cell

The service screen marks three registered ALOHA contexts feasible. In all
three, the capacity-gated candidate selects frame-aware adaptive standalone
feedback. Piggyback is lower on both RMSE and offered utilization, with both
paired intervals below zero for piggyback minus adaptive:

| Context | Piggyback minus adaptive RMSE | Piggyback minus adaptive offered load | Candidate route | Audit result |
|---|---:|---:|---|---|
| N5 Moderate bg0 | -0.004767 m | -0.008483 | adaptive | piggyback dominates |
| N5 Moderate reverse | -0.004050 m | -0.012956 | adaptive | piggyback dominates |
| N5 Moderate hidden | -0.004767 m | -0.008483 | adaptive | piggyback dominates |

Across the full matrix, eight operationally safe and interval-resolved
context--MAC cells favor piggyback; zero favor adaptive. This is stronger than
the earlier single-cell warning. It means the current selector chooses the
wrong resolved route in 3/3 feasible ALOHA cells.

Consequently:

- standalone ACK cannot remain the primary method novelty;
- EXP18B cannot be summarized as validation of an optimal or robust selector;
- exact route aliasing proves implementation honesty, not route quality.

## Finding 2 — the capacity screen remains useful but only as a sufficient gate

At the context-mean level:

- all nine screen-positive context--MAC cells have observed per-node DATA
  goodput above the 8.333-Hz requirement;
- there are zero screen-positive/mean-negative cells;
- one screen-negative cell, N5 Stressed bg0 ALOHA, nevertheless has mean
  goodput above the target.

The last cell is a conservative false negative, not a contradiction. The
screen is retained as a one-sided operating-point gate. It is not a necessity
test, trajectory guarantee, formation-safety certificate or calibrated
probability of feasibility.

## Finding 3 — EXP18B H8--H9 do not isolate access repair

The registered N10 ALOHA contrast compares the capacity-gated candidate with
the legacy selector. In all four N10 ALOHA cells, these arms differ in two
ways:

1. access probability: frame-aware `1/[N(2L_D-1)]` versus legacy `1/N`;
2. feedback route: piggyback versus adaptive standalone feedback.

Therefore H8--H9 confirm a bundled policy contrast, not access causality by
itself. The manuscript must not call those two tests a clean access ablation.

The retained `frame-adaptive` arm permits a matched descriptive isolation. It
holds adaptive feedback fixed and changes only access geometry. Across all four
N10 ALOHA core contexts, frame-aware access has intervals entirely below zero
for collisions and offered load. For example:

| Context | Collision-frame difference | Offered-load difference | RMSE difference |
|---|---:|---:|---:|
| N10 Moderate bg0 | -4300.84 | -1.30708 | -0.21560 m |
| N10 Moderate bg0.30 | -2997.29 | -0.97610 | -0.18625 m |
| N10 Stressed bg0 | -4135.23 | -1.25501 | -0.22232 m |
| N10 Stressed bg0.30 | -2840.20 | -0.92557 | -0.15331 m |

This is strong development evidence that frame-aware access matters. Because
it was not the registered H8--H9 estimand, it remains descriptive until a
clean independent validation is run.

## Finding 4 — several cells are resource-infeasible, not ACK-route problems

The candidate still observes 67--100 failures per 100 runs in several N10 or
background-loaded ALOHA cells, and 100/100 in multiple screen-negative cells.
Changing ACK route cannot create missing DATA capacity. Continuing to tune an
ACK score would optimize a secondary decision while the primary service region
is already violated.

This closes the ACK-selector method cycle. EXP18A2/A3 already failed to produce
a defensible causal marginal-value rule, and EXP18B shows that even the simpler
fixed adaptive branch is dominated after access is repaired.

## Research decision

Retain:

- causal confirmed-age invariants;
- the analytical capacity screen as a sufficient gate;
- frame-length-aware access scaling;
- piggyback cumulative feedback;
- all negative ACK-value and operating-envelope evidence.

Stop:

- standalone ACK as the main novelty;
- the current capacity-gated ACK selector as a submission candidate;
- policy-specific hardware validation or UAV procurement.

Permit:

- software work for measured-trace/radio interfaces;
- a development-only oracle diagnostic asking whether semantic admission or
  scheduling has any headroom over frame-aware piggyback.

## Next gate

EXP19A must test the action space before another deployable heuristic is built:

> Can an oracle service-aware semantic scheduler improve control and resource
> use over frame-aware piggyback in capacity-deficit cells?

If even a receiver-state/central scheduling reference cannot produce a useful
Pareto improvement, service-aware policy development stops. If oracle headroom
exists, EXP19B may build a causal distributed approximation on new development
seeds. No confirmatory holdout is opened at this stage.

## Machine-readable artifacts

- `posthoc_route_value_audit.csv`
- `posthoc_service_screen_audit.csv`
- `posthoc_access_isolation_audit.csv`
- `posthoc_research_gate_verdict.json`

All reside in the canonical EXP18B run directory. The analyzer is
`experiments/analyzeExp18BScientificAudit.m`; its classification contracts are
covered by `tests/test_exp18b_scientific_audit_contracts.m`.
