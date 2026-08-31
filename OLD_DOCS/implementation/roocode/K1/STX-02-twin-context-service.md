# Sprint STX-02 — TwinContextService + /api/twin
### DAS K1 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-01

> **STATUS: ✅ DONE 2026-07-14** — V1–V6 green · migration up/down/up clean ·
> router registered (NOT exempt) · constitution §4.4 implemented · BOOK-06
> Annex A context-service + snapshots rows ✅ · executed AFTER STX-03, so the
> outbox coupling and the twin-sync `bump_version` hook were closed in the
> same change set · next: STX-04 (STX-05 may run in parallel).

## Role
`backend-dev` implementing the single door to student context (DAS BOOK-06
Ch. 5–7; constitution §4.4, §14).

## Context
1. BOOK-06 Ch. 5 (assembly, purpose, caching), Ch. 6 (agent entitlement
   matrix — copy it into code as data), Ch. 7 (versioning/snapshots), Ch. 9
   (consent purposes: `ai_personalization`, `behaviour_analytics`,
   `career_processing`, `cross_institution_sharing`).
2. Existing: `backend/services/tutor_context_service.py` (to become an
   adapter — zero regression on `/api/learners/*`), `learner_profile.py`
   routes, Redis conventions, `get_async_db`/`get_current_user` dependencies,
   tenant middleware (do NOT add /api/twin to EXEMPT_PATHS).

## Deliverables
1. **`backend/services/twin_context_service.py`**:
   - `async get_context(user_id, layers: set[str]|None, purpose: str) -> TwinContext`
     (Pydantic model, one optional field per layer L1–L7);
   - mandatory `purpose` from enum (`tutor|gps|recommendation|success|
     discovery|staff_view|learner_self|generic`), audit-logged with actor;
   - **entitlement check**: callers declare an `agent_key` or role; layer set
     validated against the BOOK-06 Ch. 6 matrix (data-driven dict, unit-tested);
     denials audited;
   - **consent gating** per BOOK-04 §5.2 (ungranted → layer None + audit);
   - per-layer Redis cache keyed `(twin_id, layer, twin_version)` — TTL 300 s
     default, 3600 s behaviour, none for consent;
   - `async bump_version(twin_id, layer)` — increments anchor twin_version
     (single UPDATE), busts cache; (outbox coupling completes in STX-03 —
     leave a `TODO(STX-03)` hook).
2. **Snapshots**: `create_snapshot(twin_id, reason)` — immutable JSON of all
   layers + version into new tenant table `twin_snapshots` (GUID, additive
   migration `_stx_02b_twin_snapshots.py`); called on lifecycle transitions.
3. **`backend/api/routes/student_twin.py`** — `prefix="/api/twin"`, register
   via `_import_router("student_twin", …)` in `backend/api/main.py`:
   `GET /me` (query `layers`, `purpose=learner_self` forced), `GET /me/layers/{layer}`,
   `PATCH /me/career-goals`, `PUT /me/consent` (change → audit + cache bust),
   `GET /{user_id}` (RBAC `advisor+`, purpose=staff_view mandatory in query,
   audited). Status codes per CLAUDE.md §5.4.
4. **Adapter**: `tutor_context_service` reimplemented over
   `get_context(purpose="tutor")` preserving its public response shape;
   existing contract tests untouched.
5. **Frontend client**: `frontend/src/services/twinAPI.js` using the
   configured axios instance.
6. **Tests**: entitlement allow/deny matrix table-test; consent degradation;
   cache bust on bump; snapshot immutability; adapter regression; p95 latency
   smoke (cached read < 300 ms budget assertion in integration test).

## Verifications
- **V1** entitlement matrix: for each (agent_key, layer) pair in the Ch. 6
  table, allow/deny matches; a denial writes an audit row (negative test).
- **V2** `ai_personalization=false` → L5/L6/L7 return None + audit entry;
  L1–L4 unaffected.
- **V3** `bump_version` invalidates: read → bump → read returns fresh layer
  (Redis integration test).
- **V4** all existing `/api/learners/*` tests green (adapter regression).
- **V5** `/api/twin/me` requires tenant context (401/`Tenant identifier not
  found` without header — middleware test) and auth.
- **V6** staff read without `purpose` → 422; with purpose → audited.

## DoD
V1–V6 green · migration up/down/up clean · router registered, NOT exempt ·
docs: constitution §4.4 marked implemented; BOOK-06 Annex A row → ✅ for
context service (purpose audit + entitlements) · next: STX-03 (if not already
running) then STX-04.
