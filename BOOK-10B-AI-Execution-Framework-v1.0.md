# BOOK-10B — AI Execution Framework
## Runtime, Testing, Deployment & Observability of the Intelligent Components
### DLU Architecture Standard (DAS) · Normative Annex to BOOK-10 · Version 1.0 — DRAFT

> BOOK-10A says *what* the intelligent components are; this annex says **how
> they live**: how skills and tools are adopted and resolved transparently at
> every invocation, how MCP services integrate securely, how agent-managed
> processes are configured and executed, how everything is tested before
> deployment, how deployments are governed, and how production logging makes
> **every execution transparent, fully traceable and secure**.
>
> **Reuse doctrine (binding):** the running **DLU Builder AI Control Plane is
> the foundation** — the five registries, the LiteLLM gateway (virtual keys,
> pre-call quotas, usage callback, DB-driven config sync), the test endpoints,
> `agent_run_logs`, the lifecycle fields, `LLMClientFactory`, `mock_llm`, the
> OTel/Grafana stack. Nothing below replaces it; Chapter 9 is the explicit
> reuse-vs-extend map.
>
> **Conforms to:** BOOK-09 (cycles), BOOK-10 (composition/lifecycle), BOOK-11
> (patterns/guardrails/harness), BOOK-12 (memory), BOOK-19 (security/audit).
> **Primary audience:** platform engineers, AI engineers, SRE, steward.

**Normative language:** RFC 2119.

---

# Chapter 1 — Three Planes

```text
DEFINITION plane   the ACP registries: providers, presets, skills, MCP servers,
                   agent configs (+ DAS bindings) — declarative, versioned
EXECUTION plane    ACE runtime: resolution → cycle → skill engine → tool bus →
                   gateway — everything that happens at request/mission time
OBSERVATION plane  the unified execution record: traces, run logs, tool calls,
                   guardrail hits, proposals — one correlated story per cycle
```

Invariant: **the Execution plane holds no configuration of its own** — every
behaviour is resolvable to Definition-plane rows (BOOK-10 Ch. 1 legibility
invariant, made runtime-enforceable), and every action lands in the
Observation plane. Nothing configured ad hoc; nothing executed unobserved.

---

# Chapter 2 — Resolution: from Registries to ExecutionContext

Every activation (turn or mission) begins with deterministic **resolution**:

```text
1. Agent lookup         ai_agent_configs by slug — lifecycle MUST be `deployed`
2. Scope resolution     most specific wins: course > program > dept > org
                        (scope_type/scope_id — running fields)
3. Envelope merge       platform floors → agent envelope_defaults → faculty
                        course envelope (BOOK-07 F4); ceilings enforced; result
                        is the EFFECTIVE ENVELOPE (versioned inputs recorded)
4. Skill set resolution skills by binding, PINNED to their released versions
5. Tool grant           per-agent tools_config ∩ server manifests → a
   materialization      SESSION MANIFEST (least-privilege subset, Ch. 4)
6. Identity & budget    agent badge (gateway_key_id), quota class, remaining
                        cognitive budget (BOOK-09 Ch. 6), rate/turn caps
7. Entitlements         twin-layer read set (BOOK-06 Ch. 6) + consent state
        ▼
ExecutionContext — immutable for the cycle, content-hashed:
  ctx_hash = sha256(agent_version, envelope_version, skill_versions[],
                    manifest_hash, preset_version, entitlements, locale)
```

`ctx_hash` is the **reproducibility token**: identical hash ⇒ identical
configured behaviour. It enters the cycle trace (BOOK-09 Ch. 8) — any
execution can answer *"exactly which configuration acted?"* in one field.
Resolution is cached per hash inputs (invalidated by config-sync events);
resolution failures (missing grant, suspended agent, expired skill version)
abort the cycle loudly with an audited reason.

---

# Chapter 3 — Skill Execution Engine

The single runtime for every skill invocation (`skill_execution_service` —
new kernel service wrapping the running `LLMClientFactory` path):

```text
invoke(skill_ref, input, ctx):
  1 validate input against input_schema (reject early, no model cost)
  2 compose prompt: platform base → persona → effective envelope → skill
    template (locale variant) → cycle context     [layer versions → trace]
  3 gateway call: pre-call quota check → LiteLLM (badge key, preset,
    fallback chain) → usage callback              [running ACP, as-is]
  4 validate output against output_schema → repair loop (≤ N, errors fed
    back) → on failure: abstain (never malformed output downstream)
  5 egress guardrails (BOOK-11 Ch. 5.3) → block-regenerate-once → abstain
  6 emit SkillInvocation record (Ch. 8) + cost/latency telemetry
```

Rules: skills are **pure with respect to state** — they read only their
inputs and declared retrieval (no side effects; effects happen via ACE
Learn-phase events); deterministic-cacheable skills (extraction,
classification) MAY serve from an input-hash cache (L1 of the escalation
ladder); sync path for conversational turns, Celery path for missions —
one engine, two schedulers (the running async/sync doctrine).

---

# Chapter 4 — MCP Integration Layer

## 4.1 Client manager (extends the running `ai_mcp_servers` registry)

- **Connections:** pooled per server; transports per registry row (running
  field); startup handshake validates the manifest against the registered
  `tools_manifest` — drift (server offers tools the registry doesn't know)
  is a health failure, not a silent expansion.
- **Credentials:** injected per server from `llm_credentials` (running FK);
  never in prompts, never in logs.
- **Health:** the running test endpoint becomes a scheduled probe
  (`last_tested_at/last_test_ok` — running fields) + circuit breaker; an open
  circuit degrades the dependent skills to abstain-with-notice.

## 4.2 Tool invocation flow (per call)

```text
grant check (session manifest) → context propagation header:
  {agent_badge, acting_user, tenant, purpose, cycle_id, trace_id}
→ invoke → response schema check → ToolCall record → return to skill/move
```

- **Session manifest** (Ch. 2 step 5): the agent can only see/call the tool
  subset granted for THIS cycle — least privilege at runtime, not just at
  configuration.
- **Tool budget:** per-cycle call caps (envelope-tunable) prevent tool loops.
- **Internal servers** (BOOK-10A §4.1) are thin MCP facades over kernel
  services; **entitlement enforcement is server-side** (the twin-context
  server re-checks BOOK-06 Ch. 6 itself — defense in depth, the agent's
  claim is never trusted).
- **Sandboxing:** `dlu-code-executor` runs isolated (no network, resource
  caps); generic servers have egress allowlists.

---

# Chapter 5 — Agent Process Execution

## 5.1 Two execution modes, one cycle discipline

| Mode | Scheduler | Reuses | Shape |
|------|-----------|--------|-------|
| **Conversational turn** | FastAPI (async, SSE) | ACE route (STX-06) | one PDDAEL cycle per turn; first token p95 < 3 s |
| **Mission** | Celery (+beat) | `AgentWorkflow`/`AgentStep` (running orchestrator, generalized) | a mission = a plan of cycles; Workflow row = mission instance, Step row = cycle |

## 5.2 Mission definitions (declarative, registry-stored)

```yaml
mission: nightly-risk-scan
agent: dlu-student-success
trigger: {schedule: "0 3 * * *"}          # or {event: "mastery.updated", filter: …}
selector: cohort(active, risk_priority)    # cognitive-budget governed
steps: [assess-learner-state, score-risk, propose-if(threshold)]
budget: {class: mission, max_cycles: 500, max_cost: …}
timeout: 2h · idempotency: per(twin, day) · on_failure: resume-from-checkpoint
```

Missions are **event-mesh citizens**: triggered by taxonomy events or beat;
checkpoints persisted as Step rows (resumable); cancellation and timeout are
first-class; HITL steps park the mission on the proposals queue and resume on
decision events. Mission definitions are Definition-plane rows — versioned,
released, observable like everything else.

---

# Chapter 6 — Testing Framework (before anything deploys)

Five layers, each reusing something that runs today:

| Layer | Tests | Substrate |
|-------|-------|-----------|
| T1 Unit/schema | skill I/O schemas, prompt-template rendering, resolution logic | `mock_llm_service` ✅ (deterministic, zero-cost, CI-fast) |
| T2 Skill golden | per-skill golden input→output suites (incl. locale variants — M5) | running `/skills/{id}/test` endpoint, extended to suites |
| T3 MCP contract | manifest conformance, consumer-driven contracts per tool, entitlement negative tests | running `/mcp-servers/{id}/test` + contract fixtures |
| T4 Agent harness | scenario bank + graders + gates (BOOK-11 Ch. 6) — pedagogical quality, safety zero-tolerance classes, equity slices, both locales | NEW-02 |
| T5 Integration | end-to-end cycles on a **synthetic test tenant** (seeded fixture university: programs, courses, twin fixtures) — turn + mission paths, event emission, observability assertions | test tenant seeds (extends `ai_university_defaults` seeding machinery) |

CI wiring: T1–T3 on every PR; T4 on release candidates (gate); T5 nightly +
pre-release. **No real learner data in any test tier** (fixtures only —
BOOK-19). Every tier's report is an artifact attached to the release record.

---

# Chapter 7 — Deployment Pipeline (governed releases, operationalized)

```text
draft ──T1-T3──► testing ──T4 gate + steward sign──► deployed ──anomaly──► suspended
                                                        │ (canary/shadow)      ▲
                                                        └── rollback = pointer swap
```

1. **Release = snapshot:** deploying an agent (or skill/mission/envelope-
   default change — *a prompt edit is a release*, BOOK-10) freezes a
   content-addressed bundle: config + prompt layers + skill versions + manifest
   + preset. The bundle hash is what `ctx_hash` resolves against.
2. **Gate artifacts:** T4 harness report + steward approval attach to the
   release row (`deployed_at/deployed_by` — running fields); missing artifacts
   make the transition impossible (schema-enforced).
3. **Canary & shadow:** the house pattern (gateway cutover ACP-GW-06):
   new release shadows on sampled cycles (responses scored, not served) or
   canaries on a cohort %; promotion on parity/quality report.
4. **Propagation:** the running `GatewayConfigSyncService` pattern extends to
   agent/skill/mission registries — DB-driven sync, ≤ 60 s to all runtimes;
   **suspension propagates the same way**: badge key revoked + config sync ⇒
   agent stops platform-wide in seconds (the kill switch, BOOK-19).
5. **Environments:** dev → staging → prod topologies (running compose set);
   promotion moves bundles, never hand-edits; per-tenant enablement flags let
   institutions adopt releases on their own cadence within support windows.

> ✅ **IMPLEMENTED, partially (NEW-28, SPRINT-17, 2026-07-31):** point 2's "gate artifacts
> attach to the release row" now has a preset-scoped equivalent — `preset_rollouts.
> eval_run_id` (`dlu_builder_tk`, T11) requires a linked, PASSING `eval_run` before a
> rollout can activate, the exact "missing artifacts make the transition impossible" rule
> point 2 already names, applied to preset versioning specifically (see BOOK-11 Ch. 7's own
> IMPLEMENTED callout for the full mechanism). `preset_rollouts.traffic_pct` is an honest,
> disclosed FIRST STEP toward point 3's "canary on a cohort %" — it records an intended
> traffic percentage, but no runtime code anywhere in this codebase actually SPLITS live
> traffic by it yet; a future sprint's job, not fabricated here. Chapter 6's T4 row
> (scenario bank + gates) gains a sibling, lighter-weight T11 golden-set harness for 3
> non-ACE-agent domains (generation/admission_evaluation/nudging) with its own CI gate job
> — see BOOK-11 Ch. 6's own IMPLEMENTED callout for the full detail.

---

# Chapter 8 — Production Observability: the Unified Execution Record

## 8.1 One story per cycle (full traceability)

Every activation yields a correlated record set, joined by
`(trace_id, cycle_id)`:

```text
HTTP/SSE request or mission step
 └─ CycleTrace         (BOOK-09 Ch. 8: context, diagnosis, decision, ctx_hash)
     ├─ SkillInvocation[]   (skill version, prompt-layer versions, schema results,
     │                       repair count, guardrail verdicts, cost, latency)
     ├─ ToolCall[]          (server, tool, grant ref, args hash, outcome)
     ├─ GatewayCall[]       (agent_run_logs ✅: badge, preset, tokens, cost)
     ├─ GuardrailHit[]      (layer, rule, action taken)
     ├─ Event[]             (mesh emissions — outbox ids)
     ├─ MemoryWrite[]       (M2/M3 refs — BOOK-12 lineage)
     └─ ProposalDecision[]  (HITL outcomes, decider, latency)
```

**Query contract:** given any credential, recommendation, grade-adjacent
artifact or learner complaint, the platform MUST reconstruct the complete
causal story in one query (the audit fabric join — BOOK-19 Ch. 2.5). The
learner-facing "why?" affordance (BOOK-17) reads the **same records** — one
source of truth for auditors and learners alike; only the rendering differs
(BOOK-09 Ch. 8 audiences).

## 8.2 Record discipline

- **Payload minimization:** records hold references and hashes, not content
  copies (prompts reference layer versions; retrieved chunks by ref; learner
  text referenced from its store) — PII never duplicated across records.
- **Retention classes** per BOOK-04 Ch. 8/BOOK-19; audit-grade records
  survive erasure with pseudonymization (audit ≠ memory, BOOK-12).
- **Tamper evidence:** append-only + periodic hash chaining (BOOK-19 Ch. 2.5);
  **access to records is itself audited** (who read whose traces, purpose).
- **Secrets hygiene:** keys, credentials and raw tokens never appear in any
  record (structurally: the record schemas have no fields for them).

## 8.3 OTel mapping & operations

Span hierarchy mirrors §8.1 (cycle = root span; skills/tools/gateway = child
spans) on the running OTel→Tempo stack; metrics to Prometheus (cost per
engine, guardrail-hit rates, deferral rates, consumer lag, calibration drift);
dashboards feed the Steward Console (IW5) and I4; alert classes: safety
(guardrail spike, crisis-path invocation), economic (quota burn, unattributed
spend), quality (calibration drift, rubric decay in shadow evals),
operational (circuit open, sync lag). Every alert names its runbook.

---

# Chapter 9 — ACP Reuse & Extension Map (explicit)

| Running component | Disposition |
|-------------------|-------------|
| `llm_providers` (categorized, fallback, cost, health) | **reuse as-is** |
| `ai_model_presets` (scoped) | **reuse**; add preset-class tag (P-fast/standard/deliberate) |
| `ai_skill_registry` (I/O schemas, prompts, MCP binding, test endpoint) | **reuse**; extend: version pinning, locale variants, golden suites (T2) |
| `ai_mcp_servers` (transport, manifest, credentials, health) | **reuse**; extend: scheduled probes, circuit breaker, manifest-drift check |
| `ai_agent_configs` (persona, scope, roles, limits, lifecycle, badge key) | **reuse**; extend (BOOK-10 additive ALTERs): move_bindings, entitlements, envelope_defaults, calibration_ref |
| LiteLLM gateway + virtual keys + quotas + usage callback + config sync | **reuse as-is**; extend attribution (per-engine, NEW-14) |
| `LLMClientFactory` | **reuse** beneath the skill engine (signatures unchanged — running constraint) |
| `agent_run_logs` | **reuse**; extend: cycle_id/trace_id linkage |
| `AgentWorkflow`/`AgentStep` orchestrator | **reuse, generalize** into the mission runtime (Ch. 5) |
| `mock_llm_service`, test endpoints | **reuse** as T1–T3 substrate |
| `ai_governance` proposals/approvals | **reuse** as the HITL queue |
| `ai_university_defaults` | **reuse, evolve** into the catalog seeder (BOOK-10A Ch. 5) |
| **New:** skill_execution_service, resolution/ctx_hash, session manifests, mission definitions, unified record set, T4/T5 tiers, canary/shadow for agents | **add** (K2 sprints: STX-06, NEW-01/02/03 + this Book's items into BOOK-20 scopes) |

BOOK-20 scope note: Chapter 2/3/4 land inside **STX-06** (ACE runtime) and
**NEW-01**; Chapter 5 missions inside **STX-06/NEW-03**; Chapter 6–7 inside
**NEW-02** (+T5 test tenant as its V-item); Chapter 8 record set rides
**STX-06** with linkage completed by **STX-03** trace propagation.

---

# Glossary additions

| Term | Definition |
|------|-----------|
| ExecutionContext / ctx_hash | Immutable per-cycle resolved configuration; the reproducibility token |
| Effective envelope | Merge result: platform floors → agent defaults → faculty course envelope |
| Session manifest | The least-privilege tool subset materialized for one cycle |
| Skill engine | The single validated-prompt-composed-guarded invocation path for all skills |
| Mission definition | Declarative, versioned agent process (trigger, selector, steps, budget) |
| Release bundle | Content-addressed snapshot of everything a deployment freezes |
| Kill switch | Badge revocation + config sync — platform-wide stop in seconds |
| Unified execution record | The correlated per-cycle record set of §8.1 — one query, full story |
| Test tenant | Seeded synthetic university for T5 integration; no real learner data in tests |

---

*BOOK-10B v1.0 — awaiting review. With 10A (what) and 10B (how) approved, the
K1 prompt pack generation has its complete intelligent-layer specification.*


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Tutor execution runs through the governed LLM gateway; policy chooses the action, the model renders it; every response is explainable and audited.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
