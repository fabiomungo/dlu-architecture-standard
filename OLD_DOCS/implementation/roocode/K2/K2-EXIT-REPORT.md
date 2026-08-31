# K2 Cognition — Exit Report

**Phase:** K2 (BOOK-20 roadmap) · **Target repo:** `dlu_builder_tk`
**Executed:** 2026-07-17 → 2026-07-18 · **Sprints:** NEW-01, STX-06, NEW-02, NEW-03 (4/4 ✅)
**Execution order:** NEW-01 → STX-06 → NEW-02 → NEW-03 (pack dependency
graph honored: NEW-01's closed move catalog landed first since STX-06's
Decide phase consumes `move_bindings` directly; NEW-02 built on STX-06's
traces; NEW-03 upgraded STX-06's Perceive/Learn phases in place last, as
the pack's own ordering note specified).

---

## 1. Exit gate assessment (pack README)

| Gate criterion | Status |
|----------------|--------|
| Harness gates wired to ACP `lifecycle_state` (deployment blocked without a green run, steward-signed) | ✅ `POST /agents/{id}/deploy` 409s without a green, steward-signed `AgentGateRun` matching the agent's **live** `ctx_hash` (recomputed at deploy time, never trusted from the stored row) |
| Crisis protocol zero-tolerance class live and negative-tested | ✅ Unconditional, fail-closed at two independent layers, runs before Perceive on the full learner message; non-disableability proven by negative test + source inspection (no config path can skip it) |
| Every deployed agent has a complete PDDAEL trace per turn | ✅ `ace_cycle_traces` (STX-06) — schema-validated on write, immutable, written even on mid-cycle failure (best-effort error trace) so "no cycle without trace" holds under partial failure too |
| Deterministic-only degradation demonstrated (gateway down ⇒ L0/L1 moves serve) | ✅ L0 (templated) and L1 (cached) never touch the gateway; L2+ requests defer with a visible notice on gateway-down, never a 500 |
| Memory deletion + cross-learner isolation verified | ✅ `DELETE /api/twin/me/memory/{id}` (ownership-checked, effective at next assembly); cross-learner isolation fuzz-tested at the storage layer (20 random twins, zero leakage) |

**Verdict: K2 exit gate PASSED. K3 prompts can be requested.**

---

## 2. Per-sprint delivery and verification outputs

### NEW-01 — Pedagogical Move Catalog + Binding (✅ 2026-07-17)

Delivered: the closed 17-move catalog as data (`backend/services/
pedagogical_moves.py`), `LearnerStateAssessment` (typed, data-derived-only
diagnosis), the pure `check_preconditions`/`decide_move` Decide-step
engine (envelope → binding → precondition → autonomy, zero model calls),
additive `move_bindings`/`entitlements`/`envelope_defaults`/
`calibration_ref` columns on `ai_agent_configs` (migration
`20260717_1000`) with humility moves (`refer_to_human`/`abstain`)
non-disableable at both the model `@validates` layer and the API (422).

Verification highlights: 24 tests green (V1–V4 + a whitelist-bug
regression I found and fixed — `update_agent`'s field whitelist silently
dropped the new columns); migration up/down/up clean; `pytest -m phase1`
stable at 104 (K1 baseline).

### STX-06 — ACE Runtime + Discovery Agent + WS00 Companion (✅ 2026-07-17)

Delivered: the PDDAEL runtime (`ace_service.py` — Perceive → Diagnose →
Decide → Act → Explain → Learn), `ace_cycle_traces` (schema-validated,
immutable), a deterministic escalation ladder (L0 templated / L1 cached /
L2–L3 gateway / L4 blackboard / L5 human), `move_proposal_service.py`
(twin-shaped HITL queue, deliberately separate from the course-content-
shaped `proposal_service.py`), Discovery as the first seeded
`ai_agent_configs` row (`lifecycle_state="testing"`), `/api/brain/*`
routes (SSE Companion chat, agent registry, proposals, memory panel,
"why?" trace), `ace.run_mission` Celery task, and the WS00 frontend triad
(Canvas/Companion/Missions + memory panel + "why?" affordance).

Design went through an opus-class PDDAEL/one-voice review before
implementation (`docs/sprint_decisions_20260717_stx06.md`), which caught
and fixed: an untraced-failure hole on partial cycle failure, a
double-path escalation bug, an unreachable blackboard consult mapping,
and a `route()` truthiness bug.

Verification highlights: 19 tests green (V1–V7); migration up/down/up
clean; Discovery agent's JSONB round-trip verified against a disposable
Postgres container; `pytest -m phase1` stable at 104.

### NEW-02 — Eval Harness + Crisis Protocol (✅ 2026-07-18, the GA gate)

Delivered: the crisis protocol (`crisis_detector.py` — unconditional,
fail-closed at two layers, scripted non-generative handover,
`CrisisIncident` restricted-visibility table), egress checks
(`egress_checks.py` — academic-integrity, anti-sycophancy, over-
scaffolding, grounding-fidelity, tone/hedging, injection-resistance) with
real block-and-regenerate-once wired into `_act_generative`, the
scenario bank (`backend/evals/`, 9 BOOK-11 Ch. 6.1 classes, full
Discovery coverage), three grader tiers, `harness.run_gate()` producing
`AgentGateRun` (the release record, `ctx_hash` content-addressed), the
deploy/sign routes, and the shadow-eval sampler (deterministic-drift-
only, documented scope limit).

Design went through an opus-class review (`docs/sprint_decisions_
20260718_new02.md`) that caught the sprint's most important finding: the
draft's zero-tolerance check compared the *decided* move only — sound
for crisis, vacuous for injection/integrity (an agent could decide
correctly and still leak violating content in the generated text). Fixed
by enforcing zero-tolerance on the **served** move (post any egress
override), with `Decision.move` staying the honest pre-generation record.

Verification highlights: 64 tests green (NEW-02 + STX-06 + NEW-01, no
regressions); migration up/down/up clean; the full gate→sign→deploy→
drift flow verified end-to-end against a disposable Postgres container,
including confirming the gate honestly fails (not silently passes)
without a live LLM provider configured.

### NEW-03 — Memory Stores (✅ 2026-07-18)

Delivered: M2 episodic (`ace_session_summaries`, pgvector-indexed —
**not Chroma**, correcting a premise in the sprint brief: no Chroma
substrate exists anywhere in `dlu_builder_tk`, pgvector is the
established convention), `memory_write_service.py` as the sole M3
(`TwinAIMemory`) writer (episode citations required, inference
confidence + ≥2-episode bar, protected-attribute/third-party-fact
rejection list, INSERT+supersede contradiction handling), the R8
consolidation pipeline (`consolidation_service.py` — extractive-first,
salience scoring, volume-budget compression), M4 procedural
(`ProceduralCalibrationState` rolling up NEW-02's `CalibrationBaseline`
into inherited-but-flagged release state), retrieval assembly upgraded
into STX-06's Perceive phase in place (salience × purpose-relevance
ranking, M2 vector hits on history cues, per-agent budget + truncation
marker, trace citation), and `DELETE /api/twin/me/memory/{id}`
(ownership-checked, cache-busted).

Two genuine findings, fixed in the same change set rather than silently
patched: `TwinContextService._fetch_ai` never scoped `TwinAIMemory` reads
by `agent_key` at all (every entitled agent saw every other agent's
memory — BOOK-12 Ch. 4's literal hard rule); and STX-06's per-cycle
auto-write to M3 was exactly the "memory that only grows is a
surveillance file" anti-pattern BOOK-12 Ch. 3 warns against (removed —
per-cycle content already has a home in the cycle trace, M2's record).

Verification highlights: 122 tests green across the full K2 suite (2
correctly skipped — a Postgres-only FK path, verified manually against a
disposable container); migration up/down/up and the pgvector cast
verified against Postgres; `pytest -m phase1` stable at 104.

---

## 3. Regression evidence

- `pytest -m phase1`: **104 passed** after every sprint (stable baseline,
  unchanged from the K1 exit report — zero regressions across all four
  K2 sprints).
- Cumulative K2 suite (NEW-01 + STX-06 + NEW-02 + NEW-03): **122 passed,
  2 skipped** (Postgres-only, both manually verified against a
  disposable container).
- Every sprint's migration verified up → down → up clean against a
  disposable Postgres container before commit (never against the shared
  dev database).

## 4. `git diff --stat` (implementation repo, K2 range)

```
60 files changed, 8068 insertions(+), 19 deletions(-)
```

Commit series (one per sprint) on `das-k1-kernel-foundation`:
- `9aa90a7` feat(das-new01): pedagogical move catalog + agent scope-of-practice binding
- `1e242bd` feat(das-stx06): ACE PDDAEL runtime + Discovery Agent + WS00 Companion
- `a88a48e` feat(das-new02): eval harness + crisis protocol — the GA deployment gate
- `b908ad0` feat(das-new03): memory stores — M2 episodic, M3 lineage, M4 procedural

## 5. Register updates (this repo)

- **TRACEABILITY:** K2 Cognition row marks all four sprints delivered;
  "harness gates wired to ACP lifecycle" and "crisis protocol zero-
  tolerance" both satisfied per the pack's own exit-gate wording.
- **Annexes:** BOOK-09 (ACE engine skeleton, one-voice composition,
  escalation-ladder preset mapping first cut), BOOK-10 (move-catalog
  binding, Discovery as first seeded agent, eval-gated deployment),
  BOOK-11 (crisis protocol, egress set, scenario bank + graders, shadow
  evals), BOOK-12 (all four stores — the Chroma→pgvector correction
  applied here too), BOOK-06 (L7 memory-control deletion live,
  agent_key-scoping hard rule closed).
- **Constitution** (`dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`):
  §8.3–§8.6 and §14 marked implemented with delivery notes; the
  `TwinContextService._fetch_ai` agent-scoping fix and the STX-06
  per-cycle-auto-write removal are both documented inline as findings,
  not silently absorbed.
- **Design decision docs** (one per sprint, `docs/sprint_decisions_
  *.md` in `dlu_builder_tk`): STX-06, NEW-02, and NEW-03 each went through
  a documented design pass (STX-06 and NEW-02 with an opus-class review
  specifically on the highest-stakes design surfaces — PDDAEL/one-voice
  and the scenario-bank/gate policy respectively).

## 6. Residual debt / carried forward

| Item | Owner | When |
|------|-------|------|
| The other 8 agents (academic_navigator, career_advisor, student_success, etc.) as real `ai_agent_configs` rows — only Discovery is seeded through K2 | K3+ | per-sprint as each agent's workspace lands |
| `MOVE_CONSULTS` populated for real blackboard (L4) consultation — currently empty, tested via fixture only | the sprint that seeds the consulted agents | K3+ |
| Real model-graded rubric scoring requires a live LLM provider configured per tenant — the gate honestly fails without one in this dev environment (correct behavior, not a bug) | ops/deployment | before any real agent GA |
| Discovery's `explain_concept` can't ground content yet — its entitlements exclude the knowledge layer `_grounding_refs` reads from; needs a program-catalog grounding source per BOOK-10 Ch. 3 (found by the NEW-02 scenario bank) | K3+ | when Discovery's orientation-content grounding is prioritized |
| Rubric-quality drift monitoring in the shadow sampler — traces don't persist response content, only refs/metadata (NEW-02 documented gap) | K3+ | needs a content-store reference (`gateway_request_id` → `agent_run_logs`) |
| `ace.py`'s `/api/brain/memory/{id}` DELETE route has no ownership check (found during NEW-03; the new `/api/twin/me/memory/{id}` route is the hardened path) | K3+ mechanical fix | low priority — WS00 UI always calls it as the authenticated learner today |
| Calibration seeding covers `recommend_next` only (Discovery's one predictive move) — outcome tracking (predicted vs. eventual result) is still the open BOOK-09 Ch. 7 gap | K3+ | as more predictive moves get bound |
| Rubric/equity floors, salience-scoring weights, and volume budgets are all v1 policy knobs (documented as such — no Book-specified numbers exist anywhere in the Masterbook for any of these) | ongoing calibration | per-institution tuning as real usage data arrives |

## 7. Next

Request the **K3 Navigation & Evidence pack** (STX-07…12 · NEW-04, 05,
06 — BOOK-14/15/06/17). Blocking dependencies honored: NEW-02's gate now
governs every learner-facing deployment; Discovery is the only agent
currently eligible to GA (pending a real LLM provider + steward sign-off
in the target environment).
