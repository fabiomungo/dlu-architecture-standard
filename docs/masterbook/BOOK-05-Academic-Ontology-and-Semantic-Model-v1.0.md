# BOOK-05 — Academic Ontology & Semantic Model
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The semantic contract of the AOS. One vocabulary, three consumers: **humans**
> (documents, UIs, governance), **code** (models, graph, events, APIs) and
> **AI agents** (prompt vocabulary, explanation language). This Book defines the
> DLU-Core ontology, binds it to the knowledge graph schema, aligns it to external
> frameworks (ESCO, CASE, EQF, SKOS) and — as its central duty — **closes the
> semantic anomalies** declared in BOOK-04 Ch. 9, plus two new ones found during
> the census of the running graph schema (A8, A9).
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-04. **Binding for:**
> BOOK-06 (twin vocabulary), BOOK-13 (graph schema), BOOK-09/10/11 (agent
> vocabulary), BOOK-16 (credential semantics).
> **Primary audience:** ontologists, architects, AI engineers.

**Normative language:** RFC 2119. **Source-of-content rule compliance:**
systematized from the running Neo4j schema v1.0 (`KNOWLEDGE_GRAPH_SCHEMA.md`),
the PG extraction vocabulary (`KnowledgeGraphNodeType/EdgeType`), the content
model (`ComponentType`, Section/Page/Component), the existing ontology service
(`/api/ontology`: same-as links, duplicate detection, auto-linking) and the CCP
standards models (`CASEFramework`, QTI, Caliper, `CourseAchievement`).

---

# Chapter 1 — Why the Ontology Is Load-Bearing

Three failure modes occur without a governed ontology, and all three are already
visible at the edges of the running system:

1. **Human drift** — the same concept named differently across documents
   (Academic Brain vs ACE; Navigator vs GPS) until teams argue about words.
2. **Code drift** — the same relation encoded twice with different names
   (`ALIGNS_TO` vs `MAPS_TO`), or one name meaning two things (`REQUIRES` — A8).
3. **AI drift** — agents explain decisions in vocabulary that matches neither the
   UI nor the data, destroying the explainability guarantee (ADR-0006): an
   explanation the learner cannot map to what they see is not an explanation.

Therefore: **the ontology is a kernel artifact.** Its registry (Ch. 8) is
versioned in this repository; every label, relationship, event noun and API
resource name MUST resolve to a term defined here.

---

# Chapter 2 — Ontology Architecture

Four layers, each importable without the ones above it:

| Layer | Content | Formalism |
|-------|---------|-----------|
| L0 — Upper alignment | identity, part-whole, temporal notions | OWL 2 / SKOS primitives (`skos:Concept`, `skos:broader`, mapping predicates) |
| L1 — **DLU-Core** | the academic classes and relations (Ch. 3–5) | this Book + machine-readable registry (Ch. 8) |
| L2 — Framework alignment | ESCO, CASE-imported frameworks, EQF, DigComp, SFIA crosswalks | SKOS mapping (`skos:exactMatch`, `closeMatch`, `broadMatch`) |
| L3 — Institutional extension | tenant-specific competencies, custom taxonomies | subclassing/instancing only — L3 MUST NOT redefine L1/L2 terms |

**URI strategy:** every L1 term has a stable URI `https://das.dlu.education/ontology/{Term}`;
every instance is addressable as `dlu:{tenant}/{class}/{pg_id}` (the graph's
`pg_id` property is the join key to PostgreSQL — already the running convention).
External alignments store the foreign URI (`esco_uri`, `case_uri`) on the
DLU-side entity, never replace the DLU identity.

---

# Chapter 3 — DLU-Core Classes

## 3.1 The semantic quadrangle (the four most-confused terms, fixed)

| Class | Definition | It is NOT | Kernel home |
|-------|------------|-----------|-------------|
| **Concept** | An atomic unit of *knowledge* in a discipline's structure; nodes of the knowledge graph; carries prerequisite relations and per-learner mastery P(L) | a capability; a curriculum promise | Knowledge Engine (C7 overlay, C5 extraction) |
| **Skill** | An atomic, transferable *ability*, preferably ESCO-grounded (`esco_uri`); finer-grained than a competency | a concept (skills are performed, concepts are known) | Competency Engine (L2-aligned) |
| **Competency** | A framework-levelled *capability in context* (EQF/ESCO/DigComp/SFIA/custom): cluster of skills + knowledge applied to a class of situations, with evidence-backed status per learner | a course grade; an outcome statement | Competency Engine |
| **Outcome** (ILO/PLO/CLO/MLO/Lesson) | A *curricular promise*: what a program/course/module intends learners to achieve, Bloom-levelled, assessable | the learner's actual state | Outcomes context (C4) |

Canonical relations among the four:

```text
Concept  —UNDERPINS→   Competency        (knowledge that a capability presupposes)
Skill    —COMPONENT_OF→ Competency       (abilities composing it)
Outcome  —DEVELOPS→    Competency        (the curricular promise targets a capability)
Outcome  —COVERS→      Concept           (what knowledge the outcome addresses)
```

The learner's actual state attaches to Concept (mastery) and Competency
(status + confidence) — **never to Outcome**, which is design-time. This is the
ontological restatement of BOOK-01's rule that promises and evidence must not be
conflated.

## 3.2 Full class registry (L1)

**Parties & structure:** Learner, FacultyMember, Institution, Campus, College,
School, Department, Program, AcademicTerm, TeachingSection, Cohort.
**Curriculum & content:** Course, Module, Lesson, LearningActivity, Section, Page,
Component, MediaAsset, CourseResource (Ch. 4 disambiguates).
**Intelligence:** Concept, Skill, Competency, Outcome (5 levels), Assessment,
EvidenceRecord, Credential, Badge, LearningMission, Recommendation, PathScenario,
DigitalTwin (Student/Faculty/Institution), Agent.
**Operations:** Tenant, Consent, DomainEvent, Proposal.

Every class carries: definition, owning engine, key family (BOOK-04 Ch. 6),
graph label (if graphed), and deprecated synonyms — in the machine-readable
registry (Ch. 8). New classes require an RFC.

---

# Chapter 4 — Content Structure Ontology (resolves A4, clarifies A3)

The census found overlapping content containers. The resolution is that there are
**two orthogonal hierarchies plus one design-time lineage**, and every code entity
belongs to exactly one:

## 4.1 Pedagogical hierarchy (what is taught)

```text
Program → Course → Module → Lesson → LearningActivity
```

- **Module** — curriculum unit; carrier of MLOs; graph label `:Module`.
- **Lesson** — the pedagogical delivery unit; carrier of lesson outcomes and
  concept coverage (`COVERS`); graph label `:Lesson`.
- **LearningActivity** — the atomic learner-facing act (read, watch, quiz item,
  lab step); the unit xAPI statements refer to.

## 4.2 Presentational hierarchy (how it is laid out)

```text
Course → Section → Page → Component
```

- **Section/Page** — layout containers, no pedagogical semantics of their own.
- **Component** — presentation atom, typed by `ComponentType` (text, image, video,
  audio, quiz, assignment, embed, file, callout, flashcard, glossary, code, lab,
  diagram, simulation).

## 4.3 The binding

- A Lesson **renders as** one or more Pages; a LearningActivity **renders as**
  one or more Components. The mapping is `RENDERED_BY` (pedagogical → presentational)
  and it is many-to-many but total: presentational nodes with no pedagogical
  parent are decoration and MUST NOT carry outcomes, concepts or evidence.
- Assessment-bearing components (quiz, lab, assignment) are simultaneously
  LearningActivities — the evidence pipeline attaches there, never to Pages.
- **A4 resolution:** `Lesson` (pedagogical) and `Section/Page` (presentational)
  are different classes in different hierarchies; the code's parallel existence is
  correct — what was missing was the declared semantics and the totality rule.
- **A3 semantic note:** `ModuleBlueprint`/`AcademicOffering` are **design-time
  intent** (authoring lineage: `GENERATED_FROM`), not a third runtime hierarchy;
  `TenantCourse` is a projection with no independent semantics (BOOK-04).

## 4.4 Course Exchange Format binding (FEX v1.3 — resolves A10/A11/A12)

The **DLU Course Exchange Format** (`*.dlu.json`, `format_version: 1.3` — the
running Turnkey format, authored through the teacher-facing **DLU Course Builder**
wizard) is the portable serialization of a course design. It is the primary
instrument of **teacher activity**: a 9-step guided flow (info → CLOs →
bibliography/grading → policies → sections+MLOs → pages/components → final exam →
author) that produces one reviewable, re-editable file. Its semantic binding to
the ontology is normative:

| FEX element | Ontology binding | Notes |
|-------------|------------------|-------|
| `course` (identity, level, audience, credits, prerequisites, delivery_mode) | `Course` | free-text prerequisites map to `PREREQUISITE_FOR` (Course→Course) at import **when resolvable**, else remain descriptive |
| `clos[]` (3–8, description + `bloom_level`) | `Outcome` (CLO level) | Bloom verb guidance in the Builder = authoring-time linting (BOOK-01 Ch. 5.1) |
| **`sections[]` (title + blueprint + mlos)** | **`Module`** — NOT `Section` | **A10:** the FEX "section" carries MLOs and a teaching plan, i.e. it is the *pedagogical* unit; the label "Sections (Lessons)" is UX language only. Importers MUST create `:Module` semantics; the presentational Section/Page tree hangs beneath it |
| `sections[].blueprint` (pedagogical_strategy, duration, media_mix, mlos) | `ModuleBlueprint` (design-time intent) | **A12:** the FEX blueprint *is* the serialized ModuleBlueprint — one concept, two lifecycle stages; import preserves `GENERATED_FROM` lineage (A3) |
| `mlos[]` (description, bloom_level, assessment_method) | `Outcome` (MLO) + planned `ASSESSES` | assessment_method is the seed of the assessment plan |
| `pages[].components[]` (13 types) | `Page` / `Component` (presentational) | **A11:** FEX has 13 component types, the runtime enum has 15 (`diagram`, `simulation` missing). Importers MUST round-trip unknown types losslessly; FEX v1.4 SHOULD add the two |
| `final_examination` (objectives = CLO weights, 13 method types, rating) | `Assessment` + `ASSESSES {weight}` | CLO weight vector maps directly to the `ASSESSES` relationship property |
| `bibliography`, `grading_scheme`, `policies`, `course_resources` | course-catalog aggregates (`CourseBibliography`, `CourseGradeScale`, `CourseAssessmentCategory`…) | existing C5 models |
| author email/name | `FacultyMember` provenance | course ownership anchor |

**Declared gaps for FEX v1.4 (RFC candidates):**

1. **Competency alignment is not serialized** — a course travels without its
   `CLOCompetency` links and framework URIs (CASE/ESCO), losing Competency Engine
   semantics on import. v1.4 SHOULD add an optional `competency_alignments[]`
   block (CLO code → framework URI + level).
2. **Step order vs outcome-first authoring** — the Builder elicits outcomes (step
   2) before content (steps 5–6) ✅, but full assessment planning arrives at step
   7 (final exam), after content. Partial mitigation exists (per-MLO
   `assessment_method` at step 5); v1.4 of the Builder SHOULD surface the
   assessment plan alongside CLOs to fully honor BOOK-01 Ch. 5.3.
3. Concept coverage (`COVERS`) is implicit — extraction infers it post-import;
   v1.4 MAY allow authors to tag key concepts per module.
4. **DE/DI classification (G14):** activity/component types SHOULD carry the
   ANVUR Didattica Erogativa/Interattiva classification (BOOK-19 §5.1) so the
   blueprint's `media_mix` doubles as the declared DE/DI composition per CFU —
   required for the Italian telematic profile, harmless elsewhere.

---

# Chapter 5 — Relationship Registry (closed set; resolves A8, A9)

## 5.1 Census findings and collisions

The running Neo4j v1.0 schema uses: `OFFERS`, `INCLUDES_COURSE`, `HAS_LESSON`,
`CONTAINS`, `COVERS`, `ALIGNS_TO` (PLO→ILO, MLO→CLO), `MAPS_TO` (CLO→PLO),
`ASSESSES`, `PREREQUISITE_FOR` (Concept/Course/MLO), `GENERATED_BY`,
`REQUIRES` (Concept→MediaAsset), `SUPPORTS` (MediaAsset→CLO).

Two collisions:

- **A8 — `REQUIRES` double meaning.** v1.0 uses `REQUIRES` for *Concept needs
  MediaAsset*; the Student Experience constitution §6.2 proposed `REQUIRES` for
  *Concept prerequisite* (Foundation §6 vocabulary). One name, two semantics —
  intolerable in a queryable graph.
- **A9 — alignment naming inconsistency.** The same alignment semantics appears
  as `ALIGNS_TO` at two levels and `MAPS_TO` at one.

## 5.2 Resolutions (normative)

1. **Prerequisite relation:** the canonical name is **`PREREQUISITE_FOR`**
   (direction: earlier → later), as already implemented at three levels. The
   proposed `REQUIRES` alias for prerequisites is **withdrawn**; GPS and gap
   queries MUST traverse `PREREQUISITE_FOR` (inverse reading where needed). The
   Turnkey constitution §6.2 is amended in the same change set (BOOK-00 sync rule).
2. **Asset dependency:** `REQUIRES` (Concept→MediaAsset) is **renamed
   `NEEDS_ASSET`** in schema v2.0; a migration alias keeps v1.0 queries working
   for one minor release, then hard removal.
3. **Alignment:** all outcome-to-outcome alignment becomes **`ALIGNED_TO`**
   (child → parent: MLO→CLO→PLO→ILO), with property `strength`
   (`introduced|reinforced|mastered|aligned` — the existing enum). `ALIGNS_TO`
   and `MAPS_TO` become migration aliases, then removed.

## 5.3 Canonical registry (L1, closed — RFC to extend)

| Relationship | Domain → Range | Properties | Notes |
|--------------|----------------|-----------|-------|
| `OFFERS` | Institution → Program | — | existing |
| `INCLUDES_COURSE` | Program → Course | term, required | existing |
| `CONTAINS` | Course → Module | order | existing |
| `HAS_LESSON` | Course/Module → Lesson | order | existing |
| `COVERS` | Lesson/Outcome → Concept | depth | existing (+Outcome per Ch. 3.1) |
| `RENDERED_BY` | Lesson/Activity → Page/Component | — | new (Ch. 4.3) |
| `ALIGNED_TO` | Outcome → parent Outcome | strength | **normalized (A9)** |
| `ASSESSES` | Assessment → Outcome/Concept/Competency | weight | existing, range extended |
| `PREREQUISITE_FOR` | Concept/Course/MLO → same class | strength | **canonical prerequisite (A8)** |
| `DEPENDS_ON` | Competency → Competency | — | constitution v1.2 |
| `UNDERPINS` | Concept → Competency | — | new (Ch. 3.1) |
| `COMPONENT_OF` | Skill → Competency | — | new (Ch. 3.1) |
| `DEVELOPS` | Course/Outcome → Competency | strength | constitution v1.2 |
| `EVIDENCES` | Learner → Competency | confidence, status, updated_at | constitution v1.2 (student overlay) |
| `KNOWS` | Learner → Concept | p_mastery, updated_at | constitution v1.2 (BKT projection) |
| `AWARDS` | Credential → Competency | level | constitution v1.2 |
| `NEEDS_ASSET` | Concept → MediaAsset | — | **renamed from REQUIRES (A8)** |
| `SUPPORTS` | MediaAsset → Outcome | — | existing |
| `GENERATED_BY` | MediaAsset → Lesson | model, fingerprint | existing; provenance properties made mandatory |
| `GENERATED_FROM` | Course → ModuleBlueprint | job_id | new (A3 lineage) |
| `SAME_AS` | Concept → Concept | confidence, source | existing ontology service (cross-course dedup) |

Conventions: labels PascalCase; relationships UPPER_SNAKE; direction reads as an
English sentence (domain verb range); every relationship has exactly one meaning;
inverse names are never materialized (query direction instead).

## 5.4 PG extraction vocabulary (A1, semantic side)

The PostgreSQL `KnowledgeGraphNodeType` (`concept, topic, skill, person,
organization, event, location, term`) and `KnowledgeGraphEdgeType` (`related_to,
prerequisite, part_of, example_of, similar_to, depends_on, extends`) are the
**NLP extraction staging vocabulary** — deliberately looser than L1. Normative
mapping at promotion time (staging → graph):

`concept/topic/term → :Concept` · `skill → :Skill` · `prerequisite →
PREREQUISITE_FOR` · `part_of → CONTAINS/COMPONENT_OF per context` · `related_to/
similar_to → SAME_AS candidate (ontology service review)` · `person/organization/
location/event` → not promoted (metadata only). Staging records MUST NOT be
queried by product features (BOOK-04 A1); only the promotion pipeline reads them.

---

# Chapter 6 — Graph Schema Binding (Neo4j, authoritative — closes A1)

1. **Authority:** Neo4j is the single authoritative store for L1 semantic
   structure and traversal. The PG `knowledge_graphs/nodes/edges` tables are
   extraction staging (Ch. 5.4) and enter sunset: no new readers, promotion
   pipeline only, removal per BOOK-13 plan.
2. **Node contract:** every node carries `pg_id` (join key), `tenant_id` where
   tenant-scoped (student overlay always; definition tier per sharing policy),
   `created_at`, `schema_version`. Uniqueness constraints on `(label, pg_id)`.
3. **Schema versioning:** running = v1.0; constitution overlay = v1.2 (Student,
   Competency, Skill, Credential nodes + EVIDENCES/KNOWS/DEVELOPS/AWARDS);
   **this Book defines v2.0 = v1.2 + renames of Ch. 5.2** (NEEDS_ASSET,
   ALIGNED_TO normalization, RENDERED_BY, UNDERPINS, COMPONENT_OF,
   GENERATED_FROM). Migrations are idempotent Cypher scripts; aliases live for
   exactly one minor release.
4. **Write paths:** definition tier via sync service handlers; student overlay
   via event consumers only (BOOK-03 §3.3 invariants).

---

# Chapter 7 — External Framework Alignment (L2)

| Framework | Mechanism | Turnkey status |
|-----------|-----------|----------------|
| **CASE (1EdTech)** | `CASEFramework` import: CFDocument/CFItem → CompetencyFramework/Competency with `case_uri` preserved | model exists ✅; import → L1 mapping rules here are normative |
| **ESCO** | `esco_uri` on Skill/Competency and occupation URIs on career goals; local snapshot table, quarterly refresh (constitution §20) | fields designed 🔵 |
| **EQF** | framework levels on Competency (`level = "EQF-5"`); qualification mapping for Track A accreditation (BOOK-02 Ch. 9) | 🔵 |
| **SKOS crosswalks** | inter-framework equivalence uses `skos:exactMatch/closeMatch/broadMatch` predicates stored as mapping rows — never silent merging of frameworks | ⚪ |
| **QTI / Caliper / xAPI** | assessment content and activity vocabularies; QTI packages and Caliper events already modeled | ✅ |
| **Open Badges 3.0 / CLR / ELM** | credential export vocabulary: DLU Credential → OB `Achievement` (`CourseAchievement` exists), competencies → OB `alignment` objects with framework URIs | 🟡 (BOOK-16) |

Rule: external URIs are **annotations on DLU identities**. Deleting or re-mapping
an external alignment never deletes DLU-side state; crosswalk changes are governed
(they alter credential semantics).

---

# Chapter 8 — The Ontology Registry and Enforcement

1. **Registry artifact:** `architecture/ontology/dlu-core.yaml` in this repository
   — machine-readable: classes, relationships, properties, deprecated synonyms,
   graph bindings, URIs. This Book is its narrative; the YAML is what CI reads.
2. **Enforcement gates:**
   - graph migrations validated against the registry (no unregistered label/rel);
   - event nouns and API resource names checked at review against class names;
   - **agent prompt templates import vocabulary from the registry** — agents MUST
     name things as the UI names them (drift check in the agent eval harness,
     BOOK-11);
   - the existing ontology service (same-as, duplicate detection, auto-linking)
     is the runtime instrument for instance-level hygiene; its `SAME_AS`
     proposals above threshold go to human review, mirroring HITL discipline.
3. **Change process:** term addition/rename/deprecation = RFC → registry PR →
   alias window → removal. Silent renames are conformance failures.

---

# Chapter 9 — Anomaly Resolution Register

| # | Anomaly (BOOK-04 / new) | Resolution | Where |
|---|--------------------------|------------|-------|
| A1 | Dual KG storage (PG + Neo4j) | Neo4j authoritative; PG = extraction staging with promotion mapping; sunset plan | Ch. 5.4, 6 |
| A3 | Parallel course structures | Blueprint = design-time intent with `GENERATED_FROM` lineage; TenantCourse = projection | Ch. 4.3 |
| A4 | Lesson vs Section/Page | two orthogonal hierarchies + `RENDERED_BY` totality rule | Ch. 4 |
| A6 | Event catalog fragmentation | event nouns bound to registry classes | Ch. 8.2 |
| **A8** | **`REQUIRES` double meaning** (new) | prerequisite = `PREREQUISITE_FOR` canonical; asset dependency renamed `NEEDS_ASSET`; constitution §6.2 amended | Ch. 5.2 |
| **A9** | **`ALIGNS_TO`/`MAPS_TO` inconsistency** (new) | normalized to `ALIGNED_TO` + `strength`; aliases one release | Ch. 5.2 |
| **A10** | **FEX `section` ≠ ontology `Section`** (new) | FEX section binds to `Module` (MLO carrier); "Sections (Lessons)" is UX language only; importers create Module semantics | Ch. 4.4 |
| **A11** | **Component typology divergence 13 vs 15** (new) | lossless round-trip of unknown types mandatory; FEX v1.4 adds `diagram`, `simulation` | Ch. 4.4 |
| **A12** | **FEX `blueprint` vs `ModuleBlueprint`** (new) | one concept, two lifecycle stages; import preserves `GENERATED_FROM` lineage | Ch. 4.4 |

(A2, A5, A7 are structural, resolved in BOOK-04/18.)

---

# Annex A — Turnkey Baseline Mapping (normative)

| Semantic element | Turnkey asset | Status | Gap |
|------------------|--------------|--------|-----|
| Graph schema v1.0 | Neo4j labels/rels per `KNOWLEDGE_GRAPH_SCHEMA.md` | ✅ | v2.0 renames 🔵 (rides STX-05) |
| Extraction staging | PG KG tables + NLP extractor | ✅ | promotion mapping enforcement 🔵; sunset ⚪ (BOOK-13) |
| Ontology hygiene service | `/api/ontology`: same-as, duplicates, auto-link, terms | ✅ | HITL threshold policy 🟡 |
| Component typology | `ComponentType` (15 types) | ✅ | LearningActivity binding (`RENDERED_BY`) 🔵 |
| CASE import | `CASEFramework` model | ✅ | CFItem → Competency mapping rules 🔵 (STX-04) |
| QTI/Caliper/xAPI vocab | `models_ccp_standards`, xAPI/Caliper models | ✅ | — |
| Credential vocabulary | `CourseAchievement`, credential VC JSON | 🟡 | OB 3.0 alignment objects (BOOK-16) |
| Course Exchange Format | FEX v1.3 (`COURSE_EXCHANGE_FORMAT.md`, `models_course_fex.py`, `course_exchange_service`, DLU Course Builder wizard) | ✅ | semantic binding of Ch. 4.4 to enforce at import 🔵; v1.4 gaps (competency alignments, 15 types) ⚪ RFC |
| Registry + CI gates | — | ⚪ | `dlu-core.yaml` + validation (first deliverable of BOOK-13 sprint work) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Semantic quadrangle | Concept / Skill / Competency / Outcome distinctions of Ch. 3.1 |
| Pedagogical vs presentational hierarchy | The two content hierarchies of Ch. 4, bound by `RENDERED_BY` |
| Promotion | Governed move of extraction-staging records into the authoritative graph |
| Extraction staging | PG KG tables + loose NLP vocabulary, feeding promotion only |
| Registry (`dlu-core.yaml`) | Machine-readable ontology consumed by CI, migrations and agent prompts |
| Alias window | One-minor-release period in which a renamed term answers to both names |

---

*BOOK-05 v1.0 — awaiting review. The Turnkey constitution §6.2 amendment (A8) is
applied in the same change set. Next per dependency order: BOOK-06 (Student
Digital Twin).*
