# K3 Prompt Pack — Navigation & Evidence
### DAS BOOK-20 Phase K3 · sprints STX-07…12 · NEW-04, 05, 06 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Prerequisite:** K2 exit gate PASSED (see `../K2/K2-EXIT-REPORT.md`) — the
ACE PDDAEL runtime, move catalog, eval harness (the GA gate) and the
four-store memory architecture are live; every K3 agent sprint ships its
agent through the NEW-02 gate.

**Execution rules:** BOOK-20 Ch. 12 bind every sprint — read them first.
Digest: Turnkey `CLAUDE.md` guardrails are absolute (GUID PKs for new tables,
`Integer` only for FKs to `courses.id`, platform vs tenant schema, async routes
/ sync Celery, additive-only migrations with tested downgrade, soft delete,
no column literally named `metadata`, no cross-file `relationship()`);
all V-checks green before DoD; docs sync in the same change set
(constitution + CLAUDE.md + Book Annexes + TRACEABILITY); G/A-register duty;
ontology naming via `dlu-core.yaml` or RFC first; **all LLM calls via the ACP
gateway (ADR-0013) — never direct provider calls**; **every learner-facing
agent stays `lifecycle_state='testing'` until its NEW-02 harness run is green
and steward-signed — no exceptions.**

## Order and dependencies

```text
STX-07 (GPS core: fastest_path + path-health + WS01 · seeds academic_navigator)
   └─► NEW-04 (RouteGraph compiler + full edge taxonomy + Pareto + traffic/hysteresis)
          └─► STX-12 (Recognition Agent + scenarios 2–4 + hedged plans + WS02)
STX-08 (evidence pipeline — START IN PARALLEL DAY 1; gates all K4 credential work)
   └─► NEW-05 (AssessmentSession G2 — native/mirror, refusal flow; feeds evidence + SIT_EXAM/RETAKE edges)
          └─► STX-11 (Assessment Agent + WS06)
STX-09 (Recommendations v2 + WS03) ─► STX-10 (Tutor + Coach + WS04/05)
NEW-06 (Thesis + Committee — G5/G6; needs STX-08; feeds MILESTONE edges + trust-1.0 evidence)
```

- **Two independent spines.** The navigation spine (STX-07 → NEW-04 → STX-12)
  and the evidence spine (STX-08 → NEW-05 → STX-11) share no blocking edge —
  run them in parallel. STX-09/10 hang off the kernel K1/K2 delivered and can
  interleave; NEW-06 needs only STX-08.
- **STX-07 before NEW-04 (strangler order):** STX-07 ships `fastest_path` +
  path-health on a v1 term-indexed closure over the existing prerequisite/
  offering data; NEW-04 generalizes that map into the full compiler (policy
  objects, G7, session edges, Pareto) *replacing the v1 map in place* — same
  service contract, no API break. This resolves the BOOK-14 Annex A wording
  ("RouteGraph compiler ⚪ (STX-07 core)") against the BOOK-20 NEW-04 card:
  STX-07 owns the core map + contract, NEW-04 owns the full compiler.
- **NEW-04 builds the Pareto engine; STX-12 makes scenarios 2–4 real.**
  NEW-04 delivers the multi-objective machinery (4 named objectives, ≤ 8
  frontier scenarios) fixture-tested; STX-12 wires the inputs that make
  `best_career_path` / `lowest_cost` / `highest_competency_growth`
  learner-real (ESCO alignment, cost mirror, claim inventory + yield
  estimator) and adds hedged recognition plans.
- **NEW-05 before STX-11:** WS06's canvas is the session calendar; the
  Assessment Agent's readiness predictions target sessions. Building WS06
  against a stubbed aggregate wastes a rework cycle (K2 NEW-01 lesson).
- **Agents ship gated.** STX-07 (Navigator), STX-10 (Tutor, Coach), STX-11
  (Assessment), STX-12 (Recognition) each add scenario-bank coverage for
  their agent and pass the NEW-02 gate before any `deployed` transition.

## K2 residual debt — assigned intake

From `../K2/K2-EXIT-REPORT.md` §6; each item has an owning K3 sprint (or an
explicit deferral):

| Debt item | Owner |
|-----------|-------|
| Remaining agents as real `ai_agent_configs` rows | STX-07 (Navigator) · STX-10 (Tutor, Coach) · STX-11 (Assessment) · STX-12 (Recognition) — Success/Career/Credential land in K4 |
| `MOVE_CONSULTS` populated for real L4 blackboard consultation | STX-10 (Tutor↔Coach are the first real consult pair) |
| Discovery `explain_concept` grounding source (program catalog) | STX-09 (the KG/retrieval candidate stage builds the grounding path; full catalog explorer is NEW-16/K4) |
| `ace.py` `/api/brain/memory/{id}` DELETE ownership check | STX-09 (first sprint touching `ace.py`; mechanical fix, do it there) |
| Calibration seeding beyond `recommend_next` | STX-11 (readiness prediction) · STX-12 (recognition probability) — both are predictive moves with measurable outcomes |
| Outcome tracking (predicted vs eventual result — BOOK-09 Ch. 7 gap) | STX-11 closes the loop for readiness (exam results are the ground truth); STX-12 for adjudication outcomes |
| Model-graded rubric scoring needs a live LLM provider | ops/deployment — unchanged, gates real GA only |
| Rubric/equity floors, salience weights, volume budgets = v1 policy knobs | ongoing calibration — unchanged |

## Phase exit gate

**DAS-Core conformance suite green (BOOK-20 §8.1, criteria 1–7)** — layering
grep/CI gates · engine contract tests (evidence append-only, GPS determinism,
twin single-door, KG fire-and-forget) · STX-03 mesh V1–V5 as permanent suite ·
cross-tenant leakage fuzz (API + graph + streams + cache) · driver bulkhead
chaos tests · gateway-only egress gate · NFR budget dashboards + alert wiring.
Plus: every K3 agent through the NEW-02 gate · `pytest -m phase1` stable ·
K3 KPI wave wired (learning gain/durability, rec acceptance, GPS adoption +
replan stability, evidence balance — BOOK-20 Ch. 9). Produce
`K3-EXIT-REPORT.md` (verification outputs, `git diff --stat`, register
updates) before requesting K4 prompts.

| Sprint | File | Model rec. (CLAUDE.md §14) |
|--------|------|---------------------------|
| STX-07 | STX-07-gps-core-ws01.md | opus for routing-determinism/contract design review, sonnet impl |
| NEW-04 | NEW-04-routegraph-compiler.md | opus (edge taxonomy + Pareto + hysteresis are hard to reverse), sonnet impl |
| STX-08 | STX-08-evidence-pipeline.md | sonnet (trust table seeds are Book-specified) |
| NEW-05 | NEW-05-assessment-session.md | sonnet, with a design note on native/mirror mode boundary |
| STX-09 | STX-09-recommendations-v2.md | sonnet |
| STX-10 | STX-10-tutor-coach-agents.md | sonnet (R4 ladder is fully specified) |
| STX-11 | STX-11-assessment-agent-ws06.md | sonnet |
| STX-12 | STX-12-recognition-scenarios.md | opus for yield-estimator/hedged-plan design review, sonnet impl |
| NEW-06 | NEW-06-thesis-committee.md | sonnet |
