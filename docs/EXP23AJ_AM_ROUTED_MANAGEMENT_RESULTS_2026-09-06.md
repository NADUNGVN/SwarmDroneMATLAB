# EXP23AJ--AM routed-management primitive results

Date: 2026-09-06  
Final repair run: `results/exp23am_semantic_local_sentinel/2026-09-06_071938`  
Machine status under the registered model: `INTEGER_ACCOUNTED_ROUTING_PRIMITIVE_DIAGNOSTIC_VALID`  
Current scientific status: **SUPERSEDED BY INCOMPLETE-DETECTABILITY AUDIT**

## Decision

The registered EXP23AJ--AM gates validate their implemented model, but a
post-result independent collision audit found that the conflict lift was
incomplete. A direct one-hop decode edge makes a transmitter detectable at that
receiver even when the edge is not selected in the current multicast tree. The
old planner included only physical-interference edges and selected tree edges.
Therefore this evidence is retained but **must not be used to validate the
physical routing primitive**.

The independent oracle found collisions in 30/70 all-source plans: 1/5 at N=5,
9/10 at N=10 and 20/20 at N=20 under the spatial-reuse boundary. The complete-
interference boundary had none because it already serialized all detectable
senders. On the online N=10 fixture, both PREPARE and COMMIT plans had one
missed recipient collision. The simulator had also trusted the planner's
conflict matrix, so its earlier zero-collision result was not independent.

The repair adds the full direct-reach matrix to detectability and makes the
simulator recompute collisions directly from physical interference, direct
reach and half-duplex state. Fresh validation is required before continuing to
multi-origin scheduling.

Even after that repair passes, it will not yet validate closed-loop management
relaying. Multiple logical
origins in one closure frame have not been jointly scheduled on the common PHY,
and routed delivery outcomes have not yet driven the online closure kernel.
Repeated renewal, broad robustness, fresh-seed evidence and submission claims
remain false.

## Evidence retained

EXP23AJ `2026-09-06_070738` remains invalid at 15/17 because accumulated
floating-point airtime differed from `8*bytes/rate` by at most
`2.4980018054066022e-16 s`. Its scientific results remain useful:

- 210/210 unique all-source routes over N={5,10,20}, two interference bounds
  and link erasure {0.05,0.20,0.30};
- maximum direct-graph diameter and routed depth 4;
- zero collision, duplicate forward, future-random read or receiver-truth read;
- exact logical-packet failure below `10^-3`, with selected hop repetition
  ranging from 3 to 9;
- 60,000 Monte Carlo replay trials matched the exact multicast probability;
- logical-clique accounting undercounted physical attempts by up to 99x;
- hop-local repetition saved up to 264 reserved slots relative to repeating
  the complete end-to-end flood.

The conservative N=20/complete-interference boundary requires up to 99
physical transmissions and 0.59124 s of reserved duration for one 96-byte
all-node packet. This is not hidden: it motivates semantic multicast and the
next multi-origin scheduling study.

EXP23AK `2026-09-06_071357` is retained as an aborted run before any registered
random trace was accepted; its validator did not accept MATLAB's collapsed
`N x N x 1` representation.

EXP23AL `2026-09-06_071620` remains invalid at 9/10 solely because its
confirmation expected numeric zero rather than `NaN` for the undefined plan
hash of one initiator-local RESPONSE. It nevertheless established:

- exact reconstruction of all 210 EXP23AJ plans/certificates;
- 210/210 bit-exact no-loss route airtimes;
- 36,000 new conditional-relay traces over 18 cells, with attempt counts from
  1 to 11 and exact integer bytes/derived airtime in every trace;
- all 25 semantic routes had exact delivery and accounting.

EXP23AM `2026-09-06_071938` passed 7/7 gates. It confirmed one and only one
local-only RESPONSE, its `NaN` undefined-route sentinel, zero radio cost, exact
semantic recipient hashes for 25/25 rows, and exact plans/reliability/accounting
for all 24 nonlocal routes. This closes only the registered accounting/sentinel
chain. The subsequent detectability audit supersedes its routing-primitive
interpretation without altering or relabeling any machine verdict.

## N=10 semantic-route boundary

On the retained online closure fixture, semantic routing reduces many control
packets substantially relative to all-node flooding. The largest semantic
route still needs 30 physical transmissions and approximately 0.124899 s of
reserved duration. Multiple CLAIM/LOCK-PROOF/RESPONSE origins can occur in the
same frame, so serially composing these packet routes would be too costly.
Joint multi-origin conflict scheduling is therefore the next required design,
not an optional optimization.

## Canonical SHA-256

| Artifact | SHA-256 |
|---|---|
| EXP23AJ registry | `8B2EC8B5A372F298E13726DCC792EE86DADB0199CD30AF355263F377E59C613B` |
| EXP23AJ structural routes | `AECF767C5A8CA550D31111A7D57B639B85826C5E77C529CCA223D112E90E1F0A` |
| EXP23AJ Monte Carlo | `69274F6D130B75350931C7080598F6825E7DDD181A6B5025E96F7936B9439862` |
| EXP23AJ semantic routes | `B2FD3387F6EF936FCF82058195FAF3B823F965211B26B7D456595C8DD77413C3` |
| EXP23AJ gates | `CC8B7D30E8DF2F877845AAD96388F7BD92AC464CD3F597AB87D82A2A1FD3AA10` |
| EXP23AL registry | `6A8A9130516F1F363708329D368DD1EA5B700B71C1C4629A80E0923BC9CB946A` |
| EXP23AL conditional traces | `2E95F2321941AABD908A8899CA8F1B68735BC7032F40494C639E1A9922B369BD` |
| EXP23AL gates | `024DE5D8C7E998C5CBF5B3F193A9AC87CA0F1A34840C2892BD4FEC882CB28E73` |
| EXP23AM registry | `D7AEB0B9F7661374D2D0AF59790C015929982C31F00786BA6614B92FFAD0D339` |
| EXP23AM semantic confirmation | `271EDB0E4AD2C56C4476B95B448DA64F2760715BCD19563A8C4164C32E1578D3` |
| EXP23AM gates | `3CA43DF86F94F2AD11341EBDC2195D038D648F74C4083CFED3FF7D1CB827B330` |
| EXP23AM verdict | `6FFF53FDA8ADBE9BE1FFA64DA89633593C812E4F5808271DAA4746454B3B022C` |

## Next action

First revalidate the corrected single-packet route planner with independent
collision replay and fresh Monte Carlo traces. Only after that should a
receiver-lifted **multi-origin routed control scheduler** jointly color route
transmissions, preserve per-packet receive-before-forward precedence and
version isolation, and expose packet-specific delivery traces to the closure
kernel.
