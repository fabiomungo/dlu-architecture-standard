# BOOK-22 — Faculty Lifecycle, Contracting & Human Workforce
### DAS v0.4-draft · Layer: Institution / Trust · Status: IMPLEMENTED (Steps 1-3 + T9 HR/workload ledger — G18 fully closed)

> Closes **G18** (teacher onboarding, authoring contractualization with digital signature,
> and the HR/workload backbone are absent from the Turnkey baseline). Normativizes the
> *Course Creation Process v1.0* pipeline (STU authoring guide): onboard → contract →
> two deliverables → two invoices. Companion to BOOK-07 (Faculty Digital Twin: cognition)
> — this Book owns the *institutional* faculty lifecycle (documents, contracts, money).
> ER target domains: **T4, T9** (both now real). Functionality areas: **20, 23** (target tree).
>
> **v0.2 (SPRINT-08/NEW-20a):** Step 1 (onboard) and Step 2 (contract + ordered QES
> signing) are real, implemented, conformance-verified (`ER_MAP.md` §18; `ER_MAP_TARGET.md`
> T4 ✅ parte 1/2). Two corrections to this Book's own text found during implementation —
> see the inline note after Step 2 and Annex A below.
>
> **v0.3 (SPRINT-09/NEW-20b):** Step 3 (milestone/deliverable/review, T4 now 9/9 tables
> complete) is real, implemented, conformance-verified (`ER_MAP.md` §18; `ER_MAP_TARGET.md`
> T4 ✅ complete). Two more corrections found during implementation — see the inline notes
> after §3/§6 and Annex A below (the "FEX format" false-friend recurred and was
> re-corrected; the executed-copy archival correction from v0.2 also applies to how
> `SupplierInvoice` generation reads a milestone, not `issued_document_credentials`). T9
> (workload ledger) remains unchanged target-state, proposed a later sprint.
>
> **v0.4 (SPRINT-10/NEW-21):** T9 (HR positions/contracts + the workload ledger) is now
> real, implemented, conformance-verified (`ER_MAP.md` §18; `ER_MAP_TARGET.md` T9 ✅) —
> **G18 fully closed**. Several corrections to this Book's own §4 text found during
> implementation — see the inline note after §4 and Annex A below (schema placement,
> field naming, no real duration data on any source event, append-only mechanism, and a
> genuinely new Event Mesh consumer group rather than reusing `n8n-bridge`).

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

**Corrections, SPRINT-09/NEW-20b:**
(1) "Deliverable content" above assumes real FEX/CLO/MLO integration this sprint does NOT
build — `engagement_deliverables.content_ref_type`/`content_ref_id` are a SOFT reference
(no FK, never dereferenced) to a `course_exchange_service` FEX export or a `CourseVersion`
row; the actual CLO/MLO/exam/bibliography content lives in those OTHER domains, not
inspected here. `deliverable_reviews.checklist` is a free-form JSON dict a reviewer fills
in manually (e.g. `{"clo_count_in_range": true, ...}`), not a computed check against real
course structure. (2) R22.2 is NOT literally event-driven in this sprint's implementation:
`MilestoneApproved` IS emitted, but nothing listens to it — `supplier_invoices` generation
is an explicit follow-up call (`ap_service.generate_supplier_invoice_from_milestone`),
gated only by `milestone.status == 'approved'`. "Manual invoice creation forbidden" IS
true (that function is the sole writer), just not via an event subscriber. (3) R22.4's
design lock is enforced ONLY within this domain (`reopen_milestone`, reason required) —
no integration with `course_governance.py`'s own, separate content-editing locks. (4) The
"FEX format" wording is a recurring false-friend across this Book's own drafts:
`course_fex.py` is "Final Course Examination", an unrelated domain (SPRINT-08.md
correction #5, SPRINT-09.md correction #2) — the real exchange format lives in
`course_exchange_service.py`.

## 3. State machines

**Engagement:** `draft → pending_signatures → executed → in_delivery → completed`
(+ `terminated` from any active state, with cause).
**Milestone:** `pending → delivered → approved → invoiced → paid`.
**Signature:** `pending → signed | declined` (any `declined` returns engagement to `draft`).

## 4. HR & workload backbone (T9) — ✅ real, SPRINT-10/NEW-21

The institution maintains `hr_positions` and `hr_contracts` (FTE, term) linked to
`faculty_profiles` (a real hard FK, `hr_contracts.position_id → hr_positions.id`; the
faculty link itself is a soft reference, same cross-schema convention as the rest of this
domain). Every act of teaching, thesis committee duty, and authoring engagement posts to
`faculty_workload_entries` — sourced automatically via the real Event Mesh (a dedicated
`hr-workload` consumer group, not a handler bolted onto `n8n-bridge`): `teaching_assignment.
confirmed` (a brand-new event this sprint — no event existed before for teaching
assignments), `milestone.approved` (real since SPRINT-09/NEW-20b), and `committee.verdict.
recorded` (real since NEW-06 — one entry per `CommitteeMember`, not only president/
secretary). Tutoring (BOOK-07 FW4 / T5) is a reserved `entry_type` with no producer yet
(T5/SPRINT-13). No source event carries real duration data — every entry posts
`unit='act', quantity=1.0`; `unit='hours'` is reserved for a future tutoring source with
real start/end timestamps. This ledger:

- makes the **mentorship dividend** measurable (BOOK-07): AI-freed capacity visibly
  reallocated to human teaching/mentoring, as a count of acts per `entry_type`, not hours;
- feeds the HR Lead dashboard (BOOK-24) and capacity planning for intakes (BOOK-21);
- is append-only, enforced at the database level (not just a service-layer convention): a
  Postgres trigger rejects any UPDATE/DELETE outright. Corrections are new, opposite-sign
  rows (`is_compensating=True`, `compensates_entry_id` back-reference, `reason` required),
  never a mutation of the original.

A minimal staff-facing view (`OrganicoWorkloadDesk.js`, `/organization/organico-workload`)
covers positions, contracts, the entry ledger, and the mentorship-dividend summary.

> **Correction (SPRINT-10.md, verbatim summary):** this section's original sketch assumed
> the `platform` schema and a `hours`/`workload_type`/`period` shape with a `user_id` FK on
> `hr_contracts`. The real tables live in the default schema (column `tenant_id`, matching
> every sibling table in this domain); `hr_contracts` links to `faculty_profile_id`, not
> `user_id`; `faculty_workload_entries` uses `entry_type`/`quantity`/`unit` (generic, no
> event this sprint carries real duration) rather than `workload_type`/`hours`/`period`.
> Append-only is a real `BEFORE UPDATE OR DELETE` Postgres trigger, chosen over a DB-role
> `REVOKE` because this codebase has a single application role. Sourcing is a genuinely new
> `hr-workload` consumer group, not another handler on the pre-existing `n8n-bridge` group
> (cheaper, but semantically wrong — this program's standing "don't shoehorn into the
> wrong-named bucket" discipline).

## 5. Events (A6-closed)

`FacultyRegistered`, `FacultyDocumentVerified`, `FacultyActivated`,
`EngagementDrafted`, `EngagementSigned`, `EngagementExecuted`,
`DeliverableReleased`, `DeliverableApproved`, `MilestoneApproved`,
`EngagementCompleted`, `TeachingAssignmentConfirmed`, `WorkloadPosted`.

## 6. Conformance checks

- C22.1 ✅ Fixture: contract execution with a missing university-side signature → MUST fail
  (SPRINT-08/NEW-20a, `tests/conformance/test_faculty_engagement.py`).
- C22.2 ✅ Property: sum of `fee_share_pct` over milestones of one engagement = 100
  (SPRINT-09/NEW-20b, `tests/conformance/test_milestone_ap_budget.py` — the 2
  `engagement_milestones` rows are auto-created at engagement execution, mirroring
  `AuthoringEngagement.design_fee_pct`/`.full_course_fee_pct`, already CHECK-summed to
  100 since SPRINT-08).
- C22.3 ✅ Reproducibility: the executed contract PDF re-generates byte-identically from
  engagement data + template version (SPRINT-08/NEW-20a; NOT a document credential —
  see the §2 correction above).
- C22.4 ✅ Workload ledger is append-only: a real Postgres `BEFORE UPDATE OR DELETE`
  trigger rejects any mutation attempt, ORM-level and raw SQL alike (SPRINT-10/NEW-21,
  `tests/conformance/test_hr_workload.py`).
- C22.5 ✅ Audit: every `faculty_documents` read by staff is logged — reuses
  `platform.audit_logs` (SPRINT-08/NEW-20a), not a dedicated new table (`twin_access_audits`,
  the literal T5 precedent this line cites, doesn't exist yet either — SPRINT-13/NEW-24).

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Faculty profile/assignments | `faculty_profiles`, `faculty_assignments`, `faculty_workspace.py` | ✅ activation gated by onboarding verification (`onboarding_status`, SPRINT-08/NEW-20a) |
| QES signature | `qes_signature_ref`, `qes.py` (G3 ✅) | ✅ reused for engagement signatures — 3rd subject column `dlu_engagement_signature_id` (SPRINT-08/NEW-20a); catalog signatures still target |
| FEX packages | `course_fex.py` is an unrelated domain ("Final Course Examination", not exchange format — corrected TWICE now, SPRINT-08.md #5 and SPRINT-09.md #2, a recurring false-friend in this Book's own drafts) — the real exchange-format code is `course_exchange_service.py`, FEX v1.3 | `authoring_engagements.fex_format_version` + `engagement_deliverables.content_ref_type/_id` — both SOFT references only, never validated against that service |
| Document credentials | `issued_document_credentials` (G9/G10 ✅) | **corrected, SPRINT-08/NEW-20a**: executed contracts are NOT archived here — see §2/§6 correction notes above; archived directly on `authoring_engagements` instead |
| New tables | ✅ 9/9 real: `faculty_onboarding_journeys`, `faculty_documents`, `faculty_document_verifications`, `contract_templates`, `authoring_engagements`, `engagement_signatures` (SPRINT-08/NEW-20a); `engagement_milestones`, `engagement_deliverables`, `deliverable_reviews` (SPRINT-09/NEW-20b); ✅ `hr_positions`, `hr_contracts`, `faculty_workload_entries` (SPRINT-10/NEW-21) | T4 + T9 both 100% — nothing remains target in this Book |
| Sprint | ✅ **SPRINT-08/NEW-20a** (onboarding + contracting, Step 1-2); ✅ **SPRINT-09/NEW-20b** (milestone/deliverable/review, Step 3); ✅ **SPRINT-10/NEW-21** (T9 HR & workload ledger) | none |
| Register | ✅ **G18** added to TRACEABILITY, now marked **fully closed** (T4 + T9 both complete, SPRINT-10/NEW-21) | none |
