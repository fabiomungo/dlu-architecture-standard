# BOOK-23 — Financial Operations & Administrative Backbone
### DAS v0.3-draft · Layer: Institution / Delivery · Status: DRAFT (target-state extension)
*(v0.2: adds Ch. 8 — Financial Planning & Control, sprint NEW-30 — still target, not built.
v0.3: SPRINT-05/NEW-19 implements the AR slice (Ch. 2, minus R23.1's automatic trigger) and
the full student dossier (Ch. 5, T8) — see Annex A for exactly what is real vs. still target.
AP/budgets (Ch. 3–4, NEW-20b) and Ch. 8 planning & control (NEW-30) remain entirely target.)*

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

- R23.1 ⚠ **Not yet wired**: no `ApplicantMatriculated` event exists in this codebase yet
  (SPRINT-06 work, per SPRINT-05.md's own "Obiettivo" line — this sprint is its prerequisite) —
  there is nothing to trigger automatic first-invoice creation from, and no fee-schedule policy
  object exists either (that is Ch. 8's `fee_schedules`, still entirely target). Today an invoice
  is created only by a staff member (`POST /api/invoices`, `finance_service.create_invoice`) with
  an honest `INV-<uuid4>` number (no real numbering series yet).
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

`supplier_invoices` are generated exclusively by `MilestoneApproved` (BOOK-22).
`payment_runs` batch approved payables; execution requires role `cfo` approval and is
performed by the banking/ERP driver. Rule R23.5: an AP invoice without a matching
approved milestone is structurally impossible (FK + conformance check).

## 4. Budgets

`budgets` (+`budget_lines`) per fiscal year, department/program dimensioned.
Authoring engagements and payment runs impute to budget lines at authorization time
(commitment accounting), giving the CFO dashboard (BOOK-24) budget-vs-actual without
extraction jobs.

## 5. The student administrative dossier (T8)

✅ **Implemented in full, SPRINT-05/NEW-19** (`backend/database/models_student_dossier.py`,
`backend/services/student_dossier_service.py`). `student_dossiers` is the single administrative
file per student: documents, `matriculation_checklists` (one row per item, live-resolved —
identity verification/G13, transcript upload, fee-schedule signature), career-relevant
administrative acts. G13's identity-verification item is honestly scoped: it checks only
"tenant policy configured + student disclosure acknowledgement at the current policy version" —
no per-student identity-verification-succeeded event exists anywhere in this codebase, and none
is fabricated here. ⚠ Does **not** yet originate automatically from the admission application
(no `ApplicantMatriculated` event exists — same R23.1 gap above) and does **not** yet feed
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
- C23.2 ⚠ Not implemented (AP side, NEW-20b, still target): AP invoice insert without approved
  milestone → MUST fail.
- C23.3 ✅/⚠ **Partially verified SPRINT-05/NEW-19**: a financial hold blocks session enrollment
  in the same transaction boundary — verified
  (`tests/conformance/test_finance_holds.py::test_c23_3_active_hold_blocks_enrollment_then_release_allows_it`,
  exercises the production `assessment_session_service.enroll` directly). "...that GPS route
  evaluation reads" is NOT implemented — the GPS does not consume `administrative_holds` yet.
- C23.4 ⚠ Not implemented (certificate generation does not read the dossier yet, §5 above):
  any certificate regenerates byte-identically from dossier state at issuance time.
- C23.5 Multi-region compliance posture per `UNIVERSITY_PLATFORM_COMPLIANCE_MULTIREGION.md` —
  unaffected by this sprint, not (re-)checked here.

## 8. Financial Planning & Control (the CFO cycle)

Actuals (Ch. 2–4) are half the CFO's job; this chapter closes the loop with planning and
control. All planning objects are versioned with effectivity dates and pinned by the
records that consume them.

**Planning.**
- `fee_schedules` (+lines): the priced catalog per program/cohort/year. R23.6: no AR
  invoice may be issued without an effective fee schedule — `ApplicantMatriculated`
  prices the first invoice from here, never from constants.
- `revenue_forecasts`: pipeline-driven — admission funnel states (BOOK-21) × observed
  conversion rates × fee schedules; monthly snapshots comparable to actuals.
- `cashflow_projections`: inflows (AR due dates × observed delay rates) and outflows
  (expected milestone AP from executed engagements, payment runs, budget commitments).
- `financial_scenarios`: what-if on enrollment volumes, pricing, authoring costs;
  unsaved scenarios persist nothing; saved ones compare scenario vs budget vs actual.

**Control.**
- `period_closes`: monthly/quarterly close locks the period's actuals (R23.7: closed
  actuals are immutable; corrections are new entries in the open period) and snapshots
  reconciliation state.
- `variance_analyses`: budget vs actual vs forecast per line, thresholded; a breach
  requires an action — routed through `governance_actions` (BOOK-24), never resolved
  silently.

Events: `PeriodClosed`, `ForecastPublished`, `VarianceFlagged` (A6-closed).

Conformance: **C23.6** AR invoice without effective fee schedule → MUST fail ·
**C23.7** closed-period mutation → MUST fail · **C23.8** any forecast reproduces from
funnel data pinned at snapshot date.

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| PagoPA | `pagopa_payment_position`, `pagopa_notification_log`, `pagopa.py` | reconciliation source |
| ERP | `frappe_*` mappings + sync jobs | driver |
| Native AR ✅ (NEW-19) | `student_invoices`, `invoice_lines`, `payment_reconciliations` (`backend/database/models_finance.py`), `finance_service.py`, `backend/api/routes/invoices.py` (`/api/invoices`) | R23.1's automatic trigger + Ch. 8 fee schedules |
| Administrative holds ✅ (NEW-19) | `administrative_holds` (unifies 3 previously-incompatible hold concepts: native/`financial_holds`-Stripe/`frappe_financial_hold` — see `ER_MAP.md` "Finanza & Fascicolo"), `holds_service.py`, enrollment gate wired into `assessment_session_service.enroll` (C23.3) | credential-issuance gate + automatic overdue→hold sweep + GPS route-constraint read |
| Student dossier ✅ (NEW-19) | `student_dossiers`, `dossier_documents`, `matriculation_checklists` (`models_student_dossier.py`), `student_dossier_service.py` | auto-creation from `ApplicantMatriculated`, feeds certificate generation (C23.4) |
| Finance UI ✅ (NEW-19) | `FinancePayments`, `FinanceReconciliation`, `FinanceHolds`, `RegistrarDesk` re-wired to the **native** domain above via `backend/api/routes/payments.py` (`/api/v1/payments/*`, the pages' own pre-existing URL prefix) — NOT the pre-existing, orphaned Stripe domain (`backend/domains/payments/`, zero HTTP routes, stays untouched/out of scope — genuine tech debt for a future domain owner, undocumented anywhere before this sprint found it) | — |
| ds/ components ✅ (NEW-19) | `MoneyTable`, `DocChecklist` (`frontend/src/components/ds/`) | — |
| Billing (platform) | `billing.py`, `subscriptions` | unchanged (tenant-level) |
| Certificates | G9 ✅ document credentials | generated from dossier (C23.4, still target) |
| New tables | ✅ T7 AR slice: 4/9 tables (`student_invoices`, `invoice_lines`, `payment_reconciliations`, `administrative_holds`); ✅ T8: 3/3 tables | T7 AP/budget slice: 5 tables (`supplier_invoices`, `supplier_invoice_lines`, `payment_runs`, `budgets`, `budget_lines`); Ch. 8: `fee_schedules(+lines)`, `revenue_forecasts`, `cashflow_projections`, `financial_scenarios`, `period_closes`, `variance_analyses` |
| Sprint | ✅ **NEW-19** (AR slice + dossier, this sprint) | **NEW-20b** (AP+budget), **NEW-30** (planning & control, Ch. 8) |
| Register | ✅ **G19** added to TRACEABILITY gap register | — |
