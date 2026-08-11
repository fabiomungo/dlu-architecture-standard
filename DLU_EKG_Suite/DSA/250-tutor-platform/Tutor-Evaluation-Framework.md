# Tutor Evaluation Framework — ATA 1.0

## Evaluation layers

### Response quality
Grounding, correctness, pedagogical policy compliance, clarity, safety, citation integrity.

### Learning effectiveness
Immediate learning gain, delayed retention, transfer to novel items, goal progress, remediation success.

### System performance
P50/P95 latency, token cost/session, graph retrieval latency, policy decision latency, fallback rate.

### Fairness & robustness
Outcome gaps by authorized evaluation cohorts, differential recommendation rates, accessibility success, language quality, drift.

## Experiment unit
Default experimentation unit is learner or course section, not individual message, to reduce treatment contamination.

## Minimum release gates
- No regression in grounding/correctness.
- Statistically and educationally meaningful learning effect for policy changes claiming improvement.
- No material increase in high-risk or ungrounded responses.
- Approved academic owner and rollback plan.

## Observability IDs
Every turn carries `sessionId`, `turnId`, `policyVersion`, `modelRoute`, `contextPackId`, `interventionId`, `correlationId`.
