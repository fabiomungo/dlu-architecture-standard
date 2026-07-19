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
| A1 | Dual KG storage (PG + Neo4j) | 04 | Neo4j authoritative; PG = extraction staging; promotion door; sunset S1–S4 | 05/13 | STX-05 (S1), BOOK-13 plan (S2–S4) |
| A2 | Triple user population | 04 | platform GUID anchor; projections; `identity_map` sole reconciliation | 04 §5.1, 03 §5.3 | STX-01 |
| A3 | Parallel course structures | 04 | delivery vs design-time intent (`GENERATED_FROM`) vs projection | 04/05 §4.3–4.4 | doc + lineage in imports |
| A4 | Lesson vs Section/Page | 04 | two orthogonal hierarchies + `RENDERED_BY` totality | 05 Ch. 4 | KG v2.0 (STX-05) |
| A5 | Key-family mixture (G/I/B) | 04 | containment discipline; no in-place conversion | 04 Ch. 6 | review gate |
| A6 | Event catalog fragmentation | 04 | single closed taxonomy; registry lint | 04 Ch. 7, R1 | STX-03 |
| A7 | Enrollment duality | 04 | mirror rule; naming cleanup | 04/18 | K1 mechanical PR |
| A8 | `REQUIRES` double meaning | 05 | prerequisite = `PREREQUISITE_FOR`; asset dep → `NEEDS_ASSET`; constitution amended | 05 §5.2 | STX-05 aliases |
| A9 | `ALIGNS_TO`/`MAPS_TO` inconsistency | 05 | normalized `ALIGNED_TO` + strength | 05 §5.2 | STX-05 aliases |
| A10 | FEX `section` ≠ ontology Section | 05 (FEX check) | binds to `Module`; UX label only | 05 §4.4 | import enforcement |
| A11 | Component typology 13 vs 15 | 05 (FEX check) | lossless round-trip; FEX v1.4 adds 2 | 05 §4.4 | FEX RFC |
| A12 | FEX blueprint vs ModuleBlueprint | 05 (FEX check) | one concept, two lifecycle stages | 05 §4.4 | lineage preserved |

---

## 3. Sprint Set → Phases → Gates (BOOK-20)

| Phase | Sprints | Primary Books | Exit gate |
|-------|---------|---------------|-----------|
| K1 Kernel Foundation | STX-01, 02, **03 (keystone)**, 04, 05 | 03/04/05/06/13 | mesh V-suite green; identity reconciliation report |
| K2 Cognition | STX-06 · NEW-01, **02 (GA gate)**, 03 | 09/10/11/12/17 | harness gates wired to ACP lifecycle; crisis protocol zero-tolerance |
| K3 Navigation & Evidence | STX-07…12 · NEW-04, 05, 06 | 14/15/06/17 | **DAS-Core suite green** |
| K4 Trust & Institution | STX-13…15 · NEW-07, 08, 09, 10 | 16/08/07/17 | **DAS-Intelligent suite green** |
| K5 Profiles & Compliance | NEW-11…15 (incl. G12/G13/G14 ledgers) | 18/19/20 | **DAS-Certified auditable** (external audit) |

Blocking dependencies: STX-03 → all kernel consumers · NEW-02 → any
learner-facing agent GA · STX-08 → credential work (STX-13+) · NEW-04 →
session-granular GPS (needs NEW-05 aggregate + ESSE3 mirror for IT profile).

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
