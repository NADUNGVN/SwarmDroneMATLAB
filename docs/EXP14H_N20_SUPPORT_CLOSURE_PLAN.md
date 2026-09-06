# EXP14H N20 causal-support closure plan

EXP14G failed its frozen minimum-support gate because only four N20 parent
seeds supplied eligible post-transient decisions. EXP14H is a separate,
development-only N20 study. It does not change, pool into, or retroactively
repair the EXP14G verdict.

The design retains exactly the EXP14G N20 estimand and interface:

- selected adaptive/scaled N20 ring2 policy;
- eligibility begins at 8 s and requires the complete local window;
- full 12 s time grid in pilot and both replay branches;
- local outcome horizon at the first outer tick at/after 0.75 s;
- identical pre-decision network and plant/controller hashes;
- admit-target versus link-specific suppress-until-piggyback intervention;
- outcome-blind fixed busy/age/entry/forced strata;
- at most one event per parent seed;
- target 20 decisions and frozen minimum 12;
- no confirmatory claim, threshold tuning or predictor fitting.

The only deliberate change is a new fixed N20-only pilot block of 240 seeds,
`16020001:16020240`. Selection salt is `14018001`. If fewer than 12 distinct
eligible parent seeds occur, the study stops before replay and records another
support failure; the eligibility window and minimum may not be relaxed.

The event selection table and its hash are written before replay outcomes. All
effects and intervals remain descriptive development evidence. A later ACK
decision rule requires a separately frozen specification and disjoint
validation seeds.
