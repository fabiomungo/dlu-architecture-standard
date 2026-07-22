# BOOK-14 — Academic Intelligence Navigator (Academic GPS)
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The program's key differentiator. The Academic GPS answers, **in real time and
> from any starting point**, the question no university system answers today:
> *"Given everything I am and everything I have already done — anywhere — what
> is my best route to where I want to be?"* Its distinctive power is
> **recognition-aware routing**: prior experience matured elsewhere (courses,
> certifications, work, other institutions) is not a clerical afterthought but a
> set of **route segments** the optimizer evaluates like any other — because for
> a transfer student or professional learner, the fastest path usually starts
> with getting credit for the road already traveled.
>
> **Conforms to:** BOOK-00 v2.0 (Question 4). **Depends on:** BOOK-06 (position =
> twin), BOOK-13 (the map = AKN), BOOK-04 (offerings, terms), BOOK-10
> (Recognition Agent, Navigator). **Informs:** BOOK-15 (assessment-only moves),
> BOOK-17 (WS01/WS02).
> **Implementation profile:** constitution §9 (AcademicGPSService, STX-07/12).
> **Primary audience:** architects, product, registrars, advisors.

**Normative language:** RFC 2119. The automotive metaphor is carried through
precisely because it decomposes the system correctly: **positioning, mapping,
routing, guidance, rerouting** — five subsystems, five chapters.

---

# Chapter 1 — Thesis

Five capabilities define the GPS; together they are the differentiation:

1. **Any origin.** The route computation makes no assumption of a "freshman
   start": the origin is the live twin state — including competencies evidenced
   anywhere (BOOK-06 L3/L4) and *potential* credit not yet claimed (Ch. 2).
2. **Recognition-aware.** Recognition of prior learning (RPL), transfer credit,
   challenge exams and federated course-taking are **edges in the route graph**
   with cost, time, probability and yield — optimized jointly with ordinary
   enrollment (Ch. 4).
3. **Real time.** The plan reacts to events like a GPS reacts to traffic:
   grades, offering changes, recognition decisions, goal changes → invalidation
   and reroute with stability discipline (Ch. 6).
4. **Deterministic and explainable.** Routing is graph search, never LLM
   inference (BOOK-03 §3.8); every step carries its reason; every scenario is
   reproducible from its input fingerprint (Ch. 5, 8).
5. **Learner-sovereign.** Objective functions are the learner's declared
   preferences (the four canonical scenarios + Pareto alternatives) — never the
   institution's revenue (Ch. 8).

---

# Chapter 2 — Positioning: the Academic Fix

The GPS fix is richer than "credits earned":

| Component | Source |
|-----------|--------|
| Verified position | L3 competency state (evidence-backed), L2 academic mirror (official credits — ERPNext/ESSE3) |
| Fine position | L4 mastery (concept-level — distinguishes "passed the course" from "still owns the knowledge"; decay-aware) |
| **Position potential** | unclaimed prior learning: uploaded transcripts, certifications, work history (ESCO-mapped), portfolio artifacts — detected by Discovery/Recognition agents but not yet adjudicated |
| Destination | L5 career goals (ESCO occupations) and/or chosen credential/program |
| Constraints | L2 (regulation-year binding — G7), financial state, declared availability (persona: professional learners route around work) |

**Position uncertainty is a first-class concept:** unclaimed potential means
the learner may be *further along than the map shows*. The GPS quantifies this
("up to 24 ECTS of your prior experience may be recognizable") and — crucially —
**routing to resolve the uncertainty (filing recognition claims) is itself a
route segment** (Ch. 4). Cold start: Discovery dialogue + diagnostics seed the
fix (BOOK-06 Ch. 4.1).

---

# Chapter 3 — Mapping: the Route Graph

The routing map is **compiled** — a term-indexed graph built from four layers:

```text
AKN P-DEF/P-CUR (BOOK-13)      structure: PREREQUISITE_FOR, DEVELOPS, ALIGNED_TO, AWARDS
+ Offering calendar             which course-sections run in which terms (TeachingSection, AcademicTerm), capacity
+ Policy objects                recognition rules, credit caps, regulation-year constraints (G7), federation agreements (BOOK-02 Ch. 10)
+ Learner constraints           availability, finances, location/modality
→ RouteGraph(term-indexed, learner-conditioned)
```

**Edge taxonomy** — every edge carries the multi-dimensional weight vector
`⟨time, cost, effort, probability, competency_gain, career_alignment⟩`:

| Edge type | Meaning | Weight notes |
|-----------|---------|--------------|
| `ENROLL(course, term)` | take an offered section | time = term slots; cost = tuition share; gain from `DEVELOPS` strengths |
| `RECOGNIZE(claim)` | file a recognition claim for prior learning | time = dossier + adjudication SLA; cost ≈ fees; **probability from policy + historical decisions**; yield = credits/competencies granted |
| `CHALLENGE(assessment)` | assessment-only credit (exam without the course), where policy allows | probability from L4 mastery (the fine fix predicts pass likelihood) |
| `FEDERATED(course@partner)` | mobility segment at a partner institution | governed by federation policy objects; recognition-on-return encoded |
| `SIT_EXAM(assessment_session)` | sit a scheduled exam session (**appello** — G2), decoupled from course attendance | time = session calendar granularity; probability from L4 mastery + readiness; capacity/enrollment windows |
| `RETAKE(assessment_session)` | re-sit after failure — or after **grade refusal** (rifiuto del voto), where policy allows declining a passing grade to improve it | expected-value decision: probability of improvement (L4 trend) vs time cost; policy caps on attempts |
| `MILESTONE(thesis, viva, committee)` | capstone segments (G5/G6 aggregates) | scheduled against committee availability |

**Examination-decoupled model (G2, normative):** the edge taxonomy MUST NOT
assume the Anglo pattern *course completion ⇒ grade at term end*. In the
Italian model (and any deployment with discrete exam sessions), attendance and
examination are separate route segments: a learner may complete a course and
sit the exam one, two or five sessions later — and each deferral compounds
(the *fuori corso* drift). The RouteGraph therefore plans at **session
granularity** where `AssessmentSession` calendars exist (minimum-sessions
rules, enrollment windows, per-session capacity — mirrored from ESSE3 where it
is the system of record, BOOK-07 §6.3): "which appello to target" is a routing
decision with the same standing as "which course to take". Missing a session
is modeled traffic, not noise.

The compiler is deterministic and cached per (tenant, term-horizon,
policy-version); learner conditioning is applied at query time. Map quality
inherits AKN hygiene (BOOK-13 Ch. 4) — a wrong prerequisite edge is a wrong
route, which is why curriculum analytics (bottlenecks, orphans) are
route-quality work too.

---

# Chapter 4 — Recognition-Aware Routing (the differentiator)

## 4.1 Recognition as optimization, not paperwork

For a transfer student, the optimal plan is usually *recognition-first*: which
claims to file, in which order, before enrolling in anything. The GPS treats
this as portfolio optimization:

- **Claim inventory:** Recognition Agent extracts candidate claims from
  documents/experience (BOOK-10) → each becomes a `RECOGNIZE` edge with
  estimated `⟨effort, probability, yield⟩`.
- **Yield estimation:** syllabus similarity (embeddings + AKN mapping of the
  external course — `ExternalCourse` data), framework crosswalks (CASE/ESCO for
  certifications), institutional policy caps (max recognized credits,
  regulation-year applicability), and **historical adjudication data** (what
  this institution's registrar has granted for similar claims — probability
  calibrated per BOOK-09 Ch. 7 discipline).
- **Strategy output:** the recognition plan is part of every scenario:
  *"file these 4 claims (expected 21±6 ECTS, ~3 weeks); enroll in these 2
  courses meanwhile; if claim #3 is rejected, the fallback adds one term."*
  Contingent routing — plans carry their main line and their hedges.

## 4.2 HITL boundary (constitutional)

The GPS **plans with probabilities; humans decide the facts.** Claims are
prepared by the Recognition Agent (propose), adjudicated by the registrar
(reserved — BOOK-02 Ch. 4; committee flows where required, G6). Every decision
event (`competency.updated`, credit granted/denied) re-fixes the position and
triggers reroute (Ch. 6). The GPS MUST NOT present expected yield as granted
credit — probability is rendered honestly (Ch. 8).

## 4.3 Experience matured anywhere

The claim taxonomy is open by design: other universities (transcripts —
including via federation policy objects), professional certifications
(framework-mapped), MOOCs/micro-credentials (OB 3.0/CLR import — BOOK-16),
work experience (ESCO occupation history → competency claims at `evidenced`
ceiling until humanly verified — BOOK-01 rules), portfolio artifacts
(assessed via authentic-assessment paths — BOOK-15). Each source type carries
its trust weight and its adjudication path; none is invisible to routing.

---

# Chapter 5 — Routing Engine

1. **Algorithm class:** deterministic multi-objective search on the
   term-indexed RouteGraph (label-correcting / multi-criteria shortest path);
   heuristics calibrated from AKN path statistics (BOOK-13 Ch. 7).
   No LLM anywhere in the loop (BOOK-03 §3.8).
2. **Objectives:** the four canonical scenarios (constitution §9.2 —
   `fastest_path`, `best_career_path`, `lowest_cost`,
   `highest_competency_growth`) are named points on the **Pareto frontier**;
   the engine returns the frontier (reference: ≤ 8 scenarios) so trade-offs are
   visible, not hidden.
3. **Hard constraints:** `PREREQUISITE_FOR` closure (A8 canonical), offering
   calendar and capacity, regulation-year validity (G7), credit caps, financial
   holds (which block enrollment edges but never touch earned evidence —
   BOOK-02 §8.2).
4. **Reproducibility:** `inputs_fingerprint = sha256(fix, map version, policy
   versions, constraints)` persisted per scenario (constitutional §9.3);
   same fingerprint ⇒ same output, testable.
5. **Budgets:** full recompute async < 60 s (constitution); incremental
   re-scoring of the adopted path on minor events < 5 s; compilation cached.

---

# Chapter 6 — Real-Time: Traffic, Reroute, ETA

## 6.1 The traffic table (invalidation events)

| Event | Effect |
|-------|--------|
| `grade.synced`, `assessment.completed` | position re-fix; adopted-path health re-score. **Verbalization latency note (G3):** in deployments where the legal grade act is external (ESSE3 verbale), the official fix lags the pedagogical result — the GPS uses the pedagogical signal provisionally, marks the segment `pending_verbalization`, and confirms on `grade.synced` |
| `assessment_session.published/changed` (appello calendars — G2) | map recompile for affected courses; SIT_EXAM/RETAKE edge refresh; learners with targeted sessions notified |
| `competency.updated/mastered` | re-fix; may unlock CHALLENGE edges |
| recognition decision | position jump (or hedge activation); reroute |
| offering/capacity change, term rollover | map recompile (affected region); replan affected learners (batch) |
| policy/regulation change (G7) | map recompile; impacted-cohort replan with advisor notice |
| goal change (L5) | destination change; full recompute |
| `risk.detected` | health degradation flag; Navigator+advisor surfaced |

## 6.2 Reroute discipline (stability over cleverness)

A GPS that reroutes on every fluctuation destroys trust. Normative:

- **Hysteresis:** the adopted path is replaced only when a better route
  improves the learner's declared objective beyond a threshold (reference: >5%)
  or when the adopted path becomes infeasible.
- **`path.replanned` is emitted only on adoption** (learner or advisor
  confirms) — proposals accumulate quietly in path-health, they do not nag
  (recommendation idempotency discipline applies).
- **Compassionate recalculating:** failure events (failed exam, rejected claim)
  produce reroutes framed as *new best route from here* — never as loss
  accounting. The UI contract prohibits "you lost X" formulations
  (BOOK-01 P7 competence framing).

## 6.3 ETA and prediction

`evaluate_current_path` runs continuously (constitution §9.1): expected
graduation term (ETA — `eta_service` velocity models), confidence band,
`graduation.predicted` emission for institutional consumers (BOOK-08 I2,
ERPNext via n8n). ETA honesty: bands, not points; assumptions listed
(current pace, offering stability).

---

# Chapter 7 — Guidance: from Scenario to Next Action

1. **Scenario comparison (WS01 contract):** scenarios render as comparable
   cards — terms, cost, career alignment, competency growth, recognition plan,
   risks — with the trade-offs explicit (Pareto honesty). Adoption is one
   action; advisor co-review is one click (propose-tier for minors/at-risk).
2. **Turn-by-turn:** the adopted path unfolds as *this term's plan* →
   *this week's missions*. Strategic vs tactical boundary: **the GPS owns the
   route; the Coach owns the driving** (daily pacing, reviews — BOOK-10). The
   Recommendation Engine's `path_alignment` weight (constitution §10) is how
   the route influences daily suggestions without the GPS micromanaging.
3. **Narration:** the Academic Navigator narrates scenarios strictly via R7
   (BOOK-11) — the step `reason` fields (constitutional: *"unlocks
   PREREQUISITE_FOR chain to C-DB-3"*) are the only source. Questions the
   trace cannot answer escalate to advisors, honestly.

---

# Chapter 8 — Trust, Fairness, Governance

1. **Determinism & audit:** every scenario reproducible (fingerprint), every
   step reasoned, every adoption logged — the GPS is fully auditable route
   advice, which is what lets accreditors and advisors trust it (Track A
   posture).
2. **Objective sovereignty:** objective functions are learner-declared.
   Institutional interests (fill rates, revenue) MUST NOT appear in edge
   weights or scenario ranking — capacity is a *constraint*, never a
   *preference*. This is the anti-dark-pattern line (BOOK-01 Ch. 7.4) and it
   is testable: weight vectors are inspectable in the fingerprint.
3. **Routing equity (blocking guardrail):** scenario quality (time-to-goal,
   cost) is monitored across cohorts (BOOK-08 equity discipline, n≥10
   suppression). Systematically worse routes for a cohort — e.g., recognition
   probabilities depressed for foreign credentials beyond policy justification —
   is an incident, Review-Board class.
4. **Probability honesty:** recognition/challenge probabilities render with
   calibrated hedging (BOOK-09 Ch. 7.3); the calibration source is the
   registrar's actual decision history, refreshed continuously.
5. **Advisor primacy:** advisors see what the learner sees plus the hedge
   structure; GPS proposals never bypass advisor visibility for at-risk
   learners (`purpose=staff_view`, audited).

---

# Chapter 9 — Contracts and Non-Functionals

Service contract per constitution §9.1 (`compute_scenarios`,
`evaluate_current_path`), extended with `estimate_recognition(twin, documents) →
ClaimInventory`, `compile_map(tenant, horizon) → RouteGraphVersion`, and
**`simulate_scenarios(hypothetical_fix, target) → list[PathScenario]` (G15)
— ✅ implemented (NEW-16, 2026-07-27)**:
the what-if engine for prospects and enrolled students alike — a
**hypothetical fix** (self-declared background, sandbox recognition estimates,
candidate program/edition) runs through the same deterministic engine against
a published CatalogEdition, producing exploratory scenarios that are clearly
marked `simulation=true` (no twin writes, no events, no advisor queue). This
is how the catalog becomes *evaluable autonomously*: a prospect simulates
"me + my experience + program X" before ever applying; a student simulates a
minor change or a transfer before committing. Simulations are rate-limited,
anonymous-capable (pre-account) and never persisted beyond the session unless
the user saves them into a Discovery dialogue. **Implementation note**: a NEW
function, never a modification of `compute_scenarios` — reuses the REAL
engine internals (`RouteGraphCompiler.compile()` + the existing ordering
helpers), NOT `route_graph_compiler.py`'s `pareto_frontier`/`rank_candidates`,
which remain fully defined but never called anywhere in the codebase
(confirmed by repo-wide grep) — making the pre-auth simulation surface the
first-ever caller of previously-dead code would have been an unacceptable
risk. Zero-write/zero-event verified by AST-walking the entire reused call
graph for `db.add`/`db.commit`/`emit_async`/`emit_sync` (zero hits) and
regression-locked by a row-count-snapshot test. G7's regulation-year
inertness (NEW-04) is carried forward honestly, not resolved: the pinned
edition is cited/visible on every simulation, but requirement computation
does not yet differ per edition.
Persistence: `path_scenarios` (constitutional) + `route_graph_versions` +
`recognition_claims` (C7/C8 per BOOK-04). Non-functionals: recompute budgets
(Ch. 5.5); path-health read p95 < 300 ms (cached); degradation = stale plan
served **with staleness notice**, never silent (BOOK-03 Ch. 8 discipline);
scenario history retained for audit (retention-classed).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Position sources | twin layers (STX-01/02), BKT ✅, ERPNext/ESSE3 mirror — STX-07's GPS engine reads these as-is via `TwinContextService`/`StudentProgress` | 🟡/🔵 | position-potential inventory ⚪ (still open — `PathHealth.position_potential` is honestly `null` in STX-07's output, not fabricated) |
| Map inputs | AKN ✅ (v2.0 🔵), `TeachingSection`/`AcademicTerm` ✅, ExternalCourse ✅, federation core 🟡, RouteGraph compiler ✅ (NEW-04 — `route_graph_compiler.py`: full seven-type edge taxonomy; `ENROLL`, `RECOGNIZE` ✅ (STX-12 — `recognize_edges_for_twin`, a position effect not a weight, deliberately query-time not baked into the cached compile), `SIT_EXAM` ✅ (NEW-05 — compile()-time, learner-agnostic), `RETAKE` ✅ (NEW-05 — `retake_edges_for_twin`, query-time, twin-specific) all live in production; `CHALLENGE`/`MILESTONE` typed stubs, `FEDERATED` modeled+inactive; `route_graph_versions` persisted, every scenario cites its map version) | 🟡→🔵 | full learner-conditioned map still ⚪ pending K4 (federation policy); `CHALLENGE`/`MILESTONE` await their owning aggregates |
| ETA | **correction (STX-07, repo-verified): `eta_service.py` is a generic job-completion estimator, not an academic model** — new graduation-ETA velocity model built as its own module | ✅ (STX-07, as new work) | confidence tier capped at low/medium (no "high" — needs a real calendar compiler; still ⚪) |
| Prereq logic | `prerequisite_service`, `curriculum_graph_service` | ✅ | term-indexed closure ✅ (STX-07 — `AcademicGPSService._prereq_adjacency`/`_expand_scope`, full transitive closure, property-tested); regulation-year (G7) binding ⚪ — version-TAGGED in the fingerprint (NEW-04) but honestly version-INERT on real data (`program_courses` has no per-version link yet; test-proven inert, not silently claimed as enforced) |
| Scenarios engine | `fastest_path` + path-health ✅ (STX-07); real multi-objective Pareto engine ✅ (NEW-04); `highest_competency_growth` ✅ (STX-12, when a real enroll-vs-recognize choice exists — RECOGNIZE's evidenced-level `competency_gain` vs ENROLL's mastery-level is the honest differentiator NEW-04 found missing) | 🔵→partial ✅ (3/4 scenarios) | `best_career_path`/`lowest_cost` ⚪ — **premise-corrected (STX-12, repo-verified, not a "hasn't landed" placeholder)**: no course-side ESCO crosswalk or per-course cost field exists anywhere in this codebase; both are governed data imports, not sprint-seedable |
| Recognition inputs | Recognition Agent ✅ (STX-12, `lifecycle_state="testing"`, propose-only), plagiarism/doc processing ✅, CASE/ESCO 🔵, yield estimator ✅ (STX-12 — similarity/eligibility-band/credit-band/probability kept as three separate honest numbers, never collapsed; claim-class calibration excludes source institution/country by design — equity guardrail), adjudication-history calibration ✅ (`recognition_calibration_stats`, ≥5 decisions before any numeric probability renders, confidence capped at `medium`) | 🔵→partial ✅ | full ESCO/CASE crosswalk import still 🔵; aggregate "max recognized credits" hard cap ⚪ (named seam, no institution has configured one yet) |
| Session-granular routing (G2) | `AssessmentSession` aggregate ✅ (BOOK-15, NEW-05 — `assessment_session_service.py`, native + mirror-mode contract); `SIT_EXAM` ✅ live (NEW-05 — `_sit_exam_edges`, compile()-time, learner-agnostic calendar existence, `probability=1.0` sovereignty-corrected against Ch. 3's literal "mastery + readiness" wording — no learner-conditioned or capacity-derived signal enters `EdgeWeight`); `RETAKE` ✅ live (NEW-05 — `retake_edges_for_twin`, query-time, twin-specific attempt-cap eligibility, same "internal routing proxy" honesty RECOGNIZE established); traffic wiring ✅ (`gps_traffic_consumers._maybe_rescore_for_session_change` resolves every program offering the changed course via `ProgramCourse`, tenant-scoped through `Institution`, batch-replans each — corrected from a single-twin resolution that was the wrong shape for course-scoped calendar traffic) | ⚪→✅ | ESSE3 appello mirror driver remains NEW-11/BOOK-18 (this sprint ships contract + fixture ingestion only); real mastery-trend RETAKE probability is STX-11's readiness model, not this sprint's |
| Traffic/invalidation | event mesh (STX-03), fingerprints (constitutional) — full BOOK-14 Ch. 6.1 traffic table ✅ (NEW-04): grade/assessment/competency/goal/risk wired + hysteresis (`PathHealth.replan_recommended`, >5% on the adopted scenario's own objective, or infeasibility) + `pending_verbalization` (G3) overlay; "recognition decision" ✅ resolved WITHOUT an event (STX-12 — `AcademicGPSService._denied_hedge`, purely derived from live claim status vs. the adopted scenario's own `hedge_plans`) | 🔵→✅ (7/8 rows) | 1 row has NO mesh event and stays deferred by design: "policy/regulation change" (G7) — closing it needs a cross-repo taxonomy RFC, not attempted here. "Offering/term change → batch replan" is answered WITHOUT an event: `trigger_batch_replan()`, called directly by whatever recompiles a program's map |
| Guidance surfaces | WS01 Academic Journey ✅ (STX-07 — Canvas/Companion/Missions triad, `/student/journey`), Navigator agent ✅ (STX-06 registered, STX-07 moves bound), Recognition agent ✅ (STX-12 registered, propose-only moves bound) — WS02 Credit Recognition backend contract ready (`/api/recognition/claims`, `hedge_plans` on scenarios) | 🔵→partial ✅ | WS02 frontend ⚪ (STX-12 backend delivered; UI is a follow-up pass, same sequencing STX-07 used); scenario-comparison Pareto-column UX (BOOK-17) still renders `best_career_path`/`lowest_cost` as "coming" — honestly, per their corrected premise |
| Equity monitoring | BOOK-08 discipline | ⚪ | routing-equity metrics (rides scorecards) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Academic fix | The learner's full position: verified + fine + potential + destination + constraints |
| Position potential | Unclaimed prior learning quantified as recognizable range |
| RouteGraph | Compiled, term-indexed, learner-conditioned routing map |
| Recognition-aware routing | RPL/transfer/challenge/federated segments optimized jointly with enrollment |
| Hedged plan | Scenario carrying its contingency branches for uncertain claims |
| Hysteresis | Reroute threshold discipline — stability over cleverness |
| Examination-decoupled model | Attendance and examination as separate route segments (G2); session-granular planning |
| Grade refusal (rifiuto del voto) | Policy-allowed declining of a passing grade to retake — modeled as a RETAKE routing decision |
| Pending verbalization | Provisional position state awaiting the legal grade act (G3 latency) |
| Compassionate recalculating | Failure reframed as new-best-route; loss language prohibited |
| Objective sovereignty | Learner-declared objectives only; institutional interests are constraints, never preferences |

---

*BOOK-14 v1.0 — awaiting review. The intelligence spine (13–14) is complete;
next per Chapter 16 order: BOOK-15 (Assessment & Evidence Architecture — owner
of ESSE3 gaps G2/G5/G6).*
