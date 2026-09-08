# R1 theory-depth validation protocol

**Frozen before R1 numerical results.**  This is a theorem diagnostic only.
No scheduler, held-out seed, performance sweep, or economics change is
authorized.

## 1. Fixed model and action family

- Gate-3 unsaturated N=5 sampled double-integrator model;
- H=25 and D=4 samples;
- structural unit command correction along x;
- full 99-dimensional augmented state for sender-wise multi-action analysis;
- strongest current information map returned by
  `tcnsInformationLimitsSenderMap(model,j,[],0)`.

For sender j, include every implemented controller-relevant outgoing ordinary
action and, for j=1, every pinned-leader action.  Stack the full exact value
coefficients into L_j without deleting action-specific memory coordinates.
Report p_j, rank of

\[
L_j^\perp=L_j(I-C_j^\dagger C_j),
\]

the ratio r_j*/p_j, its retained singular values, and the minimum coalition
including j for which every row of L_j is identifiable.  A duplicate or shared
hidden direction is retained rather than perturbed to force full rank.

## 2. Regret witnesses

Reuse exactly the two frozen reachable witnesses: ordinary 1->5 and pinned
leader 1->4.  For their compatible endpoints q-<0<q+, compute

\[
p^*=\frac{q_+}{q_++(-q_-)},\quad
R_{rand}^*=\frac{q_+(-q_-)}{q_++(-q_-)},\quad
R_{det}^*=\min\{q_+,-q_-\}.
\]

No witness scaling or link is changed.

## 3. Numerical-rank robustness

For every existing ten-link complete-history test:

1. store the singular spectrum of C and [C; ell'];
2. report the smallest retained singular value, largest discarded singular
   value, retained/discarded gap, and the singular value introduced by ell;
3. repeat row-space residual and identifiability across relative tolerance
   factors 1e-6, 1e-8, 1e-10, 1e-12, and 1e-14;
4. independently select a row basis by pivoted QR and solve the projection in
   80-digit variable-precision arithmetic;
5. compare the high-precision and double residuals.

If any nonidentifiability conclusion changes across the declared tolerance
grid, mark it marginal.  The two full trajectory witnesses remain separate
physical evidence.

## 4. Pass interpretation

`R1_THEORY_DEPTH_PASS` requires:

- exact minimax value-radius and action-regret derivations;
- valid numerical regret for both frozen witnesses;
- complete sender-wise multi-action and coalition tables;
- no ten-link rank conclusion changes over the tolerance grid;
- 80-digit residual agreement sufficient to preserve every nonzero conclusion;
- manuscript positioning that credits sample-based/structural functional
  observability, sensor placement, and observer-order prior art.

Failure is reported without altering the action family, maps, tolerances, or
witnesses.

