# BOOK-03 — Academic Operating System
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The reference architecture of the AOS: layer semantics, the ten kernel engine
> contracts, the Event Mesh specification, tenancy and isolation, the driver model
> for external systems, and the non-functional envelope. This is the root
> architectural Book; BOOK-04…16 specify what this Book contracts.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-00 (Ch. 6 invariants),
> BOOK-01 (pedagogical constraints), BOOK-02 (process architecture P01–P08).
> **Informs:** all technical Books; BOOK-18 maps this architecture to Turnkey code.
> **Primary audience:** enterprise/solution architects, senior engineers.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** the
runtime topology, tenancy model, integration fabric and event patterns below are
systematized from the running Turnkey platform (compose topologies, multi-tenancy
architecture, `UNIVERSITY_PLATFORM_ARCHITECTURE.md`, `EVENT_CATALOG.md`, the
Student Experience constitution) — Annex A carries the mapping.

---

# Chapter 1 — Architectural Stance

Three commitments shape every decision in this Book:

1. **The kernel is small and the contracts are stable.** Engines own state and
   expose services; everything else — experiences, agents, integrations — composes
   them. Kernel contract changes are DAS-major events (BOOK-00 Ch. 8).
2. **Events are the connective tissue.** Cross-engine and cross-process effects
   flow through the Event Mesh (interrupts, not polling). Synchronous calls are
   reserved for queries and same-aggregate commands.
3. **The reference implementation is brownfield** (ADR-0008). The AOS is realized
   by *rationalizing* DLU Builder Turnkey — drawing the kernel boundary through an
   existing codebase — not by rewriting it. Where the ideal and the running system
   diverge, this Book states the ideal and Annex A states the migration.

---

# Chapter 2 — Layer Semantics

```text
Applications        ← deployable products (portal, mobile, admin console)
    ↓
Experiences         ← workspaces: WS00–WS08 student; faculty; institution (BOOK-17)
    ↓
Academic Domains    ← bounded contexts grouping engines per process area (BOOK-04)
    ↓
Academic Services   ← engine service interfaces ("syscalls") + composition services
    ↓
Academic Kernel     ← the ten engines: state + invariants + events
```

Layer rules (normative):

1. A layer MAY call only the layer directly beneath it; skipping layers is
   prohibited except for read-only telemetry.
2. **Experiences own no domain state** (BOOK-00 Ch. 6.2). An experience is
   navigation + kernel reads + event emissions + presentation state only.
3. Domains are bounded contexts: they group engine capabilities for a process area
   (e.g., the *Recognition* domain composes Competency + Assessment + Credential
   engines for P08/WS02). Domains introduce no storage of their own.
4. Composition services (sagas spanning engines) live in the service layer, are
   stateless between steps, and persist coordination state as events — never as
   private tables.

---

# Chapter 3 — Kernel Engine Contracts

Contract format: *owns (state) · provides (service interface) · consumes/emits
(events) · invariants*. Full data models in BOOK-04/05; this chapter is the
binding contract surface. All engine APIs are tenant-scoped (Ch. 5) and versioned.

## 3.1 Identity Engine

- **Owns:** user↔tenant binding, roles, consent flags, session context. Credentials
  are NOT owned — identity federates to the IdP (Keycloak; ADR see Ch. 6).
- **Provides:** `whoami`, role/permission checks (RBAC), consent queries.
- **Emits:** `student.created`, `profile.updated`, consent-change events.
- **Invariants:** every kernel call carries an authenticated principal and tenant;
  consent checks happen at context-assembly, not in UIs (BOOK-01 Ch. 7).

## 3.2 Digital Twin Engine

- **Owns:** twin anchors, layer tables, twin versioning, AI memory (BOOK-06/07/08).
- **Provides:** `TwinContextService.get_context(user, layers, purpose)` — the sole
  context assembly point; layer writes via services, never direct.
- **Consumes:** nearly everything (`enrollment.synced`, `mastery.updated`,
  `competency.*`, `activity.recorded`…). **Emits:** `student.lifecycle.changed`,
  layer-update events.
- **Invariants:** mirror layers are read-only w.r.t. their source of truth;
  `purpose` is mandatory and audited; consent gates layers.

## 3.3 Knowledge Engine

- **Owns:** the concept graph (Neo4j), prerequisite structure, per-learner
  knowledge overlay (BKT projection `KNOWS`).
- **Provides:** graph queries (prerequisite chains, gap queries), GraphRAG
  retrieval context, mastery-state reads.
- **Consumes:** `mastery.updated`, content-graph change events. **Emits:** KG sync
  completion events.
- **Invariants:** graph writes are asynchronous (worker consumers, batched); a
  graph outage MUST NOT fail an API call (fire-and-forget + try/except); student
  overlay always tenant-filtered.

## 3.4 Competency Engine

- **Owns:** frameworks (EQF/ESCO/DigComp/SFIA/custom), competency definitions,
  student competency state + confidence, curriculum↔competency links.
- **Provides:** framework CRUD, student competency reads, confidence recompute,
  human verification actions.
- **Consumes:** `evidence.recorded`. **Emits:** `competency.updated`,
  `competency.mastered`, `competency.discovered`.
- **Invariants:** confidence is deterministic and explainable (BOOK-01 Ch. 6);
  `verified` requires a human (ADR-0012); definitions are platform-shared,
  student state is tenant-isolated.

## 3.5 Learning Engine

- **Owns:** courses/content structure, learning missions, pacing/cohorts, media
  assets, delivery bindings (SCORM/LTI to LMS).
- **Provides:** content reads, mission scheduling, authoring pipeline (outcome-first,
  BOOK-01 Ch. 5.3).
- **Consumes:** recommendations (mission creation), `path.replanned`.
  **Emits:** content lifecycle and delivery events.
- **Invariants:** no content without declared outcomes; AI generation is grounded
  (retrieval context mandatory — never pure generation to learners).

## 3.6 Assessment Engine

- **Owns:** assessment definitions/alignments, attempts, the evidence pipeline,
  evidence records (sole writer — ADR-0012).
- **Provides:** assessment runtime, evidence timeline reads, integrity workflows
  (viva dossiers).
- **Consumes:** `assessment.completed`, `activity.recorded`, `grade.synced`.
  **Emits:** `evidence.recorded`.
- **Invariants:** evidence is append-only and trust-weighted; formative and
  summative share the pipeline with different weights (BOOK-01 Ch. 8); unaligned
  assessments yield mastery signal only, flagged as authoring defect.

## 3.7 Credential Engine

- **Owns:** credential templates/criteria, issued credentials, revocation lists,
  verification endpoints.
- **Provides:** criteria evaluation, issuance (policy-gated), wallet reads, public
  verification.
- **Consumes:** `competency.mastered`, completion events. **Emits:**
  `badge.awarded`, `credential.issued`, `credential.revoked`.
- **Invariants:** high-stakes issuance is HITL-reserved; issued credentials survive
  commercial state (BOOK-02 Ch. 8.2); formats are standards-compliant (OB 3.0/VC).

## 3.8 Academic GPS Engine

- **Owns:** path scenarios, path-health state, replanning triggers.
- **Provides:** `compute_scenarios(twin, target)`, `evaluate_current_path(twin)`.
- **Consumes:** `competency.updated`, `enrollment.synced`, `grade.synced`, catalog
  changes. **Emits:** `path.replanned`, `graduation.predicted`.
- **Invariants:** deterministic computation with input fingerprints; LLMs narrate,
  never plan (BOOK-00 Ch. 6.2); scenarios are reproducible from fingerprint.

## 3.9 Academic Cognitive Engine (ACE)

- **Owns:** agent registry bindings, routing policy, context budgets, turn/mission
  execution records, proposal queue (HITL).
- **Provides:** `route(user, message, workspace)`, `run_mission(agent, twin,
  mission)`, proposal approve/reject.
- **Consumes:** events as mission triggers. **Emits:** `recommendation.generated`,
  `risk.detected`, agent-proposed events (validated against taxonomy before
  emission).
- **Invariants:** every LLM call via the governed gateway (ADR-0013); agents write
  memory/events only through ACE post-processing; every turn is traceable
  (BOOK-00 Ch. 6.2 #6). Detailed in BOOK-09/10/11.

## 3.10 Event Mesh

Specified in Chapter 4. **Owns:** the taxonomy, the outbox, delivery. It is an
engine (not mere infrastructure) because the taxonomy is academic state: it defines
what can officially *happen* in the university.

---

# Chapter 4 — Event Mesh Specification

## 4.1 Semantics

- **Delivery:** at-least-once; consumers MUST be idempotent (dedupe on `event_id`).
- **Ordering:** guaranteed per aggregate (per-stream partial order), not global.
- **Atomicity:** transactional outbox — the event row commits with the state
  change; a relay publishes to the stream (reference: 2s cadence).
- **Retention:** streams retain ≥ 7 days for replay; the outbox table is the
  permanent event log (audit-grade).

## 4.2 Envelope (normative, from the Student Experience constitution)

```json
{
  "event_id": "uuid",
  "event_type": "competency.mastered",
  "occurred_at": "ISO-8601",
  "tenant_id": "uuid",
  "actor": {"user_id": "uuid", "kind": "student|agent|system|staff"},
  "aggregate": {"type": "…", "id": "…"},
  "payload": {},
  "trace_id": "otel-trace-id"
}
```

`trace_id` is mandatory: every event joins the distributed trace of its causal
request (observability, Ch. 8).

## 4.3 Taxonomy governance

The taxonomy is **closed** (BOOK-00 Ch. 6.2): the canonical registry lives in the
standard (student-domain set in the Turnkey constitution §7.3; institutional and
authoring domains to be consolidated from `EVENT_CATALOG.md` in BOOK-04). Adding an
event type requires an RFC; consumers MUST reject unknown types (fail loud).

## 4.4 Transport

Reference transport is **Redis Streams** with consumer groups per service
(ADR-0010): per-tenant stream keys, restart-safe consumers. The transport is
swappable (Kafka for high-volume deployments) behind the outbox+consumer contract;
nothing above the mesh may depend on transport specifics. The n8n bridge is one
consumer group among others — external workflow automation gets no privileged path.

---

# Chapter 5 — Tenancy and Isolation

Adopted from the running Turnkey model, **verified against the implementation**
(`models_platform.Tenant`, `models_tenant.py`, `tenant_session.py`,
`tenant_context.py` middleware, `tenant_provisioning.py`):

## 5.1 The tenant aggregate

`platform.tenants` (GUID PK) carries: `subdomain` (unique — the primary routing
key), organization identity, `country` (residency input), `status` lifecycle
(create → active → suspended → deleted → permanently deleted), **commercial
`tier`** (`free | creator | creator_plus | creator_lms | business | enterprise`)
and four JSON policy bags: `config`, `branding`, `features`, `limits`.

Two orthogonal classification axes MUST NOT be conflated:

- **`Tenant.tier`** — commercial capacity/entitlements (quota seeds, feature flags);
- **`Institution.institution_type`** — governance profile (`university`,
  `high_school`, `enterprise`, `reseller`; BOOK-02 Ch. 7). `Institution` is a
  strict 1:1 extension of `Tenant` (unique FK, CASCADE) — a tenant may exist
  without an institution (pure authoring customer), never the reverse.

## 5.2 Isolation mechanics (as implemented)

| Concern | Mechanism |
|---------|-----------|
| Data isolation | PostgreSQL: shared `platform` schema + `tenant_{uuid}` schema per tenant. Per transaction: `SET LOCAL search_path TO "{tenant_schema}", platform, public` + `SET LOCAL app.tenant_id = '{id}'` (RLS session variable) — transaction-local, connection-pool safe |
| Tenant resolution | ordered: (1) subdomain from `Host` header (+ `CustomDomain` table for vanity domains), (2) `X-Tenant-ID` header (canonical) / `tenant_id` (legacy alias); resolved context cached in Redis |
| Exemptions | explicit `EXEMPT_PATHS`, including **driver callbacks that legitimately arrive tenant-less** — LTI 1.3 registration, Caliper events from Moodle, Frappe/ERPNext webhooks — which MUST resolve tenant from payload/registration instead |
| Identity | Keycloak **realm per institution** (`university-{slug}`); kernel trusts OIDC claims, owns roles/consent (Ch. 3.1) |
| Graph isolation | shared definition tier; student overlay nodes/relations carry `tenant_id`, always filtered |
| Event isolation | per-tenant stream keys |
| AI isolation | per-tenant gateway virtual keys, quotas and budgets (seeded from `tier` limits) |
| Provisioning | `TenantProvisioningService`: schema creation, admin seeding, tier config, Redis cache; suspend/delete/purge lifecycle |

## 5.3 The identity duality (declared constraint)

The implementation carries **two user populations**, and the standard must be
honest about it:

- `platform.users` — GUID PK, shared schema (platform-level identity);
- tenant-schema `users` (`TenantUser`) — **BigInteger PK**, per-tenant profile
  (roles array, SSO-nullable password), plus tenant-schema `courses`
  (`TenantCourse`, BigInteger) alongside the legacy Integer course family.

Normative consequences:

1. Kernel contracts (Twin, Evidence, Competency) bind to the **platform GUID
   identity**; tenant-local user rows are profile projections, never the identity
   anchor.
2. The GUID↔legacy-integer mapping lives in exactly one service
   (`identity_map`, per the Student Experience constitution §13.4) — the tenancy
   model must not multiply reconciliation points.
3. New kernel tables MUST NOT introduce further key families (UUID only;
   Integer/BigInteger contained as legacy).

## 5.4 Rules

Platform-schema entities use UUID keys; legacy Integer/BigInteger families are
contained and never extended; cross-tenant queries exist only in the Platform
Operator plane, audited. **Known model gap:** no `parent_tenant_id` exists —
the reseller/consortium archetype (BOOK-02 Ch. 7) currently has no tenant
hierarchy; until an RFC adds one, reseller relationships are policy objects
(BOOK-02 Ch. 10), not structural links.

---

# Chapter 6 — Drivers: the Integration Fabric

External systems attach as **drivers**: adapters with a declared ownership
boundary (BOOK-00 Annex A.2 data ownership map), an event contract, and no reach
into kernel internals.

| Driver | System of record for | Direction | Mechanism |
|--------|---------------------|-----------|-----------|
| Identity (Keycloak) | credentials, SSO, OIDC/SAML federation | inbound tokens | OIDC; kernel trusts claims, owns roles/consent |
| Student records (ERPNext Education) | official enrollment, grades, transcripts, finance | bidirectional via events | n8n workflows ↔ mesh bridge; kernel mirrors read-only (ADR-0009) |
| CRM (Frappe) | prospects, applications, engagement campaigns | inbound events | P01 front-of-funnel |
| Delivery LMS (Moodle) | course delivery experience, forums | outbound content (SCORM/LTI), inbound xAPI/completion | Learning Engine bindings |
| Payments (Stripe) | money movement | inbound status events | financial access control middleware; never touches evidence |
| Media (HeyGen, TTS, image) | generated media artifacts | outbound jobs, webhook callbacks | signed callbacks (HMAC) |
| API edge (Kong) | routing, rate limiting, edge authn | — | fronting all applications |

Driver rules (normative):

1. A driver failure degrades its capability visibly; it MUST NOT cascade into
   kernel unavailability (bulkhead + circuit breaker per driver).
2. Inbound driver data enters as **events with source attribution**, lands in
   mirror tables, and is never written into kernel-owned aggregates directly.
3. Webhook endpoints authenticate via shared-secret HMAC and are idempotent.
4. New drivers require: ownership-map row, event contract, failure-mode statement.

---

# Chapter 7 — The AI Substrate

The LLM gateway (LiteLLM in the reference implementation) is **infrastructure
beneath the kernel**, not an engine: engines and agents consume it; it owns no
academic state.

- Multi-provider routing, fallback chains, per-tenant virtual keys, synchronous
  pre-call quota enforcement, idempotent usage callbacks (ACP Gateway architecture
  — running today, ✅).
- Normative: **no kernel component holds provider credentials**; model/prompt/
  corpus changes affecting learner-facing behaviour are governed releases (BOOK-00
  Ch. 11); cost attribution per engine and process area (BOOK-02 Ch. 8.1).
- Local-model fallback is an availability *and* economic control; the gateway
  contract MUST allow routing any agent to local inference without agent changes.

---

# Chapter 8 — Non-Functional Envelope

Reference targets (institutions calibrate; presence of budgets is normative):

| Property | Target | Notes |
|----------|--------|-------|
| Availability — kernel APIs | 99.9% | learner-facing reads degrade gracefully (cached twin context) |
| Availability — verification endpoint | 99.95% | credential trust depends on it (BOOK-02 scorecard) |
| Latency — kernel reads | p95 < 300 ms | twin context assembly cached per (twin, layer, version) |
| Latency — agent first token | p95 < 3 s | streaming mandatory for conversational turns |
| Event propagation | p95 < 5 s state-change → consumer effect | outbox relay + consumer lag SLO |
| GPS recompute | < 60 s async | never inline in request path |
| Scale unit | tenant | schema-per-tenant shards naturally; hot tenants isolable |
| Durability | evidence & outbox: no loss (RPO 0 for committed transactions) | backup + PITR |
| Data residency | region-pinned per tenant | dual-region posture (compliance doc); twin data never leaves region |
| Observability | traces (OTel), metrics (Prometheus), logs (Loki), traces store (Tempo), dashboards (Grafana) — running today | `trace_id` flows request → event → consumer → agent turn |
| Capacity guard | AI quota exhaustion degrades visibly (BOOK-02 Ch. 8.3) | never silent |

Security posture is specified in BOOK-19; binding here: zero-trust service-to-service
(authenticated calls everywhere), secrets in env/vault never in DB, audit-grade
logging on every kernel mutation.

---

# Chapter 9 — Runtime Topology (reference implementation)

The Turnkey compose topology realizes the AOS as:

```text
Edge:        kong (API gateway) · portal (Next.js) · moodle-web
Kernel svc:  dlu-builder (FastAPI, async) · worker (Celery, sync) · dlu-badge
State:       postgres (platform + tenant schemas) · neo4j (knowledge) · redis (cache/streams/broker)
Identity:    keycloak
Records/CRM: frappe-* stack (ERPNext Education + CRM: backend, queues, scheduler, websocket)
Automation:  n8n (driver workflows)
AI substrate: gateway (LiteLLM)
Observability: otel-collector · prometheus · loki · tempo · grafana
```

Binding conventions (from Turnkey CLAUDE.md, unchanged): API routes async
(`AsyncSession`), workers sync (`asyncio.run` to reach async services), additive
migrations with tested downgrades, soft delete on principal entities.

---

# Chapter 10 — DAS-Core Conformance Checklist

An implementation claims **DAS-Core** (BOOK-00) when:

1. The five layers exist with rules of Ch. 2 enforced (no experience-owned state).
2. All ten engine contracts of Ch. 3 are implemented with their invariants
   testable and tested.
3. The Event Mesh implements outbox atomicity, at-least-once delivery, idempotent
   consumers, closed taxonomy (Ch. 4).
4. Tenancy isolation per Ch. 5 holds under test (cross-tenant leakage tests).
5. Drivers respect ownership boundaries and bulkheads (Ch. 6).
6. All model access flows through the governed gateway (Ch. 7).
7. Non-functional budgets exist, are measured, and alert (Ch. 8).

BOOK-20 turns this checklist into acceptance tests.

---

# Annex A — Turnkey Baseline Mapping (normative)

Status legend as in BOOK-00 Annex A.

| AOS element | Turnkey asset | Status | Gap |
|-------------|--------------|--------|-----|
| Layered runtime & edge | compose topologies (turnkey/production/regional), Kong, portal | ✅ | layer-skip enforcement is convention, not tooling 🟡 |
| Engine boundary | services exist but grouped by feature, not by engine (`backend/services/*`) | 🟡 | kernel boundary rationalization — BOOK-18 refactoring map |
| Twin Engine | `LearnerProfile`, tutor context; STX-01/02 design | 🔵 | per constitution |
| Knowledge Engine | Neo4j + kg services + GraphRAG, fire-and-forget sync | ✅ | v1.2 overlay 🔵 |
| Competency Engine | institution models + STX-04 design | 🟡/🔵 | per constitution |
| Learning Engine | course factory, media pipeline, pacing, SCORM/LTI, Moodle sync | ✅ | outcome-first enforcement 🟡 |
| Assessment Engine | quiz/lab/grading/xAPI/Caliper | 🟡 | evidence pipeline 🔵 (STX-08) |
| Credential Engine | credential service, badges | 🟡 | OB 3.0/wallet 🔵 (STX-13) |
| GPS Engine | eta/curriculum-graph/prerequisite services | 🔵 | STX-07/12 |
| ACE | agent orchestrator + AI Management registry | 🟡 | Brain routing layer 🔵 (STX-06) |
| Event Mesh | `domain_events` outbox + Redis Streams relay + closed taxonomy (`event_taxonomy.py`) + 5 consumer groups w/ idempotency, DLQ, lag metric — **STX-03 delivered 2026-07-14**; legacy `EventService` dual-publishes (strangler) | ✅ | legacy EventService retirement after parity window 🟡; kg-sync/reco/success-watch handlers 🔵 (STX-04/05) |
| Tenancy | schema-per-tenant + `SET LOCAL search_path`/RLS (`tenant_session.py`) + subdomain/header resolution + provisioning + tier limits | ✅ | reseller tenant hierarchy ⚪ (RFC); identity duality reconciled ✅ (STX-01, ADR-0014, `identity_map`) |
| Drivers | Keycloak, ERPNext/n8n, Moodle, Stripe, HeyGen (HMAC callbacks), Kong | ✅ | per-driver bulkhead/circuit-breaker audit 🟡 |
| AI substrate | ACP Gateway (LiteLLM): virtual keys, quotas, fallback chains, usage callback + **per-engine/process-area cost attribution ✅ (NEW-14, 2026-08-01: `cost_attribution_service.py` static mapping over `LlmUsageLog.service_type` — BOOK-00 Ch. 6.1's real ten engines, not this Book's own Ch. 6.2 "AI substrate" cross-cutting label re-used as an 11th; unmapped `service_type` is an alertable governance defect, never a silent default)** | ✅ | — |
| Observability | OTel + Prometheus + Loki + Tempo + Grafana stack | ✅ | trace_id propagation through events ✅ (STX-03: outbox captures trace_id, consumer spans link to producer trace) |
| Conformance tests | pytest markers, release gates | 🟡 | DAS-Core acceptance suite ⚪ (BOOK-20) |

**Migration priority:** the Event Mesh upgrade (STX-03) unlocks Twin sync, KG
overlay, GPS invalidation and trace propagation — it SHOULD precede all other
kernel work, exactly as sequenced in the Student Experience constitution Phase 1.

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Driver | Adapter to an external system of record with declared ownership boundary and failure mode |
| Composition service | Stateless multi-engine coordinator persisting its progress as events |
| Transactional outbox | Event row committed atomically with the state change, relayed to the stream |
| Mirror table | Kernel-side read-only copy of driver-owned data, with source and sync metadata |
| AI substrate | The governed model-access layer beneath the kernel (gateway, routing, quotas) |
| DAS-Core checklist | The seven conformance criteria of Ch. 10 |

---

*BOOK-03 v1.0 — awaiting review. Next per dependency order: BOOK-04 (Academic
Domain Model).*
