# EXP22C: ELCS-F kernel results

**Accepted run:** `results/exp22c_elcs_kernel_activation/2026-09-01_170847`  
**Matrix:** 100 fresh seeds x 2 graphs x 7 conditions = 1,400 rows  
**Integrity:** 16/16 gates; `ELCS_F_KERNEL_VALID`

## 1. Safety invariant

Across all 1,400 rows, including 5% DATA erasure, 5% management erasure,
restricted management reach, permanent directed-GRANT loss, state loss and
owner reconfiguration, the certified scheduled region has:

- zero scheduled collision frames;
- zero false-valid edge-frames;
- zero owner-lock violations;
- zero stale- or future-version accepts; and
- exact management, scheduled-DATA and fallback-DATA recipient accounting.

The zero-loss and DATA-erasure arms have identical schedule-state hashes in
every paired seed/cell. DATA success is therefore no longer implicit schedule
evidence; erasing a DATA beacon cannot alter certification state.

Every selected directed-GRANT blackout creates an owner lock while leaving the
client without that lease. All 200 selected clients remain uncertified rather
than becoming false-active. This is the intended asymmetric loss semantics.

## 2. Liveness and repair

Node-indexed STATUS/GRANT minislots close the v1 refresh-outage failure:
200/200 zero-loss rows are terminally fully certified. First full
certification occurs at frame 5 in N5 and frame 10 in N10. With 5% management
erasure, mean first certification moves only to 5.84 and 11.37 frames, and all
200 rows remain terminally certified.

All 200 state-loss rows recover; mean recovery is 2 frames in both cells.
Every owner-reconfiguration waits beyond its release fence, activates the
registered color conflict, and returns to full certification. The cascade
performs one automatic recolor per N5 row and five per N10 row, totaling 600.

## 3. Boundary retained rather than hidden

Two permanent-information conditions deliberately do not finish globally
certified:

- directed-GRANT blackout: the selected client cannot legally enter the
  scheduled region;
- local management reach: some sender-conflict edges are outside management
  visibility, so endpoint leases cannot be established.

Together these produce 400 terminally noncertified rows. The candidate remains
safe by moving affected nodes to the disjoint fallback region, but the fallback
is not collision-free: 26,694 fallback collision frames are retained. Under
local management, only 39.95% of N5 and 19.98% of N10 node-frames are
certified; mean fallback attempts are 481.86 and 640.89 per 400-frame run.

Thus EXP22C proves the isolated schedule-validity invariant under the declared
model; it does not prove that fallback service is adequate for formation
control. That question must be answered on the continuous event timeline.

## 4. Cost boundary

In zero loss, mean offered/channel utilization is 0.4864/0.4863 at N5 and
0.5374/0.3749 at N10. Control attempts average 1,794 and 3,774 over 400 frames.
These values include STATUS and aggregated-GRANT frames, but use the logical
kernel timing abstraction. They are not yet the final common-PHY closed-loop
cost comparison.

## 5. Decision

ELCS-F is authorized for continuous/closed-loop integration only. The next
stage must:

1. translate every STATUS, GRANT, fallback and scheduled DATA attempt to one
   continuous event timeline with exact payload-specific airtime;
2. apply actual DATA success/erasure/collision masks to the controller cache;
3. compose the full-mission affine-clock guard without assuming an uncharged
   synchronization reset;
4. retain fallback collision and unsafe outcomes; and
5. make no superiority claim until native D-STR, D-ART and a 6P/MSF-inspired
   transactional reference run on the same timeline.

Method promotion, fresh-seed confirmation and manuscript construction remain
closed.
