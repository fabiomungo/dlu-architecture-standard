# ADR-ATA-001 — Stateless Tutor Runtime

**Status:** Accepted

## Decision
Tutor compute workers are stateless. Student state, goals, mastery, memory and evidence are stored in dedicated persistent services. A request can be served by any healthy Tutor worker.

## Consequences
Horizontal scaling and failover are straightforward; all personalization contracts must therefore be retrievable by ID and protected by consistent tenant/learner ACL. Session-local caches are disposable.
