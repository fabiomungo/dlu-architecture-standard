# BOOK-10 — AI Workforce
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The agents as an organized, governed workforce — specified **natively on the
> DLU AI Control Plane (ACP)** that is already running in Turnkey. The central
> claim: *an agent is not code — it is a composition of ACP registry entries*
> (config + persona + skills + preset + tools + scope + key), hired, deployed,
> supervised, evaluated and retired through the control plane, and permitted to
> act only inside ACE cognitive cycles (BOOK-09). No agent exists outside the
> ACP; no agent acts outside a cycle.
>
> **Conforms to:** BOOK-00 v2.0 (ADR-0005/0013). **Depends on:** BOOK-09 (moves,
> cycles), BOOK-06/07 (twin entitlements, envelopes), BOOK-03 (§3.9, Ch. 7).
> **Informs:** BOOK-11 (reasoning internals), BOOK-17 (agent surfaces).
> **Primary audience:** AI architects, engineers, AI Pedagogy Steward, AI Review
> Board.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** built
directly on the as-implemented ACP: `AI_MANAGEMENT_PLAN.md` + `models_ai.py`
(`ai_agent_configs`, `ai_skill_registry`, `ai_mcp_servers`, `ai_model_presets`),
`models_llm.py` (categorized providers), `ACP_GATEWAY_ARCHITECTURE.md` (LiteLLM
gateway, virtual keys, quota enforcement, run logs) and the AI Management CRUD/
test APIs.

---

# Chapter 1 — Thesis: a Workforce, Managed Like One

BOOK-02 declared the mixed workforce; this Book gives the AI half its personnel
system. The analogy is load-bearing, not rhetorical:

| HR concept | ACP realization (running) |
|-----------|---------------------------|
| Job description | `ai_agent_configs`: slug, description, `persona_prompt`, `allowed_roles`, `knowledge_scope` |
| Contract & badge | per-agent **gateway virtual key** (`gateway_key_id`) — identity, cost attribution, revocable access |
| Skills on the CV | `ai_skill_registry` bindings — typed capabilities with input/output JSON schemas |
| Tools issued | `ai_mcp_servers` + `tools_manifest` — the tool bus, testable per server |
| Compensation budget | quotas: `max_calls_per_min`, `max_concurrent`, tenant budgets, gateway enforcement |
| Line manager | envelope owner (human — BOOK-02 §3.2) + AI Pedagogy Steward |
| Performance review | run logs → agent scorecard (Ch. 8) + calibration (BOOK-09 Ch. 7) |
| Hiring / firing | `lifecycle_state` with `deployed_at/by` — governed releases, suspension, retirement |

**Invariant:** every capability an agent has is *legible in the registries*. If
you cannot read an agent's powers from the ACP, the agent is non-conformant.

---

# Chapter 2 — Anatomy of an Agent (ACP composition)

```text
AiAgentConfig (tenant-scoped, GUID)
 ├─ persona_prompt          voice & role (vocabulary from ontology registry — BOOK-05 Ch. 8)
 ├─ provider_id + preset_id → gateway_model_alias → LiteLLM router (fallback chains, is_local)
 ├─ skills[]                → AiSkillRegistry: system_prompt + user_prompt_tpl,
 │                            input_schema/output_schema (typed!), optional MCP binding
 ├─ tools_config + mcp_servers[] → AiMcpServer: transport, tools_manifest, credential, test status
 ├─ knowledge_scope         retrieval boundaries (courses, KG subgraphs, resource sets)
 ├─ allowed_roles           who may converse with it
 ├─ max_turns · max_calls_per_min · max_concurrent
 ├─ gateway_key_id          per-agent virtual key (identity + spend attribution)
 └─ lifecycle_state · deployed_at · deployed_by
```

DAS additions to this composition (deltas, all additive):

1. **`move_bindings`** — which pedagogical moves (BOOK-09 Ch. 3) the agent may
   execute, with per-move autonomy caps. The move catalog becomes the agent's
   *scope of practice* (the same way a professional license works).
2. **`entitlements`** — twin layers readable (the BOOK-06 Ch. 6 matrix,
   machine-enforced at context assembly).
3. **`envelope_defaults`** — the per-course faculty envelope (BOOK-07 F4)
   overrides these; agent config carries the platform defaults.
4. **`calibration_ref`** — link to per-move calibration state (BOOK-09 Ch. 7).

Scoping: `scope_type/scope_id` (already implemented) supports org-wide and
scoped variants (department, program) — a department MAY run a specialized
Subject Tutor variant without forking the platform agent.

---

# Chapter 3 — The Student-Facing Nine (contract cards)

Format: *mission · move bindings · twin reads · skills (typical) · tools (MCP) ·
knowledge scope · autonomy profile*. Twin entitlements are normative from
BOOK-06 Ch. 6; autonomy tiers from BOOK-02 Ch. 4.

**Discovery Agent** — intake and orientation.
Moves: `elicit`, `explain_concept` (about the university), `recognize_prior`
(hand-off trigger), `recommend_next` (orientation). Reads L1/L5/L7.
Skills: goal-elicitation dialogue, persona proposal, ESCO occupation lookup.
Tools: ESCO snapshot, program catalog. Autonomy: propose (persona, goals are
learner-confirmed).

**Recognition Agent** — prior learning and transfer credit.
Moves: `recognize_prior`, `explain_concept` (recognition rules). Reads L1/L3 +
submitted documents. Skills: transcript parsing, syllabus comparison
(embedding + KG), evidence dossier drafting. Tools: document processing,
ExternalCourse data, CASE/framework lookup. Autonomy: **propose only** —
registrar HITL (BOOK-07); its dossiers feed G5/G6 committee flows where present.

**Academic Navigator** — path planning dialogue.
Moves: `replan_path`, `explain_concept` (requirements), `reframe_goal`
(hand-off to Career Advisor). Reads L2/L3/L4/L5. Skills: GPS scenario
narration (narrates, never computes — BOOK-03 §3.8), requirement explanation.
Tools: GPS service API, catalog. Autonomy: propose (adoption is the learner's).

**Learning Coach** — habits, pacing, momentum.
Moves: `check_retrieval` (scheduling), `encourage`, `recommend_next`,
`celebrate`. Reads L4/L6/L7 (+L2 pacing). Skills: weekly plan composition,
review-mission assembly (SM-2 due queue), habit reflection prompts.
Tools: scheduler, notification service. Autonomy: act (low-stakes nudges);
respects quiet hours and wellbeing guardrails (BOOK-01 Ch. 10).

**Subject Tutor** — Socratic tutoring on course content.
Moves: `elicit`, `hint`, `worked_example`, `explain_concept`,
`check_retrieval`, `give_feedback`, `challenge`. Reads L4/L7 + course context —
**never L5/L6** (BOOK-06). Skills: GraphRAG-grounded explanation, misconception
diagnosis, struggle-zone dialogue. Tools: RAG/GraphRAG retrieval, code runner
(lab courses, sandboxed). Knowledge scope: enrolled courses only. Autonomy:
act, inside the faculty envelope (giveup thresholds, tone, source restrictions).

**Assessment Agent** — formative generation and feedback.
Moves: `generate_formative`, `give_feedback`, `check_retrieval`. Reads L3/L4.
Skills: Bloom-targeted item generation (existing service), rubric-based feedback
drafting, viva dossier preparation (BOOK-15). Tools: quiz/lab runtime, QTI.
Autonomy: act for formative; **propose for anything summative** (drafts for
faculty — BOOK-01 Ch. 8); never the sole grader.

**Credential Agent** — eligibility and issuance preparation.
Moves: `celebrate`, `recommend_next` (toward credential gaps). Reads L3.
Skills: criteria evaluation narration, wallet guidance. Tools: Credential
Engine APIs. Autonomy: act for auto-badges; **reserved** for high-stakes
(prepares, registrar decides).

**Student Success Agent** — risk and belonging.
Moves: `flag_risk`, `encourage`, `refer_to_human`. Reads L2/L4/L6.
Skills: risk interpretation (model-scored, agent-narrated), intervention
drafting, re-engagement campaigns (alumni). Tools: notification, advisor queue.
Autonomy: propose for interventions; its **detection missions** run on the
cognitive budget (BOOK-09 Ch. 6) with the belonging-first doctrine (BOOK-02
Ch. 6: the intervention is human connection).

**Career Advisor** — goals, market alignment, growth.
Moves: `reframe_goal`, `recommend_next`, `explain_concept` (occupations).
Reads L3/L5. Skills: ESCO gap analysis, competency-to-occupation mapping,
CV/portfolio guidance from the evidence graph. Tools: ESCO, GPS career
scenario, wallet export. Autonomy: propose (goals are self-determined —
BOOK-01 P7); employer disclosure strictly consent-scoped (BOOK-06).

---

# Chapter 4 — The Rest of the Roster

The workforce is larger than the student-facing nine; these run today or are
implied by running systems:

| Agent | Domain | Status |
|-------|--------|--------|
| Course Architect | authoring: structure proposals (`/architect/propose`) | ✅ running |
| Pedagogical Coach | QA: Bloom/coverage analysis + recommendations | ✅ running |
| Media Pipeline agents | 9-type enrichment, video professor (HeyGen), TTS | ✅ running |
| Legacy Import analysts | 3-phase import with human gates | ✅ running |
| Dean's Briefing agent | institution twin → governance dossiers (propose) | ⚪ (BOOK-08 Ch. 8) |
| Compliance Monitor | I5 posture watching, G8 completeness alerts | ⚪ (BOOK-19) |

All obey the same ACP composition, lifecycle and cycle discipline — authoring
agents execute *authoring moves* (an RFC will extend the catalog with the
authoring move class; Gate semantics of BOOK-07 §3.2 already govern them).

---

# Chapter 5 — Skills and Tools Doctrine

1. **Skill = typed capability.** `input_schema`/`output_schema` (running) make
   skills contract-first: a skill invocation is validatable, testable
   (`/skills/{id}/test` exists), mockable (mock-LLM mode), and portable across
   agents. Prompts (`system_prompt`, `user_prompt_tpl`) draw vocabulary from
   the ontology registry (BOOK-05 Ch. 8).
2. **MCP is the tool bus.** All external tools reach agents through
   `ai_mcp_servers` with explicit `tools_manifest`, credential binding and
   health testing (`/mcp-servers/{id}/test`). No ad-hoc HTTP calls from agent
   code — a tool outside the manifest is a conformance failure.
3. **Least tool privilege:** an agent's `tools_config` grants specific tools,
   not servers wholesale; grants are reviewable (Ch. 8) and envelope-restrictable.
4. **Knowledge scope is a boundary, not a hint:** retrieval outside
   `knowledge_scope` MUST be technically prevented (retrieval layer filters),
   not just prompted away.
5. **Provider categories** (`llm/embedding/image/audio/video`) mean the
   workforce doctrine covers media agents too — same keys, same quotas, same
   attribution.

---

# Chapter 6 — Agent Lifecycle (governed releases)

The implemented `lifecycle_state` + `deployed_at/by` becomes the normative
machine:

```text
draft → testing → deployed → suspended → retired
```

| Transition | Requirements (normative) |
|-----------|--------------------------|
| draft → testing | skills bound and schema-valid; MCP tests green; move bindings declared |
| testing → deployed | **eval pass** (BOOK-11 harness: grounding, vocabulary, envelope compliance, calibration seed); steward approval; for learner-facing agents this is a **governed release** (BOOK-02 Ch. 11 model-change control) with rollback plan |
| deployed → suspended | steward/board action or automatic circuit-breaker (Ch. 8 misbehaviour) — immediate, key revoked |
| any → retired | responsibilities handed over (envelope reassignment — BOOK-07 Ch. 4 rule 4); run logs retained |

Every deployment is versioned (config snapshot); prompts, presets, tool grants
and move bindings are all part of the version — **a prompt edit is a release**,
not a hotfix.

---

# Chapter 7 — Runtime Discipline

1. **Identity:** the per-agent virtual key is the agent's badge — every call
   attributable (agent × tenant × learner-purpose), every cost line assignable
   (BOOK-02 §8.1 attribution rides this).
2. **Cycle-bound execution:** agents act only inside ACE PDDAEL cycles
   (BOOK-09). Direct agent invocation bypassing ACE is prohibited — no
   free-running loops, no agent-to-agent calls outside the consultation
   blackboard (BOOK-09 §5.3).
3. **Rate & concurrency:** `max_calls_per_min`/`max_concurrent` enforced at
   gateway; `max_turns` caps runaway dialogues.
4. **Run logs** (`agent_run_logs`, running): every invocation with key, preset,
   tokens, cost, latency, linked cycle trace — the raw material of Ch. 8.
5. **One voice:** agent identity is metadata in the composed response
   (BOOK-09 §5.2).

---

# Chapter 8 — Supervision: the Agent Scorecard

Per agent, per release, continuously (the steward's console; feeds BOOK-08 I4):

| Dimension | Source |
|-----------|--------|
| Pedagogical efficacy | move-level outcome attribution (post-hint success rate, feedback → durable-learning deltas) |
| Calibration | BOOK-09 Ch. 7 curves per move |
| Envelope compliance | violations = 0 tolerance (hard block + incident) |
| Grounding integrity | % content-bearing moves with complete retrieval provenance |
| Vocabulary conformance | ontology drift checks (BOOK-05 Ch. 8) |
| Cost & efficiency | run logs: cost per cycle, escalation-level distribution (an agent living at L3 for L1-grade work is misconfigured) |
| Deferral health | refer_to_human rate — both too low (overconfidence) and too high (uselessness) alarm |
| Equity | outcome deltas across cohorts (blocking, BOOK-01 Ch. 10) |

**Misbehaviour playbook:** anomaly → automatic throttle to propose-tier →
steward review → fix as new release, or suspend (key revoked) → incident to the
AI Review Board (BOOK-02 Ch. 4 cadence). All automatic, all logged.

---

# Chapter 9 — Interoperability (forward)

MCP inbound (agents consume external tools) is running doctrine (Ch. 5).
**Outbound** — exposing DLU capabilities (GPS scenarios, wallet verification,
catalog) as MCP servers for external agents and partner institutions (P08) — is
an open RFC (BOOK-00 Ch. 9 "AI Agent interoperability"), with the trust boundary
rule already fixed: external agents are *clients of kernel APIs*, never members
of the workforce (no twin entitlements, no move bindings, no virtual keys with
internal scope).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Agent registry | `ai_agent_configs` (persona, scope, roles, knowledge_scope, max_turns, lifecycle, per-agent key, rate limits) | ✅ | `move_bindings`, `entitlements`, `envelope_defaults`, `calibration_ref` — ✅ delivered NEW-01 (2026-07-17, migration `20260717_1000`, additive; humility moves `refer_to_human`/`abstain` non-disableable at model+API layer); `dlu_builder_tk/backend/services/pedagogical_moves.py` + `move_policy_service.py` implement the closed 17-move catalog (Ch. 3.2) and the Decide-step preconditions engine (Ch. 2) |
| Skills | `ai_skill_registry` (typed I/O schemas, prompts, MCP binding, test endpoint, bulk import) | ✅ | ontology-vocabulary lint in skill tests 🔵 |
| Tools | `ai_mcp_servers` (transport, manifest, credentials, health tests) | ✅ | per-agent tool-grant granularity audit 🟡 |
| Presets/providers | `ai_model_presets` (scoped), `llm_providers` (categorized, fallback, cost, is_local, health) | ✅ | escalation-ladder preset classes (BOOK-09) 🔵 |
| Gateway | LiteLLM (Option B): DB-driven sync, virtual keys, pre-call quotas, usage callback | ✅ | per-engine cost attribution (BOOK-03) 🔵 |
| Run logs | `agent_run_logs` | ✅ | cycle-trace linkage (BOOK-09 Ch. 8) 🔵 |
| Lifecycle | `lifecycle_state`, `deployed_at/by`; eval-gated deployment ✅ (NEW-02, 2026-07-18: `AgentGateRun` release record + `ctx_hash` content-addressed snapshot, `POST /agents/{id}/deploy` 409s without a green steward-signed run matching the live config) | ✅ | — |
| Governance | proposals/approvals, ai_governance service | ✅ | scorecard + misbehaviour automation ⚪ |
| The nine agents | tutor/coach substrate (`learner_tutor_service`, GraphRAG, spaced repetition, Bloom quiz, plagiarism, credential service); **Discovery ✅ (STX-06, 2026-07-17)** — first agent config row + contract card (`ace_service.DISCOVERY_MOVE_BINDINGS`, `lifecycle_state="testing"`); **Academic Navigator ✅ (STX-07, 2026-07-19)** — `ace_service.seed_academic_navigator_agent`, `NAVIGATOR_MOVE_BINDINGS` (`replan_path`/`explain_concept`/`reframe_goal`), `lifecycle_state="testing"`; **Recognition ✅ (STX-12, 2026-07-19)** — `ace_service.seed_recognition_agent`, `RECOGNITION_MOVE_BINDINGS` (`recognize_prior`/`explain_concept`, propose-only per Ch. 3's card), `lifecycle_state="testing"` | 🟡 | remaining 6 agent config rows + contract cards per Ch. 3 (Learning Coach/Subject Tutor/Assessment/Student Success/Career Advisor/Credential — STX-10/11/13/14); all three delivered agents stay `testing` until their own NEW-02 harness gate run (none has run yet — no `deployed` transition for any of the nine) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| ACP (AI Control Plane) | The registry + gateway stack governing all AI capability: providers, presets, skills, MCP servers, agent configs, keys, quotas |
| Agent composition | The registry-defined identity of an agent (Ch. 2) — its only legitimate definition |
| Scope of practice | The agent's `move_bindings` — which pedagogical moves it may execute |
| Agent badge | The per-agent gateway virtual key: identity, attribution, revocability |
| Governed release | Versioned, eval-gated deployment of any agent change (a prompt edit is a release) |
| Agent scorecard | The per-release supervision record of Ch. 8 |
| Tool bus | MCP as the sole channel for agent tool access |

---

*BOOK-10 v1.0 — awaiting review. Next per dependency order: BOOK-11 (AI
Cognitive Architecture — reasoning patterns, guardrails, and the eval harness
this Book's lifecycle gates depend on).*
