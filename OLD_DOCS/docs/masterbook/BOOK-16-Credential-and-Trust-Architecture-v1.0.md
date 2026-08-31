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

   > ✅ **IMPLEMENTED (NEW-23, SPRINT-12, 2026-07-31):** the "course badge"
   > row of Ch. 3's table was fully built (`credential_criteria_service.
   > evaluate_templates_for_event`, `credential_issuance_service.
   > issue_or_propose`, signing, wallet) but had exactly ONE caller anywhere
   > in the codebase — a demo seed script — and `badge_credit_rule_service.
   > apply_badge_credit_rules` had zero callers. `dlu_builder_tk`'s
   > `badge_automation_service.py` now closes this: a new Event Mesh
   > consumer group `course-completion` (STX-03) emits a real, new
   > `course.achieved` event per student from `assessment_session.
   > published` (queried via `AssessmentSessionEnrollment`, PASS +
   > published + not refused), which drives both auto-issuance
   > (`achievement_badge_issuances`, idempotent, `attempts` capped at 5,
   > retried by a Celery beat sweep) and `apply_badge_credit_rules` for the
   > first time. Async-DB-touching criteria/issuance calls are bridged from
   > the sync consumer handler via `asyncio.run()`, the same technique
   > `esse3_credential_consumers.py` already used for its own async call.
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
  **✅ implemented (NEW-12, 2026-07-30):** `pagopa_payment_position` is a
  cache-only status read (never live — the frozen `BolloPaymentStatus`
  contract NEW-08's stub established is preserved exactly), the
  payment-initiation route is the write side; the seal itself follows
  Ch. 8's now-resolved trigger condition — ESSE3/registrar seals
  out-of-band for `esse3`-slot institutions, the QES driver seals for
  `qes_provider`-slot institutions with no ESSE3 of their own.

## 6.3 Diploma Supplement (G10) — a DLU strength opportunity

The DS (bilingual, EU standard model) is *exactly* what an evidence graph is
for: programme description from catalog + outcomes (P-CUR), individual results
from mirror + evidence, competency annex from L3 with framework alignments.
DLU MUST generate the DS as a first-class document credential (IT/EN), ELM-
encoded for Europass — turning a bureaucratic burden into a richer, verifiable
artifact no legacy SIS can match.

## 6.4a Catalog Edition document (G15) — ✅ implemented (NEW-16, 2026-07-27)

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

**Implementation note (NEW-16)**: the legal document is rendered
hash-stamped and reproducible via `catalog_edition_service
.generate_catalog_legal_document` — a real reportlab non-determinism bug
was found and fixed here (`SimpleDocTemplate` stamps a wall-clock
`/CreationDate` by default, breaking "same input → same hash" even
though the document's own content-building code never reads the live
clock; fixed via reportlab's own `invariant=True` flag, applied to
NEW-08's document generator too for consistency).

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

**Trigger condition (resolved, NEW-12, 2026-07-30 — this Book left it
undecided until this sprint):** a single per-tenant slot,
`Institution.config["legal_act_driver"] ∈ {"esse3", "qes_provider",
"native_vc"}`, resolved through the ONE function
`legal_act_routing.resolve_legal_act_driver` (structurally verified: no
other call site reads the config key directly). `esse3` routes step
2/3 through NEW-11's driver; `qes_provider` routes the identical step
2/3 through NEW-12's QES driver instead (`qes_signature_ref` is the
attach point, mirroring `Esse3VerbaleRef`'s references-only shape); an
institution with neither configured defaults to `native_vc` (step 4) —
the safe default, since assuming an external integration exists where
none was configured would be worse than assuming none.

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
| **G3 verbalizzazione** | **✅ fully closed** (Ch. 8): prepare native, execute at driver, cross-reference acts — ESSE3 path real (NEW-11, 2026-07-29), QES-provider path real (NEW-12, 2026-07-30), native-VC path real since STX-13 |
| G4 registro | n/a (BOOK-17) ✅ |
| G5 tesi / G6 commissioni | consumed: defense/committee verdicts are degree-criteria inputs (Ch. 4.4) ✅ |
| G7 regulation-year | honored: degree criteria evaluate against the learner's regulation year ✅ |
| G8 ANS/SUA-CdS | degree/credential events feed the completeness monitor (BOOK-08 §6.3) ✅ |
| **G9 certificati/autocertificazioni** (new) | **✅ fully closed**: self-certifications native; official certificates = content native (NEW-08) + stamp/payment/seal at driver, real PagoPA + QES adapters (NEW-12, 2026-07-30) (Ch. 6.2) |
| **G10 Diploma Supplement** (new) | **resolved**: first-class generated document credential, bilingual, ELM-encoded (Ch. 6.3) |
| **G11 conseguimento titolo** (new) | **resolved**: clearance-as-checklist from GPS path-health; application + committee + legal act chain (Ch. 6.4) |

Register now G1–G11; owners unchanged except G9/G10/G11 → this Book (surfaces
in BOOK-17, drivers in BOOK-18).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Issuance authority | **dlu-badge service**: issuers, classes, lifecycle, templates, demo suite; **plus, as of STX-13 (2026-07-23), a NEW, separate `credential_templates`/`credential_issuance_service` engine** (constitution §12) — the dlu-badge/`domains/badge(s)` tracks were deliberately left unconsolidated (real, pre-existing redundancy, see `sprint_decisions_20260723_stx13.md` §1) | ✅ | unify with constitution templates 🔵 (still open — now THREE-plus parallel badge/credential tracks, not two) |
| VC composition | `CredentialService` — OB 3.0 JSON-LD (`CourseAchievement`, unsigned) · **STX-13's `credential_issuance_service` — signed OB 3.0/VC-EDU JSON, `eddsa-jcs-2022` Data Integrity proof** | ✅ **signed (STX-13)** | KMS/HSM key custody + rotation logic (env/Fernet + versioned-key shape only, phase 1) ⚪ |
| Learner/admin surfaces | credentials + badges routes · **STX-13 WS07 `CredentialWallet.js`** | ✅ | visual unification across the parallel badge tracks 🔵 |
| Criteria engine | `credential_criteria_service.py` — deterministic (no LLM), competency-mastery + course-completion kinds | ✅ **STX-13** | richer criteria DSL if a real need arises |
| Verification endpoint | `GET /api/credentials/verify/{public_id}` — public, offline-verifiable, `EXEMPT_PATHS` | ✅ **STX-13** | — |
| Status-list revocation | `credential_revocation_service.py` — W3C Bitstring Status List, platform-schema row-locked index allocator, derived read-model | ✅ **STX-13** | 2-bit encoding (suspended vs revoked distinguishable remotely) if a real need arises |
| Wallet import | `POST /api/wallet/import` — OB 2.0/3.0 JSON → unverified, pending `RecognitionClaim` | ✅ **STX-13 (unverified-import tier only)** | cryptographic verification of externally-issued signatures (needs an external issuer trust registry — not built) |
| Transcript/ECTS views | ERPNext/ESSE3 mirror + outcomes — **as of NEW-08 (2026-07-25), a real generator: `document_credential_service.generate_transcript`, reusing the evidence-timeline aggregation** | ✅ **NEW-08** | letter-grade/GPA model (v1 uses an honestly-documented evidence-weighted score proxy — no such model exists anywhere yet) |
| G9 documents | **NEW-08 (2026-07-25)**: `document_credential_service.generate_self_certification` — learner-triggered, no institutional attestation, PDF via reportlab (not weasyprint — no native cairo/pango deps in this environment, see sprint decisions note) | ✅ **NEW-08 (self-cert only)** | official-certificate stamp/seal/payment drivers — PagoPA is a local always-unpaid STUB (`backend/drivers/pagopa_stub.py`); the real adapter is NEW-12/K5 |
| G10 Diploma Supplement | catalog + outcomes + mirror all present — **as of NEW-08, a real generator + a bounded ELM-lite JSON Schema (`elm_lite_schema.py`, v1)** | ✅ **NEW-08 (ELM-lite, NOT full Europass ELM conformance)** | full Europass ELM interop certification (explicitly out of scope, documented as such in the schema's own `$comment`) |
| G11 clearance | GPS path-health (STX-07) — **as of NEW-08, a real checklist + application + waiver flow**: 5 named criteria (`requirement_completion`/`verbalization` from live `PathHealth`, `fees_settled` from live `FinancialHold.blocks_credentials`, `thesis_deposited`/`surveys_done` honestly `not_yet_available` — no Thesis/Committee/Survey model exists yet), a 4th `waived` state (registrar-set, reason-required, audited) alongside `green`/`not_yet_available`/`red`, reachable iff every criterion is `{green, waived}`, resolved LIVE on every read (never frozen at filing — only frozen into `source_snapshot` at registrar confirmation) | ✅ **NEW-08** | `thesis_deposited`/`surveys_done` resolvers are stubs pending NEW-06 (Thesis+Committee) and a future Survey model — both are resolver swaps, not schema migrations, by design; the physical parchment/committee legal-act chain stays institution-side, out of scope |
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


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

Core unchanged; add the Course Format v2.0 credential / Open Badges 3.0 export path from the authored course.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
