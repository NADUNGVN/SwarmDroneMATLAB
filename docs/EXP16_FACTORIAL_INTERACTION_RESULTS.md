# EXP16 preregistered feedback-route-by-MAC interaction results

## Run identity

- Experiment: `exp16_factorial_interaction`
- Run: `2026-08-31_104551`
- Registry: `EXP16-FACTORIAL-INTERACTION-HOLDOUT-v1`
- Registry hash: `89775929` over 56 leaves
- Holdout seeds: `16022001:16022100`
- Frozen matrix: 600/600 rows
- Elapsed time: 3 min 25 s on a 16-worker process pool
- Source snapshot: `results/exp16_factorial_interaction/2026-08-31_104551/frozen_source`

The design, six-test family and analysis path were frozen before the first
holdout simulation. Contract tests used only development seed `16021999` and a
synthetic analysis fixture. No performance column was inspected before the
holdout-open artifact was written.

## Integrity verdict

All 14/14 gates pass:

- all 600 rows are complete and unique, with exactly six arms per seed;
- all arms within a seed use one absolute random trace, channel-state trace and
  estimator realization across both MAC levels;
- route, MAC, access and primary-factor flags match the registry;
- piggyback-only produces no standalone ACK, while adaptive decisions occur
  only in adaptive arms;
- terminal DATA/ACK accounting and channel-busy union close;
- maximum queue depth is 2 and maximum history depth is 32;
- there are zero divergences and zero protocol violations;
- all eligible continuous outcomes are finite and confirmed age remains
  conservative relative to receiver truth.

Performance analysis was opened only after these gates passed.

## Primary confirmatory results

For an outcome `Y`, the registered within-seed route difference is

`D_m(Y) = Y(adaptive,m) - Y(piggyback,m)`

and the formal interaction is

`I(Y) = D_ALOHA(Y) - D_CSMA(Y)`.

All tests below are oriented so that a negative estimate supports the frozen
alternative. The six one-sided p-values are Holm adjusted as one family.

| Outcome | Test | Estimate | 95% paired t CI | 95% bootstrap CI | Standardized effect | Holm p |
|---|---|---:|---:|---:|---:|---:|
| RMSE [m] | CSMA: piggyback − adaptive | −0.000532 | [−0.000711, −0.000353] | [−0.000704, −0.000355] | −0.589 | 5.33e−8 |
| RMSE [m] | ALOHA: adaptive − piggyback | −0.008737 | [−0.011766, −0.005708] | [−0.011780, −0.005804] | −0.572 | 5.60e−8 |
| RMSE [m] | interaction | −0.009268 | [−0.012319, −0.006218] | [−0.012335, −0.006341] | −0.603 | 4.26e−8 |
| Offered utilization | CSMA: piggyback − adaptive | −0.007402 | [−0.009288, −0.005517] | [−0.009329, −0.005627] | −0.779 | 1.34e−11 |
| Offered utilization | ALOHA: adaptive − piggyback | −0.045558 | [−0.054852, −0.036264] | [−0.054803, −0.036401] | −0.973 | 1.08e−15 |
| Offered utilization | interaction | −0.052961 | [−0.062447, −0.043475] | [−0.062336, −0.043576] | −1.108 | 1.48e−18 |

All 6/6 tests reject after Holm adjustment and both 2/2 metric reversal rules
pass. The frozen verdict is:

`SUPPORTED_REGISTERED_FACTORIAL_INTERACTION`

The result is stronger than comparing separate directional tests: the
interaction is computed within every seed from all four primary factorial
cells before inference.

## Cell means and effect size in engineering units

| MAC | Registered winner | Winner RMSE | Opposite RMSE | Relative RMSE | Winner offered util. | Opposite offered util. | Relative offered util. |
|---|---|---:|---:|---:|---:|---:|---:|
| CSMA | piggyback-only | 0.053781 | 0.054312 | −0.98% | 0.275993 | 0.283396 | −2.61% |
| ALOHA | adaptive | 0.079305 | 0.088042 | −9.92% | 0.768435 | 0.813993 | −5.60% |

The ALOHA magnitude is smaller than EXP14I's 11.84% RMSE result but retains the
same direction on a disjoint seed block. The CSMA RMSE advantage remains small,
so it must not be presented without its interval and scope.

## Fixed-deadline hybrid reference

The legacy fixed-deadline hybrid route is a secondary practical ACK-aware
baseline, not part of the primary family.

- Under CSMA, adaptive and piggyback reduce RMSE relative to hybrid by 6.04%
  and 6.96%, respectively. Piggyback reduces offered utilization by 3.94%.
- Under ALOHA, adaptive and hybrid RMSE are unresolved: adaptive minus hybrid
  is +0.000217 m with CI [−0.001664, 0.002098]. Piggyback is worse than hybrid
  by 11.32% RMSE and 5.38% offered utilization.

This reinforces the mechanistic interpretation: a fast standalone route is
valuable under the tested ALOHA load, but the adaptive scheduling detail is not
identified as superior to the simple fixed-deadline hybrid baseline there.

## Safety boundary

All six arms have 0/100 observed failures and zero divergences. Both registered
observed safety guards pass. For each arm, however, the two-sided 95% Wilson
upper bound is 3.70%. EXP16 therefore supplies no population-safety guarantee
and no safety superiority/noninferiority claim.

## Claim boundary

EXP16 supports only this statement:

> In the matched N=5 Moderate abstract shared-medium cell, the configured
> access mechanism modifies the relative RMSE and offered-airtime effect of
> adaptive standalone-plus-piggyback feedback versus piggyback-only feedback,
> in the preregistered direction.

EXP16 does not validate a general MAC selector, IEEE 802.11 behavior, genuine
hardware ALOHA, N=10/N=20 scalability, energy savings or real-radio validity.
It does not establish that adaptive feedback is better than every ACK-aware
baseline under ALOHA.

## Next gate

The next study must map whether the interaction survives a frozen operating
envelope spanning load, burst/loss, N=5/N=10 and reverse asymmetry/hidden
terminal conditions. Policy parameters remain fixed. Hardware procurement
waits until this robustness gate determines whether the interaction is broad
enough to justify a measured-radio study.

