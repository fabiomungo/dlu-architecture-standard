# Tutor Memory Architecture — ATA 1.0

## Stores
- Working memory: short-lived session store (Redis-compatible).
- Episodic memory: compact event/summary store, vector-indexed only after ACL tagging.
- Learning state: EKG + mastery service.
- Preference memory: profile service, learner-editable.

## Retrieval filter
Every query requires `tenantId`, `studentId`, purpose, role and retention class. Retrieval is policy-filtered before ranking.

## Write policy
Raw Tutor messages are not automatically promoted to durable memory. A memory extraction step proposes an item; schema, ACL, confidence and retention policy are validated before persistence.

## Deletion/rectification
A learner preference correction invalidates derived preference embeddings. Learning evidence correction follows academic record governance and produces a new version rather than silent overwrite where audit is required.
