# BOOK-24 — Executive Command & Corporate Governance
### DAS v0.1-draft · Layer: Institution / Governance · Status: IMPLEMENTED (SPRINT-14/25 policy+catalog-approval, SPRINT-15/26 KPI layer, SPRINT-16/27 board governance — G20 FULLY CLOSED; corrected from stale "DRAFT" SPRINT-22 doc-sync, 2026-08-01; Provost persona pass — SPRINT-23, 2026-08-07 — closed the "ILO coverage" gap and added Catalog Certification — see TRACEABILITY.md G20)

> Closes **G20** (role-grade command dashboards for Provost / President / Chairman / CFO,
> a historicized KPI layer, board governance, and the formal catalog/policy approval
> workflows are absent). Extends IW1 (Rector's Bridge, BOOK-17) from a view into a
> governed command system. ER target domains: **T10, T6**. Functionality areas: **21, 24**.

---

## 1. Purpose and scope

Oversight MUST be *active*: leadership sees historicized indicators, receives threshold
alerts, and acts through recorded governance actions — ratifications, promulgations,
freezes, teach-outs — that are themselves events in the mesh. Experiences own no state
(BOOK-03): every dashboard is a view over T10/T6 aggregates.

## 2. The KPI layer (T10)

`kpi_definitions` (catalog, per domain: academic, finance, marketing, HR, operations, AI)
→ `kpi_targets` (period targets + red thresholds) → `kpi_snapshots` (historicized
measures, dimensioned). Rules:

- R24.1 Snapshots are computed from mesh events and domain aggregates on schedule;
  dashboards never compute KPIs ad hoc (no "excel drift").
- R24.2 A snapshot breaching a red threshold emits `KpiBreached` → `executive_alerts`
  with severity; alerts require acknowledgement (owner role recorded).
- R24.3 The three-economy instrumentation (BOOK-08) publishes into this layer — one KPI
  system, not two.
- R24.4 ACE briefs (`ace_session_summaries`) attach to snapshots as narrative context
  (propose-only; BOOK-10 contract cards apply).

> ✅ **IMPLEMENTED (NEW-26, SPRINT-15, 2026-07-31):** the KPI data layer above is now real
> (`dlu_builder_tk`, T10, 5/7 tables — `kpi_definitions`→`kpi_targets`→`kpi_snapshots`,
> `executive_alerts`, `kpi_snapshot_briefs`). 8 per-domain compute functions
> (`kpi_compute_service.py`) cover admissions funnel conversion, pre-evaluation turnaround
> and an honest accuracy PROXY (1 − HITL override rate — the certified eval-harness accuracy
> figure lives only on an unmerged branch, confirmed absent here), AR aging over 90 days,
> budget-vs-actual utilization, the workload/mentorship dividend (reuses `hr_service.
> workload_summary` directly), and the AI agent deployment rate (reuses `steward_console_
> service.compute_steward_console`'s `n_deployed`/`n_agents`, deliberately never its
> `calibration_drift`, itself an honest, still-open gap with no drift-monitor computation
> anywhere in this codebase). A single nightly `kpi_publisher_worker.run_nightly` job is the
> ONLY writer of `kpi_snapshots` — R24.1 ("dashboards never compute KPIs ad hoc") is
> structural, not a convention: `publish_snapshot_for_kpi` skips a KPI entirely (no
> fabricated zero) when its compute function has no signal yet. A snapshot breaching its
> period's red threshold creates an `ExecutiveAlert` (severity by overshoot heuristic) and
> emits the already-reserved `KpiBreached` (R24.2) — an unacknowledged `critical` alert
> re-emits the SAME event with `escalated: true` after `ESCALATION_SLA_DAYS`, the identical
> silence-then-emit shape `nudge_service.py` already established, never suppressed by
> anything else. R24.3 (three-economy instrumentation publishing into this layer) is honored
> narrowly and honestly: only the one confirmed-real leaf of `three_economies_service.
> compute_three_economies` (`attention.faculty_load_balance.coefficient_of_variation`)
> publishes; every other leaf of that composite is still `not_yet_available` and this sprint
> does not fabricate a rollup across them. **Found a real naming collision correcting R24.4
> as written above**: `ace_session_summaries` is NOT reusable for KPI briefs — it is a real,
> already-populated, per-STUDENT episodic-memory table (BOOK-12 Ch. 2), unrelated to
> executive KPIs; built the genuinely new `kpi_snapshot_briefs` instead (templated, not
> LLM-generated — an honest v1 simplification, same discipline `consolidation_service.
> close_session` already established for that other table). Of §6's event list, only
> `KpiBreached` is emitted this sprint (it was already reserved since SPRINT-01/NEW-17f
> scaffolding); `KpiSnapshotTaken`/`AlertAcknowledged`/`GovernanceActionTaken`/
> `BoardResolutionPassed` are not yet reserved or emitted anywhere — an honest, disclosed
> gap, not a silent omission. `governance_actions` (§5) and board governance remain target —
> SPRINT-16/NEW-27, per SPRINT-14's own callout above. Mounted at `/api/executive` (no
> collision with the pre-existing, unrelated `/api/v1/analytics/dashboard/executive`). C24.4
> (breach-to-alert latency, escalation) and C24.5 (KPI recomputability within tolerance) are
> this sprint's own DoD, both verified by 18 new conformance tests; C24.1-C24.3 are T6
> concerns already closed by SPRINT-14.

## 3. Role command surfaces (views, not stores)

| Surface | Role | Reads | Acts | EKG usage / RKG maintenance (BOOK-19 §1.2, RFC-0002) |
|---|---|---|---|---|
| President Bridge | president/rector | full scorecard, three economies, red postures | ratify teach-outs, governance actions | thin (BOOK-17 IW1); none new |
| Chairman Board Pack | chairman/board | resolutions pipeline, risk register, compliance posture (BOOK-19) | convene, resolve | thin; none new |
| Provost Command | provost | academic health, pending approvals (catalog, policies), ILO coverage, Catalog Certification | approve, promulgate, certify catalog | usage: `PRO-01…05` (Academic Control Tower, Portfolio Comparison, Institution Outcome Attainment, Quality & Assurance, Employability Alignment); maintenance: institution-wide `PolicyVersion` approval, **Catalog/Ontology Certification** (extends `certify_catalog` below, ADR-0021), RFC/ontology sign-off |
| CFO Command | cfo | AR/AP aging, cash, budget-vs-actual, **planning & control views: forecasts, cash-flow projections, scenarios, period closes, variances (BOOK-23 Ch. 8)**, engagement commitments; narrative support by the propose-only CFO Analyst agent (BOOK-10A Annex T) | approve payment runs, sign engagements, close periods, act on variances | none new |
| HR Command | hr lead | positions, contracts, workload ledger, mentorship dividend (BOOK-22) | open positions, flag capacity | none new |
| MKO Funnel | marketing | intake funnel (BOOK-21), campaign attribution (CRM) | tune campaigns | none new |

> ✅ **IMPLEMENTED (NEW-27, SPRINT-16, 2026-07-31):** all 6 surfaces above are real
> (`dlu_builder_tk`), re-pointed from the OLD `analytics_kpi_*`/`/api/v1/analytics/*` system
> (which had ZERO consumers of the T10 KPI layer before this sprint) to the REAL SPRINT-15/16
> `/api/executive/*` API, and Paper-migrated (`ds/KpiCard`/`ds/AuditTimeline` — antd `KPIGrid`/
> `TrendChart`/`ConversionFunnel` removed). Several prior widgets were hardcoded sample data
> (a fake "Enrollment Conversion Funnel," "Collection Health," "System Health," quality-score
> gauges) — dropped rather than carried forward as real. President Bridge shows the KPI
> scorecard + open alerts; Provost Command (was "Rector's Bridge") adds a genuinely new
> "pending approvals" composite (`GET /api/academic-governance/pending-approvals` — no such
> tenant-wide listing existed before) alongside its pre-existing real program-health/three-
> economies/red-posture content.
>
> ✅ **CLOSED (Provost persona pass, SPRINT-23, 2026-08-07):** "ILO coverage" — a real
> `compute_ilo_coverage_pct` KPI (`academic` domain, `kpi_compute_service.py`) walks the exact
> `ILO`→`PLOtoILO`→`PLO` chain this note originally deferred, reusing the alignment-query shape
> already proven in `compliance_posture_service._claim_outcome_alignment_chain` — a real,
> honest number (0.0% on the demo tenant today, never fabricated). The same pass also gave
> Provost genuine write access to the six responsibilities a real Provost holds — set ILOs,
> co-author PLOs with Deans (`PLOEditor.js`, already built, just never role-permitted for
> `provost`), choose Deans (`AcademicStructure.js`'s `dean_user_id` appointment, now also
> genuinely grants the `dean` role, not just the FK), define the Academic Calendar
> (`TermManager.js`), author the Academic Catalogue's course list and reference credits (a
> genuinely new `ProgramCoursesEditor.js` tab — modeled and readable via `ProgramCourse`
> before this pass, but with no editor anywhere), and a new formal **Catalog Certification**
> action (`certify_catalog`, an additive `governance_actions` type, BOOK-24 §5) — the durable,
> audited artifact standing in for representing the institution before the Government
> Education System, honestly scoped as an internal certification record, not a fabricated
> external Ministry integration. `GET /api/institution/dashboard` also had no server-side role
> check at all before this pass — a real, independent access-control gap, fixed alongside.
> See `docs/demo/SCENARIO-provost.md` (`dlu_builder_tk`) for the full, re-recorded walkthrough.
>
> CFO Command shows the 2 real finance KPIs (AR aging, budget utilization) plus
> read-only budget-line commitment detail (reusing the pre-existing `budgetAPI.js`/
> `budgets.py`, SPRINT-09) — **cash position, AP aging, and the BOOK-23 Ch. 8 planning &
> control views are NOT built this sprint**, an honest, disclosed gap (no such computation
> exists anywhere in this codebase); HR Command is the pre-existing, already-Paper
> `OrganicoWorkloadDesk.js` (SPRINT-10) with one additive `ds/KpiCard` for the historized
> mentorship-dividend KPI, never a replacement of its live ledger UI; Chairman Board Pack and
> MKO Funnel are genuinely NEW pages (§5's board governance + the admissions-funnel-
> conversion KPI respectively) — neither existed in any form before this sprint. None of the
> 6 pages has a live navigation entry (URL-only) — a pre-existing condition shared by nearly
> every dashboard in this codebase, not something this sprint's scope covers.

## 4. Approval workflows (T6)

**Catalog edition approval (extends G15).** Every `catalog_editions` submission opens a
`catalog_approval_workflows` with ordered `catalog_workflow_steps` (typically
dean → provost → registrar-publish). Steps MAY require qualified signature
(`catalog_step_signatures` → QES). On completion the edition becomes the legal document
credential (G15) and is immutable; rejection returns to authoring with recorded reasons.

**Institutional policy lifecycle.** `institution_policies` → `policy_versions`
(regulation-year bound, G7) → `policy_approvals` (provost) and, where statute requires,
`board_resolutions`. Promulgation emits `PolicyPromulgated`; program versions bind to
policy versions per cohort — students are always governed by the policy set of their
regulation year (G7 honored end-to-end).

**Board governance.** `board_meetings` → `board_resolutions` (typed: policy, catalog
ratification, teach-out, budget). Resolutions link to the objects they govern; a
resolution without its object reference is invalid.

> ✅ **IMPLEMENTED (NEW-25, SPRINT-14, 2026-07-31):** the catalog edition approval and
> institutional policy lifecycle paragraphs above are now real (`dlu_builder_tk`, T6, 9/9
> tables). `CatalogEdition.status` gains `pending_approval`; the ordered `catalog_workflow_
> steps` (dean→provost→registrar_publish, same shape as `EngagementSignature`) is the ONLY
> path to `'effective'` — `publish_edition` itself is unchanged (an additive `initial_status`
> parameter, default identical for every existing caller), so C24.2 ("no publish without a
> complete workflow") is a structural guarantee, not a policy. `policy_versions.regulation_
> year` binds to a NEW `program_versions.regulation_year` column (didn't exist before this
> sprint) via a partial unique index — at most one `'approved'` policy version per
> `(policy, regulation_year)`, so C24.3 ("students always governed by the policy set of
> their regulation year") is a real DB constraint. `board_meetings`/`board_resolutions`/
> `governance_actions` (§5 below) remain target — a different domain (T10 Executive
> Command, SPRINT-16/NEW-27) this sprint deliberately does not touch or fabricate; a program
> review's `recommended_action` (e.g. `"teach_out"`) is stored as a plain informational
> string, ready for that future domain to consume, never a soft ref to a table that doesn't
> exist yet. Mounted at `/api/academic-governance` — `/api/governance` was already
> `ai_governance.py`'s prefix (AI Governance & LLM reporting), a real naming collision found
> while wiring the route, not a pre-flight gap.

> ✅ **IMPLEMENTED (NEW-27, SPRINT-16, 2026-07-31):** "Board governance" above is now real
> (`dlu_builder_tk`, T10, 3 tables: `governance_actions`, `board_meetings`,
> `board_resolutions`). `board_resolutions.affected_object_type`/`_id` are a real DB `NOT
> NULL` guarantee — "a resolution without its object reference is invalid" is structural, not
> a service-layer check (proven by a raw ORM-bypass insert in the conformance suite, the same
> technique SPRINT-14 used for C24.3's partial unique index). **Design decision, deliberately
> conservative**: SPRINT-14's own `PolicyVersion`/`CatalogEdition` state machines are already
> terminal (`'approved'`/`'effective'` are already the real, effective states) with no "board"
> slot anywhere in their closed transition sets — retrofitting an upstream board gate onto
> already-shipped, tested SPRINT-14 workflows was out of scope; passing a `policy`/`catalog_
> ratification`/`teach_out` resolution is therefore a DOWNSTREAM ratification/audit record
> only, never an upstream gate. The ONE exception: passing a `budget` resolution DOES advance
> real domain state (`Budget.status: draft → active`) — the one type among the four with a
> real, not-yet-otherwise-reachable state to advance to. Every `pass_resolution` call also
> inserts a linked `governance_actions` row, unifying the write-path (C24.1) whether a
> decision originates from a standalone governance action or a board resolution.

## 5. Governance actions

`governance_actions` records every executive act (ratify / freeze / escalate / teach_out)
with actor, role, rationale, and affected object. Actions are the *only* write path from
command surfaces into the domain — dashboards remain read-only otherwise.

> ✅ **IMPLEMENTED (NEW-27, SPRINT-16, 2026-07-31):** real (`dlu_builder_tk`). Rationale is
> ALWAYS required (unlike `ds/AIProposalCard`, which only gates `reject` — a dedicated form
> was built instead of forcing that component's existing contract). `affected_object_type`/
> `_id` are an OPTIONAL soft ref here (unlike `board_resolutions`' mandatory one) — some
> action types (e.g. a broad `freeze`) may legitimately name no single object; when given,
> existence is validated per type (`program_review`/`policy_version`/`catalog_edition`/
> `budget`) against the real table, service-layer, same "soft ref, service-validated"
> discipline as `Invoice.manual_override_by`. C24.1 (no dashboard write outside this path) is
> verified by a static route audit against an explicit allowlist, not just a fixture.

## 6. Events (A6-closed)

`KpiSnapshotTaken`, `KpiBreached`, `AlertAcknowledged`, `GovernanceActionTaken`,
`CatalogEditionApproved`, `PolicyPromulgated`, `BoardResolutionPassed`.

## 7. Conformance checks

- C24.1 Property: no dashboard endpoint issues writes except through
  `governance_actions` or workflow-step decisions.
- C24.2 Fixture: catalog edition published without completed approval workflow → MUST fail.
- C24.3 Property: a student's applicable policy set resolves uniquely from
  (cohort, regulation_year) — G7 routing constraint test extended.
- C24.4 ✅ **Verified SPRINT-15/NEW-26** (citation was missing, behavior already covered —
  corrected SPRINT-22.md "Correzioni al piano" #9) Alert SLO: breach-to-alert latency bounded
  (by construction zero — the same transaction that writes the breaching snapshot creates the
  alert); unacknowledged critical alerts escalate per policy —
  `tests/conformance/test_kpi_executive_alerts.py::test_breach_creates_alert_and_emits_event` +
  `::test_escalation_sweep_escalates_stale_critical_unconditionally`.
- C24.5 KPI reproducibility: any snapshot recomputes from the event mesh within
  tolerance (event sourcing discipline, `domain_events`).

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Dashboards | `ExecutiveDashboard`, `FinanceAnalyticsDashboard`, `MarketingDashboard`, `OperationsDashboard`, `QualityDashboard`, `RectorBridge` (IW1) | re-pointed to T10 KPI layer |
| Program health | BOOK-08 instrumentation, `analytics` routers | publishes into `kpi_snapshots` |
| Catalog editions | `catalog_editions` (G15 ✅, NEW-16) | + approval workflow (T6) |
| QES | `qes_signature_ref` | step signatures |
| Audit | `audit_logs`, `domain_events` | governance actions audited |
| New tables | — | T10: 7 tables; T6: 9 tables |
| Sprint | — | proposed **NEW-22** (KPI layer + alerts), **NEW-23** (approval workflows + board) |
| Register | — | add **G20** to TRACEABILITY gap register |


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Cross-cutting alignment only. See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
