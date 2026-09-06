# EXP21B — Continuous-time MAC validity results

**Run:** `results/exp21b_continuous_timing_validity/2026-09-01_040346`

**Matrix:** 1600/1600 rows (100 paired seeds x 2 swarm sizes x 2
synchronization periods x 4 guard factors)

**Runtime:** 1 min 11 s

**Integrity:** 11/11 gates passed

**Frozen verdict:** `TIMING_MODEL_VALID_FOR_INTEGRATION`

## 1. Question answered

EXP21A showed catastrophic collisions when locally scheduled DATA was shifted
on a 1-ms simulation grid.  EXP21B asks the narrower prerequisite question:
does a continuous-time local-clock construction reproduce the clock equation,
exact packet airtime, collision geometry, and a sufficient finite-horizon
guard bound before it is allowed into the closed loop?

The answer is yes.  This is a model-validity result, not a policy-performance
or formation-control result.

## 2. Frozen timing model and certificate

Within synchronization epoch `q`, node `i` uses

```text
C_i(t) = theta_iq + (1 + delta_i)(t - tau_q),
t_i(b) = tau_q + (b - theta_iq)/(1 + delta_i).
```

DATA transmissions occupy half-open physical intervals and their duration is
the exact 384-byte airtime at 1 Mbit/s, namely 3.072 ms.  For offset bound
`Theta`, drift bound `Delta`, and horizon `H`, the registered boundary-error
bound is

```text
E(H) = (Theta + Delta H)/(1 - Delta),
G_safe(H) = 2 E(H).
```

The randomized study used `Theta = 0.25 ms`, `Delta = 40 ppm`, a 12-s
horizon, and synchronization periods 0.5 s and infinity.  The corresponding
sufficient guards are 0.540022 ms and 1.46006 ms.

## 3. Main validity result

All 800 rows at or above the sufficient bound had zero collision frames for
both `N=5` and `N=10`.  The maximum clock-equation residual over all 1600 rows
was `1.78e-15 s`, and interval-union accounting closed exactly within the
registered numerical tolerance.

The certificate is sufficient rather than fitted.  Collision witnesses below
the bound demonstrate that the test was capable of detecting overlap:

| N | Sync period | Guard factor 0 | Guard factor 0.75 | Guard factor >= 1 |
|---:|---:|---:|---:|---:|
| 5 | 0.5 s | 100/100 collide | 95/100 collide | 0/200 collide |
| 5 | none in 12 s | 100/100 collide | 1/100 collide | 0/200 collide |
| 10 | 0.5 s | 100/100 collide | 98/100 collide | 0/200 collide |
| 10 | none in 12 s | 100/100 collide | 2/100 collide | 0/200 collide |

The non-monotone witness frequency between frequent synchronization and no
synchronization is not interpreted as synchronization being harmful.  It is a
consequence of resetting independent bounded offsets at every sync epoch,
which creates more boundary encounters.  The registered claim is instead the
analytical one that synchronization reduces the required worst-case guard,
which it does from 1.46006 ms to 0.540022 ms.

## 4. Integrity gates

All registered gates passed: frozen registry, exact unique matrix, exact seed
and factor coverage, paired absolute clock draws, collision-free sufficient
guard, clock-equation closure, valid positive-overlap witnesses, interval
accounting closure, and reduced certified guard under synchronization.  No
policy or formation outcome entered a gate.

## 5. Authorized interpretation

EXP21B invalidates the 1-ms phase-quantized clock abstraction as the sole basis
for judging scheduled access.  It establishes a numerically and analytically
consistent continuous-time kernel that may be integrated into the closed-loop
shared medium.

It does **not** show that distributed scheduling is robust, that the guard is
necessary or minimal, or that reservation/control traffic can maintain a
valid schedule.  Those questions require closed-loop integration and explicit
control-frame contention.
