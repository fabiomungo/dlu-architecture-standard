# Sprint STX-01 — Twin Core Models + Identity Reconciliation
### DAS K1 · self-contained prompt · target: `dlu_builder_tk`

> **STATUS: ✅ DONE 2026-07-14** — V1–V6 green · ADR-0014 (Option A) accepted ·
> constitution §13.4 decided · report `reports/stx01_identity_reconciliation.json`
> (100% matched, 0 orphans) · next tag: STX-02 (STX-03 may run in parallel).

## Role
You are `backend-dev` implementing the Student Digital Twin core data layer
and the identity reconciliation decision (DAS BOOK-06 Ch. 2–3, BOOK-03 §5.3,
BOOK-04 C7/C4; Turnkey constitution `docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`
§4.3, §5.2, §13).

## Context — read before coding
1. `dlu_builder_tk/CLAUDE.md` (all guardrails; esp. §4 DB architecture, §8 migrations).
2. Constitution §4.3 (twin model code), §5.2 (competency models code), §13
   (files, migrations, §13.4 identity decision).
3. Existing code: `backend/database/models_mastery.py` (ConceptMastery/
   MasteryEvent — Integer `student_id`), `backend/database/models.py` (GUID
   type, `platform.users`), `backend/database/models_content_creation.py`
   (LearnerProfile), `backend/services/mastery_tracking_service.py`.

## Deliverables
1. **`backend/database/models_student_twin.py`** — tenant schema (no
   `schema=` prefix), GUID PKs: `StudentTwin` (anchor: user_id GUID unique,
   tenant_id, lifecycle_state default `prospect`, `persona` String(30)
   nullable, twin_version Integer default 1, consent_flags JSON,
   last_synced_at, timestamps, deleted_at), `TwinAcademicMirror`,
   `TwinCareerGoal`, `TwinBehaviourProfile`, `TwinAIMemory` — exactly per
   constitution §4.3 plus: `TwinAIMemory.episode_refs JSON` and
   `superseded_by GUID nullable` (BOOK-12 lineage).
2. **`backend/database/models_competency_graph.py`** — `CompetencyFramework`
   (platform schema), `StudentCompetency`, `EvidenceRecord` per constitution
   §5.2 (EvidenceRecord: NO updated_at/deleted_at — append-only). Plus
   additive ALTER on platform `competencies`: `framework_id GUID NULL`,
   `framework_version String(20) NULL` (Review M1: student states pin
   framework versions), `level String(30) NULL`, `external_uri String(500)
   NULL`.
3. **Migrations** `migrations/versions/<YYYYMMDD_HHMM>_stx_01_student_twin_core.py`
   and `_stx_02_competency_graph.py` — named constraints, `schema="platform"`
   where applicable, complete `downgrade()`.
4. **`backend/services/identity_map.py`** — Option A: single service exposing
   `guid_for_legacy(student_id: int) -> UUID` and `legacy_for_guid(...)`;
   additive migration adding `user_guid GUID NULL` (indexed) to
   `concept_mastery` and `mastery_events`; Celery backfill task
   `backfill_identity_map` producing a reconciliation report (total rows,
   matched, orphans → `reports/stx01_identity_reconciliation.json`);
   dual-write wired into `mastery_tracking_service` (writes both keys).
   **No other file may implement this mapping** (grep-enforced, V5).
5. **ADR**: `dlu-architecture-standard/architecture/adr/ADR-0014-identity-reconciliation-option-a.md`
   (context, decision, alternatives B considered, consequences).
6. **Tests** (`tests/test_stx01_*.py`, markers `unit` + `integration`):
   model round-trips, append-only enforcement, identity_map unit + backfill
   integration.

## Guardrails
Additive only; no change to legacy tables beyond the two `user_guid` columns;
FKs to `courses.id` stay Integer (`EvidenceRecord.course_id`); no
`relationship()` across model files; soft delete everywhere except
EvidenceRecord and MasteryEvent.

## Verifications (all must pass)
- **V1** `alembic upgrade head && alembic downgrade -2 && alembic upgrade head`
  clean inside docker (`docker compose -f docker-compose.dev.yml exec backend …`).
- **V2** backfill on seeded dev data reconciles 100% of active learners;
  report artifact exists and lists any orphans (orphans block DoD unless
  triaged in the report with reason).
- **V3** dual-write test: a BKT update writes both `student_id` and
  `user_guid`; parallel read via both keys returns the same row.
- **V4** append-only: `UPDATE`/soft-delete attempts on `evidence_records`
  fail at service layer (negative unit test).
- **V5** `grep -rn "user_guid" backend/ | grep -v identity_map | grep -v models_mastery | grep -v migrations | grep -v test` → only `mastery_tracking_service` dual-write lines.
- **V6** `pytest -m "unit" tests/test_stx01_* -v` green; `make dev-unit`
  regression-free; `pytest -m phase1` still green.

## DoD
V1–V6 green · ADR-0014 written · constitution §13.4 marked "decided: Option A"
· `git diff --stat` reviewed · next tag noted: STX-02 (and STX-03 may run in
parallel).
