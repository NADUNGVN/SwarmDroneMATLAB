# FB0 feedback-economics protocol

**Status:** preregistered before result generation  
**Frozen explicit-ACK stop point:** `44d354fcba8f70576eb9c0e28206a23fae717aa8`  
**Frozen O1 source:** `centralized_state_oracle_frozen` at
`ce835c9c3195db86e610c24f4a6db21d42211559`

## Question

How much receiver-feedback overhead can each frozen O1 operating point afford
before it loses its performance-matched communication-cost advantage over the
unchanged periodic Pareto frontier?

FB0 is an offline economic sensitivity analysis. It does not rerun a plant or
network trajectory, change an O1 action, alter the periodic comparator, or
authorize an explicit-ACK policy.

## Frozen inputs

The sole trajectory-level input is
`results/tcns_ab0_ack_cost_adjusted_o1/2026-09-07_170715/adjusted_runs.csv`.
It contains the immutable O1 and periodic development runs for S2--S6. FB0
uses all five paired development seeds and the original 14-point O1 lambda
grid. Held-out seeds are prohibited.

For O1 operating point \(r\), define:

- \(E_r\): five-seed mean primary formation RMSE;
- \(D_r\): five-seed mean O1 DATA cost during the frozen evaluation window,
  in Hz/channel;
- \(A_r\): five-seed mean rate of accepted DATA deliveries that would be
  eligible to produce protocol-equivalent feedback, in feedbacks/s/channel;
- \(C_P(E_r)\): piecewise-linear interpolation of the lower-left periodic
  Pareto frontier cost at formation error \(E_r\).

Here \(A_r\) is reconstructed from the saved `adjustedAckC2Count` and the
unchanged evaluation duration and active-channel count. AB0 established that
C1 and C2 counts coincide on every frozen O1 run; C2 remains authoritative.

## Economic model and estimands

Let \(\eta\) be the cost of one feedback relative to one DATA transmission,
and let \(f\in[0,1]\) be the fraction of feedback-eligible accepted deliveries
that actually incur feedback. The adjusted O1 cost is

\[
C_r(\eta,f)=D_r+\eta f A_r.
\]

For full feedback (\(f=1\)), the critical feedback price is

\[
\eta_r^\star=\frac{C_P(E_r)-D_r}{A_r}.
\]

At the frozen feedback price \(\eta_0=0.25\), the raw allowable feedback
fraction is

\[
f_r^\star=\frac{C_P(E_r)-D_r}{0.25A_r}
=\frac{\eta_r^\star}{0.25}.
\]

The report will retain the raw value and also report
\(\min(1,\max(0,f_r^\star))\) as an operational fraction. A negative value
means O1 DATA alone is already more expensive than periodic at the same
performance. A value in \([0,1)\) means only that fraction of eligible
deliveries is affordable at price 0.25. A value at least one means full
feedback is affordable at this operating point.

## Eligibility and interpolation

1. Periodic and O1 results are first averaged by frozen arm over the five
   development seeds.
2. The periodic lower-left Pareto frontier is constructed using the existing
   `tcnsParetoFrontier` rule: lower error and lower cost are preferable.
3. \(C_P(E_r)\) is evaluated only if \(E_r\) lies inside the observed periodic
   frontier error interval. Extrapolation is forbidden.
4. An O1 point with \(A_r=0\) is reported separately. It has no finite
   feedback-price denominator and is not inserted into finite-price summary
   statistics.
5. All eligible O1 points are reported, whether favorable or unfavorable.
   Points are not filtered using their outcome.

## Frozen outputs

For every S2--S6 operating point, report the quantities above and its status:

- `DATA_ALREADY_UNECONOMIC` if \(\eta_r^\star<0\);
- `PRICE_025_UNAFFORDABLE` if \(0\le\eta_r^\star<0.25\);
- `FULL_FEEDBACK_AFFORDABLE` if \(\eta_r^\star\ge0.25\);
- an explicit exclusion reason if outside the observed domain or if \(A_r=0\).

For each scenario report count, median/IQR/min/max of finite
\(\eta_r^\star\), median/IQR of raw \(f_r^\star\), fraction with positive
headroom, and fraction able to afford full feedback at price 0.25. These are
descriptive economics, not a new policy pass/fail criterion.

## Integrity checks

The FB0 script must verify the source row counts, five seeds per arm, C1=C2,
nonnegative feedback counts/rates, unchanged C0=DATA cost for O1, strict
periodic-frontier ordering, algebraic reconstruction of C1/C2 cost, and zero
trajectory reruns. A failed check invalidates the result.

