# ADR-0016 — Pedagogy is explicit and versioned; the Policy Engine chooses, the LLM renders

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Supersedes: none · Related: ADR-0001 (AOS), ADR-0018 (tutor state external), BOOK-09, BOOK-09A, BOOK-11, BOOK-19
Source: DLU Architecture Suite — ATA 1.0 (`DLU_EKG_Suite/ATA/`, `DSA/250-tutor-platform/Tutor-Policy-Engine.md`)

## Context

The Adaptive Tutor (ATA 1.0) must personalise teaching at scale. The naïve approach — letting a large language model decide *both* the pedagogy and the wording of every turn — is unsafe and unauditable: pedagogy becomes implicit, non-reproducible, impossible to evaluate offline, and optimises for whatever the model finds fluent (often engagement) rather than durable learning. Education is an EU-AI-Act Annex III high-risk domain; steering of learning must be explainable, governed and reversible.

## Options considered

1. **LLM owns pedagogy** (prompt-only tutor). Fast to build; no explicit strategy; not reproducible; cannot be offline-evaluated or rolled back; fails governance.
2. **Static rules only.** Deterministic and auditable but rigid; cannot improve from evidence; no principled personalisation.
3. **Explicit, versioned Pedagogical Policy Engine that selects the Next-Best-Learning-Action (NBLA); the LLM only renders the chosen strategy.** Auditable, reproducible, offline-evaluable, improvable under governance. (Chosen.)

## Decision

- A dedicated **Pedagogical Policy Engine** selects the **NBLA** from an explicit strategy set (EXPLAIN, SIMPLIFY, ELABORATE, SCAFFOLD, SOCRATIC_QUESTION, WORKED_EXAMPLE, HINT, PRACTICE, REVIEW_PREREQUISITE, REMEDIATE, CHALLENGE, REFLECT, ASSESS, REASSESS). The **LLM realises** the intervention *within* the selected strategy and constraints; a generated answer **MUST NOT** silently change the selected strategy.
- The decision uses a **versioned scoring function** `Score(a)=Σ wᵢ·featureᵢ − penalties` over `{studentState, activeGoal, targetConcept, prerequisiteReadiness, recentInterventions, assessmentEvidence, constraints}`. Weights are **policy-versioned**, observable and configurable per program/tenant within governance bounds.
- The optimisation target is **learning gain and retention**, never engagement alone (illustrative reward: learning-gain 40% · retention 20% · goal 15% · assessment 10% · engagement 10% · satisfaction 5%).
- **`PolicyVersion` is a first-class, immutable, auditable entity** (same immutable-by-version pattern as `ItemCalibrationParams`/`mastery_model_params`). Every intervention records the `policyVersion` that generated it (`GENERATED_BY_POLICY`).
- **Policy evolution is gated:** V1 rules+expert weights → V1.5 offline counterfactual evaluation + calibrated propensity logging → V2 contextual bandit for eligible low-risk choices → RL **only** after governance approval with a **constrained action space**.
- **Production policy changes follow a controlled rollout:** Draft → simulation → shadow → A/B/interleaving → academic review → approved → canary → production → monitor → rollback. Release gates: no grounding/correctness regression; statistically *and* educationally meaningful effect for any improvement claim; no material increase in high-risk/ungrounded responses; named academic owner + rollback plan.
- Every recommendation **MUST** be explainable from goal, knowledge state and graph dependencies.

## Consequences

**Positive:** auditable and reproducible pedagogy; safe offline evaluation before any learner sees a change; principled personalisation; clean separation of concerns (policy vs rendering); AI-Act/BOOK-19 alignment.
**Costs/risks:** more moving parts (Policy Engine, evaluation harness, policy registry); requires disciplined feature/telemetry logging; weight calibration needs labelled data; teams must resist "just prompt it" shortcuts.
**Enforcement:** CI/GA gate rejects a tutor path where the LLM overrides the selected strategy or where a policy change lacks an offline-evaluation record; `policyVersion` is required on every intervention.

## Related artifacts

`BOOK-09A-Adaptive-Tutor-v1.0.md`; `DLU_EKG_Suite/ATA/DSA/250-tutor-platform/Tutor-Policy-Engine.md`, `Tutor-Evaluation-Framework.md`; skill `ekg-tutor`; sprints `EKG-W3-08` (Policy Engine), `EKG-W3-10` (Evaluation) in `dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md`.
