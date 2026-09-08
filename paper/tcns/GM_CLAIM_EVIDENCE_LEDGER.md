# GM claim-to-evidence ledger

| Claim | Theorem / experiment | Assumptions | Figure / table | Limitation |
|---|---|---|---|---|
| Fixed-response quadratic action benefit is affine in current state | algebraic expansion, GM Theorem 1 setup | linear finite-horizon output; fixed action response; Q PSD | Sec. IV | not true without conditioning/augmentation if response depends on hidden state |
| Exact value is locally identifiable iff its coefficient lies in the information row space | Theorem 1 | affine observation; locally rich fiber | Fig. 5, Sec. V-A | classical functional-observability specialization |
| Finite local history identifies the propagated value iff its coefficient lies in the finite-history row space | Theorem 2 | fixed affine dynamics/measurement during history | Sec. V-B | new packets/measurements change the map |
| The value-information radius is the exact minimax sender-local point-estimation error | Theorem 3, interval midpoint proof | finite compatible value interval at a fixed information state | Fig. 5, Sec. V-C | local set-membership result, not a stochastic Bayes-risk bound |
| A compatible interval straddling zero imposes strictly positive randomized and deterministic binary-action regret | Theorem 3, endpoint equalization | transmit iff exact benefit is positive; declared compatible set | Fig. 5, Table III | local one-decision minimax result, not universal stochastic-control regret |
| Minimum additional linear-statistic dimension for multiple values is rank(L_perp) | Theorem 4 | linear scalar side information | Sec. VI-A | dimension is not protocol/packet cost |
| A coalition identifies a value set iff its stacked row space contains every value coefficient | Coalition corollary | declared agent maps | Table IV | sensor selection/coalition search is established prior art |
| Gate-3 formation action values exactly fit the generic affine form | IL affine validation | N=5, H=25, delay=4, unsaturated DI scope | Sec. VIII-A | not a nonlinear 6-DOF theorem |
| All ten evaluated N=5 payload values are not sender-history identifiable, robustly to numerical rank choices | IL/R1 row-space application, tolerance sweep, 80-digit projection | strongest implemented sender map; held-memory positive-probability history | Table II | frozen graph/controller; high precision starts from implementation-generated matrices |
| Two reachable sender-indistinguishable histories have opposite exact signs and positive unavoidable regret | IL dynamic validation plus R1 regret evaluation | preregistered links; unsaturated; erasure history | Fig. 6, Table III | ordinary 1->5 and pin 1->4, not all ten |
| Four leader actions require only three joint missing statistics, whereas other multi-action senders show no compression | R1 sender-wise rank of $L_j(I-C_j^\dagger C_j)$ | common 99-state map; structural unit action response | Table IV | N=5 configuration; leader compression partly reflects two payloads with the same receiver/response direction |
| A safety-bound trigger can be Pareto dominated | Gate-5 development frontier | frozen cost, scenario, 5 paired development seeds | Fig. 2 | counterexample/motivation; no population claim |
| Exact centralized current information creates headroom in S2 but not S4 | O1 development frontier | privileged online oracle, no future information | Fig. 3 | diagnostic, not implementable or held-out |
| Acquiring value information can erase headroom | AB0/FB0 accounting | DATA+0.25 ACK metric and frozen feedback semantics | Fig. 4, Table V | not an energy/airtime theorem |
| Every sender-wise missing action-value subspace requires the five-agent coalition | exhaustive R1 enumeration | actual observation maps and topology | Table IV | do not generalize to all swarms; ownership is not a protocol |
