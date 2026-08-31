# RFC-0001 — Course Lifecycle Console: integration into the DAS paradigm

Status: **Proposed** · Author: architecture review, 2026-08-07
Owner Books: **22** (Faculty Lifecycle) · **17** (Experiences) · **23** (Financial Operations)
Affected registers: **G18** (re-opened as G18.1–G18.4, partial), **A6** (event taxonomy)
Supersedes: nothing · Superseded by: nothing

> **Verdict up front.** The STU Course Lifecycle Console prototype
> (`DLU_Course_Builder_v2.0_Lifecycle_Console.html`) re-implements, client-side,
> a pipeline that BOOK-22 already normativizes and `dlu_builder_tk` already
> ships: 9 tables, 4 services, 3 route modules, 3 pages, 12 registered events.
> It MUST NOT be merged as a system. It is admitted as **(a)** the UX
> specification for a missing faculty workspace, **FW6**, and **(b)** the source
> of a set of genuinely new capabilities the running implementation does not
> have. Everything else in it is deleted on integration.
>
> **Second pass (2026-08-07):** a federated-faculty requirement — course
> developers who are already faculty at a partner university — added deltas
> **D11** (no engagement-type discriminator, no federation registry) and
> **D12** (a latent DM 1154 accreditation defect that D11 would activate), and
> sprints **FW6-09/FW6-10**. See §4.7.

---

## 1. Context

`Course Creation Process v1.0` (the STU authoring guide) was normativized as
BOOK-22 and delivered across SPRINT-08/NEW-20a (onboarding + contracting),
SPRINT-09/NEW-20b (milestones, deliverables, reviews) and SPRINT-10/NEW-21
(HR positions + workload ledger). TRACEABILITY marks **G18 fully closed**.

Independently, a process reconciliation exercise produced *STU Digital Faculty
Onboarding, Contracting and Course-Creation Process v2.0*, which integrates
three bodies of practice the v1.0 guide did not carry: the Provost/Deans
academic gate model, the Corporate Secretariat contracting protocol, and the
real STU legal instruments (IISA + Exhibit A + Exhibit B + Consent form). A
single-file prototype was then built on top of `DLU_Course_Builder_v1.3.html`
to demonstrate that process end to end.

That prototype is what this RFC dispositions.

## 2. Duplication audit (normative — nothing below may be re-built)

Everything in this table **exists and runs today**. The Console's equivalent is
discarded.

| Console artefact | Already implemented as | Location |
|---|---|---|
| `engagement.developer` record, statuses | `FacultyOnboardingJourney` (7 statuses) + `FacultyProfile.onboarding_status` | `models_faculty_lifecycle.py` |
| Document slots | `FacultyDocument` + `FacultyDocumentVerification` | same |
| HR completeness check | `faculty_onboarding_service` + `/api/faculty-onboarding/verification-queue` | `backend/api/routes/faculty_onboarding.py` |
| `engagement.contract` + envelope | `AuthoringEngagement` (+ `executed_pdf_storage_uri`/`content_hash`/`source_snapshot`) | `models_faculty_lifecycle.py` |
| Contract generation from template | `ContractTemplate.body_template` (structured JSON) + deterministic `reportlab` renderer | `faculty_engagement_service.py` |
| E-signature envelope, ordered signing | `EngagementSignature` (+ `sequence_order`, `qes_signature_ref_id`) | same · `models_qes.py` subject col `dlu_engagement_signature_id` |
| 30/70 split | `AuthoringEngagement.design_fee_pct`/`.full_course_fee_pct`, CHECK sums to 100 | same |
| Milestones | `EngagementMilestone` (`course_design`/`full_course`, 5 statuses) | same |
| Deliverable release | `EngagementDeliverable` (+ soft `content_ref_type`/`content_ref_id`) | same |
| Gate 2 / Gate 3 review form | `DeliverableReview` (`approved`/`changes_requested`/`rejected` + `checklist` JSON) | same |
| Design lock after milestone 1 | `engagement_milestone_service.reopen_milestone` (reason required) | `engagement_milestone_service.py` |
| Invoice authorisation from a gate | `ap_service.generate_supplier_invoice_from_milestone`; `supplier_invoices.milestone_id` is a **NOT NULL FK** | `models_finance.py` · `ap_service.py` |
| Invoice lifecycle + payment | `supplier_invoices` → `payment_runs` (CFO-gated) | `ap_service.py` · `/api/supplier-invoices`, `/api/payment-runs` |
| Audit trail | `platform.audit_logs` (C22.5) + `course_workflow_events` (append-only) | `models_platform.py` · `models.py` |
| FEX export incl. `authorship`/`quality_log` | `course_exchange_service.export_course` + `_build_quality_log` reading real `ReviewCheckpoint`/`CourseWorkflowEvent`/`QAResult` rows | `course_exchange_service.py` |
| Blueprint completeness check | `course_workflow.blueprint_readiness` (MLO/media/assessment per module) | `course_workflow.py` |
| Developer-facing onboarding page | `FacultyOnboarding.js` → `/faculty/onboarding` | `frontend/src/pages/faculty/` |
| Staff verification + signature desk | `FacultyVerificationQueue.js` → `/organization/faculty-verification-queue` | `frontend/src/pages/institution/` |
| AP / budget desk | `APBudgetDashboard.js` → `/admin/finance/ap-budget` | same |
| Workload ledger desk | `OrganicoWorkloadDesk.js` → `/organization/organico-workload` | same |
| Role switcher | real RBAC: `UserRole` + `platform.role_scopes` + `ProtectedRoute` | `models.py` · `AppRoutes.js` |
| Persistence | Postgres + tenant isolation; **never** `localStorage` | — |
| Design-system widgets | `ds/`: `SignatureFlow`, `ProcessStepper`, `WorkQueue`, `DocChecklist`, `MoneyTable`, `AuditTimeline`, `StatusBadge`, `AIProposalCard` | `frontend/src/components/ds/` |

**Rule RFC1.1** — No new table, service, route or page may be created for any
row above. A sprint that does so fails review.

## 3. The real deltas (what the Console legitimately adds)

Twelve findings survive the audit. Six are capability gaps, four are normative
conflicts, one is hygiene, one is a latent compliance defect. D11–D12 were
added on the second pass, when the federated-faculty requirement surfaced.

| # | Delta | Kind | Evidence |
|---|---|---|---|
| D1 | **Signature order is inverted.** BOOK-22 §2 and the code require university-first (`ENGAGEMENT_SIGNER_ROLES = {"provost","cfo"}`), then instructor. STU's real protocol is developer → Corporate Secretariat verification → Chairman execution. | conflict | `models_faculty_lifecycle.py:141`; Corporate Secretariat protocol; sanitised IISA signature block |
| D2 | **The Chairman *persona* is recognised, the *role* is not.** BOOK-24 §3 lists a "Chairman Board Pack" surface and `ChairmanBoardPack.js` ships (SPRINT-16/NEW-27), but `UserRole` has no `chairman` — the persona is mapped onto admin-tier roles (`EXECUTIVE_COMMAND_STAFF_ROLES`). `secretariat` does not exist in any form. `VALID_SIGNER_ROLES = ("provost","cfo","instructor")`. **Doc-sync failure found in passing:** `AppRoutes.js:350` attributes this limitation to "BOOK-24 Annex A's own documented v1 limitation" — that disclosure is **not present in BOOK-24**. Signing is where a mapped-on persona stops being acceptable: an executed contract must name who actually signed. | conflict | `models.py:151`; `models_faculty_lifecycle.py:134`; `AppRoutes.js:350,706`; BOOK-24 §3 |
| D3 | **Document taxonomy is closed at three types** (`personal_id`, `career_transcript`, `fiscal_data`). The real intake needs CV, degree certificates, licences, a *typed* W-9 / W-8BEN / W-8BEN-E, contractor-classification statement, work authorisation. A CHECK constraint blocks all of them. | gap | `VALID_FACULTY_DOCUMENT_TYPES` |
| D4 | **No usable consent registry.** The Course Developer Consent, Certification and Acknowledgment Form (10 items, 9 mandatory, item 10 tri-state) has no model. A `ConsentRecord` *does* exist — in `backend/domains/marketing/`, an **orphan domain not registered in `main.py`**, shaped for GDPR marketing consent (`channel`/`status` per email/phone), which cannot express per-item contractual certifications. Reusing it would recreate, in reverse, the "three incompatible hold concepts" problem `administrative_holds` had to unify. Item 6 (generative-AI disclosure) is a BOOK-19 AI Act obligation currently carried on paper. | gap | `backend/domains/marketing/models.py:421`; no route registration in `api/main.py` |
| D5 | **No academic qualification gate.** Onboarding verification is *document* verification by back-office. STU Gate 1 is an academic judgement by the sponsoring Dean, with a Provost-level transcript waiver. Nothing models it. | gap | `faculty_document_verifications.decision ∈ (verified, rejected)` |
| D6 | **No catalogue reservation.** `authoring_engagements.course_id` is an unconstrained soft Integer ref. Two Deans can commission the same course; the Secretariat protocol names this as the failure to eliminate. | gap | `models_faculty_lifecycle.py:302`; no assignment status in `models_course_catalog.py` |
| D7 | **No Exhibit A / Exhibit B structure.** Scope, module list, deliverable taxonomy (61 discrete items for PHA 500), acceptance criteria, review window, revision-round cap and tolling exist only as prose in the signed PDF. The system cannot compute or enforce them. | gap | no scope/exhibit tables |
| D8 | **The review checklist is decorative.** `DeliverableReview.checklist` is a free-form JSON dict a reviewer fills in manually — BOOK-22 v0.3 says so explicitly. `blueprint_readiness` computes only MLO/media/assessment presence. Neither checks CLO count/Bloom variety, the 12–15 h envelope, feedback density, grading weights or video transcripts. | gap | BOOK-22 §2 correction (1); `course_workflow.py:199` |
| D9 | **Three competing gate numbering schemes.** `CourseWorkflowState` (`blueprint_validation`/`faculty_review`/`under_dean_review`), FEX v1.3 `checkpoint_type` (`gate1_blueprint`/`gate2_content`/`gate3_publication`), and STU v2.0 (Gates 1, 1b, 2, 3, 4). They are mutually offset. `ReviewCheckpoint`'s own CHECK allows a *fourth* set (`syllabus`/`lesson_content`/`qa_report`/`final_preview`). | conflict | `models.py:364`, `models.py:1179`; `course_exchange_v1.3_example.json` |
| D10 | **R22.2 is not event-driven.** BOOK-22 claims `MilestoneApproved → supplier_invoices`; in reality nothing subscribes and generation is an explicit call. BOOK-22 v0.3 already discloses this. The Console assumed the documented behaviour. | hygiene | BOOK-22 §2 correction (2); `ap_service.py` |
| D11 | **One engagement type only.** BOOK-22 assumes every author is an external independent contractor paid by STU. A course developer who is already faculty at a **federated university** (eCampus, Unilink, …) is a different legal animal: their credentials are already verified by their employer, their work may be covered by an inter-institutional agreement, and issuing them an IISA — whose §1 asserts they are *not* an employee — is a misclassification risk against a person who **is** an employee, of someone else. No engagement-type discriminator, no federation registry, no framework agreement, and no zero-consideration path exist. | gap | `authoring_engagements` has no `engagement_type`; `models_federation.py` is deployment-instance registry, unrelated; `ExternalCourse.source_institution_name` is a free string |
| D12 | **Federated faculty would silently inflate DM 1154 accreditation compliance.** `ava_faculty_requirement_service.count_available_faculty` counts *every* `FacultyProfile` assigned to a `TeachingSection`, with tenure inferred from `FacultyProfile.rank` alone. `FacultyProfile` carries **no affiliation marker** — nothing distinguishes faculty attached to STU from faculty on loan. Creating profiles for federated authors without one makes them count toward Dtot/Ttot, which is precisely what a docente di riferimento requirement is designed to prevent. This is a latent defect that D11 would activate. | gap (compliance) | `ava_faculty_requirement_service.py:113-140`; `TENURED_RANKS`; `models_institution.FacultyProfile` |

## 4. Decision

### 4.1 The Console becomes FW6, not a system

BOOK-17 Ch. 4 catalogues faculty workspaces FW1–FW5. FW1 (*Design Studio*)
already owns "Builder/FEX wizard, Factory pipeline, gate status (3-gate flow)".
There is no workspace for the *institutional* faculty lifecycle — documents,
contract, money — which is precisely BOOK-22's domain and precisely what the
Console's Phases 1–2 render.

**Decision:** add **FW6 — Engagement Desk** to BOOK-17 Ch. 4. It is a *view*:
it owns no state (BOOK-03 Ch. 1), composes existing endpoints, and is built
from `ds/` primitives only. Phase 3 of the Console is **not** FW6 — it is
absorbed into the existing FW1, whose gate-status panel gains the content
standard of D8.

```
Console prototype          →  DAS placement
─────────────────────────────────────────────────────────────────
Phase 1 Onboarding         →  FW6 (composes /api/faculty-onboarding)
Phase 2 Contracting        →  FW6 (composes /api/authoring-engagements)
Phase 3 Execution          →  FW1 (existing Design Studio + gate panel)
Invoices                   →  existing APBudgetDashboard, linked from FW6
Audit trail                →  ds/AuditTimeline over platform.audit_logs
Role switcher              →  deleted; real RBAC
localStorage               →  deleted; Postgres
Catalogue (196 courses)    →  reads models_course_catalog, not a JS array
STU Content Standard       →  promoted to a backend service (D8) — KEEP
Exhibit A/B structuring    →  promoted to real tables (D7) — KEEP
Consent capture            →  promoted to a real registry (D4) — KEEP
Gate alias table           →  promoted to an ADR + one constant (D9) — KEEP
```

### 4.2 Engine mapping (BOOK-03 semantics)

FW6 touches no engine directly. Every action resolves to an existing engine
contract:

| FW6 action | Engine | Existing implementation |
|---|---|---|
| register, verify identity | Identity | `models_auth`, auth services |
| upload/verify documents | — (domain service) | `faculty_onboarding_service` |
| qualification decision (D5) | — (domain service) | **new**, same service |
| reserve catalogue course (D6) | Learning | `models_course_catalog` + **new** status |
| draft contract | — (domain service) | `faculty_engagement_service` |
| sign | Credential (QES boundary, G3) | `qes.py`, `qes_signature_ref` |
| release deliverable | Learning | `course_exchange_service.export_course` |
| content standard (D8) | Learning + Assessment | **new** service, reuses `blueprint_readiness` |
| gate decision | — (domain service) | `engagement_milestone_service` |
| invoice | — (BOOK-23 AP) | `ap_service`, `payment_runs` |
| every transition | Event Mesh | `event_taxonomy` + outbox |

### 4.3 Integration with the turnkey drivers

**Frappe (CRM + ERPNext).** Per BOOK-18 Ch. 3 and BOOK-23 §6, Frappe is a
**driver, never the system of record**. The engagement is authored in DLU;
`supplier_invoices` is the SoR; Frappe receives the fiscal document for
emission and ledger posting. The existing `frappe_*` mapping tables carry
students, programs, courses, instructors — there is **no supplier/vendor
mapping**. Add `FrappeSupplierMapping` + `SyncJobType.SUPPLIER_INVOICES`,
mirroring the existing five mapping tables exactly. Direction is
outbound-only; a Frappe failure must never block a gate.

**n8n.** Broker, not SoR (BOOK-18 Ch. 3). The `n8n-bridge` consumer group
already exists. FW6 adds **no new consumer group** — BOOK-22 §4's own
correction established that a semantically distinct concern gets its own group
(`hr-workload`), so the outbound Frappe relay joins `n8n-bridge` (it *is* a
workflow-mediated external relay, which is that group's actual meaning).
Notification fan-out (the single-channel rule of the v2.0 process §2.3) is an
n8n workflow subscribing to the engagement events; email carries a link, never
document content.

**DLU Builder / FEX.** Unchanged. `EngagementDeliverable.content_ref_type =
'fex_package'` already points at a `course_exchange_service` export. This RFC
makes that reference **dereferenced for the first time**: the content standard
(D8) runs against the real course tree before a deliverable may be released.
The Console's client-side `buildEngagementJSON` is deleted — `export_course`
already writes `authorship.approvers` and `quality_log.review_checkpoints`
from real rows.

**DLU badge.** Out of scope for the faculty pipeline and deliberately so.
BOOK-16 draws the boundary and BOOK-22's own SPRINT-08 correction restates it:
`issued_document_credentials` is for **publicly verifiable** credentials; an
authoring contract is an internal HR/legal record. An executed contract MUST
NOT be issued as a badge or a document credential. *(Optional, non-blocking:
a "Course Author" recognition badge on `EngagementCompleted` is a BOOK-16
`UserBadge`, unrelated to the contract itself. Not proposed here.)*

**QES.** Reused unchanged (G3 closed, NEW-12). The signing-policy change (D1)
alters only the *order and roster* of `EngagementSignature` rows, never the
QES submission pipeline.

### 4.4 Signing policy (resolves D1 + D2)

`ENGAGEMENT_SIGNER_ROLES` becomes a **versioned, immutable signing policy**
resolved per institution, following the `cds_rule_packs` /
`ItemCalibrationParams` pattern that CLAUDE.md §20 already mandates for domain
rules. Hardcoded role sets are the current disclosed stand-in for the unbuilt
`institution_policies` (T6); this RFC does not build T6, it builds the one
rule pack the faculty domain needs.

```
signing_policies (versioned, immutable)
  id, tenant_id, institution_id, version, effective_from
  steps: [ {role, sequence_order, kind: "signature"|"verification"},
           ... ]
```

STU profile (v1):
```
1  instructor    signature      (developer e-signs first)
2  secretariat   verification   (governance check, not a signature)
3  chairman      signature      (sole executing signatory)
```
Default/legacy profile preserves today's behaviour exactly
(`provost`+`cfo` → `instructor`), so no running tenant changes.

`VALID_SIGNER_ROLES` widens to include `chairman` and `secretariat`;
`UserRole` gains `CHAIRMAN` and `SECRETARIAT`. Both are **additive** CHECK/enum
widenings — no drop, per BOOK-18 Ch. 1 rule 3.

This finally makes real the persona BOOK-24 §3 already surfaces as "Chairman
Board Pack". Mapping a Chairman onto an admin-tier role is defensible for a
*read* dashboard; it is not defensible for a signature, where the executed
instrument must name who signed. `EXECUTIVE_COMMAND_STAFF_ROLES` should adopt
the real role in the same sprint, and the misattributed disclosure at
`AppRoutes.js:350` corrected (it cites a BOOK-24 Annex A limitation that BOOK-24
does not contain — a live sync-rule breach).

A `kind='verification'` step records a decision without a QES act — this is the
Secretariat's governance check, which is not a signature and must not be
recorded as one.

### 4.5 Gate reconciliation (resolves D9)

Settled in **ADR-0015** (companion to this RFC). Summary: institutional gate
names become canonical in the ontology; `CourseWorkflowState` and FEX
`checkpoint_type` remain untouched wire values, related by one alias table
exposed in the ontology registry and in a single constant. FEX v1.4 renames
the checkpoint types; v1.3 remains readable forever.

### 4.6 What FW6 must not do

- MUST NOT hold state (BOOK-03 Ch. 1: experiences own no state).
- MUST NOT render the restricted fiscal/identity slice to `dean`, `provost`,
  `chairman` or `secretariat` (v2.0 process §5.3; enforce server-side, never
  by hiding a component).
- MUST NOT create an invoice; only `MilestoneApproved` may (R22.2, now made
  real — see D10/Sprint FW6-05).
- MUST NOT introduce a new CSS file or a raw hex colour (CLAUDE.md §20 UX
  rules; Paper v3 tokens + `ds/` only).

### 4.7 Engagement types — the federated route (resolves D11 + D12)

`AuthoringEngagement` gains an `engagement_type` discriminator. It is not a
flag on one process; it selects which *instrument* is generated, which
onboarding evidence is required, and whether money moves at all.

| Type | Who | Instrument | Consideration |
|---|---|---|---|
| `independent_contractor` *(default, today's path)* | external SME, no institutional employer relevant to this work | IISA + Exhibit A + Exhibit B | AP invoice to the individual |
| `federated_faculty` **(new)** | already faculty at a federated institution | **Framework Agreement** (institution↔institution, signed once) + **Assignment Order** (per course) | none, or an institution-to-institution settlement — never a personal AP invoice |
| `internal_staff` *(reserved)* | STU's own employed faculty authoring under their existing contract | Assignment Order against the employment contract | none (workload ledger only) |

`internal_staff` is reserved, not built. It is structurally identical to
`federated_faculty` with the home institution being STU itself, and naming it
now prevents a third path being invented later.

**Legacy safety:** every existing row is `independent_contractor`; the column
is `NOT NULL DEFAULT 'independent_contractor'`. No running engagement changes.

#### 4.7.1 The federation registry

Two new aggregates, deliberately minimal:

```
federated_institutions        the partner (name, country, jurisdiction,
                              legal identifiers, home LMS/SSO issuer,
                              trust tier)
federation_agreements         versioned, immutable: scope, term,
                              ip_regime, consideration_model,
                              requires_home_authorisation (bool),
                              delegated_signature (bool), attached PDF
```

**Reuse note.** `models_federation.py` is a *deployment-instance* registry
(data residency, heartbeats) and is unrelated — do not extend it; the name
collision is unfortunate and is documented in `ER_MAP.md` so the next reader
does not conflate them. `InstitutionType` gains no new value: a federated
partner is not a `reseller`, and STU's own `Institution` row is not the
partner.

**Trust tiering follows BOOK-16's own precedent.** BOOK-16 Ch. 6 records that
cryptographic verification of externally-issued credentials "needs an external
issuer trust registry — not built", and STX-13 shipped wallet import at the
*unverified* tier only. The federated route adopts the same honesty:

- **Tier 1 (build now):** the home institution's attestation of rank, field
  and good standing is recorded as a document with a named institutional
  signatory. Verified by a human, on the strength of the framework agreement.
- **Tier 2 (deferred):** the same attestation as a signed verifiable
  credential resolved against the external-issuer trust registry, when BOOK-16
  builds it. `federated_institutions.trust_tier` exists now so the upgrade is
  a data change, not a migration.

Recording the attestation as *delegated* — rather than silently skipping the
transcript — is what keeps the file auditable. An auditor must be able to see
that STU relied on eCampus, and on what basis.

#### 4.7.2 What the federated route simplifies

| Step | `independent_contractor` | `federated_faculty` |
|---|---|---|
| Identity | ID document in the vault | home-institution SSO or attested identity; **no ID document collected** |
| CV | uploaded, required | home institution's attested profile accepted |
| Transcript / degrees | required (Provost waiver possible) | **replaced** by the institutional attestation of rank and field |
| Tax form (W-9/W-8) | required | **not collected** where no consideration flows to the individual |
| Banking | at first invoice | **never** (no personal payment) |
| Contractor classification | required | **not applicable** — and must not be requested |
| Consents | 9 mandatory + item 10 | **7 mandatory + item 10** (see below) |
| Gate 1 qualification | Dean decides on documents | Dean decides on attestation + **course fit** — still a real decision |
| Instrument | IISA + Exhibits A/B | Framework Agreement + Assignment Order |
| Signature | developer → Secretariat → Chairman | developer acknowledgement + Dean; Chairman **only if** `delegated_signature=false` |
| Home authorisation | n/a | captured where `requires_home_authorisation=true` |
| Gates 2 / 3 / 4 | unchanged | **unchanged — non-negotiable** |
| Invoicing | AP invoice to the person | none, or institution-to-institution settlement |

**Consents cannot be delegated wholesale.** Seven of the ten are personal
certifications about the work and remain mandatory in both routes: 1
(e-communications), 4 (accuracy), 5 (originality and copyright), 6
(generative-AI disclosure), 7 (accessibility), 8 (confidentiality), 9
(agreement to review). Two may be satisfied at framework level and recorded as
such rather than re-collected: 2 (credential verification — the home
institution performed it) and 3 (privacy and data processing — covered by the
inter-institutional DPA). Item 10 (name, biography, photograph, voice) stays
**personal in both routes**: image and personality rights are not an employer's
to grant.

#### 4.7.3 The two things that must not be simplified

**Academic quality.** Gates 2, 3 and 4 judge the course, not the author and
not who paid. A federated engagement passes the identical STU Course Content
Standard, the identical review windows and the identical revision caps. Any
implementation that shortcuts a quality gate because the author is federated
fails review.

**Intellectual property.** This is the substantive legal difference and the
reason the IISA cannot simply be reused. IISA §6 is a work-for-hire assignment
in which the individual grants title to STU on final payment. A person
authoring within the scope of their employment at eCampus may not hold the
title they would be purporting to grant — it may vest in their employer. The
`ip_regime` on the framework agreement is therefore mandatory and enumerated
(`sta_owns` · `home_owns_stu_licensed` · `joint` · `per_assignment`), the
Assignment Order inherits it, and the contract renderer **must not** emit a
work-for-hire clause against an individual under a `home_owns_*` regime.

Related, and a question for counsel rather than for this RFC: some
institutions require their staff to obtain prior authorisation before
accepting extra-institutional assignments. The framework agreement records
whether the partner does (`requires_home_authorisation`), and the Assignment
Order captures the authorisation reference where it does. The system does not
attempt to know which partners those are.

#### 4.7.4 Money: three sub-cases, one rule

- **(a) No consideration.** Work is covered by the framework (reciprocity,
  exchange, joint programme). **No supplier invoice is created at all.**
- **(b) Institution-to-institution settlement.** STU settles with the partner,
  not the person. A `supplier_invoice` is raised with the **partner
  institution** as supplier; the tax identity is the institution's.
- **(c) Individual honorarium.** Not a federated engagement — it is
  `independent_contractor` and takes the full path, whatever the person's day
  job. The type is chosen by how the money moves, not by where the person
  works.

R23.5 is **not weakened**. "An AP invoice without a matching approved
milestone is structurally impossible" remains true at DDL level. What changes
is the converse, which was never asserted: an approved milestone may
legitimately generate no invoice. The `MilestoneApproved` subscriber
introduced in FW6-05 reads `engagement_type` and the consideration model, and
emits nothing for case (a) — recording the no-op explicitly, so that a missing
invoice is evidence of a decision rather than of a bug.

#### 4.7.5 The accreditation guard (D12) — mandatory, not optional

`FacultyProfile` gains `affiliation_type ∈ ('own','federated','visiting')`,
`NOT NULL DEFAULT 'own'` so every existing row keeps today's meaning.
`ava_faculty_requirement_service.count_available_faculty` **must** exclude
non-`own` profiles from the Dtot/Ttot counts and report them as a separate,
visible figure.

Without this, onboarding a federated author creates a `FacultyProfile` that
counts toward STU's DM 1154 faculty requirement — the same professor
simultaneously satisfying two universities' requirements, which is the exact
outcome the docente-di-riferimento rule exists to prevent. It would be an
inflated compliance posture produced silently, by a feature intended to reduce
paperwork. **FW6-09 must not ship without FW6-10.**

## 5. New events (A6 duty)

Added to `event_taxonomy.py`, closed taxonomy, `noun.verb` wire form:

| Constant | Wire | Emitted by |
|---|---|---|
| `FACULTY_QUALIFIED` | `faculty.qualified` | Gate 1 decision (D5) |
| `FACULTY_QUALIFICATION_WAIVED` | `faculty.qualification_waived` | Provost transcript waiver |
| `CONSENT_RECORDED` | `consent.recorded` | consent registry (D4) |
| `CATALOG_COURSE_RESERVED` | `catalog_course.reserved` | reservation (D6) |
| `CATALOG_COURSE_RELEASED` | `catalog_course.released` | reservation expiry/release |
| `ENGAGEMENT_VERIFICATION_RECORDED` | `engagement.verification_recorded` | Secretariat step (D1) |
| `DELIVERABLE_REVIEW_WINDOW_ELAPSED` | `deliverable.review_window_elapsed` | review clock (D7) |
| `DEADLINE_TOLLED` | `deadline.tolled` | tolling notice (D7) |
| `FEDERATION_AGREEMENT_ACTIVATED` | `federation_agreement.activated` | framework agreement execution (D11) |
| `FEDERATED_FACULTY_ATTESTED` | `federated_faculty.attested` | home-institution attestation recorded (D11) |
| `ASSIGNMENT_ORDER_ISSUED` | `assignment_order.issued` | per-course order under a framework (D11) |
| `MILESTONE_SETTLEMENT_WAIVED` | `milestone.settlement_waived` | approved milestone that generates no invoice (D11, §4.7.4a) |

`ENGAGEMENT_SIGNED`, `ENGAGEMENT_EXECUTED`, `DELIVERABLE_RELEASED`,
`DELIVERABLE_APPROVED`, `MILESTONE_APPROVED` are reused unchanged.

## 6. Conformance checks (extend BOOK-22 §6)

- **C22.6** Property: an engagement cannot reach `executed` unless every step
  of its resolved signing policy is satisfied *in sequence order*, including
  `kind='verification'` steps. (Generalises C22.1, which only tested a missing
  university signature.)
- **C22.7** Fixture: a `deliverable` release is rejected when the STU Course
  Content Standard fails; the failing check ids are returned.
- **C22.8** Property: no `authoring_engagement` may be created against a
  catalogue course whose status is not `reserved` **by the same sponsoring
  Dean**; two concurrent reservations of one course are impossible (unique
  partial index, not a service check).
- **C22.9** Fixture: all nine mandatory consents present is a precondition of
  contract generation; a withdrawn consent blocks it.
- **C22.10** Fixture: an academic role (`dean`/`provost`) receives HTTP 403 —
  not a filtered payload — on the restricted fiscal/identity endpoints.
- **C22.11** Reproducibility: gate alias round-trip — a FEX export re-imported
  yields the same institutional gate labels (ADR-0015).
- **C22.12** Fixture: a `federated_faculty` engagement cannot be created
  without an *active* `federation_agreement` covering the partner at the
  effective date; an expired agreement fails.
- **C22.13** Property: no `faculty_documents` row of type `tax_form_*`,
  `personal_id` or `contractor_classification` may exist for a
  `federated_faculty` journey — the vault stays empty by construction, not by
  UI omission.
- **C22.14** Property: an approved milestone on a zero-consideration federated
  engagement produces **no** `supplier_invoice`, and emits
  `milestone.settlement_waived` exactly once on replay.
- **C22.15** Property (compliance, D12): `count_available_faculty` excludes
  every `FacultyProfile` whose `affiliation_type != 'own'`. Fixture: adding a
  federated author to a program does not change its Dtot/Ttot verdict.
- **C22.16** Fixture: the contract renderer refuses to emit a work-for-hire
  clause when the governing `ip_regime` is `home_owns_stu_licensed`.
- **C22.17** Property: the seven personal consents are mandatory on **both**
  routes; only items 2 and 3 may be satisfied by a framework reference, and
  the reference is recorded (never a null).

## 7. Sprint catalog

Format per BOOK-20 Ch. 12. One branch per sprint, one PR per sprint, V-checks
executable and green before DoD, sync duty in the same change set.

---

### FW6-01 — Signing policy + chairman/secretariat roles
**Books:** 22 §2/§3, 19 (RACI) · **Registers:** G18.1 · **Deltas:** D1, D2

Additive migration: `signing_policies` (versioned, immutable), widen
`UserRole` enum and `VALID_SIGNER_ROLES` CHECK, add
`EngagementSignature.step_kind ∈ ('signature','verification')`. Seed two
policies: `default` (provost+cfo→instructor, byte-identical to today) and
`stu` (instructor→secretariat→chairman).
`faculty_engagement_service` resolves the policy at draft time and
materialises the signature rows from it instead of the module constant.

- **V1** Existing SPRINT-08 conformance suite passes unchanged under `default`.
- **V2** C22.6 green for both policies, including a mid-sequence verification step.
- **V3** `alembic upgrade → downgrade → upgrade` clean.
- **V4** `grep -rn "ENGAGEMENT_SIGNER_ROLES" backend/` returns only the policy seeder.
- **DoD:** BOOK-22 §2/§3 amended, ADR filed, TRACEABILITY G18 disposition updated.

---

### FW6-02 — Consent registry
**Books:** 22 §2, 19 (AI Act, consent), 06 (consent semantics) · **Delta:** D4

`consent_definitions` (versioned catalogue of the 10 items) +
`faculty_consent_records` (per subject, per version, append-only; withdrawal is
a new row, never a mutation — same discipline as `faculty_workload_entries`).

**Naming is deliberate.** The table is *not* called `consent_records`: that name
is taken by the orphaned marketing domain (`backend/domains/marketing/`, GDPR
channel consent, unregistered). This sprint neither reuses nor deletes it —
reuse would force item-level contractual certifications into a channel/status
shape, and deletion is out of scope. The two are documented as distinct concepts
in `ER_MAP.md`, so the next reader does not have to rediscover this.
Item 10 is tri-state (`yes`/`no`/`limited` + free text). Item 6 (generative-AI
disclosure) links to the existing AI-governance surface.

Contract generation reads item 10 and conditionally emits the IISA §15 clause
— closing the internal inconsistency where §15 asserts a publication right
that item 10 makes optional.

- **V1** C22.9 green.
- **V2** Withdrawal writes a new row; the original is byte-unchanged (trigger-enforced).
- **V3** IISA renders with and without §15; both re-generate byte-identically (C22.3 extended).

---

### FW6-03 — Document taxonomy + qualification gate
**Books:** 22 §2 Step 1 · **Deltas:** D3, D5

Widen `VALID_FACULTY_DOCUMENT_TYPES` (additive) to add `cv`,
`degree_certificate`, `professional_licence`, `work_authorisation`,
`contractor_classification`, and replace the undifferentiated `fiscal_data`
by keeping it **and** adding `tax_form_w9`, `tax_form_w8ben`,
`tax_form_w8bene` (old value never dropped).

New `faculty_qualification_decisions`: one immutable row per Gate 1 act
(decider, role, outcome ∈ approved/conditional/more_info/declined, evidence
set, reasons). A `transcript_waiver` sub-record requires role `provost` and a
reason. `FacultyOnboardingJourney.status` gains `qualified`.

- **V1** C22.10 green (403, not filtering) on the fiscal/identity endpoints.
- **V2** Contract generation blocked without an `approved` qualification decision.
- **V3** Waiver without `provost` → 403; waiver without reason → 422.

---

### FW6-04 — Catalogue reservation
**Books:** 22 §2 Step 2, 24 (catalog governance) · **Delta:** D6

Additive `assignment_status` on the catalogue course row +
`catalog_course_reservations` (course, dean, expires_at). Unique **partial**
index on `(course_id) WHERE status='reserved'` makes double allocation
impossible at DDL level rather than by service check. 30-day expiry swept by
the existing Celery beat.

- **V1** C22.8 green, including a concurrent-insert race (two sessions, one wins).
- **V2** Expiry sweep releases and emits `catalog_course.released`.

---

### FW6-05 — STU Course Content Standard + real R22.2
**Books:** 22 §2 Step 3, 15, 17 (FW1) · **Deltas:** D8, D10

New `stu_content_standard_service`, **wrapping and extending**
`course_workflow.blueprint_readiness` (never replacing it). Adds the checks
the Console proved out: CLO count 3–8 with Bloom variety, ≥1 MLO/section,
section count matches the Exhibit A module count, 12–15 h envelope, a
feedback-bearing component at least every 2 h, assessment weights = 100 %,
transcript present on every video component, final exam title + ≥1 method when
enabled. Returns `{ok, checks:[{id, ok, detail}]}`; the result is written into
`DeliverableReview.checklist`, replacing the manual dict with a computed one.

`release_deliverable` refuses when `ok=false`.

Close D10 honestly: register a `MilestoneApproved` subscriber that calls
`ap_service.generate_supplier_invoice_from_milestone`, making R22.2 literally
event-driven as BOOK-22 always claimed. Idempotent on retry.

- **V1** C22.7 green.
- **V2** PHA 500 fixture (7 modules, 13.1 h, 21 components) passes all checks; the same course with one video transcript removed fails exactly one check.
- **V3** `MilestoneApproved` replayed twice creates exactly one `supplier_invoice`.
- **V4** BOOK-22 §2 correction (2) retracted in the same change set.

---

### FW6-06 — Exhibit A / Exhibit B as data
**Books:** 22 §2, 23 §3 · **Delta:** D7

`engagement_scopes` (Exhibit A: project description, module list, deliverable
taxonomy selections, acceptance criteria, review window, revision-round cap)
and `engagement_compensation_schedules` (Exhibit B: currency, method, payment
window, N payment milestones each bound to a gate, Σ pct = 100 CHECK).

Generalises the hardcoded two-milestone 30/70 split without breaking it: the
existing `design_fee_pct`/`full_course_fee_pct` become the *default seed* of a
two-row schedule. Deliverable count is **computed**
(`course_items + module_items × modules`), never typed — the PHA 500 fixture
must yield exactly **61**.

Review-window clock + tolling: a `deadline_events` append-only ledger; a
University feedback breach or a late template delivery (Exhibit A §7.1) tolls
the developer's deadline by the corresponding business days. Business days
resolve against a single institutional calendar service — a globally
distributed developer pool makes "ten business days" otherwise unarguable.

- **V1** Σ payment-milestone pct = 100 property test.
- **V2** PHA 500 fixture computes 61 deliverable items.
- **V3** Effective-date change recomputes every milestone date.
- **V4** Tolling ledger append-only (trigger), same discipline as C22.4.

---

### FW6-07 — FW6 Engagement Desk (the UI)
**Books:** 17 Ch. 4 (new FW6), 22 · **Delta:** the Console's actual value

One page composing existing endpoints, `ds/` primitives only, Paper v3 tokens,
`t('…')` for every string, `useNavigate`, configured axios. Role-gated by real
RBAC. Opportunistic legacy migration: `FacultyOnboarding.js` and
`FacultyVerificationQueue.js` are migrated to tokens + `ds/` in this sprint
(the DoD verifies it), per CLAUDE.md §20.

FW1's gate panel gains the content-standard readout from FW6-05.

- **V1** No new CSS file; CI lint for raw hex passes.
- **V2** No hardcoded string; i18n IT/EN complete.
- **V3** Restricted slice invisible **and** 403 for academic roles (C22.10 at the UI layer too).
- **V4** Screenshot diff of the two migrated legacy pages reviewed.

---

### FW6-08 — Frappe supplier relay
**Books:** 18 Ch. 3, 23 §6 · **Driver work**

`FrappeSupplierMapping` + `SyncJobType.SUPPLIER_INVOICES`, mirroring the five
existing mapping tables. Outbound only, via `n8n-bridge`. DLU remains SoR;
Frappe emits the fiscal document and posts the ledger entry.

- **V1** Frappe outage → gate still passes, sync job queues and retries.
- **V2** Replayed webhook is idempotent (existing HMAC discipline).
- **V3** No read path treats Frappe as authoritative for milestone state.

---

---

### FW6-09 — Federated faculty: registry, engagement types, reduced onboarding
**Books:** 22 §2, 16 (trust tiering), 19 (inter-institutional agreements) · **Registers:** G18.5 · **Delta:** D11
**Blocked by:** FW6-01 (signing policy), FW6-02 (consents), FW6-03 (document taxonomy)
**Blocks:** nothing may deploy this without FW6-10 — see the gate below

Additive migration: `federated_institutions`, `federation_agreements`
(versioned, immutable, with `ip_regime`, `consideration_model`,
`requires_home_authorisation`, `delegated_signature`, `trust_tier`);
`AuthoringEngagement.engagement_type NOT NULL DEFAULT
'independent_contractor'`; `assignment_orders` as the light instrument under a
framework.

`faculty_onboarding_service` branches on engagement type: the federated route
records an institutional attestation (Tier 1, human-verified) in place of
transcript and degree documents, and **never requests** identity document, tax
form, banking or contractor classification. The consent set reduces to the
seven personal items plus item 10, with items 2 and 3 recorded as satisfied by
a named framework agreement reference.

`faculty_engagement_service` selects the instrument by type: Framework
Agreement + Assignment Order, never the IISA. The renderer refuses a
work-for-hire clause under a `home_owns_*` `ip_regime`.

- **V1** C22.12 green (no active agreement → creation fails; expired → fails).
- **V2** C22.13 green — vault empty by construction; asserted at the DB, not the UI.
- **V3** C22.16 green — work-for-hire refused under `home_owns_stu_licensed`.
- **V4** C22.17 green — seven personal consents mandatory on both routes.
- **V5** Every pre-existing engagement reads `independent_contractor`; the full SPRINT-08/09/10 conformance suite passes unchanged.
- **V6** `grep` gate: no code path emits an IISA for a non-`independent_contractor` engagement.
- **DoD:** BOOK-22 §11.5 amended, `ER_MAP.md` records the `models_federation.py` name collision, TRACEABILITY G18.5 opened.

---

### FW6-10 — Accreditation guard: affiliation-aware faculty counting
**Books:** 26 (DM 1154), 22 · **Registers:** G18.6 · **Delta:** D12
**Ships with or before FW6-09. Never after.**

Additive `FacultyProfile.affiliation_type ∈ ('own','federated','visiting')`,
`NOT NULL DEFAULT 'own'` — every existing row keeps today's meaning exactly.
`ava_faculty_requirement_service.count_available_faculty` excludes non-`own`
profiles from Dtot/Ttot and returns them as a separate visible figure;
`FacultyRequirementEvaluation` records both, so a historical snapshot cannot be
misread later.

This sprint is small and unglamorous and is the reason the federated feature is
safe to ship. Its own value is independent of FW6-09: the counting function is
already reachable by any future non-attached faculty record.

- **V1** C22.15 green — adding a federated author leaves Dtot/Ttot unchanged.
- **V2** Existing AVA conformance suite passes unchanged (all rows default `own`).
- **V3** A recomputation after the migration reproduces every prior evaluation's verdict byte-for-byte.
- **V4** The separated figure is surfaced in the AVA UI, not only in the payload.
- **DoD:** BOOK-26 annex notes the affiliation exclusion; TRACEABILITY G18.6.

---

## 8. Sequencing

```
FW6-01 ─┬─ FW6-03 ─┬─ FW6-04 ──┬── FW6-07
FW6-02 ─┘          │           │
                   FW6-06 ─────┤
                   FW6-09 ═╗   │
        FW6-05 ────────────╫───┘
                           ║    └── FW6-08 (any time after FW6-05)
        FW6-10 ════════════╝  (hard gate: FW6-09 MUST NOT deploy without it)
```

FW6-01 and FW6-02 are independent and may run in parallel. FW6-05 is
independent of the contracting chain and delivers value on its own — it is the
single highest-value sprint here, because it converts a decorative checklist
into a computed gate. If only one sprint is funded, fund FW6-05.

**FW6-09 ⇒ FW6-10 is a hard gate, not a preference.** Shipping the federated
route without affiliation-aware counting produces a silently inflated DM 1154
compliance posture — a worse outcome than not shipping the feature. FW6-10 may
ship first and alone; FW6-09 may not.

## 9. Register disposition

G18 was correctly closed for the BOOK-22 v1.0 pipeline. This RFC opens four
successor gaps rather than re-opening G18 (which would misrepresent delivered
work):

| G | Gap | Owner Book | Sprint |
|---|---|---|---|
| G18.1 | Signing order/roster not institution-configurable; no chairman/secretariat | 22 | FW6-01 |
| G18.2 | No consent/certification registry (AI-disclosure obligation on paper) | 22, 19 | FW6-02 |
| G18.3 | No academic qualification gate; document taxonomy too narrow; no catalogue reservation | 22 | FW6-03, FW6-04 |
| G18.4 | Deliverable review checklist not computed; Exhibit A/B not modelled; no review clock/tolling | 22, 23 | FW6-05, FW6-06 |
| G18.5 | No engagement-type discriminator; no federation registry or framework agreement; federated faculty forced onto an independent-contractor instrument | 22, 16, 19 | FW6-09 |
| G18.6 | `FacultyProfile` carries no affiliation marker; DM 1154 faculty counting cannot distinguish attached from federated faculty | 26, 22 | FW6-10 |

## 10. Ontology duty (BOOK-05)

New names requiring `dlu-core.yaml` entries before implementation:
`SigningPolicy`, `ConsentDefinition`, `ConsentRecord`,
`FacultyQualificationDecision`, `CatalogCourseReservation`,
`EngagementScope`, `EngagementCompensationSchedule`, `DeadlineEvent`,
`ContentStandardCheck`, `FederatedInstitution`, `FederationAgreement`,
`AssignmentOrder`, `EngagementType`, `AffiliationType`, `IpRegime`.

`FederatedInstitution` must be disambiguated in the registry from the existing
`InstanceRegistry` of `models_federation.py` (deployment instances) — same word,
unrelated concepts.

## 11. Alternatives considered

**Merge the Console as a parallel system.** Rejected: it would create a second
system of record for engagements, contracts and invoices, violating BOOK-03
Ch. 1 and BOOK-23's "external rails are drivers, never SoR" rule — and would
duplicate 9 tables that already carry conformance-verified behaviour.

**Keep the Console as a demo only, change nothing.** Rejected: D4, D5, D6 and
D8 are real compliance and correctness gaps. D8 in particular means every
"approved" deliverable to date rests on a hand-typed checklist.

**Adapt STU to the DAS signing order** (Chairman mapped onto `provost`).
Rejected by the process owner: it contradicts the Corporate Secretariat
protocol and the executed IISA, and would encode a governance fiction in the
audit trail.

**Handle federated faculty as an `independent_contractor` with fee = 0.**
Rejected. It would issue an IISA — an instrument whose §1 asserts the signer is
not an employee — to someone who is an employee elsewhere, and would take a
work-for-hire assignment of IP the individual may not hold. A zero total is an
accounting detail; the legal shape is what differs.

**Skip onboarding entirely for federated faculty.** Rejected. Course fit is
still an academic judgement (Gate 1), and seven of the ten consents are
personal certifications about the work that no employer can give on someone's
behalf. What is delegated must be *recorded as delegated*, so that an auditor
can see STU relied on the partner and on what basis — silence and delegation
look identical in a file six months later.

---

*Filed under the BOOK-00 sync rule: BOOK-22 → v0.5, BOOK-17 Ch. 4 (FW6),
TRACEABILITY G18.1–G18.4, and `dlu-core.yaml` update in the same change set as
the first implementing sprint.*
