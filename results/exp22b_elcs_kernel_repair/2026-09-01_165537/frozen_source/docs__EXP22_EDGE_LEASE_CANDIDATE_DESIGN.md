# EXP22: Edge-Leased Certified Scheduling with Guarded Fallback

**Design opened:** 2026-09-01  
**Evidence basis:** EXP21D-B and EXP21D-C accepted runs  
**Working name:** ELCS-F  
**Stage:** candidate mechanism and theorem construction  
**Promotion, holdout and submission claims:** closed

## 1. Design target

The candidate addresses exactly two reproduced failures of native D-STR:

1. implicit reception records become unreliable schedule evidence under DATA
   beacon erasure; and
2. local grow/shrink state can disagree when management visibility is not
   formation-wide, so locally Resolved nodes no longer share one executable
   frame.

Clock offset/drift is not a candidate target. EXP21D-C already shows that the
finite-horizon guard closes that boundary. State-loss/rejoin is also not the
primary target because native D-STR recovered in every registered rejoin row.

ELCS-F does not claim novelty for leases, sequence numbers, graph coloring,
NACK, retries, contention fallback or guard intervals. Its proposed technical
object is a locally checkable schedule-validity invariant that composes:

- spatial conflict evidence over a declared mobility/uncertainty envelope;
- asymmetric, loss-safe edge leases;
- temporal lease fencing under bounded clock error; and
- a physically disjoint fallback service region.

## 2. Network and conflict envelope

Let `G_d(t)=(V,E_d(t))` be the directed DATA graph and let `I_r(t)` denote the
set of transmitters whose signals are detectable at receiver `r`. The
transmitter conflict graph is

`G_c(t)=(V,E_c(t))`,

where `{i,j}` is in `E_c(t)` if simultaneous transmissions by `i` and `j` can
corrupt at least one intended DATA reception of either transmitter. It is a
sender-conflict graph, not merely the communication-neighbor graph.

For lease interval `J_k=[a_k,x_k]`, scheduling uses a conservative envelope

`Ebar_c(k) superset union_{t in J_k} E_c(t)`.

The envelope can be supplied by a bounded-motion reachability calculation or
by a registered topology oracle in an isolated mechanism test. The candidate
may read only its own incident envelope edges. Performance outside the stated
motion/uncertainty envelope is a boundary result, not covered by the safety
claim.

## 3. Edge lease

Every undirected envelope edge `{i,j}` has deterministic owner

`o(i,j)=min(i,j)`

and client `c(i,j)=max(i,j)`. A lease is

`kappa_ij=(v,L,s_i,s_j,a,x,h)`,

where `v` is the schedule epoch/version, `L` the common DATA-frame length,
`s_i` and `s_j` the endpoint slots, `[a,x]` the nominal validity interval and
`h` a digest over these fields and the edge identity. Authentication against
an adversary is outside the present model; IDs and payload integrity are
assumed, while loss, collision, duplication and delay are modelled.

The owner transmits a GRANT only if:

- both endpoint tuples use the same `(v,L,a,x)`;
- `s_i != s_j` for an envelope conflict edge;
- its own tuple is already fixed; and
- issuing the grant does not overlap an earlier owner lock.

Immediately upon attempting a GRANT, the owner locks its tuple through the
conservative release time, whether or not the GRANT is decoded. This is the
key loss-safe asymmetry. The client may use the edge only after decoding a
matching GRANT. Loss therefore creates conservatism, not false validity.

## 4. Local validity and temporal fencing

Let the absolute boundary error over one lease horizon be bounded by `E_k`.
The clock guard must satisfy `G >= 2 E_k`, using the already validated affine
clock construction.

To prevent a stale client lease from overlapping a changed owner tuple:

- a client stops treating lease `kappa` as valid no later than nominal
  `x-E_k`; and
- the owner cannot release or replace its locked tuple before `x+E_k`.

Node `i` is scheduled-valid at time `t`, written `V_i(t)=1`, only if:

1. its local tuple `(v_i,L_i,s_i,a_i,x_i)` is fixed;
2. for every lower-ID envelope neighbor `j`, it has decoded a matching,
   unexpired lease owned by `j`;
3. all such leases agree on `(v_i,L_i,s_i,a_i,x_i)` and declare distinct
   endpoint slots; and
4. the finite-horizon clock certificate and guard remain valid.

No positive inference is made from silence. A missing, expired, mismatched or
future-version GRANT makes `V_i=0`.

An owner does not need an ACK of its own GRANT to remain safe: a higher-ID
client cannot become scheduled-valid without decoding that GRANT. This avoids
requiring common knowledge over a lossy channel.

## 5. Guarded fallback

Each superframe contains nonoverlapping regions:

1. STATUS/CLAIM control minislot window;
2. GRANT/repair control minislot window;
3. fallback DATA contention window; and
4. certified scheduled DATA window.

A node with `V_i=0` is forbidden from the scheduled region. It may broadcast
state only in the fallback window using a registered access probability. Thus
an uncertified node cannot collide with a certified scheduled transmission.
Fallback collisions remain possible and are explicitly charged.

For `m` fallback contenders with one minislot, independent access `p=1/m` and
conditional recipient success probability at least `q>0`, a particular node
has per-minislot success probability

`r_m = q p (1-p)^(m-1) >= q/(e m)`.

With `W` independent fallback minislots per superframe, its per-frame success
probability is at least

`1-(1-q/(e m))^W`,

so the expected number of fallback frames to success is bounded by the
reciprocal. This is a service bound under the declared full-contention/i.i.d.
model, not a deterministic delivery guarantee.

## 6. Safety proposition

**Proposition 1 (loss-safe scheduled collision freedom).** Suppose during a
lease interval:

1. `Ebar_c` contains every physical sender-conflict edge;
2. every protocol-compliant node transmits in the scheduled region only when
   its local validity predicate is true;
3. owners obey grant locks and temporal fencing;
4. clients activate only from decoded matching grants;
5. every granted conflict-edge pair has distinct slots in a common epoch and
   frame; and
6. local boundary error is at most `E_k` with guard `G>=2E_k`.

Then no two certified scheduled transmissions overlap at a receiver where
they conflict.

**Proof sketch.** Take any physical conflicting pair `{i,j}` and orient it so
`i<j`. By envelope containment, `{i,j}` is an edge certified by owner `i`.
If `j` is scheduled-active, it decoded a live grant from `i` containing the
common tuple and distinct slots. From the moment `i` attempted that grant
until the fenced release time, `i` cannot transmit under a conflicting tuple.
If the grant was lost, `j` is inactive and cannot be the second scheduled
transmitter. If decoded, nominal adjacent slot intervals are separated by the
guard; `G>=2E_k` preserves nonoverlap after both clock errors. Since fallback
occupies a disjoint region, an invalid endpoint cannot create a scheduled/
fallback overlap. The argument applies to every physical conflict edge.

This proposition is conditional on envelope containment and protocol
compliance. It is stronger than a convergence statistic but narrower than a
Byzantine or unbounded-mobility guarantee.

## 7. Acquisition rule used for the first implementation

To isolate validity from sophisticated allocation, the initial implementation
uses fixed `L=N` and deterministic priority coloring:

1. node 1 fixes slot 1;
2. node `i` repeatedly listens for STATUS tuples from all lower-ID envelope
   neighbors;
3. after learning their fixed slots, it chooses the smallest unused slot;
4. it announces that tuple until matching GRANTs from every lower-ID envelope
   neighbor are decoded; and
5. leases are refreshed before expiry without changing the tuple.

This rule converges by ID induction under recurrent successful control
delivery. It is intentionally conservative: fixed `L=N` prevents frame-length
disagreement but may sacrifice spatial-reuse capacity. Later development may
change the proposal engine only after the safety kernel passes; the validity
predicate and lease semantics remain fixed.

## 8. Kernel gates before closed-loop work

The isolated kernel must demonstrate, without parameter selection:

1. exact zero-loss convergence by ID induction;
2. zero false-valid edge-frames under arbitrary finite patterns of lost GRANTs;
3. lost final GRANT leaves only the client inactive while the owner lock holds;
4. stale, duplicate and future-version messages never create validity;
5. lease expiry precedes owner tuple release by the declared fence;
6. restricted management reach cannot create frame disagreement or certified
   conflicts; affected nodes enter fallback;
7. DATA beacon erasure never mutates schedule evidence;
8. every control, fallback and scheduled attempt is separately charged;
9. fallback and scheduled regions are physically disjoint; and
10. fixed traces replay bit-identically with zero receiver-truth or
    future-random decision reads.

Only after these gates pass will EXP22 open development comparisons. Mandatory
references remain native D-STR, D-ART single-hop, a 6P/MSF-inspired
transactional reference, periodic/fallback-only frontiers and an oracle-warm
coloring. ELCS-F cannot advance to fresh-seed confirmation until direct
prior-art comparisons and sensitivity/robustness gates are passed.
