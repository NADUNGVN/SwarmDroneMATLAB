# EXP23AL routed integer-accounting confirmation plan

Frozen: 2026-09-06, before execution of seeds 16094701--16094718.

EXP23AL retains the complete EXP23AK plan and all ten gates. EXP23AK run
`2026-09-06_071357` is recorded as
`ABORTED_BEFORE_REGISTERED_RANDOM_TRACE_ACCEPTANCE`: MATLAB collapsed an
`N x N x 1` random tensor to an `N x N` array and the input validator rejected
the valid singleton case. No random link draw was accepted and no scientific
outcome was produced.

The input contract now validates dimensions with `size(U,1)`, `size(U,2)` and
`size(U,3)` and has a dedicated `r=1` regression test. Delivery, routing,
reliability, scheduling and accounting equations are unchanged. To remove any
ambiguity from the aborted execution, EXP23AL uses a disjoint registered seed
block, 16094701--16094718, for the 36,000 conditional-relay traces.

The retained scientific parent remains the invalid EXP23AJ run
`2026-09-06_070738` at 15/17 gates; EXP23AL confirms its two accounting gates
without relabeling either EXP23AJ or the aborted EXP23AK run. Passing remains
primitive-only evidence and cannot promote closed-loop routing, renewal,
robustness or submission claims.
