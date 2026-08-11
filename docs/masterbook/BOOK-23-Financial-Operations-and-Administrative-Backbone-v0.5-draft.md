# BOOK-23 — Financial Operations & Administrative Backbone
### DAS v0.5-draft · Layer: Institution / Delivery · Status: IMPLEMENTED (Ch. 2-4 and Ch. 8, T7 complete + T8) — remaining gaps disclosed inline (§2 R23.3 credential-issuance hold gate + GPS route-constraint read, §7 C23.4 certificate-from-dossier)
*(v0.2: adds Ch. 8 — Financial Planning & Control, sprint NEW-30 — still target, not built.
v0.3: SPRINT-05/NEW-19 implements the AR slice (Ch. 2, minus R23.1's automatic trigger) and
the full student dossier (Ch. 5, T8) — see Annex A for exactly what is real vs. still target.
AP/budgets (Ch. 3–4, NEW-20b) and Ch. 8 planning & control (NEW-30) remain entirely target.
v0.4: SPRINT-09/NEW-20b implements the AP slice (Ch. 3) + budgets with real commitment
accounting (Ch. 4) — T7 now 9/9 tables complete. Ch. 8 planning & control (NEW-30) remains
entirely target — see Annex A for what changed.
v0.5: SPRINT-18/NEW-30 implements Ch. 8 in full (`fee_schedules`, `revenue_forecasts`,
`cashflow_projections`, `financial_scenarios`, `period_closes`, `variance_analyses` — all 7
tables) — closes R23.1's automatic-invoice gap for real (`ApplicantMatriculated` already
existed since SPRINT-06/NEW-18; it just had nothing priced to trigger — `fee_schedules`
is that missing piece) and R23.6/C23.7/C23.8. Also corrects two stale §2/§5 claims found
while updating this same file: "no `ApplicantMatriculated` event exists" was already false
before this sprint (SPRINT-06/NEW-18 built it), and student-dossier auto-creation at
matriculation was likewise already real (same sprint) — neither was ever gated on this
sprint's own work; both are fixed below rather than left to compound further.)*

> Closes **G19** (native invoicing, reconciliation, budgets and the student administrative
> dossier are absent — today they live only in the external ERP and PagoPA rails).
> ER target domains: **T7, T8**. Functionality area: **22** (target tree).

---

## 1. Purpose and scope

The university MUST own a native financial and administrative record, with external rails
(PagoPA, ERP/Frappe, banks) treated as **drivers** (BOOK-03 semantics): they execute and
confirm, they are never the system of record for academic-financial state.

Out of scope: subscription billing of the platform tenant itself (existing `subscriptions`),
payroll (ERP driver), treasury.

## 2. Receivables — the student side (AR)

✅ **Implemented SPRINT-05/NEW-19** (table `student_invoices` — not `invoices`, see Annex A for
why) `+invoice_lines` are first-class: tuition, fees, stamps. Lifecycle:
`draft → issued → paid | overdue → cancelled` (`backend/services/finance_service.py`). Rules:

- R23.1 ✅ **Implemented SPRINT-18/NEW-30**: `matriculation_service.matriculate_applicant`
  (`ApplicantMatriculated`, real since SPRINT-06/NEW-18 — this file's own v0.3/v0.4 text
  wrongly said the event didn't exist yet; corrected here) now prices and issues the
  applicant's first tuition invoice automatically via
  `fee_schedule_service.create_tuition_invoice_from_fee_schedule`, resolving the
  program/academic-year's effective `fee_schedules` row (Ch. 8 §8) — raising
  `FeeScheduleError` rather than fabricating a price if none resolves (C23.6). A staff
  member can still create a non-tuition invoice directly (`POST /api/invoices`,
  `finance_service.create_invoice`, honest `INV-<uuid4>` numbering, unchanged) for stamps/
  late fees/other one-offs unrelated to a program's priced schedule.
- R23.2 ✅ Payment confirmation arrives only via reconciliation:
  `payment_reconciliations` matches PagoPA positions (`pagopa_payment_position`) and/or
  ERP receipts (`frappe_sync_jobs`); manual "mark as paid" requires role `cfo` (or `admin`/
  `super_admin`) and a non-empty reason (`finance_service.manual_mark_paid`). C23.1 verified
  (property test, `tests/conformance/test_finance_invoices.py`).
- R23.3 ✅/⚠ `administrative_holds` (type `financial`) blocks career acts — but only
  **enrollment in exam sessions** is wired this sprint (`assessment_session_service.enroll`,
  C23.3, same transaction boundary); credential issuance does not yet call
  `holds_service.check_credentials_allowed` (the function exists and is tested, just has no
  caller yet — future sprint). The reactive link "`overdue` invoice → hold raised automatically"
  is also **not yet wired**: `finance_service.mark_overdue` emits `InvoiceOverdue` and
  `holds_service.raise_native_financial_hold` exists and works, but nothing calls the latter in
  reaction to the former yet (both modules' own docstrings name this a future scheduled-sweep
  job) — today a hold is raised only by direct/manual call. The GPS does **not** yet read
  `administrative_holds` as a route constraint (BOOK-14 integration remains target).
  `administrative_holds` is also the unification point for 3 previously-incompatible
  "financial hold" concepts (native/Stripe/Frappe) — see `ER_MAP.md` "Finanza & Fascicolo" for
  the full finding.
- R23.4 ✅ Every invoice state change emits `InvoiceIssued` / `InvoicePaid` /
  `InvoiceOverdue` (A6-closed, `backend/services/event_taxonomy.py`).

## 3. Payables — the faculty side (AP)

✅ **Implemented SPRINT-09/NEW-20b** (`supplier_invoices`/`supplier_invoice_lines`/
`payment_runs`, `backend/services/ap_service.py`). `supplier_invoices` are generated
exclusively by `generate_supplier_invoice_from_milestone` — a REAL, NOT NULL FK
(`milestone_id -> engagement_milestones.id`, `models_finance.py`) makes R23.5 ("an AP
invoice without a matching approved milestone is structurally impossible") true at the DDL
level, not just a conformance check; the function additionally requires
`milestone.status == 'approved'` (defense in depth). `MilestoneApproved` (BOOK-22) IS
emitted at that point, but generation itself is an explicit follow-up call, not an event
subscriber — correction, see BOOK-22 v0.3 §2. `payment_runs` batch `pending` invoices;
approval requires `finance_service.CFO_ROLES` (reused, not a new `cfo`-only check);
execution is a MOCK driver (`_mock_execute_payment_run` — no real banking/ERP integration
this sprint, as this chapter's own "mock ok" already anticipated).

## 4. Budgets

✅ **Implemented SPRINT-09/NEW-20b** (`budgets`/`budget_lines`, same file/service).
`AuthoringEngagement.budget_line_id` (nullable — not every engagement is budget-tracked)
imputes `total_fee_cents` to `committed_amount_cents` at engagement EXECUTION (the real
authorization event); `payment_runs` execution moves that SAME amount from
`committed_amount_cents` to `spent_amount_cents` (decrement + increment together) for
every invoice in the run — `committed` always reflects OUTSTANDING (not-yet-paid)
commitments, real commitment accounting, not an append-only ledger. A `terminated`
engagement's un-invoiced commitment is not reconciled this sprint (honest, disclosed gap).
New page `frontend/src/pages/finance/APBudgetDashboard.js`
(`/admin/finance/ap-budget`) — role-gated on the REAL backend check (`cfo`/`admin`/
`super_admin`), not the sibling AR pages' `finance_admin` (a pre-existing frontend/backend
role-naming drift this sprint didn't introduce or fix).

## 5. The student administrative dossier (T8)

✅ **Implemented in full, SPRINT-05/NEW-19** (`backend/database/models_student_dossier.py`,
`backend/services/student_dossier_service.py`). `student_dossiers` is the single administrative
file per student: documents, `matriculation_checklists` (one row per item, live-resolved —
identity verification/G13, transcript upload, fee-schedule signature), career-relevant
administrative acts. G13's identity-verification item is honestly scoped: it checks only
"tenant policy configured + student disclosure acknowledgement at the current policy version" —
no per-student identity-verification-succeeded event exists anywhere in this codebase, and none
is fabricated here. ✅ Already originates automatically from the admission application —
`matriculation_service.matriculate_applicant` calls `get_or_create_dossier` unconditionally
at matriculation (real since SPRINT-06/NEW-18; this file's own v0.3/v0.4 text wrongly tied
this to the R23.1 gap above, which was about invoice pricing, not dossier creation —
corrected here). ⚠ Does **not** yet feed
certificate generation (BOOK-16, G9) — "certificates are generated views over dossier + evidence"
remains target; no certificate-generation code reads `student_dossiers`/`dossier_documents` yet
(C23.4 not implemented this sprint).

## 6. Boundary with external rails

| Rail | Direction | Native record | Driver executes |
|---|---|---|---|
| PagoPA | AR | invoice, reconciliation | payment position, notification |
| Frappe/ERP | AR+AP | invoice registry, budget imputation | fiscal document emission, ledger |
| QES | contracts | signature status | qualified signature act |
| ESSE3 | career | dossier, holds | legal career acts (G3 boundary) |

## 7. Conformance checks

- C23.1 ✅ **Verified SPRINT-05/NEW-19** Property: `paid` state unreachable without a
  reconciliation row (or audited CFO override) — `tests/conformance/test_finance_invoices.py`,
  against a real migrated Postgres.
- C23.2 ✅ **Verified SPRINT-09/NEW-20b**: an AP invoice insert without an approved milestone
  MUST fail — both the service-layer guard (`ap_service.APError`) and a raw FK-violating
  insert (rejected by Postgres itself) are tested,
  `tests/conformance/test_milestone_ap_budget.py`, against a real migrated Postgres.
- C23.3 ✅/⚠ **Partially verified SPRINT-05/NEW-19**: a financial hold blocks session enrollment
  in the same transaction boundary — verified
  (`tests/conformance/test_finance_holds.py::test_c23_3_active_hold_blocks_enrollment_then_release_allows_it`,
  exercises the production `assessment_session_service.enroll` directly). "...that GPS route
  evaluation reads" is NOT implemented — the GPS does not consume `administrative_holds` yet.
- C23.4 ⚠ Not implemented (certificate generation does not read the dossier yet, §5 above):
  any certificate regenerates byte-identically from dossier state at issuance time.
- C23.5 **N/A** (SPRINT-22.md "Correzioni al piano" #9). Multi-region compliance posture per
  `UNIVERSITY_PLATFORM_COMPLIANCE_MULTIREGION.md` — a real, separate document (confirmed
  present in the repo root) covering a distinct compliance domain this sprint's own scope
  (tenant guardrails, preval eval-loop) never touches; formally out of scope rather than
  merely "unaffected/not re-checked."

## 8. Financial Planning & Control (the CFO cycle)

✅ **Implemented SPRINT-18/NEW-30** (`backend/database/models_finance.py`,
`fee_schedule_service.py`/`revenue_forecast_service.py`/`cashflow_projection_service.py`/
`financial_scenario_service.py`/`period_close_service.py`/`variance_analysis_service.py`,
`backend/api/routes/finance_planning.py` — `/api/finance-planning`). Actuals (Ch. 2–4) were
half the CFO's job; this chapter closes the loop with planning and control. All planning
objects are versioned with effectivity dates and pinned by the records that consume them.

**Planning.**
- `fee_schedules` (+lines): the priced catalog per program/cohort/year, versioned by
  `effective_from`/`effective_until` with old-supersedes-new-then-flush activation
  (mirrors `CatalogEdition`/`PolicyVersion`'s established discipline). R23.6: no AR
  invoice may be issued without an effective fee schedule — `ApplicantMatriculated`
  prices the first invoice from here (§2 R23.1 above), never from constants;
  `resolve_effective_schedule` returns `None` (never fabricates one) when none resolves.
- `revenue_forecasts`: pipeline-driven — admission funnel states (BOOK-21) × OBSERVED
  conversion rates (`None`, never a fabricated 0%, with zero denominator) × the
  program's effective fee schedule; `detail` pins the exact `as_of` used, so recomputing
  with the SAME `as_of` reproduces byte-for-byte (C23.8) regardless of funnel activity
  added afterward.
- `cashflow_projections`: inflows (AR due in the snapshot month, derated by an OBSERVED
  historical on-time-payment rate — `None`/unadjusted with no paid-invoice history to
  observe from yet) and outflows (real milestone-approved `supplier_invoices`,
  `pending`/`in_payment_run`); budget commitments are reported in `detail` for
  visibility only, deliberately NOT added into outflows (would double-count against
  any already-invoiced commitment).
- `financial_scenarios`: what-if on enrollment volumes, pricing, authoring costs against
  the tenant's real current budget; `run_scenario` is a PURE compute that never persists
  a row (zero-persistence for a throwaway/preview run) — only `save_scenario` (which
  calls `run_scenario` internally) ever creates a `financial_scenarios` row.

**Control.**
- `period_closes`: monthly/quarterly close locks the period's actuals — enforced by a
  real `Invoice` `before_update` event guard (`InvoicePeriodClosedError`, same
  raw-connection-SELECT shape as `CatalogEdition`'s own guard) keyed off `issued_at`
  falling inside a `closed` window (R23.7: closed actuals are immutable; corrections are
  new invoices in the open period, never edits to a closed one) — and snapshots AR/AP
  reconciliation totals at close time.
- `variance_analyses`: budget vs actual vs forecast per `BudgetLine`, thresholded at
  ±15%; `forecast_cents` stays `None` (honest gap — no per-line link to
  `revenue_forecasts` exists, that table is program-scoped, not budget-category-scoped).
  A breach is RECORDED and emits `VarianceFlagged`; acting on it is always routed
  through `governance_actions` (BOOK-24, widened `VALID_GOVERNANCE_OBJECT_TYPES` +=
  `variance_analysis`) — never filed automatically.

New KPI `budget_variance_breach_pct` (domain `finance`, `kpi_compute_service.py`) — `None`
before any variance analysis has ever been computed for a tenant, else the % of budget lines
whose most recent analysis breached threshold. New page section: CFO Command
(`FinanceAnalyticsDashboard.js`) gains 5 additive planning/control sections below its
existing SPRINT-16 KPI/budget sections — a breached variance links to a real
`governance_actions` row via the same `executiveAPI.createGovernanceAction` SPRINT-16
established.

Events: `PeriodClosed`, `ForecastPublished`, `VarianceFlagged` (A6-closed).

Conformance: **C23.6 ✅ Verified** AR invoice without effective fee schedule → fails ·
**C23.7 ✅ Verified** closed-period invoice mutation → fails (`InvoicePeriodClosedError`) ·
**C23.8 ✅ Verified** a forecast reproduces from funnel data pinned at snapshot date —
`tests/conformance/test_cfo_planning_control.py`, against a real migrated Postgres.

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| PagoPA | `pagopa_payment_position`, `pagopa_notification_log`, `pagopa.py` | reconciliation source |
| ERP | `frappe_*` mappings + sync jobs | driver |
| Native AR ✅ (NEW-19 + NEW-30) | `student_invoices`, `invoice_lines`, `payment_reconciliations` (`backend/database/models_finance.py`), `finance_service.py`, `backend/api/routes/invoices.py` (`/api/invoices`); R23.1's automatic trigger now real (NEW-30, `fee_schedule_service.create_tuition_invoice_from_fee_schedule`) | — |
| Native AP + budgets ✅ (NEW-20b) | `supplier_invoices`, `supplier_invoice_lines`, `payment_runs`, `budgets`, `budget_lines` (same `models_finance.py`), `ap_service.py`, `budget_service.py`, `backend/api/routes/ap.py` (`/api/supplier-invoices`, `/api/payment-runs`), `backend/api/routes/budgets.py` (`/api/budgets`) | — |
| Administrative holds ✅ (NEW-19) | `administrative_holds` (unifies 3 previously-incompatible hold concepts: native/`financial_holds`-Stripe/`frappe_financial_hold` — see `ER_MAP.md` "Finanza & Fascicolo"), `holds_service.py`, enrollment gate wired into `assessment_session_service.enroll` (C23.3) | credential-issuance gate + automatic overdue→hold sweep + GPS route-constraint read |
| Student dossier ✅ (NEW-19) | `student_dossiers`, `dossier_documents`, `matriculation_checklists` (`models_student_dossier.py`), `student_dossier_service.py`; auto-creation from `ApplicantMatriculated` already real (SPRINT-06/NEW-18) | feeds certificate generation (C23.4) |
| Planning & Control ✅ (NEW-30) | `fee_schedules`, `fee_schedule_lines`, `revenue_forecasts`, `cashflow_projections`, `financial_scenarios`, `period_closes`, `variance_analyses` (same `models_finance.py`), `fee_schedule_service.py`/`revenue_forecast_service.py`/`cashflow_projection_service.py`/`financial_scenario_service.py`/`period_close_service.py`/`variance_analysis_service.py`, `backend/api/routes/finance_planning.py` (`/api/finance-planning`) | — |
| Finance UI ✅ (NEW-19 + NEW-20b + NEW-30) | `FinancePayments`, `FinanceReconciliation`, `FinanceHolds`, `RegistrarDesk` re-wired to the **native** AR domain via `backend/api/routes/payments.py` (`/api/v1/payments/*`) — NOT the pre-existing, orphaned Stripe domain (`backend/domains/payments/`, zero HTTP routes, stays untouched/out of scope); `APBudgetDashboard.js` (`/admin/finance/ap-budget`, NEW-20b) for the AP/budget slice, role-gated on the REAL `cfo`/`admin`/`super_admin` check (not the sibling pages' `finance_admin`, a pre-existing drift); CFO Command (`FinanceAnalyticsDashboard.js`) gains 5 additive planning/control sections (NEW-30) | — |
| ds/ components ✅ (NEW-19) | `MoneyTable`, `DocChecklist` (`frontend/src/components/ds/`) | — |
| Billing (platform) | `billing.py`, `subscriptions` | unchanged (tenant-level) |
| Certificates | G9 ✅ document credentials | generated from dossier (C23.4, still target) |
| New tables | ✅ T7 complete: 9/9 tables (`student_invoices`, `invoice_lines`, `payment_reconciliations`, `administrative_holds` — NEW-19; `supplier_invoices`, `supplier_invoice_lines`, `payment_runs`, `budgets`, `budget_lines` — NEW-20b); ✅ T8: 3/3 tables; ✅ Ch. 8: 7/7 tables (`fee_schedules`, `fee_schedule_lines`, `revenue_forecasts`, `cashflow_projections`, `financial_scenarios`, `period_closes`, `variance_analyses` — NEW-30) | — |
| Sprint | ✅ **NEW-19** (AR slice + dossier); ✅ **NEW-20b** (AP + budgets); ✅ **NEW-30** (planning & control, Ch. 8) | — |
| Register | ✅ **G19** added to TRACEABILITY gap register, now marked FULLY closed (Ch. 2-8, T7 complete + T8) | — |


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Cross-cutting alignment only. See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
