# EXP23N — Coherence metadata packet-cost audit

Status: frozen posthoc diagnostic before distributed-kernel integration.

## Purpose

EXP23K used the original 24-byte CLAIM and 8-byte certificate entry. A
coherence-certified lease must place its horizon on the wire. Treating that
metadata as free would invalidate the 1.91% cost advantage.

The frozen candidate format is:

- CLAIM: `28` bytes (`24 + uint16 horizonFrames + uint16 tubeDigest`);
- RESPONSE header: unchanged at `16` bytes;
- certificate entry: `10` bytes (`8 + uint16 certifiedHorizonFrames`);
- control MTU: unchanged at `96` bytes;
- REVOKE: `24` bytes when emitted; zero static-cell REVOKEs are assumed only
  for this EXP23K replay audit and are not generalized to dynamic conditions.

The 10-byte entry preserves capacity for eight entries per RESPONSE, matching
the maximum local-witness load already observed in N10. The audit reconstructs
all 60 EXP23K schedules, replaces each physical packet by the declared format,
checks MTU/entry closure, and recomputes total offered utilization.

The format retains development feasibility only if mean charged utilization
remains at least 1% below paired periodic TDMA. This is same-seed accounting,
not fresh evidence or method promotion.

