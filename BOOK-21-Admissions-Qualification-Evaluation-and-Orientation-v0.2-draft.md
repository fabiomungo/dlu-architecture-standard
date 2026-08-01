# BOOK-21 — Admissions, Qualification Evaluation & Orientation
### DAS v0.2-draft · Layer: Intelligence / Intake · Status: DRAFT (target-state extension)
*(v0.2: SPRINT-06/NEW-18 implements the full funnel — §3-5's 10 tables, the state machine, and
R21.1-R21.3 — see Annex A for exactly what is real vs. still target. R21.4's user/twin/dossier/
invoice provisioning is real; its onboarding-journey and automatic credit_pre_evaluations
hand-offs are honest, disclosed gaps, not implemented this sprint.)*

> Closes **G17** (admission funnel with qualification pre-evaluation is absent from the
> Turnkey baseline). Companion to BOOK-14A (credit pre-evaluation): 14A recognizes *credits*
> for people already inside; this Book decides *who may enter and where they should start*.
> ER target domain: **T1** (`ER_MAP_TARGET.md`). Functionality area: **19** (target tree).

---

## 1. Purpose and scope

The AI-Native University MUST treat admission as the first act of navigation, not a
paperwork gate. The intake pipeline runs: prospect (CRM) → application → **qualification
evaluation** (entry titles: diplomas, degrees, transcripts) → eligibility verdict →
**orientation** (program recommendation + recognized-credit preview + what-if simulation)
→ offer → acceptance → matriculation event.

Out of scope: credit recognition after matriculation (BOOK-14A), identity verification
policy content (BOOK-19, G13), marketing campaign mechanics (CRM driver).

## 2. Regulatory anchors (informative)

- **Italy**: entry qualifications per ministerial classes; DM 931/2024 reshapes recognition
  of prior work experience; legacy "vecchio ordinamento" fixed equivalences (annual exam
  = 12 CFU, semester = 6 CFU); 60 CFU/year standard; ESSE3/PICA/Bestr are the incumbent
  administrative rails; Open Badges as recognizable evidence.
- **US**: PLA (Prior Learning Assessment) under ACE/NCCRS recommendations; transfer-credit
  caps (typically ≤60 credits toward a bachelor, residency requirements); TES/Transferology
  as equivalence data ecosystems; AP/IB/CLEP standardized-test credit.
- **Both**: the binding operational constraint is **curricular drift** — historic syllabi
  are the scarce resource. The `external_syllabus_records` store (BOOK-14A) is therefore
  shared infrastructure between admission and credit recognition.

## 3. Domain model (aggregates)

| Aggregate | Root | Key invariants |
|---|---|---|
| AdmissionIntake | `admission_intakes` | belongs to one program + academic year; seats ≥ accepted offers; requirements are versioned with the intake, never edited after opening |
| Application | `admission_applications` | one per applicant per intake; state machine below; all decisions carry evidence links |
| QualificationClaim | `applicant_qualifications` + `qualification_documents` | a claim is *declared* until documents verify it; verification precedes any contract of enrollment |
| QualificationEvaluation | `qualification_evaluations` | three tiers (instant AI / assisted / committee) mirroring BOOK-14A; every AI verdict carries confidence + rationale; below-threshold confidence MUST escalate tier |
| EligibilityVerdict | `eligibility_verdicts` | computed against the intake's requirement set; `conditional` verdicts enumerate unmet requirements machine-readably |
| OrientationRecommendation | `orientation_recommendations` | produced by the GPS (BOOK-14) in **zero-persistence simulation mode** (G15 rule): nothing routes into a real RouteGraph until matriculation |
| AdmissionOffer | `admission_offers` | expires; acceptance is the only transition that creates platform identities |

## 4. State machine — Application

`draft → submitted → under_evaluation → (eligible | conditional | not_eligible)`
`eligible → offer_issued → (accepted | declined | expired)`
`accepted → matriculated` (terminal; emits `ApplicantMatriculated`)

Rules:
- R21.1 ✅ **Implemented SPRINT-06/NEW-18** Every tier-escalation MUST be recorded with reason
  (low confidence, applicant contest, jurisdiction rule) — `qualification_service
  .escalate_evaluation_tier`, raises if `reason` is empty.
- R21.2 ✅ `not_eligible` MUST be explainable: the verdict lists the failed requirements and
  the evaluations that produced them (calibrated humility, BOOK-11) —
  `admission_service.decide_eligibility` requires non-empty `unmet_requirements` for
  `not_eligible`/`conditional`.
- R21.3 ✅ An AI evaluation is never final for a negative outcome: rejection requires a human
  actor of role `admissions_officer` (introduced fresh this sprint) or above (HITL floor) —
  enforced at both the route and service layer.
- R21.4 ✅/⚠ `ApplicantMatriculated` (`matriculation_service.matriculate_applicant`, "atomic-
  in-intent" — best-effort sequential, honestly documented, since the reused services it calls
  each commit independently) provisions: `users` record (built directly, passwordless,
  `pending_verification` — neither pre-existing user-creation function was a fit), `student_
  dossiers` (BOOK-23, reused), initial `student_invoices` (BOOK-23, reused, honest placeholder
  line — no fee schedule exists yet). **NOT implemented**: onboarding journey (BOOK-06
  extension — `student_onboarding_journeys` doesn't exist yet, SPRINT-11/12 territory) and
  hand-off to formal `credit_pre_evaluations` (BOOK-14A/G16) — that system's `ClaimInput`
  granularity (per-course) cannot be honestly derived from this sprint's program-level
  orientation preview without fabricating a course-id mapping; the `ApplicantMatriculated`
  event payload carries the preview data instead, for a future consumer or the student's own
  use of the already-real G16 UI.

## 5. Orientation (the recognition-aware front door)

✅/⚠ **Partially implemented SPRINT-06/NEW-18** (`orientation_service
.generate_orientation_recommendations`). Orientation MUST present, per candidate program:
recognized-credit preview (yield estimate with hedges, 14A semantics) — ✅ real, reuses
`preval_workflow_service.compute_instant_estimate` (zero-persistence, twin-less); ETA bands —
✅ a simple standalone estimate (residual CFU ÷ 60 CFU/year standard pace), NOT the full GPS
Pareto-scenario comparison this section originally envisioned (the GPS engine requires a real
`StudentTwin`, which requires a `users` row that only exists post-matriculation — a genuine
architecture tension, not a shortcut); cost projection — ⚠ an honest `null` placeholder, no
fee/tuition field exists anywhere on `Program` yet; Pareto-honest trade-offs (BOOK-14 Ch. 7) —
⚠ not implemented (would need the full GPS integration above). Transfer/professional personas
landing on recognition-first onboarding (BOOK-17) — ⚠ not implemented (no onboarding journey
table exists yet). The simulation persists nothing but the recommendation record — ✅ confirmed,
`path_scenarios` is never touched.

## 6. Events (taxonomy additions, A6-closed)

`ApplicationSubmitted`, `QualificationVerified`, `QualificationEvaluated`,
`EligibilityDecided`, `OrientationRecommended`, `OfferIssued`, `OfferAccepted`,
`ApplicantMatriculated`.

## 7. Conformance checks

- C21.1 ✅ **Verified SPRINT-06/NEW-18** No physical FK from admission tables into tenant OR
  platform schemas (isolation rule upheld, stricter than originally worded — soft refs to
  `programs`/`users` too, not just tenant schemas) — structural test over `Base.metadata`,
  `tests/conformance/test_admission_funnel_core.py`.
- C21.2 ✅ **Verified** Property test: an application cannot reach `offer_issued` without an
  `eligibility_verdicts` row with verdict ∈ {eligible, conditional}.
- C21.3 ✅ **Verified** Fixture: negative verdict without human actor → MUST fail.
- C21.4 ✅ **Verified** Drift test: qualification evaluated against a syllabus record MUST pin
  the syllabus version used — `syllabus_version_pinned` pins `external_syllabus_records
  .source_edition_year` (the real versioning column; no `.version` string column exists on
  that table, corrected from this check's original wording).
- C21.5 ✅ **Satisfied — SPRINT-17/NEW-28** (this book's own text was stale; corrected
  SPRINT-22.md "Correzioni al piano" #9). Admission evaluation agents pass the eval harness GA
  gate (BOOK-11; `eval_datasets` domain `admission_evaluation`, T11): `backend/evals/
  domain_agent_fns.py::admission_evaluation_agent_fn` calls the REAL, extracted pure decision
  core — `qualification_service._compute_tier1_verdict` — against the real golden dataset
  `scripts/eval_datasets/admission_evaluation.jsonl`, registered and gate-verified by
  `tests/conformance/test_eval_harness_preset_registry.py`.

Fixture E2E (this sprint's own DoD, verified end-to-end against a real Postgres,
`tests/conformance/test_admission_e2e_fixture.py`): lead → application → qualification →
eligible → orientation preview → offer → accept → matriculated, with a real `users`/
`student_twins`/`student_dossiers`/`student_invoices` row created at the end.

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Admission funnel ✅ (NEW-18) | `admission_intakes`/`admission_requirements`/`admission_applications`/`applicant_qualifications`/`qualification_documents`/`qualification_evaluations`/`eligibility_verdicts`/`orientation_recommendations`/`admission_offers`/`admission_acceptances` (`backend/database/models_admission.py`), `admission_service.py`, `qualification_service.py`, `orientation_service.py`, `matriculation_service.py`, `lead_conversion_service.py`; eval-harness GA gate ✅ (C21.5, SPRINT-17/NEW-28) | full GPS Pareto orientation, program fee/cost data |
| CRM leads/opportunities | `CRMLeadMapping`/`CRMOpportunityMapping` (`crm_lead_mapping`/`crm_opportunity_mapping`, Frappe-sync mapping tables — no first-class DLU lead entity), read directly by `lead_conversion_service` | `backend/api/routes/crm.py` itself stays unmounted/broken (pre-existing, disclosed, unrelated CRM-sync domain bug — out of scope) |
| Credit pre-evaluation | `credit_pre_evaluations`/`pre_evaluation_service.py` (G16/BOOK-14A) — genuinely separate from, and never bridged with, `preval_requests`/`preval_workflow_service.py` (G17/BOOK-21A) — confirmed deliberate via explicit "do NOT reuse... vice versa" comments already in the codebase | automatic hand-off from `ApplicantMatriculated`'s orientation preview (blocked on a course-id-mapping gap, see §4 R21.4) |
| Equivalence data | `equivalence_rules`, `external_syllabus_records` — real, though `external_courses`' own migrated schema has drifted from its current ORM model (pre-existing, unrelated gap, patched ad hoc in this sprint's own tests) | shared store, drift-pinned — ✅ `syllabus_version_pinned` (C21.4) |
| Identity verification | `identity_verification_policies` (G13 ✅) — confirmed NOT applicable to admissions (governs assessment-integrity method selection, not applicant KYC); out of scope per this book's own §1 | — |
| New tables | ✅ T1: all 10 tables | — |
| Sprint | ✅ **NEW-18** (this sprint) | — |
| Register | ✅ **G17** added to TRACEABILITY gap register (shared with BOOK-21A's own NEW-17a/b/c slice) | — |
