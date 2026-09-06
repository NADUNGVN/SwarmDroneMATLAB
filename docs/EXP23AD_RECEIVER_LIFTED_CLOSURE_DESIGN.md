# EXP23AD receiver-lifted dependency-closure migration

Status: mathematical design before kernel falsification.  
Date: 2026-09-05.

## 1. Failure repaired

EXP23AC rejects the implication that a state change at node (i) changes only sender-conflict edges incident to (i). For intended-receiver matrix (A), physical detectability (D), and receiver-lifted sender graph (F), a moving node can be a receiver:

\[
A(i,a)=1,\quad D_{ib}:0\rightarrow1
\quad\Longrightarrow\quad F_{ab}:0\rightarrow1.
\]

The changed sender edge ({a,b}) need not contain (i). Therefore one-sender suppression cannot protect a general broadcast topology update.

## 2. Dependency closure

Let (F_0) be the retiring certified sender-conflict graph and (F_1) the graph induced by the proposed new causal tube set. Define

\[
F_U=F_0\cup F_1,\qquad
\Delta F=F_0\triangle F_1,
\]

and the migration closure

\[
\mathcal S=\{i\}\cup
\{v:\exists u,\{u,v\}\in\Delta F\}.
\]

Every changed conflict edge has at least one—and by construction both—endpoints in (mathcal S). Hence the subgraph induced by (V\setminus\mathcal S) is unchanged. The initiator is included even if it is only a receiver dependency and no changed sender edge is incident to it; this binds physical motion authorization to the network transition.

## 3. Joint union coloring

All nodes outside (mathcal S) retain their old self-locked slot. Nodes in (mathcal S) are colored deterministically against (F_U), in descending union-degree and node-ID tie-break order. At each step, the smallest slot not used by an already fixed or colored union neighbor is selected.

With at least (N) available scheduled slots, greedy selection always succeeds because a node has at most (N-1) colored neighbors. With fewer slots, failure is explicit and all affected nodes remain suppressed. The selector must verify the final candidate is a proper coloring of (F_U); it never trusts the construction alone.

## 4. Quiescence barrier and motion authorization

The new tube is a proposal, not immediately active physical authority.

1. Initiator (i) sends a version- and digest-bound PREPARE carrying the new tube and dependency set.
2. Every (s\in\mathcal S) suppresses scheduled DATA locally before returning QUIESCENT.
3. The initiator authorizes the new motion/tube only after positive QUIESCENT receipts from every member of (mathcal S).
4. If PREPARE or QUIESCENT is lost, the proposed motion does not begin. The old graph remains physical truth and active outside nodes remain safe.
5. Suppressed nodes retain closed-loop service through a separately protected emergency schedule.
6. After barrier closure, affected nodes obtain fresh incident-union witness receipts and may reactivate on their jointly selected slots.

This contract applies to commanded or otherwise gateable motion. Uncommanded motion that can violate the old tube before barrier closure is outside the theorem and must invoke the existing envelope-violation emergency boundary.

## 5. Safety theorem

### Theorem — Receiver-lifted closure migration safety

Assume:

1. (c_0) is a proper coloring of (F_0), and the actual graph remains a subgraph of (F_0) until the barrier closes;
2. the proposed physical motion does not begin until every node in (mathcal S) has locally suppressed scheduled DATA and the initiator has positive, version-bound QUIESCENT receipts;
3. after activation, every actual transition graph is a subgraph of (F_U);
4. nodes outside (mathcal S) retain (c_0), while the joint candidate (c_1) is a proper coloring of (F_U);
5. an affected node reactivates only on (c_1) after fresh witness receipts for all of its incident (F_U) edges;
6. a suppressed node uses only the protected emergency service, never an uncertified shared slot.

Then no scheduled same-slot conflict occurs before, during, or after the receiver-lifted topology transition, even if all best-effort REVOKE packets are lost.

### Proof sketch

Before barrier closure, physical truth is covered by (F_0), so (c_0) is safe. At closure every member of (mathcal S) is silent on scheduled slots. Every changed edge has its endpoints in (mathcal S); therefore conflicts among outside active nodes are unchanged and remain safely colored. After activation, any reactivated affected node uses its component of the proper union coloring (c_1), while any not-yet-reactivated affected node remains silent. Every active subset of a properly colored graph is proper. Protected emergency transmissions are outside the shared coloring. REVOKE delivery changes only cache cleanup, not local suppression, the positive barrier, or activation. Hence a scheduled same-slot conflict is impossible.

## 6. Cost and liveness boundary

Let (S=|\mathcal S|), (E_S) be the number of union edges incident to (mathcal S), and (W_S) their assigned witnesses. A conservative control-attempt bound has the form

\[
B_{ctrl}\le B_{prepare}+B_{quiet}
+\sum_{s\in\mathcal S}(B_{claim,s}+B_{response,s}+B_{proof,s}).
\]

Thus cost scales with the receiver-lifted dependency closure, not merely the number of physically moving nodes. Large (mathcal S), insufficient slots, missing management paths, or a PREPARE/QUIESCENT blackout must fail safe and may erase the scheduled-access advantage. These are operating-envelope results to measure, not conditions to hide.

## 7. Kernel falsification obligations

The next experiment must include:

- a physical-edge change incident to one receiver that creates a nonincident sender-conflict edge;
- exact closure equal to initiator plus all changed-edge endpoints;
- joint union coloring with at least one forced slot change;
- lost PREPARE and lost QUIESCENT, both preventing graph activation;
- partial suppression with no premature motion authorization;
- staggered witness closure and safe subset reactivation;
- permanent witness RESPONSE loss with persistent suppression;
- REVOKE loss independence;
- insufficient-slot, missing-management-path, stale-version, bad-digest, and oversized-payload failure cases;
- exact packet bytes, recipient attempts, airtime, and finite retry bounds;
- an independent actual-graph oracle, rather than a caller-supplied safety flag.

Only a valid closure kernel permits another attempt at online plant-state-tube integration.

