# ADR-0022 — PostgreSQL is the interim academic source-of-truth for EKG projection; Frappe is a reconciled mirror, not the write path

Status: Proposed (2026-08-08)
Related: ADR-0009 (records in institutional ERP), ADR-0019 (EKG platform subsystem), ADR-0010 (event-first integration), BOOK-18 Ch. 3-4 (driver catalog)
Source: EKG-W1-01 (RFC-0002 §7) live investigation of `dlu_builder_tk`; resolves `DAS_EKG_INTEGRATION_PLAN.md` §6 decision #2 ("Records in Frappe/ERPNext (ADR-0009 → Accepted) vs. keep-in-Postgres interim").

## Context

`DAS_EKG_INTEGRATION_PLAN.md` explicitly left this decision open before merge: ADR-0009 says academic records live in the institutional ERP (Frappe/ERPNext); the plan's own risk assessment called this "the biggest brownfield reconciliation" and deferred a decision. EKG-W1-01's own task list ("Frappe hook: business write + outbox in same tx") assumed the decision had already gone Frappe's way.

Live investigation of `dlu_builder_tk` found it hadn't, and doesn't currently support that assumption:
- Frappe **is** deployed and running (`dlu-turnkey-frappe-*` containers, a real `frappe_erp` database) — but as a **reconciled mirror**, not the write path. `FrappeProgramMapping`/`FrappeCourseMapping`/`FrappeStudentMapping`/etc. (`models_frappe.py`) map `dlu_program_id`/`dlu_course_id` (the PostgreSQL-side primary reference, named first) to a Frappe-side id, with `FrappeSyncJob`/`FrappeSyncStatus`/`FrappeConflictLog` running bidirectional reconciliation with explicit conflict resolution — the shape of a sync between two independently-writable systems, not a cache in front of one authoritative one.
- Every academic route this program has touched across four prior EKG-W0 sprints (`institution.py`, `programs.py`, `courses.py`, `models_institution.py`) reads and writes PostgreSQL directly. `COURSE_CREATED`/`COURSE_PUBLISHED`/`COURSE_UPDATED` are genuinely emitted from `course_workflow.py` — a Postgres-side domain event, before any Frappe involvement.
- `DLU_EKG_Suite/DSA/800-integrations/frappe-doctypes.json`'s DocTypes (Program, Course, Outcome, Concept, ...) have no corresponding live Frappe doctype install for this domain in the running `frappe_erp` site — the Suite's own aspirational schema, not a deployed contract.

## Options considered

1. **Frappe as authoritative, PostgreSQL as a projection.** Matches ADR-0009's letter and the Suite's own `frappe-doctypes.json`. Rejected for EKG-W1 purposes: would require migrating live read/write traffic for Program/Course/Outcome off PostgreSQL onto Frappe DocTypes with zero current usage for this domain — a major, unstaged rewrite, not an additive EKG-projection step, and contradicted by ADR-0001/ADR-0008's own brownfield-first, strangler-fig discipline (BOOK-18 Ch. 1).
2. **PostgreSQL as the interim source of truth for EKG projection purposes; Frappe reconciliation continues unchanged, orthogonal to this decision.** Matches the running system exactly, additive, reversible (a later migration of the write path to Frappe would only mean re-pointing producers, not touching the EKG projection contract itself, which is source-agnostic by design — `ekg_projection_consumers.py`, EKG-W0-04, doesn't care which service emitted the event). **Chosen.**

## Decision

- For EKG projection purposes, **PostgreSQL (`models_institution.py`, `models.py`'s Course/Section hierarchy) is the source of truth**, not Frappe. EKG-W1 producers emit outbox events (`event_outbox.emit_async`/`emit_sync`) directly from the PostgreSQL mutation routes that already exist — the same routes already emitting `COURSE_CREATED`/`COURSE_UPDATED`/`COURSE_PUBLISHED`.
- `frappe-doctypes.json` is **not loaded** as a live schema contract for this domain. It remains a reference artifact for a future Frappe-migration decision, not an active integration surface.
- This does **not** contradict ADR-0009: ADR-0009 remains a longer-horizon direction (per-entity source-of-truth ownership, ERP where the ERP genuinely owns the record — e.g. supplier/financial records already flow through Frappe via `frappe_supplier_relay_service.py`, a real, working, orthogonal integration). This ADR scopes ADR-0009's application specifically to **academic catalog entities** (Program/Course/Outcome/Concept) for as long as they remain PostgreSQL-authoritative in the running system, and states plainly that they currently are.
- The EKG projection contract itself (`ekg_projection_consumers.py`'s node/edge payload shape, EKG-W0-04) is unaffected either way — it is deliberately source-agnostic (any producer, from any system, emitting a correctly-shaped event). A future migration of the write path to Frappe requires re-pointing producers, not redesigning the consumer.

## Consequences

**Positive:** EKG-W1-01 can proceed immediately on real, already-running infrastructure instead of blocking on an unstaged Frappe migration; no contradiction introduced with the four EKG-W0 sprints' own working assumption (all built against PostgreSQL); the decision is reversible and small in surface area (producers only).
**Costs/risks:** ADR-0009 remains formally un-Accepted for the academic-catalog domain specifically — a future RFC is still needed if/when a real migration to Frappe-as-write-path for Program/Course/Outcome is proposed; this ADR does not pre-empt that RFC, it just states honestly that the migration hasn't happened yet and EKG-W1 isn't the vehicle for it.
**Enforcement:** EKG-W1 producers live in the PostgreSQL route/service layer; `frappe-doctypes.json` and the Suite's DSA/800-integrations artifacts are cited as reference only, never imported as executable schema, until a dedicated Frappe-migration RFC supersedes this ADR.

## Related artifacts

`DAS_EKG_INTEGRATION_PLAN.md` §6 decision #2; ADR-0009; `backend/database/models_frappe.py`, `backend/services/course_workflow.py` (`dlu_builder_tk`); EKG-W1-01 sprint (`ROOCODE_EKG_PROMPTS.md`).
