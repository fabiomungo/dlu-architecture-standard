# DLU EKG — the 10 knowledge-graph lifecycle questions, answered

> Answers to the standard KG-engineering lifecycle (Ontotext/GraphWise framing) applied to the **DLU Educational Knowledge Graph (EKG v1.1 + ATA 1.0)**.
> Grounded in: EKG Ontology 1.0, EKG 1.1 Production Architecture, mastery engine, DXA Lens guide, ATA, and the Turnkey integration artefacts
> (`DAS_EKG_INTEGRATION_PLAN.md`, `ER_MAP_TARGET.md`, `BOOK-05/09A/13/15`, `DLU_Course_Exchange_Format_v2.0.md`).
> **Honest framing note:** the source questions assume an RDF/GraphDB/SPARQL stack. DLU runs a **hybrid**: Neo4j 5.x is the *operational* graph; RDF/OWL/SHACL + JSON-LD are the *interchange/validation/publication* layer; a vector index powers semantic search. Where that diverges from the GraphDB-native answer, it is flagged.

---

## 1. Clarify business & expert requirements
**Goal:** make curriculum, learning outcomes, knowledge dependencies, skills, assessments, evidence, mastery and career requirements **machine-understandable in one semantic backbone**, so the platform can answer, at any moment, the **Seven Canonical Questions** (BOOK-00): *who is the learner · what do they really know · where do they want to go · what is the optimal path · what next · why is this appropriate · how does it serve long-term goals.*
**Questions the EKG must answer:** adaptive next-best-action & tutoring (ATA); deterministic learning-path/GPS; skill-gap vs a target job role; credit recognition; accreditation traceability (Program→CLO→MLO→Lesson→Assessment→Evidence, feeds DM1154/AVA); curriculum coverage/duplication for deans; institutional attainment for provosts.
**Experts/stakeholders & their intents:** Student (orientation/action), Faculty (outcome health/intervention), Dean (curriculum coverage), Provost (institutional KPIs), MappingSteward, CreditOfficer, Auditor. **Every kernel capability MUST map to ≥1 canonical question; nothing that serves none belongs in the kernel.**
**Success = falsifiable metrics** (BOOK-00 Ch.14): competency growth, mastery durability, recommendation efficacy, 100% explanation-trace coverage, tutor learning-gain/retention — *engagement is never the north-star.*

## 2. Gather & analyze relevant data
**Proprietary (source-of-truth per entity):** authored courses via **Course Exchange Format v2.0** (Course→Module→Lesson→Resource, CLO/MLO, concepts, skills, assessments); Frappe/ERPNext academic records & approvals; LMS/Moodle delivery + activity; **xAPI/Caliper** streams; assessment **evidence** artefacts (object store); ESSE3/SIS careers & CFU; existing Turnkey KG v1.0 + BKT mastery.
**Open/commercial taxonomies (referenced, pinned, never copied as truth):** **ESCO v1.2.1** (skills/occupations, URI-addressable), **SFIA** (7 responsibility levels), **DigComp 2.2**, **EQF** (levels), **Bloom** (cognitive), **1EdTech CASE 1.1** (framework interchange). Synthetic **MSc-AI** dataset for testing.
**Analysis axes:** domain (higher-ed academic), scope (per-tenant + a shared `scope='GLOBAL'` taxonomy), provenance (authoritative owner per entity — §5 of the Production Architecture), maintenance (external frameworks pinned by version; refreshed under stewardship).

## 3. Clean data to ensure quality
- **Authoring-time validation** (Course Builder v2.0 export): JSON-Schema + **graph invariants** — every MLO `CONTRIBUTES_TO` ≥1 CLO; every published outcome assessed-or-waived; `PREREQUISITE_OF` is a **DAG** (cycles rejected); rubric criterion ≥2 levels; approved mapping pinned. A release failing a blocking rule cannot reach a gate.
- **Type hygiene:** replace free-string node/edge `type` with the **closed ontology taxonomy** (registry) — the single biggest v1.0→v1.1 clean-up.
- **Evidence quality:** append-only, **hashed + provenance**; corrections **supersede** (never edit history); evaluator type explicit (human/deterministic/AI).
- **Mastery hygiene:** split **observation** (immutable, temporal) from **computed state**; keep **mastery ≠ confidence**; missing data → prior, never "fail".
- **Tenant hygiene:** `tenantId` mandatory on tenant-owned nodes; global nodes carry no learner data; adversarial two-tenant tests.

## 4. Create the semantic data model
- **Canonical ontology = EKG Ontology 1.0**: 8 layers (Academic, Knowledge, Competency, Assessment, Learner, Career, AI, Governance), ~**35 node types / ~40 typed edges** with cardinalities, plus the **ATA extension** (11 nodes / 12 edges: LearningGoal, TutorSession/Turn, LearningIntervention, Misconception, PolicyVersion, …).
- **Formalisation:** OWL/Turtle (`ekg-ontology.ttl`) publishes class/property semantics; **SHACL** (`ekg-shacl.ttl`) validates instances; **JSON-LD** context is the API/event payload; SKOS/schema.org reused for labels/definitions.
- **Reuse vs engineer:** external frameworks are **not** the internal source of truth — DLU keeps canonical URIs and wraps external concepts as `FrameworkConcept`; equivalence is a **`MappingAssertion`** (governed), never `owl:sameAs` inline.
- **Governance of the model itself:** an **Ontology Registry** (`ekg_ontology_versions/node_types/edge_types/shacl_shapes`) with a strict **URI/identity/versioning policy** (opaque IDs, status draft→approved→retired; breaking change = new version). *(EKG-W0-01)*

## 5. Integrate — ETL vs virtualization
DLU is **event-first, not batch-ETL**: an authoritative mutation writes a business record **and** an outbox row in the same transaction → a **CloudEvents-style event** (`event-envelope.schema.json`) → a **Graph Projection service** idempotently upserts Neo4j. **No direct cross-system DB writes**; synchronous Neo4j writes from save-hooks are prohibited. JSON-LD is the payload; Course files project to the academic/knowledge/assessment layers (EKG-W1-02/03/04).
**Virtualization/NoETL side:** a **policy-aware API facade** (REST + GraphQL) exposes graph projections via named/persisted queries with a resolved `TenantContext` — **no client Cypher**; RDF/JSON-LD export serves external interoperability. Semantic metadata (registry + provenance) makes data discoverable and re-projectable. *(EKG-W0-03/04/05, W0-08 broker)*

## 6. Harmonize — reconciliation, fusion, alignment
- **Alignment (taxonomy mapping):** the **Mapping Stewardship** pipeline — candidate generation (lexical + embedding + graph rerank), confidence bands (≥0.92 high / 0.78–0.92 review / <0.78 hidden), relations `exactMatch/closeMatch/broadMatch/narrowMatch/relatedMatch`, lifecycle `Suggested→Approved/Rejected/Deprecated`, full provenance. Only **Approved** mappings are canonical. *(EKG-W4-01/02)*
- **Reconciliation (entity resolution):** cross-source matching by **canonical IDs**, not titles; a shared **global taxonomy** is referenced by all tenants; a tenant customisation **never mutates a global node** — it creates a tenant node + extension/mapping relation.
- **Fusion:** mastery fuses multiple evidence types (`effectiveWeight = base·reliability·authenticity·recency·difficulty`); **credit recognition** fuses source outcomes→CLO/MLO/concept coverage + level + evidence quality + policy into a decision with graph provenance. *(EKG-W4-03/04)*

## 7. Architect the data-management & search layer *(DLU divergence from GraphDB)*
- **Operational store:** **Neo4j 5.x** (traversals, path explanations, constraints, Cypher) — *not GraphDB*. Constraints/indexes bootstrapped; tenancy = **shared-DB + logical isolation (`tenantId`)** by default, **DB-per-tenant** for regulated tenants.
- **Semantics enforcement:** SHACL shapes + **CI graph-invariant tests** + application-layer validation (rather than an OWL-DL reasoner). RDF/OWL remains the interchange/publication layer.
- **Search:** a **vector index** (GraphRAG) holds embeddings of resources/outcomes/concepts/approved labels — the DLU analogue of "sync to Elasticsearch"; optional full-text graph search; the facade composes graph + vector.
- **Scale:** stateless services autoscale; cache immutable curriculum subgraphs + short-lived learner projections; SLOs (read p95 <500 ms, mastery event→state p95 <15 s, tutor retrieval p95 <2.5 s). *(EKG-W0-02, W5-02/03)*

## 8. Augment — reasoning, analytics, text
- **Inference:** Bayesian **mastery propagation** (concept→MLO→CLO→skill, prereq caps); **confidence-sensitive skill-gap** `E=M·(γ+(1−γ)C)`; deterministic **path optimization** (GPS `utility=gapCoverage·expectedGain·confidenceNeed·relevance − timePenalty − redundancy`); **misconception** hypotheses (ATA).
- **Graph analytics:** coverage matrices, prerequisite-integrity, **duplication/orphan** detection, cross-course similarity, centrality for gap priority, accreditation coverage/traceability.
- **Text analysis / entity extraction:** NLP concept extraction from learning resources (`kg_nlp_extractor`) feeds concepts/relations; **GraphRAG** grounds tutoring in graph facts + provenance; tutor turns emit `TutorEvidence` (informal signal). Result: the graph holds **more than the sum of its sources**, better interconnected. *(EKG-W2, W3, W3-ATA)*

## 9. Maximize usability — knowledge discovery + FAIR
- **Delivery surfaces:** governed **GraphQL/REST** facade; **RDF/JSON-LD export** (and SPARQL over the RDF projection) for external interoperability; **semantic/vector search**; role **Lenses** (Student/Faculty/Dean/Provost) with **progressive disclosure L0→L3**, coverage matrices, **explainability drawer**, knowledge explorer, faceted search — *table before graph; bounded local graph only when topology answers the question* (ADR-0020).
- **FAIR:** **Findable** (stable URIs, Ontology Registry, semantic metadata); **Accessible** (governed API + RBAC/ABAC, ACL reflected in every projection); **Interoperable** (RDF/OWL/JSON-LD, 1EdTech xAPI/Caliper/CASE/Open Badges, ESCO/EQF); **Reusable** (provenance, versioning, licence on resources, immutable evidence). *(BOOK-17, EKG-W5-01)*

## 10. Make the KG easy to maintain & evolve
- **Schema evolution:** semver-classified ontology changes → migration + SHACL/graph-invariant tests + contract tests; breaking change = new API/event major or a compatibility adapter. *(BOOK-05, EKG-W0-06)*
- **Continuous ingestion:** idempotent, **replay-safe** outbox→projection; `mastery.updated`/`tutor.*` events rebuild read models; scheduled **standards sync** (n8n) pulls ESCO/CASE updates into staging for **steward review** (never silent overwrite).
- **Governance:** Architecture Board + ADR/RFC lifecycle; **Mapping Stewardship**; **PolicyVersion** governance for the Adaptive Tutor (offline eval → controlled rollout → rollback, ADR-0016). 
- **Operate:** OTel observability (graph/vector/LLM latency, projection failures, **mapping-review backlog**, DLQ depth, drift/subgroup monitors); production **Definition of Done** (restore drill, tenant-isolation pen-test, grounding benchmark). 
- **Sync duty (BOOK-00):** any kernel-contract change updates the Standard, the relevant Book Annex and TRACEABILITY **in the same change set** — silent divergence is a conformance failure. *(EKG-W5-04/05)*

---

### One-line summary
DLU treats the EKG as a **governed platform subsystem** (ADR-0019): a canonical, versioned ontology (RDF/OWL/SHACL, Neo4j-operational + vector search), fed **event-first** from authoritative sources, **harmonised** with external frameworks only through stewarded `MappingAssertion`s, **augmented** by Bayesian mastery, GPS and GraphRAG, exposed through **role Lenses and FAIR APIs**, and **kept alive** by registry versioning, continuous idempotent ingestion, stewardship and observability.
