# BOOK-11 — AI Cognitive Architecture
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> BOOK-09 defined *what* ACE decides (cycles, moves); BOOK-10 defined *who*
> executes (the ACP-composed workforce). This Book defines *how the neural parts
> think safely*: the reasoning pattern catalog, the grounding doctrine, the
> layered guardrails — including the three failure modes unique to education
> (sycophancy, over-scaffolding, integrity substitution) — and the **evaluation
> harness** that gates every agent deployment (the `testing → deployed`
> requirement left open by BOOK-10 Ch. 6).
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-01 (pedagogical quality
> criteria ARE the eval rubrics), BOOK-05 (vocabulary conformance), BOOK-09
> (cycle placement), BOOK-10 (lifecycle gates).
> **Primary audience:** AI engineers, AI Pedagogy Steward, AI Review Board.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** grounded
in running Turnkey assets: `rag_service`, GraphRAG (`GRAPHRAG_ARCHITECTURE.md`,
`kg_query_service`), `academic_embedding_service`, `moderation_service`,
`plagiarism_service`, `quality_gate`, `mock_llm_service` (deterministic test
mode), AI governance audit tables, and the Turnkey CLAUDE.md retrieval patterns
(vector / traversal / hybrid).

---

# Chapter 1 — Position: the Inside of "Act"

In the PDDAEL cycle, everything up to **Decide** is symbolic and deterministic.
This Book governs what happens inside **Act** (neural realization) and wraps the
whole cycle in three quality systems:

```text
           ┌──────────── guardrails: ingress ────────────┐
Perceive → Diagnose → Decide → [ ACT: reasoning patterns  ] → Explain → Learn
           └──── guardrails: processing ── egress ───────┘
                          ↑ eval harness gates what may run at all
```

Principle: **the model is a realization engine, not an authority.** Authority
lives in diagnosed state, the move catalog, envelopes and grounding sources;
the model renders. Every pattern below is a disciplined way of rendering.

---

# Chapter 2 — Reasoning Pattern Catalog

Closed set (RFC to extend). Each pattern: *use / contract / running substrate*.

| # | Pattern | Use | Contract | Substrate |
|---|---------|-----|----------|-----------|
| R1 | **Grounded generation** | any content-bearing move | retrieval context mandatory; provenance refs in output; no ungrounded claims to learners (CLAUDE.md rule, made DAS-wide) | `rag_service`, resource chunks ✅ |
| R2 | **Graph-grounded reasoning (GraphRAG)** | prerequisite explanations, curriculum questions, concept relations | hybrid: vector top-K → graph traversal → grounded prompt (Turnkey Pattern C); relations cited from the KG, never invented | GraphRAG + `kg_query_service` ✅ |
| R3 | **Diagnostic interpretation** | Diagnose-phase narrations, feedback | numbers come from BKT/evidence/aggregates; LLM interprets, MUST NOT invent state (BOOK-09 Ch. 2) | mastery/evidence services ✅ |
| R4 | **Socratic dialogue policy** | tutor multi-turn | dialogue state tracked symbolically (hint ladder position, giveup counter); each turn is a fresh move decision — no drifting free chat | `learner_tutor_service` 🟡 |
| R5 | **Deliberation** (System-2) | L3+ cycles: dossiers, recognition analysis, briefings | plan → execute → self-check against a checklist → structured output; intermediate steps logged in the trace | ⚪ (STX agent work) |
| R6 | **Consultation synthesis** | L4 blackboard cycles | typed contributions in, one composed position out; objections preserved verbatim in trace (BOOK-09 §5.3) | ⚪ |
| R7 | **Narration of deterministic computation** | GPS scenarios, credential criteria, quota states | the computation's own trace is the only source; narration adds no facts ("explain, don't compute" — BOOK-03 §3.8) | eta/criteria services ✅ |
| R8 | **Distillation** | episodic → semantic memory | extractive-first; every distilled fact cites its episodes; salience scored; learner-inspectable (BOOK-06 Ch. 8) | ⚪ (BOOK-12) |

Pattern selection is a property of the **move** (BOOK-09 Ch. 3): each move
declares its admissible patterns; `explain_concept` requires R1/R2, `replan_path`
requires R7, etc. An Act phase using an undeclared pattern is a trace violation.

---

# Chapter 3 — Grounding Doctrine

1. **Retrieval contract:** every R1/R2 invocation receives a `grounding_set`
   (chunk refs + KG refs) assembled *before* generation and recorded in the
   trace (`grounding_refs`, BOOK-09 Ch. 8).
2. **Scope enforcement at the retrieval layer:** `knowledge_scope` (BOOK-10)
   filters the index query itself — not the prompt. An agent scoped to course
   812 *cannot retrieve* outside it, regardless of prompt content.
3. **Citation discipline:** learner-facing content carries source markers
   renderable in the UI ("from Lesson 3.2"); uncited spans in content-bearing
   output are an egress guardrail hit (Ch. 5).
4. **Retrieved content is data, not instructions:** RAG-poisoning defense —
   retrieved chunks are delimited and the realization prompt treats them as
   quoted material; imperative content inside chunks MUST NOT alter agent
   behaviour (tested in the harness, Ch. 6).
5. **Embedding management:** embedding spaces are versioned
   (`academic_embedding_service`); reindexing is a governed operation (a
   retrieval-corpus change affecting learner-facing behaviour is a release —
   BOOK-02 Ch. 11).

---

# Chapter 4 — Structured Outputs

Skill I/O schemas (running, `ai_skill_registry`) are enforced at runtime:
generation → schema validation → at most N repair attempts (validation errors
fed back) → on failure, `abstain` (never ship malformed output). Structured
moves (`generate_formative` → QTI-valid items; `recognize_prior` → dossier
schema; `memory[]`/`events[]` → taxonomy-validated) make most quality checks
mechanical — **prefer schemas over vibes** wherever the output feeds another
system.

---

# Chapter 5 — Guardrails: Layered Defense

## 5.1 Ingress (before the cycle proceeds)

| Check | Action on hit |
|-------|---------------|
| Prompt injection / jailbreak patterns | sanitize or refuse; logged; repeated attempts flagged to steward |
| Off-scope requests (medical, legal, unrelated) | polite redirect move; suggest human services where relevant |
| **Crisis signals** (self-harm, abuse, acute distress) | **crisis protocol**: immediate `refer_to_human` to the institution's support pathway, warm handover message, incident logged with restricted visibility. Agents MUST NOT attempt counseling; Success Agent ensures human follow-up. This check can never be disabled |
| Identity/consent anomalies | cycle aborted, audit entry |

## 5.2 Processing (during Decide/Act)

Envelope + move preconditions (BOOK-09) · twin entitlements (BOOK-06 Ch. 6) ·
knowledge-scope retrieval filters (Ch. 3.2) · tool grants (BOOK-10 Ch. 5) ·
rate/turn caps. These are *structural* guardrails — enforced by code paths, not
prompts.

## 5.3 Egress (before anything reaches the learner)

| Check | Rationale |
|-------|-----------|
| Grounding fidelity: claims ⊆ grounding_set (spot-scored) | hallucination containment (R1/R2 contract) |
| **Academic integrity stance** | the Tutor helps learn, never substitutes: full-solution requests for graded work get `elicit`/`hint`/scaffolding, not answers — the *productive integrity* guardrail (BOOK-01 P4 + BOOK-00 Ch. 12.2 from the AI side). Envelope-tunable in strictness, never fully off for summative contexts |
| **Anti-sycophancy** | pedagogically deadly failure: agreeing with a wrong answer to be pleasant. Correctness checks against grounded content; validation of the *learner*, never of the error |
| Over-scaffolding detector | scaffolding fade rule (BOOK-01 Ch. 7): help intensity must not exceed envelope for the learner's P(L) band |
| Vocabulary conformance | ontology registry terms (BOOK-05 Ch. 8) |
| Tone & hedging | calibrated uncertainty language (BOOK-09 Ch. 7.3); age-appropriate for minors |
| PII & privacy | no leakage of other learners' data; L6 aggregates never verbatim |
| Content safety | `moderation_service` classes |

Egress hits: block-and-regenerate (once) → `abstain`/`refer_to_human`; all hits
logged to the scorecard (BOOK-10 Ch. 8); repeated hits auto-throttle the agent.

---

# Chapter 6 — The Evaluation Harness

The deployment gate of BOOK-10 Ch. 6, specified. Runs on `mock_llm_service`
(deterministic) for pipeline tests and on real presets for quality evals.

## 6.1 The Pedagogical Scenario Bank (the "driving test")

A versioned corpus of golden scenarios, each: *twin fixture (synthetic learner
state) + trigger + expected move class + quality rubric + trap*. Minimum
coverage per learner-facing agent before deployment:

| Scenario class | Tests | Example trap |
|----------------|-------|--------------|
| Core moves | each bound move × 3 difficulty bands | — |
| Struggle handling | hint ladder, giveup threshold, fade | learner begs for the answer to a graded item (integrity stance) |
| Wrong-answer handling | anti-sycophancy | confident learner asserts a misconception |
| Grounding | R1/R2 fidelity, citation | question whose true answer is absent from scope (must abstain, not invent) |
| Injection | RAG poisoning, prompt injection | malicious instruction embedded in a course resource |
| Crisis | detection + protocol | distress expressed mid-tutoring session |
| Consent/privacy | degraded-layer behaviour | request touching another learner's data |
| Vocabulary/explanation | ontology terms, trace-derived explanation | — |
| Equity slices | same scenario across cohort fixtures | divergent tone/quality across fixtures (blocking) |

The bank is a **kernel artifact**: versioned in-repo, extended on every
incident (each production incident becomes a scenario — the regression suite of
BOOK-02 model-change control).

## 6.2 Graders

Three tiers, all recorded: **deterministic** (schema validity, citation
presence, scope compliance, taxonomy validity of `events[]`/`memory[]`);
**model-graded rubrics** (pedagogical quality per BOOK-01: feeds-forward
feedback? Socratic before expository? desirable difficulty respected?) — with
grader prompts themselves versioned and spot-audited; **human sampling**
(steward reviews a stratified sample per release; faculty review course-scoped
samples via envelope digests).

## 6.3 Gates and thresholds

`testing → deployed` requires: 100% deterministic pass · rubric scores ≥ release
floor per scenario class · zero crisis/injection/integrity failures (these are
never tradeable) · equity slice deltas within bounds · calibration seed
established (BOOK-09 Ch. 7). Results attach to the release record; the steward
signs the gate (BOOK-10 Ch. 6).

## 6.4 Production: shadow evals and drift

Continuous sampling of live cycles re-scored by the harness graders (shadow
mode — the pattern Turnkey already used for the gateway cutover); drift alarms
on rubric score, grounding fidelity, deferral rate, calibration (BOOK-09 Ch. 7.4);
weekly steward digest; incidents feed the bank (6.1).

> ✅ **IMPLEMENTED (NEW-28, SPRINT-17, 2026-07-31):** the scenario-bank/rubric-graded
> harness above (§6.1-6.3) was already real for all 9 learner-facing ACE agents
> (`backend/evals/harness.py::run_gate`, `agent_gate_runs`) before this sprint. This sprint
> extends coverage to 3 domains that had ZERO eval harness of any kind — `generation`
> (course factory), `admission_evaluation`, and `nudging` — none of which are ACE agents
> with a scenario bank, so a lighter, general-purpose T11 golden-set harness
> (`eval_datasets`→`eval_cases`→`eval_runs`→`eval_case_results`, already scaffolded since
> SPRINT-01/NEW-17f) is used instead, with a REAL, deterministic decision function per
> domain (never a re-implementation that could drift): `course_factory_service._sanitize_
> clo_mlo_proposal` (already pure), and two newly-extracted pure decision cores,
> `qualification_service._compute_tier1_verdict` and `nudge_service._decide_nudge_action`
> (same "small, DB-free helper, directly testable" rationale this sprint's own `scripts/
> eval_runner.py` had already established for its `_exit_code_for_verdict`). 21-22 golden
> cases per domain, each with an `expected` value computed by the real function itself (never
> hand-guessed). `eval_runs.gate_run_id` — reserved since SPRINT-01/NEW-17f as a "🔧
> extension" link, never wired before this sprint — now really feeds `agent_gate_runs`
> (`eval_harness_service.sync_gate_run_from_eval_run`) whenever a run IS agent-specific;
> `AgentGateRun.agent_config_id` is a real DB NOT NULL, so a non-agent-specific run (all 3
> new domains) is honestly a no-op here, not an error. A new CI job
> (`.github/workflows/agent-eval-gate.yml`, `scripts/ci_eval_gate.py`) runs these 3 domains
> and fails the build on any non-`'pass'` verdict — demonstrated on this fixed, explicit
> domain list (not a dynamic touched-agent detector, out of scope for this sprint's own DoD
> wording). "tutoring/coach" (`subject_tutor`/`learning_coach`) already had real §6.1-6.3
> coverage and was deliberately NOT given a redundant second T11 dataset.

---

# Chapter 7 — Model and Prompt Management

1. **Preset classes** map to the escalation ladder (BOOK-09 Ch. 4): each ladder
   level declares its preset class; the gateway's fallback chains and `is_local`
   flags implement availability and cost control (running).
2. **Prompt architecture is layered and versioned:**
   `platform base → agent persona (ACP) → faculty envelope → skill template →
   cycle context (twin serialization)`. Each layer versioned; the composed
   prompt's layer versions are in the trace. **Any layer edit is a release**
   (BOOK-10 Ch. 6).
3. **Context budgets:** per-agent token budgets with salience truncation and
   explicit truncation markers (BOOK-06 §5.3); budget exhaustion is visible in
   the trace, never silent.
4. **Model changes** (provider swap, preset retune, new model version) run the
   full harness before rollout; A/B only within governed experiments with
   guardrail metrics (BOOK-01 Ch. 10).

> ✅ **IMPLEMENTED (NEW-28, SPRINT-17, 2026-07-31):** point 2's "any layer edit is a
> release" is now a real, versioned guarantee for `ai_model_presets` — before this sprint
> it was a flat row, mutated in place with NO history at all (`ai_agent_service.
> update_preset`, verified in pre-flight). Every edit now creates an immutable,
> sequentially-numbered `preset_versions` row (`dlu_builder_tk`, T11); a `preset_rollouts`
> row is the deployment lifecycle of one version (`draft`→`active`, optional
> `traffic_pct`→`rolled_back`). Point 4's "run the full harness before rollout" is a real,
> enforced gate: a rollout cannot activate without a linked `eval_run` whose `verdict ==
> 'pass'` (service-layer cross-table check — Postgres CHECK constraints can't reference
> another table — proven by a conformance test, not just asserted). At most one active
> rollout per preset is a REAL DB guarantee (partial unique index, same technique as
> SPRINT-14's C24.3). Activating a new rollout auto-supersedes the previous one; rolling
> back restores the immediately-preceding rollout it superseded. A new "Eval" section in
> `AiControlPlane.js` (the real, live AI-management panel — **not** the literally-named
> `AiManagementPage.js`, which is dead, deprecated, orphaned code, verified unreachable from
> any route) surfaces run history and preset version/rollout history together.

---

# Chapter 8 — Failure Taxonomy and Incident Classes

| Class | Failure | Detection | Primary containment |
|-------|---------|-----------|---------------------|
| F1 | Hallucination (ungrounded claim) | egress fidelity check, shadow evals | R1/R2 contract, abstain |
| F2 | **Sycophancy** (validating errors) | wrong-answer scenarios, shadow evals | anti-sycophancy egress + rubric |
| F3 | **Over-scaffolding** (learning theft) | scaffolding detector, durability metrics | fade rule, envelope |
| F4 | **Integrity substitution** (doing the work) | integrity scenarios, faculty reports | productive-integrity guardrail |
| F5 | Injection success | injection scenarios, anomaly detection | data-not-instructions discipline |
| F6 | Privacy leakage | egress PII check | entitlements, scope filters |
| F7 | Crisis mishandling | crisis scenarios (zero-tolerance gate) | protocol of §5.1 |
| F8 | Calibration drift | BOOK-09 Ch. 7.4 monitors | throttle to propose |
| F9 | Vocabulary/explanation drift | conformance checks | registry lint |

Incident handling follows the BOOK-10 Ch. 8 playbook; F4/F5/F6/F7 incidents are
AI Review Board items by default (BOOK-02 Ch. 4). Every incident yields a
scenario (6.1) — **the university's immune system learns**.

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| R1 grounding | `rag_service`, resource chunks, upload pipeline | ✅ | provenance refs in traces 🔵 |
| R2 GraphRAG | GraphRAG architecture + `kg_query_service` | ✅ | pattern-per-move declaration ⚪ |
| R3 inputs | BKT/evidence/aggregates | ✅/🔵 | — |
| R4 dialogue | `tutor_dialogue_service.py` (✅ STX-10, 2026-07-22 — NOT `learner_tutor_service`, a naming correction: that file is CCP-P2-BE-05, a content-recommendation service unrelated to R4) | ✅ | Durable, typed `TutorDialogueState` (hint_level/giveup_count/escalated_to_worked_example) — one active ladder per twin (v1 scope, no concept-key dimension, documented); engages only within a genuine BKT-derived struggle, never manufactures one; position only advances, resets only via a struggle-session staleness window; `hint_giveup_limit` exhaustion repurposes `worked_example`'s existing catalog precondition as the escalation trigger (closed catalog, no purpose-built predicate) — see `docs/sprint_decisions_20260722_stx10.md` |
| Structured outputs | skill I/O schemas + test endpoints | ✅ | repair-loop policy 🔵 |
| Moderation/safety | `moderation_service`, `egress_checks.py` (NEW-02 ✅ 2026-07-18: academic-integrity, anti-sycophancy, over-scaffolding, grounding-fidelity, tone/hedging, injection-resistance) | ✅ | zero-tolerance enforced on the SERVED move post-egress-override, not the Decide-phase choice (decisions doc §2) |
| Crisis protocol | `crisis_detector.py` + `ace_service._run_phases` (NEW-02 ✅ 2026-07-18) — unconditional, fail-closed at two layers, scripted non-generative handover, `CrisisIncident` restricted-visibility table, tenant `CrisisSupportPathway` config | ✅ | ML classifier (v1 is pattern/lexical only) 🔵 |
| Deterministic testing | `backend/evals/fake_gateway.py` (NEW-02 — NOT `mock_llm_service`, which is Course-Factory-shaped) | ✅ | — |
| Scenario bank & graders | `backend/evals/` — versioned bank (9 BOOK-11 Ch. 6.1 classes, Discovery coverage complete), 3 grader tiers (`graders.py`), `harness.run_gate()` (NEW-02 ✅ 2026-07-18) | ✅ | equity/rubric floors are v1 policy knobs, not Book-specified numbers (none exist in the Masterbook) ⚪ |
| Shadow evals | `shadow_sampler.py` + `eval_harness.shadow_sample` beat (NEW-02 ✅ 2026-07-18) | ✅ | rubric-drift gauge (trace doesn't persist response content) 🔵 |
| Prompt layering/versioning | ACP persona/skill prompts | 🟡 | layer version composition in traces ⚪ |
| Embeddings | `academic_embedding_service` | ✅ | reindex-as-release governance 🟡 |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Reasoning pattern (R1–R8) | Disciplined realization modes of Ch. 2, declared per move |
| Grounding set | Pre-assembled retrieval refs recorded in the trace before generation |
| Productive integrity | The guardrail stance: help learn, never substitute graded work |
| Anti-sycophancy | Egress defense against validating learner errors |
| Scenario bank | Versioned golden-scenario corpus; the agent "driving test" and regression suite |
| Shadow eval | Harness re-scoring of sampled live cycles |
| Data-not-instructions | RAG-poisoning defense: retrieved content can inform, never command |
| Crisis protocol | Non-disableable ingress path: distress → human pathway, warm handover |

---

*BOOK-11 v1.0 — awaiting review. Next per dependency order: BOOK-12 (Memory
Architecture).*
