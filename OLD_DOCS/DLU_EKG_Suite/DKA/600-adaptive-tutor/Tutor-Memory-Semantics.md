# Tutor Memory Semantics — ATA 1.0

## Memory classes

| Memory | Lifetime | Source | Use |
|---|---|---|---|
| Working Memory | one session | current dialogue/context | coherence |
| Episodic Memory | selected episodes | intervention/outcome summaries | avoid repetition, continuity |
| Learning State Memory | durable | EKG/mastery/evidence | adaptation and planning |
| Preference Memory | durable, user-controlled | learner choice/observed preference | presentation style |

## Rules
- Never use raw conversation history as the canonical mastery state.
- Store compact episode summaries rather than unlimited transcripts for adaptive retrieval.
- Every memory item carries `tenantId`, `studentId`, `source`, `createdAt`, `retentionClass`, `confidence`.
- High-risk or sensitive inference is excluded from pedagogical memory unless explicitly supported by governance.
- Learners can inspect and correct preference memory and learning goals.

## Retrieval priority
1. Current learning state and active goal
2. Current session working memory
3. Relevant recent episode summaries
4. Preference memory
5. General cohort/policy statistics (never personal data from other learners)
