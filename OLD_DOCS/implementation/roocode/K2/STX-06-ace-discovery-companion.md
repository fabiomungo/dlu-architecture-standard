# Sprint STX-06 — ACE Runtime + Discovery Agent + WS00 Companion
### DAS K2 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-01, K1

## Role
`backend-dev` + `frontend-dev`, with an opus-class design review on the
PDDAEL runtime and one-voice composition before merge (DAS BOOK-09;
BOOK-17 Ch. 2/7; constitution §8.3, §14).

## Context — read before coding
1. BOOK-09 Ch. 2 (PDDAEL contract per phase), Ch. 4 (escalation ladder
   L0–L5, degradation modes), Ch. 5 (routing, one-voice, blackboard,
   missions), Ch. 8 (trace schema — copy it as the Pydantic model).
2. BOOK-10 Ch. 3 Discovery contract card (moves: `elicit`,
   `explain_concept`, `recognize_prior` propose, `recommend_next`;
   reads L1/L5/L7; persona proposal is a PROPOSAL, never auto-applied).
3. Existing: `ai_agent_configs` (+ NEW-01 bindings), ACP gateway
   (`LLM_GATEWAY_URL`, presets/fallback chains — ALL model calls through it,
   ADR-0013), `agent_orchestrator_service.py` (to be subsumed — strangler,
   keep old routes green), `proposal_service.py` (HITL queue),
   `TwinContextService` (STX-02: purpose + agent_key + entitlements),
   `event_outbox`/`event_consumers` (STX-03), `pedagogical_moves` (NEW-01),
   `kg_query_service.frontier/gap` (STX-05), `mock_llm_service.py`.
4. Constitution §8.3 names the service `academic_brain_service` —
   implement as `backend/services/ace_service.py` with an
   `academic_brain_service` alias (BOOK-00 glossary: "Academic Brain" is the
   deprecated synonym; keep the constitutional name importable).

## Deliverables
1. **PDDAEL runtime** `backend/services/ace_service.py`:
   `run_cycle(agent_key, twin_id, trigger) -> CycleResult` — Perceive
   (TwinContext via the single door, purpose-tagged, twin_version cited) →
   Diagnose (`LearnerStateAssessment`, data-derived) → Decide (NEW-01
   preconditions; decision record BEFORE any generation) → Act (gateway call
   at the chosen ladder level; grounding refs mandatory for content-bearing
   moves) → Explain (rendered from the trace, never post-hoc) → Learn
   (validated `memory[]` → TwinAIMemory, validated `events[]` → outbox;
   ACE is the SOLE persistence point — agents never write directly).
2. **Trace persistence**: `ace_cycle_traces` tenant table (GUID, additive
   migration `_stx_06_ace_traces.py`) storing the BOOK-09 Ch. 8 JSON schema
   (schema-validated on write); M1 working blackboard in Redis keyed
   `(twin_id, twin_version, cycle_id)`, destroyed at cycle end.
3. **Escalation ladder + degradation**: L0 deterministic rules and L1 cached
   decisions (Redis, keyed trigger-class + twin_version) run WITHOUT model
   calls; L2/L3 via gateway presets; L4 blackboard consultation (typed
   contributions; unresolved propose-tier objection → HITL queue with both
   positions). **Deterministic-only mode**: gateway down/quota exhausted ⇒
   L0/L1 still serve, rest queues with a visible notice (never silent).
4. **Routing + one voice**: `route(user, message, workspace)` — fast intent
   classification, workspace bias, ambiguity resolved by an `elicit`;
   however many agents contribute, ONE response with agent attribution as
   metadata. `/api/brain/chat` (SSE streaming) + `GET /api/brain/agents` +
   proposals endpoints wired to `proposal_service` (constitution §14;
   tenant-scoped, NOT exempt).
5. **Mission runner**: Celery task `ace.run_mission(agent_key, twin_id,
   mission)` — event-triggered or scheduled proactive cycles, same PDDAEL +
   traces; budget floor/cap hooks stubbed for BOOK-09 Ch. 6 (full budget
   engine is later work — leave a `TODO(budget)` marker, no silent spend).
6. **Discovery Agent**: `ai_agent_configs` seed row (lifecycle
   `testing` — NEW-02 gates deployment) + contract card in code
   (moves/entitlements per BOOK-10 Ch. 3); intake flow produces a persona
   PROPOSAL (BOOK-06 Ch. 4.3) through the HITL queue.
7. **WS00 UI (frontend)**: the workspace triad — Canvas (twin summary via
   `twinAPI`), Companion (chat on `/api/brain/chat`, one voice, "I don't
   know" renders honestly), Missions (proposals + recommendations stream);
   memory panel ("what the AI remembers" — L7 list) and the **"why?"
   affordance** on every companion answer rendering the trace-derived
   explanation (learner rendering, DLU-Core vocabulary). Human escalation
   one tap (BOOK-17 Ch. 7.4).

## Verifications
- **V1** every turn/mission produces a complete schema-validated trace
  (property: no cycle without trace — assert on the API path and the
  mission path).
- **V2** gateway down (client stubbed unavailable) ⇒ L0/L1 moves still
  serve; L2+ requests queue with visible notice; nothing 500s.
- **V3** one voice: a fixture cycle with two contributing agents renders a
  single response; attribution present in metadata only.
- **V4** "why?" returns the trace-derived explanation; asking the model
  post-hoc is impossible by construction (explanation built from the
  persisted trace — unit-tested).
- **V5** `/api/brain/chat` first token p95 < 3 s streamed (smoke, mock
  preset); L0 `hint` path p95 < 1 s.
- **V6** Learn phase: invalid `events[]` (unknown taxonomy type) and invalid
  `memory[]` are rejected loudly; valid ones land in outbox/TwinAIMemory.
- **V7** `pytest -m phase1` + legacy agent routes green (strangler).

## DoD
V1–V7 green · migration up/down/up clean · Discovery stays `testing` until
NEW-02 · constitution §8.3/§14 marked implemented · BOOK-09 Annex + BOOK-10
nine-agents row updated · design-review note in `docs/sprint_decisions_*.md`
· next: NEW-03 upgrades Perceive/Learn; NEW-02 gates GA.
