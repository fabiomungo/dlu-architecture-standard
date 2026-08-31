# BOOK-22 — Faculty Lifecycle, Contracting & Human Workforce
### DAS v1.0 · Layer: Institution / Trust · Status: IMPLEMENTED (Steps 1-3 + T9 HR/workload ledger + FW6-01…FW6-10 — G18 and G18.1–G18.6 all fully closed)

> **v1.0 (2026-08-31, Pre-Test Stabilisation Checklist H2)** — version decision, not a content
> change: every step, RFC amendment, and FW6 sub-item below is marked closed, with zero ⚠ or
> disclosed open items found on review. Moved from v0.5-draft to v1.0 on that basis.

> **✅ v0.5 amendment (RFC-0001, filed 2026-08-07) — implemented 2026-08-08.** A process
> reconciliation against STU's real contracting practice (*STU Digital Faculty Onboarding,
> Contracting and Course-Creation Process v2.1*) found this Book normatively correct in
> shape but wrong in four particulars and incomplete in six others — including the
> assumption that every author is an external independent contractor, which fails for
> faculty seconded from a federated university (§11.5). G18 stayed closed for what was
> already delivered; six successor gaps **G18.1–G18.6** were opened to carry the
> remainder, and all six are now closed (TRACEABILITY.md). See
> [`architecture/rfc/RFC-0001-course-lifecycle-console-integration.md`](architecture/rfc/RFC-0001-course-lifecycle-console-integration.md)
> and [`architecture/adr/ADR-0015-gate-numbering-reconciliation.md`](architecture/adr/ADR-0015-gate-numbering-reconciliation.md)
> for the full design; §11 below records what was found, §11.7 records what shipped.

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
>
> **v0.5 (FW6-01…FW6-10, RFC-0001/ADR-0015, 2026-08-08):** every correction and omission
> §11 records is now implemented, conformance-verified, real against Postgres —
> **G18.1–G18.6 all closed** (TRACEABILITY.md). §11.7 is the sprint-by-sprint closing
> record; Annex A's mapping table and §6's conformance list are both extended below
> rather than left describing only the v0.4 state.

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
- C22.6 ✅ Property: an engagement cannot reach `executed` unless every step of its
  resolved `signing_policies` policy is satisfied in sequence order (FW6-01,
  `tests/conformance/test_signing_policy.py`).
- C22.7 ✅ Fixture: a genuinely compliant course passes the STU Course Content Standard;
  the same course missing one input fails, naming the specific failing checks (FW6-05,
  `tests/conformance/test_stu_content_standard.py`).
- C22.8 ✅ Fixture: double-reservation of one catalogue course is rejected both by the
  service layer and by a raw concurrent SQL insert (FW6-04, real unique partial index,
  `tests/conformance/test_catalog_reservation.py`).
- C22.9 ✅ Fixture: all nine mandatory consents present is a precondition of contract
  generation; a withdrawn (later `no`) consent blocks it (FW6-02,
  `tests/conformance/test_consent_registry.py`).
- C22.10 ✅ Fixture: `dean`/`provost` receive HTTP 403 — not a filtered payload — on the
  restricted fiscal/identity document endpoints (FW6-03, `tests/conformance/
  test_qualification_gate.py`).
- C22.11 Reproducibility: gate alias round-trip (ADR-0015) — not separately tested; the
  one mapping proven to reflect live data (`CourseWorkflowState` ↔ institutional gate) is
  exercised indirectly via `course_exchange_service`'s real export.
- C22.12 ✅ Fixture: a `federated_faculty` engagement cannot be drafted without an active
  `federation_agreement` covering the partner at the effective date; an expired agreement
  fails (FW6-09, `tests/conformance/test_federated_faculty.py`).
- C22.13 ✅ Property: no `faculty_documents` row of type `tax_form_*`, `personal_id` or
  `contractor_classification` may exist for a `federated_faculty` onboarding route — the
  vault stays empty by construction, asserted at the DB (FW6-09, same suite).
- C22.14 ✅ Property: an approved milestone on a zero-consideration federated engagement
  produces no `supplier_invoice` and emits `milestone.settlement_waived` exactly once on
  replay (FW6-09, same suite).
- C22.15 ✅ Property: `count_available_faculty` excludes every `FacultyProfile` whose
  `affiliation_type != 'own'` — adding a federated author leaves a program's Dtot/Ttot
  verdict unchanged (FW6-10, `tests/conformance/test_accreditation_guard.py`).
- C22.16 ✅ Fixture: the contract renderer refuses to emit a work-for-hire clause when the
  governing `ip_regime` is `home_owns_stu_licensed` (FW6-09, `test_federated_faculty.py`).
- C22.17 ✅ Property: the seven personal consents are mandatory on both the
  `independent_contractor` and `federated_faculty` routes; only items 2 and 3 may be
  satisfied by a framework reference, and the reference is recorded, never a null
  (FW6-09, same suite).

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Faculty profile/assignments | `faculty_profiles`, `faculty_assignments`, `faculty_workspace.py` | ✅ activation gated by onboarding verification (`onboarding_status`, SPRINT-08/NEW-20a) |
| QES signature | `qes_signature_ref`, `qes.py` (G3 ✅) | ✅ reused for engagement signatures — 3rd subject column `dlu_engagement_signature_id` (SPRINT-08/NEW-20a); catalog signatures still target |
| FEX packages | `course_fex.py` is an unrelated domain ("Final Course Examination", not exchange format — corrected TWICE now, SPRINT-08.md #5 and SPRINT-09.md #2, a recurring false-friend in this Book's own drafts) — the real exchange-format code is `course_exchange_service.py`, FEX v1.3 | `authoring_engagements.fex_format_version` + `engagement_deliverables.content_ref_type/_id` — both SOFT references only, never validated against that service |
| Document credentials | `issued_document_credentials` (G9/G10 ✅) | **corrected, SPRINT-08/NEW-20a**: executed contracts are NOT archived here — see §2/§6 correction notes above; archived directly on `authoring_engagements` instead |
| New tables | ✅ 9/9 real: `faculty_onboarding_journeys`, `faculty_documents`, `faculty_document_verifications`, `contract_templates`, `authoring_engagements`, `engagement_signatures` (SPRINT-08/NEW-20a); `engagement_milestones`, `engagement_deliverables`, `deliverable_reviews` (SPRINT-09/NEW-20b); ✅ `hr_positions`, `hr_contracts`, `faculty_workload_entries` (SPRINT-10/NEW-21) | T4 + T9 both 100% — nothing remains target in this Book |
| FW6 tables | — | ✅ all real: `signing_policies` (FW6-01); `consent_definitions`, `faculty_consent_records` (FW6-02); `faculty_qualification_decisions` (FW6-03); `catalog_course_reservations` (FW6-04); `engagement_scopes`, `engagement_compensation_schedules`, `deadline_events` (FW6-06); `federated_institutions`, `federation_agreements`, `assignment_orders` (FW6-09); additive columns `authoring_engagements.engagement_type`, `faculty_profiles.affiliation_type`, `faculty_onboarding_journeys.onboarding_route`, `engagement_milestones.status += 'settlement_waived'`, `engagement_signatures.signer_role += 'dean'` |
| Sprint | ✅ **SPRINT-08/NEW-20a** (onboarding + contracting, Step 1-2); ✅ **SPRINT-09/NEW-20b** (milestone/deliverable/review, Step 3); ✅ **SPRINT-10/NEW-21** (T9 HR & workload ledger) | ✅ **FW6-01…FW6-10 all implemented (RFC-0001, 2026-08-08)** — FW6-01, FW6-02, FW6-03, FW6-04, FW6-05, FW6-06, FW6-08 (driver work, no own gap), FW6-10, FW6-09, FW6-07 (Engagement Desk UI) |
| Register | ✅ **G18** added to TRACEABILITY, now marked **fully closed** (T4 + T9 both complete, SPRINT-10/NEW-21) | ✅ **G18.1–G18.6 opened (RFC-0001) then closed (2026-08-08)** — successors, never a re-opening of G18 |

---

## 11. Amendment note — v0.5 (RFC-0001, filed 2026-08-07, implemented 2026-08-08)

This section records what a reconciliation against STU's real contracting practice
found. It is written here, in the Book's own correction idiom, so that no
implementer reads §1–§10 without it. Nothing below retracts delivered work:
SPRINT-08/09/10 built what this Book specified, and it works. What follows is
where this Book *specified the wrong thing*, or specified nothing — **§11.1–§11.5
are now historical**: every correction and omission they name is implemented,
conformance-verified, and closed (§11.7).

### 11.1 Four corrections to this Book's own normative text

**(1) §2 Step 2 — signature order is wrong for the real institution.** This Book
states "the university signs first (roles `provost` and/or `cfo` per institution
policy, T6), then the instructor e-signs", and the implementation hardcodes
`ENGAGEMENT_SIGNER_ROLES = {"provost", "cfo"}`. STU's actual, documented protocol
is the reverse and has a third party: the course developer e-signs first, the
Corporate Secretariat then **verifies the file against institutional procedure**
(a governance act, not a signature), and only then does the **Chairman** — the
sole executing signatory — sign. The sanitised sample IISA in circulation is
signed by a Dean, which is a third variant again. The order is therefore not a
constant to be hardcoded but an institution-scoped, versioned **signing policy**
(RFC-0001 §4.4), following the rule-pack discipline CLAUDE.md §20 already
mandates. The `default` policy preserves today's behaviour byte-for-byte.

**(2) §2/§3 — two required roles do not exist.** `UserRole` carries no `chairman`
and no `secretariat`; `VALID_SIGNER_ROLES` is `("provost", "cfo", "instructor")`.
A governance step that is *not* a signature (the Secretariat's verification) also
has no representation — `EngagementSignature` can only be `pending|signed|declined`.
Both are additive widenings (`step_kind ∈ ('signature','verification')`), never a
drop.

The Chairman *persona* is not new to the standard: BOOK-24 §3 already lists a
"Chairman Board Pack" command surface and SPRINT-16/NEW-27 shipped it, with the
persona mapped onto admin-tier roles. That mapping is acceptable for a read-only
dashboard and unacceptable for a signature — an executed instrument must name who
signed. Two related findings, recorded here rather than lost: `AppRoutes.js:350`
attributes this limitation to "BOOK-24 Annex A's own documented v1 limitation",
and **BOOK-24 contains no such disclosure** (a live breach of the BOOK-00 sync
rule, to be corrected in the same change set as FW6-01).

**(3) §2 Step 1 — the document taxonomy is too narrow to onboard anyone.**
`VALID_FACULTY_DOCUMENT_TYPES = ("personal_id", "career_transcript",
"fiscal_data")`. The real intake requires, additionally: a CV (the primary
evidence for academic qualification), degree certificates, professional licences,
a *typed* tax form (W-9 vs W-8BEN vs W-8BEN-E — the type is what determines
whether the International Contractor Addendum of §8.3 applies), a
contractor-classification statement supporting the §1 independent-contractor
position, and work-authorisation documentation. `fiscal_data` as one
undifferentiated bucket cannot carry the treaty position. The old value is kept;
new ones are added.

**(4) §2 Step 1 — document verification is not qualification.** This Book's
Step 1 ends with "back-office verifies each document before any contract is
drawn". That is a completeness act. It is not, and cannot substitute for, the
academic judgement of whether this person is qualified to develop *this course* —
which at STU belongs to the sponsoring Dean, with Provost endorsement where
required, and which is the decision the whole engagement rests on. There is no
model for it. A `faculty_qualification_decisions` aggregate (immutable, one row
per act, with the evidence set and reasons) is required, together with a
Provost-authority transcript waiver for practitioner faculty whose qualification
rests on a terminal professional credential rather than a transcript.

### 11.2 Four things this Book does not specify at all

**(5) No usable consent, certification or acknowledgment registry.** The Course
Developer Consent, Certification and Acknowledgment Form — ten items, nine
mandatory, item 10 tri-state — has no model. A `ConsentRecord` class *does* exist,
in `backend/domains/marketing/` — an orphan domain never registered in
`api/main.py`, shaped for GDPR marketing consent (channel/status per email or
phone) and structurally unable to carry per-item contractual certifications.
Reusing it would recreate, in reverse, the incompatible-concepts problem
`administrative_holds` had to unify; the new table is therefore named
`faculty_consent_records` and both are documented as distinct in `ER_MAP.md`.
Two of the form's items are not
administrative niceties: item 6 is a **generative-AI disclosure** obligation that
BOOK-19 treats as an AI Act matter, and item 10 governs whether the developer's
CV and photograph may be published — which the sanitised IISA §15 simultaneously
asserts as a granted right. That internal contradiction is currently resolved on
paper, per developer, by whoever notices. Contract generation must read item 10
and emit §15 conditionally.

**(6) No catalogue reservation.** `authoring_engagements.course_id` is an
unconstrained soft Integer reference. Nothing prevents two Deans commissioning the
same course; nothing surfaces that a course is already spoken for. STU's own
Corporate Secretariat protocol names allocation error as the specific
embarrassment the digital process exists to eliminate. A unique partial index on
an active reservation makes it structurally impossible rather than merely
discouraged.

**(7) Exhibit A and Exhibit B are not modelled.** This Book's §2 Step 3 table
describes the two milestones' *content* in prose. The real instruments carry:
a module structure, a deliverable taxonomy at course and module level (61 discrete
items in the PHA 500 reference case, a figure that should be **computed**, never
typed), per-deliverable acceptance criteria, a ten-business-day review window, a
two-round revision cap beyond which a written amendment is required, and a
**tolling** rule under which University delay suspends the developer's deadlines.
None of this exists as data, so none of it can be enforced or even reported. The
30/70 split is additionally hardcoded as exactly two milestones; Exhibit B is the
authoritative statement of the split and may define more.

Note also that "ten business days" is unarguable only once a single institutional
business calendar is named — with a globally distributed developer pool, the
counterparty's calendar is not STU's.

**(8) The deliverable review checklist is decorative.** §2's own SPRINT-09
correction already discloses this — `deliverable_reviews.checklist` is "a
free-form JSON dict a reviewer fills in manually, not a computed check against
real course structure" — but the consequence has not been drawn: **every
milestone approved to date rests on a hand-typed assertion.** The adjacent
`course_workflow.blueprint_readiness` proves the computed form is achievable; it
simply checks a different, smaller set (MLO/media/assessment presence per module).
An **STU Course Content Standard** service must wrap and extend it with the checks
the instruments actually promise: CLO count 3–8 with Bloom variety, ≥1 MLO per
section, section count matching the Exhibit A module count, the 12–15 hour
envelope, a feedback-bearing activity at least every two hours of instruction,
assessment weights summing to 100 %, a transcript on every video component
(WCAG 2.1 AA), and a final examination with a title and ≥1 verification method
when enabled. `release_deliverable` must refuse when it fails.

### 11.3 One correction to retract

**R22.2 becomes true.** §2's SPRINT-09 correction (2) records that R22.2 is *not*
literally event-driven: `MilestoneApproved` is emitted but nothing subscribes, and
`supplier_invoices` generation is an explicit follow-up call. RFC-0001 sprint
FW6-05 registers the subscriber (idempotent on replay), at which point the
correction is retracted in the same change set rather than left standing.

### 11.4 Gate vocabulary

Four incompatible gate vocabularies are in production use (`CourseWorkflowState`,
FEX v1.3 `checkpoint_type`, `ReviewCheckpoint`'s own CHECK set, and the
institutional Gates 1/1b/2/3/4 printed in the IISA). They are mutually offset by
one, and every statement of the form "the course is at Gate 2" is currently
ambiguous. Settled by **ADR-0015**: institutional names are canonical for humans
and the ontology, no wire value is renamed, one alias module owns the mapping, and
FEX v1.4 removes the collision at the next format change.

### 11.5 One engagement type is not enough (added second pass, 2026-08-07)

**(9) Every author is assumed to be an external independent contractor paid by
STU.** §1 says "every course authored by an external or internal subject-matter
expert MUST flow through one digital pipeline" — the *pipeline* claim is right,
the *instrument* claim is not. A course developer who is already faculty at a
**federated university** (eCampus, Unilink, …) differs in three ways that no
amount of configuration on the existing tables can express:

- their academic credentials are already verified, by an institution with more
  standing to verify them than STU has;
- their work may be covered by an inter-institutional agreement, so no
  consideration flows to the individual at all;
- most importantly, **the IISA is the wrong instrument**. Its §1 asserts the
  signer is not an employee, partner or agent. Issuing it to a person who *is*
  an employee — of someone else — is a misclassification risk, and its §6
  work-for-hire assignment takes title the individual may not hold, because it
  may vest in their employer.

`authoring_engagements` therefore gains an `engagement_type`
(`independent_contractor` — the default, every existing row — `federated_faculty`,
and `internal_staff` reserved), and the federated route uses a **Framework
Agreement** (institution↔institution, signed once) plus a lightweight
**Assignment Order** per course. RFC-0001 §4.7 carries the full design,
including the `ip_regime` enumeration the renderer must obey and the three
settlement sub-cases.

Two things the simplification must not touch, stated here because they are
where this kind of feature usually goes wrong:

- **Gates 2, 3 and 4 are unchanged.** They judge the course, not the author and
  not who paid for it. The same content standard, the same review windows, the
  same revision caps.
- **Seven of the ten consents remain personal** (e-communications, accuracy,
  originality, generative-AI disclosure, accessibility, confidentiality,
  agreement to review). Only credential verification and privacy/data
  processing may be satisfied at framework level — and are *recorded* as
  satisfied by a named agreement, never simply absent. Item 10 (name, image,
  voice) stays personal in both routes: personality rights are not an
  employer's to grant.

Trust tiering follows BOOK-16's own precedent rather than inventing one: BOOK-16
Ch. 6 records that verifying externally-issued credentials "needs an external
issuer trust registry — not built", and STX-13 shipped wallet import at the
unverified tier only. The federated route accepts a human-verified institutional
attestation now (Tier 1) and upgrades to a signed verifiable credential when
that registry exists (Tier 2), with `trust_tier` present from the start so the
upgrade is a data change.

**(10) — and the reason this cannot ship alone.** `FacultyProfile` carries **no
affiliation marker**, and `ava_faculty_requirement_service.count_available_faculty`
counts every profile assigned to a `TeachingSection`, inferring tenure from
`rank` alone. Onboarding federated authors without a marker makes them count
toward STU's DM 1154 Dtot/Ttot — the same professor satisfying two universities'
faculty requirements simultaneously, which is exactly what the docente-di-
riferimento rule exists to prevent. A feature meant to *reduce* paperwork would
silently inflate an accreditation posture.

`FacultyProfile.affiliation_type ∈ ('own','federated','visiting')` (default
`own`, so nothing existing changes) and an affiliation-aware count are therefore
a **hard prerequisite**, not a follow-up: FW6-10 may ship before or with FW6-09,
never after. This is a BOOK-26 concern surfaced by a BOOK-22 feature, and is
recorded in both.

### 11.6 Disposition

| Successor gap | Covers | Sprint | Status |
|---|---|---|---|
| G18.1 | corrections (1)(2) — signing policy, chairman/secretariat roles | FW6-01 | ✅ closed 2026-08-08 |
| G18.2 | omission (5) — consent registry | FW6-02 | ✅ closed 2026-08-08 |
| G18.3 | corrections (3)(4) + omission (6) — documents, qualification gate, reservation | FW6-03, FW6-04 | ✅ closed 2026-08-08 |
| G18.4 | omissions (7)(8) + retraction (11.3) — Exhibit A/B, content standard, review clock | FW6-05, FW6-06 | ✅ closed 2026-08-08 |
| G18.5 | omission (9) — engagement types, federation registry, framework agreement | FW6-09 | ✅ closed 2026-08-08 |
| G18.6 | omission (10) — affiliation marker + DM 1154 accreditation guard (**gates G18.5**) | FW6-10 | ✅ closed 2026-08-08 (shipped before G18.5, per its own hard gate) |

The UI that surfaces all of this is **FW6 — Engagement Desk**
(`frontend/src/pages/institution/FacultyEngagementDesk.js`,
`/organization/engagement-desk`), a new faculty workspace in BOOK-17 Ch. 4. It
owns no state — see §11.7 for what it actually composes.

### 11.7 Closing record (2026-08-08) — what actually shipped

All ten RFC-0001 sprints landed, in the RFC's own dependency order, each verified
against real Postgres before the next began (`alembic upgrade → downgrade →
upgrade` clean; the full pre-existing SPRINT-08/09/10 + AVA-03 conformance suites
reproduce unchanged throughout — 444 tests passing in `tests/conformance/` at
close, up from 403 at the start of this pass). Five findings changed
implementation details from what RFC-0001's own text assumed, without changing
the design; each is disclosed in the relevant service module's docstring, not
silently worked around:

1. The pre-existing hardcoded signing roster lived in **three** places, not the
   one RFC-0001 named (`VALID_SIGNER_ROLES`, `ENGAGEMENT_SIGNER_ROLES` — a
   DIFFERENT, 2-element set — and `faculty_engagement_service.py`'s own
   `_SIGNER_SEQUENCE` constant). All three replaced by FW6-01.
2. `ap_service.generate_supplier_invoice_from_milestone` was confirmed 100% dead
   code (zero callers anywhere) rather than partially wired — FW6-05's subscriber
   is the first caller ever.
3. ADR-0015's own FEX v1.3 `checkpoint_type` mapping (`gate1_blueprint` etc.)
   never matches a real `ReviewCheckpoint.checkpoint_type` row — the exporter
   passes a different, unrelated artefact-type vocabulary straight through.
   `gate_vocabulary.py` discloses this and wires the ONE mapping proven to
   reflect live data (`CourseWorkflowState` ↔ institutional gate) into the real
   export instead.
4. FW6-09's federation registry collides with name with TWO existing, unrelated
   systems — not just the one RFC-0001 named (`models_federation.py`, a
   deployment-instance registry) but ALSO `backend/domains/federation/models.py`
   (an orphaned student-mobility/credit-transfer domain). Both documented in
   `ER_MAP.md`; neither touched or extended.
5. FW6-08's "mirror the five existing Frappe mapping tables" premise assumed
   those tables were migrated — none of them (nor `frappe_configuration`/
   `frappe_sync_jobs`) ever were, and the live `/frappe/*` routes built on them
   would fail against a real Postgres today. `FrappeSupplierMapping` is instead
   backed by its own, genuinely migrated tables, with the gap disclosed rather
   than silently inherited.

No RFC-0001 sprint required retracting or re-doing SPRINT-08/09/10 work; every
addition was additive (new tables, widened CHECK constraints, new nullable/
defaulted columns) — the version-history note at the top of this Book and
TRACEABILITY.md's G18.1–G18.6 rows are the authoritative closing record.


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Cross-cutting alignment only. See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
