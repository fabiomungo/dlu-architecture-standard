# BOOK-07 — Faculty Digital Twin
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The faculty member is the most transformed role of the AI-native university
> (BOOK-02 Ch. 5) — and therefore needs a twin as much as the learner does: to
> hold pedagogical authority over agents, to defend reallocated time, to carry
> expertise into orchestration decisions, and to anchor the human accountability
> chain. This Book specifies the Faculty Digital Twin, catalogs the **faculty
> functions** running today in DLU Builder Turnkey (authoring, Course Factory,
> the 3-gate approval workflow, teaching sections), and closes with a
> **verification against CINECA ESSE3** — the faculty-facing system of record of
> Italian universities — identifying the functions DLU does not yet cover.
>
> **Conforms to:** BOOK-00 v2.0. **Depends on:** BOOK-04, BOOK-06 (twin
> mechanics are shared). **Informs:** BOOK-09/10 (envelopes), BOOK-15
> (verification duties), BOOK-17 (faculty workspaces), BOOK-19 (RACI).
> **Primary audience:** architects, academic leadership, deans.

**Normative language:** RFC 2119. Twin mechanics (anchor, layers, context
service, versioning, consent, erasure) are **inherited from BOOK-06** and not
restated; this Book specifies deltas and faculty-specific content.

---

# Chapter 1 — Purpose

Three forces make the Faculty Twin necessary:

1. **Pedagogical authority over agents** (BOOK-00 Ch. 5.1, BOOK-02 Ch. 5.2):
   faculty configure, inspect and answer for AI agents acting in their courses.
   That authority needs a place to live: the **delegation envelope** (Ch. 4).
2. **The mentorship dividend must be measurable** (BOOK-02 Ch. 5.1): reallocation
   from content delivery to mentorship/verification is a board commitment; the
   twin's workload layer is its evidence — *in defense of faculty time, never for
   surveillance micro-management* (normative, restated).
3. **Accountability chains end at humans** (BOOK-00 Ch. 5.3): every HITL queue,
   verification act and approval gate references a faculty/staff identity with a
   role, a scope and a capacity.

---

# Chapter 2 — Faculty Twin Layers

Anchor: `FacultyTwin` (GUID, 1:1 `platform.users`, tenant-scoped) — implemented
initially as an extension of the existing `FacultyProfile`
(institution/department-linked, running today).

| Layer | Contents | Sole writers | Turnkey seed |
|-------|----------|--------------|--------------|
| F1 — Identity & Position | profile, department, role/rank, office hours, contacts | HR sync (P03), self-service | `FacultyProfile` ✅ |
| F2 — Expertise | disciplines, competencies (same Competency Graph vocabulary as students — BOOK-05), scholarship refs, teachable-course map | self + department head validation | ⚪ (new; enables assignment optimization P03.1.03) |
| F3 — Teaching Portfolio | current/past `TeachingSection` assignments with roles, authored courses, FEX authorship provenance | assignment services | `TeachingSection` + `FacultyAssignment` routes ✅ |
| F4 — Pedagogical Envelope | per-course, per-agent delegation settings (Ch. 4) | faculty (within governance floors/ceilings) | ⚪ (new — the Book's core addition) |
| F5 — Workload & Capacity | teaching load, authoring effort, verification queue depth, mentorship hours, PD | computed from kernel events + ERPNext HR mirror | 🟡 (P03.1.03 data exists; instrumentation new) |
| F6 — AI Collaboration Memory | durable agent-faculty working context (writing style for feedback, recurring decisions) | ACE only | ⚪ |

Consent model: faculty are employees — the lawful basis differs from students
(contract + legitimate interest), but the same **purpose-scoping and
anti-surveillance rules apply**: F5 aggregates only, F6 inspectable and deletable
by the faculty member, no protected-attribute features.

---

# Chapter 3 — Faculty Function Catalog (as running in Turnkey)

The faculty's working day, mapped to systems that exist today:

## 3.1 Course design and authoring (P02.1.01–03)

- **DLU Course Builder + FEX v1.3** (BOOK-05 §4.4): the 9-step outcome-first
  wizard — the faculty-facing instrument for course design; bilingual; produces
  the reviewable `*.dlu.json`.
- **Course Factory**: catalog setup, grading schemes, AI generation pipeline with
  idempotent APIs and mock-LLM mode for validation.
- **Course Architect proposals** (`/architect/propose`): AI-drafted structures
  the faculty accepts/modifies — propose-tier by construction.

## 3.2 The Course Approval Flow — 3 phases, 3 gates (running)

The governance workflow (`CourseWorkflowState`, `course_workflow.py`,
`course_governance` routes) is adopted by the standard as the **canonical
authoring governance machine**:

```text
Phase A  CATALOG_APPROVED      Dean approves catalog slot
Phase B  IN_AUTHORING          Faculty designs (Builder/FEX, blueprint)
Gate 1   BLUEPRINT_VALIDATION  Dean/Provost validates the blueprint
         GENERATING            AI generation runs (Factory)
Gate 2   FACULTY_REVIEW        Faculty reviews/corrects AI output
Gate 3   UNDER_DEAN_REVIEW     Dean/Provost final approval → published
```

Normative readings: Gate 2 is the **faculty pedagogical authority gate** — AI
output enters no learner's path without it; gates map to HITL tiers (BOOK-02
Ch. 4); transitions are events; actor roles are enforced server-side
(`_require_review`). The import pipeline's human gates
(`awaiting_semantic_review`, `awaiting_review`) are the same principle for
legacy content.

## 3.3 Teaching operations

Teaching sections CRUD + faculty assignment with roles (running routes);
collaboration on content (Yjs real-time co-authoring, comments, review
checkpoints); QA instruments (Pedagogical Coach reports, coverage matrices,
Bloom audits — BOOK-01).

## 3.4 Assessment & verification duties (BOOK-15 forward)

Summative grading authority; viva examination (dialogic verification);
evidence verification (`verified` status is faculty/examiner-granted);
HITL queues (proposals to approve/reject).

## 3.5 Mentorship & student-facing duties

Advisor views over student twins (`purpose=staff_view`, audited — BOOK-06 §5.1);
intervention approvals (Success Agent proposals); office hours (F1); CAT-7
supervision (peer-teaching learners).

---

# Chapter 4 — The Pedagogical Envelope (F4)

The envelope is the machine-readable form of academic freedom over agents:

```yaml
envelope:                       # one per (faculty, course, agent_key)
  agent: tutor
  course_id: 812
  autonomy: act                 # act | propose | off  — never above governance ceiling
  scope:
    allowed_sources: [course_resources, knowledge_graph]   # grounding restriction
    struggle_zone: {enabled: true, giveup_threshold: 3}     # BOOK-01 P4 tuning
    tone: socratic
  visibility:
    transcript_access: weekly_digest    # faculty inspection cadence
  overrides_reason: "lab course — hints allowed earlier"    # audit trail
```

Rules:

1. **Floors and ceilings:** institution governance sets safety/integrity floors
   (e.g., grounding mandatory, no summative autonomy) and autonomy ceilings;
   faculty tune freely between them (BOOK-02 Ch. 5.2). Envelope changes are
   versioned, audited, effective at next agent turn.
2. **Inspection right:** faculty MAY replay any agent interaction within their
   courses (traceability guarantee, ADR-0006, honoring student privacy: tutoring
   transcripts are course-scoped, identity-minimized in digests).
3. **Default envelope** per agent/course-type ships with the platform; a course
   with no explicit envelope runs on defaults — never ungoverned.
4. Envelope ownership transfers with course handover (P03.1.07 offboarding).

---

# Chapter 5 — Workload Layer (F5) and the Mentorship Dividend

F5 is computed from kernel events (authoring actions, gate reviews, verification
acts, viva sessions, advisory meetings) plus the ERPNext HR mirror (contracted
load). It renders the BOOK-02 Ch. 5.1 reallocation table **per faculty member,
per term** — the instrument that makes "mentorship hours must rise" auditable.

Normative constraints: aggregates per week/term (no keystroke-level tracking);
the faculty member sees everything computed about them (open model — same
principle as students, BOOK-06 Ch. 8); F5 feeds assignment optimization
(P03.1.03) and capacity checks on HITL queues (a verification queue exceeding
capacity is an institutional alert, not a faculty failing).

---

# Chapter 6 — ESSE3 Verification: Faculty Functions Coverage (the double-check)

CINECA **ESSE3** is the student-records and faculty-services system of most
Italian universities. Its *Area Docente* function set is the reality-check for
faculty-function completeness. Verification result:

## 6.1 Coverage table

| ESSE3 Area Docente function | DLU coverage | Status |
|-----------------------------|--------------|--------|
| Syllabus / programmi insegnamento | Course Builder + FEX (outcome-first, richer) | ✅ superior |
| Comunicazioni agli iscritti | notification system | ✅ |
| Approvazione piani di studio (CDS president) | GPS scenario adoption + HITL proposal queue | 🟡 role mapping needed (program-director approval flow) |
| Visione carriera/libretto studenti | student twin staff views (audited) + ERPNext mirror | ✅ (with better audit) |
| Ricevimento studenti (office hours) | — | **G1 gap** (minor): F1 field + scheduling |
| **Gestione appelli d'esame** (exam sessions, enrollment windows, minimum-sessions rules, enrollee lists) | assessment runtime exists; the *appello* mechanic (session calendars, student self-enrollment, per-session lists) does not | **G2 gap** |
| **Verbalizzazione online** (grade minutes with **qualified digital signature**, commissioner co-signing, legal preservation) | evidence + VC signing exist; legally-valid Italian verbale (firma qualificata/remota, conservazione) does not | **G3 gap** |
| **Registro lezioni e diario** (daily teaching log, formal approval by department head) | xAPI records delivery activity; the *legal register* artifact does not exist | **G4 gap** |
| **Gestione tesi** (advisor assignment, supervision, PDF/A deposit approval, plagiarism check) | plagiarism service ✅; **no thesis aggregate at all** (supervision, milestones, deposit, defense) | **G5 gap** (largest) |
| **Commissioni** (exam/graduation/doctoral committees; president registers final exams) | graduation clearance (P01.1.07) + credential issuance; committee formation & final-exam verbalization missing | **G6 gap** |
| Prove parziali / idoneità (proficiency, pass-fail) | formative/summative pipeline covers semantics; pass-fail verbalization ties to G3 | 🟡 |

## 6.2 Gap resolutions (normative direction)

- **G1 (office hours):** F1 field + booking via existing scheduling; trivial,
  bundle into faculty workspace sprint (BOOK-17).
- **G2 (appelli):** model as **AssessmentSession** aggregate (C6): course ×
  term × session windows, capacity, student self-enrollment, enrollee lists,
  communications. Where an Italian SIS is present, ESSE3 remains the system of
  record and DLU mirrors (see 6.3); in DLU-native deployments the aggregate is
  authoritative. → BOOK-15.
- **G3 (verbalizzazione):** two-part resolution: (a) the *pedagogical* result is
  already the evidence pipeline; (b) the *legal act* (qualified signature,
  preservation) is a **driver concern** — in Italy, sign in ESSE3 (or a QES
  provider driver) and ingest `grade.synced`; DLU MUST NOT reimplement Italian
  legal preservation. → BOOK-16/19 + driver contract.
- **G4 (registro):** resolve as **Track-A view** (BOOK-02 Ch. 9.1 pattern): the
  teaching register is *generated* from kernel delivery events (sections taught,
  topics from lesson metadata, hours) and submitted for department-head approval
  as a HITL artifact — a compliance view over data DLU already has. → BOOK-17
  faculty workspace.
- **G5 (thesis):** introduce the **Thesis/Capstone aggregate** as a specialized
  LearningMission with the Project-Studio pattern (BOOK-01 Ch. 11): advisor
  (first/second) assignment, milestone checkpoints with process evidence,
  plagiarism check (existing service), PDF/A deposit, committee review, defense
  as dialogic verification, evidence → credential. This is the single largest
  functional gap ESSE3 exposes. → BOOK-15 (evidence chain) + BOOK-17 (workspace).
- **G6 (committees):** **Committee** aggregate (C3): formation, roles
  (president/members), scope (exam/graduation/doctoral), verbalization acts
  binding to G3 driver. → BOOK-15/19.

## 6.3 The Italian deployment note (normative)

In Italian universities the **student-records driver slot (ADR-0009) is occupied
by ESSE3, not ERPNext**. The driver model absorbs this without kernel change:
`enrollment.synced`/`grade.synced` originate from ESSE3 interfaces; verbalization
and legal preservation stay ESSE3-side; DLU adds the intelligence layer (twin,
GPS, evidence, agents) that ESSE3 does not have. A dedicated ESSE3 driver
contract (auth, event mapping, appello mirroring) is an RFC candidate for
BOOK-18.

---

# Chapter 7 — Faculty Lifecycle (P03, adopted)

`recruitment → onboarding/provisioning → assignment → active (teach/author/
verify/mentor) → evaluation → development → offboarding with knowledge transfer`

Twin behaviour: F-layers activate progressively (F2 expertise at onboarding, F4
envelopes at first assignment); **course handover** (P03.1.07) transfers envelope
ownership and authorship provenance explicitly; evaluation (P03.1.04) reads F5
aggregates + outcome metrics — never raw agent transcripts (anti-surveillance
rule); PD recommendations (P03.1.05) reuse the student-side machinery (faculty
are learners too — same Competency Graph, same evidence model, CAT applies).

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| F1 Identity/Position | `FacultyProfile` (institution/department FKs) | ✅ | office hours field (G1) ⚪ |
| F3 Portfolio | `TeachingSection` + `FacultyAssignment` + routes | ✅ | authorship provenance from FEX author block 🔵 |
| Approval workflow | `CourseWorkflowState` 3-phase/3-gate + `course_workflow.py` + governance routes | ✅ | adopt as canonical; map gates to HITL tiers explicitly 🟡 |
| Authoring instruments | Course Builder/FEX, Course Factory, architect propose, collaboration (Yjs), Coach | ✅ | — |
| F4 Envelopes | AI Management registry (per-tenant agent configs) | 🟡 | per-course faculty-owned envelope layer ⚪ (BOOK-10 contract) |
| F5 Workload | P03 processes, ERPNext HR | 🟡 | event-derived instrumentation ⚪ |
| F2 Expertise / F6 Memory | — | ⚪ | new (F2 rides Competency Engine reuse) |
| G2 appelli / G3 verbale / G4 registro / G5 tesi / G6 commissioni | see Ch. 6.2 | ⚪ | BOOK-15/16/17/18 assignments as noted |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Pedagogical envelope | Machine-readable, faculty-owned delegation settings per (course, agent) — Ch. 4 |
| Gate 2 | The faculty review gate of the approval flow — the pedagogical authority checkpoint |
| AssessmentSession (appello) | Scheduled exam session with enrollment window and enrollee list (G2) |
| Teaching register | Compliance view over kernel delivery events, department-approved (G4) |
| Thesis aggregate | Capstone LearningMission with advisor, milestones, deposit, defense (G5) |
| Committee | Formal examining body with president/member roles and verbalization acts (G6) |

---

*BOOK-07 v1.0 — awaiting review. ESSE3 gap items G1–G6 have been assigned to
BOOK-15/16/17/18/19. Next per dependency order: BOOK-08 (Institution Digital
Twin).*

**Sources (ESSE3 verification):**
[Esse3 – Docenti — Università della Calabria](https://www.unical.it/servizi-ict/servizi-didattica/esse3-web-docenti/) ·
[ESSE3 — Verbalizzazione e Calendario Esami in Area Web Docente — Cineca](https://eventi.cineca.it/it/formazione/esse3-verbalizzazione-e-calendario-esami-area-web-docente) ·
[Assistenza per docenti e lettori — Esse3 — UNIUD](https://progettoesse3.uniud.it/docenti-e-lettori) ·
[CARRIERA STUDENTE — ESSE3 — CINECA Technical Portal](https://wiki.u-gov.it/confluence/display/ESSE3/CARRIERA+STUDENTE) ·
[Sistema Informativo Esse3 — Docenti — UNISA](https://web.unisa.it/servizi-on-line/helpdesk/esse3/docenti) ·
[Syllabus on-line — guida alla compilazione — UNISS](https://sdr.medicinachirurgia.uniss.it/sites/st03/files/2026-03/tutorial_syllabus.pdf)
