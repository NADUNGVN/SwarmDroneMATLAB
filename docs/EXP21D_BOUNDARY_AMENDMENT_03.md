# EXP21D-B Reporting Amendment 03

Date: 2026-09-01

This amendment was opened after inspecting the completed boundary-study
outcomes. It corrects the interpretation of terminal-validity fields for the
two warm-reference arms.

The warm arms replay a deterministic centralized conflict-free schedule. The
existing `DSTR_KERNEL_FINAL_*` columns describe the paired native D-STR kernel
from which the comparison condition was constructed; they do not describe the
terminal state of the warm schedule actually replayed. Using those columns in
the validity summary therefore duplicated native-kernel failures into the warm
rows.

The analysis now adds explicit `SCHEDULE_TERMINAL_*` columns. They equal the
native-kernel terminal fields for native arms and equal one for warm-reference
arms. The original `DSTR_KERNEL_FINAL_*` columns are retained unchanged as
provenance.

This is a post-outcome reporting correction only. It changes no registry,
trace, trajectory, control outcome, communication outcome, effect size,
physical-composability flag, safety result, or study verdict. No simulation is
rerun. The corrected aggregate counts are 40 unresolved schedules and 28
terminally colliding schedules, rather than the previously reported 70 and 33;
the 45 unsafe trajectories are unchanged.
