# EXP23R — Coherence packet graph-repair results

Run: `results/exp23r_coherence_packet_graph_repair/2026-09-04_174126`

Status: **COHERENCE_ELCS_W_GRAPH_REPAIR_PACKET_KERNEL_VALID (20/20 gates)**.

The study completed 1,800/1,800 unique rows on 50 fresh seeds, N5/N10,
three geometry cells and six channel cells. All 1,185 admitted non-blackout
rows terminally certified. Across the complete matrix there were zero
false-valid edge frames, zero scheduled-collision frames and zero
certificates without fresh claims. All 183 stimulated directed-blackout rows
failed silent and none reached complete certification.

The repaired graph increased the largest observed witness load to five and
the largest RESPONSE packet to 66 bytes; both remained within the frozen
single-packet/96-byte MTU contract. The maximum absolute attempt and byte
bound ratios were 0.631250 and 0.634177. The matrix stimulated 816 target,
786 contracted, 198 no-selector, 180 binding-rejected and 1,422 admitted
rows.

This result validates the static packet kernel after receiver-detectability
repair. It permits dynamic self-revocation/reacquisition implementation and
later common-PHY integration. It does not validate dynamic topology, promote
the method or authorize a submission claim.
