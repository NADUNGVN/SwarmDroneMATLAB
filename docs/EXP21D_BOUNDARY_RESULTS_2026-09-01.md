# EXP21D-B: D-STR closed-loop boundary results

**Accepted run:** `results/exp21d_boundary_continuation/2026-09-01_104515`  
**Matrix:** 30 fresh seeds x 2 cells x 6 arms = 360 trajectories  
**Integrity:** 16/16 gates; `DSTR_BOUNDARY_STUDY_VALID`

## 1. Scope and validity

EXP21D-B is a mechanism-falsification study, not a policy-selection study. It
keeps the D-STR source-native kernel fixed and asks which extrapolated network
assumption becomes the dominant failure mechanism after exact composition with
the continuous event engine and the formation controller.

Every scheduled DATA recipient outcome was replayed into the controller cache.
The event engine exactly matched scheduled success, erasure and collision
counts; no D-STR opportunity was skipped; there were no cross-plane overlaps
or protocol invariant violations. The registry hash remained `49647790` over
67 leaves.

Reporting Amendment 03 distinguishes the terminal state of the schedule that
was replayed from the terminal state of a paired native kernel retained as
provenance on warm-reference rows. No trajectory was rerun. The corrected
aggregate counts are 45 unsafe, 40 unresolved and 28 terminally colliding
schedules; all failures remain in the artifact.

## 2. Beacon-loss result: evidence corruption is material

At 5% independent DATA-beacon erasure, native D-STR retained common frame
agreement in every run, but terminal resolution fell to 17/30 at N5 and 13/30
at N10. Terminal collision freedom fell to 27/30 and 28/30, respectively.

The paired warm schedule sees the same physical DATA erasures without native
schedule acquisition. Native minus warm gives:

| Cell | RMSE | True AoI | Offered utilization |
|---|---:|---:|---:|
| N5 6-DOF | +10.72% | +20.35% | +15.64% |
| N10 ring2 | +31.60% | +46.30% | +1.14% (CI crosses zero) |

All RMSE and AoI intervals for these two contrasts exclude zero. The N10
result is especially informative: schedule-state corruption causes a large
freshness/control penalty even though mean offered utilization is not reliably
higher than warm. Lower traffic is therefore not evidence of efficiency here;
the native service process is partially collapsing.

Against zero-loss native D-STR, 5% beacon loss increases RMSE/AoI by
13.89%/27.54% at N5 and 27.43%/39.52% at N10. N10 offered utilization decreases
18.05%, confirming that the apparent cost reduction is loss of useful service,
not a favorable frontier movement.

## 3. Restricted management: the common frame ceases to exist

Restricting management reception to the physical neighbor graph makes 0/60
rows physically composable. No restricted row maintains a common frame prefix.
Mean maximum local-frame disagreement is 7.17 slots at N5 and 17.07 at N10;
mean false-Resolved exposure is approximately 1,332 node-frames in both cells.
The worst prefix disagreements reach 12 and 22 slots.

The logical-frame kernel necessarily aligns nodes after the longest declared
frame. Once local frame lengths differ, that alignment is an optimistic
projection rather than an executable physical timeline. Consequently, all
restricted controller metrics are retained in the tidy artifact but excluded
from performance summaries and paired effects. The scientific outcome is the
loss of a shared schedule time base, not an RMSE number.

All 45 observed safety failures occur in this invalid projection (26/30 N5 and
19/30 N10). They are useful severity witnesses but are not promoted to physical
closed-loop effect estimates.

## 4. Rejoin is not the active bottleneck

After node 2 loses its complete local schedule state at source frame 60, the
normal protocol path recovers in every row. Median/95th/max recovery is
5/5/5 frames at N5 and 4/5/9 frames at N10. Relative to zero-loss native D-STR,
N5 RMSE, AoI and utilization differences are negligible. N10 shows small
favorable RMSE/AoI changes and a 2.05% utilization increase; this random-path
effect does not identify rejoin as the primary gap.

## 5. Decision

EXP21D-B identifies two coupled defects that a new candidate must address:

1. implicit DATA reception records are not robust evidence of schedule state;
   modest beacon loss causes unresolved or colliding schedules and large
   freshness penalties, especially as the swarm grows;
2. without formation-wide management visibility, nodes can declare local
   resolution while using incompatible frame lengths, so a physical shared
   schedule cannot be composed.

Fast state reconstruction already works under the tested rejoin event and is
not the next optimization target. The justified design direction is an
explicit schedule-validity mechanism with bounded epoch/version consistency,
evidence repair and a safe fallback when a common schedule certificate cannot
be established. Before designing that candidate, the final Stage-C check will
compose the native schedule with the already certified bounded local-clock
model. This separates evidence/visibility failures from timing error and
prevents guard logic from being added without evidence.

No submission or superiority claim is opened by EXP21D-B.
