# BOOK-18 — Technical Architecture & Turnkey Integration
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The bridge Book. Everything the standard prescribes must land in
> `dlu_builder_tk` — descriptively where it already runs, prescriptively where
> it doesn't (ADR-0008: brownfield-first, rationalize don't rewrite). This Book
> delivers: the **engine → code mapping**, the **driver catalog with contracts**
> (including the dedicated **ESSE3 driver** — the Italian deployment keystone —
> plus PagoPA and QES from the G-register), the **refactoring map** closing the
> structural anomalies (A2/A5/A7 + engine boundaries), the deployment
> architecture, and the **master gap consolidation** that BOOK-20 turns into
> sprints.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** all Books (it maps them).
> **Informs:** BOOK-20 (sprint decomposition).
> **Primary audience:** engineers, platform ops, integration teams.

**Normative language:** RFC 2119. Engineering guardrails of `dlu_builder_tk/
CLAUDE.md` (PK families, async/sync split, additive migrations, EXEMPT_PATHS
discipline, soft delete) apply unchanged and are not restated.

---

# Chapter 1 — Doctrine: Rationalize, Don't Rewrite

1. **Strangler-fig discipline:** new kernel contracts wrap existing services;
   old paths retire only after shadow-parallel validation (the ACP-GW-06
   cutover pattern is the house method).
2. **The keystone first:** the Event Mesh upgrade (STX-03: outbox + Streams +
   closed taxonomy) unblocks twin sync, KG overlay, GPS invalidation, trace
   propagation — it precedes all other kernel work (BOOK-03 Annex A).
3. **Every change lands additive** (columns, tables, services); the single
   sanctioned drop is the A1 staging sunset S4, governance-approved (BOOK-13).
4. **Docs are part of the change set** (BOOK-00 sync rule): constitution and
   CLAUDE.md cross-references update with the code.

---

# Chapter 2 — Engine → Code Mapping (as-is → to-be)

| Engine (BOOK-03) | Running assets (models · services · routes) | To-be (target package) | Status |
|------------------|---------------------------------------------|------------------------|--------|
| Identity | `models.py:User`, `models_auth.py` · auth/oidc/saml/rbac services · auth routes | `kernel/identity/` | ✅ wrap |
| Twin | `LearnerProfile` · `tutor_context_service` · learner routes | `kernel/twin/` + `models_student_twin.py` (STX-01/02) | 🔵 |
| Knowledge | KG models(A1 staging) · kg_* services, GraphRAG, embeddings · KG routes | `kernel/knowledge/` | ✅ + v2.0 🔵 |
| Competency | `models_institution.py` (Competency, CLOCompetency) · competency services · routes | `kernel/competency/` + `models_competency_graph.py` (STX-04) | 🟡 |
| Learning | course family models · factory/media/pacing/exchange services · course routes | `kernel/learning/` | ✅ wrap |
| Assessment | quiz/lab/xapi/caliper models · grading/bloom/feedback services · routes | `kernel/assessment/` + evidence service (STX-08) + G2/G5/G6 aggregates | 🟡 |
| Credential | `CourseAchievement`, `UserBadge` · `credential_service`, **dlu-badge svc** · credentials/badges routes | `kernel/credential/` + templates/wallet (STX-13) + signing ⚪ | 🟡 |
| GPS | — · `eta/curriculum_graph/prerequisite` services | `kernel/gps/` (STX-07/12) + RouteGraph compiler ⚪ | 🔵 |
| ACE | `models_agent.py` · `agent_orchestrator_service` | `kernel/ace/` (STX-06) + PDDAEL/moves ⚪ | 🟡 |
| Event Mesh | `EventService`, `kg_event_bus`, Redis pub/sub | `kernel/mesh/` — outbox + Streams (STX-03) | 🟡→🔵 |
| ACP substrate | `models_ai/llm` · gateway services, LLMClientFactory · ai_management routes | stays `platform/acp/` (beneath kernel) | ✅ |

**Package rule:** `backend/kernel/{engine}/` becomes the home of contract
implementations; existing services are *moved or façaded*, imports updated
mechanically; route files keep their public prefixes (no API breaking).

---

# Chapter 3 — Driver Catalog (contract per driver)

Contract fields: *ownership (data it is SoR for) · auth · inbound (events/data
into DLU) · outbound (from DLU) · mirror tables · failure mode · status*.

| Driver | Ownership | Auth | Inbound | Outbound | Failure mode | Status |
|--------|-----------|------|---------|----------|--------------|--------|
| **Keycloak** | credentials, SSO sessions | OIDC | tokens/claims | user provisioning (n8n) | auth degraded → read-only public surfaces | ✅ |
| **ERPNext Education/Finance** | official records, enrollment, grades, invoices (non-Italian profile) | API keys via n8n | `enrollment.synced`, `grade.synced`, financial status | institution/program/outcomes push, credential records | mirror staleness surfaced (`synced_at`) | ✅ arch |
| **ESSE3** (Italian profile) | official records, appelli, verbali, ANS | REST WS (API keys, technical-user groups) + Gateway notifications (HMAC-SHA256) + replica/boundary tables | Ch. 4 event map | Ch. 4 | breaker (real `CircuitBreaker`, first landing) + `pending_verbalization` semantics; health panel `GET /health/esse3` | ✅ **NEW-11, 2026-07-29** |
| **Frappe CRM** | prospects, applications, campaigns | webhooks (tenant-resolved from payload — EXEMPT path exists) | lead/application events | engagement reads | funnel-only impact | ✅ |
| **Moodle** | delivery experience, forums | LTI 1.3, SCORM, webhooks | xAPI/Caliper, completion | content sync (Mode A/B) | delivery continues; sync queues | ✅ |
| **n8n** | (broker, not SoR) | internal | workflow-mediated events | same | per-workflow retry queues | ✅ |
| **Stripe** | money movement | signed webhooks | payment/refund status | checkout sessions | financial-status cache holds last-known | ✅ |
| **PagoPA** (G9, Italian) | public-sector payments (stamp duty, fees) | OAuth2 client-credentials + HMAC-SHA256 webhook | payment-outcome notifications | payment-position creation | cache-only status read (never live); document issuance blocks on unpaid bollo, visibly | ✅ **NEW-12, 2026-07-30** |
| **QES provider** (G3, where not ESSE3) | qualified signatures, legal preservation | OAuth2 client-credentials + HMAC-SHA256 webhook | signature-completion notifications | signature requests (verbali, Diploma Supplement seal) | breaker (shared `CircuitBreaker`) + best-effort submission — a provider outage degrades visibly, never blocks the DS/verdict it seals | ✅ **NEW-12, 2026-07-30** |
| **HeyGen / media** | generated media artifacts | HMAC webhooks | render completion | render jobs | enrichment degrades, courses ship | ✅ |
| **Kong** | edge routing/limits | — | — | — | platform-down class | ✅ |

Driver rules of BOOK-03 Ch. 6 bind all rows (bulkheads, events-with-source,
idempotent HMAC webhooks, ownership-map row per driver).

---

# Chapter 4 — The ESSE3 Driver Contract (Italian deployment keystone)

## 4.1 Integration modes (per CINECA's actual surfaces)

| Mode | ESSE3 surface | DLU use |
|------|--------------|---------|
| M-A REST | ESSE3 REST web services (API-key, technical-user groups) | on-demand reads (career, libretto, appelli calendars) + writes where sanctioned (session enrollment relay) |
| M-B Notifications | ESSE3 **Gateway** module (notification-driven adapters) | event-driven sync: career events, verbalization completion → mesh events |
| M-C Replica | replica/boundary tables (ODS-style) | bulk mirror refresh + G8 completeness monitor reconciliation |

Reference profile: **M-B primary** (event-driven, matches the mesh), M-A for
interactive flows, M-C nightly for reconciliation/drift detection.

## 4.2 Event mapping (driver adapter → DLU mesh)

| ESSE3 fact | DLU event | Consumers |
|-----------|-----------|-----------|
| immatricolazione / iscrizione anno | `enrollment.synced` | twin L2, GPS |
| piano di studi approvato | `enrollment.synced` (plan payload) | GPS (regulation-year binding, G7) |
| appello pubblicato/modificato | `assessment_session.published/changed` | BOOK-15 mirror mode, GPS SIT_EXAM edges |
| iscrizione appello (student) | session enrollment mirror | WS06 |
| verbale firmato (grade legal act) | `grade.synced` (verbale ref attached) | evidence pipeline, `pending_verbalization` close |
| conseguimento titolo | degree-recorded event | Credential Engine (portable degree issuance gate, BOOK-16 Ch. 4.4) |
| ANS spedizione outcomes | completeness signals | BOOK-08 §6.3 monitor |

## 4.3 Profile rules

1. In the Italian profile, ESSE3 occupies the **student-records slot** of
   ADR-0009; ERPNext MAY remain for finance/HR or be absent — the ownership map
   is per-tenant configuration, not code.
2. DLU never writes official records into ESSE3 except via sanctioned M-A
   endpoints (e.g., relaying a learner's appello enrollment) — and each such
   write is idempotent and audit-paired.
3. Verbalization and preservation stay ESSE3-side (G3 doctrine, BOOK-16 Ch. 8);
   the adapter attaches verbale references to DLU evidence records.
4. The adapter is a standalone worker (`backend/drivers/esse3/`) with its own
   boundary tables, circuit breaker and health panel (I4).

---

# Chapter 5 — Refactoring Map (structural anomaly closures)

| Item | Action | Anomaly |
|------|--------|---------|
| `identity_map` service | single GUID↔Integer/BigInteger reconciliation point; Option A dual-write on `concept_mastery` (additive `user_guid` + backfill) | A2/A5 (STX-01) |
| `TenantUser`/`TenantCourse` demotion | freeze writers; document as projections; migration of remaining readers to platform anchors | A2/A3 |
| `models.py` split | mechanical split along BOOK-04 contexts (C1/C5/C6/C8 files) — imports façaded, zero schema change | A5 hygiene |
| Enrollment naming | local delivery-state renamed distinctly from official mirror (code + docs) | A7 |
| Event catalog unification | `EVENT_CATALOG.md` superseded by taxonomy registry at STX-03; nouns linted vs `dlu-core.yaml` | A6 |
| KG staging sunset | S1–S4 plan (BOOK-13 Ch. 10) | A1 |
| Graph renames | v2.0 Cypher migration + one-release aliases | A8/A9 |
| Engine packages | Ch. 2 to-be layout; move-or-façade, prefix-stable | — |

Sequencing: `identity_map` and mesh (STX-01/03) first; splits and demotions
ride behind them as mechanical PRs; graph v2.0 with STX-05.

---

# Chapter 6 — Deployment Architecture

1. **Topologies (running):** dev / staging / turnkey (full stack incl. Frappe,
   Moodle, n8n, observability) / production / **regional** (dual-region,
   compliance doc) — compose-based today; the topology set is the conformance
   unit, orchestrator (k8s) migration is an ops choice not an architecture
   change.
2. **Profiles:** Italian profile adds `esse3-adapter` (+ optional PagoPA/QES
   adapters) and MAY drop ERPNext-Education; corporate profile drops
   Moodle/CRM. Profiles are compose overlays + tenant ownership-map config.
3. **DR & backups:** PG PITR (RPO 0 committed — BOOK-03 Ch. 8), Neo4j
   `kg-rebuild` (BOOK-13 Ch. 8.4, measured), Redis streams replay ≥ 7 days,
   media storage versioned; quarterly DR exercise is a conformance requirement.
4. **Secrets:** env/vault only (never DB — running rule); the Key inventory
   extends CLAUDE.md §13 with: `ESSE3_API_KEY/ESSE3_GATEWAY_SECRET`,
   `PAGOPA_*`, `QES_PROVIDER_*`, `ISSUER_DID_KEY_REF` (KMS pointer — BOOK-16
   signing).
5. **Observability:** OTel end-to-end with `trace_id` through mesh events
   (rides STX-03); per-driver health panels; DAS-Core dashboards (Ch. 8 gaps
   feed Grafana).

---

# Chapter 7 — Master Gap Consolidation (feeds BOOK-20)

All 🔵/⚪ items from Books 03–17 Annexes, deduplicated and phased. (STX-nn =
constitution sprints; NEW-nn = added by the Masterbook.)

## Phase K1 — Kernel foundation
STX-01 twin core + identity_map (A2/A5) · STX-02 TwinContextService (+purpose
audit, entitlements) · **STX-03 Event Mesh (keystone)** · STX-04 competency
graph + CASE mapping · STX-05 KG v2.0 (A8/A9 aliases, overlay, staging S1)

## Phase K2 — Cognition
STX-06 ACE/PDDAEL + Discovery + companion UI (one-voice, "why?") · NEW-01
move catalog binding + `move_bindings` ALTER (BOOK-10) · NEW-02 scenario bank
+ eval harness + crisis protocol (BOOK-11 — **gates all agent deploys**) ·
NEW-03 memory stores M2/M3 lineage + consolidation missions (BOOK-12)

## Phase K3 — Navigation & evidence
STX-07 GPS core + WS01 · NEW-04 RouteGraph compiler + SIT_EXAM/RETAKE edges ·
STX-08 evidence pipeline · NEW-05 AssessmentSession aggregate (G2, native+mirror)
· STX-09/10/11 reco v2, Tutor/Coach, Assessment agent + WS03–06 · STX-12
recognition + GPS scenarios 2–4 + WS02 · NEW-06 Thesis + Committee aggregates
(G5/G6)

## Phase K4 — Trust & institution
STX-13 credential templates/wallet/verify + **NEW-07 signing (did:web + Data
Integrity) + status-list** · NEW-08 document credentials: DS generator (G10),
self-cert (G9), clearance flow (G11) · STX-14 behaviour + Success + WS08 ·
STX-15 Career + hardening · NEW-09 faculty workspaces FW2/FW3/FW5 (G1/G4,
envelopes) · NEW-10 institution twin I2/I3/I5 composites + IW surfaces

## Phase K5 — Profiles & compliance
NEW-11 **ESSE3 driver** (Ch. 4) + Italian profile overlay · NEW-12 PagoPA +
QES adapters · NEW-13 AI Act register + compliance calendar (BOOK-19) ·
NEW-14 per-engine cost attribution + three-economy indicators · NEW-15
DAS-Core conformance suite + DR exercise automation (BOOK-20)

---

# Chapter 8 — DAS-Core Conformance Snapshot (BOOK-03 Ch. 10 vs today)

**Updated (NEW-15, 2026-08-02) — this snapshot originally predated any K1–K5
sprint execution; K1 through K5 are now all executed. Current, verified
status per-criterion lives in BOOK-20 §8.1/§8.2/§8.3 (the meta-test
`test_ch8_criteria_have_executable_checks.py` confirms every criterion
below has ≥1 discoverable executable check) — reproduced here so this
snapshot doesn't drift from that authoritative source again:**

| Criterion | Status |
|-----------|--------|
| 1 Layers & no experience-owned state | ✅ pre-existing CI gates (`check_kg_staging_reads.sh` + siblings) |
| 2 Ten engine contracts | ✅ pre-existing contract tests (`check_evidence_sole_writer.sh` + siblings) |
| 3 Mesh (outbox, idempotent, closed taxonomy) | ✅ STX-03, permanent V1–V5 suite |
| 4 Tenancy isolation tested | 🟡 API/graph/streams closed (K4, NEW-15 — the graph closure also fixed a real, previously-undiscovered Course/Lesson/Concept node-identity vulnerability); cache dimension still open |
| 5 Driver bulkheads | 🟡 most drivers covered; real circuit breaker only landed at NEW-11 (ESSE3/PagoPA/QES); Moodle/Frappe/Stripe/Keycloak/n8n chaos coverage still open |
| 6 Gateway-only model access | ✅ `check_gateway_only_egress.sh` |
| 7 NFR budgets measured | ✅ NEW-15 — 4 DAS-specific Grafana panels + pinning test |

Honest reading (updated): **DAS-Core and DAS-Intelligent are both reached**
(K3/K4 exit gates, BOOK-20 §8.1/§8.2). **DAS-Certified is auditable but
NOT declared achieved** — every criterion that can be code-complete is
(AI Act register, hash-chained audit fabric, regulatory profile suites, a
DR exercise on record, all NEW-11–NEW-15); the external audit itself
(§8.3's own text) cannot be code-complete by definition — it needs an
actual human auditor, which remains an open ops/compliance action, not a
code gap. See `implementation/roocode/K5/K5-EXIT-REPORT.md` for the full
itemized residual-debt table (erasure e2e, KPI scorecards, agent GA
gating, and the cache-dimension tenancy fuzz all remain genuinely open
too).

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Strangler-fig discipline | Wrap-shadow-retire migration method (house pattern from the gateway cutover) |
| Deployment profile | Compose overlay + ownership-map config (Italian, corporate, greenfield) |
| Boundary tables | Driver-side staging for replica/import integration (ESSE3 M-C) |
| Move-or-façade | Refactoring rule: relocate code or front it, never fork it |
| Master gap table | Ch. 7 consolidation — the single backlog source for BOOK-20 |
| Phase K1–K5 | The five technical phases from kernel foundation to certified profiles |

---

*BOOK-18 v1.0 — awaiting review. G-register: all technical landings assigned
(G2/G5/G6→K3, G9/G10/G11→K4, G3/G8+ESSE3→K5). Next: BOOK-19 (Governance,
Security & Compliance) and BOOK-20 (Implementation Blueprint) to close the
Masterbook.*

**Sources (ESSE3 integration surfaces):**
[CINECA Technical Portal — Servizi REST su ESSE3](https://wiki.u-gov.it/confluence/display/ESSE3/Servizi+REST+su+ESSE3) ·
[CINECA Technical Portal — GATEWAY: Repliche e Import](https://wiki.u-gov.it/confluence/display/ESSE3/GATEWAY+-+Repliche+e+Import)
