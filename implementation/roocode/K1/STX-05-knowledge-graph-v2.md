# Sprint STX-05 — Knowledge Graph v2.0 + Student Overlay + Ontology Registry
### DAS K1 · self-contained prompt · target: `dlu_builder_tk` (+ registry in `dlu-architecture-standard`) · depends: STX-03, STX-04

> **STATUS: ✅ DONE 2026-07-16** — V1–V7 green (live-Neo4j idempotency/
> parity/tenant-fuzz; 250-events→≤3-flushes batching; CI gates negative-
> tested) · `KNOWLEDGE_GRAPH_SCHEMA.md` → v2.0 + alias-window note ·
> `dlu-core.yaml` seeded + lint in both repos' CI · BOOK-05/13 Annex rows ✅
> · TRACEABILITY: A1-S1 ✅, A8 ✅, A9 ✅ · **K1 complete — assemble
> `K1-EXIT-REPORT.md` (pack README) before requesting K2 prompts.**

## Role
`backend-dev` + `ontology-specialist` review, implementing graph schema v2.0
(DAS BOOK-05 Ch. 5–6, BOOK-13; anomaly closures A1-S1, A8, A9).

## Context
1. BOOK-05 §5.2 (renames), §5.3 (canonical relationship registry), §5.4
   (staging promotion mapping), Ch. 6 (binding rules); BOOK-13 Ch. 3
   (node registry v2.0), Ch. 5 (overlay), Ch. 8 (sync rules).
2. Existing: Neo4j v1.0 schema (`docs/KNOWLEDGE_GRAPH_SCHEMA.md` — labels
   Institution…MediaAsset; rels incl. `PREREQUISITE_FOR`, `ALIGNS_TO`,
   `MAPS_TO`, `REQUIRES` Concept→MediaAsset), `graph_sync_service_pi1.py`,
   `kg_query_service.py`, `neo4j_client.py`, fire-and-forget convention
   (CLAUDE.md §7.3), STX-03 consumer framework, STX-04 events.
3. **A8/A9 are binding**: prerequisite stays `PREREQUISITE_FOR`;
   `REQUIRES` → `NEEDS_ASSET`; `ALIGNS_TO`/`MAPS_TO` → `ALIGNED_TO {strength}`.
   Aliases live exactly one minor release.

## Deliverables
1. **Cypher migration** `scripts/kg/v2_0_semantic_cleanup.cypher` —
   idempotent (safe to run twice): uniqueness constraints for new labels
   (`Competency`, `Skill`, `Credential`, `Student` on `(label, pg_id|twin_id)`);
   rename `REQUIRES`→`NEEDS_ASSET` (copy+delete, alias view note);
   normalize alignment rels to `ALIGNED_TO` with `strength` (map existing
   values; keep old rel names as duplicates flagged `alias:true` for the
   window); `schema_version` property stamped. `make kg-migrate` target added.
2. **Definition-tier sync**: extend `graph_sync_service_pi1.py` with handlers
   for Competency/CompetencyFramework CRUD (from STX-04 events via `kg-sync`
   consumer group) — fire-and-forget + try/except preserved.
3. **Student overlay consumers** (`kg-sync` group, STX-03 framework):
   `mastery.updated` → `(:Student {twin_id, tenant_id})-[:KNOWS {p_mastery,
   updated_at}]->(:Concept)`; `competency.updated/mastered` →
   `[:EVIDENCES {confidence, status, updated_at}]`. **Batched** (100 events /
   5 s window, flush on either), tenant_id on every overlay element, MERGE
   semantics (idempotent — required by V2 of STX-03).
4. **Staging S1 (A1)**: CI grep gate script `scripts/ci/check_kg_staging_reads.sh`
   failing on any non-promotion-pipeline import of
   `KnowledgeGraph|KnowledgeGraphNode|KnowledgeGraphEdge` from product code
   (allowlist: `kg_build_service`, `kg_nlp_extractor`, migrations, tests);
   wire into CI config.
5. **Ontology registry seed**:
   `dlu-architecture-standard/architecture/ontology/dlu-core.yaml` — classes
   (BOOK-05 §3.2), relationships (§5.3 table verbatim: name, domain, range,
   properties, status incl. `alias` entries), deprecated synonyms; plus
   validator `scripts/ci/lint_ontology.py` (checks migration Cypher and
   `event_taxonomy.py` nouns against the registry) wired into both repos' CI.
6. **Query facade additions** to `kg_query_service.py`: `frontier(twin_id)`,
   `gap(twin_id, competency_id)` (BOOK-13 Ch. 6 canonical forms, tenant-
   filtered, bounded depth), used-by tests.

## Verifications
- **V1 idempotency**: `make kg-migrate` twice → identical constraint/rel
  counts (assert via post-migration Cypher counts).
- **V2 aliases**: queries via old and new names return identical result sets
  during the window (parity test on fixture graph).
- **V3 tenant fuzz**: overlay queries with mismatched tenant_id return empty
  (property-based test over random tenants).
- **V4 fire-and-forget**: with Neo4j container stopped, definition-tier API
  mutations still return 2xx; sync resumes and reconciles on restart
  (integration test, `kg_integration` marker).
- **V5 registry lint**: introducing an unregistered label in a scratch Cypher
  file fails `lint_ontology.py` (negative test); taxonomy nouns pass.
- **V6 batching**: 250 mastery events → ≤ 3 overlay flushes (batch window
  test); consumer idempotent on redelivery.
- **V7 staging gate**: adding a dummy product-code import of staging models
  fails CI script (negative test), allowlisted paths pass.

## DoD
V1–V7 green · `KNOWLEDGE_GRAPH_SCHEMA.md` updated to v2.0 (+alias window
note) · BOOK-05/13 Annex rows updated · A1-S1 marked done in TRACEABILITY ·
K1 exit report can now be assembled (see pack README).
