# EXP19 research program — service-aware semantic admission and scheduling

**Status:** EXP19A completed; registered promotion rejected.  
**Execution:** `2026-08-31_175039`, 1,620/1,620 trajectories.  
**Submission and hardware claims:** prohibited.

## 1. Motivation fixed by EXP18B

After frame-length-aware access is applied, piggyback dominates adaptive
standalone feedback in all three feasible ALOHA cells and in every safe,
interval-resolved cell. Several remaining failures occur where estimated DATA
service is below the existing freshness demand. The next controllable object
is therefore DATA admission/service allocation, not ACK route.

EXP19 does not attempt another ACK threshold. Standalone ACK is disabled in all
candidate and matched scheduling arms; cumulative feedback is piggybacked.

## 2. Mathematical action space

Let `a_j(k)` be admitted semantic DATA demand for sender `j`, `mu_j(k)` its
successful service, and `w_j(k)` a semantic urgency derived from causal sender
state: innovation, confirmed worst-neighbor age, queue age and max-silence.
Introduce a virtual service-deficit queue

```text
Z_j(k+1) = max(0, Z_j(k) + a_j(k) - mu_j(k)).
```

For a feasible service region `Lambda(k)`, an ideal max-weight decision is

```text
mu*(k) in argmax_{mu in Lambda(k)} sum_j [Z_j(k)+eta*w_j(k)] mu_j.
```

This is initially an oracle/reference, not the proposed deployable method.
`eta` is not tuned in EXP19A: report the two endpoints separately:

- deficit-only (`eta=0`);
- urgency-only after normalizing each weight by its declared threshold.

A later causal candidate is permitted only if these references demonstrate
headroom over frame-aware piggyback. Any Lyapunov-drift statement will concern
virtual-queue stability under a declared interior service condition; it may not
be converted directly into formation safety.

## 3. EXP19A — oracle action-space diagnostic

### 3.1 Question

Does collision-free or max-weight allocation improve enough over frame-aware
piggyback to justify designing a distributed service-aware policy?

### 3.2 Evidence status and seeds

- Development-only seeds: `16026001:16026030`.
- These seeds are disjoint from EXP12--EXP18B.
- Outcomes may be inspected; no p-value or confirmatory claim is permitted.
- No holdout seed is reserved until an implementable candidate passes the full
  development gate.

### 3.3 Frozen diagnostic contexts

Use six contexts chosen by mechanism, not by favorable outcome:

1. N5 Moderate bg0 ALOHA — feasible reference where ACK selection failed;
2. N5 Stressed bg0 ALOHA — closest screen-negative, operational boundary;
3. N5 Moderate bg0.30 CSMA — screen-negative but operational under EXP18B;
4. N5 Stressed bg0.30 CSMA — near operational failure boundary;
5. N10 Moderate bg0 ALOHA — capacity deficit with partial failure;
6. N10 Stressed bg0 ALOHA — capacity deficit with collapse.

### 3.4 Arms

1. `frame-piggyback`: strongest causal fixed baseline;
2. `capacity-gated-selector`: retained negative control;
3. `collision-free-tdma-piggyback`: scheduling/service upper reference with
   the same trigger, packets and piggyback feedback;
4. `oracle-deficit-maxweight-piggyback`: current receiver/service state may be
   used to rank queued DATA, but no future random outcome may be read;
5. `oracle-urgency-maxweight-piggyback`: normalized semantic urgency ranking;
6. `periodic-tdma-frontier`: fixed rates around the 8.333-Hz target, retained
   so an oracle event policy cannot win merely because TDMA removes collision.

The implementation fixes that frontier at `6.25`, `8.333333`, `10`, and
`12.5` Hz. Collision-free round robin advances a persistent node cursor only
at an idle service opportunity; it does not use absolute slot index modulo
`N`, which would starve nodes when frame length and `N` share a divisor.

For the urgency endpoint, a queued DATA frame from sender `j` has the exact
development weight

```text
w_j = max { max_i ||p_j^q-p_ij^rx||/epsilon_p,
            max_i ||v_j^q-v_ij^rx||/epsilon_v,
            max_i A_ij^true/A_bar,
            queue_age_j/A_bar,
            service_silence_j/tau_max }.
```

Here `q` denotes the current queued payload and `rx` the current receiver
cache. All quantities are evaluated at the current slot. The scheduling
function has no channel-trace argument. The deficit endpoint uses only `Z_j`.
Ties in either endpoint are resolved by oldest queued frame, then node index.

The oracle arms are performance references. They are not causal sender-only
policies and cannot be submitted as the solution.

### 3.5 Outcomes

Primary development axes:

- RMSE;
- offered utilization;
- observed safety failures;
- per-node DATA goodput margin relative to 8.333 Hz.

Mechanism outputs:

- collisions and retries;
- admission/replacement count;
- virtual deficit queue and maximum starvation interval;
- true/confirmed AoI;
- per-node goodput fairness;
- fraction of decisions where oracle priority differs from ordinary FIFO.

### 3.6 Integrity gates

- complete unique seed/context/arm matrix;
- exact absolute trace and channel-state pairing where MAC semantics permit;
- no standalone ACK in all scheduling arms;
- finite queues, bounded history and zero protocol violations;
- receiver-state oracle reads present/past truth only, never future uniforms;
- oracle decision log identifies eligible set, weight vector and selected node;
- TDMA has no collision by construction and uses measured frame length;
- physical recipient and airtime accounting closes;
- all unsafe runs remain in the result.

### 3.7 Promotion gate

EXP19B is allowed only if all of the following hold:

1. at least one oracle arm Pareto-improves frame-piggyback on RMSE and offered
   utilization in the N5 Stressed bg0 ALOHA boundary;
2. at least one oracle arm reduces failures in N10 Moderate bg0 ALOHA without
   worsening mean offered utilization;
3. the improvement is not reproduced equally by the periodic-TDMA frontier;
4. priority differs from FIFO in at least 10% of eligible decisions, proving
   that the semantic scheduler actually acts;
5. all integrity gates pass.

For this development decision, “Pareto-improves” means strictly lower
30-seed mean RMSE and strictly lower mean offered utilization, with no
increase in observed failure count. Failure reduction means a strictly lower
failure count with non-increased mean offered utilization. A periodic point
“reproduces” an oracle if it is no worse in all three boundary summaries:
mean RMSE, mean offered utilization, and failure count. These are deterministic
development gates; no confidence interval or p-value is computed.

Failure of any gate produces `NO_SERVICE_SCHEDULING_HEADROOM` and stops the
method cycle. Gates are development decisions, not hypothesis tests.

## 4. EXP19B — causal distributed approximation, conditional only

EXP19B is not specified or opened until EXP19A passes. The allowed design space
is limited to observable local quantities already logged by the protocol:

- declared swarm size and frame geometry;
- local busy EWMA and queue occupancy;
- local innovation and confirmed-age deficit;
- own service/attempt history;
- cumulative piggyback feedback.

It may not use true receiver AoI, realized future collisions/losses, global
queue state or an outcome-fitted threshold. Development must compare against
frame-piggyback, the oracle reference and periodic/TDMA frontiers.

## 5. Submission and hardware gate

No manuscript promotion occurs after EXP19A. A submission candidate requires:

1. EXP19A demonstrates genuine action-space headroom;
2. EXP19B produces an implementable causal policy that captures a material
   fraction of that headroom;
3. a separately preregistered fresh-seed envelope holdout succeeds;
4. only then, measured trace/radio validation is attached to the frozen
   candidate.

Measurement-interface software may proceed in parallel, but buying UAVs or
claiming policy hardware readiness remains prohibited.
