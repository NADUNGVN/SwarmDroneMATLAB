# Invalid R2.5 run

This run is not scientific evidence.  It stopped after registry traversal
because the diagnostic formatter passed two numeric arrays to a MATLAB
`compose` format in a form unsupported by the installed release.  Cell-level
exceptions were retained internally, leaving the numeric table empty; the
subsequent VPA selector exposed that failure.

The formatter was replaced by an explicit deterministic loop.  No graph,
action, tolerance, witness, or acceptance criterion changed.
