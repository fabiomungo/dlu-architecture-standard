# Sprint STX-11 — Assessment Agent + WS06 Examination & Mastery
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-05 (sessions), STX-08 (evidence timeline), K2 (gate)

## Role
`backend-dev` + `frontend-dev` (DAS BOOK-10 Ch. 3 card; BOOK-15
Ch. 6/10/11; BOOK-14 readiness prediction; BOOK-17 WS06).

## Context — read before coding
1. BOOK-10 Ch. 3 card, binding: **Assessment Agent** — moves
   `generate_formative`, `give_feedback`, `check_retrieval`; reads
   L3/L4; Bloom-targeted item generation, rubric-based feedback
   drafting, viva dossier preparation; autonomy: **act for formative,
   propose for anything summative** (drafts for faculty — BOOK-01
   Ch. 8); **never the sole grader**.
2. BOOK-15 Ch. 10 — the AI-roles boundary table is the spec: item
   generation (act formative / propose summative), feedback drafting
   (act formative feeds-forward / summative faculty-signed), viva
   dossier prep (propose — examiner owns the exam), grading assistance
   (propose, rubric-anchored, human sign-off), item calibration (act —
   analytics), readiness prediction (act — advisory, honest probability
   rendering per BOOK-14 Ch. 8.4).
3. BOOK-15 Ch. 6 (viva dossier, R5 deliberation): compiled from the
   evidence graph — claims to verify, evidence summary, probe questions
   targeting the **weakest links** (low-confidence competencies,
   single-source claims — STX-08's triangulation bookkeeping is the
   input), suggested Bloom escalation; fully traced; the verdict is the
   examiner's alone.
4. Existing (repo-verified): `bloom_quiz_service.py` +
   `QuizBloomDistribution` (Bloom targeting — reuse, don't rewrite);
   `grading_service.py`, `quiz_feedback_service.py`, `qti_serializer.py`;
   quiz/lab runtime + attempt tables (`quiz_attempts`,
   `student_exam_attempts`); rubric models
   (`backend/domains/assessment/models.py`); NEW-05's
   `assessment_sessions` + WS06 calendar half; STX-08's
   `GET /api/assessment/me/evidence`; `AGENT_ENTITLEMENTS` already
   reserves `assessment → {L3,L4}` (reuse the exact key); new-agent
   lock-step rule (seed row + entitlements + bindings); NEW-02 harness
   incl. grading-assistance bias checks (BOOK-11 scenario class);
   NEW-02/NEW-03 calibration machinery (`CalibrationBaseline`,
   `ProceduralCalibrationState`, ctx_hash rollup).
5. **K2 debt intake (README):** calibration seeding covers
   `recommend_next` only, and outcome tracking (predicted vs eventual
   result — BOOK-09 Ch. 7) is open. Readiness prediction is the first
   predictive move with **measurable ground truth** (the exam result
   arrives): this sprint closes the loop.
6. BOOK-15 Ch. 11: accommodations flow from L1 automatically and
   privately; item fairness = differential performance across cohorts at
   item level (n≥10 suppression), flagged to review.

## Deliverables
1. **Assessment Agent**: seed row (`assessment`, `testing`), bindings
   per card; `generate_formative` (act) through `bloom_quiz_service`
   targeting the outcome's Bloom level; formative feedback (act,
   feeds-forward form); **summative tier structurally propose**: item
   drafts, grading assistance (rubric-anchored score + rationale drafts)
   and summative feedback all land in the faculty HITL queue — no code
   path applies them without sign-off.
2. **Viva dossier preparation** (R5, propose): dossier schema — claims,
   evidence summary (STX-08 timeline), weakest-link probe questions
   (lowest-confidence + single-source first), Bloom escalation
   suggestions; intermediate deliberation steps logged in the trace;
   queued for the examiner (FW3 consumes in K4 — expose the API now).
3. **Readiness prediction + calibration loop**: per (learner, session)
   readiness = calibrated probability from L4 mastery + attempt history;
   rendered only with hedging bands + assumptions; powers SIT_EXAM
   targeting ("target the June session") through NEW-05/NEW-04's edges;
   seed `CalibrationBaseline` rows for the predictive move and — new —
   **outcome tracking**: when the session result lands, record predicted
   vs observed into the M4 calibration state (closing the BOOK-09 Ch. 7
   loop for the first time).
4. **Item calibration analytics (IRT-lite, act)**: difficulty +
   discrimination from attempt data; bad items flagged to authors (QA
   surface hook); item-fairness slicing across cohorts (n≥10
   suppression) with flagged items routed to review — analytics job
   (Celery), no learner-facing effect.
5. **WS06 completion (Assess)**: full triad on NEW-05's calendar half —
   Canvas: sessions calendar, readiness predictions (hedged), attempts,
   evidence timeline (STX-08); Companion: Assessment bias (extend
   `WORKSPACE_AGENT_BIAS`); Missions: enroll in session, sit, review
   feedback, (refuse & retake where allowed). Accommodations applied
   privately end-to-end.
6. **NEW-02 coverage + gate**: scenario classes incl. grading-assistance
   bias checks and an integrity-pressure scenario ("just grade it for
   me" on summative ⇒ propose tier holds); green + steward-signed before
   any `deployed` transition.

## Verifications
- **V1** summative boundary: no execution path applies a summative
  grade/item/feedback without a human act (negative tests on the API and
  the mission path; the propose queue is the only outlet).
- **V2** calibration loop closes: prediction stored → fixture session
  result lands → observed outcome recorded against the prediction → M4
  state's `mean_observed_outcome` moves (first real outcome tracking).
- **V3** viva dossier targets weakest links: fixture evidence graph ⇒
  probe questions ordered by lowest confidence / single-source first;
  dossier is propose-tier and fully traced.
- **V4** IRT-lite flags a seeded bad item (discrimination below floor);
  fairness slicing suppresses cells with n<10 (negative test).
- **V5** readiness rendering: bands + assumptions mandatory in the
  payload (contract test); no point estimate reaches the UI.
- **V6** harness green incl. bias + integrity-pressure scenarios (gate) ·
  accommodations private (no disclosure in any list payload) ·
  `pytest -m phase1` + existing quiz/grading routes green · migration
  (if any) up/down/up clean.

## DoD
V1–V6 green · BOOK-15 Annex (viva dossiers, item analytics) + BOOK-10
nine-agents row updated · constitution §15 WS06 marked implemented ·
TRACEABILITY K3 row updated · K2 debt items (calibration beyond
`recommend_next`, outcome tracking) marked retired in the K3 exit
report · decisions note (readiness model v1, IRT-lite thresholds are
policy knobs).
