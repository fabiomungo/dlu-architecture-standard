# BOOK-13 — Academic Knowledge Network
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The foundational substrate. Manifesto principle #4 — *knowledge is
> interconnected* — is not a slogan: it is a graph, and everything intelligent
> in DLU stands on it. Content is authored against it, curricula traverse it,
> mastery attaches to it, the GPS plans over it, GraphRAG retrieves through it,
> gaps are computed on it, and the learner *sees themselves* in it (the Personal
> Knowledge Graph). This Book specifies the Academic Knowledge Network (AKN) as
> **one graph with three planes**, its v2.0 schema, its supply chain, its query
> and analytics contracts, and the closure of anomaly A1.
>
> **Conforms to:** BOOK-00 v2.0 (ADR-0003). **Depends on:** BOOK-05 (ontology —
> the AKN is its physical realization). **Informs:** BOOK-06 (L4), BOOK-11
> (R2), BOOK-14 (GPS — its primary computational client), BOOK-15 (evidence
> mapping).
> **Primary audience:** graph engineers, architects, AI engineers.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** built
on the running Neo4j 5 + APOC deployment, `kg_build/query/export/nlp_extractor`
services, `graph_sync_service_pi1`, `kg_event_bus`, GraphRAG, the ontology
hygiene service, `academic_embedding_service` and the vector-index retrieval
pattern (`concept_embeddings`) already in the Turnkey conventions.

---

# Chapter 1 — One Graph, Three Planes

| Plane | Contains | Tenancy | Volatility |
|-------|----------|---------|-----------|
| **P-DEF — Definition** | Concepts, Skills, Competencies, Outcomes, frameworks, prerequisite structure (`PREREQUISITE_FOR`, `DEPENDS_ON`, `UNDERPINS`, `COMPONENT_OF`) | shareable across tenants per sharing policy (Ch. 9) | slow — governed by ontology/curriculum change |
| **P-CUR — Curriculum** | Programs, Courses, Modules, Lessons, Assessments, MediaAssets and their traversal of P-DEF (`COVERS`, `DEVELOPS`, `ASSESSES`, `ALIGNED_TO`, `NEEDS_ASSET`) | tenant-scoped (institution's offering) | medium — authoring cadence |
| **P-LRN — Learner** | Student overlay: `KNOWS {p_mastery}`, `EVIDENCES {confidence,status}` | strictly tenant + twin scoped | fast — per attempt |

The planes are labels-and-policy, not separate databases: one Neo4j graph,
traversable across planes in a single query — that is the whole point (a gap
query touches all three in four hops).

**Foundational invariants:**

1. The AKN is the **only** authoritative store of semantic structure (A1 closed
   — Ch. 10); PostgreSQL keeps system-of-record *facts*, the graph keeps
   *structure and connection*.
2. The graph is **derived and rebuildable**: every node/relationship traces to
   a PG aggregate (`pg_id`) or a governed import; total loss of Neo4j is an
   outage, never data loss (Ch. 8.4).
3. Everything on P-LRN is *sensitive-learning* class; everything on P-DEF is an
   institutional asset with IP standing (Ch. 9.3).

---

# Chapter 2 — Physical Architecture

- **Engine:** Neo4j 5 (Community in reference deployment) + APOC; GDS for
  analytics (Ch. 7) where licensed — analytics degrade gracefully without it.
- **Join discipline:** every node carries `pg_id`, `schema_version`, timestamps;
  `(label, pg_id)` uniqueness constraints (running convention).
- **Embeddings in-graph:** `Concept.embedding` with the `concept_embeddings`
  vector index (running pattern) — vector search and traversal in one engine is
  what makes hybrid retrieval (R2) a two-step, not a federation problem.
  Embedding versions follow BOOK-11 Ch. 3.5 (reindex = release).
- **Tenancy:** P-LRN nodes/rels carry `tenant_id`, always filtered (BOOK-03
  Ch. 5); P-CUR carries `tenant_id`; P-DEF carries `sharing_scope`
  (`global | consortium | tenant`) — Ch. 9.

---

# Chapter 3 — Schema v2.0 (consolidated)

The BOOK-05 registries are the source of truth; this chapter binds them to the
graph with properties and constraints. Migration path: v1.0 (running) → v1.2
(constitution overlay) → **v2.0** (BOOK-05 renames + new relations), idempotent
Cypher under `scripts/kg/`, alias window one minor release (A8/A9 aliases:
`REQUIRES→NEEDS_ASSET`, `ALIGNS_TO/MAPS_TO→ALIGNED_TO`).

**Node registry (v2.0):**

| Label | Plane | Key properties |
|-------|-------|----------------|
| `Concept` | DEF | pg_id, name, domain, embedding, sharing_scope |
| `Skill` | DEF | pg_id, name, esco_uri |
| `Competency` | DEF | pg_id, code, framework, level, external_uri |
| `Outcome` (`:ILO/:PLO/:CLO/:MLO/:LessonOutcome` sub-labels) | DEF/CUR | pg_id, bloom_level, code |
| `Program`, `Course`, `Module`, `Lesson` | CUR | pg_id, tenant_id, status |
| `Assessment` | CUR | pg_id, assessment_type, bloom_profile |
| `MediaAsset` | CUR | pg_id, asset_type, provenance (model, fingerprint) |
| `Credential` | CUR | pg_id, credential_type, standard |
| `Student` | LRN | twin_id, tenant_id |

**Relationship registry:** the BOOK-05 Ch. 5.3 closed set, verbatim — with the
three properties classes that carry semantics: `strength`
(I/R/M on `ALIGNED_TO`, weight on `DEVELOPS`/`ASSESSES`), mastery state
(`p_mastery`, `updated_at` on `KNOWS`), evidence state (`confidence`, `status`
on `EVIDENCES`).

Constraints: uniqueness per (label, pg_id); existence checks on tenant_id for
CUR/LRN labels; relationship property types validated at write (consumer-side —
Neo4j Community lacks rel constraints; the write services are the enforcement
point).

---

# Chapter 4 — The Knowledge Supply Chain

How structure enters the graph — five sources, one hygiene gate, one promotion
door:

```text
① Outcome-first authoring (Builder/FEX)   → CLO/MLO, Module/Lesson, ALIGNED_TO, planned ASSESSES
② AI generation (Course Factory)          → Lessons, COVERS candidates, NEEDS_ASSET
③ NLP extraction (legacy import, RAG docs)→ PG staging (loose vocabulary)
④ Framework imports (CASE/ESCO)           → Competency/Skill nodes, crosswalks (SKOS)
⑤ Faculty curation                        → corrections, SAME_AS confirmations, prerequisite edits
                    │
        [ HYGIENE GATE — ontology service ]
        duplicate detection · SAME_AS proposals (HITL above threshold)
        · orphan checks · Bloom-verb lint · promotion mapping (BOOK-05 §5.4)
                    │
        [ PROMOTION — kg_build_service ]
        staging vocabulary → L1 terms · pg_id minted · provenance stamped
```

Rules:

1. Only the promotion door writes P-DEF from extraction (③); direct staging →
   graph writes are prohibited (A1 discipline).
2. Every promoted element carries provenance (`source: fex|factory|extraction|
   case|faculty`, job/import id) — the graph is auditable like everything else.
3. Faculty curation (⑤) is authoritative over AI proposals (②③): a confirmed
   `SAME_AS` or a prerequisite correction survives re-imports (curation flags
   are sticky).
4. Hygiene KPIs feed the knowledge-economy indicators (BOOK-08 I3): duplicate
   rate, orphan rate, unresolved SAME_AS queue.

---

# Chapter 5 — The Learner Plane (Personal Knowledge Graph)

P-LRN is the graph form of Twin L4 (BOOK-06):

- **Writers:** kg-sync consumers only (`mastery.updated` → `KNOWS`;
  `competency.updated` → `EVIDENCES`), batched (reference: 100 events / 5 s
  window) — never inline in API requests (BOOK-03 §3.3).
- **Rendering contract (WS03):** the Personal Knowledge Map renders the
  learner's neighborhood: concepts colored by P(L), frontier highlighted
  (prerequisite-satisfied, unmastered — *"ready to learn"*), gap paths toward
  targeted competencies. Every visual state is explainable (BOOK-06 Ch. 8:
  mastery cites evidence counts).
- **Privacy:** overlay queries are twin-scoped by construction; aggregate
  views (e.g., "class heatmap" for faculty) come from analytics with n≥10
  suppression (BOOK-08), never from raw overlay traversals.
- **Erasure:** overlay deletion is part of twin erasure (BOOK-06 Ch. 9.3).

---

# Chapter 6 — Query Contracts

`kg_query_service` is the single query facade (no ad-hoc Cypher from feature
code). The three retrieval patterns of the Turnkey conventions are elevated to
contracts:

| Pattern | Contract | Budget |
|---------|----------|--------|
| Q1 Vector | `concept_embeddings` top-K, score floor | p95 < 150 ms |
| Q2 Traversal | bounded-depth typed traversals (max 4 hops default) | p95 < 300 ms |
| Q3 Hybrid | Q1 seeds → Q2 expansion → grounded context (feeds R2) | p95 < 500 ms |

**Canonical query library** (versioned with the schema; the GPS and gap
queries are already constitutional):

- `frontier(twin)` — prerequisite-satisfied unmastered concepts (the "next"
  set for recommendations stage-1);
- `gap(twin, competency|credential)` — BOOK-05-corrected form of the
  constitution §6.4 query (via `DEVELOPS`/`EVIDENCES`);
- `prereq_chain(concept|course)` — `PREREQUISITE_FOR` closure (A8 canonical);
- `coverage(program)` — outcome/concept coverage for I2 and the Coach;
- `cross_course(concept)` — `SAME_AS` neighborhoods for cross-disciplinary
  navigation;
- `asset_needs(module)` — `NEEDS_ASSET` fulfillment state for the media
  pipeline.

Failure semantics: the facade inherits fire-and-forget on writes and **degrade-
to-empty on reads** for non-critical callers (a recommendation slate without KG
enrichment is poorer, not broken) — critical callers (GPS) surface staleness
explicitly instead.

---

# Chapter 7 — Graph Analytics

Scheduled GDS (or APOC-approximated) jobs whose outputs are **QA and planning
inputs**, never direct learner-facing decisions:

| Analytic | Output → consumer |
|----------|-------------------|
| Betweenness/centrality on P-DEF | bottleneck prerequisite concepts → curriculum review (a single concept gating 40% of a program is a design smell) |
| Community detection on COVERS/PREREQUISITE_FOR | module coherence check → Coach ("lesson 7 belongs to another module's cluster") |
| Orphan/reachability scans | concepts covered by nothing, outcomes assessed by nothing → I3 knowledge indicators |
| Path statistics (length/branching toward credentials) | GPS heuristics calibration (BOOK-14) |
| Cross-tenant concept overlap (consortium scope) | federation catalog candidates (P08) |

Analytics jobs run off-peak, versioned, with results stamped `computed_at` and
schema_version — reproducibility discipline as everywhere.

---

# Chapter 8 — Sync, Consistency, Rebuild

1. **Definition/curriculum sync:** event-driven handlers
   (`graph_sync_service_pi1` extended per v2.0); fire-and-forget + try/except —
   a Neo4j outage never fails an API call (running rule).
2. **Learner sync:** batched consumers (Ch. 5); consumer lag is an I4 metric.
3. **Drift detection:** nightly reconciliation samples PG aggregates vs graph
   projections (counts, checksums per label); drift beyond threshold triggers
   targeted resync; persistent drift pages platform ops.
4. **Rebuild capability (normative):** `make kg-rebuild` — full reconstruction
   from PG + import provenance + event log, idempotent, tenant-scopeable.
   Rebuild time is a measured DR metric. This is what "derived and rebuildable"
   (Ch. 1) means operationally.

---

# Chapter 9 — Sharing, Federation, and Knowledge IP

1. **Sharing scopes on P-DEF:** `tenant` (default) · `consortium` (shared with
   named partners — policy objects, BOOK-02 Ch. 10) · `global` (platform
   commons, e.g., ESCO-derived skills). Sharing a concept shares *structure*,
   never P-CUR content or P-LRN overlays.
2. **Cross-disciplinary linking** (running P1-S8 work): `SAME_AS` across
   domains within a tenant; across tenants only at consortium scope with
   curation on both sides.
3. **Knowledge IP:** P-DEF structure authored by an institution is an asset
   (licensable to partners — BOOK-02 revenue line); provenance stamps (Ch. 4)
   are what make licensing auditable. Framework-derived nodes (ESCO/CASE)
   carry their upstream licenses.
4. **Federated exchange** (P08): catalog/competency exchange uses CASE + the
   FEX, not raw graph dumps — the graph is an internal representation; the
   standards are the wire format (BOOK-05 Ch. 7).

---

# Chapter 10 — A1 Sunset Plan (PG staging tables)

| Phase | Action | Exit criterion |
|-------|--------|----------------|
| S1 (now) | staging demoted to extraction-only (BOOK-05 §5.4); no new readers — enforced at review | zero product-feature reads (grep-audit clean) |
| S2 | promotion pipeline is the sole consumer; staging rows get TTL after promotion | promotion provenance complete |
| S3 | staging moves to import-job-scoped temporary storage; `knowledge_graphs/nodes/edges` tables frozen | one release with zero writes |
| S4 | tables dropped **by explicit governance approval** (the one sanctioned exception to additive-only, per CLAUDE.md rule requiring approval) | archive exported; migration + rollback tested |

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Engine + schema v2.0 | Neo4j 5 + APOC; `v2_0_semantic_cleanup.cypher` — **delivered STX-05 (2026-07-16)** (A8/A9 aliases flagged, one-release window) | ✅ | alias removal at v2.1 🟡 |
| Build/promotion | `kg_build_service`, `kg_nlp_extractor`, legacy import | ✅ | promotion-door enforcement (A1 S1) 🔵 |
| Hygiene | ontology service (same_as, duplicates, auto-link) | ✅ | HITL thresholds + sticky curation flags 🟡 |
| Query facade | `kg_query_service`, GraphRAG + `frontier`/`gap` canonical forms — **STX-05, wired into a real caller STX-09 (2026-07-21):** `recommendation_service_v2.py`'s stage-1 candidate generation is the first production caller of either method — both existed since STX-05 but were dead code until this sprint; also adds `find_concept_by_name` (catalog-wide, non-twin-scoped concept lookup — Discovery's `explain_concept` grounding source, K2 debt) | ✅ | remaining canonical forms (prereq_chain, coverage, asset_needs) + budget probes 🟡 |
| Learner plane | BKT ✅; `kg_overlay_sync` batched consumers (KNOWS/EVIDENCES, DEFER-flush, tenant-scoped) — **delivered STX-05** | ✅ | **WS03 rendering ✅ STX-09 (2026-07-21)** — `KnowledgeMapWorkspace.js`, a lighter twin-level view (today's recommendation slate + L3 competency state + contest affordance), not the full mastery-colored/frontier-highlighted graph rendering contract Ch. 5 describes — that fuller visualization (vis-network, frontier/gap KG paths surfaced visually) remains a follow-up, honestly scoped out this sprint |
| Sync | `graph_sync_service_pi1` (+Competency/Framework definition tier), `kg_event_bus`, fire-and-forget; batched overlay consumers + `dlu_event_group_lag` metric — **STX-03/05** | ✅ | nightly drift reconciliation (automatic) still ⚪ — `kg-rebuild` itself (manual, on-demand full reconstruction) is ✅, see Drift/rebuild row |
| Embeddings | `academic_embedding_service` + vector index pattern | ✅ | version governance 🟡 |
| Analytics | GDS referenced; curriculum mapping (P1-S9), cross-disciplinary (P1-S8) | 🟡 | scheduled job suite + I3 feeds ⚪ |
| Drift/rebuild | export service; `make kg-rebuild` / `scripts/dr/kg_rebuild.py` — **✅ delivered NEW-15 (2026-08-02)**: enumerates courses (optionally `--tenant`-scoped), `kg_build_service.delete_graph` + `.build_full_graph` per course, timed through the existing `record_kg_build` histogram, verified idempotent and tenant-scoped | 🟡 | this is a manual, human-triggered DR drill (BOOK-20 Ch.7 framing — Neo4j here holds course/concept ontology, not twin-owned data), not an automatic drift-reconciliation job — that (scheduled detection + repair) remains ⚪ |
| Sharing scopes | federation core (PI-5) | 🟡 | `sharing_scope` property + consortium policy ⚪ |
| A1 sunset | S1 CI gate `check_kg_staging_reads.sh` (no new staging readers; legacy readers frozen in allowlist) — **delivered STX-05** | 🟡 | S2–S4 (reader migration, promotion-only writes, table removal) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| AKN | The Academic Knowledge Network — one graph, three planes |
| P-DEF / P-CUR / P-LRN | Definition, curriculum and learner planes |
| Frontier | Prerequisite-satisfied, unmastered concept set — "ready to learn" |
| Promotion door | The single sanctioned path from extraction staging into P-DEF |
| Sticky curation | Faculty corrections that survive re-imports |
| Sharing scope | P-DEF visibility class: tenant, consortium, global |
| Rebuildable | The graph reconstructs fully from PG + provenance + events |

---

*BOOK-13 v1.0 — awaiting review. Next per dependency order: BOOK-14 (Academic
Intelligence Navigator — the GPS, the AKN's primary computational client).*
