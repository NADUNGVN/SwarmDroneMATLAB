# Post-Gate-6 predictive-VoI signal diagnostic result

**Technical verdict:** `PASS`

**Scientific verdict:** `SIGNAL_PRESENT`

**Accepted run:**
`results/tcns_post_gate6_oracle_value_diagnostic/2026-09-07_093357`

**Source commit:** `f5fc880`; MATLAB R2025a.

## What passed

All 15 frozen Periodic-10 development trajectories completed for S1, S2 and
S6 over seeds 27020001--27020005. Every score is finite and nonnegative, the
Moderate-channel delay and success probability are exactly the declared four
samples and 0.8, and no evaluated follower command is saturated. The unit
test reconstructs the three-axis state recursion directly and verifies the
finite-horizon link kernel to a maximum residual of
\(1.735\times10^{-17}\). Enabling receiver-memory logging leaves all checked
plant, network, trace and communication outputs bitwise identical.

The accepted run is numerically identical to the earlier `093201` run in
every scientific field. The first run is retained but superseded because the
script omitted `finishExperiment`, so it did not write `meta.json` or
`LATEST.txt`; only runtime differs after the provenance-only repair.

## Frozen decision

| Scenario | Mean event allocation ratio | Mean paired temporal-CV ratio to S1 | Frozen scenario decision |
|---|---:|---:|---|
| S2 Formation switching | 1.3033 | 1.3196 | PASS |
| S6 Dynamic excitation | 1.3294 | 1.5200 | PASS |

Both scenarios exceed the preregistered thresholds of 1.25 on both metrics,
so the overall decision is `SIGNAL_PRESENT`. Their mean top-decile event
allocation ratios are 2.270 and 2.275, respectively. The stationary S1 mean
temporal coefficient of variation is 0.4566; it is 0.6152 in S2 and 0.6873 in
S6.

The evidence is not uniform per seed. The minimum event allocation ratio is
1.1763 in S2 and 1.1688 in S6. The frozen criterion was explicitly based on
five-seed means, so these runs pass, but the variability prevents a claim
that every realization has strongly concentrated value.

## Scientific meaning

Gate 6 showed that the stopped possible-set budget trigger allocated traffic
almost uniformly: 1.032 in S2 and 1.071 in S6. This new result establishes a
necessary distinction: under the exact linear closed-loop kernel, the
isolated value of replacing stale receiver content is materially more
concentrated than the old policy's traffic. There is therefore a state-driven
signal worth attempting to infer causally.

This is not evidence that a new policy beats periodic communication. The
diagnostic uses actual receiver memory and is marked
`onlinePolicyAdmissible=false`. It measures expected isolated output-energy
separation for one delivery, not the total cost difference in the interacting
closed loop.

## Authorized next step

Derive a transmitter-side probability distribution over the receiver-held
candidate payload using only:

- the cumulative ACK-confirmed payload;
- outstanding sent records with their generation/transmission times;
- the declared forward loss/delay law;
- ACK arrivals observed by the sender.

The next action score must subtract the expected value already supplied by
outstanding packets. It may not read the stored simulator drop flag,
receiver registers, future trace values, or the current hidden Gilbert--Elliott
state. Before simulator integration, the probability algebra and limiting
cases must be unit tested. Only a one-seed, two-scenario sanity experiment is
authorized after that checkpoint; no Gate-7 grid or held-out seed is opened.

## Gaps that remain active

- **PROOF GAP PV.1:** no exact causal posterior with delayed/lost ACKs has yet
  been derived.
- **PROOF GAP PV.2:** existing in-flight packet value is absent from the
  oracle diagnostic.
- **PROOF GAP PV.3:** isolated quadratic energy omits multi-link cross terms,
  so positive score is not guaranteed positive total-cost improvement.
- **PROOF GAP PV.4:** the kernel excludes saturation, 6-DOF, switching
  topology, estimator error and model mismatch.

