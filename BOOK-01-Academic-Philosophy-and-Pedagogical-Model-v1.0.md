# BOOK-01 — Academic Philosophy & Pedagogical Model
## DLU Architecture Standard (DAS)
### Version 1.0 — DRAFT for review

> The pedagogical layer of the DAS cascade. This Book answers *how humans learn in
> DLU and why the architecture is shaped the way it is*. Every engine specification
> in later Books MUST trace its behaviour to a principle established here.
>
> **Conforms to:** BOOK-00 v2.0 (DAS). **Depends on:** BOOK-00.
> **Informs:** all Books; binding for BOOK-06 (Twin), BOOK-09 (ACE), BOOK-14 (GPS),
> BOOK-15 (Assessment), BOOK-17 (Experiences).
> **Primary audience:** academic leaders, instructional designers, AI architects.

**Normative language:** RFC 2119 (MUST/SHOULD/MAY). Statements citing research are
informative; their consequences are normative.

**Source-of-content rule compliance:** this Book systematizes pedagogical mechanisms
already running in DLU Builder Turnkey — the ILO→PLO→CLO→MLO outcome hierarchy,
Bloom-revised tagging, I/R/M curriculum alignment, BKT mastery tracking, SM-2 spaced
repetition, the Pedagogical Coach — and extends them where the standard requires.
Annex A maps every principle to its Turnkey mechanism and status.

---

# Chapter 1 — Purpose and Position in the Cascade

The DAS cascade (BOOK-00 Ch. 8) begins:

```text
Academic Philosophy → Pedagogical Model → Business Architecture → …
```

This Book occupies the first two steps. Its function is protective: **technology
never defines pedagogy** means, concretely, that when an engineering decision and a
pedagogical principle conflict, this Book wins, and the conflict is resolved by RFC —
never by silent code.

Three claims organize the Book:

1. Learning is a **trajectory of transformation** (the CAT model, Ch. 3), not an
   accumulation of exposure.
2. The trajectory is steered by **evidence about a learner model** that the learner
   can see and contest (Ch. 6).
3. Instruction is effective only when **outcomes, activities and evidence are
   aligned by design** (constructive alignment, Ch. 5) and when practice respects
   how memory actually works (Ch. 4).

---

# Chapter 2 — The Learner as the Unit of Analysis

Traditional academic IT models the *offering* (courses, sections, terms) and treats
the learner as an enrollment record. DLU inverts this: the persistent object is the
**learner in transformation**; offerings are consumable, replaceable means.

Consequences (normative):

- Every pedagogical event MUST be interpretable as evidence about a learner state
  (knowledge, competency, behaviour), not merely as an activity log entry.
- Academic structures (courses, terms) MAY change without loss of learner state:
  the Twin (BOOK-06) survives any reorganization of the catalog.
- The learner's goals are inputs to instruction, not afterthoughts: the GPS
  (BOOK-14) plans against the Career layer, and the plan is revisited as goals change.

The epistemic triangle of BOOK-00 Ch. 4.2 (knowledge / competency / evidence) is
assumed throughout and not restated.

---

# Chapter 3 — The CAT Model, In Depth

The Continuous Academic Transformation model defines eight stages. BOOK-00
established its grounding (Dreyfus, mastery learning, SOLO, learning-by-teaching);
this chapter makes each stage **operational**: entry/exit criteria, admissible
evidence, dominant activities, and which AI agents and humans act.

## 3.1 Stage specifications

Conventions: `P(L)` is BKT mastery probability of the underlying concepts
(Turnkey: `concept_mastery.p_mastery`, mastered at ≥ 0.95); *confidence* is the
evidence-weighted competency confidence (0..1, `student_competencies.confidence`);
Bloom levels use the 2001 revision as implemented in `BloomTaxonomyLevel`.

| # | Stage | Entry criterion | Dominant activity | Admissible exit evidence | Exit criterion | Primary actors |
|---|-------|-----------------|-------------------|--------------------------|----------------|----------------|
| 1 | **Unknown** | default state | — | — | goal or curriculum places the competency in scope | GPS, Discovery Agent |
| 2 | **Aware** | competency targeted (status `targeted`) | orientation content; why-it-matters framing | self-assessment; diagnostic pre-test | diagnostic completed; learning plan exists | Discovery Agent, Navigator |
| 3 | **Learning** | plan adopted | instruction at Bloom *remember/understand*; worked examples | formative checks (low trust weight) | P(L) rising; formative accuracy ≥ threshold on foundational concepts | Subject Tutor, content |
| 4 | **Practicing** | foundational P(L) established | retrieval practice, *apply/analyze* tasks, labs; spaced review | quiz/lab attempts (BKT events); project checkpoints | P(L) ≥ 0.95 on core concepts; confidence ≥ 0.5 (`evidenced`) | Assessment Agent, Coach |
| 5 | **Competent** | `evidenced` | independent task performance; interleaved mixed practice | proctored/authentic assessment; project with process evidence | confidence ≥ 0.8 (`mastered`) | Assessment Agent + human examiner |
| 6 | **Mastered** | `mastered` | transfer tasks (*evaluate*); dialogic verification for high stakes | oral defense; triangulated evidence | human verification → status `verified` | Human examiner (HITL — never automatic) |
| 7 | **Teaching** | `verified` (or `mastered` + faculty consent) | peer tutoring, content review, mentoring (protégé effect) | teaching artifacts; mentee outcomes; faculty observation | sustained teaching evidence | Learner + faculty; Coach monitors |
| 8 | **Innovating** | Teaching sustained | creation (*create*): research, novel artifacts, contributions to the knowledge network | peer/faculty review; external validation | ongoing — this stage does not close | Learner, faculty, community |

Normative rules:

1. Stage transitions MUST be evidence-driven; time-in-stage MUST NOT be a criterion.
2. Regression is legal and expected: decayed confidence (recency decay, BOOK-06)
   moves a learner from *Competent* back to *Practicing*. The UI MUST frame
   regression as scheduled maintenance, never as failure.
3. Stages 6→7 and beyond REQUIRE human judgment. No agent may certify `verified`,
   appoint a peer teacher, or validate innovation (BOOK-00 ADR-0012, HITL tiers).
4. A learner is at different CAT stages for different competencies simultaneously;
   the stage is a property of the (learner, competency) pair, never of the learner.

## 3.2 CAT ↔ established taxonomies

| CAT | Dreyfus | Bloom (revised) emphasis | SOLO depth | Turnkey alignment strength |
|-----|---------|--------------------------|------------|---------------------------|
| Aware | Novice | remember | unistructural | `introduced` |
| Learning | Advanced beginner | remember/understand | multistructural | `introduced` |
| Practicing | Competent | apply/analyze | relational | `reinforced` |
| Competent | Proficient | analyze/evaluate | relational | `mastered` |
| Mastered | Expert | evaluate | extended abstract | `mastered` |
| Teaching / Innovating | (beyond Dreyfus) | create | extended abstract | — |

The mapping to the existing `AlignmentStrength` enum (`introduced` / `reinforced` /
`mastered`) is deliberate: the curriculum I/R/M map already in Turnkey doubles as
the **designed CAT trajectory** of each program. Coverage gaps in the
`OutcomeCoverageMatrix` are therefore pedagogical defects, not reporting artifacts.

---

# Chapter 4 — Learning Science Foundations

Ten principles. Format: *statement → evidence base (informative) → normative
consequence → Turnkey mechanism (see Annex A)*.

## P1 — Mastery before progression

Learning quality collapses when learners advance with unresolved prerequisite gaps.
*(Bloom 1968/1984; Corbett & Anderson BKT.)*

- The kernel MUST model per-concept mastery probabilistically and gate
  prerequisite-dependent recommendations on it.
- Progression gates use P(L) ≥ 0.95 (Turnkey `MASTERY_THRESHOLD`) for concepts and
  confidence thresholds for competencies; institutions MAY tighten, MUST NOT loosen
  below P(L) ≥ 0.85 without an RFC.

## P2 — Retrieval practice over re-exposure

Testing is a learning event, not only a measurement event; retrieval strengthens
retention far more than re-reading. *(Roediger & Karpicke 2006.)*

- Every content unit SHOULD embed low-stakes retrieval checks.
- Formative attempts MUST feed the learner model (BKT events) — assessment *for*
  learning and assessment *of* learning share one pipeline (BOOK-15).

## P3 — Spacing and scheduled forgetting

Distributed practice beats massed practice; review timing should track the
forgetting curve. *(Ebbinghaus; Cepeda et al. 2006.)*

- The kernel MUST maintain per-concept review schedules. Turnkey implements SM-2
  (EF ∈ [1.3, 2.5], intervals 1 → 6 → round(prev × EF), reset on quality < 3);
  the algorithm is replaceable (FSRS candidate) behind a stable scheduling contract.
- Review missions MUST be first-class recommendations, competing on equal terms
  with new content — the Coach protects review time against novelty pressure.

## P4 — Desirable difficulty

Conditions that slow apparent progress (spacing, interleaving, generation) improve
durable learning; friction is not UX failure. *(Bjork.)*

- Optimization loops MUST NOT use short-term completion speed or satisfaction as
  their sole target (BOOK-00 Principle 10; guardrail metrics Ch. 10 here).
- The Tutor MUST prefer eliciting an answer (Socratic move) over providing one when
  the learner model predicts a productive struggle zone; give-up thresholds are
  configurable per course.

## P5 — Cognitive load management

Working memory is narrow; instruction fails by overload (intrinsic vs extraneous
load) as often as by absence. *(Sweller; Mayer's multimedia principles.)*

- AI-generated content MUST respect segmenting (short units), coherence (no
  decorative media), modality and signalling principles. These bind the 9-type
  media enrichment pipeline: media variety serves load management, not spectacle.
- Prerequisite-dense content MUST be decomposed along the knowledge graph, not
  delivered as monoliths (Knowledge Engine, BOOK-13).

## P6 — Feedback that feeds forward

Feedback works when timely, specific, task-focused, and actionable; grades alone
are weak feedback. *(Hattie & Timperley 2007.)*

- Every formative attempt MUST return explanation-bearing feedback (Turnkey quiz
  feedback service), not only correctness.
- Feedback SHOULD reference the learner's model state ("this closes the gap on X")
  — connecting evidence to trajectory is what makes the open learner model useful.

## P7 — Motivation: autonomy, competence, relatedness

Sustained learning requires self-determination: perceived autonomy, growing
competence, social belonging. *(Deci & Ryan.)*

- Learners MUST retain choice among GPS scenarios (autonomy); progress views MUST
  emphasize growth against self (competence); cohort and peer structures are
  kernel objects, not optional plugins (relatedness — BOOK-00 Ch. 5.2).
- Gamification MAY be used only where it does not displace intrinsic motivation;
  streak mechanics MUST NOT penalize scheduled rest.

## P8 — Metacognition and the open learner model

Learners who see and reason about their own model calibrate better and persist
longer. *(Bull & Kay, open learner modeling.)*

- The Twin's Knowledge and Competency layers MUST be visible to the learner in
  inspectable form (WS03 Personal Knowledge Map is the constitutional view).
- The learner MUST be able to contest a model state; contests create evidence
  review tasks (HITL) and are themselves metacognitive interventions.

## P9 — Social learning and learning-by-teaching

Explaining to others is among the strongest consolidation activities; community
predicts persistence. *(Protégé effect; Lave & Wenger; Tinto.)*

- CAT stages 7–8 MUST be reachable by design: peer-tutoring roles, content review
  duties and mentoring are schedulable Learning Missions, not informal extras.
- Peer evidence carries its own trust weight (lower than faculty observation,
  higher than self-report) in the evidence model (BOOK-15).

## P10 — Constructive alignment (expanded in Ch. 5)

Learning outcomes, teaching activities and assessment must be designed as one
system. *(Biggs & Tang.)*

- No content without a declared outcome; no outcome without a planned assessment;
  no assessment without admissible evidence mapping. Authoring tools MUST enforce
  this ordering (outcome-first authoring).

---

# Chapter 5 — Constructive Alignment and the Outcome Model

## 5.1 The outcome hierarchy (running today)

Turnkey already implements the full five-level hierarchy — this standard adopts it
unchanged as the **normative outcome spine**:

```text
ILO (institutional)
 └── PLO (program)          ← PLOtoILO alignments
      └── CLO (course)      ← CLOtoPLO alignments
           └── MLO (module) ← MLOtoCLO alignments
                └── Lesson outcomes
```

Each outcome carries a Bloom (revised) level; verbs are validated against the
`BloomVerbMapping` dictionary (authoring-time linting: an outcome that says
*"understand X"* but is assessed at *apply* level is a defect the Pedagogical Coach
must flag).

## 5.2 Alignment rules (normative)

1. Every CLO MUST align to ≥ 1 PLO; unaligned CLOs are quality defects surfaced in
   the coverage matrix.
2. Every summative assessment MUST declare `OutcomeAssessmentAlignment` rows; an
   assessment aligned to nothing yields **no evidence** (Turnkey already treats
   unmapped assessments as mastery-only signals — BOOK-15 formalizes this).
3. The I/R/M (`introduced`/`reinforced`/`mastered`) designation across a program
   MUST form a coherent trajectory per PLO: at least one `introduced`, one
   `reinforced` and one `mastered` touchpoint, in that partial order. The
   `OutcomeCoverageMatrix` is the audit artifact.
4. Competency linkage: CLOs map to competencies via `CLOCompetency`; this is the
   bridge from curriculum to the Competency Engine and MUST be maintained when
   either side changes.
5. Bloom distribution: summative assessment sets SHOULD match the Bloom profile of
   their outcomes (the Bloom quiz service computes distributions; the Pedagogical
   Coach recommends corrections — e.g., "increase higher-order thinking").

## 5.3 Outcome-first authoring (binding on the Learning Engine)

The authoring sequence is: declare outcomes → declare assessment plan → generate/
curate content → validate alignment (Coach) → publish. AI course generation MUST
receive outcomes as input constraints, never invent them post hoc.

---

# Chapter 6 — The Learner Model

## 6.1 Two coupled state systems

| State | Question | Representation | Update mechanism |
|-------|----------|----------------|------------------|
| Knowledge state | What does the learner know? | per-concept P(L) via BKT: P(L), P(T), P(G), P(S); mastered at ≥ 0.95 | every scored interaction (quiz answer, lab completion) — Turnkey `mastery_tracking_service` |
| Competency state | What can the learner do? | per-competency status (`targeted → … → verified`) + confidence 0..1 | evidence records: confidence = Σ(score × weight × recency × source_trust)/Σweight |

Knowledge state is fast-moving and forgiving (probabilistic, self-correcting);
competency state is slow-moving and conservative (evidence-weighted, human-gated at
the top). **Both MUST decay**: knowledge via the review scheduler (P3), competency
via recency decay (default 180-day half-life, framework-configurable).

## 6.2 Model integrity rules

1. Parameters (P(G), P(S), decay λ, trust weights) are institution-configurable but
   MUST be versioned; a parameter change is a governed model change (BOOK-00 Ch. 11).
2. The model MUST be **calibrated**: predicted performance is periodically compared
   with observed performance; systematic miscalibration triggers review.
3. Cold start: diagnostics and the Discovery/Recognition agents seed the model;
   seeded states carry low trust weights until corroborated.
4. The model is **open** (P8): every displayed state MUST be explainable in learner
   terms ("mastered because: 12 correct retrievals over 6 weeks, verified lab").

## 6.3 What the model is not

The learner model is not a judgment of the person. It MUST NOT be used for
admission scoring, pricing, or any purpose outside learning guidance without
explicit consent and governance review (AI Act posture, BOOK-00 Ch. 12) — and
MUST NOT encode protected attributes as features.

---

# Chapter 7 — Personalization Doctrine

**Personalize the path, not the truth** (BOOK-00 Principle 6). Five admissible
adaptivity dimensions:

| Dimension | Adaptable | Bounded by |
|-----------|-----------|-----------|
| Pace | fully | program deadlines, term structure where applicable |
| Sequence | within prerequisite constraints (KG `REQUIRES`) | curriculum core (canon is shared) |
| Modality | media type per learner preference/effectiveness | cognitive-load principles (P5), accessibility |
| Difficulty | task selection in the productive-struggle zone | desirable difficulty (P4) — never minimize effort |
| Support | tutoring intensity, scaffolding, hints | scaffolding fade rule: support MUST decrease as P(L) grows |

Guardrails (normative):

1. **Serendipity quota:** recommendation slates MUST reserve a configurable share
   (default 15%) for items outside the learner's inferred preference profile —
   filter-bubble countermeasure (BOOK-00 risk register).
2. **Core canon:** programs declare a non-personalizable core; the GPS routes
   around *when* and *how*, never *whether*.
3. **Consent degradation:** with `ai_personalization = false`, the experience
   degrades to curriculum-ordered, cohort-paced delivery with full functionality —
   personalization is a consented enhancement, not a dependency.
4. **No dark patterns:** adaptivity MUST NOT optimize for time-on-platform;
   the wellbeing guardrail metrics (Ch. 10) bind every loop.

---

# Chapter 8 — Assessment Philosophy (bridge to BOOK-15)

Assessment in DLU follows **evidence-centered design**: define the claim
(outcome/competency), define what behaviour would evidence it, then design the task
— never the reverse.

- **Formative and summative share one pipeline** but differ in trust weight and
  stakes; formative is abundant, cheap and low-stakes by design (P2).
- **Integrity is layered**, per BOOK-00 Ch. 12.2: authentic tasks with process
  evidence → dialogic verification (AI-prepared, human-examined vivas) for high
  stakes → trust-weighted triangulation. Surveillance proctoring is last resort.
- **AI's role**: generation of assessment items (Bloom-targeted), first-pass
  feedback, viva preparation dossiers. AI MUST NOT be the sole grader of any
  summative, credential-bearing assessment (HITL tier: propose).
- **Bloom coverage**: assessment sets are audited against outcome Bloom profiles
  (existing Coach capability, now normative).

---

# Chapter 9 — Human Pedagogical Roles and Delegation

Extends BOOK-00 Ch. 5. Each human role owns decisions that MUST NOT be delegated;
each agent operates inside an envelope the role defines:

| Human role | Reserved decisions | Delegates to agents |
|-----------|--------------------|--------------------|
| Instructor / faculty | outcome definitions, summative grading authority, content approval, viva examination | Tutor (routine explanation), Assessment Agent (formative generation, feedback drafts) |
| Program director | curriculum core, I/R/M map, progression policy | Coach analytics, Coverage audits |
| Advisor | intervention decisions on at-risk learners | Success Agent (detection, proposal), Navigator (scenario preparation) |
| Registrar | credit recognition, credential issuance beyond auto-badges | Recognition Agent (dossier preparation) |
| Mentor (incl. peer, CAT-7) | relationship, judgment calls | Coach (scheduling, prompts) |

Delegation envelopes are formalized per-faculty in the Faculty Twin (BOOK-07);
agent contracts in BOOK-10. The invariant: **agents multiply human pedagogical
attention; they never substitute accountable judgment** (ADR-0005).

---

# Chapter 10 — Pedagogical Metrics and Falsifiability

Refines BOOK-00 Ch. 14 for the pedagogy domain. Every adaptive loop declares one
target metric and its guardrails:

| Metric | Definition | Type |
|--------|-----------|------|
| Learning gain | Δ model state per unit of study time, corrected for guess/slip | target |
| Durability | retention at spaced re-assessment (SM-2 outcomes at interval ≥ 30d) | target |
| Transfer | performance on tasks structurally different from practice | target (gold standard) |
| Calibration | |predicted − observed| performance | health |
| Struggle productivity | share of struggle episodes ending in unaided success | health |
| Review debt | overdue reviews per learner | guardrail |
| Wellbeing | session-length distribution tails, deadline-panic patterns | guardrail |
| Equity | disparate impact of all above across cohorts | guardrail (blocking) |

**Anti-Goodhart rule:** no single metric may drive an optimization loop; equity
guardrails are blocking (a personalization change that improves the mean but widens
cohort gaps MUST NOT ship).

---

# Chapter 11 — Pedagogical Pattern Catalog (normative patterns)

Reusable, kernel-supported instructional patterns. Each pattern names its
principles and the kernel objects that realize it. Experiences (BOOK-17) compose
patterns; they do not invent ad-hoc flows.

| Pattern | Flow | Principles | Kernel objects |
|---------|------|-----------|----------------|
| **Mastery loop** | instruct → retrieve → feedback → model update → branch (advance/remediate) | P1, P2, P6 | Learning Mission, BKT event, recommendation |
| **Spaced review mission** | scheduler surfaces due concepts → retrieval set → SM-2 update | P2, P3 | review schedule, quiz runtime |
| **Socratic tutoring session** | learner question → tutor elicits → hints escalate → resolution logged as evidence | P4, P6 | Tutor agent turn, xAPI statement, AI memory |
| **Productive-struggle task** | task selected slightly above P(L) → scaffold on demand → fade | P4, P5 | difficulty selector, scaffolding policy |
| **Project studio** | brief → checkpoints with process evidence → peer review → faculty verification | P9, P10, Ch. 8 | Learning Mission, EvidenceRecord chain, HITL |
| **Dialogic verification (viva)** | AI dossier from evidence graph → human oral exam → `verified` status | Ch. 8, ADR-0012 | viva dossier, verification record |
| **Learning-by-teaching** | mastered learner assigned mentee/review duty → teaching artifacts → CAT-7 evidence | P9 | peer-tutoring mission, peer evidence |
| **Diagnostic onboarding** | Discovery dialogue + adaptive pre-test → seeded model → first plan | Ch. 6.2, P7 | Discovery agent, diagnostic assessment, GPS |

---

# Annex A — Turnkey Baseline Mapping (normative)

Status legend as in BOOK-00 Annex A.

| Principle / mechanism | Turnkey asset | Status | Gap |
|-----------------------|--------------|--------|-----|
| Outcome hierarchy (Ch. 5.1) | `models_institution.py` (ILO/PLO/CLO/MLO + alignments), `models_learning_outcomes.py` (lesson outcomes, `OutcomeLevel`) | ✅ | — |
| Outcome-first authoring instrument (Ch. 5.3) | **DLU Course Builder** wizard + Course Exchange Format v1.3 (`*.dlu.json`): 9-step guided flow, CLOs (3–8, Bloom-levelled with verb guidance) elicited at step 2 before any content; per-MLO assessment_method; constraint checklist; bilingual IT/EN | ✅ | full assessment plan arrives at step 7 (after content) — Builder v1.4 SHOULD surface it alongside CLOs (BOOK-05 Ch. 4.4 gap 2); competency alignment not yet authorable ⚪ |
| Bloom tagging & verbs | `BloomTaxonomyLevel` (2001 revision), `BloomVerbMapping`, `bloom_quiz_service` | ✅ | verb linting at authoring time SHOULD become blocking |
| I/R/M trajectory audit | `AlignmentStrength`, `OutcomeCoverageMatrix`, `outcome_alignment_service` | ✅ | CAT-trajectory coherence check (Ch. 5.2 rule 3) 🔵 |
| Bloom distribution audit | Pedagogical Coach (`pedagogical_coach_service`, reports, recommendations) | ✅ | — |
| BKT mastery (P1) | `concept_mastery` (P(L),P(T),P(G),P(S)), `mastery_tracking_service`, `MASTERY_THRESHOLD = 0.95` | ✅ | parameter versioning & calibration monitoring (Ch. 6.2) ⚪ |
| Spaced repetition (P3) | `spaced_repetition_service` — SM-2, EF∈[1.3,2.5], intervals 1/6/EF-scaled | ✅ | **STX-09 (2026-07-21): due reviews are now a real stage-1 candidate source** in `recommendation_service_v2.py` (`asyncio.to_thread`-offloaded, sync-only service), competing on the same deterministic ranking as every other candidate — no privileged lane |
| Feedback (P6) | quiz feedback service (FR-241) | ✅ | model-state-referencing feedback 🔵 |
| Formative→evidence pipeline (P2, Ch. 8) | xAPI/Caliper ingestion, grading | 🟡 | assessment→CLO→competency evidence chain 🔵 (STX-08, BOOK-15) |
| Competency confidence (Ch. 6.1) | `Competency`, `CLOCompetency` | 🟡 | `StudentCompetency` + confidence algorithm 🔵 (STX-04) |
| Open learner model (P8) | `KnowledgeMastery`, `MasteryDashboard` components | 🟡 | **contestability flow ✅ STX-09 (2026-07-21):** `POST /api/competencies/{id}/contest` files a `move_proposal_service` HITL item, never edits `StudentCompetency` directly (BOOK-06 Ch. 8.3); **WS03 knowledge map ✅ STX-09:** `KnowledgeMapWorkspace.js` — a lighter, twin-level custom view, not yet reusing `KnowledgeMastery`/`MasteryDashboard` (those are course+legacy-student_id-scoped; reusing them would reintroduce the exact legacy-id bridging this sprint avoided — a documented follow-up, not an oversight) |
| Personalization guardrails (Ch. 7) | rule-based recommendation engine, `PersonalizationContext` | ✅ **STX-09 (2026-07-21)** | serendipity quota (deterministic per twin+day, sha256-keyed — never `random`, which would break the idempotency invariant) and consent degradation (collapses to rule-stage-only, course-scoped) both real in `recommendation_service_v2.py`; weight defaults (w1-w4) and the 15% quota are documented v1 policy knobs |
| Socratic tutoring (P4) | `learner_tutor_service`, GraphRAG grounding | 🟡 | struggle-zone policy & scaffolding fade ⚪ (BOOK-09/11) |
| Social learning (P9) | cohorts, forums, pacing/cohort services | 🟡 | peer-tutoring missions & peer evidence weights ⚪ (BOOK-15/17) |
| Dialogic verification (Ch. 8) | — | ⚪ | viva dossier + verification record (BOOK-15) |
| Pedagogical metrics (Ch. 10) | analytics dashboards, xAPI | 🟡 | learning gain / durability / calibration instrumentation ⚪ (BOOK-20 KPI work) |

---

# Glossary additions (extend BOOK-00 glossary)

| Term | Definition |
|------|-----------|
| CAT stage | Property of a (learner, competency) pair, per Ch. 3.1 table |
| I/R/M map | The introduced/reinforced/mastered curriculum trajectory per outcome |
| Open learner model | Learner-visible, contestable rendering of Twin knowledge/competency layers |
| Productive-struggle zone | Task difficulty band slightly above current P(L) with scaffolding available |
| Review debt | Count of overdue spaced-repetition reviews for a learner |
| Serendipity quota | Reserved share of recommendations outside the inferred preference profile |
| Outcome-first authoring | Binding sequence: outcomes → assessment plan → content → alignment validation |

# Bibliography (additions to BOOK-00)

Bloom, *Learning for Mastery* (1968) and *The 2 Sigma Problem* (1984) · Corbett &
Anderson, *Knowledge Tracing* (1995) · Roediger & Karpicke (2006) · Cepeda et al.
(2006) · Bjork, *Desirable Difficulties* · Sweller, *Cognitive Load Theory* ·
Mayer, *Multimedia Learning* · Hattie & Timperley, *The Power of Feedback* (2007) ·
Deci & Ryan, *Self-Determination Theory* · Bull & Kay, *Open Learner Models* ·
Biggs & Tang, *Teaching for Quality Learning at University* · SOLO Taxonomy ·
Dreyfus & Dreyfus (1986) · Ericsson, *Deliberate Practice* · Lave & Wenger (1991) ·
Tinto, *Leaving College* · Mislevy, *Evidence-Centered Design* · SuperMemo SM-2.

---

*BOOK-01 v1.0 — awaiting review. Next per dependency order: BOOK-02 (AI-Native
University Theory) and BOOK-03 (Academic Operating System).*
