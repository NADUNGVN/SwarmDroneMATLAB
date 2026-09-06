# EXP18A3 freshness-headroom development results

## Canonical result

- Run: `2026-08-31_124628`
- Matrix: 400/400
- Integrity: 14/14, zero protocol violations
- Decision gates: 7/8
- Verdict: `REJECT_OR_REVISE_FRESHNESS_HEADROOM`

Freshness headroom lowers standalone ACK use relative to EXP18A2 but does not
produce the registered CSMA piggyback route. Mean standalone ACK counts remain
52.65 (N5 Moderate), 19.20 (N5 Stressed), 19.10 (N10 Moderate) and 0.20
(N10 Stressed) in the four feasible CSMA core cells. Consequently none can be
declared an exact piggyback alias; maximum registered outcome/count differences
are nonzero.

The remaining seven gates pass, including feasible coverage, failure guards,
ALOHA activity, exact infeasible abstention, absolute collision repair and the
reverse-calibration boundary. They do not override the failed route gate.

## Stop decision

No additional coefficient or threshold is fitted to the marginal-value score.
The heuristic ACK-value branch is stopped after two development versions. A
simpler capacity-gated selector is the only allowed continuation:

- certificate infeasible: abstain and use piggyback-only;
- certificate feasible + configured CSMA: piggyback-only;
- certificate feasible + configured ALOHA: the existing legacy adaptive route.

This returns route choice to auditable fixed components and makes the new claim
the analytical feasibility gate plus abstention, not a learned or universally
optimal per-ACK value function.

