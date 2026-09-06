# EXP15 hardware-agnostic trace replay contract

## Purpose

EXP15 connects the frozen shared-medium simulator to future radio measurements
without choosing an onboard computer, radio standard, or UAV frame now. The
contract is intentionally about exogenous channel/service state, not a
particular device API.

A packet log collected under one communication policy is **not** a valid
paired counterfactual trace. It contains outcomes only at times when that
policy transmitted; another policy changes those times and packet lengths.
Replaying such a log would condition the channel on the policy being compared.

The admissible input is instead an absolute-time, policy-independent calibrated
trace: for every slot and directed link it supplies DATA and standalone-ACK
loss probabilities plus a declared bad-state label, and for every slot it
supplies exogenous medium occupancy. The simulator draws policy-independent
uniforms once and queries these arrays only when a policy actually attempts a
frame.

## Public MATLAB interface

```matlab
trace = buildMeasuredSharedMediumTrace(cfg, measurement, replaySeed)
report = validateMeasuredSharedMediumTrace(trace, cfg)
```

Both functions use schema `MEASURED-SHARED-MEDIUM-v1`. Invalid external data
raises a `measuredTrace:*` error before simulation. Existing generated traces
are unchanged; measured replay is an additive trace variant.

## Required measurement input

`measurement` is a scalar struct with these fields:

| Field | Type and shape | Meaning |
|---|---|---|
| `schemaVersion` | char/string scalar | exactly `MEASURED-SHARED-MEDIUM-v1` |
| `sourceId` | nonempty char/string scalar | immutable dataset/trace identifier |
| `slotTime` | positive scalar seconds | absolute calibration grid; must equal `cfg.mac.slotTime` |
| `N` | positive integer | number of indexed nodes; must equal `cfg.swarm.N` |
| `timeSec` | `K×1` finite double | starts at zero and increments exactly by `slotTime` within tolerance |
| `dataLossProbability` | `K×N×N` double | exogenous DATA loss probability in `[0,1]` |
| `ackLossProbability` | `K×N×N` double | exogenous standalone-ACK loss probability in `[0,1]` |
| `dataBadState` | `K×N×N` logical/binary | declared DATA channel-state label used only for diagnostics |
| `ackBadState` | `K×N×N` logical/binary | declared standalone-ACK state label used only for diagnostics |
| `backgroundActive` | `K×1` logical/binary | external occupancy affecting all nodes in the first contract version |

`K` must cover `ceil(cfg.swarm.T/cfg.mac.slotTime)+2` slots. Sender/receiver
indices follow the simulator convention `(receiver,sender)`. Diagonal values
must be zero because self-links are not physical channel observations.

Loss probability and bad-state label are deliberately distinct. The label can
represent an RSSI/SNR/HMM regime for stratified diagnostics; the probability
is the quantity used for frame loss. A bad-state label may not silently replace
a missing probability estimate.

## Output trace semantics

The builder returns the existing shared-medium trace fields plus:

- `sourceMode = 'measured-probability-v1'`;
- `schemaVersion` and `sourceId`;
- `measurementHash`, computed from all semantic measurement arrays;
- `measuredDataLossProbability` and `measuredAckLossProbability`;
- `measuredBackgroundActive`.

Access, DATA-loss, and ACK-loss uniform arrays are generated once from
`replaySeed`; policy actions never advance an RNG. `hashExact` covers both the
uniform arrays and measured semantic arrays. `channelStateHash` covers the two
declared state tensors. The existing MAC/channel signature remains attached so
a trace cannot be reused with a different node count or configured channel
contract without an explicit new adapter version.

Piggybacked ACK entries experience the enclosing DATA probability, exactly as
in the generated-trace simulator. Only standalone ACK frames use the measured
reverse-ACK probability tensor.

## Measurement protocol before trace construction

The radio campaign must separate calibration from policy evaluation:

1. synchronize clocks or estimate offset/drift and resample to the declared
   absolute grid;
2. collect repeated probe opportunities independent of the evaluated policy;
3. estimate DATA/ACK loss probability for every declared directed link and
   slot/window, retaining denominators and missingness;
4. classify optional bad/good regimes without using policy performance;
5. measure external occupancy independently of swarm transmissions;
6. freeze preprocessing code, raw-file hashes, link mapping, replay seed and
   trace hash before comparing policies.

Missing observations may be handled only by a preregistered calibration model
with an uncertainty/sensitivity arm. They may not be replaced by zero loss or
interpolated after observing controller outcomes.

## Two-node airtime and energy companion table

Trace replay does not calibrate frame service cost. A separate two-node bench
must record at least:

| Column | Unit |
|---|---|
| radio/firmware/configuration identifier | string |
| frame class (`DATA`, `ACK`) | enum |
| payload and total bytes | bytes |
| PHY rate/MCS/channel | declared radio units |
| measured on-air/service duration | seconds |
| transmit and receive energy | joules |
| repetitions and confidence interval | count, seconds/joules |

These measurements may replace abstract `dataBytes`, `ackBaseBytes`,
`ackEntryBytes`, `phyRateBps`, and `txPowerW` only in a new frozen EXP15
configuration. They do not modify EXP14 results.

## Integrity gates for an EXP15 replay

- schema, dimensions, absolute grid and diagonal contracts pass;
- raw/preprocessing/measurement/replay hashes are archived;
- every paired method uses the same `measurementHash` and `hashExact`;
- no performance-driven imputation or trace-window selection;
- measured-probability override is exercised for both DATA and standalone ACK;
- piggyback continues to use the DATA path;
- causal invariants, queue/history bounds and physical accounting pass;
- abstract-parameter and measured-trace results are reported as separate
  evidence layers, never pooled silently.

This contract permits trace replay and radio calibration before purchasing or
packaging a flight computer. Flight hardware becomes necessary only after the
two-node measurement and trace gates are credible.
