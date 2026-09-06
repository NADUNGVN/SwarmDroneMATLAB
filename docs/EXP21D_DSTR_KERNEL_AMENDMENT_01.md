# EXP21D-K amendment 01 — correct the source-native projection

**Date:** 2026-09-01

**Timing:** after deterministic contracts and one four-condition smoke test
at `(seed=16033001,N=10)`, but before creating a registered experiment run or
generating any aggregate randomized result.

## Trigger

The smoke test made the nominal arm remain conflicted for all 200 logical
superframes.  Inspection showed that the frozen projection had treated the
DATA graph as a clique with five initial transmission slots.  That is not the
native D-STR scenario in the primary source.  D-STR is a multi-hop spatial-
reuse protocol evaluated on a 10 m-spaced hexagonal formation with a 10 m
safety radius and formation-wide higher-power management transmissions.  The
source evaluates default transmission-superframe sizes 1 and 10; the five
transmission slots in its Table 1 illustrate a total ten-slot superframe after
including five management slots, rather than a registered default parameter.

Direct review of Section 4.4 also exposed two omitted shrink rules:

- only Resolved nodes track silent slots; and
- an objected shrink enters a per-node `failed_shrink` cache, evaluated by the
  source with `FST=10` or `30` superframes.

Primary source: [Samandari et al., D-STR,
arXiv:2511.12888v1](https://arxiv.org/abs/2511.12888).

## Amendments

Before the 800-row run, EXP21D-K is changed as follows:

1. use the source-evaluated upper default of ten initial transmission slots;
2. use a compact rectangular hexagonal formation at 10 m spacing and a 10 m
   safety-neighborhood radius for DATA delivery;
3. retain formation-wide management reach in the native arm;
4. make `restricted-management` change management reach only, leaving the
   DATA/interference graph paired;
5. add `FST=10`, track silence only while Resolved, make every Assignment node
   object in `TSo`, cache objected slots, and retain NACK-only exponential
   backoff; and
6. state explicitly that the kernel uses a binary conflict-graph PHY
   abstraction and cannot reproduce the source's numerical SINR results.

The under-provisioned five-slot deterministic witness remains only to activate
`TG/TGn` and all shrink-management transitions.  It is not a randomized
native setting.

## Integrity consequence

The failed smoke-test output was diagnostic console output and was not stored
as a registered result.  No seed was added, removed, or inspected beyond the
declared first seed; no threshold was relaxed; and the native conformance gate
still requires every registered native row to reach a physically valid
Resolved assignment.  This amendment corrects a source-mapping error rather
than rescuing a performance comparison.
