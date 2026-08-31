# Tutor Platform Architecture — ATA 1.0

## Runtime model
Tutor workers are stateless and horizontally scalable. Persistent state lives in EKG/mastery, memory and event stores.

```text
Client -> API Gateway -> Tutor Orchestrator
                         |-- Student Model Service
                         |-- Goal Service
                         |-- Pedagogical Policy Engine
                         |-- GraphRAG Service -> Neo4j + Vector Store
                         |-- Memory Service
                         |-- LLM Gateway
                         |-- Tutor Evaluation Service
                         `-- Event Bus
```

## Services

| Service | Responsibility | Owns canonical data? |
|---|---|---|
| Tutor Orchestrator | session lifecycle and workflow | session metadata only |
| Student Model Service | materialized learning twin | no; derived from evidence/mastery/goals |
| Goal Service | learner/program/career goals | yes for learning goals |
| Pedagogical Policy Engine | choose NBLA/strategy | policy definitions + decisions |
| GraphRAG Service | graph-aware retrieval | no |
| Memory Service | working/episodic/preference memory | yes for memory artifacts |
| Mastery Engine | update mastery/confidence | mastery observations |
| Tutor Evaluation Service | intervention/outcome analytics | evaluation facts |
| LLM Gateway | model routing, cost, guardrails | no learner state |

## Scaling
- Session affinity is optional; state is external.
- Orchestrator and GraphRAG autoscale independently.
- Cache immutable curriculum subgraphs and short-lived student projections.
- Batch non-urgent mastery recomputation and cohort analytics.
- Use tenant-scoped rate limits and model budgets.

## Availability
If policy or GraphRAG is degraded, Tutor falls back to course-grounded non-adaptive assistance and labels personalization as temporarily unavailable.
