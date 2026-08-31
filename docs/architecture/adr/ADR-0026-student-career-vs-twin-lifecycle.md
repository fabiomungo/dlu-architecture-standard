# ADR-0026 — `StudentCareer.lifecycle_status` (terminal) is layered beneath `TwinLifecycleState` (non-terminal); BOOK-06 Ch. 4.1 governs the person, not the academic career

Status: Accepted (2026-08-29)
Related: ADR-0024 (canonical concept identity — the directly analogous precedent for this question: a new, additive identity/state layer introduced alongside an existing one, not a replacement)
Source: `DLU_Student_Lifecycle_Integration_Plan_v1.1.md` §2.5/§4 (D-4), `DLU_Student_Lifecycle_Sprint_Backlog_v1.1.md` §1/S0-1, `DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §3.2–3.3/§5.1 (`dlu_builder_tk/docs/`)

## Context

Two normative documents in this repository make contradictory claims about the same subject:

- **BOOK-06 Ch. 4.1** ("The eight states") states the Student Digital Twin's lifecycle — `Prospect → Applicant →
  Candidate → Enrolled → Active Student → Graduate → Alumni → Lifelong Learner` — **never closes**: *"the
  continuity from first orientation to career development is precisely the absence of terminal states."*
- **The uploaded student-lifecycle specification** (`DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §5.1)
  defines six **terminal** states for a regulated academic career (`WITHDRAWN`, `DISMISSED`, `FORFEITED`,
  `TRANSFERRED_OUT`, `GRADUATED`, `DECEASED`), requires that a terminal state **must not be overwritten**, and
  permits return only via an explicit, authorized `REOPEN_CAREER` event appended as a new transition.

These are not reconcilable by implementation choice alone — direct inspection of the real codebase
(`dlu_builder_tk`) confirms both models are already independently, partially built and live:
`TwinLifecycleState` (`backend/database/models_student_twin.py`) exactly matches BOOK-06's eight states and has
no terminal-state handling; `EnrollmentState` (`backend/domains/enrollment/models.py`) is a third, non-matching
enumeration with its own `suspended`/`withdrawn` values. Picking one document as simply "correct" and
discarding the other would either strip BOOK-06's Twin of its explicitly-designed non-terminal continuity
model, or strip the regulated academic-career model of the terminal-state discipline every downstream
regulatory projection (NSLDS, ESSE3, MUR-ANS) depends on for a correct legal record.

## Options considered

1. **Make `TwinLifecycleState` terminal.** Rejected: this directly contradicts BOOK-06 Ch. 4.1's explicit,
   deliberate design ("Alumni | dormant learner, not an exit"; regression Alumni → Active on re-enrollment is
   documented as legal). The Twin models a person's continuing relationship with the institution across
   however many academic careers they have — closing it on career end is the wrong entity to close.
2. **Make the new canonical career lifecycle non-terminal, matching BOOK-06.** Rejected: a conferred degree, a
   `rinuncia` (voluntary withdrawal), or a `decadenza` (forfeiture) is a closed legal record a regulator (Title
   IV, MUR-ANS) will ask about years later. Treating career closure as non-terminal would make the canonical
   model incapable of satisfying the specification's own acceptance criteria (§47.14: "career closure events
   preserve reason and authority") and would misrepresent what ESSE3's own `immatricolazione`/closure model
   already requires (§22.3–22.4).
3. **Two layers, additive** (Chosen): `TwinLifecycleState` is unchanged and stays exactly what BOOK-06 Ch. 4.1
   already describes — the non-terminal state of the **person's** relationship with the institution. A new,
   separate `lifecycle_status` (the specification's canonical `StudentLifecycleStatus`, §48, 27 values)
   is introduced on the new `StudentCareer` entity **beneath** the Twin, where terminal states are correct and
   required. Neither enum is redefined; each governs a different real-world object. This mirrors ADR-0024's own
   precedent exactly: a new, additive identity/state layer (`CanonicalConcept` there, `StudentCareer` here)
   introduced alongside an existing one (`KnowledgeGraphNode` there, `TwinLifecycleState` here) with no
   destructive change to what already exists.

## Decision

- **`TwinLifecycleState` continues to govern the Twin — the person's relationship with the institution over a
  lifetime.** BOOK-06 Ch. 4.1 is correct as written and is **not** amended in its state list, its non-terminal
  claim, or its regression rule (Alumni → Active). It is amended only to add the scope clarification below.
- **`StudentCareer.lifecycle_status` (new, `backend/domains/student_career/`) governs one regulated academic
  career** — a specific program relationship (BSc, certificate, MSc, etc.) — and **is** terminal for
  `WITHDRAWN`, `DISMISSED`, `FORFEITED`, `TRANSFERRED_OUT`, `GRADUATED`, `DECEASED`, exactly as the
  specification requires. A terminal career state MUST NOT be overwritten; reversal is only via an explicit,
  authorized `REOPEN_CAREER` event appended as a new transition row, never an edit to the terminal one.
- **A Student (one person, per BOOK-06 Ch. 2.2's "one person, one tenant, one twin") may have many
  `StudentCareer` rows, each independently terminal or non-terminal**, per the specification's own §3.3 example
  (BSc GRADUATED, AI Certificate ACTIVE, MSc APPLICATION_SUBMITTED, all under one Student). The Twin does not
  close when any one career does.
- **A derivation rule, not hand-maintenance, keeps `TwinLifecycleState` correct**: any career `ACTIVE` → Twin
  `Active Student`; all careers closed with at least one `GRADUATED` → Twin `Graduate`/`Alumni`; no career yet
  created → `Prospect`/`Applicant`/`Candidate` per existing BOOK-06 criteria. This rule is specified fully
  during Sprint 1 (S1-4 twin-derivation) of `DLU_Student_Lifecycle_Sprint_Backlog_v1.1.md`, not by this ADR —
  this ADR fixes the layering and terminality question only, not the derivation function's exact logic.
- **BOOK-06 Ch. 4.1 is amended** (this session, alongside this ADR) with an inline normative clarification:
  the eight states describe the Twin exclusively; the regulated academic career beneath it is a separate,
  independently-terminal entity governed by this ADR and the student-lifecycle specification, not by Ch. 4.1.

## Consequences

**Positive:** both documents remain true simultaneously because they were always describing different objects
— no downstream artefact has to choose one normative source over the other. Regulatory projections (NSLDS,
ESSE3/MUR-ANS) get the terminal-state discipline they require without touching the Twin's own, independently
correct non-terminal continuity model. `EnrollmentState`'s eventual strangling (D-5, Sprint 5) targets the
career layer specifically, leaving `TwinLifecycleState` and BOOK-06 Ch. 4.1 completely undisturbed by that
migration.

**Costs/risks:** three lifecycle-shaped enumerations now coexist during the migration —
`TwinLifecycleState` (person, permanent), `StudentCareer.lifecycle_status` (career, new, canonical),
`EnrollmentState` (career, legacy, to be strangled per D-5) — until Sprint 5 retires `EnrollmentState` as a
derived projection. A reader unfamiliar with this ADR could still reasonably ask "which one is authoritative
for X" without it; every new call site MUST cite this ADR rather than re-deriving the distinction.

**Enforcement:** `backend/domains/student_career/` is the only code path permitted to write
`StudentCareer.lifecycle_status`, exclusively through `apply_command()` (Sprint 2, S2-2) — never a direct
field assignment. `backend/database/models_student_twin.py`'s `TwinLifecycleState` keeps its existing writers
unchanged by this ADR; Sprint 1's twin-derivation function (S1-4) becomes an *additional*, read-only consumer
of career state, not a new writer path that bypasses existing Twin-transition logic.

## Related artifacts

`BOOK-06-Student-Digital-Twin-v1.0.md` Ch. 4.1 (amended alongside this ADR); `DLU_Student_Lifecycle_Integration_Plan_v1.1.md`
§2.5/§3.3/§4 (`dlu_builder_tk/docs/`); `DLU_Student_Lifecycle_Sprint_Backlog_v1.1.md` §1/§4 (S1-4)/§8 (D-5)
(`dlu_builder_tk/docs/`); `DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §3.2–3.3, §5, §5.1, §48
(`dlu_builder_tk/docs/`); `backend/database/models_student_twin.py`, `backend/domains/enrollment/models.py`,
`backend/domains/student_career/` (new, `dlu_builder_tk`).
