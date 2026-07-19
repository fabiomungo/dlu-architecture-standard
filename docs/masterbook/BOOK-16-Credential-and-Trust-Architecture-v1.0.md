# BOOK-16 — Credential & Trust Architecture
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> Trust is the product (BOOK-00 Executive Summary). This Book specifies the top
> of the epistemic stack: how evidence (BOOK-15) becomes portable, verifiable,
> revocable claims the world can rely on — and how the same evidence graph
> generates every **traditional and administrative artifact** an institution
> owes its students: transcripts, official certificates and
> self-certifications (G9), the **Diploma Supplement** (G10), and the degree
> clearance flow (G11). It also owns the G3 boundary: the legally valid grade
> act in regulated deployments.
>
> **Conforms to:** BOOK-00 v2.0 (ADR-0011). **Depends on:** BOOK-15 (evidence),
> BOOK-05 (OB alignment vocabulary), BOOK-14 (wallet imports feed recognition).
> **Informs:** BOOK-17 (WS07), BOOK-18 (drivers: signature, PagoPA, ESSE3),
> BOOK-19 (keys, preservation).
> **Primary audience:** registrars, architects, compliance, product.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** the
verification found DLU further along than assumed: a dedicated **dlu-badge
microservice** (issuer profiles, badge classes with governed lifecycle:
create → approve → activate → deactivate → archive; per-tenant templates; demo
suite) and a **CredentialService already issuing Open Badges 3.0 JSON-LD
VerifiableCredentials** (`CourseAchievement`; unsigned "P2" structure, signing
deferred to "P3"). This Book adopts both as the base and specifies what P3 and
the ESSE3-derived gaps require.

---

# Chapter 1 — The Trust Stack

```text
EvidenceRecord (BOOK-15, append-only, trust-weighted)
  → StudentCompetency (confidence, status; verified = human)
    → Credential (criteria-issued, standards-encoded, signed)
      → Wallet (learner-held, consent-shared)
        → Verification (public, 99.95%, revocation-aware)
          → External trust (employers, institutions, ministries)
```

Two invariants carry the stack: **every credential resolves to its evidence
chain** (drill-down from claim to committee verdict to quiz attempt), and
**credentials survive everything** — commercial suspension (BOOK-02 §8.2),
twin erasure (pseudonymized evidence retention, BOOK-06 Ch. 9.3), even
platform migration (standards-encoded, exportable).

---

# Chapter 2 — The Running Base (adopted)

| Asset | Role in the standard |
|-------|---------------------|
| **dlu-badge service** (separate container) | the Issuance Authority: issuer profiles (per institution/college), badge classes as **credential templates** with governed lifecycle — the approve/activate machine maps directly to issuance-tier governance |
| **CredentialService** (OB 3.0 JSON-LD VC, `CourseAchievement`) | the VC composer: achievement JSON with CLO alignment (already reads course CLOs) |
| `/api/learners` credentials routes + `/api/v1/badges` | learner and admin surfaces (WS07 seeds) |
| `UserBadge` (community badges: contributor/expert/…) | engagement badges — **explicitly out of the trust stack** (no evidence claim; separate visual class in the wallet) |

Adoption rules: badge classes and constitution `credential_templates` (§12)
unify — one template model, `standard` field (`open_badges_3.0 | vc_edu`),
criteria engine per constitution; the dlu-badge lifecycle becomes the template
governance machine.

---

# Chapter 3 — Credential Taxonomy

| Type | Criteria basis | Issuance tier | Standard encoding |
|------|---------------|---------------|-------------------|
| Course badge | course completion | auto (act) | OB 3.0 Achievement |
| Competency badge | competency `mastered`+ | auto | OB 3.0 + alignment objects (framework URIs — BOOK-05 Ch. 7) |
| Micro-credential | competency set at `verified`, triangulated (BOOK-15 §4.3) | HITL (registrar) | OB 3.0 / CLR 2.0 |
| Certificate (program/professional) | program criteria + summative evidence | HITL | CLR 2.0 |
| Degree | full program + thesis/committee verdicts (G5/G6) + clearance (G11) | **reserved** (committee + registrar; legal act via driver where regulated) | CLR 2.0 + ELM (+ national legal record) |
| **Document credentials** (Ch. 6): transcript, self-certification, official certificate, Diploma Supplement | generated views over evidence/mirror | on-demand | PDF + ELM/Europass where applicable |
| Engagement badges (`UserBadge`) | community activity | auto | visual only — never verifiable claims |

---

# Chapter 4 — Issuance Architecture

1. **Templates & criteria:** constitution §12 criteria engine (deterministic —
   competency sets, statuses, levels, course completions); templates are
   platform-schema, versioned, lifecycle-governed (dlu-badge machine).
2. **Flow:** `competency.mastered`/completion events → Credential Agent
   evaluates templates (BOOK-10 card) → eligible → auto-issue or HITL queue →
   issue → `credential.issued` → wallet + n8n → institutional record
   (ERPNext/ESSE3).
3. **Signing (the P3 this Book specifies):** W3C Data Integrity proofs;
   **one DID per issuing institution** (`did:web` recommended initially —
   resolvable, no ledger dependency), key custody per BOOK-19 (KMS path,
   rotation, revocation of keys ≠ revocation of credentials); every issued VC
   carries issuer DID, evidence-chain hash, and revocation-list reference.
   The open RFC "VC issuer/DID strategy" (BOOK-00) is hereby resolved to
   did:web + Data Integrity as the default profile; ledgers remain optional
   extensions.
4. **Degree issuance** binds to the reserved chain: committee verdict (G6) +
   clearance (G11) + legal act (G3, driver) — DLU issues the *portable* degree
   credential only after the *legal* degree exists where law requires it.

---

# Chapter 5 — The Wallet (WS07)

- **Contents:** verifiable credentials + document credentials + engagement
  badges (visually distinct); each credential shows status, evidence drill-down
  (learner-visible provenance — open model applied to achievements), and
  sharing controls.
- **Export:** OB 3.0 / CLR 2.0 JSON-LD (signed), ELM/Europass for EU
  portability, PDF renderings for humans; share-links with scope and expiry
  (consent-logged).
- **Import (feeds the GPS):** external OB/CLR credentials import as
  recognition-claim candidates (BOOK-14 §4.3) — verified cryptographically
  where signed (high trust seed), document-parsed otherwise. The wallet is
  thus **bidirectional**: DLU's differentiator (recognition-aware routing)
  consumes the same standards it emits.
- Wallet contents survive lifecycle transitions (alumni keep everything —
  BOOK-06 Ch. 4.1).

---

# Chapter 6 — Traditional Artifacts as Views (Track A, operationalized)

The BOOK-02 §9.1 promise, made concrete. All documents below are **generated
views over the evidence graph + academic mirror** — computed on demand,
reproducible, evidence-linked:

## 6.1 Transcript & ECTS projection

Official-format transcript from mirror (grades) + evidence graph (competency
annex — the DLU extra); ECTS/credit-hour projections per program rules.

## 6.2 Self-certifications and official certificates (G9)

- **Self-certification** (autocertificazione, DPR 445/2000 style): learner
  self-service generation of enrollment/degree/exam declarations —
  DLU generates the document; its legal standing derives from the learner's
  declaration, so no external act is needed → **fully in scope, native**.
- **Official certificates** (with stamp duty / bollo, payments via PagoPA in
  Italy): DLU generates content; **stamp duty, payment and signature/seal are
  driver acts** (PagoPA driver, ESSE3/registrar seal — BOOK-18). The G3
  doctrine again: content native, legal act at the driver.

## 6.3 Diploma Supplement (G10) — a DLU strength opportunity

The DS (bilingual, EU standard model) is *exactly* what an evidence graph is
for: programme description from catalog + outcomes (P-CUR), individual results
from mirror + evidence, competency annex from L3 with framework alignments.
DLU MUST generate the DS as a first-class document credential (IT/EN), ELM-
encoded for Europass — turning a bureaucratic burden into a richer, verifiable
artifact no legacy SIS can match.

## 6.4a Catalog Edition document (G15)

The **course catalog is a legal artifact and a contract**: the published
edition binds what the university promises a cohort (courses, credits,
numbering, prerequisites, designations, recognition policies — G7
regulation-year semantics). Treatment mirrors every other Track-A view:

- the formal document (the "Course Catalog" PDF an institution publishes) is
  **generated** from the `CatalogEdition` aggregate (BOOK-04 C3) — versioned,
  hash-stamped, optionally signed; every statement traces to catalog rows;
- **immutability:** once effective, an edition never mutates; errata are new
  sub-editions with lineage; enrollments reference their edition immutably —
  that reference *is* the contract;
- the same aggregate feeds three consumers: the legal document (this
  section), the **student-facing explorer with what-if simulation** (BOOK-14
  Ch. 9 `simulate_scenarios`, BOOK-17 catalog explorer), and the **faculty
  authoring view** (course knowledge/competency contributions and
  recognition-policy declarations — FW1).

## 6.4 Degree application & clearance (G11)

The *domanda di conseguimento titolo* becomes a *checklist the GPS already
knows*: path-health (BOOK-14) tracks requirement completion continuously;
clearance = all requirements green (exams verbalized, thesis deposited —
BOOK-15, fees settled, surveys done). Learner applies when the checklist says
ready (or is proactively told); registrar confirms; the graduation session
(committee, G6) and legal acts follow via driver. Pergamena (physical
parchment) production/delivery stays institutional-side; DLU tracks the
request state.

---

# Chapter 7 — Verification & Revocation

- **Public verification endpoint** (constitutional EXEMPT exception):
  `GET /api/credentials/verify/{public_id}` → issuer, status
  (valid|revoked|expired), achievement + competency alignments, evidence-chain
  hash. SLO 99.95% (BOOK-03) — trust depends on it.
- **Cryptographic verification:** signed VCs verify offline against the
  issuer DID; the endpoint adds live status.
- **Revocation:** status-list (Bitstring/StatusList) referenced in every VC +
  `credential.revoked` events; revocation reasons classed (error, misconduct
  per due process BOOK-15 Ch. 11, superseded); revocation NEVER deletes —
  history preserved.
- **Verification analytics** feed the trust economy (BOOK-08 I3): who
  verifies, failure rates, latency.

---

# Chapter 8 — G3 Ownership: the Legal Grade/Degree Act

The full boundary specification (what BOOK-18's drivers must implement):

1. **Preparation (DLU):** committee/examiner verdicts, evidence-complete,
   signed within DLU's audit domain (BOOK-15 Ch. 8).
2. **Legal act (driver):** verbale with qualified electronic signature
   (FEA/QES per eIDAS in Italy), legal preservation (conservazione a norma) —
   executed in ESSE3 or a QES provider; DLU MUST NOT reimplement either.
3. **Confirmation:** `grade.synced` / degree-recorded events close the loop
   (BOOK-14 `pending_verbalization` semantics); the DLU evidence record links
   the legal act's identifier (verbale ref) — the two audit domains
   cross-reference.
4. **Native mode** (greenfield/corporate, unregulated credentials): DLU's
   signed VC *is* the act; no external dependency.

---

# Chapter 9 — Trust Governance

Issuer governance (who may create/activate templates — dlu-badge lifecycle +
registrar/Evidence Registrar roles); fraud posture (integrity architecture
BOOK-15 Ch. 9 upstream, revocation + verification downstream, issuance
anomaly monitoring — sudden template spikes alert); evidence-linkage audits
(sampled credentials walked back to evidence — a broken chain is a
trust-economy incident); key ceremonies and custody in BOOK-19; the standing
survival rules (Ch. 1) tested in the conformance suite.

---

# Chapter 10 — G-Register Check (standing verification)

| Gap | Disposition |
|-----|------------|
| G1 office hours | n/a (BOOK-17) ✅ |
| G2 appelli | consumed: session results feed evidence; refusal semantics honored (BOOK-15) ✅ |
| **G3 verbalizzazione** | **owned & resolved as boundary spec** (Ch. 8): prepare native, execute at driver, cross-reference acts |
| G4 registro | n/a (BOOK-17) ✅ |
| G5 tesi / G6 commissioni | consumed: defense/committee verdicts are degree-criteria inputs (Ch. 4.4) ✅ |
| G7 regulation-year | honored: degree criteria evaluate against the learner's regulation year ✅ |
| G8 ANS/SUA-CdS | degree/credential events feed the completeness monitor (BOOK-08 §6.3) ✅ |
| **G9 certificati/autocertificazioni** (new) | **resolved**: self-certifications native; official certificates = content native + stamp/payment/seal at driver (Ch. 6.2) |
| **G10 Diploma Supplement** (new) | **resolved**: first-class generated document credential, bilingual, ELM-encoded (Ch. 6.3) |
| **G11 conseguimento titolo** (new) | **resolved**: clearance-as-checklist from GPS path-health; application + committee + legal act chain (Ch. 6.4) |

Register now G1–G11; owners unchanged except G9/G10/G11 → this Book (surfaces
in BOOK-17, drivers in BOOK-18).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Issuance authority | **dlu-badge service**: issuers, classes, lifecycle, templates, demo suite | ✅ | unify with constitution templates 🔵 |
| VC composition | `CredentialService` — OB 3.0 JSON-LD (`CourseAchievement`) | ✅ (unsigned) | **P3 signing**: did:web + Data Integrity ⚪ (STX-13) |
| Learner/admin surfaces | credentials + badges routes | ✅ | wallet UX (WS07, STX-13) 🔵 |
| Criteria engine | constitution §12 design | 🔵 STX-13 | — |
| Verification endpoint | constitution §12.3 design | 🔵 | status-list revocation ⚪ |
| Wallet import | — | ⚪ | OB/CLR import → recognition claims (BOOK-14 feed) |
| Transcript/ECTS views | ERPNext/ESSE3 mirror + outcomes | 🟡 | generators ⚪ |
| G9 documents | — | ⚪ | self-cert native; PagoPA/seal drivers (BOOK-18) |
| G10 Diploma Supplement | catalog + outcomes + mirror all present | ⚪ | DS generator (IT/EN) + ELM encoder |
| G11 clearance | GPS path-health (STX-07) | 🔵 | clearance checklist + application flow |
| Engagement badges | `UserBadge` | ✅ | wallet visual separation 🔵 |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Trust stack | Evidence → competency → credential → wallet → verification → external trust |
| Document credential | Generated, reproducible artifact-view (transcript, certificate, DS) |
| Issuance tier | auto / HITL / reserved — per credential type |
| did:web profile | Default issuer identity: DID per institution, Data Integrity proofs |
| Bidirectional wallet | Exports and imports the same standards; imports feed recognition routing |
| Legal-act boundary | Content prepared natively; qualified signature/stamp/preservation at the driver |
| Clearance checklist | GPS-derived requirement completion state behind the degree application |
| Survival rules | Credentials outlive commercial state, twin erasure, and platform migration |

---

*BOOK-16 v1.0 — awaiting review. G-register: G3 boundary specified; G9/G10/G11
added and resolved. Next: BOOK-17 (Experiences — owner of G1/G4 and all
workspace surfaces).*
