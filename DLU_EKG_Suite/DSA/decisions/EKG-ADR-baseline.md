# ADR Summary

## ADR-001 Canonical ontology vs external standards
DLU EKG is canonical. CASE/ESCO/SFIA/DigComp/EQF are versioned external mappings. Rationale: preserve internal stability and auditability.

## ADR-002 Source-of-truth split
Frappe owns academic administration and approval workflow; LMS owns activity delivery; object storage owns immutable evidence artifacts; Neo4j owns semantic relationships and computed graph projections. No dual-write without transactional outbox.

## ADR-003 Multi-tenancy
Default: shared production graph database with mandatory tenantId on every tenant-scoped node/relationship plus repository-enforced tenant predicates and ABAC. High-regulation tenants may use database-per-tenant. Shared global taxonomy can be a separate read-only database/composite graph.

## ADR-004 Events
CloudEvents-style envelope over Kafka. Producers use idempotence; workflows that update DB + Kafka use transactional outbox / CDC. Consumers are idempotent using event id.

## ADR-005 GraphRAG
Hybrid retrieval: authorization filter -> graph seed resolution -> bounded subgraph expansion -> vector/full-text retrieval -> rerank -> policy filter -> context pack -> LLM -> grounded citations.

## ADR-006 n8n boundary
n8n orchestrates human/system workflows, scheduled syncs, notifications and low-risk integration glue. It is not the system of record, mastery engine, authorization engine or high-volume event processor.
