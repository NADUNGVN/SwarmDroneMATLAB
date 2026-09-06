# EXP23AK routed integer-accounting confirmation plan

Frozen: 2026-09-06, before any registered random replay seed is executed.

## Retained invalid parent

EXP23AJ `2026-09-06_070738` remains **invalid at 15/17 gates**. All routing,
causality, collision, exact reliability, Monte Carlo probability, semantic
recipient and negative-comparator gates passed. Its two failed gates shared one
numerical cause: routed offered airtime was accumulated once per physical
transmission in binary floating point. Attempts, integer bytes, reserved
duration and every packet outcome were exact, but 175/210 structural rows and
9/25 semantic rows differed from `8*bytes/rate` by at most
`2.4980018054066022e-16 s`.

The parent is not relabeled and no tolerance is added. Replay v2 derives
offered airtime once from its integer byte counter:

`A_offered = 8 * B_integer / R_phy`.

No routing, tree, coloring, delivery, random-read or reliability logic changes.

## Registered confirmation

1. Rebuild all 210 EXP23AJ structural route rows and require exact identity of
   route-plan hash, selected repetition, reliability certificate, attempt/byte
   bounds, reserved slots and duration with the invalid parent.
2. Replay every route without loss and require exact attempts, integer bytes,
   and bit-exact `offeredAirtime == 8*bytes/250000`.
3. Run 2,000 new conditional-relay traces in each of 18
   size/interference/loss cells (36,000 total) with one repetition per hop so
   upstream erasures produce varying physical attempt counts. Seeds are
   16094601--16094618; packet sizes cycle through
   {24,28,32,40,48,56,72,96} bytes. Every trace must respect its analytical
   attempt bound and exact byte/airtime identities.
4. Rebuild all 25 semantic routes from the retained online migration fixture;
   require exact recipient, plan, reliability and physical-accounting identity.

Ten gates also require the exact invalid-parent signature, replay-v2 identity,
retention of all 15 previously passed gates, conditional-path diversity, and
all downstream claim flags remaining false.

Passing EXP23AK validates only the routed-management primitive by combining
the retained EXP23AJ scientific gates with the new accounting confirmation.
It does not validate routed closed-loop management or repeated online renewal.
