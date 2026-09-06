# Claim–source ledger

This ledger records the external evidence used in `report-source.md`. “Inference” denotes a conclusion synthesized from sources and the repository, not a direct statement by a source.

| ID | Material claim | Source/evidence | Type | Confidence |
|---|---|---|---|---|
| C01 | Study 2 fits IoT-J topics including IoT protocols/networking, constrained systems, applications, testbeds and trials | [IoT-J Guidelines for Authors](https://ieee-iotj.org/guidelines-for-authors/) and [official PDF](https://ieee-iotj.org/wp-content/uploads/2024/10/IEEE-IoTJ-Author-Guidelines.pdf) | Official venue | High |
| C02 | AoI, data semantics, sensing–communication–control co-design, scheduling and proof-of-concept experiments are recognized IoT-J themes | [Official IoT-J AoI special-issue call](https://ieee-iotj.org/wp-content/uploads/2020/03/CFP_AoI_IoTJ.pdf) | Official venue | High |
| C03 | IoT-J can accept analytical/simulation-centered AoI/control work; hardware is not a universal formal requirement | [Official 2021 issue digest](https://www.comsoc.org/system/files/2021-10/Publications_Contents_Digest_2021_Oct.pdf); [IoT-J event-triggered quantized-control article](https://doi.org/10.1109/JIOT.2025.3634081) | Official issue record / primary article | High |
| C04 | ACK-aware event-triggered control with and without acknowledgements predates Study 2 | [Dolk and Heemels, Automatica 2017](https://doi.org/10.1016/j.automatica.2017.02.029) | Primary paper | High |
| C05 | Receiver-specific acknowledgement/retransmission mechanisms for inconsistent broadcast reception in multi-agent systems predate Study 2 | [Garcia, Cao, and Casbeer, IET CTA 2016](https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/iet-cta.2016.0107) | Primary paper | High |
| C06 | Distributed event-triggered formation control can track estimates of an agent's own state at neighbors under packet loss | [Viel et al., Automatica 2022](https://doi.org/10.1016/j.automatica.2022.110215) | Primary paper | High |
| C07 | Distributed broadcast event triggering under delay/loss is established | [Wang and Lemmon, IEEE TAC 2011](https://doi.org/10.1109/TAC.2010.2057951) | Primary paper | High |
| C08 | AoI with random forward/backward delay and delayed-feedback scheduling is established | [Pan et al.](https://arxiv.org/abs/2201.02929); [Wang 2024](https://docs.lib.purdue.edu/ecetr/764/) | Primary papers | High |
| C09 | Delayed-ACK receiver-state belief under partial observability is established | [Tahir et al., IFIP Networking 2024](https://dl.ifip.org/db/conf/networking/networking2024/1570998329.pdf) | Primary paper | High |
| C10 | AoI behavior and protocol selection differ across MAC mechanisms | [Mena and Núñez, Automatica 2023](https://doi.org/10.1016/j.automatica.2022.110652); [Kadota et al., INFOCOM 2020](https://www.mit.edu/~kadota/PDFs/INFOCOM_2020.pdf) | Primary papers | High |
| C11 | Piggybacked collaboration information has been used in an AoI-optimized MAC | [Peng et al., IEEE TWC 2021](https://arxiv.org/abs/2002.10242) | Primary paper | High |
| C12 | Feedback value depends on reliability/opportunities and feedback resource cost | [Munari and Badia, IEEE TCOM 2025 repository record](https://elib.dlr.de/216423/); [GLOBECOM version](https://www.dei.unipd.it/~badia/papers/2022_12_Globecom2022151866.pdf) | Primary paper | High |
| C13 | Delayed and piggybacked ACK mechanisms are established protocol practice | [RFC 9006](https://www.rfc-editor.org/info/rfc9006/); [RFC 4340](https://www.rfc-editor.org/info/rfc4340/) | Standards | High |
| C14 | WiSwarm provides a strong AoI-aware Wi-Fi UAV-swarm systems comparator with flight evaluation | [WiSwarm, IEEE INFOCOM 2023](https://ieeexplore.ieee.org/document/10228860/) | Primary paper | High |
| C15 | Recent IoT-J swarm work combines event-triggered theory with board-based Wi-Fi experimentation | [Privacy-Preserving Average Consensus for Swarm Systems Subject to DoS Attacks](https://ieeexplore.ieee.org/abstract/document/11192496/) | Primary paper | High |
| C16 | Linux officially documents AR9271/ath9k_htc and IBSS/monitor capabilities | [Linux Wireless ath9k_htc documentation](https://wireless.docs.kernel.org/en/latest/en/users/drivers/ath9k_htc.html) | Official technical documentation | High |
| C17 | No located paper directly established the exact Study 2 chain: earlier ACK → changed sender belief → suppressed/redirected future DATA → worse receiver/control value in semantic swarm broadcast | Targeted keyword, backward-theme and adjacent-literature search through 2026-08-31 | Search inference | Medium |
| C18 | Hardware is not formally mandatory, but a measured bridge is the least-cost way to raise this particular paper over the IoT-J evidence bar | C01–C03 plus current theory/effect sizes and systems comparators C14–C15 | Synthesis/inference | Medium-high |
| C19 | A Wi-Fi application cannot validate genuine ALOHA while the underlying 802.11 MAC still performs carrier sensing | 802.11/mac80211 architecture plus repository hardware plan | Technical inference | High |
| C20 | The safest novelty is the joint causal feedback-mediation mechanism and its bounded feedback-route-by-access interaction, not any individual ACK/AoI/MAC component | C04–C13 plus repository branch-replay evidence | Synthesis/inference | Medium-high |

## Repository evidence used

- `paper/study2/study2_manuscript_draft.tex` and included section drafts
- `docs/EXP13_DEVELOPMENT_RESULTS.md`
- `docs/EXP14G_BRANCH_AT_DECISION_RESULTS.md`
- `docs/EXP14H_N20_SUPPORT_CLOSURE_RESULTS.md`
- `docs/EXP14I_MAC_SELECTIVE_VALIDATION_RESULTS.md`
- `docs/EXP15_TRACE_REPLAY_CONTRACT.md`
- `docs/STUDY2_HARDWARE_BOM.md`
- `docs/STUDY2_MATHEMATICAL_FOUNDATION.md`

