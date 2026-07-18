# Sprint STX-07 — Academic GPS Core + WS01 Journey
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: K1, K2 (Navigator ships through the NEW-02 gate)

## Role
`backend-dev` + `frontend-dev`, with an opus-class design review on the
routing determinism contract and the map/service boundary before merge
(DAS BOOK-14; constitution §9; BOOK-03 §3.8).

## Context — read before coding
1. BOOK-14 Ch. 1 (five capabilities), Ch. 2 (the academic fix — position
   sources incl. position potential), Ch. 5 (routing engine: deterministic
   multi-objective search, **no LLM anywhere in the loop**, reproducibility
   fingerprint, budgets), Ch. 6.2–6.3 (reroute discipline, `path.replanned`
   only on adoption, compassionate recalculating, ETA bands), Ch. 7
   (guidance: scenario cards, Navigator narrates via R7), Ch. 8 (objective
   sovereignty, probability honesty).
2. Constitution §9: the service contract is `academic_gps_service.py` —
   `compute_scenarios(twin_id, target) -> list[PathScenario]` +
   `evaluate_current_path(twin_id) -> PathHealth`; four canonical scenarios
   (§9.2); `PathScenario` shape + `inputs_fingerprint` (§9.3); `/api/gps`
   routes (§14); §6.4 documents the canonical GPS path-finding KG query.
3. **Scope split (pack decision, README):** this sprint delivers
   `fastest_path` + path-health on a **v1 term-indexed closure** composed
   from existing assets — `prerequisite_service`
   (`get_completion_path`, circular-dependency validation),
   `curriculum_graph_service` (program graph + DFS), KG `PREREQUISITE_FOR`
   via `kg_query_service` (§6.4), offerings/terms, recognized credits from
   the L2/L3 mirror. NEW-04 replaces the v1 map with the full RouteGraph
   compiler *behind the same contract* — design the map interface so the
   compiler swaps in without touching `/api/gps` or the scenario schema.
   Scenarios 2–4 go learner-real at STX-12; return them as
   `not_yet_available` (honest), never as fakes.
4. **Premise correction (repo-verified):** the constitution §3 reuse map
   cites `eta_service` as GPS material, but the running
   `backend/services/eta_service.py` is a **generic job-completion
   estimator** (`record_job_completion`/`get_eta_seconds`), not an academic
   ETA model. Build the graduation-ETA velocity model as new work (own
   module or a clearly separated academic layer over `eta_service`);
   document the correction in the sprint decisions note and fix the
   constitution §3 row in the same change set.
5. Existing (repo-verified): NO `AcademicGPSService`, NO `path_scenarios`
   table, NO `/api/gps` — all net-new; migration chains off head
   `20260718_1100` (`YYYYMMDD_HHMM_stx_07_<slug>.py` convention). ACE
   runtime (`ace_service.py`) + move catalog (`pedagogical_moves.py` —
   `replan_path` exists in the closed catalog, and
   `LearnerStateAssessment.gps_invalidated_or_requested` is already a
   precondition input); NEW-02 harness (the Navigator's GA gate); event
   mesh (`event_consumers.py`); `TwinContextService` — `AGENT_ENTITLEMENTS`
   already reserves `academic_navigator → {L2,L3,L4,L5}` (reuse that exact
   agent_key).
6. **New-agent lock-step rule (repo convention):** an agent touches three
   registries together — `ai_agent_configs` seed row (pattern:
   `seed_discovery_agent` in `ace_service.py`; `lifecycle_state='testing'`),
   `AGENT_ENTITLEMENTS` in `twin_context_service.py` (already present for
   the Navigator), and `move_bindings` drawn from the closed
   `MOVE_CATALOG`.
7. Frontend pattern (repo-verified): mirror WS00 — page shell
   `frontend/src/pages/student/CompanionWorkspace.js` + components under
   `frontend/src/components/companion/` (`CompanionChat`, `MissionsFeed`,
   `WhyAffordance`), lazy route in `AppRoutes.js`, one `gpsAPI.js` client
   under `frontend/src/services/` importing the configured axios instance.
8. BOOK-13 Ch. 7 (graph analytics): search heuristics MAY be calibrated
   from AKN path statistics — keep the heuristic module separable and
   deterministic (a heuristic change is a map-version change, visible in
   the fingerprint).

## Deliverables
1. **`backend/services/academic_gps_service.py`** — deterministic graph
   search (label-correcting over the v1 term-indexed closure):
   `compute_scenarios` (fastest_path: min expected terms to target;
   target = credential | program | ESCO occupation) and
   `evaluate_current_path` (PathHealth: credits recognizable,
   time-to-graduation, cost projection, competency gaps, requirement
   status). Hard constraints v1: prerequisite closure (A8 canonical
   `PREREQUISITE_FOR`), offering calendar, recognized credits. Every step
   carries its `reason` (constitutional example: *"unlocks
   PREREQUISITE_FOR chain to C-DB-3"*).
2. **Persistence + fingerprint**: `path_scenarios` tenant table (GUID,
   additive migration) per constitution §9.3 with `inputs_fingerprint =
   sha256(fix, map_version, policy_versions, constraints)` — same
   fingerprint ⇒ identical output (property, not aspiration); scenario
   history retained (audit, retention-classed).
3. **`/api/gps` routes** (constitution §14): `POST /scenarios` (async
   compute — Celery task, < 60 s budget), `GET /scenarios`,
   `GET /path-health` (cached read p95 < 300 ms), `POST /scenarios/{id}/
   adopt` — **`path.replanned` is emitted only here**, on adoption;
   recompute proposals accumulate quietly in path-health.
4. **Graduation ETA bands** (new academic velocity model — see premise
   correction): expected graduation term with confidence band + listed
   assumptions (current pace, offering stability); `graduation.predicted`
   emitted for institutional consumers. Bands, never points (BOOK-14
   §6.3).
5. **Traffic v1**: mesh subscriptions re-fix position and re-score the
   adopted path on `grade.synced`, `assessment.completed`,
   `competency.updated/mastered`, enrollment/goal changes — re-score and
   flag only; the full invalidation table + hysteresis thresholds land in
   NEW-04 (leave the consumer seam explicit).
6. **Academic Navigator agent** (BOOK-10 Ch. 3 card): seed row
   (`agent_key='academic_navigator'`, `lifecycle_state='testing'`), moves
   `replan_path` / `explain_concept` / `reframe_goal` (hand-off), reads
   L2/L3/L4/L5 (already entitled); narration strictly R7 — the scenario's
   own `reason` fields are the only source; questions the trace cannot
   answer escalate honestly. NEW-02 scenario-bank coverage for the
   Navigator + gate run.
7. **WS01 UI (Plan)**: the triad — Canvas: scenario cards (terms, cost,
   risks — Pareto columns render as "coming" until NEW-04/STX-12, no fake
   numbers), adopted path, term plan, ETA bands; Companion: Navigator
   bias (extend `WORKSPACE_AGENT_BIAS`); Missions: adopt / replan /
   advisor co-review (one click, propose-tier for minors/at-risk).
   Compassionate-recalculating copy rule: reroutes framed as *new best
   route from here* — "you lost X" formulations are prohibited (grep the
   i18n keys in review).

## Verifications
- **V1** determinism: fixture graph snapshot — same
  `inputs_fingerprint` ⇒ byte-identical `steps[]` across repeated runs
  and across recompute; fingerprint changes when any input changes.
- **V2** `PREREQUISITE_FOR` ordering property test: no generated plan
  places a course before its prerequisite closure (fuzz over fixture
  graphs).
- **V3** recompute completes async < 60 s (fixture-scale smoke) and
  path-health cached read p95 < 300 ms.
- **V4** `path.replanned` emitted **only** on adoption — recompute alone
  emits nothing; adoption emits exactly once (mesh fixture).
- **V5** R7 contract: Navigator narration is built from the persisted
  scenario trace and cannot add or alter steps (unit — narration input is
  the scenario row, not the model's imagination); "I don't know" path
  renders honestly.
- **V6** migration up/down/up clean · `pytest -m phase1` green · Navigator
  harness run green before any `deployed` transition.

## DoD
V1–V6 green · constitution §9 marked implemented (+ §3 `eta_service` row
corrected) · BOOK-14 Annex rows (position sources, ETA, prereq logic,
guidance surfaces) updated · TRACEABILITY K3 row updated · design-review
note in `docs/sprint_decisions_*.md` · next: NEW-04 swaps in the full
compiler behind this sprint's map interface.
