# DAS Traceability Matrix
### Registers → Books → Sprints → Conformance · DAS v1.0-draft

> The audit spine of the Masterbook. Three registers (G gaps, A anomalies,
> sprint set) cross-referenced to owning Books, delivery sprints (BOOK-20) and
> conformance checks. Updated under the G-register duty and sync rule
> (BOOK-20 Ch. 12). Silent divergence between this matrix and any Book is a
> conformance failure.

---

## 1. G-Register (regulatory/functional gaps) — G1–G14

| G | Gap | Found by | Owner Book | Resolution | Sprint | Conformance check |
|---|-----|----------|-----------|------------|--------|-------------------|
| G1 | Office hours (ricevimento) | ESSE3 faculty check (07) | 17 (FW2) | publishable slots + booking | NEW-09 | UX check FW2 |
| G2 | Appelli / exam sessions | ESSE3 faculty check (07) | 15 (Ch. 5) | AssessmentSession aggregate, native/mirror, grade refusal | NEW-05 (+NEW-04 edges) | V-suite NEW-05; GPS property tests |
| G3 | Verbalizzazione (qualified signature, preservation) | ESSE3 faculty check (07) | 16 (Ch. 8) | legal-act boundary: prepare native, execute at driver, cross-reference | NEW-11/12 | pending_verbalization e2e |
| G4 | Registro lezioni | ESSE3 faculty check (07) | 17 (FW2) | generated register + certify + approval mission | NEW-09 | register reproducibility test |
| G5 | Thesis lifecycle | ESSE3 faculty check (07) | 15 (Ch. 7) | Thesis aggregate: milestones, process evidence, deposit, defense | NEW-06 | evidence-chain resolvability |
| G6 | Committees | ESSE3 faculty check (07) | 15 (Ch. 8) | Committee aggregate, formation governance, verdicts trust 1.0 | NEW-06 | conflict-of-interest check |
| G7 | Regulation-year binding (offerta formativa) | ESSE3 institutional check (08) | 08 (Ch. 4.3) | ProgramVersion regulation-year + cohort binding; policy-object versioning | K1 model ext. + NEW-04 constraint | routing constraint property test |
| G8 | ANS spedizioni / SUA-CdS | ESSE3 institutional check (08) | 08 (Ch. 6.3) + 19 (calendar) | completeness monitor + dossier export (driver executes submissions) | NEW-13 | seeded-incompleteness test |
| G9 | Certificati / autocertificazioni | ESSE3 all-roles check (16) | 16 (Ch. 6.2) | self-cert native; official cert content native + bollo/seal at driver | NEW-08 (+NEW-12 PagoPA) | field-provenance test |
| G10 | Diploma Supplement | ESSE3 all-roles check (16) | 16 (Ch. 6.3) | first-class generated document credential, IT/EN, ELM-encoded | NEW-08 | ELM schema validation |
| G11 | Conseguimento titolo / clearance | ESSE3 all-roles check (16) | 16 (Ch. 6.4) | GPS path-health clearance checklist + application + committee chain | NEW-08 | clearance-flip fixture |
| G12 | RSI instrumentation (US Title IV) | US accreditation check (19) | 19 (Ch. 6.1) | RSI plan + per-course×student ledger + zero-touchpoint alerts; AI ≠ instructor interaction | NEW-13 | ledger reproducibility + V6 negative |
| G13 | Student identity verification (34 CFR 602.17(g)) | US accreditation check (19) | 19 (Ch. 6.2) | layered verification + IVP artifact + registration disclosure | NEW-13 | disclosure render test |
| G14 | DE/DI telematic regime (ANVUR) | Masterbook Review R2 | 19 (Ch. 5.1) | DE/DI classification (FEX v1.4) + per-CFU ledger + tutor mapping + CEV evidence; AI ≠ DI | NEW-13 (+FEX RFC) | DE/DI fixture + under-quota alert + V6 negative |
| G15 | Catalog as legal contract + explorable/what-if representation | stakeholder review (catalog PDF) | 04 (CatalogEdition) + 16 (§6.4a document) + 14 (simulation) + 17 (explorer/FW1) | versioned immutable edition, cohort binding, generated legal document, pre-auth simulation, faculty contribution authoring | NEW-16 | edition immutability + pinning + doc reproducibility + zero-persistence simulation |

Cross-cutting dependency: G12/G14 ledgers require instructor-role event
capture from Moodle (Review finding M3 → BOOK-18 Moodle driver contract).

---

## 2. A-Register (structural/semantic anomalies) — A1–A12 (all closed)

| A | Anomaly | Declared | Resolution | Closed in | Lands |
|---|---------|----------|------------|-----------|-------|
| A1 | Dual KG storage (PG + Neo4j) | 04 | Neo4j authoritative; PG = extraction staging; promotion door; sunset S1–S4 | 05/13 | **S1 ✅ (STX-05, 2026-07-16: CI gate `check_kg_staging_reads.sh`, legacy readers frozen)**; S2–S4 per BOOK-13 plan |
| A2 | Triple user population | 04 | platform GUID anchor; projections; `identity_map` sole reconciliation | 04 §5.1, 03 §5.3 | STX-01 ✅ (2026-07-14, ADR-0014 Option A; report 100% matched) |
| A3 | Parallel course structures | 04 | delivery vs design-time intent (`GENERATED_FROM`) vs projection | 04/05 §4.3–4.4 | doc + lineage in imports |
| A4 | Lesson vs Section/Page | 04 | two orthogonal hierarchies + `RENDERED_BY` totality | 05 Ch. 4 | KG v2.0 (STX-05) |
| A5 | Key-family mixture (G/I/B) | 04 | containment discipline; no in-place conversion | 04 Ch. 6 | review gate |
| A6 | Event catalog fragmentation | 04 | single closed taxonomy; registry lint | 04 Ch. 7, R1 | STX-03 ✅ (2026-07-14, `event_taxonomy.py`; EVENT_CATALOG.md superseded banner; registry lint wired at STX-05) |
| A7 | Enrollment duality | 04 | mirror rule; naming cleanup | 04/18 | K1 mechanical PR |
| A8 | `REQUIRES` double meaning | 05 | prerequisite = `PREREQUISITE_FOR`; asset dep → `NEEDS_ASSET`; constitution amended | 05 §5.2 | STX-05 ✅ (2026-07-16; aliases flagged, removal at v2.1) |
| A9 | `ALIGNS_TO`/`MAPS_TO` inconsistency | 05 | normalized `ALIGNED_TO` + strength | 05 §5.2 | STX-05 ✅ (2026-07-16; aliases flagged, removal at v2.1) |
| A10 | FEX `section` ≠ ontology Section | 05 (FEX check) | binds to `Module`; UX label only | 05 §4.4 | import enforcement |
| A11 | Component typology 13 vs 15 | 05 (FEX check) | lossless round-trip; FEX v1.4 adds 2 | 05 §4.4 | FEX RFC |
| A12 | FEX blueprint vs ModuleBlueprint | 05 (FEX check) | one concept, two lifecycle stages | 05 §4.4 | lineage preserved |

---

## 3. Sprint Set → Phases → Gates (BOOK-20)

| Phase | Sprints | Primary Books | Exit gate |
|-------|---------|---------------|-----------|
| K1 Kernel Foundation | STX-01, 02, **03 (keystone)**, 04, 05 | 03/04/05/06/13 | mesh V-suite green; identity reconciliation report |
| K2 Cognition | STX-06 ✅ (2026-07-17) · NEW-01 ✅ (2026-07-17) · NEW-02 ✅ (2026-07-18, GA gate) · **NEW-03 ✅ (2026-07-18)** | 09/10/11/12/17 | **harness gates wired to ACP lifecycle ✅ · crisis protocol zero-tolerance ✅** (`AgentGateRun` + `ctx_hash`-verified deploy gate; crisis check non-disableable, negative-tested) · **K2 Cognition pack complete — all 4 sprints delivered** |
| K3 Navigation & Evidence | **STX-07 ✅ (2026-07-19, Academic GPS core: `AcademicGPSService` fastest_path + path-health on a v1 term-indexed closure, `path_scenarios` table, `/api/gps` routes, Navigator agent + WS01 Academic Journey UI — other 3 scenarios honestly `not_yet_available` pending NEW-04/STX-12)** · **NEW-04 ✅ (2026-07-19, RouteGraph compiler: seven-type edge taxonomy, `route_graph_versions` persistence, real deterministic Pareto engine, full BOOK-14 Ch. 6.1 traffic table + hysteresis, G7 regulation-year tag (version-inert, test-proven), sovereignty guard enforced at construction)** · **STX-12 ✅ (2026-07-19, Recognition Agent: `recognition_claims` + calibration + hedge plans, yield estimator honestly separates credit band/eligibility/probability, `RECOGNIZE` edges live (position effect, not a weight), `highest_competency_growth` real when a recognize-vs-enroll choice exists, evidence-ceiling gap closed in `competency_graph_service.next_status` — `best_career_path`/`lowest_cost` premise-corrected to stay `not_yet_available`, WS02 frontend + NEW-02 gate deferred)** · 09…11 · **STX-08 ✅ (2026-07-19, evidence pipeline: AssessmentEvidenceService, sole-writer + identity-mapper CI gates, institution-scoped trust table, triangulation, evidence timeline API)** · **NEW-05 ✅ (2026-07-19, AssessmentSession — the Appello aggregate, G2: native/mirror modes, per-enrollment one-shot grade refusal reusing the existing `assessment.completed` consumer with a mandatory `trust_class` override, minimum-session policy audit + I4 alert at calendar publication, `SIT_EXAM`/`RETAKE` edges now live in `route_graph_compiler.py` — Ch. 3's "mastery + readiness" SIT_EXAM probability sovereignty-corrected to calendar-existence-only, traffic wiring corrected to program/course-scoped batch replan; also fixed an orphaned-router registration gap discovered in `main.py` — STX-07's `/api/gps` and STX-12's `/api/recognition` were imported but never mounted; WS06 frontend + readiness-trend model deferred to STX-11)** · **STX-11 ✅ (2026-07-20, Assessment Agent + WS06: BOOK-10/BOOK-15 apparent inconsistency resolved as a "skills vs. moves" reading key — `generate_formative`/`give_feedback`/`check_retrieval` are the 3 catalog moves, readiness prediction/viva dossier prep/item calibration/all summative work are administrative skills run entirely outside the ACE move cycle, no move-catalog RFC needed; calibration loop closed — `consolidation_service.record_observed_outcome` writes `mean_observed_outcome` for the first time on the `recommend_next` predictive move (deterministic `readiness:{twin_id}:{session_id}` cycle_id correlates prediction→outcome), the second real outcome-tracking loop after STX-12's; viva dossiers are ephemeral propose-tier drafts via the existing `move_proposal_service` (ADR-0012's sole-writer `verify()` extended with `source_kind`/`evidence_type`/`trust_class` kwargs, fully backward-compatible, for the durable `EvidenceRecord`); item calibration is honest classical facility + corrected point-biserial discrimination (no fabricated IRT/2PL), cohort slicing only via `StudentTwin.persona` — documented as a genuine scope limit, not a demographic-equity stand-in; grading assistance writes only `StudentExamAttempt.ai_feedback_json`, never a grade — the "propose tier holds under integrity pressure" requirement needs no autonomy-override mechanism since summative skills have no `act` code path to escalate past, proven via `expected_move: abstain` in `assessment.yaml`'s 12-scenario bank; also backfilled `recognition.yaml` (STX-12 had no scenario bank at all — could never legitimately pass its own deploy gate) and closed NEW-05's WS06/readiness-trend placeholder)** · 05, 06 | 14/15/06/17 | **DAS-Core suite green** |
| K4 Trust & Institution | STX-13…15 · NEW-07, 08, 09, 10 | 16/08/07/17 | **DAS-Intelligent suite green** |
| K5 Profiles & Compliance | NEW-11…15 (incl. G12/G13/G14 ledgers) | 18/19/20 | **DAS-Certified auditable** (external audit) |

Blocking dependencies: STX-03 → all kernel consumers · NEW-02 → any
learner-facing agent GA · STX-08 ✅ (2026-07-19) → credential work (STX-13+,
consumes `triangulation_status`) · STX-12 ✅ (2026-07-19) → NEW-06 committee
flows (adjudicate where policy requires) + K4 wallet import (extends the
claim taxonomy) · NEW-04 ✅ (2026-07-19) → session-granular GPS, now
delivered by NEW-05 ✅ (2026-07-19) — `AssessmentSession` aggregate +
live `SIT_EXAM`/`RETAKE` edges; the ESSE3 mirror driver for the IT
profile remains NEW-11/K5 · NEW-05 ✅ (2026-07-19) → STX-11 ✅ (2026-07-20,
Assessment Agent + WS06 delivered the readiness-trend model + WS06
calendar/evidence UI this sprint left honestly as a placeholder) → K2
debt items retired: calibration beyond `recommend_next` and real
outcome-tracking (`mean_observed_outcome`) were declared in K2 but never
written until STX-11 — both closed, no further K2 carry-forward · STX-11 ✅
(2026-07-20) → K4 credential work may cite verified competencies sourced
from `viva`/`dialogic_verification` trust classes; remaining nine-agents
roster (STX-09/10, Learning Coach/Subject Tutor/Student Success/Career
Advisor/Credential) and STX-13 are not started and await explicit
go-ahead.

## 4. Review Findings → Disposition (MASTERBOOK-REVIEW v1.0)

| Finding | Disposition |
|---------|-------------|
| B1 taxonomy | **applied** (R1): BOOK-04 Ch. 7 + constitution §7.3 amended |
| B2 → G14 | **applied** (R2): BOOK-19 §5.1 + 05/08/20 propagation |
| M1 framework versioning · M2 recognition authenticity + EMREX · M5 locale harness | fold into STX-04 / STX-12+NEW-02 scopes (R4) |
| M3 Moodle instructor events · M4 n8n governance · M7 licensure disclosures | BOOK-18/19 amendments (R5) |
| M6 apparatus | **applied** (R3 — this matrix, INDEX, GLOSSARY, nav, CHANGELOG) |
| m1–m9 | scheduled minor edits (R5) |

## 5. Conformance Criteria → Suites (BOOK-03 Ch. 10 / BOOK-20 Ch. 8)

DAS-Core: 7 criteria → executable checks (BOOK-20 §8.1) · DAS-Intelligent →
§8.2 additions · DAS-Certified → §8.3 + external audit. Meta-rule (NEW-15):
every criterion has ≥ 1 executable check, verified by meta-tests.
