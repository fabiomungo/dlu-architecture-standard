# BOOK-12 — Memory Architecture
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> Memory is what makes the AI-native university feel *continuous* — a mentor who
> remembers you across years is the promise of the personal academic
> intelligence (BOOK-00 Manifesto #6). It is also the platform's largest privacy
> liability. This Book resolves the tension by design: **remember enough to
> mentor, forget enough to be trusted** — four typed stores, a governed
> consolidation pipeline, retrieval budgets, and forgetting as a feature.
>
> A structuring observation: DLU runs **two memory systems**. The *learner's own
> memory* is already modeled (BKT mastery, SM-2 forgetting curves — BOOK-01);
> this Book specifies the *institution's memory about the learner* — and it
> deliberately mirrors the same science: encoding, consolidation, salience,
> decay, retrieval.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-06 (L7, F6), BOOK-09
> (Ch. 9 contract, traces), BOOK-11 (R8 distillation). **Informs:** BOOK-17
> (memory UX), BOOK-19 (retention).
> **Primary audience:** AI engineers, architects, data-protection officers.

**Normative language:** RFC 2119.

---

# Chapter 1 — The Four Stores

BOOK-09 Ch. 9 named three; this Book adds the fourth (procedural) and binds all
four to contracts:

| Store | Holds | Lifetime | Human analogue |
|-------|-------|----------|----------------|
| **M1 Working** | the live cycle: blackboard, assembled context, in-flight state | one PDDAEL cycle | attention / working memory |
| **M2 Episodic** | what happened: cycle traces, interaction summaries per session, mission reports | retention-classed (Ch. 6) | autobiographical memory |
| **M3 Semantic** | what is durably true about this learner: distilled facts, preferences, commitments (`TwinAIMemory`, L7 / F6) | until superseded, expired or deleted | knowledge about a person |
| **M4 Procedural** | how the engine has learned to act: per-move calibration curves, cached L1 decisions, tuned defaults per envelope | model/release-scoped | skills and habits |

Store discipline (normative):

1. Each store has exactly one writer path: M1 by the cycle runtime; M2 by the
   Learn phase; M3 by ACE-validated `memory[]` (BOOK-03 §3.9) and the
   consolidation pipeline (Ch. 3); M4 by the calibration and caching subsystems
   (BOOK-09 Ch. 4/7).
2. **M4 holds no personal content.** Procedural memory is about the *engine's*
   competence (statistics, policies), keyed to move types, presets and
   envelopes — never to identifiable learner facts. This keeps the engine's
   accumulated skill outside every erasure and consent boundary, legitimately.
3. Stores never leak into each other except through the declared pipelines
   (M2→M3 consolidation; M2→M4 calibration aggregation).

---

# Chapter 2 — Store Contracts

## M1 Working

Keyed `(twin_id, twin_version, cycle_id)` (BOOK-09 §5.3); Redis-resident;
destroyed at cycle end (its durable residue is the trace, which belongs to M2).
Nothing in M1 survives unaudited: whatever mattered became trace, memory write
or event.

## M2 Episodic

- **Content:** cycle traces (BOOK-09 Ch. 8 schema), per-session interaction
  summaries (generated at session close — verbatim transcripts are
  short-retention operational data, NOT episodic memory), mission reports,
  `agent_run_logs` linkage.
- **Index:** vector-searchable (the running chroma substrate) for
  "have we discussed this before?" retrieval — scoped per twin.
- **Distinction (normative):** the learner's *activity* stream (xAPI/Caliper)
  is C6 kernel data, not AI memory. M2 is the record of *AI interactions*, not
  of learning activity. The two must not be conflated: activity feeds the twin's
  Knowledge layer; episodes feed the AI's continuity.

## M3 Semantic

- **Content:** `TwinAIMemory` rows — `memory_type` (fact | preference |
  intervention | summary), content in DLU-Core vocabulary, `salience` (0..1),
  `agent_key` (null = shared across the workforce), `expires_at`, episode
  citations (provenance — Ch. 3).
- **Quality bar:** atomic (one fact per row), sourced (cites episodes),
  phrased to be shown to the learner verbatim (inspectability is the writing
  standard — if it cannot be shown, it cannot be stored).
- **Never:** raw transcripts, protected attributes, third-party facts
  ("her roommate said…"), speculation not marked as such.

## M4 Procedural

Calibration state per (move, preset, envelope class); L1 decision caches keyed
(trigger class, twin_version) with bounded TTL; learned defaults proposed to
envelopes (propose-tier: faculty accept tuning suggestions, they are not
auto-applied). Release-scoped: a new agent release starts from inherited-but-
flagged procedural state until its own calibration seeds (BOOK-11 Ch. 6.3).

---

# Chapter 3 — Consolidation (M2 → M3)

The distillation pattern (R8, BOOK-11) run as governed missions:

1. **Trigger:** session close (light pass) + scheduled consolidation missions
   (nightly, cognitive-budget governed — BOOK-09 Ch. 6).
2. **Method:** extractive-first — prefer quoting the learner's own stated
   preferences/commitments over inferring; inferences carry
   `memory_type=summary` and confidence, and require ≥ 2 supporting episodes.
3. **Salience scoring:** initial salience from recency × emotional/stakes
   markers × repetition across episodes; decays (Ch. 6) unless re-retrieved
   (retrieval strengthens — the testing effect, applied to the machine).
4. **Supersession, not mutation:** a new fact contradicting an old one creates
   a superseding row linked to its predecessor (lineage preserved; the old row
   expires). The learner sees the current fact; the auditor can see the chain.
5. **Volume discipline:** per-twin M3 budgets (reference: ≤ 200 active rows);
   consolidation MUST compress (merge duplicates, expire trivia) — a memory
   that only grows is a surveillance file, not a mentor's understanding.

---

# Chapter 4 — Retrieval

1. **When:** Perceive phase assembles M3 (by salience × purpose relevance) and
   M2 search hits (if the trigger suggests history: "as we discussed…").
2. **Budget:** memory injection is part of the per-agent context budget
   (BOOK-06 §5.3); truncation markers apply; the trace records which memories
   were injected (explanations can cite them: "you told me you prefer
   worked examples").
3. **Scoping:** `agent_key`-scoped rows go only to their agent; shared rows to
   all entitled agents. Purpose relevance respects consent: with
   `ai_personalization=false`, M3/M2 retrieval returns nothing (BOOK-06 L7
   degradation) — the engine is politely amnesic.
4. **Cross-learner isolation (hard rule):** retrieval is twin-keyed at the
   storage layer. An agent serving learner A can never receive learner B's
   memories — enforced structurally (key prefixing + entitlement check), tested
   in the harness (BOOK-11 privacy scenarios). Cross-learner insight flows only
   through anonymized aggregates in the proper channels (QA reports, I2/I3
   analytics) — never through memory stores.

---

# Chapter 5 — Multi-Scope Memory

| Scope | Store binding | Notes |
|-------|--------------|-------|
| Learner (L7) | M2/M3 per twin | this Book's main subject |
| Faculty (F6) | M2/M3 per faculty twin | working-style memory (feedback phrasing, recurring decisions); same rules, employee-appropriate lawful basis (BOOK-07 Ch. 2) |
| Course | ⚠️ restricted | "what confuses students in lesson 3" is **QA knowledge**, not memory — it flows through Coach reports and analytics (anonymized, n≥10), never through memory stores |
| Institution | M4 only | the engine's procedural competence is the only legitimately institutional "memory" |

The course/institution rows exist to *prohibit* the tempting shortcut: agent
memory is personal and consent-bound; institutional learning is analytics and
QA, with their own governance. Mixing the channels is a conformance failure.

---

# Chapter 6 — Forgetting by Design

1. **Expiry classes** (defaults; per-institution calibration): interventions
   1 year · session summaries 2 years · preferences until superseded ·
   facts reviewed at lifecycle transitions (graduation prompts a consolidation
   review: what should the university still remember about an alumna?).
2. **Salience decay:** unretrieved rows decay toward expiry; retrieval
   refreshes. The mentor remembers what keeps mattering.
3. **Learner deletion (BOOK-06 Ch. 8.4):** any M3 row deletable directly,
   effective next assembly; M2 session summaries deletable on request
   (traces follow audit retention — BOOK-19 — but are excluded from retrieval
   once the learner deletes the summary: **audit ≠ memory**).
4. **Consent degradation:** `ai_personalization=false` freezes writes and
   blocks retrieval (data retained per retention class but inert); re-consent
   reactivates.
5. **Erasure:** twin erasure purges M2/M3 per BOOK-06 Ch. 9.3; M4 is untouched
   (contains nothing personal — Ch. 1.2); M1 is ephemeral by construction.
6. **Lifecycle-transition reviews:** at Graduate and Alumni transitions a
   consolidation review runs with the learner: shown their memory, invited to
   prune — the open-model principle applied to long-term relationship building.

---

# Chapter 7 — Privacy and Governance Summary

M2/M3 are *sensitive-learning* class (BOOK-04 Ch. 8): consent-gated
(`ai_personalization`), region-pinned, inspectable ("what the AI remembers about
me" — BOOK-06 Ch. 8.1), deletable, never verbatim transcripts, never protected
attributes, never third-party facts. Writers are audited; the consolidation
pipeline is a governed mission class; memory-related incidents (F6 leakage —
BOOK-11 Ch. 8) are Review-Board items. The scenario bank includes memory cases
(injection into memory, cross-learner leakage, deletion honored).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| M1 working | Redis + cycle runtime (STX-06) | ✅ | blackboard keying per BOOK-09 §5.3 already satisfied by STX-06's `synthesize_blackboard` — no NEW-03 work needed |
| M2 episodic | `ace_session_summaries` (NEW-03 ✅ 2026-07-18) — pgvector-indexed, **not Chroma**: no Chroma substrate exists anywhere in Turnkey (a prior version of this row's "chroma substrate present" was incorrect — the actual, established RAG convention is pgvector, `academic_embedding_service.py`); session-close + nightly consolidation missions | ✅ | rubric-quality drift on M2 content is a separate NEW-02-documented gap (trace doesn't persist response text) |
| M3 semantic | `TwinAIMemory` (constitution §4.3, STX-01) + `memory_write_service.py` (NEW-03 ✅ 2026-07-18) — episode citations required on every write, supersession lineage wired, rejection list (protected attributes, third-party facts) | ✅ | protected-attribute categories are this sprint's own policy list (GDPR + US classes) — the Book itself names only the generic category |
| M4 procedural | `ProceduralCalibrationState` (NEW-03 ✅ 2026-07-18) rolling up NEW-02's `CalibrationBaseline`; inherited-but-flagged on new releases | ✅ | outcome tracking (prediction vs. eventual result) is still the open BOOK-09 Ch. 7 gap NEW-02 already documented — this sprint only builds the inheritance/flagging mechanics |
| Consolidation | `consolidation_service.py` (NEW-03 ✅ 2026-07-18) — R8 extractive-first, salience scoring, volume-budget compression | ✅ | salience weights/coefficients are this sprint's policy choice (no formula given in the Book) |
| Retrieval scoping | Perceive-phase assembly (NEW-03 ✅ 2026-07-18) — salience × purpose relevance, M2 vector hits on history cues, per-agent budget + truncation marker, trace citation | ✅ | a genuine pre-existing gap found and fixed in this sprint: `TwinContextService._fetch_ai` never filtered by `agent_key` at all before NEW-03 — closed in the same change set |
| Deletion/inspection UX | `DELETE /api/twin/me/memory/{id}` (NEW-03 ✅ 2026-07-18, ownership-checked) + `/api/brain/memory` (STX-06, WS00 panel) | ✅ | the STX-06 `/api/brain/memory/{id}` route still has no ownership check — flagged as a follow-up hardening item, not fixed as a drive-by change in NEW-03 |
| Cross-learner isolation | tenant isolation ✅; twin-level key prefixing + entitlement check (NEW-03 ✅ 2026-07-18, fuzz-tested at the storage layer) | ✅ | — |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| M1–M4 | Working, episodic, semantic, procedural stores |
| Consolidation | Governed M2→M3 distillation: extractive-first, cited, salience-scored, compressive |
| Supersession | Contradiction handling: new row linked to predecessor, lineage kept |
| Salience decay | Unretrieved memories drift toward expiry; retrieval refreshes |
| Politely amnesic | Consent-degraded mode: memory inert, engine fully functional |
| Audit ≠ memory | Deleted-from-retrieval content may persist in audit trails without ever re-entering cognition |
| Memory budget | Per-twin cap on active semantic rows; consolidation must compress |

---

*BOOK-12 v1.0 — awaiting review. The AI spine (09–12) is complete; next per
dependency order: BOOK-13 (Academic Knowledge Network).*


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Adopt **Tutor Memory Semantics**: working / episodic / preference memory with salience and expiry; all memory access is tenant- and learner-authorised; retrieved content is data, not instructions.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
