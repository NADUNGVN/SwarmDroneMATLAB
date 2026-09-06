# EXP23AO multi-origin routed-control development plan

Frozen: 2026-09-06, before execution of seeds 16094901--16094905.

## Purpose

EXP23AN validates one routed logical packet at a time. The closure protocol can
emit multiple CLAIM/LOCK-PROOF or RESPONSE packets in the same phase. Serially
composing individually over-protected routes is correct but too slow. EXP23AO
tests a joint multi-origin scheduler and a cross-layer allocation of reliability
between hop repetitions and existing outer protocol retries.

This remains a development diagnostic on the retained N=10 online fixture. It
does not drive the plant or permit a fresh/robustness/submission claim.

## Multi-origin scheduler

Each `(packet identity, route transmitter)` is a non-preemptive repetition
block. A serial concatenation of the EXP23AN single-packet schedules is the
feasible incumbent. Tasks are processed in deterministic incumbent order and
left-shifted only when all of the following hold:

- the complete parent block of the same packet has finished;
- no concurrent task uses the same sender;
- no receiver-level conflict exists under physical interference, full direct
  reach, intended receivers and half duplex;
- packet/version identity remains separate in `known(packet,node)` state.

No task can move later than the incumbent, so compacted makespan is never worse
than serial. Runtime independently recomputes collisions and derives offered
airtime from integer physical bytes.

## Cross-layer reliability

For link erasure `p`, hop repetition `r` and path depth `h`, one logical
sender-to-receiver obligation has erasure

`q(h,r) = 1 - (1-p^r)^h`.

These path-specific values replace scalar receiver erasures in the existing
phase-reserved transaction certificate. Temporal independence is required for
repeated attempts of the same packet/link path. Correlation among different
obligations is allowed because their failures are combined by a union bound.

The frozen grid uses one uniform `r` in {1,...,7}. For each `r`, the diagnostic
enumerates PREPARE attempts 2--7, CLAIM attempts 3--15, every nonempty
evidence/response split, and COMMIT attempts 2--6. The selected point is the
minimum conservative transaction time subject to failure below `10^-3`.

Calibration fixed uniform `r=4`, PREPARE=3, CLAIM=4 with 2 evidence-prefix and
2 response-suffix opportunities, COMMIT=2, and maximum phase index 11. A mixed
kind-specific repetition vector improved the time estimate by only 14.5 ms
while adding three policy parameters, so it is not promoted.

The conservative time model charges each PREPARE round for PREPARE,
QUIESCENT and all DATA slots; each CLAIM round for EVIDENCE, RESPONSE and DATA;
each COMMIT round for COMMIT and DATA; and the two eligibility-delay frames for
DATA. Bundle slots use their largest actual routed packet, not a fictitious
96-byte payload for every kind.

## Registered bundles and replay

Five phase bundles are fixed:

1. PREPARE: 1 logical / 1 routed packet;
2. QUIESCENT: 3 / 3;
3. EVIDENCE (CLAIM + LOCK-PROOF): 10 / 10;
4. RESPONSE: 10 logical / 9 routed plus one local-only response;
5. COMMIT: 1 / 1.

At selected `r=4`, each bundle receives 5,000 independent replay trials. Gates
compare empirical all-packet failure with the exact product certificate using
five binomial standard errors plus `1/n`. A deterministic packet-blackout
negative must suppress only the targeted packet and leave all other packet
states intact.

## Frozen gates

Sixteen gates require: exact valid EXP23AN parent; source/tests and version
identity; exact bundle membership; admissible conflict-free precedence;
independent no-loss delivery; serial-incumbent non-regression and visible
compaction; integer bytes/derived airtime; packet-version isolation; exact
multi-origin probability and union ordering; Monte Carlo agreement with zero
physical collision; exact routed endpoint-cache replay; complete retry grid;
visible infeasible `r=1` and over-budget `r=2` boundaries; registered `r=4`
selection and retry allocation; transaction failure/time feasibility; and all
downstream scope flags remaining false.
