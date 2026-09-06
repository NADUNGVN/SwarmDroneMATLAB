# EXP23H — Same-sequence cumulative-receipt kernel results

Run: `results/exp23h_cumulative_receipt_kernel_validation/2026-09-04_161234`

Status: **valid kernel result; cumulative-receipt ELCS-W may advance to a
fresh closed-loop falsification study**.

## Integrity and scope

- 100 fresh seeds, two conflict graphs, six channel conditions and two retry
  modes: 2,400/2,400 unique kernel rows.
- Registry hash `114741684` over 75 leaves.
- All 17/17 predeclared validation gates passed.
- Absolute loss, occupancy and witness-assignment realizations pair exactly
  between legacy and cumulative modes.
- This result validates the protocol kernel only. It neither promotes a new
  method nor establishes a closed-loop performance or submission claim.

## Safety and liveness

- Zero false-valid edge-frames, scheduled-collision frames and unsupported
  certificates were observed in every cumulative row.
- Every non-blackout cumulative row reached terminal certification:
  1,000/1,000 rows.
- Under a directed permanent RESPONSE blackout, cumulative retry remained
  fail-silent: no missing witness receipt was converted into validity.
- Attempt and byte bounds held with maximum observed bound ratios
  `0.354250` and `0.367429`, respectively.
- Management/DATA recipient accounting, exact airtime accounting and the
  causal information contract all closed.

## Isolated effect of cumulative receipts

Under zero loss, both retry modes are exactly equivalent in control attempts,
bytes, DATA regions and terminal certification. The redesign therefore does
not buy its result by changing nominal scheduling behavior.

Under shared IID occupancy at 15%, retaining exact per-edge receipts across
same-sequence retransmissions removes a substantial part of fragmented-load
amplification:

- N5: attempts decrease from `801.96` to `602.20` per run (`-24.91%`), and
  bytes decrease from `21,836.4` to `16,738.0` (`-23.35%`).
- N10: attempts decrease from `1,399.71` to `1,017.81` per run (`-27.28%`),
  and bytes decrease from `43,444.8` to `32,266.16` (`-25.73%`).

Both graphs retained 100% terminal certification in that condition. Smaller
effort reductions also occur under independent CLAIM, RESPONSE and joint
control loss, while zero-loss and permanent-blackout effort remain unchanged
as required by the frozen gates.

## Decision

EXP23H establishes that the same-sequence cumulative-receipt transaction is a
valid protocol repair for the mechanism diagnosed in EXP23G. It does **not**
yet establish that the closed-loop candidate escapes periodic epsilon-
dominance. The next admissible experiment is a fresh-seed closed-loop test at
the decisive N5/IID-15% cell, comparing periodic TDMA, legacy ELCS-W and
cumulative ELCS-W on identical channel, clock and occupancy realizations.

