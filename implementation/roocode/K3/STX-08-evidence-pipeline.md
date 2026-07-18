# Sprint STX-08 — Evidence Pipeline (the sole writer)
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: K1 · **start in parallel day 1 — gates all K4 credential work**

## Role
`backend-dev` implementing the epistemic engine (DAS BOOK-15 Ch. 1/3/4;
constitution §11; constitutional invariant: the Assessment Engine is the
**only writer** of append-only `EvidenceRecord`).

## Context — read before coding
1. BOOK-15 Ch. 1 (two products per interaction: fast mastery signal +
   durable evidence — the split IS the architecture), Ch. 3 (the pipeline:
   all ingress paths → `AssessmentEvidenceService` → BKT → alignment
   chain → `EvidenceRecord` → `evidence.recorded` → competency recompute),
   Ch. 4 (trust model: seed table 4.1, confidence formula 4.2 —
   `verified` = human act only, ADR-0012; triangulation rule 4.3).
2. Constitution §11: service is `assessment_evidence_service.py` (sync —
   Celery consumer); mapping chain is data-driven (assessment →
   `OutcomeAssessmentAlignment` → CLO → `CLOCompetency` → Competency);
   unmapped assessments ⇒ mastery only + WARN metric; `grade.synced`
   enters with `source_kind="erpnext"`, trust 0.9; recognition claims
   enter as `prior_learning`, ceiling `evidenced` until human
   verification; identity via `identity_map` **only** (§13.4,
   grep-enforced).
3. Existing (repo-verified — read these before writing a line):
   - `EvidenceRecord` **already exists** append-only
     (`models_competency_graph.py`, `EvidenceAppendOnlyError` enforced at
     the model layer since K1) — this sprint builds the *pipeline around
     it*, not the table.
   - `CompetencyGraphService` (STX-04): deterministic
     `compute_confidence`, `next_status` state machine — the recompute
     target, do not reimplement.
   - **Two BKT implementations**: `mastery_tracking_service.py` (DB-backed
     production path — `record_answer`, `_bkt_update`, emits
     `mastery.updated`, writes `concept_mastery`/`mastery_events` with
     `user_guid`) and `knowledge_mastery_service.py` (older, in-memory
     `BKTService`). The pipeline consumes **`mastery_tracking_service`**;
     record the consolidation decision (and the in-memory service's
     disposition) in the sprint decisions note — don't silently pick.
   - **Grading and mastery are NOT wired end-to-end today**:
     `grading_service.py` grades quiz/lab attempts, and the Caliper
     receiver stores/forwards without touching BKT — the "single
     ingestion path" (BOOK-15 Annex: consolidation 🔵 STX-03/08) is
     genuine new wiring, not a refactor.
   - Alignment models live in `backend/domains/assessment/models.py`
     (`CLOAlignment` et al.) — verify the exact chain model names against
     constitution §11 before wiring; if the constitution's names drift
     from code, fix the constitution in the same change set (sync rule).
   - Event mesh (STX-03): `assessment.completed`, `activity.recorded`,
     `grade.synced` in the closed taxonomy; consumer framework in
     `event_consumers.py`.
   - Migration chains off the current head under `migrations/versions/`.
4. Ingress paths that don't exist yet (leave typed seams, do not stub
   fake data): viva/committee verdicts (NEW-06), recognition dossiers
   (STX-12), `AssessmentSession` results (NEW-05).

## Deliverables
1. **`backend/services/assessment_evidence_service.py`** (sync, Celery) —
   the sole writer: consumes `assessment.completed`, `activity.recorded`
   (xAPI/Caliper — closing the ingestion gap), `grade.synced`; per event:
   (1) BKT update via `mastery_tracking_service`, (2) alignment-chain
   resolution, (3) `EvidenceRecord` write (normalized score,
   `source_kind`, `source_trust`, weight, payload snapshot), (4) emit
   `evidence.recorded`, then trigger
   `CompetencyGraphService.recompute` → `competency.*`.
2. **Trust table** (BOOK-15 Ch. 4.1 seed values: committee 1.0, viva
   0.95–1.0, proctored/official 0.9, challenge 0.85, unproctored 0.6,
   peer 0.5, recognition dossier 0.4, self-report 0.3) — **versioned**
   per institution (platform-side policy object; changes never rewrite
   existing evidence rows, they apply forward).
3. **Sole-writer enforcement**: every other write path to
   `EvidenceRecord` removed/forbidden; add a CI grep gate (pattern:
   `EvidenceRecord(` outside the service + its tests fails the build) —
   same technique as the STX-01 identity-map gate.
4. **Unmapped-assessment WARN**: assessments with no alignment chain
   produce mastery only + a WARN metric surfaced to authors (QA
   dashboard hook) — never silently promoted to evidence (BOOK-01
   §5.2.2 authoring defect).
5. **Evidence timeline API**: `GET /api/assessment/me/evidence`
   (paginated, per constitution §14) — the learner-facing read the WS06
   canvas and the K4 credential engine both consume.
6. **Triangulation bookkeeping** (Ch. 4.3): expose a
   `triangulation_status` computation (≥ 2 evidence types incl. ≥ 1
   high/highest class) for credential-bearing claims — consumed by K4;
   plus a single-source-drift metric (input to the BOOK-08 I3 trust
   alarm).

## Verifications
- **V1** integration: a quiz attempt flows end-to-end — BKT update +
  `EvidenceRecord` + `evidence.recorded` + competency recompute event,
  in order, idempotent on duplicate delivery (mesh discipline).
- **V2** append-only: any update attempt on an `EvidenceRecord` fails
  loudly (`EvidenceAppendOnlyError`); corrections create new records
  referencing `source_ref`.
- **V3** regression: existing mastery tests stay green
  (`test_stx04_competency_engine.py`, mastery/xAPI suites) —
  `pytest -m phase1` unchanged.
- **V4** identity via `identity_map` only — CI grep gate (no second
  GUID↔legacy mapping anywhere in the pipeline).
- **V5** unmapped assessment ⇒ mastery updates + WARN metric, zero
  evidence rows (negative test); `verified` status unreachable by any
  pipeline path (human act only — negative test).
- **V6** sole-writer grep gate red when a rogue write is introduced
  (self-test of the gate) · migration up/down/up clean.

## DoD
V1–V6 green · constitution §11 marked implemented (+ any alignment-model
naming drift corrected) · BOOK-15 Annex rows (ingestion single-path,
evidence service, trust calibration seed) updated · TRACEABILITY K3 row
updated · decisions note (BKT consolidation, trust-table versioning) ·
next: NEW-05 feeds session results; NEW-06 feeds verdicts; STX-12 feeds
dossiers; K4 credential engine consumes `triangulation_status`.
