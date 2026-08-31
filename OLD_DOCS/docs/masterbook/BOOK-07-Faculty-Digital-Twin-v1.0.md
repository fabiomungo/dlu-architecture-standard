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

> ✅ **IMPLEMENTED (NEW-24, SPRINT-13, 2026-07-31):** human tutoring is now
> tracked end to end (T5, `dlu_builder_tk`) — `tutoring_sessions`/
> `tutoring_session_notes` (originating from a real G1 office-hours booking
> or scheduled/adhoc against a real `AdvisorAssignment`), with a mandatory
> outcome required to close a session (service guard + a DB CHECK, defense
> in depth) that posts REAL workload hours to `faculty_workload_entries`
> (`entry_type="tutoring"`, `unit="hours"` — the first source in this
> codebase to carry real duration data; `"tutoring"` had been reserved with
> no producer since SPRINT-10). `intervention_logs` records human-tutor
> interventions; escalating one emits the REAL `RISK_DETECTED` event
> (reusing the existing crisis pathway), never a new mechanism. "Advised
> over student twins (`purpose=staff_view`, audited)" above is now
> literally true: a NEW, dedicated `twin_access_audits` table (BOOK-22
> §C22.5's own deliberate first exception to the `platform.audit_logs`-
> reuse convention) is written on every such read, and — unlike the
> pre-existing best-effort audit — a write failure here fails the whole
> read, closing a real, pre-existing gap where IW4's own caseload view
> produced zero audit rows despite this section's claim.

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
| F1 Identity/Position | `FacultyProfile` (institution/department FKs) — **as of NEW-09 (2026-07-26), office hours (G1) has a real publish/booking workflow**: `office_hours_service.py` + `OfficeHourBooking` (tenant schema) validates bookings against the existing weekly template | ✅ **G1 closed (NEW-09)** | — |
| F3 Portfolio | `TeachingSection` + `FacultyAssignment` + routes | ✅ | authorship provenance from FEX author block 🔵 |
| Approval workflow | `CourseWorkflowState` 3-phase/3-gate + `course_workflow.py` + governance routes | ✅ | adopt as canonical; map gates to HITL tiers explicitly 🟡 |
| Authoring instruments | Course Builder/FEX, Course Factory, architect propose, collaboration (Yjs), Coach | ✅ | — |
| F4 Envelopes | **as of NEW-09, a real, per-course faculty-owned envelope layer**: `FacultyEnvelope` (platform schema, versioned insert-new-row-per-update) folded with `AiAgentConfig.envelope_defaults` via `pedagogical_moves.resolve_effective_envelope` (tightening-only: autonomy caps MIN-rank, disabled-move/class sets union, humility floor re-validated on the merge) — wired into the REAL Decide-step runtime (`ace_service._resolve_faculty_envelope`/`_decide`, both `check_preconditions` and `_choose_escalation` call sites use the merged result) | ✅ **F4 delivered (NEW-09)** | no production route/frontend caller supplies the `course_id` this wiring needs yet (no workspace has a "which course" concept) — the mechanism is real and end-to-end tested, not yet live in a real user flow; same shape as NEW-04's G7 inertness note |
| F5 Workload | P03 processes, ERPNext HR | 🟡 | event-derived instrumentation ⚪ — still not built (I3's Attention economy, BOOK-08, is honestly thinner for exactly this reason) |
| F2 Expertise / F6 Memory | — | ⚪ | new (F2 rides Competency Engine reuse) |
| G2 appelli / G3 verbale / **G4 registro** / G5 tesi / G6 commissioni | see Ch. 6.2 | **all six now closed** — **G4 ✅ (NEW-09)**: `teaching_register_service.py` — `TeachingRegister`/`TeachingRegisterSession`/`TeachingRegisterApproval`, drafted deterministically from `TeachingSection.schedule` × `AcademicTerm` dates (no delivery/xAPI event stream exists in this codebase to draft from — an honest, reproducible substitute), department-head approval chain, append-only audit trail; **G2 ✅ (NEW-05, 2026-07-19)**: `AssessmentSession` (the Appello aggregate) — native/mirror modes, per-enrollment one-shot grade refusal, minimum-session policy audit + I4 alert at calendar publication (BOOK-15 §Annex A); **G5 ✅ (NEW-06, 2026-07-22)** + **G6 ✅ (NEW-06, 2026-07-22)**: `Thesis`/`ThesisMilestone`/`ThesisDeposit` (guarded status machine, four advisor-HITL milestones) and `Committee`/`CommitteeMember`/`CommitteeVerdict` (governed formation, quorum + conflict-of-interest check, `pass` writes the only `committee_verdict` trust-1.0 evidence in the codebase) — BOOK-15 §Annex A; **G3 ✅ (NEW-11, 2026-07-29 + NEW-12, 2026-07-30)**: ESSE3 `verbale_firmato` path and QES-provider `signature_completed` path both close `pending_verbalization` via the existing, unmodified `committee_service.close_verbalization` consumer — BOOK-16 §Annex A | BOOK-15/16/17/18 assignments as noted — resolved as specified, no further action needed |

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


---

## Addendum — EKG v1.1 / ATA 1.0 / Course Format v2.0 (2026-08-08)

**Persona × EKG-usage/RKG-maintenance (RFC-0002, BOOK-19 §1.2):** Faculty's EKG usage is
`FAC-01…08`. Unlike Student, Faculty carries a real RKG-maintenance duty — not thin: Course
Format v2.0 authoring writes directly into the ontology (fields bind to concept/outcome/skill
ids at export), Faculty holds the academic-review sign-off step in the `PolicyVersion` rollout
pipeline (ADR-0016), and course-scoped evidence review. This does not change the "Low-Med" Suite
impact rating for the Faculty *Twin's own layers* — it is additive persona-RACI scope, not a Twin
model change.

Cross-cutting alignment only otherwise. See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.

See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for the full change-set; `../dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` and the Suite `DLU_EKG_Suite/ATA/` for detail.
