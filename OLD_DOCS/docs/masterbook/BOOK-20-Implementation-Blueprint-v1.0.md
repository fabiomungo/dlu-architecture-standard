# BOOK-20 — Implementation Blueprint
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review · Final volume of the Masterbook

> The Book that makes the other nineteen executable. It consolidates every gap
> the Masterbook identified (constitution sprints STX-01…15, technical items
> NEW-01…15, regulatory register G1–G14) into a **phased sprint catalog with
> verification cards**, defines the **conformance suites** for DAS-Core /
> DAS-Intelligent / DAS-Certified, the **KPI instrumentation plan**, the
> **maturity evidence model**, program risks, and the **execution rules** for
> the AI implementation agents (Claude/RooCode) that will build it.
>
> **Conforms to:** BOOK-00 v2.0. **Consolidates:** all Books.
> **Companion artifacts:** sprint prompt packs generated from Ch. 3–7 into
> `implementation/roocode/` (this repo) and `dlu_builder_tk/docs/` per the
> house prompt-pack pattern.
> **Primary audience:** delivery teams, AI implementation agents, program leads.

**Normative language:** RFC 2119.

---

# Chapter 1 — Method

1. **Source of truth:** this Book's sprint cards are generated from — and MUST
   stay consistent with — the master gap table (BOOK-18 Ch. 7). A sprint not
   traceable to a Book requirement does not exist.
2. **Sprint anatomy (house pattern):** every sprint ships as a self-contained
   prompt with: context refs (Books + code files), deliverables, guardrails
   (CLAUDE.md), verifications **V1…Vn** (executable checks), and a Definition
   of Done. Cards below carry the essentials; full prompts are generated
   per-sprint at execution time.
3. **Strangler-fig always** (BOOK-18 Ch. 1): wrap → shadow → retire; no API
   prefix breaks; additive migrations with tested downgrades.
4. **Gates:** learner-facing agent work cannot deploy before NEW-02 (eval
   harness) exists — **K2 blocks agent GA, not agent development**.
5. **Model assignment** (running CLAUDE.md doctrine): opus-class for
   hard-to-reverse design inside a sprint; sonnet-class for implementation;
   haiku-class for test generation and mechanical refactors.

---

# Chapter 2 — Program Structure

```text
K1 Kernel Foundation ──► K2 Cognition ──► K3 Navigation & Evidence ──► K4 Trust & Institution ──► K5 Profiles & Compliance
   (STX-01..05)            (STX-06, NEW-01..03)   (STX-07..12, NEW-04..06)   (STX-13..15, NEW-07..10)    (NEW-11..15, G12/G13)
        │                        │                       │                          │                         │
   DAS readiness:           agents gated            DAS-Core ✓                DAS-Intelligent ✓         DAS-Certified auditable
```

Alignment: Foundation v1 roadmap Phase 1 ≈ K1–K2 + WS00/WS01 (in K3);
Phase 2 ≈ K3; Phase 3 ≈ K4; Phase 4 rides K5+.
Dependency spine: **STX-03 (mesh) → STX-01/02 (twin) → everything**;
NEW-02 (harness) gates all agent deployments; STX-08 (evidence) gates
credential work.

**Cadence assumption:** cards are sized for 1–2 week sprints of one
implementation agent + reviewer; phases K1–K2 ≈ one quarter, K3 ≈ one
quarter, K4–K5 ≈ one quarter each at single-team pace — parallelizable per
the dependency notes on each card.

---

# Chapter 3 — Phase K1: Kernel Foundation

### STX-01 — Twin core + identity reconciliation
*Refs:* BOOK-06 Ch. 2–3; BOOK-03 §5.3; constitution §4.3/§13.
*Deliver:* `models_student_twin.py` (5 tables) + `models_competency_graph.py`
(3 tables) + migrations `stx_01/02`; `identity_map.py` (Option A: additive
`user_guid` on `concept_mastery`/`mastery_events` + backfill + dual-write).
*Verify:* V1 migrations up/down/up clean · V2 backfill reconciles 100% of
active learners (report artifact) · V3 dual-write proven by parallel-read test
· V4 no schema change to legacy tables beyond additive columns.
*DoD:* CLAUDE.md §13.4 decision recorded as ADR in this repo.

### STX-02 — TwinContextService
*Refs:* BOOK-06 Ch. 5–7; constitution §4.4.
*Deliver:* service with layer assembly, purpose tag (mandatory, audited),
consent gating, per-layer Redis cache keyed on twin_version; tutor-context
adapter (zero regression on `/api/learners/*`); `/api/twin` routes;
lifecycle-transition snapshots.
*Verify:* V1 entitlement matrix enforced (deny + audit test) · V2 consent
degradation returns None + audit · V3 cache busts on version bump · V4
existing tutor-context contract tests green · V5 p95 < 300 ms cached.

### STX-03 — Event Mesh (the keystone)
*Refs:* BOOK-03 Ch. 4; constitution §7.
*Deliver:* `domain_events` outbox + relay (2 s) + Redis Streams consumer
framework (groups: twin-sync, kg-sync, reco, success-watch, n8n-bridge);
envelope with `trace_id`; taxonomy registry (closed set) + validation;
wire existing producers (mastery, xAPI, course workflow).
*Verify:* V1 outbox atomicity (tx rollback drops event) · V2 duplicate
delivery idempotency test **mandatory** · V3 unknown event type rejected loudly
· V4 trace_id propagates producer→consumer in OTel · V5 7-day replay works.

### STX-04 — Competency Engine
*Refs:* BOOK-04 C4; BOOK-01 Ch. 6; BOOK-05 Ch. 7 (CASE).
*Deliver:* `CompetencyGraphService` (confidence formula, golden-case tested;
status transitions; HITL-only `verified`); `/api/competencies` routes;
CASE CFItem→Competency import mapping; framework CRUD.
*Verify:* V1 confidence golden cases (incl. decay, trust weights) · V2
`verified` unreachable by formula (negative test) · V3 CASE import round-trip
· V4 events emitted per taxonomy.

### STX-05 — Knowledge Graph v2.0
*Refs:* BOOK-05 Ch. 5–6; BOOK-13.
*Deliver:* idempotent Cypher migration (new labels/rels, A8 `NEEDS_ASSET`,
A9 `ALIGNED_TO`, alias windows); definition-tier sync handlers; batched
overlay consumers (`KNOWS`/`EVIDENCES`, 100/5 s); staging S1 (no product
reads — grep-audit in CI); `dlu-core.yaml` registry seed + CI lint.
*Verify:* V1 migration idempotent (run twice) · V2 aliases answer both names ·
V3 overlay tenant-filter fuzz test · V4 fire-and-forget: Neo4j down ⇒ API
green · V5 registry lint fails on unregistered label (negative test).

---

# Chapter 4 — Phase K2: Cognition

### STX-06 — ACE + Discovery + Companion
*Refs:* BOOK-09; BOOK-17 Ch. 2/7.
*Deliver:* PDDAEL cycle runtime (trace schema persisted), routing
(`/api/brain/chat` SSE), one-voice composition, proposals queue wiring,
mission runner (Celery), deterministic-only degradation mode; Discovery Agent
(ACP config row + contract card); WS00 UI (triad + memory panel + "why?"
affordance).
*Verify:* V1 every turn produces a complete trace (schema-validated) · V2
gateway-down ⇒ L0/L1 moves still serve · V3 one-voice: multi-agent cycle
renders single response with attribution metadata · V4 "why?" renders
trace-derived explanation · V5 first-token p95 < 3 s streamed.

### NEW-01 — Move catalog binding
*Refs:* BOOK-09 Ch. 3; BOOK-10 Ch. 2.
*Deliver:* `move_bindings`/`entitlements`/`envelope_defaults`/`calibration_ref`
ALTERs on `ai_agent_configs`; move preconditions engine reading diagnosed
state; `refer_to_human`/`abstain` non-disableable (schema constraint).
*Verify:* V1 out-of-binding move blocked + audited · V2 envelope cannot
disable humility moves (negative test) · V3 preconditions read only
LearnerStateAssessment fields.

### NEW-02 — Eval harness + crisis protocol (**gates all agent GA**)
*Refs:* BOOK-11 Ch. 5–6.
*Deliver:* pedagogical scenario bank (min. coverage per Ch. 6.1 classes,
twin fixtures), three grader tiers, gate thresholds wired to ACP
`lifecycle_state` (testing→deployed requires green run), shadow-eval sampler;
**crisis protocol**: ingress detector + warm-handover flow + institutional
pathway config + zero-tolerance gate class; education-specific egress set
(integrity, anti-sycophancy, scaffolding detector).
*Verify:* V1 deployment blocked on any crisis/injection/integrity failure ·
V2 mock-LLM deterministic suite in CI · V3 incident→scenario pipeline
(one added as fixture) · V4 shadow sampler re-scores live cycles.

### NEW-03 — Memory stores
*Refs:* BOOK-12.
*Deliver:* M3 lineage (episode citations, supersession), consolidation
missions (R8, budget-capped), M2 session summaries + twin-scoped vector index,
retrieval assembly at Perceive with budget, learner deletion honored,
cross-learner isolation keying.
*Verify:* V1 supersession preserves lineage · V2 deletion effective next
assembly · V3 cross-learner leakage fuzz (harness scenario) · V4 memory
budget compression triggers.

---

# Chapter 5 — Phase K3: Navigation & Evidence (DAS-Core at exit)

### STX-07 — GPS core + WS01
*Deliver:* `AcademicGPSService` (fastest_path + path-health), `path_scenarios`
persistence with fingerprints, `/api/gps`, ETA bands (`eta_service`), WS01
scenario cards + adoption flow.
*Verify:* V1 fixture-graph snapshot determinism (same fingerprint ⇒ identical
output) · V2 `PREREQUISITE_FOR` ordering property test · V3 recompute < 60 s
async · V4 `path.replanned` only on adoption.

### NEW-04 — RouteGraph compiler + session edges
*Refs:* BOOK-14 Ch. 3/5.
*Deliver:* term-indexed compiler (offerings, policies, G7 regulation-year),
edge taxonomy incl. `SIT_EXAM`/`RETAKE`/`CHALLENGE`/`MILESTONE`, multi-
objective Pareto engine (4 named scenarios ≤ 8 total), hysteresis + traffic
consumers, compilation cache.
*Verify:* V1 constraint violations impossible (property tests: prereq, term,
regulation-year) · V2 Pareto set non-dominated check · V3 hysteresis: minor
event ⇒ no thrash · V4 objective weights inspectable in fingerprint
(sovereignty audit).

### STX-08 — Evidence pipeline
*Deliver:* `AssessmentEvidenceService` (sole writer), alignment-chain mapping,
trust table (versioned), `evidence.recorded` + recompute wiring, evidence
timeline API; unmapped-assessment WARN metric.
*Verify:* V1 quiz attempt ⇒ BKT + evidence + competency event (integration) ·
V2 append-only enforced (update attempt fails) · V3 phase1 mastery tests stay
green · V4 identity via identity_map only (grep gate).

### NEW-05 — AssessmentSession (G2)
*Deliver:* aggregate + calendars + enrollment windows + refusal flow +
minimum-session policy validation; native and mirror modes; WS06 calendar +
readiness surface; GPS edge feed.
*Verify:* V1 refusal: mastery stands, official evidence deferred · V2
min-session violation ⇒ I4 alert · V3 mirror mode ingests external session
fixture · V4 readiness prediction renders with hedging.

### STX-09/10/11 — Recommendations v2 · Tutor+Coach · Assessment agent + WS03–06
*Deliver:* 3-stage reco (rules+KG+narration; explanation_trace mandatory;
serendipity quota; consent degradation); Tutor (R4 symbolic hint ladder,
struggle-zone policy) + Coach (review missions from SM-2) on ACE; Assessment
Agent (Bloom formative, propose-tier summative); WS03 knowledge map, WS04/05/06
triads.
*Verify:* V1 narration cannot alter item set (contract test) · V2 rec without
trace invalid (schema) · V3 hint-ladder state machine tests · V4 review
missions compete equally in slates · V5 harness green per agent (NEW-02 gate).

### STX-12 + NEW-06 — Recognition + full scenarios + Thesis/Committee (G5/G6)
*Deliver:* Recognition Agent (dossier schema, propose) + claim inventory +
yield estimator (similarity + policy + adjudication-history calibration);
GPS scenarios 2–4 + hedged plans; WS02; Thesis aggregate (milestones, process
evidence, deposit, defense) + Committee aggregate (formation, verdicts,
verbalization binding).
*Verify:* V1 claims never auto-verify (HITL negative test) · V2 hedge
activation on rejection fixture · V3 thesis evidence chain → credential
criteria resolvable · V4 committee verdict = trust-1.0 evidence · V5
conflict-of-interest check on formation.

**Exit gate K3: DAS-Core conformance suite green (Ch. 8.1).**

---

# Chapter 6 — Phase K4: Trust & Institution (DAS-Intelligent at exit)

### STX-13 + NEW-07 — Credential engine + signing
*Deliver:* unified templates (dlu-badge lifecycle = governance machine),
criteria engine, issuance tiers + HITL, wallet API + WS07, public verify
endpoint (the EXEMPT exception), **did:web + Data Integrity signing +
status-list revocation**, wallet import → recognition claims.
*Verify:* V1 signed VC verifies offline · V2 revocation reflected in verify
+ status-list · V3 survival tests: suspension/erasure leave credentials valid ·
V4 verify SLO harness (99.95% budget) · V5 imported OB credential becomes
claim candidate.

### NEW-08 — Document credentials (G9/G10/G11)
*Deliver:* DS generator (IT/EN, ELM-encoded), self-certification generator,
transcript/ECTS views, clearance checklist (GPS-fed) + application flow +
IW2 queue.
*Verify:* V1 DS validates against ELM schema · V2 every document field
traces to evidence/mirror source · V3 clearance flips exactly when path-health
requirements green (fixture) · V4 bollo-required docs block visibly without
PagoPA (driver stub).

### NEW-17 — Credit Recognition & Pre-Evaluation (G16) *(added by BOOK-14A)*
*Refs:* BOOK-14A (framework), BOOK-14 Ch. 4, BOOK-15 Ch. 8, BOOK-16.
*Depends:* NEW-16 (editions), NEW-06 (committee for Tier-2), STX-12
(recognition agent/skills).
*Deliver:* `RecognitionRulePack` (IT-CFU seeded per DM 931/2024 + US-SCH
seeded per PLA/CAEL), `CreditPreEvaluation` three-tier flow (instant AI
estimate < 60 s with confidence bands + non-binding marker → council HITL →
Validated Pre-Evaluation Statement as signed document credential →
conversion at enrollment), `EquivalenceRule` precedent memory,
`BadgeCreditRule` auto-convalida (Bestr→ESSE3 pattern on dlu-badge),
`ExternalSyllabusRecord` + historic-syllabus public endpoint, taxonomy
amendment (`preevaluation.*`, `credential.recognized` — RFC-first).
*Verify:* V1 rule-pack golden cases (IT fractions/caps/obsolescence/year
placement; US grades/exclusions/residency) · V2 Tier-1 e2e < 60 s on fixture
dossier · V3 estimate→validation→conversion chain, precedent recorded ·
V4 signed-badge auto-convalida round-trip, zero manual steps · V5 anti-gaming
(rate limit + altered-document flag) · V6 no hard-coded jurisdiction
parameters outside packs (grep gate).

### NEW-16 — Catalog Edition & Explorer (G15)
*Refs:* BOOK-04 C3 (CatalogEdition), BOOK-14 Ch. 9 (`simulate_scenarios`),
BOOK-16 §6.4a, BOOK-17 (explorer + FW1).
*Deliver:* CatalogEdition aggregate (versioned, immutable-once-effective,
edition lineage, cohort binding via G7); legal catalog document generator
(hash-stamped); public catalog explorer with pre-auth what-if simulation
(rate-limited, `simulation=true`, no twin writes); FW1 contribution/
recognition-policy authoring; `dlu-catalog` MCP tools extension
(get_edition, simulate_path).
*Verify:* V1 effective edition immutable (mutation attempt fails; erratum
creates sub-edition with lineage) · V2 enrollment pins its edition; plan
constraints resolve against the pinned edition (G7 fixture) · V3 generated
document reproducible from edition hash · V4 anonymous simulation runs
end-to-end with zero persistence · V5 simulation output marked and excluded
from events/advisor queues.

### STX-14/15 — Behaviour + Success + Career (WS08) + hardening
*Deliver:* nightly behaviour recompute (aggregates only), Success Agent (risk
missions on cognitive budget, human-connection interventions), Career Advisor
(ESCO gap analysis), WS08; load tests, docs, NFR dashboards.
*Verify:* V1 no raw streams in L6 (schema audit) · V2 risk alerts route to
humans (propose) · V3 cognitive-budget equity report generates · V4 NFR
budgets measured + alerting.

### NEW-09/10 — Faculty + Institution surfaces
*Deliver:* FW2 (office hours G1 + generated register G4 + approval mission),
FW3 verification desk, FW5 envelope console (F4 storage + digests + learned-
default proposals); Institution Twin composites (I2 program health, I3
three-economy indicators, I5 posture) + IW1–IW3 surfaces.
*Verify:* V1 register generated from delivery events, human-certified flow ·
V2 envelope change versioned + effective next turn · V3 program-health
drill-down reaches kernel evidence · V4 n≥10 suppression on equity cells.

**Exit gate K4: DAS-Intelligent suite green (Ch. 8.2).**

---

# Chapter 7 — Phase K5: Profiles & Compliance (DAS-Certified auditable)

### NEW-11 — ESSE3 driver + Italian profile
*Deliver:* `backend/drivers/esse3/` adapter (M-B notifications primary, M-A
REST, M-C nightly reconciliation), event map (BOOK-18 §4.2), boundary tables,
circuit breaker + health panel, SPID/CIE Keycloak brokering, Italian compose
overlay.
*Verify:* V1 event-map fixtures round-trip · V2 pending_verbalization closes
on verbale event · V3 adapter down ⇒ mirrors stale-with-notice, kernel green ·
V4 SPID-brokered login e2e (test IdP).

### NEW-12 — PagoPA + QES adapters
*Verify:* payment-gated document flow; signature round-trip with act
cross-reference.

### NEW-13 — Compliance registers + calendar (+ G12/G13/G14)
*Deliver:* AI Act obligation register + FRIA templates; **RSI ledger**
(per course×student instructor-interaction aggregation + zero-touchpoint
alerts); **DE/DI ledger** (per-CFU Didattica Erogativa/Interattiva
classification + under-quota alerts + CEV evidence export — G14, BOOK-19
§5.1); **Identity Verification Policy** artifact + registration disclosure;
ANS completeness monitor; compliance calendar in I5.
*Verify:* V1 RSI ledger reproduces from kernel events (audit fixture) · V2
zero-touchpoint alert fires (fixture) · V3 disclosure rendered at
registration · V4 spedizione pre-check catches seeded incompleteness · V5
DE/DI ledger classifies a fixture course correctly and flags an under-quota
CFU · V6 AI interactions excluded from DI/RSI counts (negative test).

### NEW-14 — Cost attribution + economies
*Deliver:* per-engine/process-area gateway attribution; C_learner computation;
three-economy dashboard feeds.
*Verify:* V1 every gateway call attributed (unattributed = alert) · V2
C_learner reconciles with usage snapshots.

### NEW-15 — Conformance suites + DR automation
*Deliver:* Ch. 8 suites as CI-runnable packs; quarterly DR exercise automation
(kg-rebuild timed, PITR drill); maturity evidence collectors (Ch. 10).
*Verify:* the suites verify themselves — meta-tests that each criterion has
≥ 1 executable check.

---

## 7b. Target-State Program (`_dlu/sprint-plan`, post-K5)

A SEPARATE, 22-sprint executable plan (NEW-17f through NEW-33/NEW-29),
distinct from the K1-K5 blueprint above (which remains "complete through
K5" per §7's own closing line) — it closes new gaps G17-G21 (Admissions/
BOOK-21, Credit Pre-Evaluation operations/BOOK-21A, Faculty Lifecycle/
BOOK-22, Financial Operations/BOOK-23, Executive Command/BOOK-24,
Research Workspace/BOOK-25) and the ~105-item backlog in
`_dlu/ALBERO_FUNZIONALITA_TARGET.xlsx`/`_dlu/BACKLOG_TARGET.xlsx`. Full
sprint sequence, protocol, and source-of-truth files: `_dlu/sprint-plan/
PLAN.md`. Progress tracked per-sprint in `_dlu/sprint-plan/HANDOVER.md`
and each `SPRINT-NN.md`'s own header, not narrated sprint-by-sprint here
(this Book's own sync duty is the G-register row in TRACEABILITY.md,
kept current at each sprint's DOC-SYNC step).

### NEW-17f — Target-state foundations (scaffolding)
*Deliver:* 9 empty target-domain model files (T1-T10/T12, populated by
later sprints); 14 target-state events registered in the closed taxonomy
(`event_taxonomy.py`) as reserved/unwired slots; the T11 eval-harness
target tables (`eval_datasets`/`eval_cases`/`eval_runs`/
`eval_case_results`) added to the EXISTING NEW-02 `models_eval.py` (not
a parallel file) with two 🔧 FK links extending `agent_gate_runs`/
`eval_human_samples`, plus `scripts/eval_runner.py`; a CI "Conformance
Suite" job (tests/conformance/ had 3 real meta-tests, never wired into
any workflow before this sprint); Paper v3 ratified as the one frontend
design-token system (`legacyBridge.css` aliases the legacy `--color-*`
set, zero rewrites), an 8-component `frontend/src/components/ds/`
library (AIProposalCard is the flagship — every future AI-proposal
surface in this program consumes it), and an anti-hex-regression CI
lint. No user-facing feature — pure scaffolding for the 21 sprints that
follow.
*Verify:* migrations round-trip clean; `eval_runner.py --dataset dummy`
produces a real `eval_runs` row; taxonomy/ontology lints green
(`scripts/ci/lint_ontology.py` — found and fixed a real cross-repo
registry gap: 9 new event nouns were missing from
`dlu-core.yaml`/`architecture/ontology/dlu-core.yaml`, same class of gap
as NEW-11/NEW-17's own `degree`/`preevaluation` additions); design
system showcase page renders all 8 components; hex lint tested against
a deliberate fixture (fails red) and a clean diff (passes).

### NEW-32 — Demo & Conformance suite (Demo Scenario Pack)
*Deliver:* 9 persona-driven demo walkthroughs on the `DLU Demo
University` tenant — Student, Faculty, Dean, Provost, CFO, HR Lead,
Admin University (Tech Admin Institution), Admin Tenant (System
Admin), Admin AI Engineering (a 10th persona, Researcher, deferred to
SPRINT-21/NEW-33 per the plan's own condition). Each scenario ships a
real E2E test (`dlu_builder_tk/tests/e2e/demo/test_*.py`, 28 tests, 25
passed / 3 skipped on environment-dependent steps — SSO's `xmlsec`
native-library mismatch, and Redis-backed steps where no Redis is
provisioned) that drives the real service layer under transaction +
rollback against a real Postgres — the same discipline every `tests/
conformance/*.py` file already uses, not a new HTTP/browser harness —
plus a `docs/demo/SCENARIO-<persona>.md` write-up, a README index, and
a reset/execute/teardown runbook. `backend/scripts/seed_demo.py
--scenario=ai_native_demo` extended with 4 new persona users
(dean/provost/cfo/hr) and the governance/finance/HR/quiz domains those
scenarios need, confirmed idempotent across two consecutive runs
against a freshly migrated Postgres.
*Verify:* `pytest tests/e2e/demo -q` green (25 passed, 3 honestly
skipped); seed idempotency confirmed; zero-PII scan clean; two-pass
regression sweep unaffected (Phase1 104/4, `tests/conformance/` 354
passed + the same 3 pre-existing failures, event-mesh suite 17/1) with
zero stray rows left in any shared/reference table. Found and fixed a
real, pre-existing bug blocking this sprint's own catalog-governance
step: `platform.course_catalog_items` had never had an Alembic
migration despite its ORM model existing since PI-1 — every prior
`test_governance.py` fixture happened to avoid it via an early-return
on an empty course list, never exercised until this sprint's real
`ProgramCourse` rows.

---

# Chapter 8 — Conformance Suites

## 8.1 DAS-Core (exit K3) — per BOOK-03 Ch. 10

**Annex A status (NEW-15, 2026-08-02)** — every criterion below now has
≥1 named, discoverable executable check, meta-verified by
`tests/conformance/test_ch8_criteria_have_executable_checks.py`
(`dlu_builder_tk`). ✅ = fully closed this Masterbook pass; 🟡 = closed
for the dimensions this pass actually covered, a named sub-dimension
still open; ⚪ = registry entry exists, underlying suite not built this
pass.

| # | Criterion | Executable checks | Status |
|---|-----------|-------------------|--------|
| 1 | Layering | grep/CI gates: no experience-owned tables; no layer skipping imports | ✅ pre-existing (`scripts/ci/check_kg_staging_reads.sh` + siblings) |
| 2 | Engine contracts | contract test per engine invariant (evidence append-only, GPS determinism, twin single-door, KG fire-and-forget…) | ✅ pre-existing (`scripts/ci/check_evidence_sole_writer.sh` + siblings) |
| 3 | Mesh | STX-03 V1–V5 as permanent suite | ✅ pre-existing (`tests/test_stx03_event_mesh_integration.py`) |
| 4 | Tenancy | cross-tenant leakage fuzz (API + graph + streams + cache) | 🟡 API dimension pre-existing; **graph + streams closed this sprint** (`test_kg_cross_tenant_fuzz.py`, `test_stream_cross_tenant_fuzz.py` — the graph closure also fixed a real, previously-undiscovered Course/Lesson/Concept node-identity vulnerability, see `sprint_decisions_20260802_new15.md`); **cache dimension still open** |
| 5 | Drivers | bulkhead chaos tests (driver down ⇒ scoped degradation) | 🟡 pre-existing (`tests/chaos/test_pi2_disaster_recovery.py`, 27 tests) — most drivers covered, a real circuit breaker only landed at NEW-11; not extended this sprint |
| 6 | Gateway-only | egress network policy test + code grep gate | ✅ pre-existing (`scripts/ci/check_gateway_only_egress.sh`) |
| 7 | NFR | budget dashboards + alert wiring proof | ✅ this sprint — 4 DAS-specific budget panels added to `grafana/dashboards/api-performance-overview.json` (kernel-read P95, verification-endpoint availability, event-propagation P95, GPS-recompute latency), plus `test_nfr_budget_panels.py` pinning them |

## 8.2 DAS-Intelligent (exit K4)

Core + : twin seven layers live with consent/erasure e2e; ACE trace
completeness (100% sampled cycles); harness gates enforced in ACP lifecycle;
GPS sovereignty audit (weights inspectable); credential survival suite;
one-voice + "why?" UX checks; scorecards live.

**Annex A status (NEW-15, 2026-08-02):**
- Twin seven layers + consent: ✅ (K4). Erasure e2e: ⚪ **still not
  proven end-to-end** — `revoke_or_suspend(purge_pii=True)` exists,
  tested in isolation, no caller anywhere in this codebase performs a
  real erasure-request → purge chain. Not addressed this sprint (out of
  this sprint's own declared scope — see Context point 8).
- ACE trace completeness: 🟡→✅ **now genuinely measured**, not just
  asserted by construction (this sprint's own core deliverable — see
  §10 below and `AceCycleAttempt`/`reconcile_ace_trace_completeness`).
- Harness gates enforced in ACP lifecycle: ✅ unchanged since K2/K3. Agent
  GA gating itself remains ⚪ — all 9 seeded agents still
  `lifecycle_state="testing"`, zero `/agents/{id}/gate` runs — an
  ops/steward action, explicitly out of this sprint's scope (Context
  point 8), unchanged from K4's own exit report.
- GPS sovereignty audit: ✅ unaffected, still true from K3.
- Credential survival suite: ✅ unaffected, still true from K4 (STX-13).
- One-voice + "why?" UX checks: 🟡 **a structural proxy now exists**
  (`test_explanation_trace_coverage.py` + `explanation_registry.py`) —
  explicitly documented, in the test's own docstring and the
  maturity-collector's output, as never a substitute for the actual
  human UX audit, which remains ⚪ not performed.
- Scorecards: ⚪ still not built — the same gap K3/K4's own exit reports
  already flagged, carried forward again, not addressed this sprint.

## 8.3 DAS-Certified (K5 + audit)

Intelligent + : AI Act register complete with FRIA; audit fabric hash-chained;
regulatory profile suites (Italian: SPID/eIDAS/ANS; US: RSI ledger + G13
policy + engagement mapping); DR exercise on record; **external audit** of a
sampled evidence→credential chain and a sampled cycle trace.

**Annex A status (NEW-15, 2026-08-02):**
- AI Act register + FRIA: ✅ NEW-13.
- Audit fabric hash-chained: ✅ **this sprint** — `backend/domains/
  audit/` extended with 7 DAS-specific event types, wired into 6 real
  service call sites (best-effort, post-commit); three real,
  previously-undiscovered bugs that silently broke this system against
  any real Postgres deployment (never SQLite) were found and fixed —
  see `sprint_decisions_20260802_new15.md` §"three real audit bugs."
- Regulatory profile suites (Italian SPID/eIDAS/ANS; US RSI/G13):
  ✅ NEW-11/NEW-13.
- DR exercise on record: ✅ **this sprint** — `scripts/dr/
  run_dr_exercise.sh` automates a restore-mechanics drill (kg-rebuild +
  pg_restore + audit hash-chain integrity check), verified end-to-end
  against an isolated throwaway Postgres. Explicitly NOT a production
  WAL-archived PITR claim — that remains a documented ops task.
- External audit: ⚪ **cannot be code-complete by definition** — needs an
  actual human auditor, no methodology specified anywhere in the
  Masterbook. This sprint prepared the sampling/export tooling (the
  audit-fabric wiring above) an auditor would use; it did not, and
  could not, simulate being the auditor.

**Verdict, stated as plainly as K3/K4's own exit reports state theirs:
DAS-Certified is NOT being declared achieved by this Annex update.**
Erasure e2e, scorecards, agent GA gating, the cache-dimension tenancy
fuzz, and the external audit itself all remain genuinely open — see
`implementation/roocode/K5/K5-EXIT-REPORT.md` for the full, itemized
residual-debt table.

---

# Chapter 9 — KPI Instrumentation Plan

| Wave (phase) | Metrics wired |
|--------------|---------------|
| K1 | mesh lag, twin assembly latency, identity reconciliation coverage |
| K2 | trace completeness, deferral rates, harness pass rates, memory budgets |
| K3 | learning gain/durability (BOOK-01), rec acceptance, GPS adoption + replan stability, evidence balance |
| K4 | trust economy (verification SLA, % explained = 100%), mentorship hours (F5), belonging index, C_learner |
| K5 | equity deltas (blocking, all domains), RSI health, compliance freshness, maturity per P-area |

Rule: a metric ships with its guardrails (BOOK-01 Ch. 10) or not at all.

---

# Chapter 10 — Maturity Evidence Model (BOOK-02 Ch. 11)

Promotion evidence per level, per process area — collected automatically
(NEW-15):

| To level | Required evidence |
|----------|-------------------|
| M1 | process digitized: L2 sequence exists + system-of-record identified |
| M2 | dashboards live with ≥ 1 term of data; alert wiring |
| M3 | agent(s) at propose-tier with HITL queue metrics; harness green; incident count in bounds |
| M4 | event-driven execution proof (no manual step in happy path); economics attributed; human accountability points exercised (sampled) |

**Implementation (NEW-15, 2026-08-02):**
`backend/services/maturity_evidence_service.py::compute_maturity_evidence`
(`dlu_builder_tk`) — one cell per (BOOK-02 Ch. 2's 8 process areas × the
4 M-levels above) + 2 cross-cutting cells, mirroring
`compliance_posture_service.py`'s `_claim()`/`_gap()` pattern. M1 is a
static design-time fact; M2/M3 query real `LlmUsageLog`/`AiAgentConfig`
signals; M4 composes NEW-15's own ACE trace-completeness reconciliation
with NEW-14's unattributed-spend detector. No cell defaults to
`"verified"` without real evidence (V6). Exposed at `GET
/api/institution-workspaces/maturity-evidence` and folded into the QA
Console (IW3).

---

# Chapter 11 — Program Risks

| Risk | Mitigation |
|------|-----------|
| Mesh migration destabilizes running features | strangler shadow: old EventService dual-publishes during STX-03; retire on parity report |
| Harness becomes a bottleneck | scenario bank grows incrementally; deterministic tier always fast; gate only learner-facing GA |
| Identity backfill surprises (orphan legacy ids) | STX-01 V2 report gates progression; manual reconciliation queue |
| Agent quality below bar at K2 exit | K2 gates GA, not development — K3 proceeds with propose-tier agents |
| ESSE3 interface variance across universities | adapter config per tenant; M-C reconciliation catches mapping drift |
| Scope creep via workspace polish | triad minimum ships first; polish behind KPI evidence |
| Team context loss across long program | Document & Clear doctrine (below) + this repo as single memory |

---

# Chapter 12 — Execution Rules for Implementation Agents

The operational contract for every Claude/RooCode sprint execution:

1. **Read first:** BOOK-00 Annex A lineage + the sprint's Book refs + relevant
   `dlu_builder_tk` code. Turnkey CLAUDE.md guardrails bind absolutely
   (PK families, async/sync, additive migrations, EXEMPT_PATHS, soft delete,
   configured axios, useNavigate, tokens/i18n).
2. **Verification discipline:** all V1…Vn green before DoD; verifications are
   executable (tests/scripts), not assertions.
3. **Sync duty (BOOK-00):** constitution, CLAUDE.md and affected Book annexes
   update in the same change set; silent divergence is a conformance failure.
4. **G-register duty:** every sprint touching G-items updates the register
   disposition; new gaps discovered get numbers, owners, and Book assignments.
5. **Ontology duty:** new names resolve to `dlu-core.yaml` or an RFC is filed
   first (BOOK-05).
6. **Handoff checklist (per sprint):** files on disk (`git diff --stat`),
   decisions as ADRs/notes, next sprint tag recorded, review pass for
   convention violations — the running house checklist, unchanged.
7. **Document & Clear:** long sessions compact only after state is written to
   files; the repo is the memory, not the context window.

---

# Closing — the Masterbook is Complete

Twenty Books. A standard that is descriptive where the system runs and
prescriptive where it doesn't; a register (G1–G16) that faced ESSE3, ANVUR
and US accreditation honestly; a kernel with contracts, a cognition with humility, an
experience with a soul, and a blueprint that turns it all into sprints an AI
workforce can execute under human governance — which is, fittingly, exactly
the operating model the DLU AI-Native University proposes for education
itself.

*Per aspera ad astra — one verified sprint at a time.*

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Sprint card | The Ch. 3–7 unit: refs, deliverables, V1…Vn, DoD |
| Exit gate | Conformance suite that closes a phase (K3→Core, K4→Intelligent) |
| GA gate | NEW-02 harness requirement for learner-facing agent deployment |
| Maturity evidence collector | Automated gatherer of Ch. 10 promotion proofs |
| Execution rules | Ch. 12 — the binding contract for implementation agents |

---

*BOOK-20 v1.0 — awaiting review. Upon approval: generate the K1 prompt pack
(`implementation/roocode/K1/`) and begin with STX-01, in dependency order,
under the execution rules.*


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Add the **ATA waves/sprints** to the roadmap (see `../dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` W3-ATA) and the **Course Format v2.0** sprint (EKG-W1-07). Instrument tutor learning-gain/retention KPIs.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
