# BOOK-04 — Academic Domain Model
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The domain layer of the AOS: bounded contexts, aggregates and their owners,
> lifecycle state machines, the identity & consent model, key-type discipline and
> the aggregate↔event map. BOOK-05 gives these concepts semantic (ontological)
> identity; BOOK-06/07/08 specialize the twin aggregates; BOOK-18 maps the model
> to code files.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-03 (engine contracts,
> tenancy). **Primary audience:** architects, senior engineers, data stewards.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** the
catalog below was extracted by census of the running Turnkey model layer
(~60 persistent classes across ~30 `models_*.py` files) plus the Student
Experience constitution's designed models. Where the census found duplications
or parallel populations, this Book **declares them** (Ch. 9) rather than idealizing
them away.

---

# Chapter 1 — Purpose and Method

A domain model for a brownfield system has one job: impose a **single conceptual
map** over code that grew feature-by-feature, so that every future change knows
which context it belongs to, which aggregate it touches, who owns that aggregate,
and which events it must emit.

Method used (and to be repeated at every DAS minor release):

1. Census of all persistent classes and enums in `backend/database/`.
2. Assignment of every class to exactly one bounded context (Ch. 2) and one
   owning engine (BOOK-03 Ch. 3).
3. Identification of aggregate roots and their invariants (Ch. 3).
4. Declaration of anomalies — duplicate populations, parallel hierarchies,
   key-family mixtures (Ch. 9) — each with an owner and a resolution path.

**Rule:** a new model class that cannot be assigned to a context and an engine is
rejected at review. "Miscellaneous" is not a context.

---

# Chapter 2 — Bounded Contexts

Ten contexts. Each names its owning engine(s), its schema placement and its
process areas (BOOK-02).

| # | Context | Owning engine | Schema | Process areas |
|---|---------|---------------|--------|---------------|
| C1 | Identity & Access | Identity | platform | all |
| C2 | Tenancy & Commercial | Identity (platform plane) | platform | P05, P06 |
| C3 | Institutional Structure | (structural substrate — governed by Institution Twin) | platform | P01–P03, P07 |
| C4 | Outcomes & Competency | Competency | platform (definitions) + tenant (student state) | P02, P07 |
| C5 | Content & Authoring | Learning | tenant | P02 |
| C6 | Delivery & Activity | Learning + Assessment | tenant | P02 |
| C7 | Learner Intelligence | Twin + Knowledge + GPS + ACE | tenant | P01, P02 |
| C8 | Trust & Credentials | Assessment + Credential | tenant (+ platform templates) | P01, P07 |
| C9 | AI Operations | ACE + substrate | platform (+ tenant overrides) | P06 |
| C10 | Federation & Interop | drivers (BOOK-03 Ch. 6) | platform + mapping tables | P08 |

Context rules:

1. Cross-context references use **identifiers, never object references**
   (no cross-file `relationship()` — a running Turnkey convention that doubles as
   context isolation).
2. A context MAY read another context's aggregates through its engine services;
   it MUST NOT write them.
3. Contexts map to Academic Domains (BOOK-03 Ch. 2 layer): an experience composes
   contexts through domain facades, e.g. *Recognition* = C4 + C8 + C10.

---

# Chapter 3 — Aggregate Catalog

Format: *aggregate root [key family, schema] — members — core invariant*.
Key families: **G** = GUID, **I** = legacy Integer, **B** = tenant BigInteger
(discipline in Ch. 6).

## C1 — Identity & Access

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **User** [G, platform] | AuthIdentity (multi-provider: local/SAML/OIDC), TenantUserMembership, RoleScope | one platform identity per person; credentials live in the IdP; memberships define tenant reach |
| **SSOConfig / SAMLConfiguration** [G, platform] | per-tenant IdP bindings | secrets encrypted at rest, never in payloads |
| **Consent** (kernel extension, on Twin anchor) | consent_flags + change history | consent changes are events; evaluation at context assembly (BOOK-01 Ch. 7) |

## C2 — Tenancy & Commercial

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **Tenant** [G, platform] | PlatformSubscription, CustomDomain, tier/config/features/limits | BOOK-03 §5.1; tier ⊥ institution_type |
| **UsageEvent / AuditLog** [G, platform] | — | append-only; audit log is never soft-deleted |

## C3 — Institutional Structure

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **Institution** [G, platform] | Campus, College → School → Department | 1:1 Tenant; hierarchy soft-deleted only, children checked (409 on active children) |
| **Program** [G, platform] | ProgramVersion, ProgramCourse, CourseCatalogItem | versioned; catalog items project programs to offerings |
| **AcademicTerm** [G, platform] | — | terms bound scheduling and GPS planning |
| **CatalogEdition** [G, platform] *(G15)* — **✅ implemented (NEW-16, 2026-07-27)** | CourseCatalogItem set + numbering system, credit rules, designations (e.g. G/W), prerequisites, per-course knowledge/competency contributions (`DEVELOPS`/`COVERS` declarations, `CourseContributionDeclaration`), recognition policies (`CatalogRecognitionPolicyDeclaration`) | **the legal/contractual catalog**: versioned, published, immutable once effective; enrollment binds a cohort to an edition (regulation-year semantics, G7 — cited/visible per edition, requirement computation still version-inert, unchanged by this sprint); the formal catalog document is a generated view over it (BOOK-16 §6.5). Modeled as a `RouteGraphVersion`-style compiled SNAPSHOT (header row + canonical-JSON blob, insert-only, `publish_edition` the sole sanctioned reader of the live `Program`/`ProgramVersion`/`CourseCatalogItem` rows — enforced by `check_catalog_sole_reader.sh`), not a retrofit of immutability onto those live, actively-CRUD'd tables |
| **TeachingSection** [G, platform] | FacultyAssignment | links program courses to faculty and terms |
| **FacultyProfile** [G, platform] | — | seed of the Faculty Twin (BOOK-07) |

## C4 — Outcomes & Competency

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **Outcome hierarchy** [G, platform] | ILO, PLO, CLO, MLO, lesson outcomes + alignments (CLOtoPLO, PLOtoILO, MLOtoCLO, OutcomeAssessmentAlignment) + BloomVerbMapping, OutcomeCoverageMatrix | alignment rules of BOOK-01 Ch. 5.2; Bloom-levelled |
| **Competency** [G, platform] | CLOCompetency; CompetencyFramework (designed, STX-04) | framework-aligned, levelled (BOOK-01) |
| **StudentCompetency** [G, tenant] *(designed)* | EvidenceRecord (append-only) | sole writer: Assessment Engine; `verified` requires human |
| **ExternalCourse** [G, platform] | — | recognition source data (P08/WS02) |

## C5 — Content & Authoring

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **Course** [I, tenant] | Section → Page → Component; Lesson; CourseVersion, LessonVersion; CourseTemplate; CourseGlossary/GlossaryTerm | outcome-first authoring (BOOK-01 Ch. 5.3); workflow states Ch. 4 |
| **MediaAsset** [I/G mixed, tenant] | VideoProject, MediaTranscript, TranscriptChunk | generated media carries provenance (model, prompt fingerprint) |
| **CourseResource** (RAG) [I, tenant] | ResourceChunk, ResourceLanguageAnalysis | retrieval grounding source (BOOK-01 P5, BOOK-03 §3.5) |
| **GenerationJob** [G, tenant] | GenerationArtifact, ReviewTask, ApprovalTask | human gates in the pipeline are never skipped |
| **Quality** | QAResult, ContentCheck, ContentReview, CrossCourseSimilarity, ContentVariant, ContentRefreshJob/History | QA verdicts are append-only records |
| **AcademicOffering / ModuleBlueprint** [G, tenant] | ModuleLearningObjective, ReferenceDocument(+Scope) | blueprint→course generation lineage preserved (Ch. 9 anomaly A3) |

## C6 — Delivery & Activity

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **Enrollment** [I/B, tenant] | StudentProgress, LessonProgress | official enrollment mirrors ERPNext (ADR-0009); local enrollment is delivery state |
| **QuizAttempt / LabSubmission** [I, tenant] | QuizBloomDistribution | attempts are immutable once scored |
| **Activity stream** | XAPIStatement, Caliper events, LearnerEvent | append-only; single ingestion path feeds BKT and evidence (BOOK-01 P2) |
| **Cohort / Pacing** | cohort + pacing models | community objects with health metrics (BOOK-02 Ch. 6) |

## C7 — Learner Intelligence

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **StudentTwin** [G, tenant] *(designed, STX-01)* | TwinAcademicMirror, TwinCareerGoal, TwinBehaviourProfile, TwinAIMemory; LearnerProfile [G, platform] as identity-layer seed | BOOK-06; layers update independently via events; version bump on write |
| **ConceptMastery** [I, tenant] | MasteryEvent (append-only) | BKT state; GUID reconciliation via identity_map (BOOK-03 §5.3) |
| **PersonalizationContext / RecommendationRule** [G, tenant] | recommendations *(designed)* | explanation trace mandatory (ADR-0006) |
| **PathScenario** [G, tenant] *(designed)* | — | deterministic, input-fingerprinted (BOOK-03 §3.8) |

## C8 — Trust & Credentials

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **EvidenceRecord** [G, tenant] *(designed, STX-04/08)* | — | append-only, trust-weighted, sourced |
| **CredentialTemplate** [G, platform] *(designed)* | criteria | policy-gated issuance tiers |
| **IssuedCredential / UserBadge** [G/I, tenant] | revocation entries | survives commercial state (BOOK-02 §8.2); standards-compliant export |

## C9 — AI Operations

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **AgentConfig** [G, platform] | ai_model_presets, ai_skill_registry, ai_mcp_servers | every agent has an envelope owner (BOOK-02 §3.2) |
| **LLMProvider / Quota** [G, platform] | gateway virtual keys, quota budgets/keys | master key never in DB; quotas enforced pre-call |
| **AgentWorkflow** [I, tenant] | AgentStep, AgentLog | execution records are audit-grade |

## C10 — Federation & Interop

| Aggregate | Members | Invariant |
|-----------|---------|-----------|
| **InstanceRegistry** [G, platform] | federation policies | agreements as policy objects (BOOK-02 Ch. 10) |
| **Interop mappings** | moodle/frappe mapping tables, interop bridge, CCP standards models | mapping tables are driver-owned mirrors, not kernel state |

---

# Chapter 4 — Lifecycle State Machines

Canonical machines (transitions emit events; unlisted transitions are illegal):

**Tenant** (C2): `provisioning → active → suspended → deleted → purged`
— suspension blocks access, never erases evidence (BOOK-02 §8.2).

**Learner lifecycle** (C7, Twin anchor): `prospect → applicant → candidate →
enrolled → active → graduate → alumni → lifelong` — mirrors P01; transitions are
`student.lifecycle.changed` events; regression (alumni → active) is legal.

**Course workflow** (C5, existing `CourseStatus`/`CourseWorkflowState`):
`draft → in_review → approved → published → archived`, with QA gates
(`awaiting_semantic_review`, `awaiting_review` in the import pipeline) that MUST
NOT be skipped.

**Competency status** (C4): `targeted → in_progress → evidenced → mastered →
verified` (+ `expired` by decay) — thresholds in BOOK-01 Ch. 6; `verified` only
via human action.

**Credential** (C8): `eligible → pending_policy → issued → (revoked | expired)`
— high-stakes issuance passes a HITL queue (`agent_proposals`).

**Evidence** (C8): created → (never mutated) — corrections are new records
referencing the original.

**Agent proposal** (C9): `proposed → approved | rejected | expired` — 409-guarded
against double processing.

---

# Chapter 5 — Identity & Consent Model

## 5.1 One anchor, several projections

```text
platform.users (GUID)  ← THE identity anchor (kernel contracts bind here)
 ├─ AuthIdentity          per-provider login bindings (local, SAML, OIDC/Keycloak)
 ├─ TenantUserMembership  which tenants, which roles — cross-tenant reach
 ├─ TenantUser [B]        per-tenant profile projection (legacy population)
 ├─ LearnerProfile (G)    learning preferences/accessibility (Twin identity layer seed)
 └─ StudentTwin (G)       kernel learner aggregate (1:1 per tenant)
```

Rules (extend BOOK-03 §5.3):

1. Kernel aggregates reference `platform.users.id` (GUID) — never TenantUser keys.
2. A person with memberships in N tenants has N twins (twin is tenant-scoped);
   cross-tenant twin linkage is a federation concern (C10), consent-gated,
   never implicit.
3. `AuthIdentity` supports multiple concurrent providers; account merge is a
   governed registrar operation, emitting an identity-merge event that consumers
   (mastery, evidence) MUST honor.

## 5.2 Consent model

Consent is **purpose-scoped**, not binary:

| Purpose key | Gates | Degradation when false |
|-------------|-------|------------------------|
| `ai_personalization` | Career/Behaviour/AI twin layers; personalized recommendations | curriculum-ordered delivery (BOOK-01 Ch. 7) |
| `behaviour_analytics` | behaviour feature computation | no behaviour profile; risk detection from academic signals only |
| `career_processing` | ESCO matching, career advisor | GPS career scenario disabled |
| `cross_institution_sharing` | federation twin linkage, mobility dossiers | recognition via documents only |

Consent state lives on the Twin anchor; every change is an audited event with
effect at next context assembly (cache bust). Minors (high-school profile) add
guardian-consent requirements (BOOK-19).

---

# Chapter 6 — Key-Type Discipline

Three key families exist; the discipline is containment:

| Family | Population | Status | Rule |
|--------|-----------|--------|------|
| **GUID** | platform schema; all kernel aggregates; all new tables | canonical | mandatory for everything new |
| **Integer** | legacy course family (Course, Section, Page, Component, QuizAttempt…), ConceptMastery | contained | FKs to `courses.id` stay Integer; never extended to new families |
| **BigInteger** | tenant-local population (`TenantUser`, `TenantCourse`…) | contained | treated as projections; no new kernel FKs to this family |

Reconciliation: exactly one mapping service (`identity_map`) for GUID↔Integer
learner identity (constitution §13.4); course-family bridging uses explicit
`course_id Integer` columns on kernel tables (e.g. EvidenceRecord). Any migration
touching key families is additive-only with dual-write, never in-place conversion.

---

# Chapter 7 — Aggregate ↔ Event Map

The Event Mesh taxonomy (BOOK-03 Ch. 4.3) is organized by aggregate. The
student-domain set is canonical in the Turnkey constitution §7.3; this chapter
adds the consolidation duty for the remaining domains, currently scattered in
`EVENT_CATALOG.md`:

| Aggregate (context) | Canonical events |
|---------------------|------------------|
| Tenant (C2) | `tenant.provisioned/suspended/deleted` |
| User/Consent (C1) | `student.created`, `profile.updated`, `consent.changed`, `identity.merged` |
| Twin (C7) | `student.lifecycle.changed`, layer-update events, `persona.proposed/confirmed` (BOOK-06 Ch. 4.3 — proposed by Discovery Agent intake, confirmed by ACE only on learner acceptance) |
| Course (C5) | `course.created/updated/published/archived`, QA-gate events |
| GenerationJob (C5) | `generation.completed`, review/approval gate events |
| Enrollment (C6) | `enrollment.synced`, `grade.synced` (driver-sourced) |
| Activity (C6) | `activity.recorded`, `assessment.completed` |
| Mastery (C7) | `mastery.updated` |
| Competency (C4) | `competency.discovered/updated/mastered` |
| Evidence (C8) | `evidence.recorded` |
| Credential (C8) | `badge.awarded`, `credential.issued/revoked` |
| GPS (C7) | `path.replanned`, `graduation.predicted` |
| Recommendation (C7) | `recommendation.generated/accepted/dismissed` |
| Risk (C7) | `risk.detected/cleared` |
| AssessmentSession (C6) — G2 | `assessment_session.published/changed`, `assessment_session.enrolled/withdrawn` |
| Thesis (C6/C8) — G5 | `thesis.milestone.completed`, `thesis.deposited`, `thesis.defended` |
| Committee (C3) — G6 | `committee.formed`, `committee.verdict.recorded` |
| Federation (C10) | `partner.registered`, `mobility.requested/approved` |
| FSEP Obligation/Payment/Financing/Card/Reward (new context, **BOOK-27** — not yet one of C1–C10) | 24 proposed events (RFC-0003 §3) — **not yet implemented**; producers/consumers land in Phase 1, gated on the pilot per `dlu_builder_tk/docs/ops/TRACK_C_POST_PILOT_PLAN.md` |

Rules: every aggregate-mutating service MUST emit its aggregate's events through
the outbox; an aggregate with no events is either read-only or wrongly modeled.

---

# Chapter 8 — Data Classification (pointer to BOOK-19)

Minimum classification, applied per aggregate: **public** (catalog, published
content) · **internal** (authoring drafts, QA) · **personal** (identity, profile,
enrollment) · **sensitive-learning** (mastery, behaviour, risk, AI memory —
highest protection: consent-gated, region-pinned, aggregate-only analytics) ·
**trust-critical** (evidence, credentials — integrity over confidentiality:
append-only, signed where exported). Retention and erasure per class in BOOK-19;
the twin-erasure exception for credential-supporting evidence is already
constitutional (pseudonymized retention).

---

# Chapter 9 — Declared Anomalies (with owners and resolution paths)

The census found parallel populations. Per the source-of-content rule they are
declared, owned and scheduled — not hidden:

| # | Anomaly | Reality | Resolution path |
|---|---------|---------|-----------------|
| A1 | **Dual knowledge-graph storage** | `KnowledgeGraph/Node/Edge` tables in PostgreSQL *and* Neo4j graph | Neo4j is authoritative for traversal/semantics (BOOK-13); PG tables are build artifacts/cache — MUST NOT be queried by new code; sunset via BOOK-13 |
| A2 | **Triple user population** | platform User (G) + TenantUser (B) + LearnerProfile (G) | Ch. 5.1 anchor rule; TenantUser demoted to projection; merge plan in BOOK-18 |
| A3 | **Parallel course structures** | Course/Section/Page/Component (I) vs AcademicOffering/ModuleBlueprint (G) vs TenantCourse (B) | Course family = delivery structure; Blueprint family = authoring intent (lineage kept); TenantCourse = projection; no new writers to TenantCourse |
| A4 | **Lesson vs Section/Page** | both content containers exist in models.py | BOOK-05 ontology names Lesson the pedagogical unit, Section/Page the layout units; code alignment in BOOK-18 |
| A5 | **Key-family mixture** | G/I/B across contexts | Ch. 6 discipline; no in-place conversion |
| A6 | **Event catalog fragmentation** | `EVENT_CATALOG.md` (Redis pub/sub era) vs constitution §7.3 (Streams) | Ch. 7 consolidation; single registry at STX-03 |
| A7 | **Enrollment duality** | local enrollment/progress vs ERPNext official enrollment | ADR-0009 mirror rule; local = delivery state, official = ERPNext; naming cleanup in BOOK-18 |

---

# Chapter 10 — Conformance Rules

1. Every persistent class is assigned to one context, one engine, one key family.
2. Aggregate roots enforce their invariants in services, not in UIs.
3. Cross-context writes are prohibited; cross-context reads go through engine
   services.
4. Every mutation emits its aggregate's events via the outbox.
5. State machines of Ch. 4 are the only legal transitions.
6. Consent purposes of Ch. 5.2 gate everything they name, at assembly time.
7. Anomalies A1–A7 MUST NOT grow: no new writers/readers on deprecated
   populations.

---

# Annex A — Model File → Context Mapping (extract)

| Turnkey file | Context(s) | Notes |
|--------------|-----------|-------|
| `models.py` | C1 (User), C5 (Course family, media, RAG, QA), C6 (attempts, progress, activity), C8 (UserBadge) | largest legacy file; split plan in BOOK-18 |
| `models_platform.py` | C2 | ✅ clean |
| `models_auth.py` | C1 | AuthIdentity, memberships, SAML |
| `models_tenant.py` | C1/C5 projections | B-family; contained (A2/A3) |
| `models_institution.py` | C3, C4 | hierarchy + outcomes + competency |
| `models_learning_outcomes.py` | C4 | alignments, Bloom, coverage |
| `models_mastery.py` | C7 | BKT (I-family, contained) |
| `models_xapi.py` / `models_caliper.py` | C6 | activity stream |
| `models_content_creation.py` | C5, C7 | blueprints + LearnerProfile + personalization |
| `models_course_catalog.py` | C3/C5 | catalog projections (tenant schema) |
| `models_agent.py`, `models_ai.py`, `models_llm.py` | C9 | workforce + substrate |
| `models_federation.py`, `models_moodle.py`, `models_frappe*.py`, `models_interop_bridge.py`, `models_ccp_standards.py` | C10 | driver mirrors |
| `models_pedagogical.py`, `models_review.py`, `models_collaboration.py` | C5 | quality & collaboration |
| `models_student_twin.py`, `models_competency_graph.py`, `models_student_experience.py` | C7, C4, C8 | **delivered STX-01/02/03/04** (2026-07-14/15): twin anchor+layers+snapshots; frameworks/StudentCompetency/EvidenceRecord + versioned `competency_engine_params` (C4 engine service ✅, BOOK-15 §4.1 trust config); `domain_events` outbox |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Context (C1–C10) | Bounded context per Ch. 2; unit of ownership and change review |
| Key family (G/I/B) | GUID / legacy Integer / tenant BigInteger populations, per Ch. 6 |
| Projection | Read-oriented copy of an aggregate owned elsewhere (TenantUser, TenantCourse, mirrors) |
| Declared anomaly | Census-found duplication with owner and resolution path (Ch. 9) |
| Purpose-scoped consent | Consent model of Ch. 5.2 — per-purpose gates with defined degradation |

---

*BOOK-04 v1.0 — awaiting review. Next per dependency order: BOOK-05 (Academic
Ontology & Semantic Model).*


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

New aggregates/lifecycles: `LearningGoal`, `TutorSession`/`TutorTurn`, `LearningIntervention`, `Misconception`, `LearningPlan`, `PolicyVersion`, `TutorEvidence`. Course Format v2.0 makes CLO/MLO/Concept/Skill first-class with stable identity.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
