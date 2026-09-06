# Run invalidated: collision-graph mismatch

The complete v2 matrix failed its collision-witness gate because leader-pin
receiver links were added by the closed-loop simulator after the D-STR kernel
graph had been constructed. Kernel and event engine therefore used different
graphs. The 180 rows, failed verdict and all negative outcomes are retained,
but no performance result from this run may be interpreted or rescored. V3
uses new seeds and one exact pin-augmented graph in both components.

