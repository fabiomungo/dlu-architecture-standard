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
| K3 Navigation & Evidence | **STX-07 ✅ (2026-07-19, Academic GPS core: `AcademicGPSService` fastest_path + path-health on a v1 term-indexed closure, `path_scenarios` table, `/api/gps` routes, Navigator agent + WS01 Academic Journey UI — other 3 scenarios honestly `not_yet_available` pending NEW-04/STX-12)** · **NEW-04 ✅ (2026-07-19, RouteGraph compiler: seven-type edge taxonomy, `route_graph_versions` persistence, real deterministic Pareto engine, full BOOK-14 Ch. 6.1 traffic table + hysteresis, G7 regulation-year tag (version-inert, test-proven), sovereignty guard enforced at construction)** · **STX-12 ✅ (2026-07-19, Recognition Agent: `recognition_claims` + calibration + hedge plans, yield estimator honestly separates credit band/eligibility/probability, `RECOGNIZE` edges live (position effect, not a weight), `highest_competency_growth` real when a recognize-vs-enroll choice exists, evidence-ceiling gap closed in `competency_graph_service.next_status` — `best_career_path`/`lowest_cost` premise-corrected to stay `not_yet_available`, WS02 frontend + NEW-02 gate deferred)** · 09…11 · **STX-08 ✅ (2026-07-19, evidence pipeline: AssessmentEvidenceService, sole-writer + identity-mapper CI gates, institution-scoped trust table, triangulation, evidence timeline API)** · **NEW-05 ✅ (2026-07-19, AssessmentSession — the Appello aggregate, G2: native/mirror modes, per-enrollment one-shot grade refusal reusing the existing `assessment.completed` consumer with a mandatory `trust_class` override, minimum-session policy audit + I4 alert at calendar publication, `SIT_EXAM`/`RETAKE` edges now live in `route_graph_compiler.py` — Ch. 3's "mastery + readiness" SIT_EXAM probability sovereignty-corrected to calendar-existence-only, traffic wiring corrected to program/course-scoped batch replan; also fixed an orphaned-router registration gap discovered in `main.py` — STX-07's `/api/gps` and STX-12's `/api/recognition` were imported but never mounted; WS06 frontend + readiness-trend model deferred to STX-11)** · **STX-11 ✅ (2026-07-20, Assessment Agent + WS06: BOOK-10/BOOK-15 apparent inconsistency resolved as a "skills vs. moves" reading key — `generate_formative`/`give_feedback`/`check_retrieval` are the 3 catalog moves, readiness prediction/viva dossier prep/item calibration/all summative work are administrative skills run entirely outside the ACE move cycle, no move-catalog RFC needed; calibration loop closed — `consolidation_service.record_observed_outcome` writes `mean_observed_outcome` for the first time on the `recommend_next` predictive move (deterministic `readiness:{twin_id}:{session_id}` cycle_id correlates prediction→outcome), the second real outcome-tracking loop after STX-12's; viva dossiers are ephemeral propose-tier drafts via the existing `move_proposal_service` (ADR-0012's sole-writer `verify()` extended with `source_kind`/`evidence_type`/`trust_class` kwargs, fully backward-compatible, for the durable `EvidenceRecord`); item calibration is honest classical facility + corrected point-biserial discrimination (no fabricated IRT/2PL), cohort slicing only via `StudentTwin.persona` — documented as a genuine scope limit, not a demographic-equity stand-in; grading assistance writes only `StudentExamAttempt.ai_feedback_json`, never a grade — the "propose tier holds under integrity pressure" requirement needs no autonomy-override mechanism since summative skills have no `act` code path to escalate past, proven via `expected_move: abstain` in `assessment.yaml`'s 12-scenario bank; also backfilled `recognition.yaml` (STX-12 had no scenario bank at all — could never legitimately pass its own deploy gate) and closed NEW-05's WS06/readiness-trend placeholder)** · **STX-09 ✅ (2026-07-21, Recommendations v2 + WS03: three-stage pipeline reuses the existing rule engine (strangler) + STX-05's `kg_query_service.frontier`/`gap` (built but dead code since STX-05 — this sprint is their first real caller) + SM-2 due reviews (sync-only, `asyncio.to_thread`-offloaded); `recommendations` table with `explanation_trace` as `JSON(none_as_null=True)` — a real SQLAlchemy gap found: plain `JSON` serializes Python `None` to the string `"null"`, silently defeating `nullable=False`; idempotency per `(tenant_id, twin_id, rec_type, payload_hash, day)`; consent degradation collapses to rule-stage-only per BOOK-01 Ch. 7; serendipity is sha256-keyed on `(twin_id, day)`, never `random` (would break idempotency); `reco` mesh consumer goes real (mastery/competency/path events, budgeted per-twin refresh, fire-and-forget Celery); WS03 contest affordance files a HITL item via a new `/api/competencies/{id}/contest` route, never mutates state directly; closed 2 K2 debt chores — Discovery's `explain_concept` grounding (catalog fallback via a new `KGQueryService.find_concept_by_name`) and `ace.py`'s memory DELETE ownership check; found and fixed a genuine pre-existing bug in `models_review.py` (`ReviewSchedule.next_review_at` double-declared the same index — same bug class as NEW-05's `refusal_status` fix); corrected a stale doc-drift in `docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §18 that had assigned WS03 to STX-11 and WS04 to STX-09, mismatching the K3 README's own dependency graph)** · **STX-10 ✅ (2026-07-22, Subject Tutor + Learning Coach + WS04/WS05: R4 symbolic hint ladder (`tutor_dialogue_service.py`, durable `TutorDialogueState` — NOT `learner_tutor_service`, a naming correction, that file is an unrelated CCP content-recommendation service) engages only within a genuine BKT-derived struggle, never manufactures one; giveup-pressure phrases ("just tell me the answer") can only escalate the SAME scaffolded ladder to `worked_example`, never bypass it — no catalog move means "state the answer directly"; `MOVE_CONSULTS` populated for the first time (`reframe_goal` → Subject Tutor + Learning Coach — needed zero changes to the existing L4 escalation gate, since `reframe_goal` was already `plan`+`propose`), `_consult` implemented for real (previously `NotImplementedError`); Learning Coach etiquette (`coach_etiquette_service.py`) closes a real, previously-unenforced gap — `NotificationPreference.quiet_hours_*`/`max_per_day` existed as columns but were never checked anywhere; review missions compete equally through STX-09's own recommendation slate, no Coach-private queue)** | 14/15/06/17 | **DAS-Core suite green** |
| K4 Trust & Institution | **STX-13 + NEW-07 ✅ (2026-07-23, Credential Engine + signing: `credential_templates`/`credential_signing_keys`/`credential_status_list_sequences` (platform) + `issued_credentials` (tenant); deterministic criteria engine (no LLM in the eligibility path); did:web (one method) + `eddsa-jcs-2022` Data Integrity signing — a deliberate scope narrowing from JSON-LD RDF canonicalization (`eddsa-rdfc-2022`), which would have pulled in an unused `pyld` dependency and threatened offline verification via its default network `@context` fetch; versioned per-institution Ed25519 keys (Fernet-at-rest) so a future rotation never orphans an already-signed VC; W3C Bitstring Status List revocation with a platform-schema row-locked index allocator (never `max()+1` — the concrete fix for a real concurrent-issuance collision hazard found in design review); wallet API + WS07 UI; wallet import lands as an unverified `RecognitionClaim` candidate, never a trusted import; Credential Agent seeded, 7/9 BOOK-10 agents now real)** · **STX-14/15 ✅ (2026-07-24, Behaviour recompute + Student Success + Career Advisor + WS08: nightly job is the first-ever writer of `TwinBehaviourProfile` (dead since STX-01/02), a deterministic weighted heuristic over existing aggregate signals, never an LLM/trained model, L6-consent-gated; a NEW `risk_score` threshold crossing emits `risk.detected`, finally reachable after sitting unbound since before this sprint; mission-budget gate generalized from STX-10's Learning-Coach-only `coach_etiquette_service` into a `(agent_key, mission_kind)`-parameterized primitive (behavior-preserving delegation, verified); `flag_risk` filed only on a genuine Decide-step confirmation, never a bypass — no advisor-assignment relationship exists anywhere in this data model, so the HITL proposal queue itself (same pattern every other agent's propose-tier surface already uses) is the v1 human-connection vehicle, not an invented push notification; Career Advisor's ESCO gap analysis grounded in a small, hand-curated `urn:dlu-esco-lite:` seed (8 occupations), honestly `not_yet_available` outside it; `success-watch` consumer group made real for the first time (STX-03-reserved, zero handlers until now) — `graduation.predicted` registered but honestly dormant, no producer exists; WS08 UI; completes all NINE BOOK-10 Ch. 3 agents with a real config row)** · **NEW-08 ✅ (2026-07-25, Document Credentials G9/G10/G11: `document_credential_service`/`clearance_service` — a NEW, deliberately separate artifact-type domain from STX-13's signed VCs (rendered PDFs, not Verifiable Credentials); self-certification (learner-triggered, no attestation), Diploma Supplement (ELM-lite v1 — a bounded, documented JSON Schema subset, NOT full Europass ELM conformance) and transcript generators, PDF rendering via `reportlab` not `weasyprint` (no native cairo/pango deps in this environment — a verified, documented substitution); a real `degree_clearance_applications`/`degree_clearance_waivers` DB-table queue (not `move_proposal_service`'s 7-day-TTL Redis store — clearance can stay open for months); 5 named criteria resolved LIVE on every read via per-criterion resolvers (`requirement_completion`/`verbalization` ← GPS `PathHealth`, `fees_settled` ← real `FinancialHold.blocks_credentials`, `thesis_deposited`/`surveys_done` honestly `not_yet_available` — no Thesis/Committee/Survey model exists yet); a 4th `waived` state (registrar-set, reason-required, audited) distinct from `not_yet_available`, without which no institution could ever complete the clearance journey; confirmation re-resolves and re-enforces the gate rather than trusting filing-time state; a local always-unpaid PagoPA stub (`backend/drivers/pagopa_stub.py`) makes bollo-gated diploma-supplement issuance block visibly, real adapter deferred to NEW-12/K5)** · **NEW-09/10 ✅ (2026-07-26, Faculty + Institution Surfaces G1/G4: FW2 office-hours booking + generated teaching register (`TeachingRegister`/`TeachingRegisterSession`/`TeachingRegisterApproval`, drafted deterministically from `TeachingSection.schedule` × `AcademicTerm` dates — no delivery/xAPI event stream exists in this codebase to draft from, an honest substitute); FW3 Verification Desk (pending-competency worklist real; viva-dossier panel an honest single-twin slice, `move_proposal_service`'s Redis store has no tenant scoping and no safe bulk-listing mechanism); FW5 Envelope Console — `FacultyEnvelope` (versioned, insert-new-row-per-update) folded with the platform `AiAgentConfig.envelope_defaults` via a new, pure, tightening-only `resolve_effective_envelope` (autonomy caps MIN-rank, disabled-sets union, humility floor re-validated on the merge) and wired into the REAL Decide-step runtime (`ace_service._resolve_faculty_envelope`/`_decide`, confirmed both `check_preconditions` AND `_choose_escalation` call sites use the merged envelope — an opus design review flagged the second site as the one a naive wiring attempt would plausibly miss); `course_id` threads additively through `route`/`run_cycle`/`_run_phases` but no production caller supplies it yet (no workspace has a "which course" concept — same shape as G7's inertness); I2/I3/I5 institution composites + IW1/IW2/IW3 workspaces are pure read-time aggregations over existing kernel data, zero new tables, every element real-with-drill-down or honestly `not_yet_available`; two real cross-tenant IDOR bugs found and fixed (`office_hours_service`'s faculty lookup, `is_course_instructor`'s missing tenant join); a genuine SQLAlchemy `JSON`-column bug found and fixed in the QA Console's item-fairness count (same `none_as_null` class as STX-09's `recommendations.explanation_trace`); a genuine reportlab non-determinism bug found and fixed in both this sprint's and NEW-08's PDF generators (`invariant=True`, reportlab's own documented fix for wall-clock `/CreationDate` stamping breaking hash-reproducibility))** · **NEW-16 ✅ (2026-07-27, Catalog Edition & Explorer G15: `CatalogEdition` — a `RouteGraphVersion`-style compiled snapshot aggregate (platform schema, insert-only, one sanctioned live-model reader enforced by `check_catalog_sole_reader.sh`), never a retrofit of immutability onto the live, actively-CRUD'd `Program`/`ProgramVersion`/`CourseCatalogItem` tables; `simulate_scenarios` — a NEW function reusing the REAL routing-engine internals, corrected from the sprint's own brief which had assumed `route_graph_compiler.py`'s Pareto primitives were already wired in (confirmed: fully defined, never called anywhere in the codebase); zero-write/zero-event verified by AST-walking the reused call graph; G7 regulation-year inertness (NEW-04) carried forward honestly, not resolved; a public, pre-auth Catalog Explorer — the first genuinely pre-auth, cross-tenant-by-design surface in this codebase, independently security-reviewed with 0 critical/high findings; a `dlu-catalog` MCP server (`services/dlu_catalog_mcp/`) with all 5 tools genuinely new, including the 3 "base" ones BOOK-10A had marked planned since K3 despite never being built; FW1 (Design Studio) extended with DEVELOPS/COVERS + recognition-policy authoring, feeding the NEXT edition only)** | 16/08/07/17 | **DAS-Intelligent suite green** |
| K5 Profiles & Compliance | NEW-11…15 (incl. G12/G13/G14 ledgers) | 18/19/20 | **DAS-Certified auditable** (external audit) |

Blocking dependencies: STX-03 → all kernel consumers · NEW-02 → any
learner-facing agent GA · STX-08 ✅ (2026-07-19) → credential work (STX-13 ✅
2026-07-23) · STX-12 ✅ (2026-07-19) → NEW-06 committee
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
from `viva`/`dialogic_verification` trust classes · STX-09 ✅ (2026-07-21,
Recommendations v2 + WS03) → STX-10 ✅ (2026-07-22, Subject Tutor +
Learning Coach + WS04/WS05): the SM-2 due-review candidate source and the
`recommendation_service_v2` slate were already real, so the Coach's
review missions assembled as first-class recommendations (BOOK-01 Ch. 3,
"compete equally, no privileged lane") against a live pipeline, not a
stub · K2 debt items retired: `MOVE_CONSULTS` populated with its first
real entry and `_consult` implemented (both declared in K2, empty/stub
until now) — closed, no further K2 carry-forward on this item · **K3
Navigation & Evidence phase pack now fully delivered** (all of STX-07…12,
NEW-04/05 ✅; NEW-06 Thesis/Committee tracked separately, needs only
STX-08 ✅, not blocked by anything in this list) — see
`implementation/roocode/K3/K3-EXIT-REPORT.md` for the exit-gate audit
(functional delivery green; the broader DAS-Core conformance-suite
INFRASTRUCTURE — cross-tenant fuzz, driver chaos tests, NFR dashboards,
a gateway-only egress CI gate — is only partially built, carried forward
as residual debt, not silently claimed done) · **K4 Trust & Institution
pack authored** (`implementation/roocode/K4/`, README + STX-13 +
STX-14-15 prompt files — covers only the two sprints explicitly
requested; NEW-08/09/10 and NEW-16/17 remain BOOK-20-blueprinted but
unauthored) · **STX-13 + NEW-07 ✅ delivered** (2026-07-23) · **STX-14/15
✅ delivered** (2026-07-24, see K4 row above) — **the nine-agents roster
is now complete** (all of Discovery, Academic Navigator, Recognition,
Assessment, Subject Tutor, Learning Coach, Credential, Student Success,
Career Advisor have a real `ai_agent_configs` seed function + contract
card + NEW-02 scenario bank; none has run its own harness gate yet — no
`deployed` transition for any of the nine, ops/steward action, carried
forward); NEW-08/09/10 and NEW-16/17 remain BOOK-20-blueprinted, not
requested, not started.

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
