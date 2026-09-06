# Post-EXP19 direction decision

**Verdict:** `DO_NOT_OPEN_EXP20_AS_CURRENTLY_FRAMED`

The proposed broad direction—causal contention-to-scheduled access using
semantic/ACK information—is not sufficiently novel after a primary-source
audit through 2026-08-31.

Three independent prior-art lines close the broad claim:

- [Z-MAC](https://ieeexplore.ieee.org/document/4453818/) and later adaptive
  hybrid protocols already switch or blend CSMA and TDMA according to
  contention, queue state, and collisions.
- [DTSA](https://ar5iv.labs.arxiv.org/html/2202.00919) and
  [Aydin et al.](https://napier-repository.worktribe.com/output/3595870/distributed-tdma-scheduling-for-autonomous-aerial-swarms-a-self-organizing-approach)
  already provide decentralized/demand-aware dynamic TDMA for UAV swarms,
  including flight-state priority, slot migration, dynamic frames, recovery,
  and flight/COTS evidence.
- [DELTA](https://www.research.unipd.it/retrieve/bd3d2509-7171-4b37-82db-5fc8c770de9f/Goal-Oriented_Medium_Access_With_Distributed_Belief_Processing.pdf),
  published in IEEE Transactions on Networking in 2026, already uses
  ACK-derived distributed beliefs about semantic freshness to drive
  goal-oriented random access under collisions and imperfect feedback.

The audit also found a broader 2025
[Goal-oriented Medium Access preprint](https://arxiv.org/pdf/2508.19141) with
distributed VoI thresholds and bandit learning. Together with EXP19A's own
negative semantic-promotion verdict, this makes a new generic hybrid or
semantic scheduler scientifically weak.

## Residual question worth testing

The exact information structure of this project remains conditionally
different:

> continuous-state peer-to-peer swarm control; one broadcast has multiple
> receivers; acknowledgements are private, delayed, lossy, non-FIFO, and
> receiver-specific; there is no common gateway/public feedback from which all
> nodes can derive common knowledge.

This matters because DELTA's coordination argument explicitly relies on public
ACK/NACK announcements. The audit found no exact work that jointly handles the
above structure, charges all coordination traffic, and evaluates closed-loop
formation safety. This is a scoped gap, not yet a contribution or priority
claim.

## Authorized next research step

Open `EXP20A_PRIOR_ART_BASELINE_CLOSURE`, not a new policy search.

Minimum arms:

1. current Causal-v3/frame-piggyback;
2. periodic-TDMA frontier and collision-free round-robin;
3. faithful DTSA kinematic-priority scheduling;
4. DELTA with native public feedback;
5. DELTA projected onto delayed private per-neighbor feedback;
6. Chen-style age-gain thinning;
7. a Z-MAC-like hybrid access baseline; and
8. the EXP19A oracle references.

The primary mechanism test is the difference between public/common feedback
and delayed private multi-receiver feedback. Aydin's full distributed STDMA
becomes mandatory if the first screen is positive.

Stop the branch if periodic TDMA/DTSA explains the closed-loop frontier or if
DELTA/age-gain baselines match the current mechanism under equal information
and fully charged airtime. Only design a new candidate if private feedback
causes a reproducible loss that the current ACK-confirmed memory avoids and
that periodic/DTSA access cannot reproduce.

## Submission implication

If EXP20A is positive, the likely publishable contribution is theory-first:
an information-structure result or self-stabilizing protocol for private
delayed multi-receiver feedback, then closed-loop and measured validation.
Hardware should wait for those gates, but it will be effectively mandatory for
an IoT-J/communication submission because the nearest UAV-TDMA works already
include flight, COTS, or semi-physical validation.

## Integrity finding

`paper/references.bib` currently assigns the wrong DOI to
`munari2025feedback`. The correct DOI is
[`10.1109/TCOMM.2025.3583639`](https://doi.org/10.1109/TCOMM.2025.3583639);
the stored DOI `10.1109/TCOMM.2025.3548035` belongs to a different Slotted
ALOHA energy-harvesting paper. The bibliography was not edited in this
research-only step.

The full evidence synthesis and claim ledger are stored internally under
`docs/post_exp19_literature_audit_2026-08-31/`.
