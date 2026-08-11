# DLU — Integration Plan: DLU Architecture Suite (DAS v1.0) × DLU Architecture Standard (Masterbook) with EKG v1.1

> Critical analysis of the **DLU Architecture Suite** (the four-pillar EKG package: DKA/DSA/DXA/DPA) and the two attached blueprints
> (*EKG Ontology 1.0 — Technical Blueprint*, *EKG 1.1 — UI/UX Experience Design Reference Guide*), and a plan to **merge** the Suite into
> the **DLU Architecture Standard** (BOOK-00 … BOOK-20), evolving the current DLU Knowledge Graph (KG v1.0) into the **Educational
> Knowledge Graph (EKG) v1.1**.
> Companion deliverables (this change set): `dlu_builder_tk/docs/ER_MAP_TARGET.md`, `dlu_builder_tk/docs/BACKLOG_TARGET.md`,
> `dlu_builder_tk/docs/ALBERO_DI_FUNZIONALITA_TARGET.md`.
> Date: 8 August 2026.

---

## 0. Terminology — resolving the "DAS" collision

Two artefacts both abbreviate to **DAS**. This plan fixes the vocabulary:

| Term (this plan) | What it is | Location |
|------------------|-----------|----------|
| **DLU Architecture Suite** (the *Suite*) | The four-pillar EKG package v1.0 — DKA/DSA/DXA/DPA + executable contracts | `DLU_Architecture_Suite/` (external) |
| **DLU Architecture Standard** (the *Standard* / *Masterbook*) | The normative BOOK-00 … BOOK-20 | `dlu-architecture-standard/` |
| **Turnkey** | The running reference implementation | `dlu_builder_tk/` |

Recommendation (RFC-worthy): **retire "DAS" as an ambiguous acronym.** Use **"the Suite"** and **"the Standard"** in all cross-references, and keep "DAS-Core / DAS-Intelligent / DAS-Certified" strictly as the Standard's *conformance levels* (BOOK-00).

---

## 1. What the Suite is (critical read)

The Suite is a **mature, executable, EKG-centric architecture package** organised in four pillars, with governance (MANIFEST, TRACEABILITY, GOVERNANCE, ADR/EDR templates):

- **DKA — Knowledge Architecture.** The **EKG Ontology 1.0**: 8 semantic layers (Academic, Knowledge, Competency, Assessment, Learner, Career, AI, Governance), ~35 canonical node types, ~40 typed edges with cardinalities, a URI/identity/versioning policy, a confidence-aware **Bayesian mastery engine** (Beta posteriors; `w_e = quality·reliability·recency·authenticity`), graph governance and synthetic datasets (MSc AI). Ships `ekg-ontology.ttl`, `ekg-shacl.ttl`, JSON-LD context/sample.
- **DSA — Solution Architecture.** The **EKG 1.1 Production Architecture**: a **hybrid platform** — Frappe (transactional academic workflow + approvals), LMS/Moodle (delivery), **Neo4j 5.x** (semantic graph), **Kafka** (event backbone, transactional outbox), **n8n** (human-centric integration), **vector index** (GraphRAG), object storage (immutable evidence). 12 microservices (EKG API, Graph Projection, Ontology Registry, Mapping, Mastery, Learning Path, Credit Recognition, GraphRAG Orchestrator, Tutor, Evidence, Career/Gap, Audit). Executable contracts: `openapi.yaml`, `schema.graphql`, `asyncapi.yaml`, `event-envelope.schema.json`, `neo4j-bootstrap.cypher`, `reference-queries.cypher`, `frappe-doctypes.json`, `n8n-workflows.json`, `k8s-reference.yaml`. Includes a **migration EKG 1.0→1.1** and a **6-wave roadmap**.
- **DXA — Experience Architecture.** The **EKG UI/UX Reference Guide**: the **Lens** abstraction (a *governed projection contract*: Role × Intent × Scope × Projection × Depth × Actions × ACL), **progressive disclosure L0→L3**, the invariant **mastery ≠ confidence**, the **bounded local graph** (≤ 12–20 nodes, EDR-001), a Role×Intent×View matrix and visualization grammar, ~30 screen specs (stu/fac/dea/pro/xro), 10 AI-interaction patterns (AIP-01…10), Information Architecture, EDRs.
- **DPA — Product Architecture.** Capability map, product vision, workspace map, roadmap, product KPIs, Definition-of-Ready.

**Assessment — strengths.** The Suite is *more concrete and more standards-serious* than the Standard on three axes the Standard explicitly flagged as gaps: (1) a **formal, versioned ontology** with SHACL/JSON-LD/OWL; (2) an **executable event/API/graph contract set**; (3) a **first-class experience model** (Lens) that solves the "don't expose the graph" problem the Standard only gestures at. Its mastery mathematics and mapping-governance are production-grade.

**Assessment — gaps / risks.**
1. **Naming & scope overlap** with the Standard (the "DAS" collision, and "Academic GPS" vs "Learning Path Service", "ACE" vs "Tutor/GraphRAG Orchestrator").
2. **Source-of-truth stance** — the Suite makes **Frappe/ERPNext** the transactional owner; the Standard's ADR-0009 says the same, but Turnkey today owns records in PostgreSQL (`models_*`). This is the biggest brownfield reconciliation.
3. **Event backbone** — the Suite mandates **Kafka**; Turnkey uses Redis pub/sub + `EventService`/`kg_event_bus` + outbox (`event_outbox.py`). The Standard's ADR-0010 says "broker is swappable" — so this is a decision to formalise, not a conflict.
4. **Governance duplication** — the Suite has its own ADR/EDR registries and TRACEABILITY; these must be *folded into* the Standard's governance (BOOK-00 Ch.9, BOOK-19) rather than run in parallel.
5. **Two-tenancy models** — the Suite's Neo4j "shared DB + logical isolation (tenantId)" must be reconciled with Turnkey's PostgreSQL RLS + schema-per-tenant.

**Net position:** the Suite is not a competitor to the Standard — it is the **missing detailed specification for four Books** (03 AOS, 05 Ontology, 13 Knowledge Network, 15/16 Assessment/Credential) plus the experience layer (BOOK-17) and the AI layer (BOOK-09/10/11). The right move is **absorption**, per the Standard's own "source-of-content rule" (BOOK-00 Ch.16): systematise the running/spec'd system, don't re-invent it.

---

## 2. How the Suite maps onto the Standard (absorption map)

| Suite pillar / artefact | Absorbed into (Standard Book) | Conformance level |
|-------------------------|-------------------------------|-------------------|
| DKA — EKG Ontology 1.0 (nodes/edges, URI/versioning, SHACL/JSON-LD/OWL) | **BOOK-05** Academic Ontology & Semantic Model; registered in `architecture/ontology/dlu-core.yaml` | DAS-Core |
| DKA — Mastery engine (Bayesian, confidence) | **BOOK-13** Knowledge Network (mastery overlay) + **BOOK-15** (evidence) | DAS-Intelligent |
| DKA — Graph governance | **BOOK-19** Governance | DAS-Certified |
| DSA — EKG 1.1 Production Architecture (hybrid, microservices) | **BOOK-03** Academic Operating System + **BOOK-18** Technical/Turnkey integration | DAS-Core |
| DSA — Event backbone (Kafka, outbox, envelope) | **BOOK-03** (Event Mesh) — ADR-0010 formalised | DAS-Core |
| DSA — Source-of-truth & Frappe DocTypes | **BOOK-18** + ADR-0009 | DAS-Core |
| DSA — Mapping pipeline (CASE/ESCO/SFIA/DigComp/EQF) | **BOOK-05** + **BOOK-16** (portable credentials) | DAS-Intelligent |
| DSA — Learning Path Service | **BOOK-14** Academic GPS (deterministic path) | DAS-Intelligent |
| DSA — GraphRAG Orchestrator + Tutor | **BOOK-09** ACE + **BOOK-11** Cognitive Architecture | DAS-Intelligent |
| DSA — Credit Recognition | **BOOK-15/16** + Turnkey recognition domain | DAS-Intelligent |
| DSA — Evidence Service (append-only, hashed) | **BOOK-15** Assessment & Evidence | DAS-Certified |
| DXA — Lens abstraction + screens + AI patterns | **BOOK-17** Experiences (WS00–WS08) | DAS-Intelligent |
| DXA — EDR-001 bounded graph, EDR-002 mastery≠confidence | **BOOK-17** + design-system profile (Paper v3) | DAS-Intelligent |
| DPA — capability/workspace/roadmap/KPIs | **BOOK-02** University Theory + **BOOK-20** Blueprint; KPIs → BOOK-00 Ch.14 | — |
| Governance: MANIFEST/TRACEABILITY/ADR/EDR | **BOOK-00 Ch.9** + **BOOK-19**; TRACEABILITY merged into the Standard's `TRACEABILITY.md` | DAS-Certified |

**Engine-name reconciliation (normative once merged):**

| Suite name | Standard kernel engine | Decision |
|------------|------------------------|----------|
| Learning Path Service | **Academic GPS Engine** (BOOK-14) | GPS is the deterministic optimiser; keep GPS as canonical name; "Learning Path" is its output artefact. |
| GraphRAG Orchestrator + Tutor | **ACE** (BOOK-09) | ACE orchestrates; GraphRAG is ACE's retrieval pattern (BOOK-11). |
| Mastery Engine | **Knowledge + Competency Engines** overlay (BOOK-13/04) | Mastery observations/state live on the Knowledge Network. |
| Mapping Service | **Competency Engine + Ontology Registry** (BOOK-04/05) | MappingAssertion is the governance object. |
| EKG API / Graph Projection | **Event Mesh + Kernel API facade** (BOOK-03) | Experiences never touch Neo4j (matches kernel invariant #1). |

The mapping is clean: **the Suite is the concrete "how" for the Standard's abstract "what."** Where the Suite is more specific, it becomes the normative detail; where names differ, the Standard's kernel vocabulary wins (BOOK-00 glossary is normative).

---

## 3. From KG v1.0 (Turnkey today) to EKG v1.1 (target)

### 3.1 Where Turnkey is today
Turnkey's KG is **v1.0**: `knowledge_graphs`, `knowledge_graph_nodes`, `knowledge_graph_edges` (relational store synced to Neo4j), `kg_build/query/export` services, GraphRAG (`rag_service`), BKT mastery (`concept_mastery`, `mastery_events`, `mastery_tracking_service`), competencies (`competencies`, `competency_graph`, ILO/PLO/CLO/MLO in `models_institution`/`models_learning_outcomes`), ESCO (`esco_occupations`, `esco_occupation_skills`), student twin. Per BOOK-00 Annex A this is ✅ for KG v1.0 and 🔵 for "KG v1.2 competency + student overlay (STX-05)".

### 3.2 The v1.1 deltas (what actually changes)
Following the Suite's *Migration EKG 1.0→1.1* (§24) applied to Turnkey:

1. **Formal ontology & registry.** Adopt the 8-layer node/edge taxonomy as the canonical schema; stand up an **Ontology Registry** (versions, node/edge types, SHACL invariants) and register it in `dlu-core.yaml`. *Turnkey today has ad-hoc node/edge `type` strings — these become a governed, versioned taxonomy.*
2. **Temporal, provenance-aware mastery.** Split **observation** (immutable `MasteryObservation` — score, confidence, observedAt, sourceType, algorithmVersion, provenance) from **computed state** (`LearningState`). Keep **mastery ≠ confidence** end-to-end (Beta posteriors). *Replaces the collapsed BKT single-value state.*
3. **Governed external mappings.** Introduce **`MappingAssertion`** (mappingType exact/close/broad/narrow/related, confidence, reviewer, status) instead of uncontrolled `sameAs`. Frameworks (CASE/ESCO/SFIA/DigComp/EQF/Bloom) referenced by pinned version via **`FrameworkConcept`**. *Extends the current ESCO tables into a stewarded pipeline.*
4. **Source-of-truth + outbox.** Establish Frappe/LMS ownership per §5 and the **transactional outbox → event → Graph Projection** flow; forbid synchronous Neo4j writes from save hooks. *Formalises Turnkey's `event_outbox.py` + `kg_event_bus`; ADR-0010 fixes broker choice (Kafka target; Redis Streams acceptable interim).* 
5. **Policy-aware API facade.** No direct application Cypher from experiences; all reads via named/persisted queries with resolved `TenantContext`. *Matches kernel invariant #1.*
6. **Career & AI layers.** Add **JobRole / SkillRequirement / GapObservation / CareerPath** and **LearningPath / LearningPathStep / Recommendation / Agent** as first-class graph objects feeding GPS/ACE.
7. **Evidence & credentials as graph objects.** Append-only **Evidence** (hashed, provenance) → outcomes; **Credential** (Open Badges 3.0/CLR) per BOOK-16.
8. **Experience Lenses.** Deliver role read-models via **projection/view-model services**; the browser never computes mastery.

### 3.3 Compatibility strategy (brownfield-first)
- **Additive migrations only** (CLAUDE.md §8): new tables/columns; keep `knowledge_graph_*` as a **legacy projection** during shadow.
- **Shadow mode** for the mastery engine (Suite §24.8) — run Bayesian alongside BKT, compare on golden datasets before cutover.
- **Strangler pattern** for the API facade: new EKG endpoints proxy old routes; deprecate direct KG access route-by-route.
- **Broker**: run the outbox against Redis Streams first (no new infra), swap to Kafka at Wave-scale — contracts (`asyncapi.yaml`, envelope) are identical.

---

## 4. Impact on the Master Book (BOOK-00) and connected Books

### 4.1 BOOK-00 (Master Book) — changes
- **Ch.6 (AOS):** add the **hybrid platform** picture (Frappe/LMS/Neo4j/Kafka/vector/object) as the concrete AOS deployment; keep the ten-engine kernel; annotate Event Mesh with the outbox+envelope contract.
- **Ch.9 (ADRs):** promote **ADR-0009/0010/0013** from *Proposed* to *Accepted* (records in Frappe; outbox event backbone; governed gateway) — the Suite provides the evidence. Add **ADR-0014 "EKG is a platform subsystem, not a DB feature"** and **ADR-0015 "Experience Lens is a governed projection contract"** (absorbs EDR-001/002).
- **Ch.10 (Frameworks):** upgrade CASE/ESCO/SFIA/DigComp/EQF from "aligned" to **normative mapping pipeline** with `MappingAssertion` governance.
- **Ch.14 (Metrics):** add EKG SLOs (mastery event→state p95 < 15 s; tutor retrieval p95 < 2.5 s; GraphRAG grounding rate; mapping review backlog).
- **Glossary:** add EKG, Lens, MappingAssertion, MasteryObservation/LearningState, FrameworkConcept, Graph Projection; deprecate ambiguous "DAS".
- **Annex A:** flip several 🔵 to 🟡/✅ once Waves land; add the Suite as a normative input alongside the Turnkey constitution.

### 4.2 Connected Books — impact matrix

| Book | Impact | Absorbs from Suite |
|------|--------|--------------------|
| **01** Philosophy & Pedagogy | Low | mastery≠confidence as a pedagogical principle (open learner model) |
| **02** University Theory | Medium | DPA capability/workspace/KPI baseline; adoption archetypes |
| **03** Academic Operating System | **High — rewrite** | EKG 1.1 Production Architecture (microservices, deployment, SLOs, tenancy, event contracts) |
| **04** Academic Domain Model | **High** | node/edge taxonomy → aggregates; identity/versioning; consent |
| **05** Ontology & Semantic Model | **High — rewrite** | EKG Ontology 1.0 (TTL/SHACL/JSON-LD), URI policy, framework mapping |
| **06** Student Digital Twin | Medium | Learner/MasteryObservation/LearningState layers; read projection |
| **07** Faculty Digital Twin | Low-Med | Faculty Lens; delegation/authoring envelopes (AIP-08) |
| **08** Institution Digital Twin | Medium | Provost/Dean lenses; program-health/coverage projections |
| **09** ACE | **High** | GraphRAG Orchestrator + Tutor contract; retrieval policies |
| **10** AI Workforce | Medium | Agent node, delegated capability tokens, AI patterns catalog |
| **11** AI Cognitive Architecture | **High** | GraphRAG pipeline, grounding/eval harness, vector design |
| **12** Memory Architecture | Medium | vector/semantic memory design; retrieval traces |
| **13** Academic Knowledge Network | **High — rewrite** | Neo4j model, mastery overlay, invariants, analytics |
| **14** Academic GPS | **High** | Learning Path Engine objective/explanation |
| **15** Assessment & Evidence | **High** | Evidence pipeline, rubric/criterion/level, integrity, trust weights |
| **16** Credential & Trust | Medium-High | Credential graph object; credit-recognition workflow; VC/OB |
| **17** Experiences | **High — rewrite** | Lens contract, 30 screens, IA, AI patterns |
| **18** Technical/Turnkey | **High** | source-of-truth, Frappe DocTypes, k8s, CI/CD, migration |
| **19** Governance/Security/Compliance | **High** | tenancy controls, ACL/ABAC, mapping/mastery audit, DoD |
| **20** Implementation Blueprint | **High** | 6-wave roadmap → sprint packs; DoD for production readiness |

**Net:** 9 Books get **High** impact (four are effectively *rewritten from the Suite*), 6 Medium, 2 Low. No Book is contradicted; the Suite fills them in.

---

## 5. Integration roadmap (merged 6 waves ↔ Standard conformance ↔ Turnkey sprints)

| Wave | Scope (Suite §25) | Standard level | Turnkey sprint tag (proposed) | Key books |
|------|-------------------|----------------|-------------------------------|-----------|
| **W0 Foundations** | contracts, IDs, tenant context, Ontology Registry, Neo4j bootstrap, event envelope, outbox, CI invariants | DAS-Core | `EKG-W0-*` | 03, 04, 05, 18, 19 |
| **W1 Academic Graph** | Frappe/LMS projection, outcomes, concepts, assessments, accreditation queries | DAS-Core | `EKG-W1-*` | 05, 13, 15, 18 |
| **W2 Learner State** | Evidence Service, Mastery Engine (shadow→cutover), Student Workspace, Learning Path MVP | DAS-Intelligent | `EKG-W2-*` | 06, 13, 14, 15 |
| **W3 GraphRAG Tutor** | vector ingestion, policy-aware retrieval, grounded tutor, eval harness | DAS-Intelligent | `EKG-W3-*` | 09, 11, 12 |
| **W4 Career + Credit** | ESCO/CASE mapping stewardship, skill gap, career targets, credit recognition | DAS-Intelligent | `EKG-W4-*` | 04, 05, 16 |
| **W5 Hardening** | performance, DR, security, governance, observability, cost | DAS-Certified | `EKG-W5-*` | 19, 20 |

Aligns with the AVA accreditation work (`AVA_DM1154_2021_REQUIREMENTS.md`): the EKG's outcome/evidence/coverage graph is the substrate for the accreditation traceability and indicators — W1/W2 feed AVA Phase 1–2.

---

## 6. Decisions required (RFC list before merge)

1. **Retire "DAS" acronym**; adopt Suite/Standard vocabulary. *(BOOK-00 glossary)*
2. **Records in Frappe/ERPNext** (ADR-0009 → Accepted) vs. keep-in-Postgres interim; define the projection direction. *(BOOK-18)*
3. **Broker**: Kafka target, Redis Streams interim — same `asyncapi` contract. *(ADR-0010)*
4. **Neo4j tenancy**: shared-DB-logical default vs DB-per-tenant for regulated tenants; reconcile with PostgreSQL RLS. *(BOOK-19)*
5. **Ontology domain URI** (replace `dlu.example.org`) and registry ownership. *(BOOK-05)*
6. **Mastery cutover gate**: golden-dataset agreement + shadow duration. *(BOOK-13/15)*
7. **Lens catalog ownership** and ACL model source (RBAC+ABAC). *(BOOK-17/19)*

---

## 7. What ships in this change set

1. **This plan** — analysis + absorption map + book-impact + roadmap.
2. **`ER_MAP_TARGET.md`** — the target data model: the EKG graph schema (nodes/edges) **and** the relational tables Turnkey must add/evolve (registry, mapping assertions, temporal mastery, learning state, evidence, career, learning paths, outbox/projection), with Mermaid diagrams and a v1.0→v1.1 delta table.
3. **`BACKLOG_TARGET.md`** — the integration backlog: epics/stories per wave, with book impact, sprint tags, acceptance criteria and dependencies.
4. **`ALBERO_DI_FUNZIONALITA_TARGET.md`** — the target functionality tree: the current 18 areas evolved with EKG-native capabilities (Lenses, GraphRAG tutor, Bayesian mastery, mapping stewardship, career/gap, credit recognition, projection services, accreditation traceability).

---

*Methodological note: analysis for architecture-integration purposes. On any conflict, precedence is BOOK-00 (constitution) > Suite blueprints (detailed spec) > Turnkey `CLAUDE.md` (engineering guardrails); a true kernel-contract conflict is an RFC, not a judgment call (BOOK-00 Ch.9).*


---

## 8. Update 2026-08-08 — ATA 1.0 + Course Format v2.0

The Suite advanced to **v1.1** adding **ATA 1.0 (Adaptive Tutor Architecture)** as a cross-cutting slice (DKA/DXA/DSA/DPA), and the authoring artefact advanced to **Course Exchange Format v2.0**. Both are absorbed into the Standard:

- **ATA** = the concrete spec for the Standard's ACE tutoring (BOOK-09/11) + Student Twin (BOOK-06) + Memory (BOOK-12) + Knowledge overlay (BOOK-13), governed by BOOK-19. It adds an EKG extension (11 nodes/12 edges), a **versioned Pedagogical Policy Engine** (NBLA), a stateless Tutor platform, and an evaluation/rollout pipeline. New ADR-0016/0018.
- **Course Format v2.0** becomes the authoritative EKG projection source (ADR-0017); v1.3 via adapter; Course Builder v2.0 validates graph invariants at export.

Full per-Book impact, ADRs and connected-doc updates are in `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md`. Implementation sprints: `../dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` (W1-07 Course Format v2.0; W3-ATA-06…10 Adaptive Tutor).
