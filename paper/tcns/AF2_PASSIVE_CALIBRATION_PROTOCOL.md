# AF2 passive ACK-free belief calibration protocol

**Status:** frozen before result generation  
**Policy effect:** none; the belief is reconstructed offline and cannot alter
any transmission or control action.

## 1. Scientific question

Does the AF0 packet-identity PMF reproduce receiver-memory outcomes under the
same static IID loss and deterministic-delay law used by the S2/S6 simulator,
before the PMF is connected to a scheduler?

## 2. Frozen matrix

- scenarios: S2 Formation-switching and S6 Dynamic-excitation only;
- development seeds: 27020001--27020005;
- existing periodic P10 schedule: period 0.10 s;
- mission: 30 s, exact double-integrator plant;
- scored window: \(8\le t<30\) s;
- DATA channel: frozen Moderate IID loss 0.20, delay 0.08 s, no jitter;
- no ACK generation and no ACK input to the belief;
- existing per-sender periodic phases and common random traces unchanged.

Receiver-memory and sender-fire logging are passive.  Every scored PMF is
computed after same-tick due deliveries, matching the simulator's logged
receiver state.  No held-out seed is used.

## 3. Proper scores

For observation \(n\), let \(s_n^\star\) be the realized receiver-held packet
identity and \(b_n(s)\) the AF0 PMF.  Report

\[
\mathrm{NLL}_n=-\log b_n(s_n^\star)
\]

and the multiclass Brier score

\[
\mathrm{BS}_n=\sum_s
\left(b_n(s)-\mathbf 1\{s=s_n^\star\}\right)^2.
\]

The corresponding conditional Bayes expectations are

\[
H(b_n)=-\sum_s b_n(s)\log b_n(s),\qquad
B_0(b_n)=1-\sum_s b_n(s)^2.
\]

For a matched model, mean NLL should agree with mean entropy and mean Brier
with mean \(B_0\), subject to finite development-sample variation.

## 4. Reliability calibration

Pool every candidate-state probability and its binary realization indicator
within each scenario.  Use fixed equal-width bins

\[
[0,0.1),[0.1,0.2),\ldots,[0.9,1].
\]

For nonempty bin \(g\), report count, mean forecast, empirical frequency and
their absolute gap.  Expected calibration error (ECE) weights each gap by
bin count.  Maximum calibration error (MCE) is evaluated only over bins with
at least 100 candidate-state forecasts.

Also report the distribution of probability assigned to the realized state,
MAP packet-identity accuracy, support size, and any support violation.

## 5. Control-residual validation quantities

For each candidate packet \(s\), compute the exact communication-induced
command correction used by the implemented controller.  For an ordinary
link,

\[
d^c_{ij}(s)=K_p\alpha_i[p_j-p_s]+K_v\alpha_i[v_j-v_s],
\]

where \(\alpha_i\) is the implemented degree scale.  For a pinned leader
stream, use

\[
d^c_{iL}(s)=K_{pL}[p_L-p_s]+K_{vL}[v_L-v_s]+[a_L-a_s].
\]

Report the belief mean \(\mathbb E[d^c]\), second moment
\(\mathbb E[\lVert d^c\rVert^2]\), and realized correction.  Per scenario
report vector-component correlation, norm correlation/RMSE/bias, and
second-moment correlation/RMSE/bias.  These are diagnostics rather than a
tuning objective; the realized correction is validation-only truth.

## 6. Frozen pass/fail rule

AF2 returns `AF2_CALIBRATION_PASS` for a scenario only if all conditions hold:

1. zero realized-state support violations;
2. all probabilities are finite, nonnegative, and normalized within
   \(10^{-12}\);
3. mean NLL minus mean entropy has absolute value at most 0.05 nat;
4. mean Brier minus mean conditional Bayes Brier has absolute value at most
   0.03;
5. ECE is at most 0.03;
6. MCE over bins with at least 100 forecasts is at most 0.10;
7. trace hashes are equal across the passive reconstruction and the original
   simulator output by construction, and all information-leak flags remain
   false.

Both S2 and S6 must pass.  If either fails, return
`STOP_BELIEF_MODEL`; do not reinterpret bins, thresholds, seeds, or the
channel model after viewing results.

Passing AF2 validates the AF0 PMF under the frozen passive periodic
experiment only.  It does not close the AF0 proof gaps concerning the full
plant-observation filtration or endogenous active action times, and it does
not authorize AF5.

## 7. Required artifacts

- one row per scored link/sample observation;
- fixed-bin calibration table;
- scenario summary and machine-readable verdict;
- exact seed/config/provenance metadata;
- a generated reliability/residual diagnostic figure;
- a standalone reproducibility script and test.

