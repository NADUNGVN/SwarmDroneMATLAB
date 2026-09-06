# EXP14F paired-shadow ACK-value development plan

## Scientific question

EXP14E showed that standalone adaptive ACKs do not beat piggyback-only feedback
in the N5 and N10 CSMA cells, are nearly inactive at N20, but can repay their
airtime under the ALOHA boundary. Aggregate airtime accounting cannot reveal
whether an accepted standalone ACK actually confirms a generation earlier than
a complete piggyback-only counterfactual. EXP14F measures that missing temporal
quantity.

This is a development mechanism study, not a confirmatory extension of EXP14E.
No policy threshold is changed, no performance success gate is defined, and no
confirmatory claim is permitted.

## Frozen design

- Registry: `EXP14F-PAIRED-SHADOW-DEVELOPMENT-v1`.
- Registry hash: `20176987` over 25 leaves.
- Seeds: `16018001:16018020`, disjoint from EXP14/14C/14D/14E.
- Cells: N5 CSMA, N10 ring2, N20 ring2, and N5 ALOHA.
- Arms: selected adaptive/scaled actual policy and piggyback/scaled shadow.
- Matrix: 20 seeds × 4 cells × 2 arms = 160 full simulations forming 80
  paired groups.
- Both arms consume the same absolute exogenous trace in each group.
- Horizon, controller, plant, topology, MAC and policy parameters are inherited
  unchanged from EXP14E.

## Passive event contract

Logging occurs only after a valid ACK entry passes every causal/history check
and advances sender belief. Each event stores the directed link, sequence,
generation time, acceptance time, carrier frame, transport type and frame
service metadata. Logging defaults off outside EXP14F. A dedicated on/off test
requires bit-identical plant, controller, network counters, policy state and
trace hashes, so the diagnostic cannot influence transmission decisions.

## Generation-matched estimand

For every accepted standalone confirmation in the actual arm at time
\(t_A\), on directed link \((i,j)\), confirming generation \(g_A\), let
\(t_P\) be the first accepted confirmation in the full piggyback-only shadow
on the same link whose generation time is at least \(g_A\). The horizon-capped
lead is

\[
L_A=\max\{\min(t_P,H)-t_A,0\}.
\]

If the shadow already crossed that generation by \(t_A\), the lead is zero.
If no crossing occurs by horizon \(H\), the row is retained as right-censored
and \(L_A=H-t_A\). Sequence identifiers need not match because the two full
policies may generate different transmission histories; generation time and
directed link define information equivalence.

The event-level observations are clustered within seed and may reuse a shadow
crossing. Therefore they are not treated as IID, their leads are not summed as
an additive control benefit, and no event-level significance test is allowed.

## Integrity gates and outputs

Integrity gates cover the registry, complete paired matrix, finite eligible
outcomes, protocol causality, bounded memory, physical terminal accounting,
common random traces, arm semantics, one logged event per accepted confirmation
and generation/horizon matching. Performance never determines integrity.

The runner writes run-level data, event-level lead data, lead summaries,
paired policy contrasts, gate results, readiness metadata, source snapshots and
the MATLAB workspace. A predictive ACK-value certificate remains unavailable
until a causal-at-decision predictor is specified in advance and validated on
a new disjoint seed block.
