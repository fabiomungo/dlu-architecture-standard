# K3 Navigation & Evidence — Exit Report

**Phase:** K3 (BOOK-20 roadmap) · **Target repo:** `dlu_builder_tk`
**Executed:** 2026-07-19 → 2026-07-22 · **Sprints:** STX-07, NEW-04, STX-08,
STX-12, NEW-05, STX-11, STX-09, STX-10 (8/8 ✅ — the full STX-07…12 +
NEW-04/05 set the pack named; NEW-06 Thesis/Committee was NOT executed
this pass — see §6)
**Execution order:** STX-07 → NEW-04 → STX-08 (parallel spine start) →
STX-12 → NEW-05 → STX-11 → STX-09 → STX-10 (the two independent spines —
navigation `STX-07→NEW-04→STX-12` and evidence `STX-08→NEW-05→STX-11` —
ran in the sequence documented by the pack's own dependency graph; STX-09
and STX-10 followed last per their own explicit `STX-09 → STX-10`
ordering note, since STX-10's Coach review-mission wiring needed STX-09's
recommendation slate to be real, not a stub).

---

## 1. Exit gate assessment (pack README)

The pack README's exit gate is two-layered: (a) every sprint's own V1–Vn
checks, and (b) the BOOK-20 §8.1 DAS-Core conformance suite as
INFRASTRUCTURE (cross-cutting CI gates, fuzz/chaos suites, NFR
dashboards). (a) is fully green. (b) is **partially** built — the pieces
each sprint's OWN scope required exist and are real; the items that were
never any single sprint's explicit deliverable were not built as
standalone K3 infrastructure. Both are reported honestly below, not
conflated.

| Gate criterion | Status |
|----------------|--------|
| Every K3 sprint's own V1–Vn checks green | ✅ 8/8 sprints, no exceptions — see §2 |
| Sole-writer / sole-mapper CI grep gates | ✅ `scripts/ci/check_evidence_sole_writer.sh`, `check_identity_reconciliation_sole_mapper.sh` (STX-08), `check_kg_staging_reads.sh` (STX-05, K2-era, still enforced) |
| STX-03 mesh V1–V5 as a permanent suite | ✅ `tests/test_stx03_event_mesh_integration.py` — unchanged, still green after every K3 sprint |
| GPS determinism / evidence append-only / twin single-door / KG fire-and-forget contract tests | ✅ each enforced where the OWNING sprint's own service lives (`academic_gps_service.py`, `competency_graph_service.py`, `twin_context_service.py`, `kg_overlay_sync.py`) — real, but as per-service unit tests, not a single named "engine contract" suite |
| Every K3 agent through the NEW-02 gate (scenario bank coverage) | ✅ 6 agents now have complete 9-class scenario banks (`discovery`, `academic_navigator`, `recognition`, `assessment`, `subject_tutor`, `learning_coach`) — **none has actually RUN `/gate` + been steward-signed yet**; that is an explicit operational action this report does not claim happened |
| `pytest -m phase1` stable | ✅ unchanged baseline throughout — see §3 |
| K3 KPI wave wired (learning gain/durability, rec acceptance, GPS adoption + replan stability, evidence balance dashboards) | ⚪ **NOT built.** No sprint in this pack had a KPI-dashboard deliverable in its own V-checks; this is a genuine gap, not a silent omission — see §6 |
| Cross-tenant leakage fuzz (API + graph + streams + cache, one coherent suite) | ⚪ **NOT built as a unified suite.** Per-feature tenant-scoping is real and tested (e.g. STX-08's institution-scoped trust table, STX-05's KG tenant filters) but no dedicated K3 fuzz harness exists — see §6 |
| Driver bulkhead chaos tests | ⚪ **NOT built this phase.** `tests/chaos/test_pi2_disaster_recovery.py` predates K3 (PI-2 era) and was not extended for K3's new drivers — see §6 |
| Gateway-only egress CI gate (grep-enforced "no direct provider calls") | ⚪ **NOT built.** Every sprint's own LLM calls go through `LLMClientFactory`/the ACP gateway by construction (verified per-service), but no repo-wide CI grep exists to catch a future regression — see §6 |

**Verdict: every sprint's own functional exit gate PASSED (8/8). The
broader DAS-Core conformance-suite INFRASTRUCTURE items BOOK-20 §8.1
names are partially built — real where a sprint's own scope required
them, absent where none did. K4 prompts can reasonably be requested on
the strength of the functional delivery, with the infrastructure gaps
carried forward explicitly (§6), not silently absorbed into "exit gate
passed."**

---

## 2. Per-sprint delivery and verification outputs

### STX-07 — Academic GPS core + Navigator Agent + WS01 (✅ 2026-07-19)

Delivered: `AcademicGPSService` (`fastest_path` + path-health on a v1
term-indexed closure over existing prerequisite/offering data),
`path_scenarios` table, `/api/gps` routes, the Academic Navigator agent
(first agent seeded after Discovery), WS01 Academic Journey UI. The other
3 GPS scenarios (`best_career_path`/`lowest_cost`/
`highest_competency_growth`) were honestly rendered `not_yet_available`,
pending NEW-04's Pareto engine and STX-12's real inputs.

### NEW-04 — RouteGraph compiler (✅ 2026-07-19)

Delivered: the seven-type edge taxonomy, `route_graph_versions`
persistence, a real deterministic Pareto engine, the full BOOK-14 Ch. 6.1
traffic table + hysteresis, the G7 regulation-year tag (version-inert,
test-proven), and a sovereignty guard enforced at construction (a closed
six-dimension `EdgeWeight`, never a learner-conditioned routing weight
smuggled in).

### STX-08 — Evidence Pipeline (✅ 2026-07-19, parallel spine start)

Delivered: `AssessmentEvidenceService` (the sole writer of
`EvidenceRecord`, Celery consumer on the new `evidence-pipeline` mesh
group), the institution-scoped trust table, triangulation (Ch. 4.3),
sole-writer + identity-sole-mapper CI grep gates, and the evidence
timeline API.

### STX-12 — Recognition Agent + GPS scenarios 2–4 (✅ 2026-07-19)

Delivered: `recognition_claims` + calibration + hedge plans, a yield
estimator that honestly separates credit band / eligibility /
probability (never conflating "estimated credit" with "granted credit"),
live `RECOGNIZE` edges (a position effect on the route, not a routing
weight — sovereignty-preserving), `highest_competency_growth` made real
when a recognize-vs-enroll choice genuinely exists, and the evidence-
ceiling gap closed in `competency_graph_service.next_status`.
`best_career_path`/`lowest_cost` were premise-corrected to stay
`not_yet_available` (their literal Book wording described signals this
sprint does not, and by sovereignty design should not, compute inside a
shared cache) — WS02 frontend and the NEW-02 gate run were explicitly
deferred.

### NEW-05 — AssessmentSession, the Appello Aggregate, G2 (✅ 2026-07-19)

Delivered: native/mirror session modes, per-enrollment one-shot grade
refusal (reusing the existing `assessment.completed` consumer with a
mandatory `trust_class` override), minimum-session policy audit + I4
alert at calendar publication, and live `SIT_EXAM`/`RETAKE` edges in
`route_graph_compiler.py`. Found and fixed a real orphaned-router
registration gap in `main.py` (STX-07's `/api/gps` and STX-12's
`/api/recognition` were imported but never mounted — invisible to every
existing test, since both prior sprints tested their service layers
directly, never the route prefix).

### STX-11 — Assessment Agent + WS06 (✅ 2026-07-20)

Delivered: the "skills vs. moves" reading key resolving an apparent
BOOK-10/BOOK-15 inconsistency (no move-catalog RFC needed); the
calibration loop closed for real for the first time
(`mean_observed_outcome` actually written, not just declared); ephemeral
propose-tier viva dossiers via the existing `move_proposal_service`;
`CompetencyGraphService.verify()` extended (not duplicated) with
optional `source_kind`/`evidence_type`/`trust_class` kwargs; honest
classical item-analysis statistics (facility + corrected point-biserial,
deliberately not a fitted IRT/2PL); grading assistance that writes only
`StudentExamAttempt.ai_feedback_json`, structurally incapable of applying
a grade. Backfilled STX-12's missing scenario bank (a real, pre-existing
gap: Recognition could never have legitimately gated before this fix).

### STX-09 — Recommendations v2 + WS03 (✅ 2026-07-21)

Delivered: the three-stage pipeline (existing rule engine + STX-05's
previously-dead-code `kg_query_service.frontier`/`gap` + SM-2 due
reviews), real idempotency/consent-degradation/serendipity, the `reco`
mesh consumer going real, and the WS03 contest affordance. Found and
fixed two genuine bugs: a SQLAlchemy `JSON`/`nullable=False` semantics
gap (`None` silently serializes to the JSON string `"null"`, not SQL
`NULL`, unless `none_as_null=True`) and a second occurrence of NEW-05's
own `index=True`-vs-explicit-`Index()` collision bug, this time in
`models_review.py`. Corrected a stale doc-drift in the constitution's
§18 phasing table that had WS03/WS04 swapped between STX-09/STX-11
relative to the pack's own dependency graph.

### STX-10 — Subject Tutor + Learning Coach + WS04/WS05 (✅ 2026-07-22)

Delivered: the R4 symbolic hint ladder (`tutor_dialogue_service.py` —
NOT `learner_tutor_service.py`, a naming correction: that file is an
unrelated CCP content-recommendation service), engaging only within a
genuine BKT-derived struggle and never bypassable by pressure phrases
(no catalog move means "state the answer directly"); `MOVE_CONSULTS`
populated for the first time (`reframe_goal` → Subject Tutor + Learning
Coach, needing zero changes to the existing L4 escalation gate since
`reframe_goal` was already `plan`+`propose`); `_consult` implemented for
real (previously `NotImplementedError`); Learning Coach etiquette
(`coach_etiquette_service.py`) closing a real, previously-unenforced
quiet-hours/daily-cap gap.

---

## 3. Regression evidence

- Full non-integration/non-slow suite, run after every sprint: stable at
  **84 pre-existing, unrelated failures** throughout (SAML cert fixtures,
  Kong config, RAG chromadb/tenacity dependency issues, frappe
  tenacity dependency, Stripe/security pi3 tests, KG staging-gate
  permissions) — verified NOT caused by this pack's own changes (STX-09's
  own regression check reproduced the suspicious `test_api.py` failures
  against a `git stash`-clean pre-sprint tree to confirm this, rather than
  assuming).
- Passed count grew monotonically with each sprint's own new tests, never
  regressing: **2230 → 2244 (STX-11) → 2274 (STX-09, +14) → 2292 (STX-10,
  +18)** in this session's own measured runs (earlier sprints' counts per
  their own decisions notes).
- Every sprint's migration verified upgrade → downgrade → upgrade against
  an isolated, disposable Postgres 15 (+ pgvector where the base image
  needed it) container — never the shared dev stack.

## 4. `git diff --stat` (implementation repo, K3 range: `f04bb14`..`631ca85`)

```
99 files changed, 17650 insertions(+), 171 deletions(-)
```

Commit series on `stx07-work`:
- `b9bbbea` / `330ca8d` — feat(das-stx07): Academic GPS core + Navigator agent (backend) / WS01 frontend
- `71f5a14` — feat(das-new04): RouteGraph compiler + Pareto engine + hysteresis
- `0c963b1` / `4f35bb8` — feat(das-stx08): evidence pipeline (+ merge from an orphaned agent worktree)
- `0bace01` — feat(das-stx12): Recognition Agent + full scenario set
- `ee2a8ec` — feat(das-new05): AssessmentSession — the Appello Aggregate
- `95a7023` — feat(stx-11): Assessment Agent + WS06 Examination & Mastery
- `bd0e0be` — feat(stx-09): Recommendations v2 + WS03 Personal Knowledge Map
- `631ca85` — feat(stx-10): Subject Tutor + Learning Coach agents + WS04/WS05

## 5. Register updates (this repo)

- **TRACEABILITY:** K3 Navigation & Evidence row marks all 8 sprints
  delivered with full technical detail; the "Blocking dependencies"
  paragraph records each sprint's downstream unlock (STX-08✅→credential
  work, STX-12✅→NEW-06/K4 wallet import, NEW-04✅→NEW-05, NEW-05✅→STX-11,
  STX-09✅→STX-10) and explicitly states the K3 phase pack is now fully
  delivered.
- **Annexes:** BOOK-14 (RouteGraph/GPS scenarios, Annex A rows for the
  query facade + learner plane), BOOK-15 (evidence pipeline, viva
  dossiers, item analytics, AssessmentSession), BOOK-01 (personalization
  guardrails, spaced repetition, open learner model, Socratic tutoring),
  BOOK-09 (`MOVE_CONSULTS` populated for real, engine skeleton gap note
  corrected), BOOK-10 (six of nine agents now delivered — Discovery,
  Academic Navigator, Recognition, Assessment, Subject Tutor, Learning
  Coach — all `lifecycle_state="testing"`), BOOK-11 (R4 dialogue engine,
  with the `learner_tutor_service` naming correction), BOOK-13 (KG query
  facade's `frontier`/`gap` finally wired to a real caller).
- **Constitution** (`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`): §9
  subsections 9.3–9.8 (one per K3 sprint), §10 (Recommendation Engine v2),
  §11 (Evidence Pipeline), §13 (models + migration chain through
  `20260722_0900`), §14 (API surface, one row per new router), §15
  (workspaces WS01–WS06 marked implemented), §18 (phasing table corrected
  where it had drifted from the pack's actual dependency graph).
- **Design decision docs** (one per sprint, `docs/sprint_decisions_*.md`
  in `dlu_builder_tk`): all 8 sprints have one; STX-07, NEW-04, and STX-12
  went through an opus-class design review on their highest-stakes
  surfaces (routing determinism, edge taxonomy/Pareto/hysteresis,
  yield-estimator/hedged-plan design respectively) per the pack's own
  model recommendation table.

## 6. Residual debt / carried forward

| Item | Owner | When |
|------|-------|------|
| K3 KPI dashboards (learning gain/durability, rec acceptance, GPS adoption + replan stability, evidence balance) — no sprint had this as an explicit deliverable | K4/ops | before any GA claim resting on these metrics |
| Cross-tenant leakage fuzz as ONE coherent suite (API + graph + streams + cache) — per-feature tenant scoping is real and tested, but no unified fuzz harness exists | K4+ | a dedicated hardening pass, not a per-agent sprint's natural scope |
| Driver bulkhead chaos tests for K3's new drivers (GPS/Recognition/Evidence/Assessment/Recommendations/Tutor-Coach) — `tests/chaos/` predates K3 and wasn't extended | K4+ | alongside NFR hardening |
| Gateway-only egress CI gate (repo-wide grep enforcing "no direct provider calls") — every sprint's OWN calls go through the gateway by construction, but nothing catches a future regression automatically | K4+ | cheap, should be prioritized early in K4 |
| None of the six seeded agents (Discovery, Academic Navigator, Recognition, Assessment, Subject Tutor, Learning Coach) has actually RUN `/agents/{id}/gate` + been steward-signed — all real scenario-bank coverage exists, but the operational gate action itself hasn't happened for any of them | ops/steward action | before any `deployed` transition |
| `MOVE_CONSULTS` has exactly one entry (`reframe_goal`) — real and production-reachable, but the other `plan`+`propose` catalog move set is empty; a Tutor/Coach-owned move consult (e.g. `hint`) would require generalizing `_choose_escalation`'s L4 gate, deliberately not done this pack (would add blackboard-consult cost to every routine hint delivery) | future sprint, if wanted | when a second real consult need arises |
| Calibration seeding/outcome-tracking covers `recommend_next` (Discovery, Assessment/readiness) only — Recognition's own predictive moves are STX-12's own documented gap, not newly found here | K4+ | as more predictive moves get bound |
| Rubric/equity floors, salience-scoring weights, ranking weights (recommendation stage-2), serendipity quota, and hint-giveup limits are ALL v1 policy knobs (documented as such in each sprint's own decisions note — no Book-specified numbers exist for any of these) | ongoing calibration | per-institution tuning as real usage data arrives |
| NEW-06 (Thesis + Committee, G5/G6) — named in the K3 pack's own dependency graph as needing only STX-08, never blocked by anything else in this report — was NOT executed this pass; still open | K4+ or a dedicated pass | whenever prioritized |

## 7. Next

Request/author the **K4 Trust & Institution pack** (STX-13…15 · NEW-07,
08, 09, 10 — BOOK-16/08/07/17). No K4 prompt pack existed in this repo
before this report; the sprint prompts for STX-13 (Credential engine +
Credential Agent + WS07) and STX-14/15 (Student Success + Career Advisor
agents + WS08) are authored alongside this report, derived from
BOOK-20 Ch. 6's existing blueprint (`STX-13 + NEW-07`, `STX-14/15`) and
BOOK-10 Ch. 3's agent cards, at the sonnet-appropriate scope this pack's
own model-recommendation convention would assign (agent registration +
kernel-object CRUD is implementation work, not an architecture decision)
— with a design-review flag on the ONE genuinely hard-to-reverse surface
in STX-13 (verifiable-credential signing scheme) called out explicitly
rather than silently scoped down.

Blocking dependencies honored: STX-08 ✅ → credential work (STX-13+,
consumes `triangulation_status`); STX-12 ✅ → NEW-06 committee flows +
K4 wallet import (both still open, tracked in §6, not part of this
request); NEW-05 ✅ → STX-11 ✅ (closed); STX-09 ✅ → STX-10 ✅ (closed).
