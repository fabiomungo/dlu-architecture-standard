# Changelog

## Unreleased

- **K2 prompt pack generated** (2026-07-16, post K1 exit gate):
  `implementation/roocode/K2/` — README (order: NEW-01 → STX-06 → NEW-03,
  NEW-02 in parallel as the GA gate; exit gate per TRACEABILITY K2 row) +
  self-contained prompts NEW-01 (move catalog binding, BOOK-09 Ch. 3 /
  BOOK-10 Ch. 2), STX-06 (PDDAEL runtime + one voice + Discovery + WS00
  triad, BOOK-09 / BOOK-17), NEW-02 (scenario bank + 3 grader tiers +
  lifecycle gate + crisis protocol zero-tolerance, BOOK-11 Ch. 5–6),
  NEW-03 (M1–M4 memory stores + consolidation R8 + consent amnesia,
  BOOK-12). Combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K2_PROMPTS.md`.
  Implementation may begin with NEW-01 (‖ NEW-02).

- **STX-05 executed — K1 COMPLETE** (2026-07-16, `dlu_builder_tk`):
  Knowledge Graph v2.0. Idempotent Cypher migration (`make kg-migrate`):
  A8 `REQUIRES`→`NEEDS_ASSET`, A9 →`ALIGNED_TO {strength}` (aliases
  flagged one minor release), v2.0 label constraints, `SchemaMeta` stamp.
  Student overlay via batched `kg-sync` consumers (KNOWS/EVIDENCES,
  DEFER-flush ≤100/pass, ack-after-flush, tenant-scoped). Definition-tier
  Competency/Framework sync (fire-and-forget preserved). **Ontology
  registry seeded**: `architecture/ontology/dlu-core.yaml` + lint in both
  repos' CI; A1-S1 staging gate live. `frontier`/`gap` canonical queries.
  V1–V7 green (incl. live-Neo4j idempotency/parity/tenant-fuzz and
  250-events→≤3-flushes batching). Registers: A1-S1 ✅, A8 ✅, A9 ✅.
  **All five K1 sprints delivered — K1 exit report can be assembled.**

- **STX-04 executed** (2026-07-15, `dlu_builder_tk`): Competency Engine.
  Deterministic §5.3 confidence (`Σ score·weight·recency·trust / Σ weight`)
  with versioned, immutable `competency_engine_params` seeded from BOOK-15
  §4.1; status machine with decay hysteresis → `expired` checkpoint (daily
  beat); `verified` = HITL `verify()` only (ADR-0012, negative-tested);
  `register_evidence` as the single writer entrypoint (STX-08 intake);
  CASE 1.1 idempotent import + round-trip export preview; student rows pin
  `framework_version` (Review M1); `/api/competencies` routes +
  `competencyAPI.js`; all mutations emit `competency.updated/mastered`,
  `evidence.recorded` via the STX-03 outbox. V1–V6 green (8 golden cases
  ≤1e-6). BOOK-04 C4 and BOOK-06 L3 Annex rows → ✅.
  K1 remaining: STX-05.

- **STX-02 executed** (2026-07-14, `dlu_builder_tk`): TwinContextService —
  the single door to student context. Purpose-audited reads, BOOK-06 Ch. 6
  entitlement matrix enforced in code (data-driven, denials audited),
  consent gating (Ch. 9, learner_self bypass per the Open Learner Model),
  per-layer version-keyed Redis cache, immutable `twin_snapshots` on
  lifecycle transitions, `/api/twin` routes (tenant-scoped), tutor context
  adapter with zero regression, `consent.changed` producer wired to the
  STX-03 mesh, twin-sync consumer now routes through
  `bump_version_sync`. V1–V6 green; BOOK-06 Annex A context-service and
  snapshot rows → ✅; constitution §4.4 marked implemented.
  K1 remaining: STX-04, STX-05.

- **STX-03 executed — THE KEYSTONE** (2026-07-14, `dlu_builder_tk`):
  Academic Event Mesh delivered. Transactional outbox `domain_events`
  (migration `20260714_1100`), closed taxonomy consolidating constitution
  §7.3 + BOOK-04 Ch. 7 (41 types, `event_taxonomy.py` — EVENT_CATALOG.md
  superseded for kernel events), Redis Streams relay (2 s beat, ≥7-day
  XTRIM retention), 5 consumer groups with exactly-once side effects,
  XAUTOCLAIM recovery, dead-letter stream and Prometheus lag alerting.
  twin-sync wired (`profile.updated` → twin_version bump); producers:
  mastery.updated, activity.recorded, course.* (governance workflow),
  legacy EventService dual-publish (strangler). OTel trace propagated
  producer → consumer via span links. V1–V7 green; register A6 closed;
  BOOK-03 Annex A Event Mesh row → ✅. Design decisions:
  `dlu_builder_tk/docs/sprint_decisions_20260714_stx03.md`.
  Next: STX-04 and STX-05 unblocked (STX-02 still pending).

- **STX-01 executed** (2026-07-14, `dlu_builder_tk`): Student Twin core
  models + Competency Graph tables + identity reconciliation. **ADR-0014**
  accepted — identity reconciliation Option A (additive `user_guid` +
  backfill + dual-write; mapping exclusively in
  `backend/services/identity_map.py`). Constitution §13.4 marked
  "decided: Option A". V1–V6 green; reconciliation report at
  `dlu_builder_tk/reports/stx01_identity_reconciliation.json` (100%
  matched, 0 orphans). Next: STX-02 (STX-03 may run in parallel).

- **G15** (catalog as legal contract + explorable what-if representation):
  `CatalogEdition` aggregate (04), `simulate_scenarios` GPS mode (14),
  catalog legal document (16 §6.4a), public explorer + FW1 authoring (17),
  sprint **NEW-16** (20); register now G1–G15.
- **K1 prompt pack generated**: `implementation/roocode/K1/` (README +
  STX-01…05 self-contained prompts with V-suites, dependencies, exit gate);
  combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K1_PROMPTS.md`.
  Implementation phase may begin with STX-01 (‖ STX-03).

## 1.0.0-draft (das-v1.0-draft) - 2026-07-14

### The Masterbook — complete

- **BOOK-00 v2.0** — Executive Vision & Manifesto: conformance model
  (DAS-Core/Intelligent/Certified), RFC 2119 normative language, Seven
  Canonical Questions, manifesto principles with tensions, 13 ADRs, expanded
  standards alignment (1EdTech, EU AI Act), Human Institution / Trust &
  Integrity / Viability chapters, full 20-book plan, **Annex A Turnkey
  baseline** (descriptive-where-running doctrine, source-of-content rule).
- **BOOK-01…20 v1.0** — full Masterbook per the BOOK-00 Ch. 16 plan:
  philosophy (01), institution theory (02), AOS (03), domain model (04),
  ontology (05), twin trilogy (06/07/08), AI spine (09/10/11/12),
  knowledge network (13), GPS (14), assessment & evidence (15),
  credentials & trust (16), experiences (17), technical/Turnkey integration
  (18), governance/security/compliance (19), implementation blueprint (20).

### Registers

- **A-register A1–A12** (structural/semantic anomalies) — all declared and
  closed with owners (incl. A8 `REQUIRES` collision, A9 alignment naming,
  A10–A12 FEX v1.3 bindings).
- **G-register G1–G14** (regulatory/functional gaps from ESSE3, ANVUR and US
  accreditation verifications) — all resolved or owned: appelli (G2), thesis
  (G5), committees (G6), regulation-year (G7), ANS/SUA-CdS (G8), certificates
  (G9), Diploma Supplement (G10), clearance (G11), **US RSI (G12)**, identity
  verification (G13), **ANVUR DE/DI telematic regime (G14)**.
- **Sprint set** STX-01…15 + NEW-01…15 in phases K1–K5 with verification
  cards and conformance exit gates (BOOK-20).

### Review & remediation

- **MASTERBOOK-REVIEW v1.0** — independent critical review (completeness,
  internal/external consistency): verdict *approved with reservations*;
  blocking findings **R1** (event-taxonomy registration: session/thesis/
  committee families) and **R2** (G14 DE/DI) **applied**; R4/R5 scheduled
  into K1 scopes.

### Catalog annex

- **BOOK-10A** — AI Workforce, Skills & MCP Catalog: exhaustive phased roster
  (24 agents across student/faculty/institutional/ops domains, 44 typed skills
  in 12 categories, 19 MCP servers internal/generic/external), usage modes
  (scoping, preset classes, quota classes), seeded-to-target mapping for the
  running `ai_university_defaults` (3 MCP servers, 10 skills, 4 agents),
  bilingual and least-privilege doctrines. Prerequisite refinement for the K1
  prompt pack.

- **BOOK-10B** — AI Execution Framework: three-plane model
  (definition/execution/observation), resolution pipeline with `ctx_hash`
  reproducibility token, skill execution engine, MCP integration layer
  (session manifests, server-side entitlements, circuit breakers),
  declarative mission runtime (generalizing the running orchestrator),
  five-tier testing (T1–T5 on mock-LLM/test-endpoints/harness/test-tenant),
  governed deployment with canary/shadow and seconds-scale kill switch, and
  the **unified execution record** (one query = full causal story; learner
  "why?" and auditors read the same records). Explicit ACP reuse-vs-extend
  map — the running control plane is the foundation.

### Apparatus (R3)

- `MASTERBOOK-INDEX.md` — volume map, reading paths, the Five Ideas.
- `TRACEABILITY.md` — G/A/sprint/conformance cross-matrix.
- `GLOSSARY.md` — unified normative glossary (≈130 terms).
- `scripts/sync-masterbook.sh` + `docs/masterbook/` — MkDocs rendering of the
  Masterbook (generated copies; root is source of truth).
- MkDocs nav: Masterbook section wired.

### Cross-repo (sync rule)

- `dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` (Turnkey
  implementation profile) amended in lockstep: A8 prerequisite canonicalization
  (`PREREQUISITE_FOR`), event-taxonomy additions (R1).

## 0.1.0 - 2026-07-12

- Created the initial DLU Architecture Standard repository.
- Added MkDocs Material configuration.
- Added initial manifesto, architecture-standard, reference-architecture and Turnkey sections.
- Added ADR, RFC, workspace and RooCode scaffolding.
