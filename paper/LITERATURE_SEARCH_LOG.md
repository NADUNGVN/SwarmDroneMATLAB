# Literature search and verification log

Record of how the 51 references in `paper/references.bib` were found and
verified. Kept so that the bibliography can be re-audited, and so that the
novelty verdict in `NOVELTY_GAP_REVIEW.md` can be re-tested against a
known search boundary.

**Date of pass:** August 2026.

## 0. Independent post-EXP11 novelty re-audit (2026-08-28)

This pass did not assume the previous review was correct. It re-opened the
three named near-neighbours from primary DOI/publisher or author-manuscript
sources and searched the combined concepts `AoI + event trigger + ACK or
causal feedback + receiver freshness + multi-agent or UAV + state innovation
+ in-flight suppression`.

| Work | Primary identifier | Verified overlap | Verified distinction |
|---|---|---|---|
| Mamduhi et al. (2020) | `10.3390/jsan9030043` | mixed AoI/event scheduling across multiple control loops | scheduler formulation; no sender-side cumulative-ACK memory or new-information/refresh split |
| Ceran et al. (2019) | `10.1109/TWC.2019.2899303` | ACK/NACK-driven causal AoI optimization with HARQ | single source--destination status-update link; no physical state innovation or multi-agent control loop |
| Tripathi et al. / WiSwarm (2023) | `10.1109/INFOCOM53939.2023.10228860` | AoI-aware collaborative UAV networking and real flight hardware | centralized leader/network middleware; not the distributed sender trigger studied here |
| **Tahir et al. (2024)** | `10.23919/IFIPNetworking62109.2024.10619823` | **closest newly identified neighbour:** decentralized sensor agents use delayed ACKs and a belief over receiver AoI under partial observability | optimizes AoI/channel load; no UAV formation/control state, state-innovation threshold, or new-versus-refresh in-flight-suppression semantics |
| Wang et al. (2021) | `10.1631/FITEE.2000206` | AoI-based event-triggered Kalman consensus filtering | no delayed-ACK estimate of receiver freshness or semantic traffic split |
| Lin et al. (2026) | `10.3390/pr14152502` | multi-agent consensus using state-error or AoI-bound triggering | sender-side AoI resets on broadcast; no ACK-derived receiver-freshness estimate |

Additional discovery candidates included Kesper et al. (2023), a
distributed event-triggered multi-agent RL controller with receiver-side age
timers, and Noroozi--Fidler (2024), a signal-aware/AoI hybrid update policy.
They were not cited because the three added verified references already map
the relevant claim boundary more directly.

**Verdict:** no substantial match to the complete core mechanism was found;
there is no novelty-conflict stop. The result is deliberately phrased as
“We did not identify prior work combining …”. No priority statement is
supported. Tahir et al. prevents claiming novelty for ACK-based receiver-AoI
inference or for its use by decentralized multi-agent decision makers.

---

## 1. Verification method

**Primary authority: Crossref.** Every entry was verified against the
Crossref REST API, which serves the metadata deposited by the publisher as
the DOI registration agency. For each reference the following were read
off that record and transcribed:

- exact title,
- **complete author list, given and family names**,
- year (`issued`),
- container title (journal or proceedings),
- volume, issue, pages or article number,
- work type (`journal-article`, `proceedings-article`).

Two query forms were used:

```
GET api.crossref.org/works?query.title=<exact title>&rows=2..3
GET api.crossref.org/works?filter=doi:<d1>,doi:<d2>,...&rows=N
```

The second form verifies several DOIs in one authoritative call and was
used for the confirmation sweep once candidate DOIs were known.

**What was not used as final evidence:** secondary citation aggregators,
search-engine snippets, and any generated citation string. WebSearch was
used only for *discovery* — to learn that a paper exists and what it is
called — never as the source of the metadata that went into the `.bib`.

**Publisher-page cross-check.** Every DOI resolves through
`https://doi.org/<DOI>`, recorded in `REFERENCE_AUDIT.csv`. One publisher
page (MDPI) returned HTTP 403 to automated fetching; that entry
(`mamduhi2020freshness`) was verified through Crossref, whose record
includes the abstract, and its content assessment is based on that
abstract.

## 2. Why author verification mattered

The verification sweep was not a formality. **Nine of the entries had at
least one incorrect given name** when first drafted from recall, and all
nine were corrected from the Crossref record:

| Entry | Drafted from recall | Verified correct |
|---|---|---|
| `rajaraman2021notjustage` | Goutam Reddy | **Goonwanth** Reddy |
| `yang2025aoiperspective` | Xijun Chen | **Zhengchuan** Chen |
| `tang2022whittle` | Zhiyuan Tang, Zhiyuan Sun | **Zhifeng** Tang, **Zhuo** Sun |
| `chen2020howoften` | Xin Chen, Huaicheng Yan | **Zhiyong** Chen, **Yamin** Yan |
| `yin2023eventbased` | Yuhan Yin, Junjie Gu, Jiaqi Yan | **Tingting** Yin, **Zhou** Gu, **Shen** Yan |
| `ji2023dynamic` | Yuehui Ji, Dandan Li, Wei Liao, Xiaoyan Yang | **Mingfei** Ji, **Tao** Li, **Jiawen** Liao, **Xin** Yang |
| `chen2024distributed` | Chen Chen, Yang Zhao, Zhicheng Hou, Wei Chen, Yan Zhuang | **Tianxing** Chen, **Jiasheng** Zhao, **Zhiwei** Hou, **Hongbo** Chen, **Xuebin** Zhuang |
| `yang2025fencing` | Jian Yang, Xiang Yu, Youmin Zhang, Yu Yao | **Xiuxia** Yang, **Hao** Yu, **Yi** Zhang, **Wenqiang** Yao |
| `ge2021dynamic`, `zhang2025overview` | Lei Ding | **Derui** Ding |

This is the concrete reason the rule "verify authors, do not recall them"
exists, and it is recorded rather than quietly fixed.

## 3. Known metadata artefacts, and how they were handled

| Entry | Artefact in the Crossref record | Resolution |
|---|---|---|
| `astrom2002riemann` | `issued` year is empty | Year taken from the container title, "Proceedings of the 41st IEEE Conference on Decision and Control, **2002**". Flagged in `REFERENCE_AUDIT.csv`. |
| `hespanha2007survey` | renders as "Joo P. Hespanha" | Diacritic loss in the deposited record; the correct form **João** is used |
| `zeng2019accessing` | renders as "Yongs Zeng" | Transcription artefact; **Yong** Zeng, consistent with the same author's record in `zeng2016wireless` |
| `vasarhelyi2018optimized` | renders as "Csaba Virághr" | Trailing-character artefact; **Csaba Virágh** |
| `walsh2002stability`, `tatikonda2004control`, `olfatisaber2006flocking`, `heemels2012introduction`, `astrom2002riemann` | initials only, no full given names | Full given names used where they are unambiguous and consistent with the same authors' other verified records; the initials form would also be correct |

None of these affects DOI, title, venue, year, volume, issue or pages.

## 4. Preferred-version decisions

| Reference | Versions found | Cited | Why |
|---|---|---|---|
| Sun et al., "Update or Wait" | INFOCOM 2016 `10.1109/infocom.2016.7524524`; IEEE TIT 2017 `10.1109/TIT.2017.2735804` | **journal** | Rule: prefer the peer-reviewed journal version |
| Ceran et al., "Average AoI with Hybrid ARQ" | WCNC 2018; IEEE TWC 2019 | **journal** | Same rule |
| Gatsis et al., "Optimal Power Management" | ACC 2013; IEEE TAC 2014 | **journal** | Same rule |
| Amodu et al., AoI in UAV data collection | SSRN preprint `10.2139/ssrn.4416386`; JNCA 2023 | **journal** | Preprint discarded |
| Lee et al., "Geometric tracking control" | CDC 2010; IFAC 2011 (different title) | **CDC 2010** | The IFAC item is a different paper, not a version |

**No preprint-only reference is cited.** Several arXiv items appeared
during discovery — including some with 2026 identifiers directly relevant
to AoI and event-triggered control — and were excluded because they could
not be verified as peer-reviewed. If any is later needed, the rule is to
cite it *labelled as a preprint*.

## 5. Discovery queries actually run

Search-engine discovery (results used only to identify candidates):

1. `age of information aware event-triggered control acknowledgement feedback sender estimate receiver freshness`
2. `transmitter estimates age of information at receiver using ACK feedback scheduling without oracle knowledge`
3. `age of information adaptive threshold event-triggered multi-agent consensus formation control freshness aware`
4. `2024 2025 survey age of information UAV networks freshness scheduling IEEE journal`
5. `event-triggered communication multi-UAV formation control 2023 2024 IEEE Transactions experimental quadrotor`
6. `"receiver AoI" delayed ACK partial observability multi-agent`
7. `AoI state innovation in-flight suppression event-triggered UAV`
8. exact-title/DOI searches for Mamduhi, WiSwarm, Ceran, Tahir, Wang and Lin

Queries 1–3 exist specifically to attack our own novelty claim: they are
phrased to surface a paper that already does what we do. Query 5 exists to
prevent the false claim that event-triggered UAV formation control is
unexplored — it is not, and four such papers are now cited.

Crossref exact-title verification queries: one per reference, plus four
batched multi-DOI confirmation sweeps.

## 6. Coverage against the required minimums

| Group | Required | Cited | Entries |
|---|---|---|---|
| G1 AoI / freshness in networked control | ≥ 6 | **9** | kaul2012, sun2017, yates2021, yang2025aoiperspective, kaswan2025, rajaraman2021, ayan2019, mamduhi2020, wang2021 |
| G2 event-triggered multi-agent / consensus | ≥ 6 | **16** | astrom2002, tabuada2007, heemels2012, dimarogonas2012, seyboth2013, girard2015, yi2017, nowzari2019, chen2020, ge2021, zhang2025, yin2023, ji2023, chen2024, lin2026 (+ li2026 counted in G3) |
| G3 wireless / networked control and scheduling | ≥ 6 | **8** | walsh2002, hespanha2007, gatsis2014, park2018, ceran2019, tang2022, tahir2024, li2026 |
| G4 UAV / swarm communication constraints | ≥ 6 | **8** | gupta2016, zeng2016, mozaffari2019, zeng2019, campion2019, amodu2023, tripathi2023, yang2025fencing |
| G5 communication-control co-design | ≥ 5 | **5** | tatikonda2004, nair2007, molin2013, ramesh2013, demirel2017 |
| G6 UAV / swarm dynamics, formation, flight | ≥ 4 | **6** | olfatisaber2006, lee2010, mellinger2011, oh2015, vasarhelyi2018, zhou2022 |
| **Total** | 35–55 | **51** | |

**2021–2026 window:** 18 references — yates2021, rajaraman2021, ge2021,
tang2022, zhou2022, tripathi2023, amodu2023, yin2023, ji2023, chen2024,
yang2025aoiperspective, kaswan2025, zhang2025, yang2025fencing, li2026,
wang2021freshness, tahir2024collaborative, lin2026cooperative.

Group totals sum above 51 because several entries are legitimately relevant to
two groups; each is assigned one **primary** group in
`REFERENCE_AUDIT.csv`, and the minimums above are met on primary
assignment alone.

## 7. What is deliberately absent

- **No bibliography padding.** Every entry is attached in
  `REFERENCE_AUDIT.csv` to a specific manuscript claim. An entry with no
  claim would be a citation for decoration.
- **No self-citation** from this campaign.
- **No citation of a source for a claim it does not support.** In
  particular, the UAV-communication surveys are cited for *constraints*
  and never for anything about triggering policy, and the event-triggered
  surveys are cited for the *state of the field*, never for AoI.
- **No priority claim**, because a search of this shape cannot support one.
