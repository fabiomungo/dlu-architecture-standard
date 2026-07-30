# BOOK-22 — Faculty Lifecycle, Contracting & Human Workforce
### DAS v0.2-draft · Layer: Institution / Trust · Status: PARTIALLY IMPLEMENTED (Step 1-2, SPRINT-08/NEW-20a) — Step 3 + T9 remain target-state

> Closes **G18** (teacher onboarding, authoring contractualization with digital signature,
> and the HR/workload backbone are absent from the Turnkey baseline). Normativizes the
> *Course Creation Process v1.0* pipeline (STU authoring guide): onboard → contract →
> two deliverables → two invoices. Companion to BOOK-07 (Faculty Digital Twin: cognition)
> — this Book owns the *institutional* faculty lifecycle (documents, contracts, money).
> ER target domains: **T4, T9**. Functionality areas: **20, 23** (target tree).
>
> **v0.2 (SPRINT-08/NEW-20a):** Step 1 (onboard) and Step 2 (contract + ordered QES
> signing) are real, implemented, conformance-verified (`ER_MAP.md` §18; `ER_MAP_TARGET.md`
> T4 ✅ parte 1/2). Two corrections to this Book's own text found during implementation —
> see the inline note after Step 2 and Annex A below; Step 3 (milestones/deliverables) and
> T9 (workload ledger) are unchanged target-state, proposed SPRINT-09/NEW-20b.

---

## 1. Purpose and scope

Every course authored by an external or internal subject-matter expert MUST flow through
one digital pipeline with a single source of truth: one identity and document record per
teacher, one auto-generated contract, milestone-gated delivery in the exchange format
(FEX v1.3+), and payment that follows approval — not elapsed time.

Out of scope: pedagogical envelopes and agent delegation (BOOK-07/10), course content
quality gates (BOOK-15/17 FW1), payroll execution (external ERP driver).

## 2. The pipeline (normative)

**Step 1 — Onboard.** The teacher registers, then uploads three artifacts:
personal ID, career transcript (degrees, confer dates, GPA, coursework), fiscal data
(tax ID/VAT, billing address, bank details). Back-office verifies each document before
any contract is drawn (`faculty_document_verifications`). Verification activates the
`faculty_profiles` record (🔧).

**Step 2 — Contract.** The engagement contract is auto-drafted from onboarding data and
a `contract_templates` instance. It MUST identify: the course (catalog item), the exchange
format version, total fee and the milestone split (default **30% design / 70% full
course**). Signature order: the university signs first (roles `provost` and/or `cfo`
per institution policy, T6), then the instructor e-signs. All signatures are qualified
(QES/eIDAS via `qes_signature_ref`). The executed copy is archived directly on
`authoring_engagements` (`executed_pdf_storage_uri`/`content_hash`/`source_snapshot`) —
**correction, SPRINT-08/NEW-20a**: NOT `issued_document_credentials` as originally
planned here. That table's `twin_id` is a NOT-NULL FK to `student_twins` (a faculty
member has no student twin) and its `document_type` CHECK has no contract value; more
fundamentally it is for PUBLICLY VERIFIABLE credentials (BOOK-16 wallet/verify), while an
employment contract is an internal HR/legal record with no such need.

**Step 3 — Deliver.** Two deliverables, two gates, two invoices:

| Milestone | Deliverable content | Gate | On approval |
|---|---|---|---|
| `course_design` (30%) | course info, CLOs (3–8, Bloom-varied), bibliography & grading, policies & resources, sections + blueprints + MLOs (≥1/section) | design review (Dean/program office) | design locked; supplier invoice #1 authorized |
| `full_course` (70%) | all pages & components (13 types), final examination (if enabled), author info, validated FEX JSON, published on platform | technical validation + QA publish gate | supplier invoice #2 authorized |

Rules:
- R22.1 A milestone cannot be `approved` without an `engagement_deliverables` row in
  state `released` and a passing `deliverable_reviews` decision.
- R22.2 Invoice authorization is event-driven (`MilestoneApproved` → `supplier_invoices`,
  BOOK-23); manual invoice creation against an engagement is forbidden.
- R22.3 Contract terms bind the FEX version; a format upgrade requires an addendum
  (new signature round), never in-place mutation.
- R22.4 The design lock (milestone 1) makes CLO/MLO structure immutable except through a
  change-request that reopens the design gate.

## 3. State machines

**Engagement:** `draft → pending_signatures → executed → in_delivery → completed`
(+ `terminated` from any active state, with cause).
**Milestone:** `pending → delivered → approved → invoiced → paid`.
**Signature:** `pending → signed | declined` (any `declined` returns engagement to `draft`).

## 4. HR & workload backbone (T9)

The institution maintains `hr_positions` and `hr_contracts` (FTE, term) linked to
`faculty_profiles`. Every act of teaching, tutoring (BOOK-07 FW4 / T5), thesis
supervision, committee duty, and authoring engagement posts to
`faculty_workload_entries`. This ledger:

- makes the **mentorship dividend** measurable (BOOK-07): AI-freed hours visibly
  reallocated to human tutoring;
- feeds the HR Lead dashboard (BOOK-24) and capacity planning for intakes (BOOK-21);
- is append-only; corrections are compensating entries.

## 5. Events (A6-closed)

`FacultyRegistered`, `FacultyDocumentVerified`, `FacultyActivated`,
`EngagementDrafted`, `EngagementSigned`, `EngagementExecuted`,
`DeliverableReleased`, `DeliverableApproved`, `MilestoneApproved`,
`EngagementCompleted`, `WorkloadPosted`.

## 6. Conformance checks

- C22.1 ✅ Fixture: contract execution with a missing university-side signature → MUST fail
  (SPRINT-08/NEW-20a, `tests/conformance/test_faculty_engagement.py`).
- C22.2 Property: sum of `fee_share_pct` over milestones of one engagement = 100. Target —
  `engagement_milestones` (SPRINT-09/NEW-20b) doesn't exist yet; SPRINT-08 built the
  analogous one-level-up check on `authoring_engagements.design_fee_pct`/
  `full_course_fee_pct` itself (DB CHECK, sums to 100) as a declared-only placeholder.
- C22.3 ✅ Reproducibility: the executed contract PDF re-generates byte-identically from
  engagement data + template version (SPRINT-08/NEW-20a; NOT a document credential —
  see the §2 correction above).
- C22.4 Workload ledger is append-only (no UPDATE/DELETE grants). Target — T9 unbuilt.
- C22.5 ✅ Audit: every `faculty_documents` read by staff is logged — reuses
  `platform.audit_logs` (SPRINT-08/NEW-20a), not a dedicated new table (`twin_access_audits`,
  the literal T5 precedent this line cites, doesn't exist yet either — SPRINT-13/NEW-24).

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Faculty profile/assignments | `faculty_profiles`, `faculty_assignments`, `faculty_workspace.py` | ✅ activation gated by onboarding verification (`onboarding_status`, SPRINT-08/NEW-20a) |
| QES signature | `qes_signature_ref`, `qes.py` (G3 ✅) | ✅ reused for engagement signatures — 3rd subject column `dlu_engagement_signature_id` (SPRINT-08/NEW-20a); catalog signatures still target |
| FEX packages | `course_fex.py` is an unrelated domain ("Final Course Examination", not exchange format — corrected, SPRINT-08.md) — the real exchange-format code is `course_exchange_service.py`, FEX v1.3 | `authoring_engagements.fex_format_version` — a SOFT string reference only, not validated against that service this sprint |
| Document credentials | `issued_document_credentials` (G9/G10 ✅) | **corrected, SPRINT-08/NEW-20a**: executed contracts are NOT archived here — see §2/§6 correction notes above; archived directly on `authoring_engagements` instead |
| New tables | ✅ 6/9 real (SPRINT-08/NEW-20a): `faculty_onboarding_journeys`, `faculty_documents`, `faculty_document_verifications`, `contract_templates`, `authoring_engagements`, `engagement_signatures` | T4 remaining 3/9 (`engagement_milestones`, `engagement_deliverables`, `deliverable_reviews`); T9: 3 tables |
| Sprint | ✅ **SPRINT-08/NEW-20a** (onboarding + contracting, Step 1-2) | Step 3 + T9 (workload ledger), proposed **NEW-20b** |
| Register | ✅ **G18** added to TRACEABILITY, marked done for Step 1-2 | Step 3 + T9 remain open in the register |
