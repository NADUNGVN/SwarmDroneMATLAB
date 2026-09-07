# True branch-at-decision value diagnostic protocol

**Status:** frozen before execution

**Class:** development-only paired counterfactual diagnostic; not held-out
evidence and not an online proposed policy

## Question

Does the centralized fixed-input cross-term score predict the realized
finite-horizon value of one extra transmission after the plant, receiver
memory, later periodic packets, and future payloads are allowed to evolve
endogenously?

This is the required bridge between the algebraic cross-term diagnostic and
any richer information architecture. Failure stops the predictive mechanism
family; success authorizes only a centralized online-oracle sanity study.

## Frozen experiment matrix

- scenarios: S2 Formation-switching and S6 Dynamic-excitation;
- development seeds: 27020001--27020005;
- baseline: Periodic-10 with the existing deterministic sender phase trace;
- plant: exact double integrator;
- horizon: \(H=25\) samples = 0.5 s;
- fixed anchor times: 8.5, 9.5, ..., 27.5 s;
- 20 candidate actions per scenario/seed, hence 200 paired forced branches;
- static Moderate channel: 0.2 IID forward loss, four-sample deterministic
  delay, no jitter;
- no parameter search and no held-out data.

The ten controller-relevant payload links are traversed in this fixed order
and repeated once across the 20 anchors:

1. ordinary \(1\to2\);
2. ordinary \(3\to2\);
3. ordinary \(2\to3\);
4. ordinary \(4\to3\);
5. ordinary \(3\to4\);
6. ordinary \(5\to4\);
7. ordinary \(1\to5\);
8. ordinary \(4\to5\);
9. pinned-leader payload \(1\to2\);
10. pinned-leader payload \(1\to4\).

For an anchor/link, choose the first outer sample at or after the anchor,
within at most nine later samples, satisfying both:

- the corresponding baseline periodic payload class does not normally fire;
- the isolated response energy is finite and greater than \(10^{-14}\).

Selection may not read the packet-loss outcome, cross-term benefit, or
realized branch result. The chosen-time shift is exported.

## Paired branch construction

For each selected action, rerun the complete 30 s baseline configuration with
one extra directed DATA attempt at that time/link. The extra attempt consumes
the same pre-drawn link/time loss outcome as the baseline trace. Nothing else
about the periodic schedule, channel realization, controller, plant, or
scenario changes.

For a dropped injected action, the complete \(P,V,A\) trajectory must be
bit-identical to the baseline output. For a successful action, the
packet must be accepted after the declared delay. Every branch must add
exactly one DATA attempt and one broadcast-accounting action.

## Frozen predictors and realized return

At decision sample \(k\), retain from the baseline:

- isolated expected response energy \(E_{iso}\);
- centralized fixed-input expected total benefit \(B_{cross}\).

The paired realized benefit is

\[
B_{real}=\frac{1}{m}\sum_{r=1}^{H}
\left(\|e^{base}(k+r)\|_F^2-
\|e^{branch}(k+r)\|_F^2\right).
\]

Predictor correlations are evaluated only on successfully accepted actions,
using \(E_{iso}/p_s\) and \(B_{cross}/p_s\); division by the common success
probability affects scale but not rank/correlation. Dropped actions remain in
the dataset and are required to have exactly zero realized benefit.

## Frozen technical gates

Technical PASS requires:

1. all 200 branches complete;
2. every chosen time is within 0.18 s of its anchor;
3. every branch preserves exact trace hash, phase hash, and periodic fire log;
4. plant state is identical through the decision sample;
5. every injected action adds exactly one DATA and one broadcast action;
6. every successful action is accepted and every dropped action leaves
   \(P,V,A\) bit-identical to baseline;
7. no baseline or branch acceleration saturation occurs in the evaluation
   interval;
8. at least 50 successful actions occur in each scenario;
9. the observed overall success fraction lies in [0.65, 0.95].

## Frozen scientific gates

For each S2 and S6, using successful actions only:

- **prediction gate:** Pearson correlation between \(B_{cross}\) and
  \(B_{real}\) is at least 0.50;
- **incremental-information gate:** that correlation exceeds the correlation
  obtained from \(E_{iso}\) by at least 0.10;
- **positive-headroom gate:** at least 75% of actions in the top predicted
  quartile have positive realized benefit;
- **ranking-headroom gate:** mean realized benefit in the top predicted
  quartile is greater than in the bottom predicted quartile.

The scientific decision is:

- `BRANCH_SIGNAL_VALID` only when technical PASS and all four gates pass in
  both scenarios;
- `STOP_RICH_VOI` when technical PASS holds but any scientific gate fails;
- `INVALID_OR_OUT_OF_SCOPE` otherwise.

No threshold or candidate may be changed after execution.

## Scope boundary

Even `BRANCH_SIGNAL_VALID` is not evidence that adaptive communication beats
periodic communication. It only shows that the missing cross term has
predictive value for real one-action branches. A separately preregistered
centralized online-oracle frontier would still be required before designing
a causal distributed residual message. Gate 7, scalability, and held-out
evaluation remain closed.
