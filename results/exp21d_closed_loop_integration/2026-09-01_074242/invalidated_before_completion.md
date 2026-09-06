# Run invalidated before completion

This v1 run stopped at 18/180 rows because the oracle-warm constructor depended
on a valid native terminal D-STR assignment, which did not exist for a later
seed at the frozen horizon. No summary, gates or performance verdict was
generated. The partial rows are retained but must not be interpreted or reused.
Version 2 uses new seeds and an independent deterministic centralized
conflict-graph coloring for the oracle-warm reference.

