# BOOK-19 — Governance, Security & Compliance
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The Book that makes DAS-Certified possible. It consolidates the governance
> RACI scattered across the Masterbook, specifies the security architecture,
> maps the **EU AI Act** obligations to kernel mechanisms, and defines two
> verified **regulatory profiles**: the **Italian profile** (SPID/CIE, AgID,
> eIDAS/conservazione, PagoPA, ANS) and the **US distance-education profile** —
> whose verification produced two findings of strategic weight for any
> AI-native university: **Regular & Substantive Interaction** (AI interaction
> does not count as instructor interaction for Title IV — G12) and **student
> identity verification** under 34 CFR 602.17(g) (login alone is insufficient —
> G13).
>
> **Conforms to:** BOOK-00 v2.0 (Ch. 11–12). **Depends on:** all Books (it
> governs them). **Informs:** BOOK-20 (conformance suite), BOOK-08 (I5 feeds).
> **Primary audience:** compliance, DPO, CISO, registrars, AI Review Board,
> accreditation liaisons.

**Normative language:** RFC 2119.

---

# Chapter 1 — The Four Governance Layers, Consolidated

BOOK-00 Ch. 11 named them; the Masterbook distributed their content; this
chapter is the single index:

| Layer | Body | Cadence | Owns (with Book refs) |
|-------|------|---------|----------------------|
| Academic | Senate / Program Boards | per statute | curriculum core, I/R/M maps (01), CAT criteria (01), assessment policy (15), program lifecycle (08) |
| AI | AI Review Board (faculty+students+ethics+eng) | monthly min. | autonomy tiers (02), envelope floors (07), releases & incidents (10/11), calibration drift (09), memory incidents (12) |
| Data | DPO office | continuous | consent taxonomy (04), retention (this Book), erasure (06), DPIA, region pinning |
| Architecture | Architecture Board | per release | DAS conformance (03), ADR/RFC lifecycle (00), ontology registry (05), driver contracts (18) |

## 1.1 Consolidated RACI (decision extract — the normative full table)

| Decision | R | A | C | I |
|----------|---|---|---|---|
| Agent release (learner-facing) | AI Pedagogy Steward | AI Review Board | envelope-owner faculty | tenants |
| Envelope floors/ceilings | Steward | Review Board | Senate (pedagogy) | faculty |
| `verified` competency status | examiner | faculty of record | — | learner |
| Credential issuance (reserved) | Evidence Registrar | Registrar | committee (G6) | learner, wallet |
| Credit recognition | Recognition officer | Registrar | program director | GPS (event) |
| Intervention (at-risk) | Advisor | Advisor lead | Success team | learner (consent-shaped) |
| Twin staff access grants | role admin | DPO | — | audit |
| Retention/erasure exceptions | DPO | DPO | Registrar (credential evidence) | learner |
| Driver contract changes | integration lead | Architecture Board | affected engine owners | ops |
| Model/prompt/corpus change | engineer | Steward | faculty (course-scoped) | Review Board |
| Teach-out / program retirement | Program director | Provost + Board | GPS impact analysis | students (guaranteed plans) |

Staffing rule (BOOK-02 §3.2): Learning Engineer, AI Pedagogy Steward and
Evidence Registrar are **accountabilities that MUST exist**, merged into
existing roles only at small scale, never absent.

---

# Chapter 2 — Security Architecture

1. **Identity chain:** Keycloak OIDC as the hub (BOOK-03); MFA for staff and
   for high-stakes learner acts (sessions enrollment, credential export);
   **Italian profile: SPID/CIE brokered through Keycloak** (Ch. 5); service-to-
   service zero-trust (authenticated calls, no ambient trust).
2. **Secrets & keys:** env/vault only (running rule); **key classes**: platform
   secrets (JWT, HMAC driver secrets), gateway master key (env only, never
   DB — running rule), **issuer DID keys** (BOOK-16 — KMS-held, ceremony-
   created, rotation schedule, key compromise ≠ credential revocation:
   re-anchoring procedure documented).
3. **Data protection:** classification per BOOK-04 Ch. 8; encryption in
   transit (TLS everywhere) and at rest (DB, media, backups); *sensitive-
   learning* class additionally: consent-gated access paths only, region-pinned
   storage, aggregate-only analytics (n≥10), field-level encryption for L7
   memory content SHOULD be applied.
4. **Application security:** OWASP ASVS baseline; the AI-specific ingress/
   egress defenses of BOOK-11 Ch. 5 (injection, RAG poisoning, PII egress);
   rate limiting (Kong + per-agent caps); dependency and image scanning in CI.
5. **Audit fabric:** the union of — kernel mutation logs, twin access purposes
   (06), ACE cycle traces (09), agent run logs (10), envelope changes (07),
   consent changes (04), driver acts cross-references (16/18), admin actions
   (`PlatformAuditLog`). Retention: audit-grade classes survive erasure
   (audit ≠ memory, BOOK-12); tamper-evidence (append-only + hash chaining
   SHOULD).
6. **Incident response:** severity classes (privacy F6, integrity F4/F5,
   crisis F7 mishandling, security breach); paging paths; regulatory clocks
   (GDPR 72h breach notification); every AI incident feeds the scenario bank
   (BOOK-11 — the immune system).

---

# Chapter 3 — EU AI Act Mapping (deployer obligations → mechanisms)

Education is Annex III high-risk (BOOK-00 Ch. 12). The mapping the standard
commits to:

| Obligation | Kernel mechanism |
|-----------|------------------|
| Risk management system | risk register (00 Ch. 12.3 + living I5), scenario bank + shadow evals (11), misbehaviour playbook (10) |
| Data governance & quality | BOOK-04 classes, consent taxonomy, calibration monitoring (01/09) |
| Technical documentation | this Masterbook + release records (10) + trace schemas (09) |
| Record-keeping / logs | audit fabric (Ch. 2.5) — cycle-level traceability |
| Transparency to users | AI disclosure notices, "why?" affordance (17), agent attribution, memory panel (12) |
| **Human oversight** | HITL tiers (02), envelope owners (07), deferral triggers (09), reserved decisions RACI (Ch. 1.1) |
| Accuracy & robustness | eval gates (11 Ch. 6), calibration floors (09), drift alarms |
| FRIA (fundamental rights impact) | template + trigger list (new deployments, new cohium classes); equity guardrails as standing FRIA evidence |
| Serious-incident reporting | incident classes (Ch. 2.6) with regulator notification path |

Register status renders in I5 (BOOK-08); red items are board-visible by
construction.

**✅ implemented (NEW-13, 2026-07-31):** `ai_act_risk_class`/`ai_act_role`
are two new nullable columns on the existing, live `platform
.ai_agent_configs` registry (9 seeded rows) — extending it rather than
resurrecting either dead-code AI-governance attempt already in the
codebase. `ai_act_obligations` (one row per `(ai_agent_config_id,
obligation_key)`, the nine obligations above) is seeded — never
overwriting an already-attested row — at the agent's `testing ->
deployed` lifecycle transition, which also opens a `fria_assessments`
row (`trigger_kind="new_deployment"`; `trigger_kind="new_cohort_class"`
is a valid, CHECK-constrained value with no automatic trigger wired yet
— this codebase's `Cohort` model is a course-pacing construct, not the
"new deployment context" this chapter means, and its service is legacy
sync code incompatible with an async trigger without a larger refactor).
FRIA reports are structured JSON (`template_json`), never a rendered
PDF — no such requirement exists anywhere in this Masterbook. A single
non-`verified` obligation anywhere renders the WHOLE register posture
`partial` in I5, never rolled up green.

---

# Chapter 4 — GDPR / FERPA Core

Lawful bases per twin layer (contract for L1–L4; consent for L5–L7 purposes —
BOOK-04 §5.2); DPIA required for: behaviour analytics, risk scoring, proctoring
(if ever enabled), cross-border federation; **erasure** per BOOK-06 Ch. 9.3
(with the credential-evidence pseudonymization exception, documented);
**FERPA**: education-records access rights map to the open learner model
(inspection is native), directory-information policies per tenant, audit of
disclosures = twin access log. Dual-region posture per the running compliance
architecture; minors: guardian consent flows + age-appropriate egress (11).

---

# Chapter 5 — Italian Regulatory Profile (verified)

| Requirement | Basis | DLU mechanism |
|-------------|-------|---------------|
| **SPID/CIE access** to online services (exclusive since 1 Oct 2021; exceptions: foreign students, minors) | CAD art. 63; DL 76/2020 (Semplificazioni) | Keycloak identity brokering to SPID/CIE IdPs; fallback local credentials only for the sanctioned exception classes; ESSE3 sessions already SPID-based on the driver side |
| AgID minimum ICT security measures (PA) | AgID circulars | Ch. 2 posture mapped to the AgID measure classes; self-assessment in I5 |
| Qualified signatures + legal preservation | eIDAS; CAD | G3 boundary (16 Ch. 8): QES/conservazione at ESSE3 or QES driver — never reimplemented |
| Public payments (bollo, fees) | PagoPA obligation | PagoPA driver (18) for G9 documents and fees |
| Accessibility | Legge Stanca / EN 301 549 | BOOK-17 Ch. 6 WCAG 2.2 AA floor + accessibility declarations |
| ANS/SUA-CdS | MUR/ANVUR | G8 completeness monitor + dossier export (08); compliance calendar Ch. 7 |
| Regulation-year cohort rules | ordinamenti | G7 (08/14/15 consumers) |
| **Telematic accreditation: DE/DI quotas, tutors, LMS logs** | ANVUR AVA (telematiche procedures + CEV guidance) | **G14 — §5.1 below** |

## 5.1 The telematic regime — G14 (added by Masterbook Review R2)

Fully online Italian universities are accredited under ANVUR's dedicated
telematic procedures, whose distinctive requirements the platform MUST
instrument:

1. **DE/DI classification and quotas.** Teaching activity divides into
   **Didattica Erogativa** (DE — one-way delivery: recorded lectures,
   courseware, slide/PDF content) and **Didattica Interattiva** (DI —
   instructor-involving interaction: web-conference seminars, assessed
   e-tivities, facilitated discussions, virtual labs), with **minimum hours
   per CFU** on the combined total and floors on each per ANVUR guidance.
   Orientation-only tutoring is **excluded** from DI. This is the Italian
   counterpart of US RSI (G12) — and gets the same treatment:
   - course designs MUST declare their DE/DI composition (the FEX blueprint
     `media_mix` + activity typology carries the classification — BOOK-05
     §4.4 FEX v1.4 item);
   - the kernel maintains a **DE/DI ledger** per CFU per course (sibling of
     the RSI ledger — same delivery events, Italian classification), with
     under-quota alerts *before* CEV visits;
   - **AI boundary:** agent interaction does not count toward DI (as AI does
     not count toward RSI); AI legitimately absorbs orientation tutoring —
     which ANVUR excludes from DI anyway — freeing humans for the DI quota.
     The mentorship dividend is, once again, the compliance strategy.
2. **Tutor figures.** ANVUR distinguishes qualified disciplinary tutors from
   orientation tutoring; role mapping: tutor disciplinare ↔ instructor/
   qualified-tutor roles with DI-countable events; orientation ↔ Coach/
   Success agents + staff.
3. **LMS tracking logs as evidence.** The xAPI stream + DE/DI ledger export
   is the CEV evidence package — provable where incumbents self-declare.
4. **CEV procedures.** The living self-study (BOOK-08 §6.1) gains a
   telematic-profile section aligned to the dedicated CEV indicator set.

**✅ implemented in part (NEW-13, 2026-07-31):** items 1–2 (declaration +
ledger + AI-boundary + under-quota alerting) are real —
`de_di_classification` is a new nullable JSON column declared per
module (colocated beside `media_mix` on `ModuleBlueprint`, per-course
via the SAME roster-anchored ledger function G12 uses,
`regime="de_di"`); Italian telematic courses are selected via
`Program.credit_system=='ects'` + `delivery_mode=='online'` (the
closest existing proxy for "telematic" — no dedicated boolean column
exists yet); the under-quota floor is a documented, institution-
overridable placeholder (`DEFAULT_DI_HOURS_PER_CFU_FLOOR`), never
presented as an ANVUR-sourced figure, since no concrete number is
specified anywhere in this Masterbook. Items 3–4 (tutor-figure role
mapping, FEX v1.4 formal item, CEV-indicator-aligned living-self-study
section) are **NOT built this sprint** — an honest carry-forward, not
claimed done.

---

# Chapter 6 — US Distance-Education Profile (verified — strategic findings)

## 6.1 Regular & Substantive Interaction — G12 (new)

34 CFR 600.2: distance education requires **regular and substantive
interaction between students and instructors** — substantive = engaging in
teaching/learning/assessment **plus at least two of**: direct instruction;
assessing or providing feedback on coursework; responding to content
questions; facilitating content discussions; other agency-approved activities.
"Regular" = predictable/scheduled + instructor monitoring of engagement.
Courses failing RSI are **correspondence courses**: Title IV repayment
exposure, and >50% correspondence threatens all federal aid eligibility.

**The AI-native implication (normative):** interaction with DLU agents —
however excellent — is NOT instructor interaction. Therefore:

1. Every US-profile course MUST have a declared **RSI plan**: scheduled
   instructor activities (feedback on summatives — already faculty-signed per
   BOOK-15; content discussions; office hours G1; vivas) with predictable
   cadence.
2. The kernel MUST **instrument RSI evidence**: faculty interaction events
   (already emitted: Gate-2 reviews, feedback sign-offs, forum facilitation,
   bookings, viva sessions) aggregated per course × student × term into an
   **RSI ledger** — audit-ready proof that no learner fell into
   correspondence-mode. F5 (BOOK-07) already counts these hours; G12 adds the
   per-student regulatory ledger and alerting (a student with zero instructor
   touchpoints in N weeks is a compliance alert *and* a Success signal).
3. **Strategic reading:** legacy universities assert RSI; DLU **proves** it
   from kernel events — the mentorship dividend (BOOK-02) is also the
   compliance strategy. AI absorbs routine load precisely so instructor
   interaction is abundant and documentable.

**✅ implemented (NEW-13, 2026-07-31):** `rsi_plan` is a new nullable
JSON column declared per module (colocated beside `media_mix`); the
ledger is roster-anchored — active `CohortEnrollment` rows LEFT JOINed
against `StudentExamAttempt` human sign-offs (`grader_id`/`graded_at`
both set — the only real, course-attributed source), which is what
makes a *zero*-touchpoint provable at all. Office-hours bookings,
thesis-milestone approvals, and viva completions are tallied as a
student-attributed, course-agnostic supplement, reported alongside
rather than merged into the course-level rows. **The gap this chapter's
own "already emitted" phrase assumed away turned out to be real and is
now explicitly disclosed, not hidden:** forum facilitation and web-
conference attendance are NOT captured anywhere as role-attributed
events today (`XAPIStatement.actor_id` has no role field, confirmed by
this sprint's own fact-check) — every ledger row carries a
`data_completeness` block naming exactly this gap. Extending the Moodle
driver contract to close it is explicitly out of this sprint's scope, a
future fix.

## 6.2 Student identity verification — G13 (new)

34 CFR 602.17(g)/(h): institutions must establish that the registered student
is the one who academically engages; secure login alone is deemed insufficient
(post-2020 tightening); processes must **protect privacy** and **disclose any
extra verification charges at registration**.

DLU mapping: layered verification = Keycloak MFA (+SPID-grade assurance where
available) · assessment-integrity layers (BOOK-15 Ch. 9: authentic tasks with
process evidence, dialogic verification — a viva is the strongest identity
check in existence) · session-based checks for high-stakes (proctoring last
resort, consented, DPIA'd). **G13 deliverables:** a per-tenant Identity
Verification Policy artifact (methods per assessment class), registration-time
disclosure (charges), and privacy documentation — surfaced in I5.

**✅ implemented (NEW-13, 2026-07-31):** `identity_verification_policies`
(per-tenant, versioned) resolves LIVE via `resolve_identity_verification
_policy` — never written by the resolver itself, same never-write
discipline as `clearance_service.resolve_clearance_checklist`.
Registration-time disclosure is recorded as a new versioned key in the
twin's EXISTING `consent_flags` JSON, idempotent per policy version — a
re-registration at an unchanged version never duplicates the record.
`tenant_id` is a required, validated parameter on the write path (a
real cross-tenant IDOR was found and fixed here by independent security
review before this sprint landed — see
docs/sprint_decisions_20260731_new13.md).

## 6.3 Title IV mechanics

**Academic engagement / last date of attendance:** federal definitions count
submitting assessments, interactive tutorials, participating in instruction —
*not* mere login. DLU's xAPI stream natively distinguishes these classes;
the engagement ledger yields audit-grade last-date-of-attendance per learner.
**Credit hour:** ECTS/credit projections (BOOK-16 Ch. 6.1) MUST document the
work-based equivalency per federal credit-hour definition. **State
authorization / NC-SARA:** enrollment by state tracked; SARA status per tenant
in the compliance calendar. **Misrepresentation:** marketing claims (P01
funnel) reviewed against outcomes data — the scorecard keeps marketing honest.
**ADA / Section 508:** BOOK-17 accessibility floor + procurement statements.

---

# Chapter 7 — The Compliance Calendar and Living Registers

I5-rendered (BOOK-08), owned by compliance, fed by kernel events:

| Register / cadence | Content |
|--------------------|---------|
| AI Act register (continuous) | Ch. 3 posture, incidents, FRIA status |
| DPIA register | assessments + review dates |
| Consent & disclosure versions | notices, identity-verification disclosures (G13) |
| **RSI ledger review** (per term, US profile) | per-course RSI health, zero-touchpoint alerts (G12) |
| **DE/DI ledger review** (per term, IT telematic profile) | per-CFU DE/DI quota health, under-quota alerts, CEV evidence freshness (G14) |
| ANS spedizioni (per MUR calendar, IT profile) | completeness pre-checks (G8) |
| Accreditation cycles | dossier freshness (living self-study, 08) |
| Key ceremonies & rotations | DID/issuer keys (16), driver secrets |
| DR exercises (quarterly) | kg-rebuild, restore drills (18) |
| Board reviews | Review Board minutes, incident trends, equity reports |

**✅ implemented (NEW-13, 2026-07-31):**
`compliance_calendar_service.py::compute_compliance_calendar` is ONE
compute-on-read function serving both row kinds — no materialized
calendar table (the durable evidence already lives in the registers/
ledgers above; materializing occurrences would add a reconciliation
burden for zero audit benefit). Schedule-only rows (AI Act register,
DPIA register, consent/disclosure versions, ANS spedizioni,
accreditation cycles, key ceremonies, DR exercises, board reviews) come
from a small static cadence catalog plus one row per
`program_state_disclosures` entry (the Masterbook Review M7 licensure-
disclosure item, structurally distinct from G13 though textually
adjacent). Evidence-driven rows (RSI ledger review, DE/DI ledger
review) call Ch. 6.1/§5.1's ledger function live against the
institution's current `AcademicTerm`; no current term configured
degrades honestly to `not_yet_available`. Surfaced as a new section of
the EXISTING I5 `compute_compliance_posture` response — no standalone
calendar route or workspace.

---

# Chapter 8 — G-Register Check (standing verification)

| Gap | Disposition |
|-----|------------|
| G1–G6 | consumed upstream (07/15/16/17) — governance hooks (committees formation approval, register approval, verbale boundary) codified in RACI ✅ |
| G7 | regulation-year rules enter as versioned policy objects; change control here ✅ |
| G8 | ANS calendar + completeness monitor governance (Ch. 7) ✅ |
| G9/G10/G11 | document credentials legal boundaries (bollo/PagoPA, DS issuance, clearance acts) mapped to Italian profile ✅ |
| **G12 RSI instrumentation** (new) | **owned here, ✅ engineered NEW-13 (2026-07-31)**: RSI plan requirement + roster-anchored ledger + zero-touchpoint alerts (Ch. 6.1) — Moodle instructor-event under-count disclosed via `data_completeness`, not silently closed |
| **G13 identity-verification policy** (new) | **owned here, ✅ engineered NEW-13 (2026-07-31)**: layered verification + live-resolved versioned policy artifact + registration disclosure (Ch. 6.2) |
| **G14 DE/DI telematic regime** (Masterbook Review R2) | **owned here, ✅ engineered in part NEW-13 (2026-07-31)**: DE/DI classification + ledger + under-quota alerting (Ch. 5.1) — tutor mapping, FEX v1.4 formal item, and CEV evidence NOT yet built, an honest carry-forward |
| **G15 catalog as legal contract + explorer** (stakeholder review) | governance hook here: edition publication is a governed act (Senate/board approval → effective); consumer-protection reading — the pinned edition is the enforceable promise (misrepresentation guard applies to explorer content); resolution in 04/14/16/17, sprint NEW-16 |
| **G16 credit pre-evaluation + rule packs** (stakeholder review) | governance hooks here: rule-pack changes are governed acts (DM 931/2024 caps, PLA/residency parameters — versioned, effective-dated, G7-aware); Tier-1 estimates carry the non-binding marker (misrepresentation guard); Tier-2 adjudication is council HITL (Committee, G6); prospect-document retention limits + `career_processing` consent; PLA-fee and portability disclosures (G13 discipline); resolution in BOOK-14A, sprint NEW-17 |

Register now **G1–G16**.

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Governance bodies & proposals | ai_governance service, approval routes | ✅ | RACI codification + board tooling 🟡 |
| Identity & MFA | Keycloak, SAML/OIDC services | ✅ | SPID/CIE brokering (IT profile) ⚪ |
| Secrets | env conventions, encrypted tokens | ✅ | KMS + DID key ceremony ⚪ (rides NEW-07) |
| Audit fabric | audit logs, purpose-tagged twin reads (STX-02), run logs | 🟡 | hash chaining, unified query ⚪ |
| AI Act register | governance dashboards | 🟡 | obligation register + FRIA templates ⚪ (NEW-13) |
| GDPR/FERPA | compliance/multiregion architecture, dual-region compose | ✅ arch | executable erasure job ⚪ (BOOK-06) |
| RSI ledger (G12) | xAPI + faculty events (Gate-2, feedback, bookings, vivas) all present/planned | ⚪ | ledger aggregation + alerts |
| Identity verification (G13) | MFA + BOOK-15 integrity layers | 🟡 | policy artifact + disclosure flow |
| Engagement/attendance | xAPI classes | ✅ | Title IV engagement mapping doc 🔵 |
| Compliance calendar | I5 design (08) | 🔵 | register implementations (NEW-13) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Regulatory profile | Deployment-scoped compliance bundle (Italian, US distance-ed) |
| RSI ledger (G12) | Per-course × student record of instructor interaction events — Title IV evidence |
| DE/DI ledger (G14) | Per-CFU classification of delivery events into Didattica Erogativa/Interattiva — ANVUR telematic evidence |
| Correspondence risk | Classification failure when RSI is absent; Title IV exposure |
| Identity Verification Policy (G13) | Per-tenant artifact: methods per assessment class + registration disclosure |
| Engagement ledger | xAPI-derived academic-engagement record; last-date-of-attendance source |
| FRIA | Fundamental Rights Impact Assessment (AI Act) |
| Re-anchoring | Issuer key compromise procedure preserving credential validity |

---

*BOOK-19 v1.0 — awaiting review. G-register: G12/G13 added and owned; register
G1–G14. Next and last: BOOK-20 (Implementation Blueprint).*

**Sources (regulatory verification):**
[eCFR — 34 CFR 600.2 (distance vs correspondence education, RSI definition)](https://www.ecfr.gov/current/title-34/subtitle-B/chapter-VI/part-600/subpart-A/section-600.2) ·
[eCFR — 34 CFR 602.17 (identity verification, application of standards)](https://www.ecfr.gov/current/title-34/subtitle-B/chapter-VI/part-602/subpart-B/subject-group-ECFR941656d458ef3eb/section-602.17) ·
[WCET — Student Identity Verification](https://wcet.wiche.edu/policy/student-identity-verification/) ·
[OLC/ERIC — Regular and Substantive Interaction](https://files.eric.ed.gov/fulltext/ED593878.pdf) ·
[Dipartimento Trasformazione Digitale — SPID/CIE dal 1 ottobre](https://innovazione.gov.it/notizie/articoli/identita-digitale-dal-1-ottobre-si-accede-ai-servizi-pubblici-con-spid-e-cie/) ·
[UniFI — SPID per i servizi di Ateneo](https://www.unifi.it/it/ateneo/spid-sistema-pubblico-di-identita-digitale) ·
[ANVUR — Accreditamento periodico Università Telematiche (finalità e procedure)](https://www.anvur.it/sites/default/files/2025-02/2_AVA1_Finalit%C3%A0%20e%20procedure_Telematiche.pdf) ·
[Linee guida DE/DI — esempio attuativo](https://ava.unipegaso.it/quadri/2021/file/DE-DI-Linee-guida-didattica-erogativa-e-interattiva_LINK_B1D.pdf)
