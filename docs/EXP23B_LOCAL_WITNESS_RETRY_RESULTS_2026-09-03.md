# EXP23B local-witness causal retry results

Run: `results/exp23b_local_witness_retry_validation/2026-09-03_142535`

## Verdict

- 1,000/1,000 unique rows on 100 fresh seeds, two topologies and five
  conditions.
- 16/16 gates passed.
- `ELCS_W_KERNEL_VALID`; common-PHY integration is permitted.
- Promotion and submission claims remain prohibited.

Zero loss certified 200/200 runs in frame 1 and used the nominal scheduled-
epoch attempt and byte bounds exactly, with no retry. Under 5% random control
loss, terminal full certification improved from the invalid EXP23A values
37.5%/53.0% to 100% for both CLAIM and CERT loss.

| Cell | Condition | Mean retry CLAIMs | Mean control attempts | Mean control bytes | Certified node-frame fraction |
|---|---|---:|---:|---:|---:|
| N5 | zero | 0.00 | 310.00 | 8,680.00 | 1.000000 |
| N5 | CLAIM loss 5% | 31.32 | 410.11 | 11,354.40 | 0.999645 |
| N5 | CERT loss 5% | 20.49 | 390.69 | 10,755.52 | 0.999795 |
| N10 | zero | 0.00 | 620.00 | 19,840.00 | 1.000000 |
| N10 | CLAIM loss 5% | 76.62 | 878.20 | 27,664.40 | 0.999573 |
| N10 | CERT loss 5% | 46.37 | 819.52 | 25,676.08 | 0.999798 |

Retry activation ranged from 11 to 113 attempts across random-loss rows.
Relative to zero loss, mean control bytes rose 30.8%/23.9% in N5 and
39.4%/29.4% in N10 for CLAIM/CERT loss.

Across all five conditions there were zero false-valid edge-frames, zero
scheduled collisions and zero certificates without fresh endpoint claims.
DATA erasure changed delivery outcomes without changing the paired
certificate-state hash. All 200 permanent directed-CERT blackouts were
retained with the target client inactive. Maximum absolute attempt/byte-bound
ratios were 0.354250 and 0.367429.

## Interpretation and next gate

EXP23B closes the one-hop visibility and 5% IID control-loss kernel gate. It
does not yet establish physical timing or closed-loop value. The next study
must translate variable-size CLAIM/RESPONSE packets into one common PHY,
reserve each deterministic witness slot using its frozen maximum assigned
entry load, charge actual packet airtime, and preserve exact recipient and
logical-opportunity replay under bounded affine clocks.
