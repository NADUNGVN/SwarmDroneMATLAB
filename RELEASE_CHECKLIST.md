# Release checklist

State of the `simulation-v1.0` release and the `paper-v2` submission
package.

**Frozen commit: `32858b1`** — authoritative. The tag is a label; the SHA is
the anchor. Identity is machine-readable in `paper/FROZEN_BASE.json`.

---

## BLOCKED — OWNER ACTION REQUIRED

### The `simulation-v1.0` tag is not on the remote

```
git push origin simulation-v1.0
```

**Status at last check:** `git ls-remote --tags origin simulation-v1.0`
returns nothing.

**Why it is blocked here:** a push of this tag was attempted and **denied by
the environment's permission classifier**. It has not been retried, and it
must not be worked around.

**Consequence while it is missing:** a fresh clone of the paper branch
cannot resolve `simulation-v1.0`. Verification still works — `paper_guard`
falls back to the SHA, which is equally strong — but the release label is
unpublished and `paper_guard` reports `REMOTE_TAG_MISSING / OWNER_ACTION`.

**Classification:** **release-publication blocker, not a scientific or
audit failure.** No number in this package depends on it. Do **not** move,
delete or re-create the tag to clear this.

**Also unpushed:** the post-tag commit `3266030`, which records a
confirmation validation run executed *against* the tagged tree. It is
evidence about the release, deliberately **not part of it** — committing a
validation log necessarily moves `HEAD` past the commit the log describes.
The release boundary must not be moved to include it.

---

## Frozen release — `simulation-v1.0`

| Item | Status |
|---|---|
| Tag exists locally and resolves to `32858b1` | **PASS** (`TAG_OK`) |
| Tag is annotated (resolve with `rev-list -n1`, not `rev-parse`) | noted |
| Frozen commit present in the repository | **PASS** |
| Release boundary excludes `3266030` | **PASS** |
| Tag pushed to remote | **BLOCKED** — see above |
| Test suite, 9 files | **PASS** — 9/9 |
| `test_lock_regression` reproduces locked values bit-identically | **PASS** |
| 10 locked experiment tags present with recorded SHAs | **PASS** |
| Holdout dataset: 3400 rows, 50 seeds, block `25000001:25000050` | **PASS** |
| Realisation hashes re-verified in a fresh process | **PASS** — 0 mismatches over 3400 rows |
| Serial-versus-parallel determinism, bit-identical | **PASS** |
| Environment manifest written | **PASS** |
| Clean-clone reproduction | **PASS** |
| Confirmation validation at the tagged tree | **PASS** — 7/7 |

## Paper package — `paper-v2`

| Item | Status |
|---|---|
| Branched from the frozen tag | **PASS** |
| No frozen path modified (`paper_guard`) | **PASS** — 0 violations |
| Manuscript: 9 sections + root | **PASS** |
| Method section sufficient to reimplement (2 algorithms, 12 equations) | **PASS** |
| Tables I–VI generated from frozen results | **PASS** |
| Figures 1–11 generated from frozen results | **PASS** |
| Every headline number is a generated macro | **PASS** — 0 hard-coded results |
| Metric traceability (`headline_metrics.csv`, 279 rows with source files) | **PASS** |
| Claim ledger with three groups | **PASS** — 8 / 12 / 7 |
| Bibliography: 48 references, all verified | **PASS** |
| Reference audit: all `VERIFIED`, no duplicate DOIs, all cited | **PASS** |
| Novelty near-neighbour review, 15+ papers | **PASS** — no conflict found |
| Related Work rewritten from the verified matrix | **PASS** |
| Contributions tightened to three | **PASS** — C1/C2/C3 |
| Title selected from five candidates | **PASS** |
| Abstract 180–230 words with all required elements | **PASS** — 205 words |
| Oracle wording: never an accuracy bound | **PASS** |
| Acronyms expanded before first use | **PASS** — 4 corrected this pass |
| Static manuscript QA | **PASS** — 0 undefined refs, 0 duplicate labels, 0 missing artefacts, 0 placeholders |
| **Manuscript compiles** | **BLOCKED** — no TeX distribution in this environment; exact blocker in `MANUSCRIPT_QA.md` §1 |
| Publication consistency audit | **PASS** — see `paper/AUDIT_REPORT.md` |
| Venue shortlist from official current sources | **PASS** — 5 ranked |
| Submission support material | **PASS** — title/abstract options, highlights, cover letter, one-pager |
| Reviewer-attack exercise | **PASS** — 18 items, classified |
| Artifact README | **PASS** |
| `CITATION.cff` | **PASS** — software citation only |

## Not done, deliberately

| Item | Why |
|---|---|
| Venue template conversion | Deferred until a venue is chosen; converting now would have to be redone |
| Author list, affiliations, funding, ORCIDs | Withheld in this draft |
| Page-count reduction to a venue limit | Depends on the venue; the estimate is 17–19 pages and TCNS allows 12. Reduction order is planned in `MANUSCRIPT_QA.md` §3 |
| Formal inter-event-time statement | Recommended before a TCNS submission; see `REVIEWER_ATTACKS.md` A15 |
| Bibliography style `IEEEtran.bst` | `unsrt` chosen so the build needs no added dependency; switch when the venue is fixed |

## Before submitting anywhere

1. Push the frozen tag (the blocker above).
2. Install TeX and compile; record page count, overfull boxes and float
   placement in `MANUSCRIPT_QA.md` §6–§7.
3. Re-check every "not stated" row in `VENUE_SHORTLIST.md` against the
   venue's current author instructions.
4. Convert to the venue template and cut to its limit, following the
   reduction order — **Table VI and the ACK-inclusive reversal are not
   reduction candidates.**
5. Re-run `make_paper_metrics`, `make_paper_tables`, `make_paper_figures`,
   `paper_guard`, `paper_audit` after any change, and confirm
   `AUDIT_REPORT.md` still reads PASS.
6. Fill the bracketed fields in `COVER_LETTER_DRAFT.md` and keep both
   negative paragraphs.

## Re-verification commands

```bash
git rev-list -n1 simulation-v1.0          # must print 32858b1...
git ls-remote --tags origin simulation-v1.0   # currently empty: the blocker
```

```matlab
addpath('paper/scripts');
paper_guard      % frozen-source integrity + tag/remote state
paper_audit      % publication consistency, writes AUDIT_REPORT.md
```
