# Sprint NEW-04 — RouteGraph Compiler + Session Edges + Pareto Engine
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-07

## Role
`backend-dev`, with an opus-class design review on the edge taxonomy,
Pareto engine and hysteresis policy before implementation — these are
hard to reverse once scenarios are adopted (DAS BOOK-14 Ch. 3/5/6).

## Context — read before coding
1. BOOK-14 Ch. 3 (the compiled map: four input layers → term-indexed,
   learner-conditioned RouteGraph; the seven-type edge taxonomy with
   weight vector `⟨time, cost, effort, probability, competency_gain,
   career_alignment⟩`; the **examination-decoupled model** — G2,
   normative: attendance and examination are separate route segments,
   session granularity where `AssessmentSession` calendars exist),
   Ch. 5 (engine: label-correcting multi-criteria search, four named
   objectives as points on the Pareto frontier, ≤ 8 scenarios, hard
   constraints, fingerprint, budgets), Ch. 6 (traffic table, hysteresis
   >5% reference threshold, batch replan, `pending_verbalization` — G3),
   Ch. 8.2 (objective sovereignty — **testable**: weight vectors
   inspectable in the fingerprint, capacity is a constraint never a
   preference).
2. **Strangler contract (pack decision, README):** STX-07 shipped
   `fastest_path` + path-health on a v1 map behind a swappable map
   interface. This sprint replaces the v1 map with the full compiler
   **behind the same `AcademicGPSService` contract** — `/api/gps`, the
   `PathScenario` schema and STX-07's V-suite must stay green untouched.
3. **Edge realism boundary:** `ENROLL` edges are fully real (offerings +
   prerequisites). `SIT_EXAM`/`RETAKE` edges are **fixture-fed until
   NEW-05** lands the `AssessmentSession` aggregate (then its feed goes
   live — build the feed seam now). `RECOGNIZE`/`CHALLENGE` edges carry
   estimator stubs until STX-12 (claim inventory + yield estimator);
   `MILESTONE` until NEW-06 (thesis/committee); `FEDERATED` needs
   federation policy objects (K4+ — model the type, mark inactive).
   Every stubbed edge type is type-complete and property-tested against
   fixtures; none renders to learners as available before its feed
   exists.
4. Existing (repo-verified): STX-07's map interface + `path_scenarios` +
   Celery recompute; `prerequisite_service` / `curriculum_graph_service`;
   `kg_query_service` (constitution §6.4 canonical GPS query); event
   mesh consumers (`event_consumers.py` — note `reco`/`success-watch`
   groups are logging stubs, don't touch them here); `identity_map`;
   ERPNext cost mirror fields on L2. Migration chains off the current
   head (check `migrations/versions/` — after STX-07's migration).
5. G7 (regulation-year binding): policy objects are versioned; a
   learner's plan validates against **their cohort's** regulation year,
   not the latest. Policy-version participates in the fingerprint.

## Deliverables
1. **Compiler** (`route_graph_compiler.py` or module within the GPS
   service): AKN P-DEF/P-CUR structure (`PREREQUISITE_FOR`, `DEVELOPS`,
   `ALIGNED_TO`, `AWARDS`) + offering calendar (sections/terms, capacity)
   + policy objects (recognition rules, credit caps, G7 regulation-year,
   federation agreements) + learner constraints (availability, finances,
   modality) → `RouteGraph(term-indexed, learner-conditioned)`.
   Deterministic; cached per `(tenant, term_horizon, policy_version)`;
   learner conditioning applied at query time; `route_graph_versions`
   persistence (additive migration) so every scenario cites its map
   version.
2. **Edge taxonomy** — all seven types with the six-dimension weight
   vector: `ENROLL(course, term)`, `RECOGNIZE(claim)`,
   `CHALLENGE(assessment)`, `FEDERATED(course@partner)`,
   `SIT_EXAM(assessment_session)`, `RETAKE(assessment_session)` (incl.
   grade-refusal expected-value semantics — policy caps on attempts),
   `MILESTONE(thesis, viva, committee)`. Session granularity per the
   examination-decoupled model: missing a session is modeled traffic,
   not noise.
3. **Multi-objective Pareto engine**: label-correcting multi-criteria
   search returning the frontier (≤ 8 scenarios) with the four named
   objectives (`fastest_path`, `best_career_path`, `lowest_cost`,
   `highest_competency_growth`) as named points. Hard constraints:
   prerequisite closure, calendar + capacity, regulation-year validity
   (G7), credit caps, financial holds (block enrollment edges, **never**
   touch earned evidence). Objectives 2–4 compute from whatever inputs
   exist (fixture-tested); they go learner-real at STX-12.
4. **Traffic consumers + hysteresis**: implement the full BOOK-14 §6.1
   invalidation table on the mesh (grade/assessment → re-fix + re-score
   with `pending_verbalization` provisional semantics;
   `assessment_session.published/changed` → recompile affected region +
   edge refresh; competency events → re-fix, may unlock CHALLENGE;
   recognition decisions → position jump / hedge activation;
   offering/policy/term changes → recompile + **batch replan** of
   affected learners; goal change → full recompute; `risk.detected` →
   health degradation flag). Hysteresis: the adopted path is replaced
   only when a better route improves the learner's declared objective
   > 5% (policy knob, documented) or on infeasibility — otherwise
   proposals accumulate quietly in path-health.
5. **Budgets**: compilation cached; incremental re-scoring of the
   adopted path < 5 s on minor events; full recompute stays < 60 s
   async; degradation = stale plan served **with staleness notice**,
   never silent.
6. **Objective sovereignty, enforced**: the weight vector per objective
   is data, inspectable in the fingerprint; no institutional-preference
   term exists in any objective (capacity/holds are constraints). Add
   the sovereignty audit as a permanent test, not a review note.

## Verifications
- **V1** constraint violations impossible — property tests fuzzing
  fixture graphs: no plan violates prerequisite closure, term
  availability, or regulation-year (G7 fixture: same program, two
  regulation years ⇒ different valid plans).
- **V2** Pareto set non-dominated check: no returned scenario is
  dominated on all objectives by another returned scenario; the four
  named scenarios are members of (or projections onto) the frontier.
- **V3** hysteresis: minor event (small mastery gain) ⇒ adopted path
  unchanged, no `path.replanned`, proposal visible in path-health;
  infeasibility event (offering cancelled) ⇒ replan proposed; adoption
  still the only emitter.
- **V4** objective weights inspectable in the fingerprint (sovereignty
  audit): recompute with an injected institutional-preference weight
  fails the audit test.
- **V5** `pending_verbalization`: pedagogical result moves the position
  provisionally + marks the segment; `grade.synced` confirms and clears
  (G3 fixture).
- **V6** strangler: STX-07's full V-suite green unchanged on the new
  compiler · migration up/down/up clean · `pytest -m phase1` green.

## DoD
V1–V6 green · BOOK-14 Annex rows (map inputs, scenarios engine,
session-granular routing, traffic/invalidation) updated · constitution §9
compiler note added · TRACEABILITY K3 row updated · design-review note in
`docs/sprint_decisions_*.md` (edge taxonomy + hysteresis decisions) ·
next: NEW-05 feeds SIT_EXAM/RETAKE live; STX-12 makes RECOGNIZE real +
scenarios 2–4 learner-real.
