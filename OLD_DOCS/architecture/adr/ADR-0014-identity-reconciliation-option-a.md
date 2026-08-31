# ADR-0014 — Identity Reconciliation: Option A (additive GUID column + dual-write)

Status: Accepted (STX-01, 2026-07-14)

## Context
The Turnkey reference implementation carries two user key families
(BOOK-04 C7, register A2): the canonical identity anchor `platform.users.id`
(GUID) and legacy Integer keys in the BKT tables `concept_mastery.student_id`
/ `mastery_events.student_id`, which reference the tenant-schema `users`
table (BigInteger PK, linked to the platform anchor only by email within a
tenant). The Student Digital Twin (BOOK-06) and the Competency Graph anchor
all student state on the GUID, so twin layers cannot join BKT knowledge
state without a reconciliation mechanism. Constitution
`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §13.4 marked this as a blocking
decision for STX-01.

## Decision
Adopt **Option A**:

1. Additive nullable column `user_guid UUID` (indexed) on `concept_mastery`
   and `mastery_events` (migration `20260714_1000_stx_01_student_twin_core`).
   The legacy `student_id` column is never dropped (additive-only rule).
2. The Integer↔GUID mapping is implemented **exclusively** in
   `backend/services/identity_map.py` (`guid_for_legacy` / `legacy_for_guid`),
   resolving via `tenant_{hex}.users.id → email → platform.users.id`.
   Grep-enforced: no other module may reference `user_guid` except the
   mastery models, the dual-write lines in `mastery_tracking_service`,
   migrations and tests (STX-01 V5).
3. A Celery backfill task (`identity_map.backfill_identity_map`) populates
   `user_guid` on existing rows and emits a reconciliation report
   (`reports/stx01_identity_reconciliation.json`) listing totals, matched
   learners and triaged orphans.
4. `MasteryTrackingService` dual-writes both keys on every BKT update and
   heals `user_guid` on legacy rows it touches. Resolution failures never
   block a mastery write (`user_guid` stays NULL → orphan, reconciled later).
5. New kernel code (TwinContextService, Competency Graph, GPS) reads the
   GUID only.

## Alternatives considered
**Option B — standalone mapping table** (`identity_map(legacy_id, user_guid,
tenant_id)`) was rejected: it adds a join to every knowledge-layer read on
the hottest student-state tables, requires its own consistency maintenance,
and still needs dual-write discipline. It offered no benefit over Option A
since the mapping is deterministic from tenant users + email and the legacy
tables accept additive columns. Option B remains viable as a future overlay
if a non-deterministic mapping (e.g. merged accounts) ever becomes necessary.

## Consequences
- Twin/competency layers can join BKT state on `user_guid` without touching
  the legacy Integer contract; existing mastery API routes stay unchanged.
- Rows whose legacy id cannot be resolved (no tenant user row, unmatched
  email, ambiguous cross-tenant id) remain readable via `student_id` and are
  reported as orphans; they block GUID-only reads until triaged.
- The email-based join makes email changes a reconciliation event: account
  email updates must re-run the backfill (or future event-driven heal).
- Constitution §13.4 is marked "decided: Option A"; register A2 traceability
  (TRACEABILITY.md) already points identity reconciliation at STX-01 and
  `identity_map` as sole owner.
