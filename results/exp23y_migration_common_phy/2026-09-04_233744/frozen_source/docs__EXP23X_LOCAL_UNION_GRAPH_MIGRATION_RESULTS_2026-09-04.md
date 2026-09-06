# EXP23X — Local union-graph migration kernel results

Canonical run:
`results/exp23x_local_union_migration_kernel/2026-09-04_232823`.

Status: **LOCAL_UNION_MIGRATION_KERNEL_VALID (21/21 gates)**.

The repaired randomized study contains 3,000/3,000 rows over 100 seeds,
`N={5,10,20}` and ten paired cases. Every topology removes one incident edge,
adds another incident edge whose endpoint shares the migrating sender's old
slot, and forces the selector to choose a different union-safe slot.

The earlier run `2026-09-04_232607` is superseded. Its neighbor LOCK-PROOF
transmission schedule depended on the revoker's private transaction state.
The canonical run replaces that shortcut with a fixed 20-frame proof window;
witness RESPONSE emission requires a current-frame CLAIM. Attempt and byte
bounds charge the complete fixed window.

Results:

- 300/300 zero-loss rows reactivate at the registered eligibility frame;
- 300/300 IID-20 and 300/300 IID-40 rows recover cumulatively; the maximum
  observed reactivation frame is 26;
- every supported row has zero scheduled-collision and unsafe-reuse frames;
- permanent RESPONSE blackout and stale-version RESPONSE remain suppressed;
- delivered and lost REVOKE have identical local transition state;
- concurrent two-sender migration is explicitly rejected and remains silent;
- missing union witness coverage and over-MTU migration responses are
  inadmissible and remain silent;
- the incomplete-union negative control is rejected by the independent
  actual-graph oracle and retains 15,600 observed collision frames rather than
  hiding them;
- control components, recipient outcomes and exact airtime close; maximum
  attempt- and byte-bound ratios are 0.9787 and 0.9795;
- all trace hashes validate, with zero future-random or receiver-truth reads.

Artifact SHA-256:

- `migration_tidy.csv`: `A937060279E7F6848FBFF2536185ED37E45D2A0DD8A3B09FB9B2313EDCC06B58`
- `migration_verdict.json`: `0E75CC58AE5F1DADEA6F707249A79F5F328FD06354B3E98154111A11056FBA36`

This is kernel evidence only. It does not yet show that CLAIM, LOCK-PROOF,
RESPONSE, REVOKE and changed-slot DATA coexist safely on one continuous PHY,
nor that the transition preserves closed-loop performance. The next gate is
common-PHY continuous integration with affine clocks and exact event-level
airtime accounting.
