# EXP21B — Continuous-time local-TDMA model validity

**Status:** frozen model-validity design, written before EXP21B diagnostic
outcomes are generated

**Study type:** deterministic/adversarial infrastructure validation

**Policy optimization:** prohibited

**Formation-performance or submission claim:** prohibited

## 1. Reason for the study

EXP21A evaluated local scheduling on a 1-ms global grid.  A node used its
perturbed local clock only to choose a slot label at each global grid point.
That abstraction is discontinuous at zero offset and does not represent the
actual start time of an asynchronous transmitter.  It also called the 1-ms MAC
quantum a TDMA slot even though a 96-byte DATA frame at 250 kbit/s occupies
four such quanta.

EXP21B replaces that timing abstraction before any scheduling mechanism is
optimized.  Its only question is:

> Does a continuous-time interval model reproduce the analytically expected
> collision/no-collision boundary under local clock offset, drift,
> resynchronization and receiver-specific interference?

EXP21A remains immutable and is not reinterpreted as this corrected model.

## 2. Frozen clock and slot model

Within synchronization epoch `q`, beginning at global time `tau_q`, node `i`
uses

```text
C_i(t) = theta_iq + (1 + delta_i) (t - tau_q),
```

where `theta_iq` is residual offset in seconds and `delta_i` is fractional
frequency error.  The nominal local boundary `b` occurs globally at

```text
t_i(b) = tau_q + (b - theta_iq)/(1 + delta_i).
```

Intervals are half open: `[start,start+D_DATA)`.  Two frames collide at a
receiver only when their intervals overlap with positive duration and the
receiver's interference map declares the other sender an interferer.

The physical TDMA slot duration is

```text
T_slot = D_DATA + G,
```

where `G` is the full nominal separation between consecutive DATA intervals.
The superframe is `F*T_slot`, with `F >= N` unless spatial reuse is explicitly
tested.  The 1-ms simulator quantum is not used as the ownership-slot length.

At synchronization, the local superframe restarts.  A boundary whose solved
global start lies outside that synchronization epoch is not transmitted.  This
makes missed first opportunities explicit rather than clipping them onto a
global grid.

## 3. Frozen sufficient guard bound

For nominal boundary `0 <= b <= H`, assume

```text
|theta_iq| <= Theta,  |delta_i| <= Delta < 1,
```

where `H` is the smaller of the synchronization interval and diagnostic
horizon.  The boundary displacement obeys

```text
|t_i(b) - (tau_q+b)|
    = |theta_iq + delta_i*b|/|1+delta_i|
    <= (Theta + Delta*H)/(1-Delta) = E.
```

For consecutive nominal slots, the smallest actual separation between the
later start and the earlier DATA end is at least `G-2E`.  Therefore the frozen
sufficient condition is

```text
G >= G_safe = 2(Theta + Delta*H)/(1-Delta).
```

Equality is safe because transmission intervals are half open.  This is a
sufficient finite-horizon bound, not an optimal guard theorem.

## 4. Mandatory deterministic cases

1. **Zero-clock equivalence:** zero offset/drift and zero guard reproduce exact
   nominal starts and have no collision for unique adjacent slots.
2. **Offset witness:** adversarial adjacent offsets collide when `G < 2*Theta`.
3. **Offset bound:** the same witness is collision-free at `G_safe`.
4. **Drift witness:** adversarial opposing drift produces an overlap late in a
   sufficiently long unsynchronized horizon when guard is zero.
5. **Synchronization bound:** resetting every 0.5 s reduces `G_safe` relative
   to a 12-s unsynchronized mission and eliminates the registered witness.
6. **Positive-duration rule:** touching half-open intervals do not collide.
7. **Receiver-specific interference:** temporal overlap alone is insufficient;
   only declared interfering receivers are corrupted.
8. **Physical-slot rule:** the slot duration equals exact DATA airtime plus
   guard, independently of the legacy 1-ms MAC quantum.

## 5. Frozen randomized stress matrix

The diagnostic uses seeds `16031001:16031100`, `N={5,10}`, offset bound
`Theta=0.25 ms`, drift bound `Delta=40 ppm`, DATA airtime `3.072 ms`, horizon
12 s, and synchronization periods `{0.5 s, infinity}`.  For every paired clock
draw it evaluates guard factors `{0,0.75,1.0,1.25}` times `G_safe`.

Clock draws are indexed by absolute `(seed,epoch,node)` coordinates.  The
factor-1 and factor-1.25 arms must be collision-free for every trajectory.
Sub-bound arms are diagnostic and need not collide for every random draw; the
adversarial cases establish that the sufficient boundary is meaningful.

## 6. Integrity and continuation gates

The timing model is eligible for integration into the closed-loop simulator
only if all gates pass:

1. all mandatory deterministic cases pass;
2. repeated configurations are bit-identical;
3. exact randomized matrix and declared seeds are retained;
4. all factor-1 and factor-1.25 trajectories are collision-free;
5. all starts solve the declared local-clock equation within numerical
   tolerance;
6. every collision corresponds to positive interval overlap and declared
   receiver interference;
7. offered airtime and busy-time union accounting close;
8. synchronization strictly reduces the analytical guard bound for nonzero
   drift over the registered horizon; and
9. no formation controller or scheduling-policy outcome is used as a model
   validity criterion.

Failure stops integration and requires a timing-model correction.  Passing
authorizes integration only; it does not validate a distributed scheduler.
