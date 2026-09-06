# Amendment 002 — terminal right-censoring

EXP14A completed 10,500/10,500 rows and passed 10/11 integrity gates. The sole
failure used the one-slot identity `attempts = success + loss`. Under the
frozen multi-slot PHY, frames started immediately before the finite horizon can
remain active and have no outcome yet.

The corrected passive identity is
`attempts = success + loss + terminal-in-flight`. No frame is relabeled and no
simulation is rerun. Original result/gate/verdict artifacts are retained with
the suffix `_pre_terminal_accounting_amendment`; exact residual counts and the
corrected verdict are recorded in
`AMENDMENT_002_TERMINAL_ACCOUNTING.json`.
