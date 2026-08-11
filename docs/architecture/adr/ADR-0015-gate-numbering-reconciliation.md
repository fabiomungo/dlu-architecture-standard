# ADR-0015 — Gate numbering reconciliation and the institutional gate vocabulary

Status: **Proposed** (RFC-0001, 2026-08-07)
Owner Books: **22** (Faculty Lifecycle), **17** (Experiences), **05** (Ontology)
Related: RFC-0001 §4.5 (delta D9) · ADR-0014 (the same "additive alias, never rename" technique)

## Context

Four different vocabularies are in production use for what people call "the
gates", and they do not line up. Nothing is broken today only because the two
main pipelines rarely meet in one screen; RFC-0001's FW6 puts them side by
side, which forces the reconciliation.

**(1) `CourseWorkflowState`** — the real content-production state machine
(`backend/database/models.py`, `backend/services/course_workflow.py`), STU
slide-15 model:

```
catalog_approved → in_authoring → blueprint_validation  [GATE 1 Dean/Provost]
                 → generating   → faculty_review        [GATE 2 Faculty]
                 → under_dean_review                    [GATE 3 Dean/Provost]
                 → approved → published
```

**(2) FEX v1.3 `checkpoint_type`** — the exchange-format wire values, as
emitted in `course_exchange_v1.3_example.json` and consumed by
`course_exchange_service._build_quality_log`:

```
gate1_blueprint · gate2_content · gate3_publication
(workflow_state: gate1_passed · gate2_passed · gate3_passed)
```

**(3) `ReviewCheckpoint.checkpoint_type` CHECK** — a *fourth* closed set that
predates both and matches neither (`models.py:1179`):

```
syllabus · lesson_content · qa_report · final_preview
```

**(4) STU process v2.0 institutional gates** — the vocabulary the Provost,
the Deans, HR, the Corporate Secretariat and the CFO actually use, and the one
printed in the IISA and its exhibits:

```
Gate 1  Qualification              (Dean; Provost where required)
Gate 1b Contract execution         (Chairman)
Gate 2  Design approval            → authorises invoice 1
Gate 3  Final academic acceptance  → authorises invoice 2
Gate 4  Technical validation       (publication)
```

The collisions are not cosmetic. In (1) *Gate 2* is a **faculty** review of AI
output; in (4) *Gate 2* is a **Dean** approval of the design. In (2)
`gate2_passed` corresponds to institutional **Gate 3**. A reader who sees
`gate2_passed` in an exported file and reports "the course is at Gate 2" is
wrong by one, and the error is invisible — both statements parse.

## Decision

**1. The institutional vocabulary (4) is canonical for humans and for the
ontology.** `dlu-core.yaml` gains a `Gate` concept whose instances are the
five institutional gates, each carrying `authority`, `decides`,
`financial_effect`. Every user-facing surface (FW1, FW6, exported PDFs,
notifications, dashboards) names gates this way and only this way.

**2. No existing wire value is renamed.** `CourseWorkflowState`,
`checkpoint_type` and `ReviewCheckpoint`'s CHECK set are all persisted data
with running consumers. Renaming is a destructive migration and BOOK-18 Ch. 1
rule 3 forbids it. They remain exactly as they are.

**3. One alias table, one home.** A single **new** module —
`backend/services/gate_vocabulary.py` (does not exist today; created by the
first implementing sprint) — owns the mapping in both directions.
No other module may hardcode a cross-vocabulary correspondence; this is
grep-enforced in review, the same discipline ADR-0014 applied to
`identity_map.py`.

```
institutional  │ CourseWorkflowState    │ FEX checkpoint_type │ FEX workflow_state
───────────────┼────────────────────────┼─────────────────────┼───────────────────
Gate 1         │ —                      │ —                   │ —
Gate 1b        │ —                      │ —                   │ —
Gate 2         │ blueprint_validation   │ gate1_blueprint     │ gate1_passed
Gate 3         │ under_dean_review      │ gate2_content       │ gate2_passed
Gate 4         │ published              │ gate3_publication   │ gate3_passed
```

Gates 1 and 1b have no course-side representation by design: they happen
before a course exists in the authoring pipeline. They live in
`faculty_qualification_decisions` and `authoring_engagements` respectively.

`CourseWorkflowState.faculty_review` — vocabulary (1)'s own "Gate 2" — maps to
**no institutional gate**. It is an *internal* faculty check of AI-generated
output, not an institutional approval act. Naming it a gate was the original
error; it keeps its value, loses the label, and is documented as an
intra-phase checkpoint.

**4. Exported files self-describe.** Every `review_checkpoint` written by
`course_exchange_service` carries an additional `stu_gate` field with the
institutional label. This is additive to FEX v1.3 (unknown fields are
tolerated on import) and makes an exported file unambiguous to a human reader
without needing the alias table.

**5. FEX v1.4 renames the checkpoint types** to `design_approval`,
`academic_acceptance`, `technical_publication`, removing the ordinal collision
permanently. v1.3 remains readable forever
(`import_course` already accepts 1.0–1.3); the alias table gains a v1.3→v1.4
row rather than a migration. Contract terms bind the FEX version (R22.3), so
an engagement signed against 1.3 stays on 1.3 unless an addendum is signed.

**6. `ReviewCheckpoint`'s CHECK set is left alone and deprecated in place.**
Its four values describe artefact types, not gates, and it has its own
consumers. It is out of scope for the gate vocabulary; the RFC's conformance
check C22.11 asserts only that gate-bearing checkpoints round-trip.

## Consequences

**Positive.** One name per gate in every human-facing surface. The off-by-one
becomes structurally impossible to state, because no UI ever renders a raw
`checkpoint_type`. The mapping is testable in one place (C22.11).

**Negative.** A developer reading the database directly still sees three
vocabularies and must consult `gate_vocabulary.py`. This is the accepted cost
of the no-rename rule; the alternative — a destructive rename across live
tables and exported files in the field — is worse.

**Neutral.** FEX v1.4 is now on the roadmap for a reason unrelated to course
content. It should be batched with the next substantive format change rather
than shipped for this alone.

## Alternatives considered

**Rename the wire values to match the institutional gates.** Rejected:
destructive migration of persisted state plus every exchange file already
issued to an author or another institution. Violates BOOK-18 Ch. 1 rule 3.

**Adopt the FEX numbering as canonical and renumber the institutional
process.** Rejected: the institutional numbers appear in the signed IISA and
its exhibits, and in the Provost/Dean approval record. The system does not get
to renumber a contract.

**Leave it and rely on documentation.** Rejected: it is already documented in
three places, and the collision survived all three. The Console prototype
reproduced the off-by-one faithfully from the sample file, which is the
evidence that documentation alone does not close this.

## Verification

- **C22.11** Round-trip: export a course past Gate 3, re-import it, and assert
  the institutional labels resolve identically both ways.
- Grep gate: no module other than `gate_vocabulary.py` may contain both an
  institutional gate label and a raw `checkpoint_type`/`CourseWorkflowState`
  value.
- Every FW1/FW6 gate-status string resolves through `gate_vocabulary` — asserted
  by a UI test, not by convention.
