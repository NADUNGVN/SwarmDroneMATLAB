# R2.5 novelty stress test

## Hostile-reviewer question

> If Theorems 1--2 are functional observability and the rank results are
> linear algebra, what exactly is new?

The row-space and finite-history tests are not new, and the manuscript says
so.  The contribution is to derive the exact fixed-response marginal value of
a communication action from the sampled closed loop and then make that value,
rather than the full state, the functional whose distributed availability is
audited.  When the functional varies along sender-indistinguishable reachable
directions, the paper converts missing observability into a value interval and
a strictly positive local minimax communication-decision regret, rather than
stopping at a reconstructibility statement.  For several actions it separates
the shared algebraic hidden dimension from which coalitions own the operands
and from whether obtaining them is economically compatible with the available
Pareto headroom.  Implementation-replayed opposite-sign histories show that
the distinction is physically active for every action in the frozen N=5 case,
while the finite registry and feedback accounting delimit rather than
universalize the result.

## Where each differentiator lives

| Element | Current result carrying it | Honest novelty status |
|---|---|---|
| Communication-action value as target functional | Sec. IV derivation and Gate-3 implementation map | control/communication synthesis and problem formulation; quadratic expansion itself is elementary |
| Distributed local information structure | Sec. III-C and sender maps | application-specific, grounded in established decentralized information structures |
| Exact/sign ambiguity | Theorem 3 compatible interval; N=5 actual witnesses | decision interpretation plus implementation-faithful closure; nonobservability premise is classical |
| Minimax consequence | Theorem 3 value radius and deterministic/randomized regret | strongest analytical decision contribution; explicitly local and one-step |
| Simultaneous-action hidden dimension | Theorem 4 and sender-wise `r_j*` tables | algebraic characterization specialized to jointly deciding communication actions; not sensor count or observer order |
| Coalition ownership versus algebraic dimension | coalition corollary, exhaustive R2/R2.5 audit | co-design distinction and case-study evidence; coalition/sensor selection itself is prior art |
| Actual dynamically reachable witnesses | R2 constructor plus R2.5 persisted independent replay | implementation-faithful evidence that hidden directions survive reachability, response, and saturation constraints |

## Remaining novelty risk

The strongest honest description is a theory-guided control-communication
co-design and limits paper built from established functional-observability
geometry, not a new general observability theory.  A reviewer who requires a
new standalone systems-theory primitive may still classify it as an
application/synthesis paper.  The defense is the combined chain from exact
communication-action functional to local minimax decision loss,
simultaneous-action compression, distributed ownership/economics, and actual
reachable counterexamples.  The paper should not manufacture a new theorem
or use “first” to evade this residual risk.
