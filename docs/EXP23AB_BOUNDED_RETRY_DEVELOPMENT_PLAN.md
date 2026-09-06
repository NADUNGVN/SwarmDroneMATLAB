# EXP23AB bounded retry/backoff development plan

Frozen: 2026-09-05, before execution of the registered matrix.

## Motivation

EXP23AA restored closed-loop safety during permanent RESPONSE loss by carrying the suppressed node's DATA in a protected slot. Its remaining defect is control-plane persistence: mean management airtime increased from 0.17279 s in ordinary migration to 0.36039 s in the blackout arm because CLAIM and RESPONSE attempts continued until mission end.

EXP23AB asks whether a finite, deterministic, node-local retry schedule removes that overhead without weakening lease silence, protected DATA service, ordinary reacquisition, or closed-loop safety.

## Frozen policy

The revoker has a public retry schedule relative to its locally known eligibility epoch:

- CLAIM in each of the first 6 eligible frames;
- then inter-CLAIM gaps of 2, 4, and at most 8 frames;
- no more than 10 CLAIM attempts for the topology version;
- stop earlier when all incident union-graph receipts have arrived;
- keep the node suppressed after budget exhaustion;
- continue protected emergency DATA while suppressed.

The schedule reads no packet outcome, future random value, or receiver-private truth. A new topology version would create a new transaction; that case is outside this single-event development matrix.

## Finite-horizon certificate

For one conservative incident entry, let (p_P,p_C,p_R) be proof, CLAIM, and RESPONSE erasure probabilities. Conditional on the first successful proof at frame (t), each later scheduled CLAIM has receipt probability at least

\[
q=(1-p_C)(1-p_R).
\]

The implementation sums over every possible first-proof frame and the number of remaining CLAIM opportunities. It then applies a union bound over all incident union-graph entries. Self-witness cases only improve on this bound. At the registered IID-20 condition, the required union failure upper bound is (10^{-3}).

This certificate is conditional on the independent control-erasure model and is not promoted beyond that model.

## Matrix

Twenty new development seeds, 16088001--16088020, are paired across six arms:

1. periodic IID-20;
2. protected migration with legacy dense retry;
3. protected migration with bounded backoff;
4. protected dense retry under permanent RESPONSE loss;
5. protected bounded backoff under permanent RESPONSE loss;
6. protected bounded backoff under REVOKE loss.

The graph-input fixture, continuous PHY, affine clocks, DATA loss field, event, controller, and emergency slot are inherited unchanged from EXP23AA. `geometryCoupledToPlant=false` remains a hard scope guard.

## Registered expectations

- The backoff blackout arm exhausts exactly 10 CLAIM opportunities and remains suppressed.
- It has strictly fewer CLAIM, RESPONSE, total control attempts, management airtime, and total cost than the paired dense-blackout arm.
- Dense and backoff blackout arms have identical DATA service, RMSE, minimum separation, and safety because their protected DATA schedules are identical.
- Both ordinary dense and ordinary backoff arms reacquire without safety failure.
- The protected blackout arms remain collision-free and safe.
- REVOKE loss is locally irrelevant to the backoff transaction.
- The fixed LOCK-PROOF window is unchanged by CLAIM backoff.

No directional RMSE superiority is required for ordinary backoff versus ordinary dense retry. Any such result is descriptive in this development stage.

## Decision rule

All 24 frozen contracts must pass to call the mechanism `BOUNDED_RETRY_DEVELOPMENT_FEASIBLE`. Failure is retained and diagnosed; parameters are not retuned on these seeds. Even a full pass is development evidence only and cannot support a submission claim or fresh-seed claim.

