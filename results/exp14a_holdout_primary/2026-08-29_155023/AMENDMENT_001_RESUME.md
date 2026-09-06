# Amendment 001 — deterministic checkpoint resume

The original MATLAB process was externally interrupted after 160 complete
seed--scenario groups (5,600/10,500 rows). Only progress and row counts were
inspected. No performance metric was read.

The resumed runner validates the original registry hash (`201658753`), exact
35-row group boundaries, cell uniqueness, and paired trace/state hashes, then
runs only the 140 missing groups in their original order. The frozen scientific
design is unchanged. See `docs/EXP14_AMENDMENTS.md` in the project workspace.

Pre-opening runner SHA-256:
`44b717acad1a218b4200af73ad877172c4276fdaf54e63cb4af186128ce5c5d0`.
Recovery runner SHA-256:
`d5fd0016d1d5d455c2ccc35190665f8623d27c65f06ef563affe8db74dbbef57`.
