# Cover letter — draft (venue-neutral)

Deliberately venue-neutral. Bracketed fields are filled once a venue is
chosen from `paper/VENUE_SHORTLIST.md`; nothing else should need editing.

---

Dear [Editor-in-Chief / Associate Editor],

We submit for consideration the manuscript **"Causal ACK-Assisted,
AoI-Aware Event-Triggered Communication for UAV Swarm Coordination"** for
publication in **[VENUE]**.

**Main contribution.** Communication in a UAV formation is usually either
fixed-rate, which cannot adapt to a network whose quality is unknown, or
triggered on local state error, which is blind to how stale the receiver's
copy has become. We present a communication policy in which each sender
estimates its receiver's information freshness *only* from cumulative
acknowledgements traversing a delayed and lossy reverse channel — never by
reading receiver state — and uses that estimate to scale a state-innovation
threshold. The element the design turns on is a semantic separation: a
repetition cooldown governs repetition alone, and not traffic that carries
genuinely new information. A controlled ablation shows why the two
alternatives fail in opposite directions, and that resolving the conflict
required no change to any threshold value.

**Evidence.** The evaluation is a pre-registered simulation campaign:
acceptance gates, operating points, statistical procedure and seed policy
were committed in writing before each experiment ran. It concludes with a
holdout validation over **50 seeds never used during development**, 3400
runs, with 6-DOF quadrotor followers, common random numbers so that
comparisons are properly paired, and 95 % confidence intervals on every
headline claim. On the nominal point the policy adapts its DATA traffic
monotonically with network quality with one fixed parameterization, and
attains lower formation error than a conventional state-event trigger in
all 17 cells of the final matrix.

**What we do not claim, stated up front.** We think this is the more useful
part of the submission. The traffic reduction is DATA-only: against a 20 Hz
periodic baseline, DATA falls by 16.73 Hz while the ACK-inclusive total
*rises* by 10.67 Hz, both intervals excluding zero. We therefore claim no
reduction in total radio traffic, and no Pareto superiority under
ACK-inclusive cost in the most impaired condition — a pre-registered claim
to that effect was tested earlier in the campaign and **rejected**. Seven
pre-registered claims were rejected in total, and all seven are reported in
a dedicated table rather than omitted, including three whose cause we
attribute to the controller rather than to our contribution.

**No hardware validation.** This is a simulation study. No timing, airtime
or energy quantity has been measured on a radio or a processor; the airtime
and broadcast cost models are stated proxies. We position the work against
published results that have reached hardware rather than beside them, and a
staged hardware programme is specified, beginning with bench-measurable
quantities before any flight.

**Artifact availability.** The complete campaign is frozen at a tagged
commit. One command re-runs the test suite, re-verifies every random
realisation against a registry fixed in advance, checks bit-identity
between serial and parallel execution, rebuilds every table and figure in
the manuscript from persisted result files, and writes an environment
manifest. A separate check clones the repository and reproduces the test
suite, the aggregate tables and one re-simulated seed bit-identically.
Every number in the manuscript is a generated macro traceable to a named
result directory; none is typed into the prose.

We confirm that this manuscript is original, is not under consideration
elsewhere, and that all authors have approved the submission. We declare no
conflicts of interest. [Add funding and data-availability statements as the
venue requires.]

Thank you for considering our submission.

Sincerely,
[Authors]
[Affiliation]
[Contact]

---

## Notes for adapting this letter

**Do not remove the two negative paragraphs.** They are the reason a
reviewer can trust the positive ones, and they pre-empt the two strongest
objections (`REVIEWER_ATTACKS.md` R2 and R1) before review starts.

**Per-venue emphasis** — see `VENUE_SHORTLIST.md`:

- **TCNS**: lead on communication constraints and the paired statistics;
  acknowledge directly that the paper offers no stability theorem, since
  that is the likely rejection ground there.
- **TCST**: lead on implementation realism — the 6-DOF plant, the runtime
  protocol invariants, the reproduction machinery — and cite the venue's
  own scope language about simulation.
- **TAES**: lead on the system view — airtime, neighbour-count scaling, the
  N = 50 anchor — and be first to say that airtime is a proxy.
- **RA-L**: the letter must be much shorter, and the length limit makes the
  negative results harder to keep visible; say explicitly where they live.
- **IEEE Access**: as drafted.
