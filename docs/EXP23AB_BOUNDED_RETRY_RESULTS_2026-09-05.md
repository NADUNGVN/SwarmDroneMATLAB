# EXP23AB bounded retry/backoff development result

Date: 2026-09-05  
Canonical result: `results/exp23ab_bounded_retry_development/2026-09-05_075106`  
Status: `BOUNDED_RETRY_DEVELOPMENT_FEASIBLE`  
Scope: development evidence; graph input is not yet coupled to online plant state.

## Decision

All 24 frozen gates pass over 120 trajectories (20 new development seeds x 6 paired arms). A six-frame dense prefix followed by 2--4--8-frame exponential backoff and a ten-CLAIM hard budget removes persistent control-plane retry cost without changing ordinary operation or protected closed-loop behavior during permanent RESPONSE loss.

This closes the overhead defect exposed by EXP23AA. The next unresolved validity gap is online causal state-tube coupling. No submission or fresh-seed claim is permitted from EXP23AB.

## Main results

- Ordinary IID-20 operation is exactly unchanged: dense and backoff arms have identical RMSE, cost, reacquisition, control attempts, and airtime across all 20 paired seeds. Both reacquire safely in 20/20 rows.
- Under permanent RESPONSE loss, backoff stops after exactly 10 CLAIM attempts in 20/20 rows; dense retry uses 40 CLAIM attempts.
- Backoff saves a mean 150.8 control transmissions: 30 CLAIM and 120.8 RESPONSE transmissions.
- Management airtime falls by 0.15060 s, from 0.36283 s to 0.21223 s.
- Total cost falls by 4.961%, from 0.25296 to 0.24041.
- The dense and backoff blackout arms have exactly identical DATA attempts, recipient outcomes, RMSE, minimum separation, and safety for every paired seed.
- Both blackout arms remain suppressed on uncertified shared slots, collision-free, and safe in 20/20 rows because protected emergency DATA continues after retry exhaustion.
- Backoff under REVOKE loss is exactly identical to ordinary backoff.
- The fixed LOCK-PROOF window is invariant to CLAIM backoff.

Against periodic IID-20, protected backoff under permanent RESPONSE loss has 1.97% higher mean RMSE but 6.09% lower total cost. That comparison is descriptive, not a registered superiority claim.

## Analytical certificate

Under the registered independent 20% control-erasure model, the conservative union failure upper bound over the fixture's incident migration entries is 0.000585, below the frozen (10^{-3}) gate. The bound integrates over the first successful LOCK-PROOF frame and all remaining scheduled CLAIM/RESPONSE opportunities. It does not assume that a self-witness link enjoys its actual zero-hop advantage, so it is conservative for this kernel.

The certificate is model-conditional; correlated erasures remain for a later robustness matrix.

## Integrity

- Matrix: 120/120 unique rows.
- Seeds: 16088001--16088020.
- Registry: 115 frozen leaves; short registry hash `121752855`.
- Exact replay, control bytes/airtime, affine clocks, and causal-read instrumentation all pass.
- Collision frames: zero in all six arms.
- `geometryCoupledToPlant=false`.
- `freshSeedEvidence=false`.
- `submissionClaimPermitted=false`.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| `trajectory_tidy.csv` | `ACDFA1C31434851DC1A4F47558F95FE3CAAB517E899986B551CDC4B88281A593` |
| `summary.csv` | `82949B652812CBE8945B3E943C2CCD1782666CCE3029AC23436BDE5B148485E3` |
| `paired_contrasts.csv` | `7E307C8322A274B7EA6461BBF47E723E6A7F8AC126E5F9199D18136DD5D285B1` |
| `validation_gates.csv` | `6E90E8CE89E6F12AD10B6984325973D9AC72B37710FD3AB5F400594EF52275D1` |
| `bounded_retry_verdict.json` | `478741633D8DA95C1F21D80C2787B71A6D48E0D55FB98AEF7302DAF5ACF2562F` |

