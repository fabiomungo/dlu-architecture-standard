# Sprint NEW-18 — Credit Recognition Hardening (closes NEW-17's carried debt)
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-17, NEW-06 (committee), STX-13 (credential templates), NEW-11 (ESSE3 driver)

## Role
`backend-dev` + `frontend-dev`. No new G-register item — this sprint
closes three gaps NEW-17's own delivery note carried forward honestly
rather than a newly-discovered functional requirement.

## Context — read before coding
1. NEW-17's own carried-gap list (`docs/sprint_decisions_20260803_new17.md`
   §"Known gaps"; constitution §30's closing paragraph): (a) Tier-2/
   registrar frontend and badge-rule authoring UI not built, (b) the
   Tier-1 frontend was never runtime-tested in a browser, (c) NEW-11's
   ESSE3 driver does not consume `credential.recognized` (that event
   didn't exist when NEW-11 shipped).
2. **Repo-verified existing patterns to reuse, not reinvent:**
   - Staff queue+detail+action UI: `frontend/src/pages/institution/
     RegistrarDesk.js` (the direct predecessor for this exact surface —
     antd `Table` + row action opening a `Modal`+`Form`,
     `form.validateFields()`, `message.success`/`error(err.response?.data
     ?.detail)`). `backend/api/routes/pre_evaluation.py`'s
     `STAFF_ROLES = {"admin","instructor","dean","provost","advisor"}` is
     byte-identical to `AppRoutes.js`'s existing
     `VERIFICATION_DESK_STAFF_ROLES` — reuse that constant verbatim for
     the new route, don't invent a second role list.
   - Rule-authoring CRUD UI: `frontend/src/components/LLMProviderSettings/
     LLMQuotaRules.js` + `backend/api/routes/llm_providers.py`'s
     `GET/PUT/DELETE /quota-rules` — Table + "Add Rule" button + one
     shared create/edit Modal+Form + inline `Modal.confirm` delete. This
     is the shape for `BadgeCreditRule` authoring (no admin UI or route
     exists for it today — confirmed via grep, `create_badge_credit_rule`
     is currently code/test-only).
   - ESSE3 outbound push: `backend/drivers/esse3/client.py::
     Esse3Client.relay_session_enrollment` is the one existing outbound
     M-A REST push method (itself unwired/unused — no caller exists yet,
     confirmed via grep) — the shape to copy for a new
     `push_recognized_credit` method. `Esse3StudentMapping` (`backend/
     database/models_esse3.py`) resolves `twin_id → matricola`.
     `n8n-bridge` is the confirmed, correct consumer group (already
     documented in `thesis_committee_consumers.py`'s own docstring as
     "the ESSE3/ERPNext ↔ mesh bridge"); the one-line lazy-import
     registration in `backend/workers/event_mesh_worker.py::drain_group`
     is the exact pattern (`if group_name == "n8n-bridge": import ...`).
     `event_taxonomy.CREDENTIAL_RECOGNIZED` already exists (NEW-17) with
     zero consumers today.
   - `backend/services/thesis_committee_consumers.py` is the one existing
     `n8n-bridge` handler — copy its `SESSION_FACTORY_OVERRIDE`/
     `_handler_session()`/sync-session-crossing shape exactly (event
     consumers run on a worker thread, never the caller's AsyncSession).
3. **Explicit non-goals:** this sprint does not build a real ESSE3
   sandbox integration test (no live ESSE3 endpoint exists to test
   against — the same honest limitation every other ESSE3 driver test in
   this codebase already has, fixture-only); does not add a "pick an
   existing committee" flow to the Tier-2 UI beyond what
   `pre_evaluation_service.request_tier2_validation`'s `committee_members`
   path already supports (forming a fresh committee inline is enough for
   v1 — a "reuse a standing council" convenience is a future refinement).

## Deliverables
1. **Registrar-queue + generic committee-list routes** (additive,
   `backend/api/routes/pre_evaluation.py` and `backend/api/routes/
   committees.py`): `GET /api/pre-evaluations/registrar-queue` (staff-only,
   tenant-wide, filterable by status) so a registrar can find candidates
   for Tier-2 without knowing a specific learner's twin_id; `GET /api/
   committees?kind=recognition` (staff-only list, currently missing —
   `committees.py` has no generic list endpoint).
2. **Tier-2 Registrar UI**: `frontend/src/pages/institution/
   RecognitionCouncilDesk.js` + `.css`, API client `frontend/src/services/
   preEvaluationStaffAPI.js` (staff-only calls, kept separate from the
   existing learner-facing `preEvaluationAPI.js` — same file-split
   convention as `recognitionAPI.js`'s own docstring). Queue table (status,
   twin, requested date) → row actions: "Request validation" (Modal+Form:
   pick/enter committee members) → "Decide" (Modal+Form: validated/
   rejected + optional disposition-table amendment textarea, JSON) →
   "Convert" (button, enabled once `tier2_validated`). Route
   `/organization/recognition-council`, `ProtectedRoute
   requiredRoles={VERIFICATION_DESK_STAFF_ROLES}` (imported, not
   redefined).
3. **Badge-rule authoring UI + route**: `POST /api/admin/badge-credit-
   rules` + `GET /api/admin/badge-credit-rules` + `DELETE .../{id}`
   (additive route file `backend/api/routes/badge_credit_rules_admin.py`,
   wrapping `badge_credit_rule_service.create_badge_credit_rule` — add a
   `list_rules`/`deactivate_rule` function to the service if missing).
   Frontend: `frontend/src/pages/institution/BadgeCreditRuleAdmin.js` +
   `.css`, mirroring `LLMQuotaRules.js`'s Table+"Add Rule"+shared Modal
   pattern exactly; route `/organization/badge-credit-rules`, same staff
   role guard.
4. **ESSE3 driver consumes `credential.recognized`**: `Esse3Client.
   push_recognized_credit(matricola, payload) -> Dict[str, Any]` (new
   outbound method, copies `relay_session_enrollment`'s shape); new model
   `Esse3CredentialSyncLog` (platform schema, additive migration —
   mirrors `Esse3NotificationLog`'s idempotency-log shape but for the
   outbound direction: `tenant_id`, `credential_id`, `twin_id`,
   `matricola`, `status` (`pending|synced|failed|no_mapping`), `payload`,
   `synced_at`, `error_detail`); new consumer
   `backend/services/esse3_credential_consumers.py` on `n8n_bridge` for
   `CREDENTIAL_RECOGNIZED` — resolves `Esse3StudentMapping` by
   `(tenant_id, twin_id)`, calls `push_recognized_credit` (circuit-
   breaker-aware — a down ESSE3 must never raise into the mesh consumer;
   log `status="failed"` and let the mesh's own retry/replay semantics
   handle redelivery, matching this driver's established "stale-with-
   notice, kernel stays green" resilience posture), writes the sync-log
   row, `status="no_mapping"` (not `"failed"`) when no
   `Esse3StudentMapping` exists — an honest distinction between "ESSE3
   is down" and "this tenant isn't ESSE3-mirrored at all."
5. **Tier-1 frontend runtime-tested**: start the dev server, exercise
   `PreEvaluationWorkspace.js` end-to-end in a real browser (request an
   estimate, see the disposition table + non-binding banner render);
   fix whatever the manual pass finds. Same for the two new pages built
   in this sprint (registrar desk + badge-rule admin) — click through the
   full create/decide/convert flow at least once each.

## Verifications
- **V1** registrar-queue route returns only staff-visible, tenant-scoped
  pre-evaluations (negative test: a different tenant's rows never leak);
  `GET /committees?kind=recognition` returns only `kind="recognition"`
  rows.
- **V2** Tier-2 UI round-trip (component/integration test or a scripted
  browser pass, documented either way): request-validation → decide
  (validated) → convert, hitting the real backend routes NEW-17 already
  shipped — no regression to those routes' own behavior.
- **V3** badge-rule admin CRUD round-trip: create → list → delete, and a
  created `auto`-tier rule is immediately usable by
  `badge_credit_rule_service.apply_badge_credit_rules` (no caching gap).
- **V4** ESSE3 consumer: fixture `credential.recognized` event with a
  real `Esse3StudentMapping` row → `push_recognized_credit` called (mock
  transport) → `Esse3CredentialSyncLog` row `status="synced"`; without a
  mapping → `status="no_mapping"`, no call attempted; transport failure →
  `status="failed"`, consumer does not raise (mesh stays healthy).
- **V5** browser pass documented for all three frontend surfaces
  (Tier-1, registrar desk, badge-rule admin) — screenshots or an explicit
  written account of what was clicked and observed, not just "tests
  pass."
- **V6** migration up/down/up clean (disposable Postgres) ·
  `pytest -m phase1` stable · NEW-17's own 25 tests + STX-12/NEW-06/
  STX-13/NEW-16/STX-14-15 suites still green (no regression).

## DoD
V1–V6 green · TRACEABILITY NEW-17 row's carried-gaps note updated to
"closed (NEW-18)" · K4 README sprint table gets a NEW-18 row · design
notes in `docs/sprint_decisions_*.md`.
