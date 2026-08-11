# ADR-0019 — The EKG is a platform subsystem, not a database feature

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Related: ADR-0001 (AOS), ADR-0009 (records in ERP), ADR-0010 (event backbone), ADR-0020 (Lens), BOOK-03, BOOK-05, BOOK-13, BOOK-18, BOOK-19
Source: DLU Architecture Suite — EKG 1.1 Production Architecture (`DLU_EKG_Suite/DSA/100-context/EKG-1.1-Production-Architecture.md`, §29)
Note: replaces the earlier working reference to "ADR-0014" for this decision (0014 is already assigned to identity-reconciliation).

## Context

The Educational Knowledge Graph is easy to mistake for "a Neo4j database we query." Treated that way it becomes a second source of truth, accrues ad-hoc Cypher from every service and UI, drifts from the transactional systems, and cannot be governed, versioned or evaluated. EKG 1.1 promotes the graph from a data model to a **production platform capability** — the machine-understandable contract connecting curriculum, outcomes, concepts, skills, assessments, evidence, mastery, career and AI reasoning.

## Options considered

1. **EKG = a database.** Services and UIs query Neo4j directly. Minimal upfront work; uncontrolled Cypher, tenant-leak risk, no source-of-truth discipline, unversioned schema. Rejected.
2. **EKG = an analytics mirror.** Read-only reporting copy. Loses the adaptive/tutoring/path use cases that need the graph as a live contract. Rejected.
3. **EKG = a platform subsystem.** Canonical ontology + source-of-truth ownership + event contracts + projection services + policy-aware API facade + mastery mathematics + authorization + GraphRAG + explainable services. (Chosen.)

## Decision

- The EKG is a **subsystem**, not a DB feature. Its product is the combination of: a **canonical, versioned ontology** (Ontology Registry, SHACL/JSON-LD/OWL); **source-of-truth ownership** (authoritative system per entity — Frappe/LMS/registry — ADR-0009); **event-first integration** (transactional outbox → Graph Projection; no direct cross-system DB writes — ADR-0010); a **policy-aware API facade** (named/parameterized queries with a resolved `TenantContext`; **no raw/client Cypher**); the **mastery engine** (confidence-aware, mastery ≠ confidence); **tenant isolation by design** (`tenantId` on every tenant-owned node; `scope='GLOBAL'` taxonomy); **GraphRAG** (graph + vector); and **explainability** (paths + provenance).
- **Neo4j is a component, not the product.** RDF/OWL is the interchange/publication layer; JSON-LD is the API/event payload; PostgreSQL holds only service operational data (idempotency, outbox, registry, projection checkpoints), never a second semantic graph.
- **Ontology and contracts are versioned products.** Each schema change carries semantic-version classification, migration, SHACL/graph-invariant tests and contract tests; breaking changes require a new API/event major version or a compatibility adapter.
- **Experiences never own academic state.** They read via the facade and mutate via kernel services/events (BOOK-00 kernel invariant #1); all model calls go through the governed gateway (ADR-0013).

## Consequences

**Positive:** governance, versioning, tenant safety, explainability and evolvability of the graph; no drift between transactional systems and the graph; the graph becomes the substrate for tutoring (BOOK-09A), GPS (BOOK-14), assessment/evidence (BOOK-15) and accreditation traceability (BOOK-26).
**Costs/risks:** more infrastructure (registry, projection service, facade, event backbone) and discipline (no shortcut Cypher). Brownfield reconciliation with Turnkey's PostgreSQL RLS/schema-per-tenant is required (see `DAS_EKG_INTEGRATION_PLAN.md`).
**Enforcement:** CI scans reject client/UI/save-hook Cypher and unscoped tenant queries; ontology changes fail the build without a registry entry + invariant tests; `EKG-W0-*` sprints implement registry, bootstrap, outbox, projection, facade and CI invariants.

## Related artifacts

`DAS_EKG_INTEGRATION_PLAN.md`, `ER_MAP_TARGET.md`; skill `ekg-graph`; sprints `EKG-W0-01…06`.
