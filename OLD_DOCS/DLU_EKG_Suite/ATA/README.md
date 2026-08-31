# ATA 1.0 — Adaptive Tutor Architecture

**Status:** Baseline 1.0  
**Scope:** Cross-cutting architecture slice across DKA, DXA, DSA and DPA  
**Purpose:** Define how DLU delivers a scalable adaptive tutor that personalizes teaching from the student's knowledge state, goals and evidence, while improving its pedagogical policy through controlled learning loops.

## Core principle

The Tutor does **not** continuously retrain the LLM on each learner. It continuously updates the **Student Learning Digital Twin** and improves a versioned **Pedagogical Policy** using measured learning outcomes.

`Student State + Goal + EKG + Evidence + Pedagogical Policy -> Next Best Learning Action -> Tutor Intervention -> Outcome -> State Update`

## Architecture map

| Domain | Question answered | ATA artefacts |
|---|---|---|
| DKA | What does the Tutor know? | Student Learning Digital Twin, pedagogical ontology, learning goals, evidence, misconception model, memory semantics |
| DXA | How does the learner experience adaptation? | Tutor session, diagnosis, hints, remediation, explain-why, adaptive difficulty, learning plan |
| DSA | How is it implemented and scaled? | Tutor Orchestrator, Policy Engine, Student Model Service, Memory, GraphRAG, events, APIs, evaluation pipeline |
| DPA | What product capabilities are delivered? | Adaptive Tutor, Diagnostic Tutor, Socratic Tutor, Practice Tutor, Learning Advisor; roadmap and KPIs |

## Non-negotiable design decisions

1. Tutor runtime is stateless; learner state is persisted externally.
2. Mastery and confidence are separate measures.
3. A conversational turn may create an informal signal; only qualified evidence updates high-stakes mastery.
4. Pedagogical strategy is explicit and versioned; the LLM does not autonomously own pedagogy.
5. Tutor optimization targets learning gain and retention, not engagement alone.
6. Production policy changes require offline evaluation and controlled rollout.
7. Every recommendation must be explainable from goal, knowledge state and graph dependencies.
8. All retrieval and memory access is tenant- and learner-authorized.

## Navigation

### DKA
- `DKA/600-adaptive-tutor/Student-Learning-Digital-Twin.md`
- `DKA/600-adaptive-tutor/Pedagogical-Ontology.md`
- `DKA/600-adaptive-tutor/Tutor-Memory-Semantics.md`
- `DKA/600-adaptive-tutor/Learning-Evidence-and-Misconceptions.md`
- `DKA/600-adaptive-tutor/ATA-EKG-Extension.md`

### DXA
- `DXA/400-ai-patterns/AIP-11-socratic-dialogue.md`
- `DXA/400-ai-patterns/AIP-12-hint-ladder.md`
- `DXA/400-ai-patterns/AIP-13-remediation.md`
- `DXA/400-ai-patterns/AIP-14-adaptive-difficulty.md`
- `DXA/400-ai-patterns/AIP-15-tutor-diagnostic.md`
- `DXA/400-ai-patterns/AIP-16-explain-why-next-action.md`
- `DXA/300-screens/stu_13-tutor-session.md`
- `DXA/300-screens/stu_14-learning-diagnosis.md`
- `DXA/300-screens/stu_15-personal-learning-plan.md`

### DSA
- `DSA/250-tutor-platform/Tutor-Platform-Architecture.md`
- `DSA/250-tutor-platform/Tutor-Policy-Engine.md`
- `DSA/250-tutor-platform/Tutor-Memory-Architecture.md`
- `DSA/250-tutor-platform/Tutor-Evaluation-Framework.md`
- `DSA/250-tutor-platform/Tutor-Sequence-Diagrams.md`
- `DSA/300-apis/tutor-openapi.yaml`
- `DSA/300-apis/tutor-schema.graphql`
- `DSA/400-events/tutor-asyncapi.yaml`
- `DSA/400-events/tutor-event-envelope.schema.json`

### DPA
- `DPA/200-capabilities/Adaptive-Tutor-Capability.md`
- `DPA/500-roadmap/Adaptive-Tutor-Roadmap.md`
- `DPA/700-kpis/Adaptive-Tutor-KPIs.md`

## Reference lifecycle

`Expert policy -> Instrumented pilot -> Evidence collection -> Offline policy evaluation -> Controlled experiment -> Approved policy version -> Production rollout -> Monitoring`
