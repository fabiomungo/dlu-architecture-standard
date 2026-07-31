# Changelog

## Unreleased

- **SPRINT-12/NEW-23 — badge automation, knowledge-map before/after
  snapshots, study missions & engagement nudging (BOOK-16/17 agg., T3 +
  T2 8/8 tables now complete)** (2026-07-31, `dlu_builder_tk`): wires up
  an entire STX-13 credential/badge pipeline that had been fully built
  but never connected to anything — `credential_criteria_service.
  evaluate_templates_for_event` had exactly one caller anywhere in the
  codebase (a demo seed script) and `badge_credit_rule_service.
  apply_badge_credit_rules` had zero. A genuinely new Event Mesh consumer
  group `course-completion` (STX-03, 4 touch points) chains 3 real
  handlers: `mastery.updated` → captures a `pre_course` knowledge-map
  snapshot (first occurrence per twin+course); `assessment_session.
  published` → emits a brand-new, per-student `course.achieved` event for
  every published, non-refused PASS (queried off `AssessmentSession
  Enrollment`); `course.achieved` → drives BOTH automatic badge issuance
  (`achievement_badge_issuances`, idempotent, `attempts` capped at 5,
  retried by a Celery beat sweep) and a `post_course` snapshot. Async
  criteria-evaluation/issuance calls are bridged from the sync consumer
  handler via `asyncio.run()` — the same technique `esse3_credential_
  consumers.py` already used for its own async HTTP call, now extended to
  an async DB-touching service. Two false-friend names avoided by
  building under clearly different names instead of overloading them:
  `user_badges` (unrelated community/gamification badges) and
  `course_achievements` (a separate, pre-existing manual-claim pipeline)
  are untouched. `study_missions`/`mission_activities` close out T2 (now
  8/8 tables): daily missions generated from 3 sources — `coach` (top
  scored `Recommendation`, concept-level, so `mission_activities.
  lesson_id` is nullable by design), `gps` (first `PathStep` of the
  adopted scenario), `self` (student-created) — completed self-service
  via a new `/api/missions` surface; the student-facing widget is
  deliberately named `StudyMissionsFeed.js`, distinct from the existing
  `MissionsFeed.js` (the workspace triad's own ACE HITL queue — "Missions"
  already meant something else). Engagement nudging
  (`nudge_service.py`) reuses real machinery end to end, no new
  mechanism: a disengaged twin gets a proactive `learning_coach` mission
  (`AcademicCognitiveEngine.run_mission`, same etiquette-gated pattern
  SPRINT-11 established) plus a real delivered `Notification`; a
  severely, long-silent twin instead emits `RISK_DETECTED`, reusing the
  real crisis-escalation pathway (`student_success_consumers.py` →
  `flag_risk` HITL) rather than building a second one; the opt-out gate
  reuses the same `behaviour_analytics` consent flag
  `behaviour_recompute_service.py` already checks; the cooldown is
  checked against real, already-sent `Notification` rows, no new "nudge
  log" table. **Found and fixed a real design bug in this sprint's own
  new code**, caught by its own adversarial test fixtures rather than
  reported by the user: the first cut of the nudge-severity check treated
  "no mission ever completed" as automatically crisis-level, wrongly
  escalating a twin disengaged for only 1-3 days, and gated severity
  behind the same 7-day recent-window count used for ordinary nudges, so
  a genuinely severe 23-25-day-old disengagement never even reached the
  severity check; corrected with a new, deliberately UN-windowed
  `_silence_days` helper checked first and independently of the recent
  window, with crisis escalation never suppressed by the nudge cooldown.
  Branched from SPRINT-11's own branch (real same-file/migration-chain
  dependency on `models_student_journey.py`), not fresh off `origin/main`.
  17 new conformance tests (badge automation incl. redelivery idempotency
  and no-matching-template skip; snapshot capture idempotency and honest
  unresolved-identity skip; all 3 course-completion consumer handlers;
  mission generation across all 3 sources incl. daily-idempotency and
  self-mission duplicate rejection; nudging incl. opt-out, cooldown, and
  crisis escalation). Full regression sweep clean on a genuinely fresh
  container (Phase1: 104 passed, 4 skipped; event mesh unit suite: 18/18;
  conformance: 202 passed, the same 3 pre-existing, unrelated
  `cds_grids`-seed/test-fixture collision documented in SPRINT-09/10/11's
  own entries). *(Milestone M2 will be annotated here together with
  SPRINT-13's own entry, per this sprint's own Doc-sync note.)*

- **SPRINT-11/NEW-22 — student onboarding, diagnostic assessment, key
  objective (BOOK-06 agg., T2 6/8 tables)** (2026-07-31, `dlu_builder_tk`):
  the day-0 onboarding journey that `matriculation_service.py`'s own
  docstring had flagged as a disclosed gap since SPRINT-06 ("no
  onboarding-journey row... SPRINT-11/12 territory"). `student_
  onboarding_journeys`/`onboarding_steps` walk profile → consents →
  diagnostic → goal, resumable at any point via `current_step`; created
  by a genuinely new `student-onboarding` Event Mesh consumer group
  reacting to `applicant.matriculated` (real since SPRINT-06/NEW-18, but
  had zero consumers until now). The "consents" step reuses the REAL
  `TwinContextService.set_consent` (already audited + emits `consent.
  changed`) rather than building a second consent mechanism.
  `diagnostic_assessments`/`diagnostic_results` implement a lightweight
  confidence self-check over REAL Knowledge Graph concepts (`KGQueryService
  .get_concepts`, enumerated via a real `ProgramCourse` program→course
  mapping) — neither existing "quiz engine" fit: `bloom_quiz_service.py`
  needs real Lesson+Course rows and emits only placeholder text; the
  WS06/STX-11 assessment-agent pipeline is for CREDIT-BEARING assessment,
  wrong per this sprint's own "distinto dal credito: nessun CFU". Answers
  seed `concept_mastery` (BKT baseline) by reusing `MasteryTrackingService
  .batch_record_answers` directly — never an `EvidenceRecord`/
  `StudentCompetency` write (the trust-weighted competency graph stays
  untouched). `student_key_objectives` (renamed from the target sketch's
  bare `learning_objectives`, which collides with 4+ unrelated
  course-content tables/columns of that same name) moves `proposed ->
  committed -> achieved/revised`, linked to existing `TwinCareerGoal`/
  `PathScenario` rows; `objective_reviews`' nudge reuses the existing
  `learning_coach` ACE agent (`AcademicCognitiveEngine.run_mission`) — no
  new agent. New page `StudentOnboarding.js` (`/student/onboarding`) is a
  deliberately distinct "day-0" flow, NOT "WS00" (that slot is already
  Academic Discovery & Student Twin, STX-06) and NOT an extension of
  `JourneyWorkspace.js` (WS01 Academic GPS — an unrelated "journey"
  concept); a new "Diagnostic baseline" panel was added to
  `KnowledgeMapWorkspace.js` (separate from its existing `StudentCompetency`
  panel, which reads a different, trust-weighted pipeline) and a "Key
  objective" widget to `CompanionWorkspace.js` (WS00). **Found and fixed 2
  real, pre-existing bugs** blocking this sprint's own "consents audited"
  DoD, discovered verifying against a real disposable Postgres (never
  caught by mocked/SQLite tests): (1) `TwinContextService._audit` — and 3
  duplicated copies of the same pattern in `ace.py`, `student_twin.py`,
  `move_policy_service.py` — used the wrong raw-SQL column name
  (`meta_data` instead of the real `metadata`; the same bug had already
  been found and fixed once in `audit_service.py`'s own copy by an earlier
  hardening pass, but never propagated to these other 4); (2) the same 4
  functions bound `datetime.utcnow().isoformat()` — a STRING — to a
  timestamptz column, which asyncpg rejects; corrected to the SQL-literal
  `NOW()`/`datetime('now')` pattern `audit_service.py`/`erasure_service.py`
  already used correctly. Branched fresh off `origin/main` (not off
  SPRINT-08/09/10's stacked branches) — this domain has zero structural
  dependency on faculty/HR/finance. 13 new conformance tests (journey
  resumability + out-of-order-step rejection; consents-step real audit
  trail; diagnostic generation/submission incl. the no-program_id and
  unresolved-identity honest-gap paths; key-objective lifecycle; the
  `applicant.matriculated` consumer itself, incl. redelivery idempotency).
  Full regression sweep clean on a genuinely fresh container (Phase1: 104
  passed; event mesh unit suite: 18/18; conformance: 185/188, the same 3
  pre-existing, unrelated `cds_grids`-seed/test-fixture collision
  documented in SPRINT-09/10's own entries below). Confirmed via a
  stash/restore isolation check that 3 unrelated, pre-existing test files
  (`test_stx07_academic_gps.py`, `test_stx11_assessment_agent.py`,
  `test_new03_memory_stores.py`) fail identically with every SPRINT-11
  change stashed out — not a regression this sprint introduced.

- **SPRINT-10/NEW-21 — HR positions/contracts + the workload ledger
  (BOOK-22 §4, closes G18 completely — T4 and T9 both now 100%)**
  (2026-07-30, `dlu_builder_tk`): the HR/workload backbone half of BOOK-22
  that SPRINT-08/09 left target. `hr_positions`/`hr_contracts` (default
  schema, column `tenant_id` — NOT `platform` as the original target
  sketch assumed, consistent with the rest of this domain) plus
  `faculty_workload_entries`, a REAL append-only ledger: a Postgres
  `BEFORE UPDATE OR DELETE` trigger rejects any mutation outright
  (verified both ORM-level and raw-SQL, C22.4) — chosen over a DB-role
  `REVOKE UPDATE/DELETE` because this codebase has a single application
  role that doesn't cleanly support per-role grants. Corrections post as
  new, opposite-sign rows (`is_compensating=True`, `compensates_entry_id`
  back-reference, `reason` required by a CHECK constraint), never a
  mutation of the original. Entries are sourced automatically from 3
  Event Mesh subscriptions via a genuinely new `hr-workload` consumer
  group (STX-03 framework) — deliberately NOT another handler bolted onto
  the pre-existing `n8n-bridge` group, which would have been cheaper but
  semantically wrong (this program's standing "don't shoehorn into the
  wrong-named bucket" discipline): `teaching_assignment.confirmed` (a
  brand-new event this sprint — no event existed before for teaching
  assignments, a real gap found and closed in pre-flight, wired into
  `teaching_sections.py`'s `add_faculty`), `milestone.approved` (real
  since SPRINT-09/NEW-20b), and `committee.verdict.recorded` (real since
  NEW-06 — posts ONE workload entry per `CommitteeMember` on the
  committee, not only the president/secretary named in the event
  payload). No source event this sprint carries real duration data —
  every entry posts `unit='act', quantity=1.0`; `unit='hours'` is
  reserved for a future tutoring source (T5/SPRINT-13) with real
  start/end timestamps. New router `backend/api/routes/hr.py` (3
  sub-routers: `/api/hr-positions`, `/api/hr-contracts`, `/api/workload`)
  and a minimal staff-facing frontend, `OrganicoWorkloadDesk.js`
  (`/organization/organico-workload`) — positions, contracts, the entry
  ledger, a compensating-entry form, and the `workload_summary`
  "mentorship dividend" view (BOOK-07: count of acts per `entry_type`,
  not hours). 7 new conformance tests against a real disposable Postgres
  (C22.4 append-only trigger — ORM update + raw delete + the
  reason-required CHECK constraint; 2 Event Mesh sources posting through
  the real consumer handlers with hand-built envelopes, no Redis needed;
  the `workload_summary` mentorship-dividend query, including
  compensating-entry net-quantity accounting). Fixed one real, pre-
  existing test as a direct consequence of this sprint's own closed-set
  change: `test_stx03_event_mesh.py::test_consumer_groups_closed_set`
  hardcodes the full `CONSUMER_GROUPS` tuple and needed `"hr-workload"`
  added — confirmed via a stash/restore isolation check that this was
  the only regression this sprint introduced (the `test_new06_thesis_
  committee.py` SQLite/UUID-dialect errors seen during the same sweep
  reproduce identically with every SPRINT-10 change stashed out, so are
  pre-existing and unrelated). Full regression sweep clean on a
  genuinely fresh container (Phase1: 104 passed; event mesh unit suite:
  18/18; conformance: 197/200, the same 3 pre-existing, unrelated
  `cds_grids`-seed/test-fixture collision documented in SPRINT-09's own
  entry below).

- **SPRINT-09/NEW-20b — milestone, deliverable, AP, budget (BOOK-22 §2
  Step 3 + BOOK-23 §3-4, closes G18 + G19 completely — T4 and T7 both
  now 9/9 tables)** (2026-07-30, `dlu_builder_tk`): the second and final
  slice of the Course Creation v1.0 faculty pipeline, plus native
  Accounts-Payable and budget commitment accounting. `engagement_
  milestones` (2 rows, `course_design` 30% / `full_course` 70%) are
  created automatically as a side effect of `execute_engagement`
  (SPRINT-08's own function, extended) — not a separate step a caller
  must remember to invoke; their `fee_share_pct` mirrors `Authoring
  Engagement.design_fee_pct`/`.full_course_fee_pct`, already CHECK-summed
  to 100 (C22.2, now verified end-to-end). `engagement_deliverables`/
  `deliverable_reviews` add the release → review → approve cycle (R22.1:
  only a passing review promotes a milestone to `approved`, never set
  directly). `content_ref_type`/`content_ref_id` are a soft reference to
  a `course_exchange_service` FEX export or a `CourseVersion` row —
  found the SAME "FEX format" false-friend again in this sprint's own
  plan text (`course_fex.py` is "Final Course Examination", unrelated;
  already corrected once in SPRINT-08, re-corrected here). Design lock
  (BOOK-22 §2): an `approved`/`invoiced`/`paid` `course_design` milestone
  refuses a new deliverable release until `reopen_milestone` (reason
  required) — enforced only within this domain, no integration with
  `course_governance.py`'s own, unrelated content-editing locks.
  `supplier_invoices` are generated exclusively by
  `ap_service.generate_supplier_invoice_from_milestone` — a REAL,
  NOT NULL FK (`milestone_id -> engagement_milestones.id`) makes R23.5/
  C23.2 ("an AP invoice without an approved milestone is structurally
  impossible") true at the DDL level, not just a service-layer check
  (both are tested). `payment_runs` batch invoices; approval reuses
  `finance_service.CFO_ROLES` (not a new role); execution is a MOCK
  driver (no real banking/ERP integration this sprint, as BOOK-23 §3
  already names explicitly). Real commitment accounting (BOOK-23 §4):
  `AuthoringEngagement.budget_line_id` (nullable — not every engagement
  is budget-tracked) commits `total_fee_cents` to a `BudgetLine.
  committed_amount_cents` at engagement execution; payment-run execution
  moves that same amount to `spent_amount_cents` (decrement + increment
  together) — corrected mid-implementation from an initially-assumed
  append-only ledger (which would have left `committed` permanently
  overstated instead of reflecting outstanding commitments). New
  frontend: milestone/deliverable sections added to `FacultyOnboarding.js`
  (release deliverables) and `FacultyVerificationQueue.js` (review +
  reopen), and a new `pages/finance/APBudgetDashboard.js`
  (`/admin/finance/ap-budget`) — role-gated on the REAL backend check
  (`cfo`/`admin`/`super_admin`), not the sibling AR finance pages'
  `finance_admin` (a pre-existing frontend/backend role-naming drift,
  not introduced or fixed by this sprint). **Found and fixed a real bug
  before writing any new code**: SPRINT-08's own migration (still open
  in PR #84) had a `down_revision` pointing at SPRINT-07's unmerged
  migration chain — a leftover from before SPRINT-08 was correctly
  re-branched off `origin/main` mid-closure; `alembic heads` failed to
  resolve. Corrected directly on PR #84 (the real chain tip is
  SPRINT-06/NEW-18's migration), not worked around locally, since
  SPRINT-09 depends on that same chain being valid. Migration verified
  via a full upgrade-from-zero + downgrade + re-upgrade round-trip
  against a real disposable Postgres (8 new tables + 1 new column). 7
  new conformance tests (C22.2, C23.2 — both service-guard and raw-FK
  paths — design lock, CFO gate, full E2E fixture from engagement
  execution through paid payment run with budget commitment verified at
  every step), full regression sweep clean on a genuinely fresh
  container (Phase1: 104 passed; conformance: 190/193, the 3 remaining
  failures a pre-existing, unrelated test-fixture collision between
  `test_admission_orientation.py`/`test_admission_e2e_fixture.py`
  (SPRINT-06) and the real preval pilot CDS-grid seed data (SPRINT-03/04)
  — both independently hardcode the literal program name "L-33 Economia
  e Commercio," confirmed via traceback inspection, not touched by this
  sprint's own domain).

- **SPRINT-08/NEW-20a — faculty onboarding + authoring-contract signing
  (BOOK-22 §2 Step 1-2, closes G18 parte 1/2)** (2026-07-30,
  `dlu_builder_tk`): the first slice of the Course Creation v1.0 faculty
  pipeline. Step 1 (onboard): register → upload personal_id/career_
  transcript/fiscal_data → back-office verification (`faculty_document_
  verifications`, DB-backstopped required rejection reason) →
  verification-complete auto-activates the real, pre-existing
  `faculty_profiles` row (new `onboarding_status` column, `active` left
  untouched). Step 2 (contract): auto-drafted from a JSON-structured
  `contract_templates` instance (no Jinja/docxtpl anywhere in this
  codebase — the renderer is a pure, reportlab, byte-identical-on-
  identical-input function, same discipline as `document_credential_
  service.py`), ordered multi-party QES signing (university roles
  `provost`/`cfo` first, then the instructor — enforced via `sequence_
  order`), execution archives the contract directly on `authoring_
  engagements` (`executed_pdf_storage_uri`/`content_hash`/
  `source_snapshot`) rather than `issued_document_credentials` as
  BOOK-22's own Annex A had assumed — that table is for publicly
  verifiable credentials (twin_id NOT NULL FK, closed document_type
  CHECK), a faculty contract is an internal HR/legal record with no such
  need. `qes_signature_ref` (NEW-12) extended from 2 to 3 mutually
  exclusive subjects (`dlu_engagement_signature_id`), reusing the real
  QES submission pipeline (`submit_engagement_signature_for_qes`)
  instead of forking a parallel one. A decline on any signature returns
  the engagement to `draft` and resets every other signature row to
  `pending`; `resubmit_for_signatures` restarts a fresh ordered cycle.
  C22.5 (every staff read of a `faculty_documents` row is audited) reuses
  the real, existing generic `platform.audit_logs` table rather than a
  new dedicated one. New frontend: `pages/faculty/FacultyOnboarding.js`
  (self-service register/upload/track/sign), `pages/institution/
  FacultyVerificationQueue.js` (staff document-verification queue +
  university-side signature actions), and a new `ds/SignatureFlow`
  component (ordered multi-party signature sequence renderer).
  **Found and fixed two real bugs during verification, both directly
  blocking this sprint's own work rather than pre-existing-but-unrelated
  gaps this program otherwise only discloses:** (1) `platform.faculty_
  profiles` — a real, actively-used table — had NEVER had an Alembic
  migration anywhere in this codebase (confirmed via exhaustive grep;
  only its sibling `faculty_assignments` did), backfilled idempotently as
  this sprint's own migration's "step 0" (`checkfirst=True` table
  create); (2) `PlatformAuditLog.ip_address` was declared `String(45)`
  in the ORM against a REAL Postgres `INET` column — any insert of that
  model via an async (asyncpg) session crashed with `DatatypeMismatch
  Error`, even with the field left `NULL`, because asyncpg's explicit
  per-parameter type cast didn't match the real column type; this was
  already live for the one other caller of this table
  (`content_workflow.py`'s section-status audit log), simply never
  exercised against a real Postgres+asyncpg connection before. Fixed via
  `String(45).with_variant(INET(), "postgresql")` — no migration needed,
  the real column was already correct, only the ORM declaration was
  wrong. Also closed a real authorization gap found while wiring the
  frontend: the `submit-signature` endpoint originally let ANY
  authenticated user submit a `provost`/`cfo` signature with no role
  check at all — now staff-gated (instructor retains self-service via a
  `FacultyProfile.user_id` identity check). Migration verified via a
  full upgrade-from-zero + downgrade + re-upgrade round-trip against a
  real disposable Postgres. Step 3 (`engagement_milestones`/
  `engagement_deliverables`/`deliverable_reviews`) and T9 (workload
  ledger) remain target-state, proposed SPRINT-09/NEW-20b. 11 new
  conformance tests (C22.1/C22.3/C22.5), full regression sweep clean
  (Phase1: 104 passed; conformance: 209 passed) — a pre-existing,
  unrelated `platform.legal_holds`/wave2-bootstrap schema-drift bug was
  found incidentally during the sweep and disclosed, not fixed (out of
  this sprint's own domain).

- **SPRINT-07/NEW-17d — preval golden-set + eval-harness gate, closes
  C21A.6 (G17, F4 — Milestone M1 functionally complete)**
  (2026-07-30, `dlu_builder_tk`): the last open phase of the credit
  pre-evaluation automation program (BOOK-21A §7). Turned an old,
  audit-only HITL override into a real correction mechanism —
  `submit_hitl_review` now accepts structured
  `corrected_units_validated`/`corrected_units_to_integrate`/
  `corrected_grid_row_ref`/`corrected_rule_invoked` fields and actually
  mutates `preval_sheets.rows`/`.totals` for the amended row (the exact
  "amend sheet row" action BOOK-21A's own Annex A had flagged as a
  prerequisite for its still-open C21A.6 conformance check since
  SPRINT-04 — closed here as a side effect of building this sprint's own
  learning loop, not the primary goal). Every HITL-approved
  `preval_sheets` row becomes a golden `EvalCase` (T11 eval-harness
  tables, dataset domain `preval_case` — deliberately not the plan's own
  literal "credit_pre_evaluation" wording, which collides with a
  different, unrelated, pre-existing system); because the same builder
  function always reflects a sheet's CURRENT state, a later HITL
  correction is picked up automatically the next time the learning loop
  runs, with no separate "override → golden case" code path. The grader
  replays the deterministic A6 matching engine against each golden
  case's pinned grid/rule-pack version and scores it against the
  human-confirmed sheet — composite ECTS accuracy, per-row
  precision/recall, and HITL escalation/override rates (by rule and by
  CDS) are real, computed metrics; VRA-outcome-exactness and
  extraction/SSD component accuracy are honestly reported as `None` — no
  ground truth exists in this codebase to measure them independently,
  and no number is fabricated for either. A real CI gate
  (`scripts/preval_eval_gate.py`) now blocks the actual production image
  build/push job (`build-push-images.yml`) on a failing composite-
  accuracy verdict — not a symbolic check, a working dependency in the
  real deploy pipeline. A weekly report and a per-CDS partial
  auto-approval threshold config were also built (the latter defaults
  `enabled=False` and is not wired into the real HITL flow anywhere this
  sprint — turning it on is explicitly left to a future sprint, once a
  real, non-provisional certification exists). **Honest, load-bearing
  caveat, not a footnote**: this environment has zero real historical
  approved-sheet data (confirmed in pre-flight, matching the plan's own
  risk register) — the golden set is bootstrap-sized (one demo fixture
  plus whatever live sprint-02-06 traffic has produced), so today's
  "pass" verdict certifies the mechanism works, not a mature
  ~90%-over-a-real-corpus statistical result; the weekly report's own
  `certification_status` field reports `"provisional"` below 30 golden
  cases rather than silently "certified." Also independently
  investigated and ruled out a claim (from one of two parallel agents on
  this sprint) that this codebase's established rolled-back-transaction
  test-fixture pattern silently leaks committed rows — reproduced
  empirically against a fresh Postgres and confirmed the fixture pattern
  is sound; the agent had conflated its own manual runs of the new,
  intentionally-persisting CI gate SCRIPT (a different mechanism by
  design) with the test suite's separate rollback discipline. BOOK-21A
  bumped to v0.3 (§7/§8/Annex A rewritten with real measured mechanism
  and honest gaps, not projections). Milestone **M1 (PreEval + Intake)**
  is functionally complete — every planned feature across SPRINT-02
  through SPRINT-07 has shipped and is verified — though
  `BACKLOG_TARGET.xlsx`'s own row-level bookkeeping for M1 still shows
  17 stale `Da fare`/`In corso` rows from SPRINT-02/03/04/06, a
  now-3-times-confirmed pre-existing doc-sync gap (rows never actually
  written despite prior HANDOVER.md entries claiming otherwise) —
  disclosed again rather than silently backfilled outside this sprint's
  own scope; a dedicated backlog-bookkeeping cleanup pass is recommended
  given the pattern's now-repeated recurrence.

- **SPRINT-06/NEW-18 — admission funnel: intake, titles, orientation,
  matriculation (G17)** (2026-07-30, `dlu_builder_tk`): the full
  prospect-to-matriculated pipeline — `admission_intakes` (versioned
  requirements, immutable once open) → `admission_applications` (11-state
  machine, BOOK-21 §4) → `applicant_qualifications`/`qualification_
  evaluations` (3-tier AI+HITL, mirroring the BOOK-21A engine's own
  registry-lookup pattern against `equivalence_rules`/
  `external_syllabus_records` rather than reusing that system's tables
  directly) → `eligibility_verdicts` (R21.2 explainable, R21.3 human-
  actor-gated negative verdicts) → `orientation_recommendations` (reuses
  `preval_workflow_service.compute_instant_estimate` for a zero-
  persistence, twin-less recognized-credit preview; a simple standalone
  ETA estimate, honest `null` cost projection — no fee-schedule data
  exists yet) → `admission_offers`/`admission_acceptances` →
  `ApplicantMatriculated` (creates a real `users` row directly — neither
  existing user-creation function fit a passwordless admitted applicant
  — plus a `student_twins`/`student_dossiers`/first `student_invoices`
  row, reusing prior sprints' own services rather than reimplementing
  them). Pre-flight found the plan's assumed "existing admissions/* UI"
  was actually a separate, pre-existing, broken CRM lead/opportunity-
  management surface (`crm.py`, never mounted, several response-shape
  bugs of its own) — left untouched and disclosed as unrelated tech debt;
  new pages were built instead for the real application funnel. Also
  found and disclosed (not silently reconciled) two deliberately separate
  "credit pre-evaluation" systems already coexisting in this codebase
  (G16/BOOK-14A's `credit_pre_evaluations` vs. G17/BOOK-21A's
  `preval_requests`, confirmed via the codebase's own "do NOT reuse...
  vice versa" comments) — this sprint's qualification engine borrows the
  latter's approach without merging the two, and `ApplicantMatriculated`
  does not fabricate a hand-off between them. The 4 backend agents
  building this sprint each owned entirely separate new files (no shared-
  file conflicts by construction); the coordinating session wrote the
  10-table model layer and combined migration itself before delegating,
  letting every agent develop against an already-migrated real schema.
  Found and closed one real gap after all agents landed: no list endpoint
  existed for browsing intakes/applications, only single-id lookups —
  added `list_intakes`/`list_applications` (service + route + frontend
  wiring) post-hoc. Verified end-to-end against a real, freshly migrated
  Postgres: a from-scratch fixture test (this sprint's own DoD) walks
  lead → application → qualification → eligible → orientation → offer →
  accept → matriculated using only the real production functions across
  every module, asserting a real `users`/`student_twins`/
  `student_dossiers`/`student_invoices` row exists at the end — plus the
  full existing conformance suite (175 tests) and a Phase1 (104 tests)
  regression sweep, both clean. Along the way, patched three pre-existing,
  unrelated infrastructure gaps ad hoc for this sprint's own tests only
  (a CRM-integration migration whose idempotency guard checks the wrong
  schema and silently no-ops; `external_courses`' migrated schema drifted
  from its current ORM model) — disclosed, not fixed at the source (out
  of scope, different domains). BOOK-21 bumped to v0.2 (Annex A refined:
  funnel → exists, every remaining gap — C21.5's eval-harness gate, full
  GPS Pareto orientation, program fee data, onboarding-journey/G16 hand-
  offs — named explicitly).

- **SPRINT-05/NEW-19 — native student AR, unified administrative holds,
  student dossier (G19)** (2026-07-30, `dlu_builder_tk`): native
  receivables register replacing "invoicing lives only in external
  Frappe/PagoPA" — `student_invoices`/`invoice_lines`/
  `payment_reconciliations` (`finance_service.py`,
  `draft → issued → paid | overdue → cancelled`, R23.2's payment
  confirmation gated to reconciliation or an audited CFO override —
  C23.1 verified as a property test against a real Postgres). Pre-flight
  found an entire parallel Stripe Connect AR system already living in
  `backend/domains/payments/` with zero HTTP routes ever mounted, and 3
  incompatible "financial hold" concepts never reconciled with each
  other — resolved via an explicit architecture decision with the
  operator: `administrative_holds` becomes the ONE authoritative hold
  table (`source: native|stripe|frappe_sync`, same discriminated-source
  pattern as `EvidenceRecord.source_kind`), `backend/domains/payments/`
  stays untouched (disclosed as orphaned tech debt, not silenced). Wired
  the first real enrollment-time hold check in this codebase
  (`assessment_session_service.enroll`, C23.3, same transaction
  boundary — the Stripe domain's own hold check was previously the only
  one, and only ever ran at degree-clearance time, never at exam-session
  enrollment). Added the student administrative dossier (T8, BOOK-23
  §5) in full: `student_dossiers`/`dossier_documents`/
  `matriculation_checklists` (one row per item, live-resolved — mirrors
  `clearance_service`'s never-mutate posture), and re-wired the 3
  previously-dead Finance UI pages (`FinancePayments`,
  `FinanceReconciliation`, `FinanceHolds`) plus `RegistrarDesk` to this
  new native domain at their own pre-existing `paymentAPI.js` URL
  prefix — per BOOK-23 Annex A's own wording ("UI reused over native
  domain"), not the Stripe domain, correcting my own initial framing of
  the operator-approved decision after reading that line in full. Found
  and fixed a real naming collision during conformance testing: a
  pre-existing, orphaned PI-3/Stripe-billing `invoices` table already
  occupied that name in every migrated environment — the new AR
  aggregate is `student_invoices` instead. G13's identity-verification
  checklist item is honestly scoped to "policy configured + disclosure
  ack at current version" — no per-student verification-succeeded event
  exists anywhere in this codebase, and none is fabricated. Two new
  `ds/` components (`MoneyTable`, `DocChecklist`, UI_AUDIT.md #12/#10,
  never built in SPRINT-01's original 8) plus the 4 pages migrated from
  antd to Paper tokens. Also found, during doc-sync, that `ER_MAP.md`
  had not been updated by any of the 3 preceding sprints (SPRINT-02/03/04
  NEW-17a/b/c's ~15 preval tables are entirely missing from it, and its
  own "308 tables" header predates all of them) — disclosed honestly in
  the file itself rather than silently patched or retroactively
  backfilled (out of scope for this sprint). 69 new conformance tests
  (invoices, holds, dossier, payment routes) plus the full existing
  suite (141 total) verified green against a real, freshly-migrated
  disposable Postgres; the combined migration's up round-trip clean.
  AP/budgets (Ch. 3-4) and Ch. 8 planning & control remain entirely
  target — NEW-20b/NEW-30. BOOK-23 bumped to v0.3 (Annex A refined:
  AR slice + T8 → exists, every remaining gap named explicitly rather
  than left implicit).

- **SPRINT-04/NEW-17c — rule packs, registries, VRA (F3)** (2026-07-30,
  `dlu_builder_tk`, third slice of G17): versioned CDS-specific
  derogations (`cds_rule_packs`, A6 addition — the one concrete rule
  type documented anywhere in the source material,
  `max_cap_per_ssd_family`, proven via a synthetic fixture since neither
  of the 2 pilot CDS grids has a real derogation on record), career/
  certification validity registries (`career_validity_registry`/
  `certification_registry`, A3/A4 — promotes NEW-17b's `engine.py`
  in-code certification stand-in to a real table), VRA for master's
  applicants (`vra_evaluations`, A7 — 4 outcomes, first-applicable-wins;
  `run_automatic_evaluation` now hard-blocks any magistrale case with no
  prior VRA record, C21A.4), a third per-row confidence factor +
  targeted escalation flag (A8), and a public, stateless, zero-
  persistence `POST /api/preval-requests/instant-estimate` (multi-CDS
  what-if preview, usable before any formal case exists). Pre-flight
  found the 178-page source manual isn't extractable in this
  environment (no PDF renderer installed) — exactly the situation this
  sprint's own prerequisites anticipated; all registries are seeded only
  with the concrete examples already documented in PREVALUTAZIONE_SPEC/
  BOOK-21A, the rest is explicitly open data-entry, not fabricated.
  Found and corrected my own earlier pre-flight assumption during
  verification: SPRINT-02's HITL override is audit-only — it never
  mutates a sheet's actual row data — so C21A.6 (granting the seminar
  row near an admission-year threshold without real surplus) is an
  honestly unresolved gap, not something "verified via the existing
  mechanism" as first written; a future "amend sheet row" endpoint is a
  prerequisite. Also closed a real test gap found in NEW-17b's own
  engine logic (C21A.3, student-choice partial coverage correctly
  rejected — the logic already existed, it just had no dedicated test).
  32 new conformance tests; BOOK-21A bumped to v0.2 (Annex A refined —
  F1-F3 all live, only F4 remains, C21A.6 flagged as an open gap).
  Verified end-to-end against a disposable Postgres: the combined
  migration's up/down/up round-trip clean, seed script confirmed
  idempotent, 72/72 conformance tests green, Phase1 (104 tests)
  regression sweep clean.

- **SPRINT-03/NEW-17b — real document extraction + deterministic matching
  engine (F2)** (2026-07-30, `dlu_builder_tk`, second slice of G17): the
  admissions-funnel case workflow's manual evaluation step (SPRINT-02)
  becomes real. 5 new tables (`extracted_careers`/`extracted_exams`/
  `cds_grids`/`cds_grid_rows`/`ssd_crosswalk`) + a migration. Agent A1
  (document classification/legibility, `preval/intake.py`); agent A2
  (transcript parsing via a real `LLMClientFactory` call, isolated
  behind a monkeypatchable seam per this codebase's own convention) +
  agent A5 (SSD crosswalk mapping, `preval/parser.py`); agent A6 — a
  byte-for-byte Python port of the Workbench prototype's own
  `calcolaMatching()`/`totali()` JS (SSD matching, valid-certification
  fills, student-choice/seminar surplus chaining, V.O. full-fill,
  internship/final-exam never auto-filled), against 2 seeded pilot CDS
  grids ("L-33 Economia e Commercio", "L-24 Scienze e Tecniche
  Psicologiche") transcribed verbatim from that same prototype (no
  external xlsx files exist — corrected a pre-flight assumption in the
  plan). `preval_requests.target_program_label` added as the real
  lookup key (no seeded `catalog_editions` rows exist for the 2 pilot
  programs yet). Pre-flight also found the task's own algorithm summary
  omitted the certification-matching step — required to reproduce the
  DoD's own fixture (demo career "Conti" → 74 units recognized/3 to
  integrate/71 net/3rd-year admission), verified byte-identical
  end-to-end via a real integration test (not just the pure engine in
  isolation). Found and fixed a real bug during verification: the
  auto-evaluation trigger, wired into document-upload completion, could
  raise unhandled for a legitimate applicant with no prior credits to
  pre-evaluate (the 'triennale' checklist doesn't require a transcript —
  correctly, since a brand-new student may have nothing to convalidate)
  — now degrades gracefully to the SPRINT-02 manual staff fallback
  instead of crashing the upload request. 16 new conformance tests (6
  engine, 9 parser, 1 full-workflow integration), all passing against a
  real migrated Postgres; correctly skip (not error) when Postgres isn't
  reachable.

- **SPRINT-02/NEW-17a — admissions-funnel Credit Pre-Evaluation CASE
  workflow (F1)** (2026-07-29, `dlu_builder_tk`, closes the first slice of
  G17 — see TRACEABILITY.md; `_dlu/sprint-plan` program): the pre-
  evaluation workflow goes live with evaluation still MANUAL — a human
  pre-evaluator types in recognized/to-integrate totals; no AI extraction
  yet. 6 new tables (`preval_requests`/`preval_documents`/
  `preval_evaluations`/`preval_sheets`/`hitl_reviews`/
  `sheet_countersignatures`), a new `/api/preval-requests` +
  `/api/preval-sheets` API with R21A.1 workability gates (identity, CF,
  dedup/homonym, CDS-target — structured `not_workable_reason`, never a
  silent drop), a confidence-ordered HITL queue with mandatory-reason
  overrides, and a countersignature that makes the sheet immutable
  (DB-level unique constraint, not just an app check). 7 `preval_case.*`
  events wired end-to-end (2 of them correct a SPRINT-01 naming mistake —
  see SPRINT-02.md's own "Correzioni al piano" — `preevaluation.shared`/
  `countersigned` renamed to `preval_case.shared`/`countersigned` since
  this is a genuinely distinct domain from NEW-17's existing Tier1-3
  `credit_pre_evaluations`, not an extension of it). Frontend:
  `PreEvaluationWorkspace` gets a clearly-separated new case section
  (wizard, document upload, sheet review/countersign via
  `AIProposalCard`), plus a new staff `PrevalDesk` HITL desk. Verified
  against a real migrated Postgres: migration round-trip clean, 12
  conformance tests (workability gates, C21A.1 — no sheet reaches
  `shared` without a completed HITL chain — even when `status` is forced
  to `approved` directly, C21A.5 — countersigned immutability — event
  emission in exact order, `dlu.preval_case.v0_2` serializer round-trip),
  correctly skip (not error) when Postgres isn't reachable.

- **SPRINT-01/NEW-17f — target-state program foundations** (2026-07-29,
  `dlu_builder_tk`, opens G17-G21 — see TRACEABILITY.md; first sprint of
  the separate 22-sprint `_dlu/sprint-plan` program, BOOK-20 §7b): pure
  scaffolding, no user-facing feature. 9 empty domain model files
  (T1-T10/T12); 14 target-state events registered in the closed
  taxonomy as reserved slots (2 correct a plan drift — 3 of the
  originally-specified 5 "Preval*" events already existed as
  `PREEVALUATION_REQUESTED/ESTIMATED/VALIDATED`, only `SHARED`/
  `COUNTERSIGNED` were genuinely new; see SPRINT-01.md's own
  "Correzioni al piano"); the T11 eval-harness target tables added to
  the EXISTING NEW-02 `models_eval.py` (not a parallel file), extending
  `agent_gate_runs`/`eval_human_samples` via two 🔧 FK links rather than
  duplicating them, plus `scripts/eval_runner.py`; a CI "Conformance
  Suite" job (3 real meta-tests in `tests/conformance/` had never been
  wired into any workflow before this sprint); Paper v3 ratified as the
  one frontend token system (`legacyBridge.css`, zero rewrites), an
  8-component `components/ds/` library (`AIProposalCard` is the
  flagship), and an anti-hex-regression CI lint. Found and fixed a real
  cross-repo drift while running `scripts/ci/lint_ontology.py`: 9 new
  event nouns were missing from both `dlu-core.yaml` copies (same class
  of gap NEW-11/NEW-17 hit for `degree`/`preevaluation`) — fixed in both
  repos before closing the sprint.

- **Tenth persona: the Researcher — Research Workspace & Open Science**
  (2026-07-29, plan `_dlu/sprint-plan`): grounded in the comparative
  analysis "Architetture IA per Ricerca Universitaria" (Renku 2.0
  reproducibility/provenance, Swiss Data Custodian zero-trust
  collaboration, EuroHPC AI Factories, Federated RAG, GDPR/AI-Act for
  research). New **BOOK-25** (v0.1-draft, G21) and ER domain **T13**
  (11 tables: projects, versioned datasets, reproducible environments,
  provenance DAG, outputs, grants→budget links, federated KB scopes,
  compliance assessments). Research Assistant added to BOOK-10A Annex T
  (propose-only, verifiable citations). Feature tree area 25 (+12),
  backlog 93 → **105** items; executable plan grows to **22 sprints**
  (new SPRINT-21 = NEW-33; hardening renumbered SPRINT-22 = NEW-29);
  demo pack gains the Researcher scenario.

## Unreleased

- **Target-state plan extension — CFO planning & control, persona agents,
  demo scenarios** (2026-07-28, plan `_dlu/sprint-plan`): coverage check on
  the 21-sprint target plan found three gaps, now closed. (1) BOOK-23 gains
  Ch. 8 (v0.2-draft): fee schedules, pipeline-driven revenue forecasts,
  cash-flow projections, what-if scenarios, period closes and variance
  analyses with governance-action routing (sprint NEW-30, C23.6–C23.8).
  (2) BOOK-10A gains Annex T: four propose-only persona-support agents —
  Student Companion (consolidated), Faculty Assistant, Admin Copilot, CFO
  Analyst (sprint NEW-31); BOOK-24 CFO Command row updated accordingly.
  (3) Demo Scenario Pack (sprint NEW-32): extends `seed_demo.py` and adds
  nine per-persona guided scenarios, each mirrored by an automated E2E
  test. Feature tree/backlog grow 82 → 93 items; final hardening renumbered
  NEW-29 = SPRINT-21.

- **Investor-demo readiness — all 4 items delivered** (2026-08-20,
  `dlu_builder_tk`, no new G-register item — a demo/pilot-readiness
  pass, not a regulatory gap): the nine named agents seeded since
  STX-14/15 had never been seeded outside the test suite — a fresh
  environment showed an empty agent registry and no Twin/GPS/
  credential/recognition data to demo.
  **Demo data** (`--scenario=ai_native_demo`, `backend/scripts/
  seed_demo.py`): seeds all 9 agents, 5 Student Digital Twins, a real
  GPS `fastest_path` scenario, a signed credential, a granted
  recognition claim, a Tier-1 pre-evaluation, viva evidence, a real
  advisor caseload, and one demo login per persona (student/instructor/
  admin/platform_admin) — reusing real service functions throughout,
  never hand-written rows bypassing business logic. Found and worked
  around two pre-existing `academic_gps_service.py` bugs along the way
  (`platform.course_catalog_items` has no creation migration anywhere;
  a `not_yet_available` reason string exceeds `PathScenario.reason`'s
  own 200-char column limit, aborting the 4-scenario batch insert) —
  both disclosed, neither fixed, out of this pass's scope.
  **Nav/persona alignment**: the AI-native student pages were
  completely unreachable from the app's own navigation — the component
  first assumed to be the live nav (`Sidebar.js`) turned out to be dead
  code with zero imports anywhere, and the actual live one
  (`PaperNav.js`) showed the identical course-authoring toolbar to
  every logged-in persona regardless of role, including a
  `platform_admin` with no click-path to Operator Plane at all (nested
  under an `admin`-only dropdown, a different role set than
  `operator_plane.py`'s own `_require_operator`) despite being fully
  authorized server-side. Fixed: persona-aware post-login redirect, the
  course-authoring toolbar hidden for a "pure" student/operator
  account, Operator Plane promoted to its own persona-gated link.
  **New pages**: IW4 Advisor Workspace and IW6 Operator Plane, both
  left backend-only by the large-tier backlog below, now have real
  frontend pages.
  All four personas rehearsed and screen-recorded end to end against a
  live local instance; `docs/INVESTOR_DEMO_WALKTHROUGH.md` is the
  resulting script. Found, disclosed, not fixed here: the entire
  `backend/domains/payments/` subsystem (financial holds, invoices,
  installments) has no Alembic migration anywhere — surfaces as a real
  500 on the Credential Wallet's clearance-checklist section, degrading
  to an honest empty state rather than crashing.

- **Category 3 infrastructure gaps — all 3 items closed** (2026-08-19,
  `dlu_builder_tk`, no new G-register item): closes the user's own
  stated priority order's last tier — "no real deployment target/IaC,
  alerting not reaching anyone, no automated backup schedule"
  (`docs/sprint_decisions_20260807_security_tenancy_hardening.md`
  lines 3-5/159-161).
  **Alerting** (2026-08-16): Prometheus's `alerting:` block, commented
  out since inception, now points at a new Alertmanager instance
  (staging + production compose); a new in-app webhook receiver
  (`POST /api/internal/alerts/webhook`, mirrors `internal.py`'s shared-
  secret auth pattern) always logs every received alert and optionally
  forwards to a configured Slack/webhook URL. Found while closing this:
  most pre-existing alert rules (all of the orphaned `prometheus-
  alerts-pi4.yml`, a real subset of the already-mounted `alerts.yml`)
  reference metrics that are never incremented anywhere or don't exist
  at all — only the 2 confirmed-live orphaned rule files (event-mesh,
  eval-harness) are wired in; `pi4`'s stays deliberately unmounted
  rather than faking working payment/workflow/AI-governance alerting.
  **Backup automation** (2026-08-17): a dedicated Celery beat+worker
  pair runs `pg_dump` nightly with the existing `scripts/backup_
  production.sh`'s own 7-day retention policy; `postgresql-client`
  added to `backend/Dockerfile` so `pg_dump` is actually present in the
  worker container. Found while closing this: `celery beat` has never
  run in ANY environment (dev/turnkey/italian run a plain worker only;
  staging/production run no Celery process at all) — all ~20 pre-
  existing `beat_schedule` entries have therefore never fired anywhere.
  Surfaced to the user directly (turning that on wholesale would
  activate 20 previously-dormant production tasks at once); the user
  chose a minimal, dedicated beat+worker pair scoped to backup only,
  leaving the shared scheduler exactly as dormant as before.
  **Deployment/IaC** (2026-08-18): new CI workflow builds and pushes
  `backend`/`frontend` Dockerfiles to GitHub Container Registry using
  the repo's own `GITHUB_TOKEN` — closes the loop `docker-compose.
  production.yml` already assumed existed (`${PRODUCTION_BACKEND_
  IMAGE}`/`${PRODUCTION_FRONTEND_IMAGE}`, previously referencing images
  nothing ever built; `docker compose --profile ops config` now exits 0
  with zero env vars supplied). Deliberately no Kubernetes/Terraform —
  BOOK-18 Ch. 6 already treats orchestrator choice as an ops decision,
  not an architecture one.
  15 new tests; every new/changed infra file verified with its real
  authoritative tool (`promtool`, `amtool`, `docker compose config`,
  `actionlint`), not just visual inspection; full raw-suite regression
  (52 failed/5 errors) confirmed the same pre-existing, unrelated
  baseline documented one day earlier in the large-tier-backlog summary
  below (68 failed/5 errors, same categories, zero file overlap). See
  `docs/sprint_decisions_20260819_category3_summary.md` (cross-
  references all 3 per-item docs).

- **Large-tier driver/integration backlog — all 6 deferred items closed**
  (2026-08-15, `dlu_builder_tk`, no new G-register item): closes the
  moderate/large-tier backlog deferred by the two prior driver/
  integration hardening passes below — LTI 1.3 full JWT verification,
  GPS `lowest_cost`, G7 regulation-year schema binding, Institution
  Workspace IW4 (Advisor Workspace) + IW6 (Operator Plane), and a full
  ESCO occupation crosswalk. Planned as one 6-item effort, executed and
  committed one item at a time in dependency order (G7 → GPS-cost → LTI
  → IW4 → IW6 → ESCO).
  **G7**: `program_courses.program_version_id` (nullable FK, two
  PARTIAL unique indexes — a naive 3-column unique would have silently
  allowed duplicates for the version-agnostic NULL case every existing
  row is in) makes NEW-04's regulation-year fingerprint tag actually
  change computed plans instead of being cosmetic-only; no backfill to
  a specific version, to avoid silently emptying a different cohort's
  requirement set.
  **GPS `lowest_cost`**: new `cost_per_credit` column, honesty-gated
  total (any course missing cost/credits data keeps the whole scenario
  `not_yet_available`).
  **LTI**: new `LtiPlatform` registration table + a real JWKS-fetch-and-
  cryptographically-verify path (`PyJWT`'s `PyJWKClient`) — no genuine
  verified-JWT pattern existed anywhere in this codebase before this;
  OIDC init now redirects to a registered platform's real auth endpoint
  when one resolves, falling back to the prior demo behavior unchanged
  otherwise.
  **IW4**: new `AdvisorAssignment` table (partial-unique-indexed for
  soft-delete/reassignment) + management-gated CRUD + an own-caseload-
  default composite (GPS hedges, risk stream); also fixed a real latent
  bug in `move_proposal_service.list_for_twin` — reached into a
  client-specific private `_cache` dict instead of the real
  `redis.asyncio.Redis` `scan_iter` interface every other cache-backed
  service already uses (verified this doesn't currently manifest in
  production, since `redis_client` is still always the same in-process
  mock everywhere, but would silently break the moment a real Redis
  client is ever substituted).
  **IW6**: driver-health snapshot reusing the three existing per-driver
  `CircuitBreaker` singletons directly (already process-wide), a new
  read-only `ConsumerGroup.mesh_lag()` sibling to `drain()` (zero
  `XREADGROUP`/`XAUTOCLAIM`/handler dispatch), and one new anonymized
  cross-tenant AI-spend aggregate — gated to `platform_admin`/
  `super_admin` only, no new role invented.
  **ESCO**: sourced REAL data from the official public ESCO REST API
  (confirmed reachable — the plan's own honest "if not fetchable"
  fallback did not apply) — 2,700 of ESCO's ~2,942 published
  occupations (91.8%), 104,504 real skill-relation rows, via a
  pagination quirk found and fixed empirically (ESCO's own `offset`
  param is a page index, not an item-skip count); replaces the
  STX-14/15 hand-curated 8-occupation `urn:dlu-esco-lite:` seed via the
  first CSV-bundled bulk-insert migration in this codebase;
  `career_gap_service._skill_has_competency`'s matching logic
  deliberately unchanged (verified via a direct sanity break-and-revert
  check); every live "ESCO-lite" doc reference across `backend/` swept
  and corrected, including the eval scenario bank and the Career
  Advisor agent's own persisted system prompt.
  All 6 migrations verified end-to-end against a disposable Postgres
  (clean upgrade/downgrade/re-upgrade round-trip); 51 new tests;
  `phase1` gate 104 passed/3 skipped/0 failed unchanged throughout; a
  full raw-suite run's 68 failures confirmed pre-existing and unrelated
  (zero file overlap, spot-checked across 5 failure categories). See
  `docs/sprint_decisions_20260815_large_tier_backlog_summary.md`
  (cross-references all 6 per-item docs).
- **Category 2 hardening — governed per-institution policy calibration
  infrastructure** (2026-08-12, `dlu_builder_tk`, no new G-register
  item): the user's own next pick, continuing the priority order (code
  gaps, then ops/business gaps, then infrastructure) into category 2 for
  the first time. Fresh re-verification confirmed almost all of category
  2 genuinely cannot be substituted for by code (external audit, legal
  sign-off, agent GA gating, live third-party credentials, real
  production PITR all remain exactly as open as before) — but surfaced
  one real, code-shaped gap: per-institution policy calibration was a
  MIXED bag, not a uniform gap. `ItemCalibrationParams`/
  `CompetencyEngineParams` already had a real, governed, versioned,
  institution-scoped-with-global-fallback override mechanism (just never
  populated per-institution); `move_policy_service.RISK_THRESHOLD`,
  `recommendation_service_v2`'s rank weights + `SERENDIPITY_QUOTA`, and
  `consolidation_service`'s salience weights had NO override mechanism at
  all. New `RiskPolicyParams`/`RecommendationPolicyParams`/
  `SalienceWeightParams` (one migration, same immutable-row shape as
  `ItemCalibrationParams`) close that gap — the knob, not the calibration
  decision itself, which remains a genuine steward/institution-authority
  call, unmade for any institution before or after this pass.
  `build_assessment` resolving the new `RiskPolicyParams` rippled into 8
  existing test files (every agent's `run_cycle`/`run_mission` passes
  through it) — found running the full suite, not assumed. Full
  regression clean (12 new tests plus 150 passed across the 8
  ripple-affected files; `phase1` gate: 104 passed, 4 skipped, 0 failed).
  See
  `docs/sprint_decisions_20260812_category2_policy_calibration_hardening.md`.
- **Driver/integration hardening II — small/contained tier from the
  moderate/large backlog** (2026-08-11, `dlu_builder_tk`, no new
  G-register item): continuation of the pass below — re-surveyed the
  deferred moderate/large backlog and found several premises wrong once
  verified: analytics revenue/quality metrics is genuinely large (not
  moderate as first labeled), Moodle grade-passback is smaller than
  "large" (real driver + ID-mapping tables already existed, just
  unpopulated), and the marketing domain isn't a sizing problem at all —
  its routers were never mounted in `main.py`, so its real, routed
  frontend pages have 404'd since they were built (flagged for removal
  per the user's own choice, nothing implemented). GPS `best_career_path`
  premise-corrected and wired onto the existing ESCO-lite seed;
  `lowest_cost` stays an honest gap with its stale "STX-12 brings them"
  reason replaced by the real blocker. New IW5 Steward Console composes
  already-real agent-governance data (scorecards, release-gate history,
  incident queue, an honest calibration-drift gap) behind a narrower role
  gate than IW1-3. New Moodle `assessment.completed` grade-passback
  consumer on the `n8n-bridge` group. A test-infrastructure side-quest
  found and fixed four independent, pre-existing bugs blocking a
  real-Postgres container test run (a `DLU_TEST_PG_URL` clobber, a
  `metadata`/`meta_data` column typo, a dead duplicate SQLite-only DDL
  block, and a missing pgvector test image) — never exercised this way
  before. G7 regulation-year and LTI full JWT verification were
  re-verified and confirmed at their original size, both still deferred.
  Full regression clean (3071 tests collected, 18 more than the prior
  pass's own new tests; `phase1` gate: 104 passed, 4 skipped, 0 failed).
  See
  `docs/sprint_decisions_20260811_driver_integration_hardening_ii.md`.
- **Driver/integration + data/model hardening — small/mechanical tier**
  (2026-08-10, `dlu_builder_tk`, no new G-register item): the user's own
  next pick after agent-governance hardening, scoped to the
  small/mechanical tier only (LTI full JWT verification, analytics real
  SQL, Moodle grade-passback ID-mapping, marketing domain, GPS ESCO
  crosswalk, G7 schema change, and Institution workspaces IW4-6 all
  explicitly deferred). `gateway_config_sync.delete_provider` was a
  no-op — now calls the real gateway `/model/delete`, keyed by
  `provider_id` to match how the provider was registered, wired into
  `soft_delete_provider` post-commit with fail-open error handling.
  `ai_management`'s Test-Skill preview always returned a literal
  MVP-stub string — now a real LLM invocation mirroring the working
  Test-Agent pattern. `graduation.predicted` premise-corrected: its own
  docstring claimed no producer existed, already false when written
  (`gps_worker.recompute_path_health_task` has emitted it since STX-07's
  first commit) — the real bugs were an overly-broad emission gate
  (fired on nearly every recompute, predicting nothing — tightened to
  require completion within 1 term) and a dormant consumer stub, now
  wired to enqueue a real career-gap-refresh task. A critical, unrelated
  bug found first and fixed separately while researching LTI: a live,
  unauthenticated open redirect in `lti_oidc_init` (fixed with a
  same-origin/bare-path allow-list, committed separately). A live decoy
  found during research and separately confirmed for removal:
  `/advisor/dashboard` rendered hardcoded fake KPIs and two fabricated
  named students unconditionally, as if real — replaced with an honest
  not-yet-available state; the real underlying gap (no
  advisor-assignment relationship exists anywhere in this data model) is
  disclosed, not fixed. Full regression clean (3053 tests collected, 19
  more than the prior pass's own new tests; `phase1` CI gate: 104
  passed, 4 skipped, 0 failed, identical to the prior pass's own
  baseline). See
  `docs/sprint_decisions_20260810_driver_integration_hardening.md`.
- **Agent governance hardening — mission-budget gate generalized to all
  9 agents** (2026-08-09, `dlu_builder_tk`, no new G-register item):
  `ace_service.run_mission`'s BOOK-09 Ch. 6 budget check special-cased
  exactly two of the nine DAS agents (`learning_coach`, `student_success`)
  — the other seven had zero volume/rate protection on proactive
  missions. Replaced the `if/elif` ladder so every agent calls
  `mission_budget_service` (quiet hours + a daily-contact cap);
  `learning_coach` alone kept its own dedicated branch through
  `coach_etiquette_service` to preserve an existing test's patchable
  call site. Closes BOOK-09 Ch. 6 point 4 (budget lines) only —
  need-based priority allocation, an equity guardrail, and per-learner
  floors (Ch. 6 points 1-3) remain genuinely unbuilt, documented as such
  rather than implied closed. A real bug found first and fixed
  separately: re-verifying a stale "unreachable in production" docstring
  claim on `synthesize_blackboard` (carried forward, uncritically, into
  a prior hardening pass's own reasoning) found `_act_l4` IS reachable
  since STX-10 and never threaded its own `tenant_id` through — every
  real `consultation_deadlock` proposal was filed with `tenant_id=
  "unknown"`, which that earlier pass's own defense-in-depth check would
  then 404 the twin's own legitimate proposal against. Also corrected an
  initial research premise before acting on it:
  `consolidation_service`'s nightly job makes zero LLM calls (pure
  deterministic token-matching + DB row lifecycle) — applying the
  learner-contact cap gate there would have been a category error, left
  functionally untouched with its docstring corrected instead. Two other
  researched sub-items (per-move calibration + steward alerts;
  misbehaviour escalation ladder) remain open, both converging on the
  same missing piece — a real steward role + review surface — documented
  but not built this pass. See
  `docs/sprint_decisions_20260809_agent_governance_budget_hardening.md`.
- **Consolidation debt hardening — dead code removed, a much bigger
  audit-logging bug fixed** (2026-08-08, `dlu_builder_tk`, no new
  G-register item): deleted two dead-code AI-governance attempts
  (`backend/domains/ai_governance/`, zero migration ever created its
  tables; 6 dead PI-1 models from `models_ai_governance.py`, keeping the
  live `AIProvenance`) and the dead `PagoPAStubDriver` (kept the
  still-live `BolloPaymentStatus` dataclass NEW-12's real driver
  imports). Badge/credential research found a quadruple duplication,
  not the documented triple — deleted the fully-dead
  `backend/domains/badge/` (singular) + its broken frontend
  `BadgeWallet` widget (silently 404ing on every page that rendered it,
  since `badgeAPI.js` called the unregistered plural
  `backend/domains/badges/` route); left the plural domain and
  `services/dlu_badge`-vs-monolith as documented open architecture
  decisions. The real finding: the legacy audit trail was silently
  near-completely broken — nearly every `AuditService.log_action` call
  site never awaited it (an `async def`, silently a no-op),
  `log_action`'s own internal `execute()`/`commit()` calls weren't
  awaited either (no-op with `AsyncSession`, used by `auth.py`'s OIDC
  routes), `AuditLoggingMiddleware` had a permanent `lambda: None`
  session-factory placeholder since it was added, and — found only by
  testing against a real disposable Postgres — the table was missing
  `endpoint`/`http_method` columns in every definition (raw SQL
  bootstrap scripts and the ORM model) and `log_action` hardcoded the
  wrong Postgres metadata column name (`meta_data` instead of the real
  `metadata`, misreading an ORM attribute alias). Fixed all of it,
  adopted `platform.audit_logs` into the Alembic chain (same
  legacy-script-only status as `legal_holds`/`tenant_settings`/
  `rate_limits`), added a nightly partition-maintenance Celery beat job
  (the table's Postgres-native monthly partitioning had no partitions
  past March 2026), and mounted NEW-15's hash-chained audit fabric REST
  API (`backend/api/routes/audit.py`, fully built and tested but never
  mounted) — with `require_admin()` added to every route first, since it
  had none and would otherwise have been a new cross-tenant
  vulnerability (verified live: unauthenticated → 401, non-admin → 403).
  See `docs/sprint_decisions_20260808_consolidation_debt_hardening.md`.
- **Security/tenancy hardening — cross-tenant leakage fuzz cache dimension
  closed** (2026-08-07, `dlu_builder_tk`, no new G-register item):
  `move_proposal_service.store()`'s Redis-backed store carried no
  `tenant_id` anywhere (only `twin_id`/`agent_key`) — added as a required
  parameter, threaded through all 10 production call sites +
  3 test call sites; `ace.py`'s `_require_own_proposal` now checks
  `tenant_id` in addition to the pre-existing `twin_id` check (K3/K4
  hardening pass) — deliberate defense-in-depth, proven via a dedicated
  forged-record test. Also adopted `platform.rate_limits` into the
  Alembic chain (same legacy-script-only status `legal_holds`/
  `tenant_settings` had) — verified end-to-end against a disposable
  Postgres (full migration-chain replay, idempotency re-run, downgrade/
  upgrade round-trip) — and, via that same live-Postgres verification,
  found and fixed a real production bug: `RateLimitService.
  check_rate_limit` compared a timezone-aware Postgres `TIMESTAMPTZ`
  value against naive `datetime.utcnow()`, raising `TypeError` on the
  second call for any identifier+endpoint — would have hard-failed every
  second login/registration/password-reset attempt within a rate-limit
  window in any real deployment, fully masked by mocked unit tests that
  never exercised a real driver. NEW-17's Tier-1 pre-evaluation limiter
  was reviewed for coupling to `RateLimitService` and deliberately left
  self-contained — its business-data-derived rolling-window count has no
  drift risk, and genuine coupling would change actual block semantics
  (a product policy call, not a code gap). Streams dimension of the fuzz
  suite remains open. See
  `docs/sprint_decisions_20260807_security_tenancy_hardening.md`.
- **BOOK-14A** — Credit Recognition & Pre-Evaluation Framework (Italy & USA),
  from the comparative regulatory analysis: jurisdiction **RulePacks**
  (IT-CFU with DM 931/2024 caps 48/24, SSD matching, fraction tolerances,
  obsolescence, ITS/master rules, fees; US-SCH with PLA/CAEL, ACE/NCCRS,
  residency, exclusions), **G16** three-tier pre-evaluation for registered
  non-enrolled prospects (instant AI estimate + council HITL + Validated
  Pre-Evaluation Statement as signed credential), badge-to-credit automation
  (Bestr→ESSE3 pattern on the running OB 3.0 Badge Service), equivalence-
  precedent memory, curricular-drift answer (historic-syllabus endpoint on
  immutable CatalogEditions). Sprint **NEW-17** (K4). Register G1–G16.
- **K5 hardening — Erasure e2e chain closed** (2026-08-05, `dlu_builder_tk`,
  no new G-register item): `erasure_service.request_erasure` finally
  calls `credential_revocation_service.revoke_or_suspend(purge_pii=True)`
  (real since STX-13, zero callers until now) and executes BOOK-06 Ch.
  9.3's full erasure procedure — anchor soft-delete, immediate hard purge
  of L5 (Career)/L6 (Behaviour)/L7 (AI memory + episodic summaries), a
  deferred L3 (Competency) purge (new `purge_after` column + a nightly
  `erasure_purge_worker` — no Book anywhere specifies the actual
  "retention schedule" duration BOOK-06 refers to, so this is a
  documented 30-day default, not a silent guess), a structurally-ready
  L4/Neo4j no-op hook, a Redis move-proposal cache flush, and dual audit
  emission (the DAS hash-chained fabric + the legacy `audit_logs`
  `user.data_delete` action — found to be referenced by
  `compliance_service`'s own GDPR report query but never once emitted
  anywhere before this). Gated on the existing `ComplianceService.
  get_legal_holds` (BOOK-19 RACI: DPO owns retention/erasure exceptions)
  rather than a new approval workflow, which surfaced `platform.
  legal_holds` had existed only via a standalone `sql/compliance_schema
  .sql` bootstrap script, never any Alembic migration — adopted into the
  chain for the first time this pass. A real bug found and fixed while
  wiring `TwinSnapshot`'s new narrow, audited immutability bypass:
  committing the purge AFTER the authorization context manager had
  already exited meant the flush-time `before_delete` listener saw
  authorization already revoked and rejected its own legitimate caller.
  **Same-day follow-up, all three of this pass's own carried gaps
  closed:** the "no twin-owned Neo4j data exists" premise behind the L4
  no-op was found WRONG (`kg_overlay_sync.py` — live, registered on
  `kg-sync`, not dead code — writes real `(:Student {twin_id})` nodes) and
  fixed with a real `DETACH DELETE`, proven against an actual Neo4j
  instance (a new `@pytest.mark.integration` test, not mocked); the
  30-day L3 retention window is now per-tenant overridable via
  `platform.tenant_settings.erasure_l3_deferred_purge_days` (that table
  also adopted into the Alembic chain for the first time, same legacy-
  script-only status `legal_holds` had); a self-service `/student/privacy`
  frontend was built and browser-tested end-to-end (confirm-phrase gate,
  real request round-trip verified server-side, zero console errors). 9
  tests total, full regression clean. See
  `docs/sprint_decisions_20260805_k5_erasure_hardening.md`.
- **CORS preflight fix** (2026-08-04, `dlu_builder_tk`): `CORSMiddleware`
  was registered innermost (added first), so `TenantContextMiddleware`'s
  own OPTIONS short-circuit (a deliberate skip of tenant DB resolution on
  preflight) returned a bare 204 with zero `Access-Control-Allow-*`
  headers — silently breaking any cross-origin dev split of frontend/API.
  Found during NEW-18's own browser-testing pass, fixed same-day by
  reordering `app.add_middleware()` so `CORSMiddleware` is outermost.
  Verified via a standalone `TestClient` script plus a 161-test
  middleware/CORS/tenant/auth regression sweep — zero regressions.
- **NEW-18 executed — closes NEW-17's own carried-gaps note** (2026-08-04,
  `dlu_builder_tk`): Tier-2/registrar (`RecognitionCouncilDesk.js`) and
  badge-rule-authoring (`BadgeCreditRuleAdmin.js`) frontends — neither
  existed, both mirror the established `RegistrarDesk.js`/
  `LLMQuotaRules.js` Table+Modal+Form shape; two new read routes
  (`GET /api/pre-evaluations/registrar-queue`,
  `GET /api/committees?kind=`) the UIs needed; NEW-11's ESSE3 driver now
  consumes `credential.recognized` via a new `push_recognized_credit`
  method + `Esse3CredentialSyncLog` + an `n8n-bridge` consumer
  (`synced`/`no_mapping`/`failed`, the last never raised into the mesh);
  the Tier-1 frontend (`PreEvaluationWorkspace.js`) actually
  runtime-tested in a live browser for the first time — found (and,
  same-day, fixed — see the CORS preflight fix entry above) a
  pre-existing CORS bug; full Tier-1→Tier-2 queue→create/deactivate
  lifecycle exercised live end-to-end. 8 new
  tests, full regression clean. Anti-gaming rate-limit integration,
  `EquivalenceRule` consortium sharing, and the outbound
  historic-syllabus endpoint remain open (NEW-17's own carried debt,
  untouched by this sprint). See
  `docs/sprint_decisions_20260804_new18.md`.
- **NEW-17 executed — G16 resolved, register complete at G1–G16**
  (2026-08-03, `dlu_builder_tk`): `RecognitionRulePack`/
  `CreditPreEvaluation`/`EquivalenceRule`/`ExternalSyllabusRecord`/
  `BadgeCreditRule`. Tier 2 uses a dedicated `RecognitionCommitteeVerdict`
  (NEW-06's `CommitteeVerdict.thesis_id` is `NOT NULL` — concretely
  thesis-coupled despite its forward-looking docstring); reuses NEW-06's
  generic `Committee`/`CommitteeMember` formation only. Validated
  Pre-Evaluation Statement issued via STX-13's `_sign_and_persist`
  directly. Conversion executes the already-decided verdict at
  enrollment — no re-evaluation. Badge auto-convalida matches STX-13's
  live `credential_templates`, not the two dead badge implementations.
  25 tests green; migration verified up/down/up; full regression clean
  (`pytest -m phase1` stable at 104/3; combined NEW-17+STX-12+NEW-06+
  STX-13+NEW-16+STX-14/15: 108 passed). K4 pack now fully delivered
  (7/7 items — see `implementation/roocode/K4/README.md`).
- **K1 phase completed** in `dlu_builder_tk` (STX-01…05 ✅ per sprint status
  notes): twin core + identity_map, TwinContextService, Event Mesh,
  Competency Engine, KG v2.0 + `dlu-core.yaml`.

- **K2 prompt pack generated** (2026-07-16, post K1 exit gate):
  `implementation/roocode/K2/` — README (order: NEW-01 → STX-06 → NEW-03,
  NEW-02 in parallel as the GA gate; exit gate per TRACEABILITY K2 row) +
  self-contained prompts NEW-01 (move catalog binding, BOOK-09 Ch. 3 /
  BOOK-10 Ch. 2), STX-06 (PDDAEL runtime + one voice + Discovery + WS00
  triad, BOOK-09 / BOOK-17), NEW-02 (scenario bank + 3 grader tiers +
  lifecycle gate + crisis protocol zero-tolerance, BOOK-11 Ch. 5–6),
  NEW-03 (M1–M4 memory stores + consolidation R8 + consent amnesia,
  BOOK-12). Combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K2_PROMPTS.md`.
  Implementation may begin with NEW-01 (‖ NEW-02).

- **STX-05 executed — K1 COMPLETE** (2026-07-16, `dlu_builder_tk`):
  Knowledge Graph v2.0. Idempotent Cypher migration (`make kg-migrate`):
  A8 `REQUIRES`→`NEEDS_ASSET`, A9 →`ALIGNED_TO {strength}` (aliases
  flagged one minor release), v2.0 label constraints, `SchemaMeta` stamp.
  Student overlay via batched `kg-sync` consumers (KNOWS/EVIDENCES,
  DEFER-flush ≤100/pass, ack-after-flush, tenant-scoped). Definition-tier
  Competency/Framework sync (fire-and-forget preserved). **Ontology
  registry seeded**: `architecture/ontology/dlu-core.yaml` + lint in both
  repos' CI; A1-S1 staging gate live. `frontier`/`gap` canonical queries.
  V1–V7 green (incl. live-Neo4j idempotency/parity/tenant-fuzz and
  250-events→≤3-flushes batching). Registers: A1-S1 ✅, A8 ✅, A9 ✅.
  **All five K1 sprints delivered — K1 exit report can be assembled.**

- **STX-04 executed** (2026-07-15, `dlu_builder_tk`): Competency Engine.
  Deterministic §5.3 confidence (`Σ score·weight·recency·trust / Σ weight`)
  with versioned, immutable `competency_engine_params` seeded from BOOK-15
  §4.1; status machine with decay hysteresis → `expired` checkpoint (daily
  beat); `verified` = HITL `verify()` only (ADR-0012, negative-tested);
  `register_evidence` as the single writer entrypoint (STX-08 intake);
  CASE 1.1 idempotent import + round-trip export preview; student rows pin
  `framework_version` (Review M1); `/api/competencies` routes +
  `competencyAPI.js`; all mutations emit `competency.updated/mastered`,
  `evidence.recorded` via the STX-03 outbox. V1–V6 green (8 golden cases
  ≤1e-6). BOOK-04 C4 and BOOK-06 L3 Annex rows → ✅.
  K1 remaining: STX-05.

- **STX-02 executed** (2026-07-14, `dlu_builder_tk`): TwinContextService —
  the single door to student context. Purpose-audited reads, BOOK-06 Ch. 6
  entitlement matrix enforced in code (data-driven, denials audited),
  consent gating (Ch. 9, learner_self bypass per the Open Learner Model),
  per-layer version-keyed Redis cache, immutable `twin_snapshots` on
  lifecycle transitions, `/api/twin` routes (tenant-scoped), tutor context
  adapter with zero regression, `consent.changed` producer wired to the
  STX-03 mesh, twin-sync consumer now routes through
  `bump_version_sync`. V1–V6 green; BOOK-06 Annex A context-service and
  snapshot rows → ✅; constitution §4.4 marked implemented.
  K1 remaining: STX-04, STX-05.

- **STX-03 executed — THE KEYSTONE** (2026-07-14, `dlu_builder_tk`):
  Academic Event Mesh delivered. Transactional outbox `domain_events`
  (migration `20260714_1100`), closed taxonomy consolidating constitution
  §7.3 + BOOK-04 Ch. 7 (41 types, `event_taxonomy.py` — EVENT_CATALOG.md
  superseded for kernel events), Redis Streams relay (2 s beat, ≥7-day
  XTRIM retention), 5 consumer groups with exactly-once side effects,
  XAUTOCLAIM recovery, dead-letter stream and Prometheus lag alerting.
  twin-sync wired (`profile.updated` → twin_version bump); producers:
  mastery.updated, activity.recorded, course.* (governance workflow),
  legacy EventService dual-publish (strangler). OTel trace propagated
  producer → consumer via span links. V1–V7 green; register A6 closed;
  BOOK-03 Annex A Event Mesh row → ✅. Design decisions:
  `dlu_builder_tk/docs/sprint_decisions_20260714_stx03.md`.
  Next: STX-04 and STX-05 unblocked (STX-02 still pending).

- **STX-01 executed** (2026-07-14, `dlu_builder_tk`): Student Twin core
  models + Competency Graph tables + identity reconciliation. **ADR-0014**
  accepted — identity reconciliation Option A (additive `user_guid` +
  backfill + dual-write; mapping exclusively in
  `backend/services/identity_map.py`). Constitution §13.4 marked
  "decided: Option A". V1–V6 green; reconciliation report at
  `dlu_builder_tk/reports/stx01_identity_reconciliation.json` (100%
  matched, 0 orphans). Next: STX-02 (STX-03 may run in parallel).

- **G15** (catalog as legal contract + explorable what-if representation):
  `CatalogEdition` aggregate (04), `simulate_scenarios` GPS mode (14),
  catalog legal document (16 §6.4a), public explorer + FW1 authoring (17),
  sprint **NEW-16** (20); register now G1–G15.
- **K1 prompt pack generated**: `implementation/roocode/K1/` (README +
  STX-01…05 self-contained prompts with V-suites, dependencies, exit gate);
  combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K1_PROMPTS.md`.
  Implementation phase may begin with STX-01 (‖ STX-03).

## 1.0.0-draft (das-v1.0-draft) - 2026-07-14

### The Masterbook — complete

- **BOOK-00 v2.0** — Executive Vision & Manifesto: conformance model
  (DAS-Core/Intelligent/Certified), RFC 2119 normative language, Seven
  Canonical Questions, manifesto principles with tensions, 13 ADRs, expanded
  standards alignment (1EdTech, EU AI Act), Human Institution / Trust &
  Integrity / Viability chapters, full 20-book plan, **Annex A Turnkey
  baseline** (descriptive-where-running doctrine, source-of-content rule).
- **BOOK-01…20 v1.0** — full Masterbook per the BOOK-00 Ch. 16 plan:
  philosophy (01), institution theory (02), AOS (03), domain model (04),
  ontology (05), twin trilogy (06/07/08), AI spine (09/10/11/12),
  knowledge network (13), GPS (14), assessment & evidence (15),
  credentials & trust (16), experiences (17), technical/Turnkey integration
  (18), governance/security/compliance (19), implementation blueprint (20).

### Registers

- **A-register A1–A12** (structural/semantic anomalies) — all declared and
  closed with owners (incl. A8 `REQUIRES` collision, A9 alignment naming,
  A10–A12 FEX v1.3 bindings).
- **G-register G1–G14** (regulatory/functional gaps from ESSE3, ANVUR and US
  accreditation verifications) — all resolved or owned: appelli (G2), thesis
  (G5), committees (G6), regulation-year (G7), ANS/SUA-CdS (G8), certificates
  (G9), Diploma Supplement (G10), clearance (G11), **US RSI (G12)**, identity
  verification (G13), **ANVUR DE/DI telematic regime (G14)**.
- **Sprint set** STX-01…15 + NEW-01…15 in phases K1–K5 with verification
  cards and conformance exit gates (BOOK-20).

### Review & remediation

- **MASTERBOOK-REVIEW v1.0** — independent critical review (completeness,
  internal/external consistency): verdict *approved with reservations*;
  blocking findings **R1** (event-taxonomy registration: session/thesis/
  committee families) and **R2** (G14 DE/DI) **applied**; R4/R5 scheduled
  into K1 scopes.

### Catalog annex

- **BOOK-10A** — AI Workforce, Skills & MCP Catalog: exhaustive phased roster
  (24 agents across student/faculty/institutional/ops domains, 44 typed skills
  in 12 categories, 19 MCP servers internal/generic/external), usage modes
  (scoping, preset classes, quota classes), seeded-to-target mapping for the
  running `ai_university_defaults` (3 MCP servers, 10 skills, 4 agents),
  bilingual and least-privilege doctrines. Prerequisite refinement for the K1
  prompt pack.

- **BOOK-10B** — AI Execution Framework: three-plane model
  (definition/execution/observation), resolution pipeline with `ctx_hash`
  reproducibility token, skill execution engine, MCP integration layer
  (session manifests, server-side entitlements, circuit breakers),
  declarative mission runtime (generalizing the running orchestrator),
  five-tier testing (T1–T5 on mock-LLM/test-endpoints/harness/test-tenant),
  governed deployment with canary/shadow and seconds-scale kill switch, and
  the **unified execution record** (one query = full causal story; learner
  "why?" and auditors read the same records). Explicit ACP reuse-vs-extend
  map — the running control plane is the foundation.

### Apparatus (R3)

- `MASTERBOOK-INDEX.md` — volume map, reading paths, the Five Ideas.
- `TRACEABILITY.md` — G/A/sprint/conformance cross-matrix.
- `GLOSSARY.md` — unified normative glossary (≈130 terms).
- `scripts/sync-masterbook.sh` + `docs/masterbook/` — MkDocs rendering of the
  Masterbook (generated copies; root is source of truth).
- MkDocs nav: Masterbook section wired.

### Cross-repo (sync rule)

- `dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` (Turnkey
  implementation profile) amended in lockstep: A8 prerequisite canonicalization
  (`PREREQUISITE_FOR`), event-taxonomy additions (R1).

## 0.1.0 - 2026-07-12

- Created the initial DLU Architecture Standard repository.
- Added MkDocs Material configuration.
- Added initial manifesto, architecture-standard, reference-architecture and Turnkey sections.
- Added ADR, RFC, workspace and RooCode scaffolding.
