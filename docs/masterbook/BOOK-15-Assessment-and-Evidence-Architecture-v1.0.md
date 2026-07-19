# BOOK-15 — Assessment & Evidence Architecture
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The epistemic engine of the university. Assessment is where activity becomes
> truth: every scored interaction yields a **fast product** (mastery signal,
> BKT) and — when aligned — a **durable product** (evidence, trust-weighted and
> append-only). This Book specifies the full pipeline, the trust model, dialogic
> verification, and the three aggregates the ESSE3 verification exposed as
> missing: **AssessmentSession (appelli, G2), Thesis (G5), Committee (G6)**.
> It closes with the standing **G-register check**.
>
> **Conforms to:** BOOK-00 v2.0 (Ch. 12.2, ADR-0012). **Depends on:** BOOK-01
> (Ch. 8 — evidence-centered design), BOOK-04 (C6/C8), BOOK-05 (`ASSESSES`),
> BOOK-11 (Assessment Agent boundaries). **Informs:** BOOK-16 (credentials
> consume evidence), BOOK-14 (SIT_EXAM/RETAKE/MILESTONE edges).
> **Implementation profile:** constitution §11 (STX-08).
> **Primary audience:** assessment leads, registrars, architects, faculty.

**Normative language:** RFC 2119. **Source-of-content rule compliance:** built
on running Turnkey assets: quiz/lab runtime, `grading_service`,
`bloom_quiz_service`, `quiz_feedback_service`, xAPI/Caliper ingestion,
`OutcomeAssessmentAlignment`, `plagiarism_service`, QTI serialization,
`CourseFinalExamination` + `ExamLearningObjective` (FEX v1.2+), BKT, SM-2.

---

# Chapter 1 — Purpose: Two Products per Interaction

**Evidence-centered design (Mislevy)** is the method: define the claim → define
what behaviour evidences it → design the task. Every assessment interaction
then yields:

| Product | Speed | Consumer | Store |
|---------|-------|----------|-------|
| **Mastery signal** | immediate, per attempt | BKT (L4), Tutor, Coach, spaced repetition | `concept_mastery` (probabilistic, self-correcting) |
| **Evidence** | on alignment, trust-weighted | Competency Engine (L3), Credential Engine, GPS | `EvidenceRecord` (append-only, conservative) |

The split is the architecture: fast/forgiving for steering learning,
slow/conservative for certifying capability (BOOK-06 §6.1). An assessment with
no alignment chain produces the first product only — flagged as an authoring
defect (BOOK-01 §5.2.2), never silently promoted to evidence.

---

# Chapter 2 — Assessment Taxonomy

| Kind | Purpose | Evidence weight class |
|------|---------|----------------------|
| Diagnostic | position fixing (onboarding, cold start) | seed-only (low trust until corroborated) |
| Formative | steering; retrieval practice (BOOK-01 P2) | low (volume compensates) |
| Summative | certification of course/module outcomes | high (proctored/authentic conditions) |
| Authentic | projects/labs with **process evidence** | high (process trail is the point) |
| Dialogic (viva) | human verification of high-stakes claims | highest (Ch. 6) |
| Challenge | credit by examination (GPS `CHALLENGE` edges) | summative-grade |
| Capstone/Thesis | integrative, committee-verified (Ch. 7) | highest |

All kinds share: Bloom targeting against the outcome's level (running
`bloom_quiz_service` + `QuizBloomDistribution` audit), QTI serialization where
interoperable, and the single ingestion path (Ch. 3). The FEX final-examination
block (13 method types, CLO weight vector) is the declared summative plan
(BOOK-05 §4.4).

---

# Chapter 3 — The Evidence Pipeline (sole writer)

Constitution §11, elevated and completed:

```text
attempt/submission ──► grading (existing) ──► assessment.completed ─┐
xAPI/Caliper stmt ──► ingestion (existing) ──► activity.recorded ───┤
grade.synced (driver: ERPNext/ESSE3) ────────────────────────────────┤
viva/committee verdicts (Ch. 6–8) ───────────────────────────────────┤
recognition dossiers (BOOK-14 §4, propose) ──────────────────────────┤
                                                                     ▼
                                   AssessmentEvidenceService (Celery, sync)
                                     1. BKT update (mastery product)
                                     2. alignment chain: Assessment → OutcomeAssessmentAlignment
                                        → CLO → CLOCompetency → Competency
                                     3. EvidenceRecord (normalized score, source_kind,
                                        source_trust, weight, payload snapshot)
                                     4. emit evidence.recorded
                                                                     ▼
                                   CompetencyGraphService.recompute → competency.*
```

Rules (constitutional, restated as binding): the service is the **only writer**
of `EvidenceRecord`; evidence is **append-only** (corrections = new records
referencing `source_ref`); identity via `identity_map` only; unmapped
assessments log a WARN metric surfaced to authors.

---

# Chapter 4 — The Trust Model

## 4.1 Source trust (seed values; institution-calibrated, versioned)

| Source | Trust | Notes |
|--------|-------|-------|
| Committee-verified (thesis defense, graduation exam) | 1.0 | Ch. 7–8 |
| Human observation / viva | 1.0 / 0.95 | examiner-signed |
| Proctored or authentic-with-process summative | 0.9 | includes `grade.synced` official results |
| Challenge exam | 0.85 | conditions-controlled |
| Unproctored quiz/lab | 0.6 | volume + triangulation compensate |
| Peer evidence (CAT-7 teaching, peer review) | 0.5 | BOOK-01 P9 |
| Recognition dossier (unverified) | 0.4 | ceiling `evidenced` until human decision |
| Self-report / diagnostic | 0.3 | seeding only |

## 4.2 Confidence and status

`confidence = clamp(Σ score·weight·recency·source_trust / Σ weight)` with
180-day default half-life (BOOK-01 Ch. 6); statuses `evidenced ≥ 0.5`,
`mastered ≥ 0.8`, **`verified` = human act only** (ADR-0012 — no formula
reaches it).

## 4.3 Triangulation (normative)

Credential-bearing competency claims require **≥ 2 evidence types** including
≥ 1 from the high/highest classes; drift toward single-source evidence is a
trust-economy alarm (BOOK-08 I3). Trust weights themselves are calibrated:
predicted vs observed downstream performance per source class (the BOOK-09
Ch. 7 discipline applied to the evidence model).

---

# Chapter 5 — AssessmentSession: the Appello Aggregate (G2)

The scheduled-examination mechanic, absent from the platform and required by
BOOK-14's SIT_EXAM/RETAKE edges:

```text
AssessmentSession (C6, GUID, tenant):
  assessment_ref · course_id · term_id · session_date/window
  enrollment_opens/closes · capacity · location/modality
  committee_id (nullable — Ch. 8) · status (planned→open→closed→graded→finalized)
  policy: min_sessions_rule ref · attempt_caps · grade_refusal_allowed
```

- **Learner flow:** self-enrollment within windows → enrollee list →
  communications (existing notification system) → sitting → grading → result
  publication → *(where policy allows)* **grade refusal** window → retake
  eligibility.
- **Grade refusal (rifiuto del voto):** modeled as a learner decision event on
  a passing result: the mastery product stands (they demonstrably know it);
  the *official* evidence enters only on acceptance. The GPS prices the retake
  (BOOK-14 `RETAKE`).
- **Two deployment modes:** *native* (DLU authoritative — greenfield/corporate)
  and *mirror* (ESSE3 authoritative: sessions, enrollments and verbali mirror
  in via the driver; DLU adds intelligence — readiness prediction, session
  recommendation, list analytics). Mode is a tenant policy; the aggregate is
  identical.
- **Minimum-session rules** (e.g., 3 sessions in winter/summer periods) are
  policy objects validated at calendar publication — a course failing its
  minimum is an I4 operational alert before it becomes a student complaint.

---

# Chapter 6 — Dialogic Verification (vivas)

The highest-trust instrument, made scalable:

1. **Dossier (AI, propose):** the Assessment Agent compiles from the evidence
   graph: claims to verify, evidence summary, probe questions targeting the
   *weakest* links (low-confidence competencies, single-source claims),
   suggested Bloom-level escalation. R5 deliberation, fully traced.
2. **Examination (human):** examiner conducts; AI MAY transcribe/timestamp
   (consented); the verdict is the examiner's alone, signed.
3. **Product:** viva verdict → evidence at trust 0.95–1.0; competency
   `verified` transitions; committee co-signing where required (Ch. 8).
4. **When required:** credential-bearing claims above policy thresholds;
   integrity doubts (Ch. 9); recognition claims above yield thresholds
   (BOOK-14 §4.2); sampling audits (a % of ordinary summatives, QA-driven).
5. **Scaling:** dossier automation is what makes vivas affordable at scale —
   the faculty hour goes to examining, not preparing (BOOK-02 §5.1
   reallocation, instrumented via F5).

---

# Chapter 7 — Thesis & Capstone (G5)

The largest ESSE3 gap, resolved as a specialized LearningMission running the
Project-Studio pattern (BOOK-01 Ch. 11):

```text
Thesis (C6/C8, GUID):
  learner · advisors (first, second — FacultyAssignment roles) · title/proposal
  milestones[] (proposal→literature→draft→final) each with process evidence
  plagiarism_check (existing service — report attached as evidence)
  deposit (PDF/A, versioned, advisor-approved)
  defense: viva (Ch. 6) before Committee (Ch. 8) · verdict + grade
  status: proposed→approved→in_progress→submitted→deposited→defended→archived
```

Normative points: **process evidence throughout** (versioned drafts,
checkpoint reviews — the integrity strategy is the workflow itself, Ch. 9);
advisor approvals are HITL acts (BOOK-07 duties); the deposit is immutable and
retention-classed (institutional record); the defense verdict is
committee-signed evidence at trust 1.0 feeding directly into credential
criteria (BOOK-16). The GPS schedules the whole chain as `MILESTONE` edges
against committee availability.

---

# Chapter 8 — Committees (G6)

```text
Committee (C3, GUID): kind (exam|graduation|doctoral|recognition)
  · members[] (role: president|member|secretary; FacultyProfile refs)
  · quorum rules · term/session scope · formation_approved_by (dean/rector)
Acts: convocation → session minutes → verdicts (per candidate) → verbalization
```

- **Formation** is a governed act (dean/provost approval; conflicts of interest
  declared — an advisor SHOULD NOT preside over their own advisee's defense
  without policy exception).
- **Verdicts** are collective, president-signed, secretary-recorded; they enter
  the pipeline as highest-trust evidence.
- **Verbalization binding (G3):** where the legal act is external (ESSE3
  verbale with qualified signature), the Committee act *prepares* it and the
  driver executes it; `grade.synced` confirms (BOOK-14 pending-verbalization
  semantics). DLU never fabricates the legal act (BOOK-07 §6.2 G3 resolution).
- Recognition committees (where institutional policy requires collegiality on
  RPL) reuse the same aggregate — closing the loop with BOOK-14 §4.2.

---

# Chapter 9 — Integrity Architecture

BOOK-00 Ch. 12.2 operationalized, in order of preference:

1. **Design-out** (authentic-first): process evidence, in-context checkpoints,
   personalized task variants (`ContentVariant` substrate), oral components —
   assessments whose cheating cost exceeds their honest cost.
2. **Triangulate** (Ch. 4.3): converging types, so no single artifact carries
   a credential.
3. **Verify dialogically** (Ch. 6): targeted vivas on doubt or stakes.
4. **Detect, humbly:** plagiarism/similarity (running service) as *signals for
   human review* — **AI-generated-text detectors MUST NOT be sole evidence of
   misconduct** (unreliable, biased against non-native writers); they may only
   trigger review conversations.
5. **Proctor, proportionally:** surveillance is last resort, consented,
   privacy-assessed (BOOK-19), never default.

Integrity incidents: due process (learner heard, human decision, appeal path —
Ch. 11); confirmed incidents annotate (never delete) affected evidence and
recompute confidence downstream.

---

# Chapter 10 — AI Roles and Boundaries

| AI act | Tier | Boundary |
|--------|------|----------|
| Item generation (Bloom-targeted) | act (formative) / propose (summative) | faculty approve summative items (Gate-2 spirit) |
| Feedback drafting | act (formative, feeds-forward form) | summative feedback is faculty-signed |
| Viva dossier prep | propose | examiner owns the exam (Ch. 6) |
| Grading assistance | propose | **never sole grader of summative/credential-bearing work** (BOOK-01 Ch. 8); rubric-anchored drafts, human sign-off |
| Item calibration | act (analytics) | difficulty/discrimination from attempt data (IRT-lite): flags bad items to authors; feeds adaptive selection within faculty-set bounds |
| Readiness prediction | act (advisory) | powers SIT_EXAM recommendations ("target the June session"); honest probability rendering (BOOK-14 Ch. 8.4) |

All learner-facing acts run as moves under envelopes (BOOK-09/10); assessment
scenarios in the harness include grading-assistance bias checks (BOOK-11).

---

# Chapter 11 — Fairness, Accessibility, Appeal

1. **Accommodations** (L1 accessibility prefs): extended time, modality
   alternatives, assistive compatibility — applied automatically at session/
   assessment level, privately (no disclosure in lists).
2. **Item fairness:** differential-performance monitoring across cohorts at
   item level (the psychometrics of Ch. 10 sliced per BOOK-08 equity
   discipline, n≥10) — flagged items go to review.
3. **Appeal (contest):** every result is contestable (BOOK-06 Ch. 8.3): appeal
   → human review (committee where policy requires) → outcome as new evidence
   with lineage. Appeals are SLA-tracked (I5).

---

# Chapter 12 — G-Register Check (standing verification)

| Gap | This Book's disposition |
|-----|------------------------|
| G1 office hours | not in scope (BOOK-17 confirmed owner) ✅ |
| **G2 appelli** | **resolved**: AssessmentSession aggregate, dual mode (native/mirror), refusal + minimum-session policies (Ch. 5) |
| G3 verbalizzazione | boundary honored: committee acts prepare, driver executes legal act, `grade.synced` confirms (Ch. 8) — full driver contract to BOOK-18 |
| G4 registro lezioni | not in scope; delivery events this Book emits are among its inputs (BOOK-17 owner) ✅ |
| **G5 tesi** | **resolved**: Thesis aggregate with process evidence, deposit, defense (Ch. 7) |
| **G6 commissioni** | **resolved**: Committee aggregate, formation governance, verdict evidence (Ch. 8) |
| G7 regulation-year | consumed as constraint (session/attempt policies may vary per regulation year — policy-object versioning honored) ✅ |
| G8 ANS/SUA-CdS | this Book's data (sessions, verdicts, degrees) feeds the completeness monitor (BOOK-08 §6.3); no reporting duty here ✅ |

---

# Annex A — Turnkey Baseline Mapping (normative)

| Element | Turnkey asset | Status | Gap |
|---------|--------------|--------|-----|
| Runtime & grading | quiz/lab, `grading_service`, feedback service | ✅ | — |
| Bloom targeting & audit | `bloom_quiz_service`, `QuizBloomDistribution` | ✅ | — |
| Ingestion | xAPI + Caliper | ✅ | single-path consolidation 🔵 (STX-03/08) |
| Alignment chain | `OutcomeAssessmentAlignment`, `CLOCompetency` | ✅ | — |
| Evidence service | constitution §11 design | 🔵 STX-08 | trust calibration ⚪ |
| Final exam plan | `CourseFinalExamination` + `ExamLearningObjective` (FEX) | ✅ | feeds summative declaration 🔵 |
| AssessmentSession (G2) | — | ⚪ | aggregate + calendars + refusal flow; ESSE3 mirror via BOOK-18 |
| Thesis (G5) | `plagiarism_service` ✅; rest — | ⚪ | aggregate + workflow + deposit |
| Committee (G6) | `FacultyAssignment` roles substrate | ⚪ | aggregate + acts |
| Viva dossiers | Assessment Agent (STX-11) | 🔵 | dossier schema + sampling policy |
| Item analytics | attempt data ✅ | ⚪ | IRT-lite job + fairness slicing |
| Integrity | plagiarism ✅, ContentVariant ✅ | 🟡 | due-process workflow + detector-humility policy ⚪ |

---

# Glossary additions

| Term | Definition |
|------|-----------|
| Two products | Mastery signal (fast) + evidence (durable) per interaction |
| AssessmentSession | The appello aggregate (Ch. 5), native or mirror mode |
| Grade refusal | Learner declining a passing result; mastery stands, official evidence deferred |
| Viva dossier | AI-prepared examination brief targeting weakest evidence links |
| Triangulation rule | ≥2 evidence types incl. ≥1 high-class for credential-bearing claims |
| Detector humility | AI-text detectors as review triggers only, never sole misconduct evidence |
| Process evidence | Versioned work history as integrity-by-workflow |
| Due process | Contest → human review → lineage-preserving outcome |

---

*BOOK-15 v1.0 — awaiting review. G-register: G2/G5/G6 closed here. Next:
BOOK-16 (Credential & Trust Architecture — owner of G3 and consumer of
everything this Book certifies).*
