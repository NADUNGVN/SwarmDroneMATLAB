# Centralized quadratic cross-term diagnostic protocol

**Status:** frozen before execution

**Class:** development-only mechanism diagnostic; not a policy comparison and
not held-out evidence

## Question

Does the global formation-error cross term materially change the sign or
ranking of the isolated link-response score that failed in the online
predictive-VoI sanity experiment?

This is Stage A of the post-falsification audit. It does not claim a Pareto
frontier. A true closed-loop branch or online oracle is authorized only if
this diagnostic first shows that the missing cross term is material.

## Frozen model and data

- scenarios: S1 Stationary-Moderate, S2 Formation-switching, and S6
  Dynamic-excitation from `tcnsGate6Scenario`;
- development seeds: 27020001--27020005;
- baseline: Periodic-10, with its existing sender phase offsets;
- plant: exact double integrator;
- evaluation starts at 8 s;
- horizon: \(H=25\) samples = 0.5 s;
- forward loss/delay: scenario default, namely static 0.2 IID loss and four
  deterministic delay samples;
- no jitter, no parameter search, and no held-out data.

The same 15 baseline runs used by the earlier receiver-truth signal
diagnostic are regenerated because their full trajectories were deliberately
not retained in MAT files. This is a reproducibility rerun, not a new policy
arm.

## Frozen quantity

At each time and controller-relevant link, let \(Z\) be the logged baseline
formation-error trajectory over the next \(H\) samples. Let \(G\) be the exact
Gate-3 response to replacing that receiver's held payload by the current
sender payload after the deterministic forward delay. For delivery success
probability \(p_s\) and \(m=N-1\) followers, export

\[
E_{iso}=p_s\|G\|_F^2/m,
\]

\[
C_{cross}=-2p_s\langle Z,G\rangle_F/m,
\]

\[
B_{total}=C_{cross}-E_{iso}
=p_s(\|Z\|_F^2-\|Z+G\|_F^2)/m.
\]

Only candidates with \(E_{iso}>10^{-14}\) enter ranking/sign summaries. No
candidate is selected or used to change the simulated baseline.

## Counterfactual contract and limitations

This diagnostic freezes all future network inputs and payloads to their
logged Periodic-10 values and applies the candidate correction persistently
through the horizon. It therefore isolates the missing quadratic cross term
exactly within that fixed-input contract.

It is not a true branch replay: it ignores later packet replacement,
in-flight redundancy, state-dependent future payload changes, future
endogenous actions, and saturation across a counterfactual branch. It is also
centralized and reads receiver truth. These limitations prevent any direct
communication-efficiency or online-policy claim.

## Per-run diagnostics

For every scenario/seed export:

- fraction of positive-isolated candidates with \(B_{total}\le0\);
- overlap between the top decile ranked by \(E_{iso}\) and the top decile
  ranked by \(B_{total}\), normalized by the common top-set size;
- Pearson correlation between \(E_{iso}\) and \(B_{total}\);
- fraction for which \(|C_{cross}|>E_{iso}\);
- median \(|C_{cross}|/E_{iso}\);
- event-window allocation of positive total benefit;
- candidate count, formation RMSE, saturation fraction, trace hash, runtime,
  and maximum direct-vs-decomposed identity residual.

All candidate-level values are retained in machine-readable form.

## Frozen decision rule

Technical PASS requires:

1. all 15 runs complete with finite metrics;
2. at least 1,000 positive-isolated candidates per run;
3. maximum quadratic-decomposition residual below \(10^{-12}\);
4. zero acceleration-saturation fraction in the evaluation interval;
5. expected delay/success-probability values are four samples and 0.8.

For each of S2 and S6, call the cross term material when either:

- the mean non-beneficial fraction is at least 0.10; or
- the mean top-decile overlap is at most 0.80.

The scientific decision is:

- `CROSS_TERM_MATERIAL` only if technical PASS holds and the materiality rule
  passes in both S2 and S6;
- `CROSS_TERM_NOT_MATERIAL` if technical PASS holds but either dynamic
  scenario fails;
- `INVALID_OR_OUT_OF_SCOPE` otherwise.

No threshold above may be changed after execution. S1 is a reported boundary
case and does not enter the promotion conjunction.

## Consequence

`CROSS_TERM_MATERIAL` authorizes only a preregistered true branch-at-decision
audit. It does not authorize an online proposed policy or Gate 7. That later
branch audit must establish real counterfactual formation benefit and whether
any centralized oracle action set has frontier headroom after accounting for
its traffic.

`CROSS_TERM_NOT_MATERIAL` stops this predictive mechanism family. The project
then falls back to the established Gate-1--3 theory/limitations route or
requires a research-question reset.
