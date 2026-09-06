# EXP23F — Invalid background-robustness run retained

Run: `results/exp23f_local_witness_background_robustness/2026-09-03_171702`

Status: **invalid for performance conclusions**.

The full 480-row matrix completed, but only 19/20 frozen integrity gates
passed. The failed `paired_shared_realizations` gate required bit-exact
equality of `REALIZED_BACKGROUND_FRACTION` between two independently summed
event timelines. The underlying shared trace hashes, occupancy-field hashes,
transition counts and background busy time all paired correctly. The largest
observed fraction discrepancy is floating-point accumulation error on the
order of `1.7e-14`; it is not a different realization.

The gate was therefore mis-specified: physical time already uses a declared
tolerance, while the derived ratio used exact `unique`. EXP23F remains
invalid and is not reinterpreted post hoc.

The invalid output also contains an important diagnostic warning: N5 under
IID 15% occupancy has one terminal-uncertified trajectory and point-estimate
periodic epsilon-dominance. Those are not accepted findings because the run
failed integrity. They determine no parameter change. EXP23G will change
only the derived-fraction comparison to an absolute `1e-12` tolerance, keep
all conditions, arms, thresholds and policy parameters fixed, and use 30 new
seeds. If EXP23G repeats either safety or dominance failure, ELCS-W returns
to design.
