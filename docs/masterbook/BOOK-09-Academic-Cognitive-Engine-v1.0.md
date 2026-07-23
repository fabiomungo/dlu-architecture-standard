# BOOK-09 — Academic Cognitive Engine (ACE)
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The cognitive core of the AOS — and the Book where DLU claims original ground.
> ACE is **not** an agent router with a system prompt. It is a **pedagogically
> typed, neuro-symbolic cognitive engine**: its unit of decision is not a token
> stream but a *pedagogical move* selected symbolically from a governed catalog
> and realized neurally; its explanations are byproducts of its decision traces,
> not post-hoc rationalizations; it runs on two processing paths with an explicit
> escalation ladder; it allocates its own attention under an equity-guarded
> cognitive budget; and it is calibrated enough to know when to say
> *"a human should decide this."*
>
> **Conforms to:** BOOK-00 v2.0 (ADR-0005/0006/0013). **Depends on:** BOOK-01
> (moves are grounded in learning science), BOOK-03 (§3.9 contract), BOOK-06/07/08
> (twins as context). **Informs:** BOOK-10 (agents execute moves), BOOK-11
> (reasoning/guardrail internals), BOOK-12 (memory).
> **Implementation profile:** `academic_brain_service` (Turnkey name; "Academic
> Brain" is the deprecated synonym — BOOK-00 glossary).
> **Primary audience:** AI architects, engineers, AI Review Board.

**Normative language:** RFC 2119.

---

# Chapter 1 — Thesis: Five Claims of Originality

1. **Pedagogical typing.** Generic agent frameworks decide *what to say*; ACE
   decides *which teaching move to make*, from a closed, evidence-grounded
   catalog (Ch. 3). The LLM realizes the move; it does not choose it alone.
2. **Explanation-first.** The decision trace (state → move → rationale) exists
   *before* the response is generated. "No trace, no action" — explainability is
   structural, not decorative (ADR-0006 made architectural).
3. **Dual-process cognition.** A fast path (deterministic policies, small
   models, cached micro-decisions) and a slow path (LLM deliberation,
   multi-agent consultation), with pedagogical SLAs deciding the path (Ch. 4).
4. **Cognitive budget with equity.** ACE allocates proactive inference per
   learner by *need*, not equally — and audits the allocation for disparate
   impact, treating compute as the attention economy's currency (Ch. 6).
5. **Calibrated humility.** ACE tracks its own predictive calibration per move
   type; deferral to humans is a first-class move with defined triggers, not an
   exception path (Ch. 7).

Together these make ACE an **institutional cognitive system**: the same engine
serves tutoring turns, nightly risk scans and dean's briefings — one cycle, one
trace discipline, one voice.

---

# Chapter 2 — The Academic Cognitive Cycle

Every ACE activation — conversational turn, event-triggered mission, scheduled
scan — is one cycle of **PDDAEL**:

```text
Perceive → Diagnose → Decide → Act → Explain → Learn
```

| Phase | Contract | Key rules |
|-------|----------|-----------|
| **Perceive** | assemble context: twin layers (entitlement-checked, BOOK-06 Ch. 6) + triggering event/message + working memory (BOOK-12) | purpose-tagged, version-cited; consent gates applied here |
| **Diagnose** | produce a typed **LearnerStateAssessment**: CAT stage per relevant competency, mastery snapshot, affect/engagement signals, risk flags | diagnosis is data-derived (BKT, evidence, behaviour aggregates); the LLM MAY interpret, MUST NOT invent state |
| **Decide** | select a **pedagogical move** (Ch. 3) via the policy layer: envelope constraints (BOOK-07 F4) → autonomy tier → move preconditions → utility ranking | symbolic step; produces the decision record BEFORE any generation |
| **Act** | realize the move: agent invocation via gateway (grounded generation), tool call, event emission, or proposal creation | all LLM calls via gateway (ADR-0013); grounding mandatory for content-bearing moves |
| **Explain** | render the decision record for the audience (learner / faculty / auditor) | derived from the trace — never asked of the model post-hoc |
| **Learn** | persist: episodic record, memory writes (validated `memory[]`), calibration update (predicted vs eventual outcome), event emissions (validated `events[]`) | agents never write directly; ACE is the sole persistence point (BOOK-03 §3.9) |

The cycle is the auditable atom: every ACE action in the university decomposes
into cycles, each with its trace.

---

# Chapter 3 — The Pedagogical Move Catalog

## 3.1 Why moves

Tutoring research (Graesser's AutoTutor dialogue moves; VanLehn's tutoring
studies; Wood & Bruner's scaffolding; Chi's ICAP engagement modes) converges on
a stable repertoire of effective teaching acts. DLU makes this repertoire the
**symbolic action space** of its cognitive engine — the same role the syscall
table plays in an OS. Benefits: envelopes constrain *moves* (faculty tune
comprehensible knobs — BOOK-07 F4 `scope` references move classes); calibration
attaches to *moves*; audit speaks in *moves*; research evaluates *moves*.

## 3.2 The catalog (v1 — closed set, RFC to extend)

| Move | Class | Preconditions (twin state) | Autonomy | Grounding |
|------|-------|---------------------------|----------|-----------|
| `elicit` | Socratic | learner in productive-struggle zone (P(L) in band) | act | Graesser; BOOK-01 P4 |
| `hint` | Socratic | struggle beyond threshold; giveup counter < envelope limit | act | VanLehn |
| `worked_example` | instruct | low P(L) on prerequisites; cognitive-load risk | act | Sweller; BOOK-01 P5 |
| `explain_concept` | instruct | learner request or diagnosed gap; retrieval context available | act | grounded generation only |
| `check_retrieval` | assess | spaced review due, or post-instruction | act | BOOK-01 P2/P3 |
| `generate_formative` | assess | outcome-aligned item need | act | Bloom-targeted (BOOK-01 Ch. 5) |
| `give_feedback` | assess | scored attempt present | act | feeds-forward form (BOOK-01 P6) |
| `challenge` | stretch | mastery high; ICAP escalation warranted | act | Chi ICAP; desirable difficulty |
| `encourage` | affect | engagement dip, effort present | act | SDT-consistent (no hollow praise) |
| `reframe_goal` | plan | goal-progress mismatch | propose | learner owns goals (BOOK-06 L5) |
| `replan_path` | plan | GPS invalidation or request | propose | GPS computes; ACE narrates (BOOK-03 §3.8) |
| `recommend_next` | plan | recommendation pipeline output | act (low-stakes) | explanation trace mandatory |
| `recognize_prior` | evidence | prior-learning claim detected | propose | registrar HITL (BOOK-07) |
| `flag_risk` | care | risk signals over threshold | propose | Success Agent; human intervention |
| `celebrate` | affect | milestone/credential earned | act | — |
| `refer_to_human` | humility | Ch. 7 triggers | **always available** | the escape hatch every cycle can take |
| `abstain` | humility | no move's preconditions met with confidence | act | logged; better than guessing |

Rules: a move outside the catalog is a conformance failure; move preconditions
read **only** diagnosed state (no hidden context); every learner-facing move
class is envelope-controllable (BOOK-07); `refer_to_human` and `abstain` can
never be disabled by any envelope.

---

# Chapter 4 — Dual-Process Execution

## 4.1 Two paths

| | **System-1 (fast)** | **System-2 (slow)** |
|---|---------------------|---------------------|
| Mechanism | deterministic policies, cached micro-decisions, small/local models via gateway presets | frontier-model deliberation, multi-step reasoning, multi-agent consultation |
| Latency budget | p95 < 1 s | seconds–minutes (streamed or async) |
| Typical moves | `hint`, `check_retrieval`, `give_feedback` (templated), `recommend_next` (pre-ranked) | `replan_path` narration, `recognize_prior`, viva dossier prep, dean's briefings |
| Cost | ~zero marginal | budgeted (Ch. 6) |

## 4.2 The escalation ladder (normative)

```text
L0 deterministic rule            (no model call)
L1 cached decision               (same twin_version + same trigger class)
L2 small-model realization       (gateway preset: local/haiku-class)
L3 frontier-model deliberation   (single agent)
L4 multi-agent consultation      (blackboard, Ch. 5.3)
L5 human                         (refer_to_human)
```

Each cycle starts at the lowest level that can satisfy the move's quality bar;
escalation triggers are explicit (low confidence, envelope requirement, stakes
class). **Pedagogical SLAs pick the path:** a learner stuck mid-quiz gets an L0–L2
`hint` in under a second; nobody's career gets replanned by a cached rule.

## 4.3 Degradation modes

Gateway outage → **deterministic-only mode**: L0/L1 moves continue (reviews,
recommendations from last ranking, rule-based feedback), everything else queues
with visible notice. Quota exhaustion degrades the same way (BOOK-02 §8.3 —
visible, never silent). The university keeps teaching when the models are down;
it just teaches less adaptively.

---

# Chapter 5 — Routing, Orchestration, One Voice

## 5.1 Routing

`route(user, message, workspace)`: intent classification (fast path) → agent
selection biased by workspace (WS05 → Tutor; WS02 → Recognition) → PDDAEL cycle
under that agent's identity. Ambiguity is resolved by asking, not guessing
(an `elicit` on intent).

## 5.2 The One-Voice Principle (normative)

The learner converses with **their university**, not with nine bots. However
many agents contribute, ACE composes **one response, one tone, one memory**.
Agent identity is metadata (visible on request — "the Career Advisor
contributed this"), never nine competing chat windows. Hand-offs between agents
are cycle-internal, invisible unless pedagogically meaningful.

## 5.3 Consultation blackboard (L4)

For cycles needing multiple specialists (e.g., replan touching career + credits +
risk): a per-cycle blackboard keyed to `(twin_id, twin_version, cycle_id)`;
contributing agents post typed contributions (assessment, option, objection);
a designated synthesizer (the routed agent) composes; conflicts escalate — an
unresolved objection between agents on a propose-tier matter goes to the human
queue with both positions attached (disagreement is signal, not noise).

## 5.4 Missions

`run_mission(agent, twin, mission)`: event-triggered or scheduled proactive
cycles (nightly risk scan, weekly plan, re-engagement). Missions are Celery-run,
cycle-disciplined (same PDDAEL, same traces), and budget-governed (Ch. 6).

---

# Chapter 6 — The Cognitive Budget and Attention Scheduling

Proactive cognition is finite (inference costs money — BOOK-02 Ch. 8). ACE
schedules it like the scarce attention it is:

1. **Need-based allocation:** each learner carries a **cognitive priority**
   computed from risk score, momentum (recent progress), upcoming stakes
   (exam proximity), and staleness (time since last meaningful contact).
   High-need learners get deeper, more frequent proactive cycles.
2. **Equity guardrail (blocking):** allocation is audited for disparate impact
   across cohorts — *spend equity is a reported metric* (BOOK-08 I3/I4). A
   policy that systematically under-serves a cohort MUST NOT ship (BOOK-01
   Ch. 10 anti-Goodhart discipline applied to compute).
3. **Floors:** every active learner receives a minimum proactive cadence
   (nobody becomes invisible because they are quietly fine) and every consent
   degradation still receives its non-personalized floor.
4. **Budget lines:** per-tenant, per-engine, per-mission-class — enforced by
   gateway quotas (running today); exhaustion degrades per Ch. 4.3.

This chapter is the architectural translation of the attention economy: **the
institution's cognition is allocated deliberately, observably and fairly.**

---

# Chapter 7 — Calibration and Epistemic Humility

1. **Per-move calibration:** for predictive moves (risk flags, mastery-based
   choices, recommendation efficacy) ACE records prediction → eventual outcome
   and maintains calibration curves per move type and per model preset
   (BOOK-01 Ch. 6.2 extended to the engine itself).
2. **Deferral triggers (`refer_to_human`):** stakes class ≥ reserved tier;
   confidence below the move's calibrated floor; envelope requires it;
   guardrail hit (BOOK-11); learner requests a human; consultation deadlock
   (§5.3); repeated `abstain` on the same need.
3. **Honest uncertainty:** learner-facing realizations of low-confidence moves
   MUST carry calibrated hedging ("this is a suggestion — your advisor can
   confirm") — never confident tones on uncertain content.
4. **Calibration is governed:** drift beyond thresholds pages the AI Pedagogy
   Steward (BOOK-02 role); a miscalibrated move class is throttled to
   propose-tier until recalibrated.

---

# Chapter 8 — Explanation Architecture

The trace schema (persisted per cycle, audit-grade):

```json
{
  "cycle_id": "…", "trigger": {"kind": "message|event|mission", "ref": "…"},
  "context": {"twin_version": 412, "layers": ["L3","L4"], "purpose": "tutor"},
  "diagnosis": {"cat_stage": "practicing", "p_mastery": {"c-sql-3": 0.62}, "flags": []},
  "decision": {"move": "hint", "candidates_rejected": [{"move": "worked_example", "why": "prereqs mastered"}],
               "envelope": "course-812/tutor/v7", "escalation_level": "L2"},
  "action": {"model_preset": "…", "gateway_request_id": "…", "grounding_refs": ["res-1141#c3"]},
  "explanation_rendered": {"learner": "…", "faculty_digest": "…"},
  "learn": {"memory_writes": 1, "events": ["…"], "prediction": {"kind": "unaided_success", "p": 0.7}}
}
```

Rendering rules: **learner** sees the pedagogical why in DLU-Core vocabulary
(BOOK-05 Ch. 8 — words match the UI); **faculty** sees move + envelope + digest
(BOOK-07 F4 inspection); **auditor** sees the full trace. One trace, three
renderings — never three stories.

---

# Chapter 9 — Memory Interface (contract with BOOK-12)

ACE reads/writes memory through three typed stores: **working** (the cycle
blackboard — ephemeral), **episodic** (cycle records, per-twin interaction
history — retention-classed), **semantic** (distilled durable facts →
`TwinAIMemory` L7, salience-managed). Distillation from episodic to semantic is
itself a governed mission (what the AI remembers about a learner is curated,
inspectable, deletable — BOOK-06 Ch. 8). Full architecture in BOOK-12.

---

# Chapter 10 — Service Contracts

```python
class AcademicCognitiveEngine:
    async def route(user_id, message, workspace) -> StreamedTurn      # SSE; cycle-traced
    async def run_mission(agent_key, twin_id, mission) -> CycleReport # Celery
    async def get_trace(cycle_id, audience) -> RenderedExplanation
    async def proposals(...)                                          # HITL queue (BOOK-03 §3.9)
```

Non-functionals bind (BOOK-03 Ch. 8): first token p95 < 3 s (streamed);
System-1 moves p95 < 1 s; every cycle traced; every trace retrievable.

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Engine skeleton | `ace_service.py` (`AcademicCognitiveEngine`, PDDAEL `run_cycle`/`route`/`run_mission`/`get_trace`) — `agent_orchestrator_service` kept as-is (authoring-side, unrelated) | ✅ (STX-06, 2026-07-17) | consultation-mapped blackboard for the remaining agents once seeded 🔵 |
| Agent/skill/preset registry | AI Management v2.0 (`ai_agent_configs`, `ai_skill_registry`, `ai_mcp_servers`, `ai_model_presets`); move-catalog binding delivered NEW-01 | ✅ | **all nine student-facing agents now seeded as real config rows** (Discovery STX-06, Navigator STX-07, Recognition STX-12, Assessment STX-11, Subject Tutor + Learning Coach STX-10, Credential STX-13, Student Success + Career Advisor STX-14/15 — see BOOK-10 §Annex A) — but every one remains `lifecycle_state="testing"`; zero have run `/agents/{id}/gate` + steward sign-off, so none has ever transitioned to `deployed` |
| Gateway + presets + quotas | ACP Gateway (routing, fallback, virtual keys, budgets) | ✅ | escalation-ladder presets mapping — first-cut deterministic table shipped (STX-06, `ESCALATION_PRESET`); calibration-history-driven mapping still open ⚪ |
| Diagnose inputs | BKT, evidence (STX-08), behaviour aggregates, tutor context; `LearnerStateAssessment` (NEW-01) | ✅ | — |
| Grounded realization | GraphRAG, RAG service, mock LLM (testing) | ✅ | grounding-mandatory enforcement per move class 🔵 (STX-06's `_grounding_refs` is a minimal citation stub, not full RAG resource citation) |
| HITL queue | `move_proposal_service.py` (twin-shaped, STX-06 — deliberately separate from the course-content-shaped `proposal_service.py`) | ✅ (STX-06) | deferral-trigger coverage is partial (low confidence + explicit ask only; full Ch. 7 trigger set is later work) ⚪ |
| Traces | `ace_cycle_traces` (migration `20260717_1100`), schema-validated `CycleTrace` (Ch. 8) | ✅ (STX-06) | `agent_run_logs` ↔ `cycle_id` linkage still open ⚪ |
| Missions | Celery + beat; `ace.run_mission` task (STX-06, no beat schedule registered yet — event-triggered dispatch point only) | ✅ | cognitive budget scheduler (Ch. 6 floors/caps/equity) — `TODO(budget)` marker in code, no enforcement yet ⚪ |
| Calibration | — | ⚪ | per-move calibration store + steward alerts (BOOK-11 eval harness) |
| One-voice composition | `synthesize_blackboard` (structural: one `response` field, attribution as metadata) | ✅ (STX-06) | **MOVE_CONSULTS populated for real ✅ (STX-10, 2026-07-22)**: `{"reframe_goal": ["subject_tutor", "learning_coach"]}` — `reframe_goal` is already `plan`+`propose` in the closed catalog, so the existing L4 escalation gate needed zero changes; `_consult` (previously `NotImplementedError`) now returns a deterministic, data-derived contribution per consulted agent — NOT a nested LLM call (cost/recursion/budget-compounding has no infrastructure yet, an honest scope limit); `_tutor_consult_view`/`_coach_consult_view`/`synthesize_blackboard` are tested directly (same fixture-level precedent as STX-06 itself), but `_consult`'s own DB round-trip (`_load_agent` against a real `AiAgentConfig` row) is untested at the integration level — `AiAgentConfig`'s Postgres-only JSONB columns are the same SQLite-test limitation every prior sprint has documented |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| PDDAEL cycle | The six-phase cognitive cycle: Perceive, Diagnose, Decide, Act, Explain, Learn |
| Pedagogical move | Symbolic unit of ACE decision, from the closed catalog of Ch. 3 |
| Escalation ladder | L0–L5 execution levels from deterministic rule to human |
| One-Voice Principle | The learner hears one composed voice, whatever agents contributed |
| Cognitive budget | Governed allocation of proactive inference per learner, equity-audited |
| Consultation blackboard | Per-cycle shared workspace for multi-agent contributions |
| Calibrated deferral | `refer_to_human` triggered by per-move confidence floors |
| Deterministic-only mode | Degradation mode: L0/L1 moves continue without models |

---

*BOOK-09 v1.0 — awaiting review. Next per dependency order: BOOK-10 (AI
Workforce — the agents as executors of moves) and BOOK-11 (reasoning and
guardrail internals).*
