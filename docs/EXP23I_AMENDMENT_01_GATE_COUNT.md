# EXP23I amendment 01 — Pairing-gate consolidation

Time: 2026-09-04, after all 180 trajectories were checkpointed and before
any performance contrast or verdict was produced.

The frozen registry declares 18 validation contracts. The initial analysis
implementation emitted 19 rows because absolute realization pairing and
candidate trace/overlay pairing were represented as two separate gate rows,
although both implement the single pairing requirement stated in the frozen
plan. MATLAB therefore stopped at the gate-count assertion before computing
or displaying performance results.

The analysis code is repaired by combining those two Boolean checks into one
`paired_absolute_realizations` gate. No trajectory, seed, registry field,
threshold, metric, bootstrap rule, decision rule or simulation source is
changed. The completed 180-row checkpoint will be resumed without rerunning
trajectories. The pre-amendment source remains preserved in the run's
`frozen_source` directory, and this amendment records the only post-freeze
analysis change.

