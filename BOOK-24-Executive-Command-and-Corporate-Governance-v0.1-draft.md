# BOOK-24 — Executive Command & Corporate Governance
### DAS v0.1-draft · Layer: Institution / Governance · Status: DRAFT (target-state extension)

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

## 3. Role command surfaces (views, not stores)

| Surface | Role | Reads | Acts |
|---|---|---|---|
| President Bridge | president/rector | full scorecard, three economies, red postures | ratify teach-outs, governance actions |
| Chairman Board Pack | chairman/board | resolutions pipeline, risk register, compliance posture (BOOK-19) | convene, resolve |
| Provost Command | provost | academic health, pending approvals (catalog, policies), ILO coverage | approve, promulgate |
| CFO Command | cfo | AR/AP aging, cash, budget-vs-actual, **planning & control views: forecasts, cash-flow projections, scenarios, period closes, variances (BOOK-23 Ch. 8)**, engagement commitments; narrative support by the propose-only CFO Analyst agent (BOOK-10A Annex T) | approve payment runs, sign engagements, close periods, act on variances |
| HR Command | hr lead | positions, contracts, workload ledger, mentorship dividend (BOOK-22) | open positions, flag capacity |
| MKO Funnel | marketing | intake funnel (BOOK-21), campaign attribution (CRM) | tune campaigns |

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

## 5. Governance actions

`governance_actions` records every executive act (ratify / freeze / escalate / teach_out)
with actor, role, rationale, and affected object. Actions are the *only* write path from
command surfaces into the domain — dashboards remain read-only otherwise.

## 6. Events (A6-closed)

`KpiSnapshotTaken`, `KpiBreached`, `AlertAcknowledged`, `GovernanceActionTaken`,
`CatalogEditionApproved`, `PolicyPromulgated`, `BoardResolutionPassed`.

## 7. Conformance checks

- C24.1 Property: no dashboard endpoint issues writes except through
  `governance_actions` or workflow-step decisions.
- C24.2 Fixture: catalog edition published without completed approval workflow → MUST fail.
- C24.3 Property: a student's applicable policy set resolves uniquely from
  (cohort, regulation_year) — G7 routing constraint test extended.
- C24.4 Alert SLO: breach-to-alert latency bounded; unacknowledged critical alerts
  escalate per policy.
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
