# Sprint STX-04 — Competency Engine
### DAS K1 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-01, STX-03

> **STATUS: ✅ DONE 2026-07-15** — V1–V6 green (8 golden cases ≤ 1e-6;
> `verified` unreachable by formula; CASE import idempotent; outbox events
> asserted; params immutable) · constitution §5.3 params note added ·
> BOOK-04 C4 / BOOK-06 L3 Annex rows ✅ · next: STX-05 (last K1 sprint).

## Role
`backend-dev` implementing the Competency Engine service layer (DAS BOOK-03
§3.4, BOOK-01 Ch. 6, BOOK-04 C4, BOOK-05 Ch. 7; constitution §5).

## Context
1. Constitution §5.3 (confidence algorithm), BOOK-15 §4.1 (source-trust seed
   table — copy as versioned config), BOOK-01 Ch. 6 (thresholds:
   evidenced ≥ 0.5, mastered ≥ 0.8, verified = human only; decay λ default
   180-day half-life).
2. Existing: `models_institution.py` (`Competency`, `CLOCompetency`),
   `models_ccp_standards.py` (`CASEFramework`), STX-01 models
   (`CompetencyFramework`, `StudentCompetency`, `EvidenceRecord`), STX-03
   outbox (`emit`), `identity_map`.
3. Review M1 (framework versioning): frameworks immutable per version;
   `StudentCompetency` pins `(competency_id, framework_version)`;
   version migration is a governed act — implement pinning now, crosswalk
   later.

## Deliverables
1. **`backend/services/competency_graph_service.py`** (async for routes +
   sync wrapper for Celery):
   - `recompute(student_competency_id)` — constitution §5.3 formula
     (`Σ score·weight·recency·source_trust / Σ weight`, `recency=exp(-λ·age)`);
     trust weights + λ from versioned config table
     `competency_engine_params` (additive migration, seeded from BOOK-15
     §4.1); status transitions with hysteresis on decay (`expired` checkpoint);
     emits `competency.updated` / `competency.mastered` via outbox;
   - `verify(student_competency_id, verifier_user_id)` — **the only path to
     `verified`**; requires staff role; records verifier on the evidence;
   - `register_evidence(...)` used by the (future STX-08) pipeline — for now
     the only writer entrypoint, service-internal;
   - decay checkpoint mission (Celery beat daily) re-running recompute for
     stale rows.
2. **CASE import**: `import_case_framework(case_framework_id) ->
   CompetencyFramework + Competency rows` with `case_uri`/version preserved;
   idempotent re-import (upsert by case_uri within framework version); round-
   trip export preview.
3. **Routes** `backend/api/routes/competency_graph.py`
   (`prefix="/api/competencies"`, tenant-scoped, registered in main.py):
   `GET /frameworks` · `POST /frameworks` (admin) · `POST /frameworks/import-case/{id}` (admin)
   · `GET /me` · `GET /me/{competency_id}/evidence` (paginated timeline)
   · `POST /{student_competency_id}/verify` (staff, 409 on double-verify).
4. **Frontend client** `frontend/src/services/competencyAPI.js`.
5. **Tests**: golden confidence cases (fixtures: single high-trust, mixed
   sources, decayed, triangulated — expected values precomputed in the test
   file with the formula shown); negative: formula can never set `verified`;
   CASE import idempotency; event emission through outbox (uses STX-03 test
   harness).

## Verifications
- **V1** golden cases: computed confidence within 1e-6 of expected for ≥ 6
  fixtures incl. decay and trust-weight variation.
- **V2** `verified` unreachable: brute recompute with perfect evidence stays
  `mastered`; only `verify()` transitions (negative test).
- **V3** CASE import: run twice → identical row counts (idempotent);
  `case_uri` preserved; framework version pinned on student rows.
- **V4** every mutation emits its taxonomy event via outbox (assert rows).
- **V5** param change requires new `competency_engine_params` version row
  (immutability test on the active version).
- **V6** `make dev-unit` + `pytest -m phase1` green.

## DoD
V1–V6 green · params config documented in constitution §5.3 note · BOOK-04
C4 / BOOK-06 L3 Annex rows updated (🔵→✅ for engine service) · next: STX-05.
