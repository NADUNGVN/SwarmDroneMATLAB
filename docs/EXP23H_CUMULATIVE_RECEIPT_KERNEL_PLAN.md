# EXP23H — Same-sequence cumulative-receipt kernel validation

Status: frozen before fresh-seed execution on 2026-09-04.

## Motivation and single allowed change

Valid EXP23G found that current ELCS-W is epsilon-dominated by periodic TDMA
for N5 under 15% IID occupancy. The diagnosed cause is same-frame retry
amplification. EXP23H changes only receipt state:

- one CLAIM sequence is allocated when a renewal transaction starts;
- retransmissions retain that sequence;
- exact per-edge witness receipts accumulate across frames;
- the transaction closes after all incident witnesses acknowledge it.

Slot coloring, witness assignment, packet format, lease duration, refresh
lead, fence, fallback, PHY and causality rules remain unchanged.

## Frozen matrix

- 100 fresh seeds `16071001:16071100`.
- N5 6-DOF and N10 ring-2 graphs.
- Conditions: zero loss, CLAIM 5%, RESPONSE 5%, joint control 5%, shared IID
  occupancy 15%, and a directed permanent RESPONSE blackout.
- Modes: legacy same-frame/new-sequence retry and the cumulative candidate.
- 2,400 paired kernel rows.

## Gates

The study requires exact matrix and realization pairing; one-hop coverage;
zero-loss effort equivalence; zero false-valid and scheduled-collision
witnesses; terminal certification in every non-blackout cumulative row;
fail-silent behavior under permanent blackout; exact recipient accounting;
absolute attempt/byte bounds; evidence that sequence transactions accumulate
receipts; and strictly lower aggregate attempt and byte effort under IID-15%
in both graphs.

This is kernel validation only. A pass permits a fresh closed-loop rerun of
the failed EXP23G cell and full background matrix. It does not promote the
method or authorize a robustness/submission claim.
