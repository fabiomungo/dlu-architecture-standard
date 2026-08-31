# ADR-0018 — Tutor state is external; the Tutor runtime is stateless; a turn is an informal signal

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Related: ADR-0016 (pedagogy versioned), BOOK-06, BOOK-09A, BOOK-12, BOOK-13, BOOK-15, BOOK-19
Source: DLU Architecture Suite — ATA 1.0 (`Tutor-Platform-Architecture.md`, `Tutor-Memory-Architecture.md`, `Learning-Evidence-and-Misconceptions.md`)

## Context

An adaptive tutor must scale horizontally, survive worker restarts, respect privacy, and never quietly corrupt the academic record from casual chat. Two anti-patterns must be prevented: (a) keeping learner state inside the tutor worker/LLM context (unscalable, unauditable, leaky), and (b) letting a conversational turn update high-stakes mastery as if it were graded evidence.

## Options considered

1. **Stateful tutor workers** (session state in memory / long LLM context). Simple demo; breaks on scale/restart; hard to isolate per tenant; privacy risk.
2. **Turn == evidence** (every chat exchange updates assessed mastery). Fast signal but pollutes the record; unfair; violates assessment integrity.
3. **Stateless runtime with externalised state; turns are informal signals; only qualified evidence updates high-stakes mastery.** (Chosen.)

## Decision

- **Stateless Tutor runtime.** Tutor workers hold no durable learner state; persistent state lives in the **EKG + Mastery service** (learning state), **Memory service** (working/episodic/preference), and **Goal service**. Session affinity is optional; the Student Model Service materialises a derived read model.
- **Externalised, authorised memory.** Working memory is short-lived; episodic memory is vector-indexed **only after ACL tagging**; preference memory is learner-editable. Every retrieval requires `tenantId, studentId, purpose, role, retentionClass` and is **policy-filtered before ranking**. Raw tutor messages are **not** auto-promoted to durable memory — a memory-extraction step proposes an item; schema/ACL/confidence/retention are validated before persistence. Retrieved content is treated as **data, not instructions** (prompt-injection defence).
- **Evidence tiers.** `QualifiedEvidence` (graded/rubric-scored/authenticated) may update assessed mastery with normal weight; `TutorEvidence` (tutor micro-assessment, with evaluator model/version + rubric + confidence) is **weight-capped unless validated**; `InformalSignal` (hesitation, explanation quality, repeated error) drives **diagnosis and intervention planning only** and **never** directly updates high-stakes mastery. `effectiveWeight = baseWeight × reliability × authenticity × recency × difficultyCalibration`. **TutorEvidence cannot override authoritative grades.**
- **Mastery ≠ confidence** everywhere; missing data falls back to prior, never "fail". Misconceptions are **probabilistic hypotheses** ("It looks like…") re-evaluated after remediation, never asserted as fact at low confidence.
- **Deletion/rectification:** a preference correction invalidates derived preference embeddings; an evidence correction follows academic-record governance and produces a **new version** rather than a silent overwrite.
- **Degraded mode:** if Policy/GraphRAG is degraded, the Tutor falls back to course-grounded, non-adaptive assistance and labels personalisation temporarily unavailable.

## Consequences

**Positive:** horizontal scale + resilience; strong tenant/learner isolation and privacy; assessment integrity preserved; clean separation of "chat signal" from "record".
**Costs/risks:** requires an external state/memory tier and a memory-extraction/validation step; more services to operate; teams must resist promoting chat to evidence for convenience.
**Enforcement:** static/integration tests assert no learner state in the runtime; two-tenant + adversarial-id memory tests; a check that `TutorEvidence`/`InformalSignal` never writes assessed mastery; audit records effective tenant + policy decision per turn (`sessionId, turnId, policyVersion, modelRoute, contextPackId, interventionId, correlationId`).

## Related artifacts

`BOOK-09A-Adaptive-Tutor-v1.0.md`, `BOOK-12`, `BOOK-15`; `DLU_EKG_Suite/ATA/DSA/250-tutor-platform/*`; skill `ekg-tutor`; sprints `EKG-W3-07` (Student Model), `EKG-W3-09` (Memory), `EKG-W3-10` (Orchestrator/Evaluation).
