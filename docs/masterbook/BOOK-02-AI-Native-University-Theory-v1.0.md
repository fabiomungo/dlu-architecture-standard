# BOOK-02 — AI-Native University Theory
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The theory of the **institution** that runs on an Academic Operating System.
> BOOK-00 states the vision; BOOK-01 grounds the pedagogy; this Book answers the
> provost's and CFO's questions: how is such a university organized, staffed,
> financed, accredited and transformed — and why it remains a university rather
> than a software product with students.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-00, BOOK-01.
> **Informs:** BOOK-03 (AOS), BOOK-07 (Faculty Twin), BOOK-08 (Institution Twin),
> BOOK-17 (Experiences), BOOK-19 (Governance), BOOK-20 (Blueprint).
> **Primary audience:** rectors, provosts, boards, CFOs, CIOs, transformation leads.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** this Book
systematizes the Turnkey **Master Process Map** (`AI_NATIVE_UNIVERSITY_PROCESS_MAP.md`,
P01–P08 with L0/L1/L2 decomposition), the macro-role hierarchy, multi-tenant and
subscription models, the payment/financial-access architecture and the PI-5
federation core. Annex A maps every organizational mechanism to its Turnkey asset.

---

# Chapter 1 — Purpose: a Theory of the Institution

An AOS without an institutional theory produces the standard failure of ed-tech:
excellent software wrapped around an unchanged organization, adopted by no one.
The reverse failure is equally documented: organizational redesign without an
operating substrate collapses into slideware.

This Book therefore holds one thesis:

> **The AI-native university is an organization whose processes are event-driven,
> whose routine cognition is delegated to an AI workforce, and whose humans are
> deliberately concentrated where accountability, judgment and relationships create
> value — and it must be economically self-explaining and externally accreditable
> at every moment.**

Everything below operationalizes that sentence.

---

# Chapter 2 — The Operating Model: Process Architecture P01–P08

The Turnkey Master Process Map is adopted as the **canonical business architecture**
of the DAS. It decomposes the university into eight process areas at three levels
(L0 map → L1 sub-processes → L2 sequence diagrams):

| Area | Name | Scope | Characteristic AI contribution |
|------|------|-------|-------------------------------|
| P01 | Student Lifecycle Management | prospect → applicant → enrolled → active → graduate → alumni | lead scoring, application screening, onboarding personalization, at-risk detection, graduation clearance |
| P02 | AI-Augmented Academic Delivery | curriculum design → authoring → enrichment → delivery → adaptive assessment | AI course generation, 9-type enrichment, BKT scoring, 24/7 RAG tutoring, video professor |
| P03 | Faculty & Staff Management | recruitment, assignment, workload, development | assignment optimization, workload analytics |
| P04 | Administrative & Student Services | records, requests, support | AI service desk, document automation |
| P05 | Finance, Billing & Compliance | tuition, invoicing, financial access control | dunning automation, financial-status-driven access |
| P06 | Technology & Platform Operations | tenancy, SRE, AI infrastructure | gateway routing, quota enforcement, observability |
| P07 | Quality Assurance & Accreditation | internal QA, accreditation evidence | coverage audits, Bloom distribution analysis, evidence dossiers |
| P08 | Partnerships, Federation & Mobility | inter-institutional agreements, credit mobility | recognition analysis, federated catalog |

Normative rules:

1. Every institutional process MUST be locatable in P01–P08; a process that fits
   nowhere triggers an RFC to extend the map, never an unmapped workflow.
2. Every L2 sequence MUST identify: the events consumed/emitted (Event Mesh), the
   system of record touched (data ownership map, BOOK-00 Annex A.2), the AI
   contribution, and the **human accountability point**.
3. Process areas are wired by events, not by synchronous cross-area calls — the
   organizational mirror of the kernel invariant (BOOK-00 Ch. 6.2).

**The inversion to internalize:** in a traditional university, humans execute
processes and systems record them. In DLU, the mesh executes processes and humans
**govern exceptions, judgment calls and relationships**. Chapter 5 quantifies what
this does to jobs.

---

# Chapter 3 — Organizational Theory: Three Economies and a Mixed Workforce

## 3.1 Three internal economies

The institution manages three scarce resources with different laws:

| Economy | Scarce asset | Produced by | Degraded by |
|---------|-------------|-------------|-------------|
| **Knowledge economy** | validated, connected content | faculty curation + AI generation | staleness, incoherence, hallucination |
| **Trust economy** | credible evidence and credentials | assessment integrity + human verification (BOOK-01 Ch. 8) | fraud, grade inflation, opaque AI judgments |
| **Attention economy** | human mentorship hours and learner engagement | faculty time reallocation + AI absorption of routine load | admin creep, burnout, engagement-hacking |

Executive decisions SHOULD be tested against all three: a change that grows one
economy by silently taxing another (e.g., cutting verification effort to ship more
content) is the canonical AI-native failure mode. The **Institution Twin (BOOK-08)
MUST expose health indicators for each economy.**

## 3.2 The mixed workforce

The org chart contains two workforces under one governance:

- **Human workforce** — macro-roles adopted from the Turnkey process map: Platform
  Operator (cross-tenant), Institution Administrator, Rector/Provost, Dean, Program
  Director, Faculty, Advisor, Registrar, Student Services, Finance, QA Officer.
- **AI workforce** — the nine student-facing agents (BOOK-00/10) plus
  authoring-side agents (course architect, pedagogical coach, media pipeline),
  each with a contract: mission, tools, autonomy tier, envelope owner, audit trail.

Normative consequences:

1. Every AI agent has a **named human envelope owner** (the role that configures
   and answers for it). An agent without an owner MUST NOT run.
2. AI agents appear in process L2 diagrams as actors, with the same explicitness
   as human roles — organizational transparency about who/what does what.
3. New human roles are established: **Learning Engineer** (owns pedagogical pattern
   implementation, BOOK-01 Ch. 11), **AI Pedagogy Steward** (owns agent envelopes
   and model change review for learner-facing behaviour), **Evidence Registrar**
   (owns verification workflows and credential issuance queues). Institutions MAY
   merge these into existing roles at small scale; the *accountabilities* MUST exist.

---

# Chapter 4 — Governance and Decision Rights

Refines BOOK-00 Ch. 11 at institutional level. Decision rights matrix (extract —
full RACI in BOOK-19):

| Decision | Owner | Consulted | AI role |
|----------|-------|-----------|---------|
| Academic mission, new programs | Rector + Academic Senate | deans, boards | briefing dossiers only |
| Curriculum core & I/R/M map | Program Director | faculty, QA | Coach proposals |
| Course outcomes & content approval | Faculty | program director | drafts, alignment checks |
| Agent envelopes (learner-facing) | AI Pedagogy Steward + AI Review Board | faculty | self-reports, eval results |
| Credit recognition | Registrar | program director | Recognition Agent dossier (propose) |
| Credential issuance (high-stakes) | Registrar / Evidence Registrar | faculty examiner | Credential Agent preparation (reserved) |
| Intervention on at-risk student | Advisor | success team | Success Agent detection (propose) |
| Tuition, refunds, financial holds | Finance (P05) | registrar | dunning automation within policy |
| Tenant/AI quotas, model routing | Institution Admin (within Platform Operator limits) | CIO | usage analytics |

Governance bodies MUST meet the cadence their risk requires: the **AI Review Board**
reviews envelope changes and incident reports at minimum monthly, and MUST include
faculty and student representation (BOOK-00 Ch. 11).

---

# Chapter 5 — Faculty Transformation

## 5.1 The reallocation, quantified

Illustrative workload budget for a 40-hour teaching-track week (institutions
calibrate; the *shape* is normative — reallocation toward the right column MUST be
planned and budgeted, not assumed):

| Activity | Traditional | AI-native target | Mechanism |
|----------|------------|------------------|-----------|
| Lecture preparation & delivery | 14h | 4h | AI authoring + video professor; faculty curate and validate (P02) |
| Grading & feedback | 10h | 3h | formative feedback automated (BOOK-01 P6); faculty grade summative + vivas |
| Administration & reporting | 6h | 2h | process automation (P03/P04), Coach reports |
| **Mentorship & Socratic seminars** | 3h | **12h** | freed hours flow to the attention economy |
| **Assessment design & verification (vivas)** | 3h | **8h** | integrity strategy (BOOK-01 Ch. 8) |
| **Curriculum & knowledge network stewardship** | 2h | **6h** | KG curation, outcome maintenance |
| Research / innovation | 2h | 5h | CAT stage 8 supervision |

The **mentorship-hours-per-learner metric MUST rise** through transformation
(BOOK-00 Ch. 14); a transformation that converts freed hours into headcount cuts
rather than attention is a strategy choice the board MUST make explicitly — the
default DAS posture is reallocation.

## 5.2 Career, incentives, freedom

1. **Promotion criteria MUST be updated** to value: verified mentorship outcomes,
   assessment design quality, knowledge network contributions, agent envelope
   stewardship — alongside research. What is not promoted will not happen.
2. **Academic freedom extends to agents** (BOOK-00 Ch. 5.1): faculty inspect and
   tune agents operating in their courses; institution-wide envelope floors
   (safety, integrity) are set by governance, ceilings by faculty.
3. **Workload transparency:** the Faculty Twin (BOOK-07) records real allocation;
   it exists to *defend* faculty time (evidence against admin creep), and MUST NOT
   be used for surveillance-style performance micro-management.
4. **Hiring profile shifts:** postings SHOULD weight mentorship ability, assessment
   literacy and comfort supervising AI-augmented delivery.

## 5.3 Adoption reality

Faculty adoption is the single highest transformation risk (Ch. 11). Minimum
program: co-design pilots with volunteer faculty; envelope controls in faculty
hands from day one; visible time savings before any mandate; a faculty-majority
forum reviewing every learner-facing AI change.

---

# Chapter 6 — The Student Body and Community Model

- **Personas** (Foundation v1, adopted): new, transfer, professional, international,
  corporate, lifelong. Personas parameterize onboarding (P01.1.04), GPS defaults
  and communication cadence — they MUST NOT gate capabilities.
- **Lifecycle** is P01 end-to-end; the Twin lifecycle states (BOOK-06) mirror it.
  Alumni are *dormant learners*, not exits: re-engagement (P01.1.08) is a
  first-class process with its own economics (Ch. 8).
- **Community is engineered** (BOOK-00 Ch. 5.2, BOOK-01 P9): cohorts, study groups,
  peer tutoring (CAT-7) and events are kernel objects with owners and health
  metrics (belonging index). A learner with zero community attachments is a risk
  signal for the Success Agent — the intervention is human connection, not more
  content.

---

# Chapter 7 — Adoption Archetypes

One kernel, four institutional profiles. Turnkey's multi-tenant platform and
`InstitutionType` (`university`, `high_school`, `enterprise`, `reseller`) already
encode them:

| Archetype | Turnkey type | Governance profile | Dominant risks | Phasing emphasis |
|-----------|-------------|--------------------|----------------|------------------|
| **Greenfield AI-native institution** | `university` (new tenant) | full DAS from day one; accreditation track started pre-launch | regulatory approval, trust building | P01+P02 first; credential trust early |
| **Brownfield transformation** *(reference path)* | `university` | dual-running: DAS alongside legacy processes; per-program migration | faculty adoption, data migration, parallel-cost bubble | maturity ladder (Ch. 11); mirror-first integration (ADR-0009) |
| **Corporate academy** | `enterprise` | competency-first, credential-light; HR-integrated | competency framework alignment (SFIA), privacy of employee data | Competency Engine + GPS; skip degree accreditation |
| **Reseller / consortium** | `reseller` + child tenants | platform-operator governance; per-member institutional autonomy | cross-tenant isolation, brand/quality consistency | P06 operations; federation (Ch. 10) |

Rules: capabilities are gated by governance profile, not forked code — one kernel,
configuration-differentiated (`institution_type` conditional experience is already
a Turnkey convention). High-school tenants inherit the university profile with
minor-protection constraints (BOOK-19).

---

# Chapter 8 — Economics

## 8.1 The cost structure inversion

Traditional universities: dominant marginal cost = human hours per enrolled
learner (Baumol). AI-native: human hours concentrate in mentorship/verification;
the new marginal costs are **inference, orchestration and content maintenance**.

Unit economics per active learner per term (the Institution Twin MUST compute
these continuously):

```text
C_learner = C_inference + C_content_maint + C_human_attention + C_platform + C_compliance
```

- `C_inference`: observable **today** per tenant/agent/model via the ACP Gateway
  usage accounting (`PlatformUsageEvent`, LLM usage services, quota budgets).
  Normative: inference cost MUST be attributable per engine and per process area
  (P0x) — unattributable AI spend is a governance defect.
- `C_human_attention`: mentorship/verification hours (Faculty Twin) × loaded rates.
- Cost shocks (model price changes) are absorbed by gateway routing/fallback
  chains (multi-provider, local-model fallback) — an economic control, not merely
  a technical one.

## 8.2 Revenue models

Tuition (term or program), **subscription learning** (lifelong tier — aligns
revenue with the lifelong-learner thesis), micro-credentials à la carte, B2B
corporate contracts (per-seat: Turnkey seat management + credit quotas), federation
services and content licensing to partner institutions.

Normative: pricing experiments MUST NOT touch the integrity chain (no paid
fast-lanes through verification), and financial status enforcement follows the
Turnkey pattern — suspended payers lose *access*, never *earned evidence*; the
evidence graph and issued credentials survive any commercial state (Stripe
integration + financial access-control middleware, with EU 14-day cooling-off
honored).

## 8.3 Sustainability rules

1. Contribution margin per program MUST be visible before scaling a program.
2. AI spending has budgets and hard quota enforcement per tenant/department
   (existing gateway quotas) — pedagogical degradation from quota exhaustion MUST
   fail visibly (banner: reduced AI assistance), never silently.
3. The parallel-cost bubble of brownfield transformation (legacy + DAS running
   together) MUST be explicitly budgeted with a sunset date per process area.

---

# Chapter 9 — Accreditation and Regulatory Strategy

## 9.1 Dual-track (BOOK-00 Ch. 13, operationalized)

- **Track A — compatibility:** DLU MUST always emit traditional artifacts as
  *views over the evidence graph*: transcripts, ECTS/credit-hour mappings, grade
  scales, attendance proxies. Program design records both the competency
  trajectory (I/R/M map) and its ECTS projection. This makes DLU legible to any
  existing accreditor without waiting for regulatory innovation.
- **Track B — engagement:** institutions SHOULD pursue recognition of
  evidence-based progression with their quality agencies (EQAR/ENQA space, national
  agencies, regional US accreditors), using DLU's audit artifacts (coverage
  matrices, Bloom distributions, verification records) as the QA evidence base.

## 9.2 Internal QA is continuous, not episodic

P07 runs on kernel data: the Pedagogical Coach, `OutcomeCoverageMatrix`, Bloom
audits, calibration monitoring (BOOK-01 Ch. 6.2) and assessment integrity metrics
form a **living self-study**. Accreditation visits consume a generated dossier,
not a six-month document hunt. Normative: every claim in an accreditation dossier
MUST link to its kernel evidence.

## 9.3 AI Act organizational posture

As deployer of Annex III high-risk systems (BOOK-00 Ch. 12), the institution MUST
maintain: named human oversight per system (envelope owners, Ch. 3.2), logging and
record-keeping (kernel audit trails), transparency notices to learners, an
incident register with board review, and fundamental-rights impact assessment
where required. BOOK-19 maps obligations to mechanisms; the *organizational*
obligation here is that these are staffed roles, not documents.

---

# Chapter 10 — Partnerships, Federation and Mobility

P08, running on the PI-5 federation core (federation endpoints, institution and
policy endpoints — partially implemented):

- **Credit mobility:** inter-institutional recognition uses the same evidence
  pipeline as internal recognition (Recognition Agent + registrar HITL); a partner
  transcript is one more evidence source with its own trust weight.
- **Federated catalogs:** partner institutions expose course/competency catalogs;
  the GPS MAY plan across federated offerings where policy allows.
- **Credential ecosystems:** Open Badges 3.0 / ELM export (BOOK-16) makes DLU
  credentials portable into Europass and employer wallets; inbound, the same
  standards make external credentials machine-recognizable.
- Normative: federation agreements are encoded as **policy objects** (who
  recognizes what, at which trust weight, with which caps) — never as ad-hoc
  manual workflows.

---

# Chapter 11 — Transformation: Maturity Model and Change Management

## 11.1 Maturity ladder (per process area, not institution-wide)

| Level | Name | Marker |
|-------|------|--------|
| M0 | Traditional | manual process, systems as filing cabinets |
| M1 | Digital | process digitized, still human-executed |
| M2 | Smart | analytics inform humans (dashboards, alerts) |
| M3 | AI-Augmented | agents execute routine steps, humans approve (propose tier) |
| M4 | AI-Native | event-driven execution, humans govern exceptions; economics observable per unit |

Rules: maturity is assessed **per process area** (P01 may be M3 while P05 is M1);
promotion requires evidence (defined per level in BOOK-20); skipping levels is
prohibited for learner-facing areas — trust is sequenced (M2 dashboards build the
confidence that makes M3 acceptable).

## 11.2 Change management minima

Faculty program (Ch. 5.3) · student transparency (learners are told what AI does,
can see their model — BOOK-01 P8 — and know the human escalation path for every AI
touchpoint) · staff reskilling toward the new roles (Ch. 3.2) · a named
transformation owner with board mandate · communication that leads with the
mentorship dividend, not the technology.

---

# Chapter 12 — Executive Scorecard

The Institution Twin (BOOK-08) renders this continuously; targets are set per
institution, presence of the metrics is normative:

| Perspective | Metrics |
|-------------|---------|
| Learners | enrollment conversion, completion, time-to-goal, belonging index, satisfaction |
| Learning (BOOK-01 Ch. 10) | learning gain, durability, transfer, equity deltas (blocking guardrail) |
| Trust | verification SLA, credential verification uptime, integrity incident rate, % explained AI outputs (=100%) |
| People | mentorship hours/learner (**must rise**), faculty satisfaction & adoption, reskilling progress |
| Economics | C_learner and margin per program, inference cost per engine, parallel-cost burn-down |
| Transformation | maturity level per P01–P08, incident register trend, accreditation dossier freshness |

---

# Annex A — Turnkey Baseline Mapping (normative)

Status legend as in BOOK-00 Annex A.

| Mechanism | Turnkey asset | Status | Gap |
|-----------|--------------|--------|-----|
| Process architecture (Ch. 2) | `AI_NATIVE_UNIVERSITY_PROCESS_MAP.md` + `P01…P08_*.md` (L0/L1/L2, Mermaid) | ✅ | human accountability point per L2 to be made explicit (rule 2) 🟡 |
| Macro-roles (Ch. 3.2, 4) | process map §2 role hierarchy; RBAC service | ✅ | Learning Engineer / AI Pedagogy Steward / Evidence Registrar roles ⚪ (BOOK-19 RACI) |
| Multi-tenancy & archetypes (Ch. 7) | `Tenant`, `InstitutionType`, schema-per-tenant + RLS, tenant provisioning | ✅ | governance-profile configuration per archetype 🟡 |
| AI cost observability (Ch. 8.1) | ACP Gateway usage accounting, `PlatformUsageEvent`, LLM usage routes, quota budgets/keys | ✅ | attribution per engine / process area 🔵 |
| Seats & B2B (Ch. 8.2) | seat management UI, credit quota API | ✅ | — |
| Payments & financial access (Ch. 8.2) | Stripe service, financial-check middleware + Istio authz, 14-day refund policy | ✅ | "evidence survives suspension" invariant to assert in tests 🟡 |
| Accreditation views (Ch. 9.1) | transcripts/grade data via ERPNext mirror; coverage matrix, Coach reports | 🟡 | ECTS projection views over evidence graph ⚪ (BOOK-16) |
| Continuous QA (Ch. 9.2) | Pedagogical Coach, `OutcomeCoverageMatrix`, QA routes | ✅ | generated accreditation dossier ⚪ |
| Federation (Ch. 10) | PI-5 federation core (federation/institution/policy endpoints) | 🟡 | policy-object encoding of agreements; federated GPS ⚪ |
| Maturity instrumentation (Ch. 11) | PI status reports, release gates | 🟡 | per-area maturity assessment ⚪ (BOOK-20) |
| Institution Twin (Ch. 3.1, 12) | dashboards (institution, analytics) | 🟡 | three-economy health indicators ⚪ (BOOK-08) |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Three economies | Knowledge, trust and attention economies of Ch. 3.1 |
| Envelope owner | Named human role accountable for an AI agent's configuration and behaviour |
| Mentorship dividend | Faculty hours freed by AI absorption of routine load, reallocated to human attention |
| Parallel-cost bubble | Temporary double running cost of brownfield transformation |
| Maturity ladder | M0–M4 per-process-area transformation scale of Ch. 11.1 |
| Track A / Track B | Accreditation compatibility track (views over evidence) / regulatory engagement track |
| Policy object | Machine-readable encoding of a federation/recognition agreement |

---

*BOOK-02 v1.0 — awaiting review. Next per dependency order: BOOK-03 (Academic
Operating System).*
