# DLU Architecture Standard — Masterbook Index
### The Master Document of the DLU AI-Native University · DAS v1.0-draft

> 21 stabilized volumes (BOOK-00 through BOOK-20) + 7 target-state extension
> volumes (BOOK-21 through BOOK-26, BOOK-21–25 added SPRINT-22 doc-sync,
> 2026-08-01; BOOK-26 added AVA doc-sync, 2026-08-05) + apparatus. **BOOK-00
> v2.0 is the root**: it defines conformance
> (DAS-Core / DAS-Intelligent / DAS-Certified), the Seven Canonical Questions,
> the normative language, and the lineage rules every other volume obeys.
> Reference implementation: **DLU Builder Turnkey** (`dlu_builder_tk`) — every
> Book carries a normative Annex A mapping to the running code.

---

## The Volumes

| # | Title | One-line scope | Layer |
|---|-------|----------------|-------|
| [00](BOOK-00-Executive-Vision-and-Manifesto-v2.0.md) | Executive Vision & Manifesto (v2.0) | conformance model, manifesto with tensions, ADRs, standards, 20-book plan, Turnkey baseline (Annex A) | Root |
| [01](BOOK-01-Academic-Philosophy-and-Pedagogical-Model-v1.0.md) | Academic Philosophy & Pedagogical Model | CAT operationalized, 10 learning-science principles, constructive alignment, learner model, personalization doctrine | Philosophy |
| [02](BOOK-02-AI-Native-University-Theory-v1.0.md) | AI-Native University Theory | P01–P08 process architecture, three economies, faculty transformation, archetypes, economics, accreditation strategy | Institution |
| [03](BOOK-03-Academic-Operating-System-v1.0.md) | Academic Operating System | layer semantics, 10 engine contracts, Event Mesh spec, tenancy, drivers, NFRs, DAS-Core checklist | Architecture |
| [04](BOOK-04-Academic-Domain-Model-v1.0.md) | Academic Domain Model | 10 bounded contexts, aggregate catalog from real code, state machines, identity & consent, anomaly register A1–A7 | Architecture |
| [05](BOOK-05-Academic-Ontology-and-Semantic-Model-v1.0.md) | Academic Ontology & Semantic Model | DLU-Core ontology, semantic quadrangle, relationship registry, FEX binding, framework alignment, A8–A12 closures | Semantics |
| [06](BOOK-06-Student-Digital-Twin-v1.0.md) | Student Digital Twin | seven layers, lifecycle & personas, context assembly, agent entitlements, open learner model, erasure | Twins |
| [07](BOOK-07-Faculty-Digital-Twin-v1.0.md) | Faculty Digital Twin | F-layers, pedagogical envelopes, workload/mentorship dividend, ESSE3 faculty gap analysis (G1–G6) | Twins |
| [08](BOOK-08-Institution-Digital-Twin-v1.0.md) | Institution Digital Twin | derived layers, three-economy instrumentation, program health, compliance posture, G7–G8 | Twins |
| [09](BOOK-09-Academic-Cognitive-Engine-v1.0.md) | Academic Cognitive Engine (ACE) | PDDAEL cycle, pedagogical move catalog, dual-process execution, cognitive budget, calibrated humility | AI spine |
| [10](BOOK-10-AI-Workforce-v1.0.md) | AI Workforce | ACP-native agent composition, the nine contract cards, lifecycle as governed releases, scorecards | AI spine |
| [10A](BOOK-10A-AI-Workforce-Skills-and-MCP-Catalog-v1.0.md) | Workforce, Skills & MCP Catalog (annex) | exhaustive roster: 24 agents, 44 skills, 19 MCP servers, usage modes, phasing | AI spine |
| [10B](BOOK-10B-AI-Execution-Framework-v1.0.md) | AI Execution Framework (annex) | resolution/ctx_hash, skill engine, MCP layer, missions, testing T1–T5, deployment, unified execution record | AI spine |
| [11](BOOK-11-AI-Cognitive-Architecture-v1.0.md) | AI Cognitive Architecture | reasoning patterns R1–R8, grounding doctrine, education-specific guardrails, the eval harness (GA gate) | AI spine |
| [12](BOOK-12-Memory-Architecture-v1.0.md) | Memory Architecture | four stores M1–M4, consolidation, forgetting by design, cross-learner isolation | AI spine |
| [13](BOOK-13-Academic-Knowledge-Network-v1.0.md) | Academic Knowledge Network | one graph three planes, schema v2.0, supply chain, canonical queries, analytics, A1 sunset | Intelligence |
| [14](BOOK-14-Academic-Intelligence-Navigator-v1.0.md) | Academic Intelligence Navigator (GPS) | recognition-aware routing, RouteGraph, examination-decoupled model, real-time reroute, fairness | Intelligence |
| [14A](BOOK-14A-Credit-Recognition-and-Pre-Evaluation-v1.0.md) | Credit Recognition & Pre-Evaluation (annex) | IT/US jurisdiction rule packs, three-tier pre-evaluation (instant AI + HITL), badge-to-credit automation, equivalence precedents, historic syllabi | Intelligence |
| [15](BOOK-15-Assessment-and-Evidence-Architecture-v1.0.md) | Assessment & Evidence Architecture | two-products pipeline, trust model, appelli (G2), thesis (G5), committees (G6), integrity | Trust |
| [16](BOOK-16-Credential-and-Trust-Architecture-v1.0.md) | Credential & Trust Architecture | trust stack, signing (did:web), bidirectional wallet, document credentials (G9/G10/G11), G3 boundary | Trust |
| [17](BOOK-17-Experiences-v1.0.md) | Experiences | Canvas·Companion·Missions triad, WS00–WS08 + faculty + institution workspaces, quality bars, G1/G4 | Experience |
| [18](BOOK-18-Technical-Architecture-and-Turnkey-Integration-v1.0.md) | Technical Architecture & Turnkey Integration | engine→code mapping, driver catalog (ESSE3 keystone), refactoring map, phases K1–K5 | Delivery |
| [19](BOOK-19-Governance-Security-and-Compliance-v1.0.md) | Governance, Security & Compliance | RACI, security, AI Act mapping, Italian profile (incl. G14 DE/DI), US distance-ed profile (G12/G13) | Governance |
| [20](BOOK-20-Implementation-Blueprint-v1.0.md) | Implementation Blueprint | sprint catalog with verification cards, conformance suites, KPI plan, execution rules for AI agents | Delivery |

### Target-state extension volumes (BOOK-21–26)

Added after BOOK-00's original 20-book plan, one per persona/gap the initial plan didn't cover
(TRACEABILITY.md gaps G17/G19/G20/G21/G22 + T12 guardrails). BOOK-21–25 listed here since
SPRINT-22 doc-sync (2026-08-01); **BOOK-26 added AVA doc-sync, 2026-08-05** — all 7 are real,
sprint-implemented volumes, not placeholders. Version/status strings kept as each book's own file
states (some still carry "-draft" in the filename as this sub-program's own maturity marker,
independent of whether specific chapters are implemented — see each book's own Status line for
what's actually built).

| # | Title | One-line scope | Status |
|---|-------|----------------|--------|
| [21](BOOK-21-Admissions-Qualification-Evaluation-and-Orientation-v0.2-draft.md) | Admissions, Qualification Evaluation & Orientation | full funnel: application→eligibility→orientation→offer→matriculation (G17) | IMPLEMENTED (SPRINT-06/NEW-18) |
| [21A](BOOK-21A-Credit-Pre-Evaluation-Operations-and-Automation-v0.4-draft.md) | Credit Pre-Evaluation: Operations & Automation (annex) | CDS extraction/matching engine, rule packs, golden-set eval loop (G17) | IMPLEMENTED (SPRINT-02..04/07/22 — F1-F4 all real; C21A.6/C21A.7 corrected + closed for real SPRINT-22) |
| [22](BOOK-22-Faculty-Lifecycle-Contracting-and-Workforce-v0.5-draft.md) | Faculty Lifecycle, Contracting & Human Workforce | onboarding, QES-signed authoring contracts, milestone/deliverable gates, HR/workload ledger (G18) | IMPLEMENTED (SPRINT-08/09/10 — G18 FULLY CLOSED) |
| [23](BOOK-23-Financial-Operations-and-Administrative-Backbone-v0.5-draft.md) | Financial Operations & Administrative Backbone | native AR/AP, holds, student dossier, financial planning & control (G19) | IMPLEMENTED (SPRINT-05/09/18 — G19 FULLY CLOSED) |
| [24](BOOK-24-Executive-Command-and-Corporate-Governance-v0.1-draft.md) | Executive Command & Corporate Governance | policy/catalog-approval workflow, historicized KPI layer, board governance (G20) | IMPLEMENTED (SPRINT-14/15/16 — G20 FULLY CLOSED) |
| [25](BOOK-25-Research-Workspace-and-Open-Science-v0.1-draft.md) | Research Workspace & Open Science | reproducibility/provenance, federated zero-trust RAG, grant→budget/workload links (G21, 10th persona) | IMPLEMENTED (SPRINT-21/NEW-33 — G21 FULLY CLOSED) |
| [26](BOOK-26-Accreditation-Quality-Assurance-and-DM1154-Compliance-v0.1-draft.md) | Accreditation, Quality Assurance & DM 1154/2021 Compliance | faculty-requirement engine, Art. 3/4 accreditation lifecycle, Allegato E indicators, SUA-CdS/SMA tracking, Auditor/CEV persona, evidence registry, alert engine, Allegato C judgment workflow (G22, 11th/12th personas) | IMPLEMENTED (AVA-01…12 — G22 FULLY CLOSED) |

Guardrail tenant policies (T12, BOOK-19 §7 extension, SPRINT-22/NEW-29 — the program's final
sprint) live inside **BOOK-19** itself (Governance, Security & Compliance), not a standalone book.

**Apparatus:** [TRACEABILITY.md](TRACEABILITY.md) (registers → Books → sprints →
checks) · [GLOSSARY.md](GLOSSARY.md) (unified normative glossary) ·
[MASTERBOOK-REVIEW-v1.0.md](MASTERBOOK-REVIEW-v1.0.md) (independent review,
R1/R2 applied) · [CHANGELOG.md](CHANGELOG.md)

**Lineage (BOOK-00 Annex A.3):** DAS Books (normative) → `DLU_Foundation_v1.md`
(superseded for principles; WS map input) → `dlu_builder_tk/docs/
STUDENT_EXPERIENCE_ARCHITECTURE.md` (Turnkey implementation profile, STX
sprints) → `dlu_builder_tk/CLAUDE.md` (binding engineering guardrails).

---

## Reading Paths

| You are… | Read in this order |
|----------|--------------------|
| Rector / Board / CFO | 00 → 02 → 08 (Ch. 3, 12) → 19 (Ch. 5–7) → 20 (Ch. 2) |
| Provost / Academic leadership | 00 → 01 → 02 → 15 → 17 (Ch. 3–4) |
| Enterprise / solution architect | 00 → 03 → 04 → 05 → 13 → 18 |
| AI architect / engineer | 00 (Ch. 6) → 09 → 10 → 11 → 12 → 06 (Ch. 5–6) |
| Product / UX | 00 → 17 → 06 → 14 (Ch. 7) → 16 (Ch. 5–6) |
| Registrar / QA / Compliance | 00 → 15 → 16 → 19 → 08 (Ch. 6) → 26 (periodic accreditation, DM 1154/2021) |
| Integration engineer (Italy) | 18 (Ch. 3–4) → 19 (Ch. 5) → 15 (Ch. 5, 8) → 16 (Ch. 8) |
| Implementation agent (Claude/RooCode) | 20 (Ch. 12 first — execution rules) → sprint refs per card |

## The Five Ideas (if you read nothing else)

1. **One kernel, ten engines, everything else is a view** (03) — experiences
   own no state; the Event Mesh is how the university *happens*.
2. **Evidence is the epistemic currency** (15/16) — two products per
   interaction; credentials resolve to evidence chains; transcripts and the
   Diploma Supplement are generated views.
3. **The AI decides in pedagogical moves, not tokens** (09/10/11) — symbolic
   decision, neural realization, structural explainability, calibrated
   humility, and a driving test before deployment.
4. **The GPS routes through recognition** (14) — prior learning anywhere is a
   route segment; the fastest path often starts with credit for the road
   already traveled.
5. **Compliance is proven, not asserted** (19) — RSI and DE/DI ledgers, the
   generated registro, the living self-study: the same events that teach also
   testify.


---

### Update 2026-08-08 — ATA 1.0 cross-cut + Course Format v2.0
The Masterbook now integrates the DLU Architecture Suite **EKG v1.1** and **ATA 1.0 (Adaptive Tutor Architecture)**, and adopts the **DLU Course Exchange Format v2.0**. Start from `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` and `DAS_EKG_INTEGRATION_PLAN.md`. ATA is a cross-cutting slice touching BOOK-03/05/06/09/11/12/13/14/15/17/18/19; implementation sprints are in `../dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` (W3-ATA) and the Course Format sprint (EKG-W1-07).

### BOOK-09A — Adaptive Tutor (ATA)
Annex to BOOK-09 (ACE). Normative spec of the Adaptive Tutor: Student Learning Digital Twin, Pedagogical Strategy Ontology, Pedagogical Policy Engine (NBLA), evidence tiers & misconceptions, tutor memory, platform architecture, EKG extension (11 nodes/12 edges), evaluation framework and governed rollout. Binds ADR-0016/0018; adopts ADR-0017 (Course Format v2.0). See `architecture/adr/ADR-0016..0018`.

### Update 2026-08-08 — EKG persona integration & RKG governance (RFC-0002)
Closes the persona/UI gap the EKG v1.1 absorption left open: a 12-persona EKG-usage/RKG-maintenance
RACI (BOOK-19 §1.2), an IW7 Dean Console + RKG Governance Console spec (BOOK-17 IW6), EKG/RKG columns
on BOOK-08/24, and the Ontology Registry population (`architecture/ontology/dlu-core.yaml`) BOOK-05
had called for but never received. **ADR-0021** defines RKG as the EKG's governance/maintenance
plane, not a second graph. Start from `RFC-0002-ekg-persona-integration-and-rkg-governance.md`
(`architecture/rfc/`). Turnkey-side console/frontend work is specced, not built, as `EKG-W6-07/08`
in `../dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` (Wave 6).

### Update 2026-08-09 — EKG-W0…W5 core platform implementation complete
The EKG v1.1 absorption's own 36-sprint engineering catalog (`../dlu_builder_tk/docs/
ROOCODE_EKG_PROMPTS.md`, Waves 0–5 incl. W3-ATA) is now fully implemented and tested against live
Postgres/Neo4j: mastery engine + mapping stewardship (BOOK-13), a grounded GraphRAG tutor
(BOOK-09A), career+credit recognition (BOOK-14/14A), and Wave 5 hardening — Postgres RLS,
Neo4j per-tenant routing, full SRE observability, a proven DR drill, application-level evidence
encryption, gateway cost governance, and an EKG-scoped production DoD assessment. **ADR-0016…0020**
move from Proposed to **Accepted** accordingly. Full sprint-by-sprint narrative with evidence
citations: `TRACEABILITY.md` (`EKG-W0-01`…`EKG-W5-05`) and `../dlu_builder_tk/docs/
STUDENT_EXPERIENCE_ARCHITECTURE.md`. **Honest scope note**: this is the EKG-scoped
implementation program only — it does not claim the platform-wide `DAS-Certified` tier
(BOOK-20 §8.3's own unchanged verdict).
