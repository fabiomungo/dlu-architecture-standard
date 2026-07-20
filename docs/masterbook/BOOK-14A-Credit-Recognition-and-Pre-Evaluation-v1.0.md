# BOOK-14A — Credit Recognition & Pre-Evaluation Framework (Italy & USA)
## DLU Architecture Standard (DAS) · Normative Annex to BOOK-14 · Version 1.0 — DRAFT

> The complete credit-management specification for the two reference
> jurisdictions, derived from the comparative analysis *"Riconoscimento
> Crediti e Prevalutazioni: Italia e USA"* and reconciled with the
> **post-K1 implementation state** of `dlu_builder_tk` (twin core,
> Competency Engine, event mesh and KG v2.0 are now landed ✅). It adds four
> things the Masterbook did not yet have: **(1) jurisdiction rule packs** as
> machine-readable policy objects (CFU/DM 931/2024 vs SCH/PLA/CAEL);
> **(2) the Pre-Evaluation service** — instant, AI-computed, HITL-validated
> credit estimates for **registered, not-yet-enrolled prospects** (G16);
> **(3) badge-to-credit automation** on the Bestr→ESSE3 model, built on the
> running OB 3.0 Badge Service; **(4) the equivalence-precedent memory and
> the historic-syllabus answer** to curricular drift.
>
> **Conforms to:** BOOK-14 (recognition-aware routing), BOOK-15 (evidence,
> committees), BOOK-16 (credentials, wallet), BOOK-19 (profiles G12–G14).
> **Primary audience:** registrars, product, architects, compliance.

**Normative language:** RFC 2119.

---

# Chapter 1 — Position and the Two Philosophies

The source analysis frames the divide precisely: Italy is **centrally
codified** (ministerial rules bind committee discretion: SSD sectors, CFU
arithmetic, hard caps), the US is **decentralized and market-oriented**
(institutional autonomy under accreditor standards, national tooling for
transparency). DLU MUST serve both without forking the kernel:

- one **recognition pipeline** (BOOK-14 Ch. 4: claims → yield estimation →
  dossier → HITL adjudication → position jump), already sprint-planned
  (STX-12);
- per-jurisdiction behaviour expressed **only as rule packs** (Ch. 3) and
  process parameters — never as code branches.

The strategic reading from the analysis: Italian *telematiche* win enrollment
by offering **free, fast pre-evaluation** while traditional universities
refuse it; the US institutionalized it nationally (Transferology). An
AI-native university must do it **better than both**: instant like
Transferology, binding-quality like a delibera — with the honesty layer in
between (Ch. 4).

---

# Chapter 2 — Domain Model Additions

All GUID, additive; contexts per BOOK-04 (C4/C8 unless noted).

| Aggregate | Purpose | Notes |
|-----------|---------|-------|
| `RecognitionRulePack` [platform] | versioned jurisdiction policy object: unit system, caps, tolerances, exclusions, procedural terms (Ch. 3) | referenced by tenant profile; changes governed (BOOK-19); regulation-year aware (G7) |
| `CreditPreEvaluation` [tenant] | the G16 aggregate: prospect request → instant estimate → HITL validation → offer (Ch. 4) | bound to a `CatalogEdition` (G15) — the estimate is contractual-grade only against a pinned edition |
| `EquivalenceRule` [tenant, shareable] | precedent memory: (external course/certification fingerprint → internal course/competency, disposition, conditions) learned from adjudications | the TES-style rule base; feeds the yield estimator's calibration (BOOK-14 §4.1); consortium-shareable as policy objects |
| `ExternalSyllabusRecord` [tenant] | historic syllabus evidence attached to claims: source edition/year, document, provenance, authenticity signals | the curricular-drift answer, external side (Ch. 6) |
| `BadgeCreditRule` [platform] | badge class → credit convalida mapping (Ch. 5) | the Bestr→ESSE3 pattern on dlu-badge |

Extends (no new tables): `ExternalCourse` gains `ssd_code`, `unit_system`,
`units`, `grade_scale`, `syllabus_record_id`, `source_edition_year`;
recognition claims (BOOK-14) gain `rule_pack_version`, `authenticity_score`,
`equivalence_rule_id`.

---

# Chapter 3 — Jurisdiction Rule Packs

## 3.1 Italy pack (`rulepack-it-cfu`, seeded from the verified analysis)

| Rule class | Content (machine-readable parameters) |
|-----------|----------------------------------------|
| Unit system | CFU (DM 509/1999, DM 270/2004): 1 CFU = 25 h; 60/year; 180 L, 120 LM |
| Matching basis | **SSD sector + CFU count** — committee evaluation bound to both |
| Legacy equivalences | vecchio ordinamento: annual exam = 12 CFU, semestral = 6; hours fallback (40 h→6, 60 h→9) |
| Fraction tolerance | deficit ≤ 1 CFU on 6 or ≤ 2 on 12 → full convalida, no integration; **excess CFU are lost** (8-for-6 → 2 non-reusable) |
| Grade merging | grouped exams → arithmetic or CFU-weighted mean, rounded to integer (per-regolamento switch) |
| Experience caps (**DM 931/2024**) | professional/certified learning: **≤ 48 CFU** (L, LM ciclo unico), **≤ 24 CFU** (LM); admissible: D.Lgs 13/2013 certified competencies, PA training, regulated language/IT certifications, Servizio Civile Universale, elite sport; may exempt curricular internship |
| Master credits | I livello → L only; II livello → LM/ciclo unico; ≤ 12 CFU per regolamento |
| ITS Academy | → lauree professionalizzanti coerenti: ≤ 60 CFU (≤ 24 caratterizzanti); reverse: 60% of ITS hours, 70–90% for final-year entry |
| Year placement | thresholds (e.g. ≥ 31 CFU → 2nd year, ≥ 81 → 3rd) — parameterized per regolamento |
| **Obsolescence** | exams older than 8–10 years (parameter) → obsolete: not convalidable or partial-with-integration |
| Procedure | one-shot request at matriculation within manifesto windows; delibera Consiglio di Corso (≤ 90 gg); acceptance term 15–20 gg; optional silenzio-assenso |
| Fees | istruttoria (60–290 €, non-refundable), abbreviazione indennità, ricongiunzione (290 €/year, cap 4 500 €; disability ≥ 66% → 30 €/year) — PagoPA driver (G9) |

## 3.2 USA pack (`rulepack-us-sch`)

| Rule class | Content |
|-----------|---------|
| Unit system | Semester Credit Hour; institutional comparability under accreditor standards |
| Minimum grades | transfer: ≥ C undergraduate, ≥ B graduate |
| Exclusions | recreational, physical education, ESL, remedial/developmental courses |
| PLA methods (CAEL) | Portfolio-Based Assessment (faculty-evaluated), articulated agreements (intro-level only, not gen-ed core), **ACE/NCCRS recommendations** (military JST, corporate training) |
| PLA caps & residency | PLA ≤ 60 credits (bachelor); **residency: ≥ 12 credits or ≥ 20% at awarding institution** |
| PLA portability | warn: ~65% of institutions do not accept transferred-in PLA credits — recognition statements MUST disclose this |
| Financial | PLA fees ≠ tuition (disclosed at registration — G13 discipline); Title IV generally excludes PLA costs (Experimental Sites/COA note); savings/time data used honestly in guidance (never as marketing promises — misrepresentation guard) |
| Compliance hooks | credit-hour definition documentation (BOOK-19 §6.3); transfer decisions auditable for accreditors |

Rule packs are versioned, effective-dated, regulation-year-aware; the yield
estimator, the GPS `RECOGNIZE` edges and the Pre-Evaluation engine consume
them **exclusively through the pack interface** — a hard-coded cap anywhere
is a conformance failure.

---

# Chapter 4 — The Pre-Evaluation Service (G16 — the product requirement)

## 4.1 Who and when

Offered to **registered, not-yet-enrolled users**. In twin terms (BOOK-06 —
landed ✅): website registration creates a **Prospect twin** (consent-minimal).
No matriculation, no fees barrier for the *instant* tier (institutions MAY
price the *validated* tier per rule pack). This adopts the telematiche
insight — pre-evaluation as orientation and attraction — with US-grade
transparency.

## 4.2 The three-tier flow

```text
TIER 0 — anonymous what-if (existing G15): catalog explorer + simulate_scenarios
         no documents, indicative only, zero persistence
              │ registration
TIER 1 — INSTANT ESTIMATE (AI, seconds):
  prospect uploads documents / declares experience
   → extraction skills (parse-transcript, parse-certification,
     map-experience-to-esco) — template-free, any format
   → authenticity screening (detect-document-anomalies): fraud signals
     scored, never verdicts (detector humility)
   → matching engine: EquivalenceRule precedents ⊕ embedding similarity vs
     CatalogEdition (course descriptions, SSD where IT) ⊕ rule-pack
     arithmetic (caps, tolerances, exclusions, obsolescence)
   → OUTPUT within the session: per-course disposition table
     (recognizable | partial+integration | excluded+reason), estimated
     units + confidence band, year-placement estimate (IT), residency
     check (US), GPS scenario preview with the recognition applied
   → clearly marked: «stima non vincolante / non-binding estimate,
     soggetta a validazione del Consiglio» — calibrated hedging (BOOK-09)
              │ prospect requests validation (optional fee per pack)
TIER 2 — VALIDATED PRE-EVALUATION (HITL, days not months):
   → Recognition Agent compiles the dossier (claims, syllabi evidence,
     precedents cited, rule-pack computation trace)
   → routed to the faculty council queue (Consiglio di Corso / registrar
     committee — BOOK-15 Committee aggregate, G6, `purpose`-audited)
   → council validates/amends per item; decision recorded as
     EquivalenceRule precedents (the memory grows)
   → prospect receives a VALIDATED PRE-EVALUATION STATEMENT:
     a signed document credential (BOOK-16, OB 3.0/VC) stating the
     credits that WILL be recognized upon enrollment in edition E within
     validity window W — the enrollment-conversion instrument
              │ enrollment
   → statement converts to formal recognition (delibera where IT), evidence
     recorded, position jump, GPS replan — no re-evaluation
```

## 4.3 Normative rules

1. **Instant but honest:** Tier-1 output MUST render confidence bands and
   the non-binding marker; presenting an estimate as granted credit is a
   misrepresentation-guard violation (BOOK-19).
2. **HITL is constitutive:** only the council/registrar converts estimate →
   commitment (ADR-0012 lineage); the AI prepares, cites precedents, and
   computes rule arithmetic — it never decides.
3. **Anti-gaming:** Tier-1 rate limits per identity; document authenticity
   below threshold forces Tier-2 with original-document requirements;
   repeated resubmission of altered documents flags the identity.
4. **One evaluation, honored:** a validated statement converts at enrollment
   without re-adjudication (window and edition permitting) — fixing the
   Italian one-shot rigidity *and* the US PLA-portability failure inside
   DLU's own perimeter.
5. **Data protection:** prospect documents are consent-scoped
   (`career_processing`), retention-limited if no enrollment follows
   (parameter, default 12 months), erasable on request.

---

# Chapter 5 — Badge-to-Credit Automation (the Bestr→ESSE3 pattern, on dlu-badge)

The analysis documents the one genuinely automated flow in the Italian
landscape: Bestr Open Badge → API notification → ESSE3 checks the libretto →
**automatic CFU convalida with zero manual steps**. DLU generalizes it on the
running Badge Service (OB 3.0 ✅):

1. **`BadgeCreditRule`** (platform): badge class (issuer, achievement,
   alignment framework refs) → credit disposition (course convalida | CFU/SCH
   amount | competency evidence weight) + conditions (edition, program
   scope, rule-pack caps).
2. **Inbound flow:** wallet import or issuer webhook → **cryptographic
   verification** (OB 3.0 signature — trust tier `verified badge`, higher
   than any parsed document) → rule match → if rule is `auto` tier:
   convalida recorded + evidence written + `credential.recognized` event +
   libretto/mirror update (ESSE3 driver where present); if `propose`:
   one-click item in the council queue.
3. **Outbound symmetry:** DLU-issued badges carry alignment metadata rich
   enough that *other* institutions' rules can auto-recognize them — we emit
   what we wish to receive.
4. Auto-tier is reserved to **low-stakes, well-defined rules** (language
   ideoneità, transversal skills — the Bestr precedent); everything touching
   caps arithmetic or degree requirements stays propose-tier.

---

# Chapter 6 — Curricular Drift and the Historic-Syllabus Answer

The analysis identifies the operational bottleneck of both systems: valid
equivalence requires the syllabus **of the year the exam was taken**; Italy
fragments (burden on the student), the US solved it commercially
(CollegeSource: 190 k catalogs / 130 M descriptions) and structurally
(Simple Syllabus: immutable, publicly searchable archives).

DLU's position:

1. **Internally, the problem is solved by construction:** the immutable
   `CatalogEdition` (G15) + FEX archives are a Simple-Syllabus-grade
   historic record from day one — every DLU course's exact-year syllabus is
   permanently retrievable and publicly linkable. This MUST be surfaced as a
   **public historic-syllabus endpoint** (edition-scoped, indexed) so other
   institutions can evaluate DLU students cheaply — trust-economy export.
2. **Inbound**, `ExternalSyllabusRecord` captures what the prospect provides
   with provenance and year; the matching engine weights confidence by
   syllabus availability (course-description-only matches carry wider bands);
   where registries exist (CollegeSource-covered US sources, EMREX/ELMO for
   EU verified records — Review M2), the corresponding MCP tools upgrade the
   claim's trust tier.
3. **The precedent memory compounds:** every adjudicated equivalence stores
   its syllabus evidence refs — the second student from the same origin
   course gets a Tier-1 estimate backed by a validated precedent, and the
   council a one-click confirmation. Recognition gets *faster and more
   accurate with volume* — the AI-native answer to the 90-day delibera.

---

# Chapter 7 — Implementation Mapping (post-K1 state)

| Element | Builds on (✅ landed / running) | Lands in |
|---------|-------------------------------|----------|
| Rule packs | policy-object pattern (BOOK-02), G7 regulation-year | **NEW-17** (with STX-12) |
| Pre-Evaluation aggregate + tiers | Prospect twin ✅ (STX-01/02), CatalogEdition + simulate (NEW-16), extraction skills (10A), Committee (NEW-06), document credential (STX-13/NEW-08) | **NEW-17** |
| Instant matching engine | Competency Engine ✅ (STX-04), embeddings ✅, `EquivalenceRule` (new), KG v2.0 ✅ | **NEW-17** |
| Badge-to-credit | dlu-badge ✅ + CredentialService OB 3.0 ✅, event mesh ✅ | **NEW-17** (rules) + STX-13 (wallet verify) |
| Authenticity screening | plagiarism/doc services ✅, `detect-document-anomalies` (10A) | STX-12 scope (M2) |
| Historic-syllabus endpoint | CatalogEdition (NEW-16), FEX archive ✅ | NEW-16 extension |
| ESSE3 convalida sync | driver contract (BOOK-18 Ch. 4: M-A sanctioned writes) | NEW-11 |
| Events | taxonomy ✅ — add `preevaluation.requested/estimated/validated/converted`, `credential.recognized` (RFC-first: amend constitution §7.3 + BOOK-04 Ch. 7 in the same change set as NEW-17) | NEW-17 |

**Sprint NEW-17 — Credit Recognition & Pre-Evaluation (K4, after NEW-16;
Tier-2 committee flow requires NEW-06):** deliverables per this Book;
verifications: V1 rule-pack arithmetic golden cases (IT fractions/caps/
obsolescence; US grades/exclusions/residency) · V2 Tier-1 end-to-end < 60 s
on fixture dossier with bands + non-binding marker · V3 estimate→validation→
conversion chain with precedent recorded · V4 badge auto-convalida round-trip
(signed badge fixture) with zero manual steps · V5 anti-gaming (rate limit +
altered-document flag) · V6 no hard-coded jurisdiction parameter outside
packs (grep gate).

---

# Chapter 8 — G-Register Check (standing verification)

| Gap | Disposition |
|-----|------------|
| G2/G5/G6 | consumed: committee flow (G6) is Tier-2's adjudicator; thesis/appelli untouched ✅ |
| G7 | rule packs are regulation-year-aware ✅ |
| G9/G10/G11 | fees via PagoPA (IT pack); validated statement joins the document-credential family ✅ |
| G12/G13/G14 | pre-evaluation is pre-enrollment: RSI/DE-DI not applicable; identity verification applies from Tier-2 (document authenticity + G13 methods) ✅ |
| G15 | consumed: Tier 0 = catalog explorer; estimates bind to editions ✅ |
| **G16 credit pre-evaluation service** (new — this Book) | **owned here**: three-tier flow, rule packs, precedent memory, badge automation, historic-syllabus answer; sprint NEW-17 |

Register now **G1–G16**.

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Rule pack | Versioned, machine-readable jurisdiction recognition policy (IT-CFU, US-SCH) |
| Tier 0/1/2 | Anonymous what-if · instant AI estimate · HITL-validated pre-evaluation |
| Validated Pre-Evaluation Statement | Signed document credential: credits that will be recognized upon enrollment (edition + window bound) |
| Equivalence precedent | Adjudicated rule reused for future claims — recognition improves with volume |
| Badge-to-credit rule | Bestr→ESSE3-pattern mapping from verified badge class to credit disposition |
| Obsolescence rule | IT parameter: exams beyond 8–10 years lose convalidability |
| Residency requirement | US parameter: minimum credits at the awarding institution |
| Curricular drift | Courses change over years; equivalence needs the year-exact syllabus |
| Historic-syllabus endpoint | Public, edition-scoped syllabus archive — DLU's Simple-Syllabus-grade export |

---

*BOOK-14A v1.0 — awaiting review. G16 registered; sprint NEW-17 defined.
The K2 pack generation (post-K1 exit report) will sequence NEW-17 into K4 as
noted.*
