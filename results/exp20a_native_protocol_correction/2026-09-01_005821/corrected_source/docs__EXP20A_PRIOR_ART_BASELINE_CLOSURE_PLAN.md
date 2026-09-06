# EXP20A — Prior-art baseline closure before a new policy

**Status:** frozen design, written before any EXP20A outcome is generated

**Study type:** development/falsification; not a confirmatory holdout

**Candidate tuning:** prohibited

**Manuscript or hardware promotion:** prohibited unless every continuation gate
below passes and a later fresh-seed study is preregistered

## 1. Decision inherited from EXP19A and the literature audit

EXP19A showed large headroom for collision-free scheduled access but did not
promote receiver-truth semantic max-weight scheduling. Periodic TDMA reproduced
one registered boundary and the N10 failure repair required increased offered
load. The post-EXP19 primary-source audit then found direct prior art for hybrid
CSMA/TDMA, dynamic UAV TDMA, age-gain random access and ACK-derived semantic
belief processing.

EXP20A therefore does not optimize a new Causal policy. It asks whether the
remaining information-structure distinction is measurable after faithful
prior-art mechanisms are represented:

> Does replacing public, slot-synchronous common feedback by delayed, lossy,
> non-FIFO and receiver-specific private feedback create a material loss that
> is not already explained by periodic/kinematic scheduling or age-gain random
> access?

## 2. Two panels; no false equivalence

DELTA's native task is binary anomaly reporting to one gateway. The swarm task
is continuous-state peer broadcast with multiple receivers. Calling a
continuous formation heuristic “native DELTA” would be scientifically wrong.
EXP20A therefore separates two panels.

### Panel N — native information-structure panel

This panel implements the published binary persistent-anomaly model and the
four DELTA phases: zero-wait, collision resolution, collision exit and belief
threshold. The public arm uses a slot-synchronous public ACK/NACK outcome. The
private arm is an explicitly labelled extension: every node receives the same
gateway outcome through its own delayed/lossy/non-FIFO feedback path and acts
from its local view.

Comparators are zero-wait random access, maximum-age-first and round robin.
Primary metrics are time-average AoII, maximum AoII, attempt rate, success rate
and collision rate. This panel tests the information structure only; it makes
no formation-control claim.

The implementation is clean-room and is checked against deterministic protocol
micro-cases. Aggregate reproduction against the authors' GPLv3 reference code
is descriptive and records the upstream commit; no upstream source is copied
into this repository.

### Panel F — common formation/MAC task

This panel uses the existing plant, topology, absolute channel traces, finite
queues, physical airtime and safety metrics. Literature methods whose source
task differs are labelled `projection`, not `reproduction`.

Mandatory arms:

1. current frame-aware Causal-Broadcast with piggyback feedback;
2. collision-free round robin with the same Causal admission rule;
3. periodic TDMA at 6.25, 8.333, 10 and 12.5 Hz;
4. DTSA kinematic priority with an ideal common schedule view;
5. DTSA kinematic priority with receiver-specific local views;
6. Chen-style age-gain thinning under private cumulative feedback;
7. a Z-MAC-like owner-priority hybrid;
8. a DELTA-style continuous-state public-feedback projection;
9. the same projection under private delayed feedback; and
10. the EXP19 deficit and urgency oracle references.

The DTSA and DELTA projections retain their source mechanisms but do not claim
bit-for-bit reproduction of a different application model.

## 3. Frozen cells and randomization

Panel F reuses all six EXP19A development contexts:

- N5 Moderate and Stressed, zero-background ALOHA;
- N5 Moderate and Stressed, background-0.30 CSMA; and
- N10 Moderate and Stressed, zero-background ALOHA.

Formation seeds are `16027001:16027030`. Every arm in one seed/context group
uses the same absolute channel, estimator and state traces. Panel N uses
`16027101:16027130`, with `N={5,10,20}`, offered load
`rho={0.20,0.50}`, forward erasure `epsilon={0.05,0.20}`, 20,000 measured
slots after a 1,000-slot burn-in. Private feedback uses loss 0.10 and integer
delay uniformly distributed over 1--5 slots. All stochastic draws are indexed
by absolute `(seed,slot,node)` coordinates rather than consumed conditionally.

No seed from EXP20A is a future holdout seed.

## 4. Fixed accounting and comparisons

Formation comparisons use RMSE, observed safety failures, offered utilization,
channel utilization, DATA/ACK airtime and control-plane airtime. Public feedback
is charged as an explicit feedback mini-slot; private feedback uses the actual
ACK frames and delay/loss path. A method cannot pass through uncharged common
feedback.

Dominance uses the inherited 1% engineering margin. Method A dominates B in a
cell only if A is no worse than B by more than 1% on neither RMSE nor charged
offered utilization, is strictly better by at least 1% on one axis, and has no
more observed safety failures.

Panel N reports paired seed differences. Bootstrap intervals use 10,000 paired
resamples with the resample seed fixed in the analysis source before results
are opened.

## 5. Integrity gates

All must pass before performance analysis opens:

1. exact matrix completeness and uniqueness;
2. exact declared seeds and arm/cell coverage;
3. paired absolute trace hashes within each formation group;
4. deterministic native-panel draw hashes across methods;
5. no causal invariant violation in private-feedback arms;
6. public arms never read future draws;
7. private arms never read gateway truth before their feedback event arrives;
8. bounded queues, histories and private feedback queues;
9. DATA, ACK, collision and terminal accounting closes;
10. public-feedback airtime is nonzero and included in charged utilization;
11. DTSA priorities are finite and local-view disagreement is logged;
12. every named mechanism is activated in at least one eligible run; and
13. all unsafe/diverged runs remain in the dataset.

Scientific failure is not an integrity failure and is never repaired by tuning.

## 6. Frozen stop/go decision

The broad branch stops with `PRIOR_ART_EXPLAINS_FRONTIER` if either condition
holds:

1. a periodic-TDMA or DTSA arm dominates the current method at the N5 Stressed
   boundary and does not increase failures at N10 Moderate; or
2. the private DELTA projection or age-gain arm matches/dominates the current
   method in both primary cells under charged utilization.

The native information gap is supported in a cell only if the paired relative
AoII penalty is at least 10% and its paired 95% interval is entirely positive.
The branch stops with `NO_PRIVATE_FEEDBACK_GAP` if this occurs in at most two
of the six `rho=0.50` cells. Exactly three of six is inconclusive.

Only `INFORMATION_STRUCTURE_GAP_SUPPORTED` permits design of a new candidate,
and only when all of the following hold:

1. all integrity gates pass;
2. private delayed feedback increases native DELTA mean AoII by at least 10%
   with a positive paired 95% interval in at least four of six `rho=0.50`
   cells;
3. neither periodic TDMA nor DTSA explains the formation frontier;
4. neither private DELTA projection nor age-gain matches the current method in
   both primary cells; and
5. at the N5 Stressed boundary, the private DELTA formation projection is at
   least 1% worse than the public projection on RMSE or charged utilization,
   or has more observed safety failures, after both feedback paths are charged.

Any mixed outcome is `INCONCLUSIVE_NO_CANDIDATE`. EXP20A cannot produce a
submission claim; a positive result only authorizes a theory-first candidate
and a later independent preregistered validation.

## 7. Source provenance

- DELTA article: DOI `10.1109/TON.2025.3629535`.
- Authors' reference implementation:
  `https://github.com/signetlabdei/delta_medium_access`, GPLv3, observed commit
  `813dd2d952e172fff302356cd936e0d20a30a328` on 2026-08-31.
- DTSA source: arXiv `2202.00919`.
- Aydin et al. distributed STDMA: DOI `10.1109/ACCESS.2024.3381859`.

Aydin's full two-hop reservation/migration protocol is a mandatory second-stage
baseline only if EXP20A does not stop the branch. It is not silently represented
by the Z-MAC-like arm.
