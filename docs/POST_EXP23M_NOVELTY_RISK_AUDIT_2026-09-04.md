# Post-EXP23M novelty-risk audit

Status: scoped primary-source audit; not a claim of exhaustive novelty.

## What cannot be claimed as novel

Distributed TDMA reservation and hidden-terminal avoidance are established
ideas. FPRP already uses a fully distributed two-hop localized reservation
conversation for broadcast scheduling in mobile ad hoc networks. Bhatia's
DTSS explicitly accumulates receiver responses across subsequent frames while
blocking a candidate slot. Therefore neither “distributed reservation,”
“conflict graph coloring,” nor “cumulative receipts across frames” is a safe
standalone novelty claim.

Relevant primary sources:

- C. Zhu and M. S. Corson, “A Five-Phase Reservation Protocol (FPRP) for
  Mobile Ad Hoc Networks,” 1997, https://drum.lib.umd.edu/items/70739de1-fe55-4964-ad5c-276f5d3e5d4f
- A. Bhatia, “A Distributed TDMA Slot Scheduling Algorithm for Spatially
  Correlated Contention in WSNs,” *Mobile Information Systems*, 2015,
  https://doi.org/10.1155/2015/234143
- T. Herman and S. Tixeuil, “A Distributed TDMA Slot Assignment Algorithm for
  Wireless Sensor Networks,” 2004, https://arxiv.org/abs/cs/0405042

## Closest mobility-adaptive families

Reactive mobility handling is also established. VeMAC partitions slots to
reduce mobility-induced collisions in vehicular networks. PAAS changes TSCH
schedules after detecting topology or traffic changes and enters a recovery
phase. Predictive OLSR uses position/speed information to anticipate link
quality, but at the routing layer. A recent FANET TDMA approach uses multi-agent
reinforcement learning and local observations to adapt conflict-free resources
under dynamic topology.

- H. A. Omar, W. Zhuang, and L. Li, “VeMAC: A TDMA-Based MAC Protocol for
  Reliable Broadcast in VANETs,” *IEEE TMC*, 2013,
  https://doi.org/10.1109/TMC.2012.142
- J. Jung et al., “Parameterized Slot Scheduling for Adaptive and Autonomous
  TSCH Networks,” 2018,
  https://yung-web.github.io/home/Publication/Conference/Parameterized_Slot_Scheduling_for_Adaptive_and_Autonomous_TSCH_Nets.pdf
- S. Rosati et al., “Dynamic Routing for Flying Ad Hoc Networks,” *IEEE TVT*,
  2016, https://doi.org/10.1109/TVT.2015.2414819
- “Distributed Time Division Medium Access for Flying Ad-Hoc Network: A
  Multi-Agent Deep Reinforcement Learning Approach,” *IEEE TVT*, 2026,
  https://doi.org/10.1109/TVT.2025.3643419

## Defensible remaining gap

Within this scoped audit, the most defensible gap is the following joint
combination, not any component alone:

1. receiver-confirmed AoI supplies causal state-error radii;
2. bounded motion converts those radii into a future potential-conflict
   supergraph and a certifiable lease horizon;
3. local conflict witnesses bind slot tuples and horizon expiry with
   fail-silent positive evidence;
4. the sender self-revokes before leaving its advertised tube, so safety does
   not rely on REVOKE delivery;
5. all management packets, recipients, retries and common-PHY airtime are
   charged in the closed-loop control comparison.

The literature above covers distributed coloring/reservation, response
collection, reactive topology recovery, traffic adaptivity or mobility
prediction separately. It does not, from the material inspected here, provide
this causal AoI-to-motion-tube-to-witness-lease safety chain with closed-loop
formation and exact communication accounting.

## Consequence for the research program

The contribution should not be named or sold as a new TDMA reservation
protocol. The candidate contribution is a **coherence-certified validity layer
for distributed schedules**, coupled to ACK-derived information uncertainty.
To make that gap credible, the next implementation must compare directly
against at least FPRP/DTSS-style acquisition and a modern dynamic FANET TDMA
baseline, and must show the extra certificate logic—not merely long leases—is
responsible for the safety/overhead frontier.

