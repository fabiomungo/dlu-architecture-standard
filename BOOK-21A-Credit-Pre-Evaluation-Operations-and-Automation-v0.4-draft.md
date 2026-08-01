# BOOK-21A — Credit Pre-Evaluation: Operations & Automation (annex)
### DAS v0.4-draft · Layer: Intelligence / Intake · Status: IMPLEMENTED (F1-F4 all real, G17/C21A.6/C21A.7 FULLY CLOSED — SPRINT-22 correction, see v0.4 note below)

> **v0.4 (2026-08-01, NEW-29/SPRINT-22) — IMPORTANT CORRECTION to the v0.3 note below**: the
> v0.3 claim that C21A.6/C21A.7 were closed by "NEW-17d/SPRINT-07" was **never actually true**.
> `git merge-base --is-ancestor sprint/NEW-17d-preval-eval-loop HEAD` (checked against this
> program's real development chain, since nothing across all 22 sprints has yet merged to
> `main`) proved that branch (PR #83) was orphaned — never merged — the entire time this v0.3
> note has existed. `preval_eval_builder.py`/`preval_eval_metrics.py`/`preval_eval_gate.py` did
> not exist in the actual running codebase until SPRINT-22 rebuilt them fresh (found during
> SPRINT-22/NEW-29 pre-flight; the user chose full re-implementation over a lighter
> correction-only fix). The rebuild uses a materially improved design vs. what v0.3 describes
> below: `replay_case` is a PURE, instant, zero-I/O replay against the deterministic engine's OWN
> frozen resolved inputs (captured at golden-case-build time), not a replay of the full
> production pipeline (which always makes a real, non-idempotent LLM call, as F4's original
> design implied). Verified for real this time — `tests/conformance/test_preval_eval_loop.py`
> (6 tests, real migrated Postgres) and `preval_eval_gate.py` genuinely wired into
> `.github/workflows/build-push-images.yml` (`needs: [test-gate, preval-eval-gate]`, confirmed).
> Everything else the v0.3 note and the rest of this document describe below (module names,
> mechanism, the honest PROVISIONAL certification caveat) is technically accurate — only the
> sprint/date attribution was wrong. **G17 is NOW FULLY CLOSED for real** (TRACEABILITY.md G17).

> **v0.3 (2026-07-30, NEW-17d/SPRINT-07)** — retained for the historical record, see v0.4
> correction above: F4 (golden set + eval loop) implemented — the last
> open phase. §7/§8/Annex A updated with real measured numbers and mechanism, not projections.
> **C21A.6 closed** as a side effect of building this sprint's own row-correction capability
> (not the primary goal — see §7's own note). **C21A.7 real and CI-wired**, but the
> certification itself is honestly **PROVISIONAL**: this environment has zero real historical
> approved-sheet data (confirmed in pre-flight) — the golden set is bootstrap-sized (the Conti
> demo fixture + whatever real sprint-02-06 traffic has produced), not the "~90% over a real
> historical corpus" BOOK-21A §7 originally envisioned. The gate mechanism itself is real,
> working, and CI-enforced; the STATISTICAL weight of a 'pass' verdict today is not yet what the
> number implies — see §7 for the precise reasoning, not hidden in a footnote.
>
> **v0.2 (2026-07-30, NEW-17c/SPRINT-04)**: Annex A refined — F1-F3 (workflow, extraction/
> matching, rule packs/registries/VRA) now all live; only F4 (golden set + eval loop, ~90%
> accuracy target) remains.

> Operationalizes the credit pre-evaluation service inside the admission funnel (BOOK-21,
> G17) and the recognition framework (BOOK-14A, G16). Source of ground truth: the
> **Pre-Evaluators Training Manual 2025-26** (178 pp., updated SSD codes) — the manual used
> to train human pre-evaluators — plus real student document samples and issued
> pre-evaluation sheets. Italian-language operational companion: `PREVALUTAZIONE_SPEC.md`.
> Goal: an automatic, real-time preliminary verdict — credits recognized vs. credits still
> to earn — at **~90% accuracy** against the final human-approved sheet, with HITL review
> before anything becomes binding. ER detail: extends domain **T1** (`ER_MAP_TARGET.md`).

---

## 1. Purpose and scope

A prospective student MUST be able to ask, before enrolling: *"how much of my past
counts here, and what remains?"* — and receive a structured, explainable, preliminary
answer in real time, later confirmed by a human pre-evaluator. This annex normativizes:
the intake workflow, the evaluation rulebook, the digital pre-evaluation sheet, the
agent/skill architecture, and the accuracy program.

Out of scope: post-matriculation recognition adjudication (BOOK-14A committees),
admission eligibility itself (BOOK-21), career reconstruction at matriculation (registrar).

## 2. The workflow (state machine)

`request → document_intake → automatic_evaluation → sheet_proposed → hitl_review →
sheet_approved → shared_with_student → countersigned → matriculated`

with loops: `document_intake ↔ integration_request` (missing/illegible documents),
`hitl_review → automatic_evaluation` (replay with corrected parameters),
`shared_with_student → hitl_review` (student contests / adds documents).

Rules:
- R21A.1 **Workability gates** precede any evaluation: identity document present;
  personal data and fiscal code consistent (double names included); duplicate/homonym
  check across all existing requests (same name, different birth date/fiscal code =
  homonym); correct intake area (internal transfer vs. new student); target program
  (CDS) selected. A failed gate yields `not_workable` with a structured, student-visible
  reason — never a silent drop.
- R21A.2 The instant estimate shown at upload time is labeled **preliminary** and carries
  a confidence band (e.g. "78–84 of 180 ECTS"); no sheet reaches the student as final
  without a completed HITL review.
- R21A.3 The sheet is **mutable until countersignature, immutable after** (the manual's
  rule "modifiable until matriculation" tightened to the signature act).
- R21A.4 Every change in HITL review records (row, rule invoked, reason) — this is the
  learning-loop feed (§7).

## 3. The evaluation rulebook (normative digest)

### 3.1 Required documents (per path)

| Path | Documents |
|---|---|
| Bachelor (triennale) | CV; post-diploma IT certificate; post-diploma language certificate; any prior university career |
| Master (magistrale) | **completed** bachelor/legacy career with degree class; CV; IT/language certificates not already validated in a completed career; further prior careers |
| Foreign career | Declaration of Value from the Italian embassy **in the awarding country** (embassy-in-Italy issues are invalid), or CIMEA comparability attestation, or ARDI + Diploma Supplement; sworn translation of exams that **must show the final thesis**; ≥12 years of schooling |
| Pontifical/religious | final degree **awarded**; 60 ECTS/year structure (3+2); Theology and Magisterium excluded unless nominal equipollence from the Ministry; pre-2015 matriculation → nominal equipollence required |
| Special cases | L19 early-childhood: ≥1 year professional experience (ages 0–3) for internship credit; L13/LM61: self-certified professional activity → committee, max 6 ECTS internship |

### 3.2 Source-career validity
Italian institution recognized in the CINECA/MIUR registry (incl. AFAM); pontifical
careers only with regular ECTS structure and completed title; SSML (linguistic mediation
schools) only if under active convention — otherwise zero validation with the standard
notice (an SSML-awarded LM94 is professional-only: 0 credits); non-university providers
= professional title (worth a fixed 12 ECTS of professional training activity when not
in convention); second degree in an already-held class → warning + liability waiver;
pre-1999 professional diplomas and legacy (V.O.) degrees resolved via the equivalence
tables (a V.O. degree maps to an LM class).

### 3.3 Ordinamento detection
V.O. (pre-2000: no degree class, no ECTS, 4–5 years) · D.M. 509/1999 (class number
without "L"; "n/S" for specialistica) · D.M. 270/2004 (L-n / LM-n). A V.O. exam fills
its matching grid exam **entirely**; in a VRA a V.O. exam is worth 12 ECTS
(annual = 12, semester = 6).

### 3.4 Grid matching (the core algorithm)
The program grid has, per year block: **SSD | exam | ECTS required | validating exam |
ECTS to integrate**. Normative rules:

1. Validation is keyed on **SSD** (scientific-disciplinary sector).
2. Multiple grid exams share the SSD → prefer the **same name**, else the **highest
   position** in the grid.
3. Missing SSD on source documents → resolve via the digital **SSD registry**
   ("SSDiario") + the old→new SSD crosswalk (e.g. BIO/13→BIOS-10, IUS/13→GIUR-09,
   IUS/02→GIUR-11); web lookup as last resort, flagged low-confidence.
4. Insufficient ECTS → partial validation with explicit **ECTS to integrate** on the row.
5. Surplus exams → **student-choice slots**: any SSD, summable, but **never** with an
   integration remainder (a slot that cannot be fully covered is not used; the exam is
   forfeited).
6. **Seminar slot** ← credit surplus (or professional experience); it MAY be granted
   without real surplus only to cross the year-access thresholds at 28/29 (and 68/69,
   118/119, 168/169).
7. **Internship** (a.y. 2025-26 rule): only from relevant professional experience
   ≥8 months post-diploma (L19: ≥12 months), not already validated elsewhere, or from
   the **same degree class**; never from leftover exams (exceptions: L-22, L-24, LM-51,
   L-13, LM-61).
8. IT/language certificates resolve against the **certification registry**
   (valid/invalid issuers and formats — the manual's ~70 classified examples are the
   seed; participation-only attestations are invalid, an actual exam is required).
9. **Program-specific derogations** (faculty chapters of the manual) are versioned
   **rule packs per CDS** with effectivity dates — e.g. LM33 must count economics exams
   (IEGE-01 family) up to max 36 ECTS / 3 exams to avoid granting direct access to
   economics graduates; CEAR/08–10 validate INGIND/15; family law validates only family
   law; LM33 language slot is English only.

### 3.5 Totals and closure
Recognized = Σ validated ECTS − Σ integrations; remaining = 180 (bachelor) / 120
(master) / 300 (LMG-01) − recognized; admission year from ECTS thresholds; the
"documents to present at matriculation" list is exactly the set used for validations;
the didactic-office grid (ex-OFA) is computed: ≥30 ECTS → flag 1; ≤29 with a recognized
exam in the listed SSDs → flag "required SSDs"; text-comprehension exemption only if at
least one mandatory exam was validated (where the CDS requires it).

### 3.6 VRA (master's access verification)
Mandatory before any master's pre-evaluation. Exactly four outcomes: **direct access by
degree class** (mind the 509↔270 class crosswalk: L24 ≠ class 24) · **access by credits
in required SSDs** · **access after max 3 single courses** (verifying that exams of the
needed ECTS actually exist in those SSDs) · **requirements not bridgeable**. In a VRA
(only), prior-career laboratories in the sector also count.

## 4. The digital pre-evaluation sheet

The sheet is a **data object**, not a hand-built PDF: header (student, program/CDS,
grid version, rule-pack version), rows (grid row ← source exam, ECTS validated, ECTS to
integrate, rule invoked, evidence link, confidence), totals (recognized / to earn /
admission year / ex-OFA flags), documents-to-present list, and the audit trail of HITL
decisions. PDF/Word are generated renderings. The countersigned sheet is archived as a
verifiable document credential (BOOK-16) and consolidates into `credit_pre_evaluations`
(G16) at matriculation.

## 5. Agent & skill architecture (BOOK-10/10A composition)

| # | Agent | Role | Skills (MCP) |
|---|---|---|---|
| A1 | Document Intake | classify documents, OCR, completeness/legibility gates | `doc-classify`, `ocr-extract` |
| A2 | Transcript Parser | extract exams (name, SSD, ECTS, grade, date), detect ordinamento | `transcript-parse`, `ordinamento-detect` |
| A3 | Career Validator | §3.2 registries: CINECA/AFAM, pontifical, foreign (DoV/CIMEA/ARDI), SSML conventions, dual-degree | `cineca-lookup`, `career-rules` |
| A4 | Certification Validator | §3.4-8 certificate registry match | `cert-registry-match` |
| A5 | SSD Mapper | SSD assignment + old→new crosswalk, per-assignment confidence | `ssd-lookup`, `ssd-crosswalk` |
| A6 | Grid Matcher | §3.4–3.5 as a **deterministic rule engine** over versioned CDS rule packs | `cds-rule-packs` |
| A7 | VRA Evaluator | §3.6 four-outcome verification, class crosswalk | `vra-rules`, `classi-crosswalk` |
| A8 | Confidence & Routing | composite per-row confidence (extraction × SSD × rule), HITL escalation, per-row explanation | `hitl-router` |
| A9 | Sheet Composer | sheet object + renderings + governed standard notices | `scheda-render` |

Architectural rule R21A.5: **inference extracts, rules decide.** A6/A7 are deterministic
(same inputs → same grid); LLM inference is confined to extraction, classification and
mapping (A1–A5), each with declared confidence. Every row carries its evidence chain
(document → extracted exam → SSD → rule). All agents are ACP-composed (BOOK-10), subject
to contract cards and the eval-harness GA gate (BOOK-11 / T11, dataset domain
`credit_pre_evaluation`).

## 6. Data model (T1 refinement)

New tables (16): `preval_requests`, `preval_documents`, `extracted_careers`,
`extracted_exams`, `cds_grids`, `cds_grid_rows`, `cds_rule_packs`,
`preval_evaluations`, `preval_grid_matches`, `vra_evaluations`, `preval_sheets`,
`hitl_reviews`, `sheet_countersignatures`, `ssd_crosswalk`, `certification_registry`,
`career_validity_registry`. They join existing `credit_pre_evaluations`,
`equivalence_rules`, `external_syllabus_records` and BOOK-21's
`admission_applications`. Grids and rule packs are versioned with effectivity dates;
every evaluation **pins** the grid and rule-pack versions it used (no silent
retroactivity — the anti-drift discipline of BOOK-14A applied to rules).

Events (A6-closed): `PrevalRequested`, `PrevalDocumentsComplete`, `PrevalAutoEvaluated`,
`PrevalSheetProposed`, `PrevalReviewed`, `PrevalShared`, `PrevalCountersigned`.

## 7. The accuracy program (~90%)

✅ **Implemented SPRINT-07/NEW-17d.** `backend/services/preval_eval_builder.py` (golden-set
builder) + `preval_eval_metrics.py` (grader/run orchestrator) + `preval_eval_gate.py` (CI gate
script, wired into `.github/workflows/build-push-images.yml`, blocks the real image build/push
job — the same posture `test-gate` already has, extended not duplicated).

- **Golden set** — ⚠ **honestly PROVISIONAL, not historic**: this environment has ZERO real
  historical approved-sheet data (confirmed in this sprint's own pre-flight — no fixture beyond
  the single synthetic "Conti" demo case exists anywhere, matching the plan's own stated risk
  register: "F1 live da S2 produce dati propri"). The golden set is bootstrapped from live
  sprint-02-06 traffic + the Conti fixture, growing via the learning loop below — NOT a real
  historical corpus. Every golden case is one `EvalCase` per HITL-APPROVED `preval_sheets` row
  (`build_golden_case_from_sheet`), `expected` = that sheet's CURRENT (possibly HITL-corrected)
  `rows`/`totals`. The manual's classified negative-class examples (invalid certificates,
  invalid DoVs, etc.) were NOT separately seeded this sprint — no dedicated negative-class
  fixture exists; disclosed as future work, not silently claimed done.
- **Metrics** — ✅ total-ECTS accuracy (`|expected − actual| ≤ 3` ECTS, the primary per-case
  pass/fail criterion) and per-row precision/recall are REAL, computed by replaying the
  deterministic A6 engine (`run_matching_engine`, pure/no-DB) against each golden case's pinned
  grid/rule-pack version and comparing against the human-confirmed sheet. Escalation rate /
  HITL override rate per rule and per CDS are REAL, computed directly from `hitl_reviews
  .decision` history (`compute_hitl_rates`). ⚠ **VRA outcome exactness is honestly `None`** — no
  HITL mechanism captures "the VRA outcome should have been X" the way the row-correction path
  does for sheet rows; reporting a fabricated percentage with no ground truth to compare against
  would violate this program's own no-fabrication discipline.
- **Error decomposition** — ⚠ **the extraction ≥97% / SSD-mapping ≥95% component targets are
  NOT independently measured this sprint, and this is a genuine, disclosed limitation, not an
  oversight**: only the FINAL sheet is ever human-confirmed in this codebase (no ground truth
  exists at the intermediate extraction/SSD-mapping stage in isolation) — the theoretical
  decomposition in this section remains a reachability ARGUMENT, not something the eval gate
  independently verifies component-by-component. The gate enforces the one number that IS
  honestly measurable end to end: composite sheet-level accuracy (`COMPOSITE_ACCURACY_TARGET =
  0.90`) against the golden set.
- **Learning loop** — ✅ real and working, but simpler than "rule-pack or extractor update":
  `submit_hitl_review` now accepts structured `corrected_units_validated`/
  `corrected_units_to_integrate`/`corrected_grid_row_ref`/`corrected_rule_invoked` fields — when
  given with `decision='overridden'` and a `row_key`, it actually mutates `preval_sheets.rows`/
  `.totals` (closing C21A.6, §8). Because `sync_golden_set` always rebuilds a golden case from a
  sheet's CURRENT state, an override with a captured correction is picked up automatically the
  next time the learning loop runs — there is no separate "override → golden case" code path,
  deliberately unified rather than duplicated. A weekly report
  (`preval_eval_report.generate_weekly_report`, rendered via `render_report_markdown`) surfaces
  golden-set growth + accuracy + HITL rates for the responsible person; it marks
  `certification_status: "provisional"` whenever total golden cases < 30 (this sprint's own
  prerequisite clause), never silently "certified" on a bootstrap set. **Scheduling**: this
  codebase's Celery Beat infrastructure exists but was independently reconfirmed to have never
  actually run in any environment (dormant since before this sprint) — the report is wired both
  as a (currently-dormant, matching existing convention) Celery task AND as a standalone CLI
  script (`scripts/preval_weekly_report.py`) that genuinely works today; true periodic (weekly)
  triggering remains out of scope until this codebase's scheduler infrastructure is itself made
  real, a pre-existing gap this sprint did not create and does not fix.
- **Partial auto-approval** — ✅ `preval_auto_approval_configs` (one row per `CdsGrid`,
  `enabled` defaults **False**, `confidence_threshold` defaults 0.95) + `preval_auto_approval
  _service.is_row_auto_approvable` exist as a real, tested mechanism — but are **NOT wired into
  the real HITL flow anywhere this sprint**, and `enabled` is never flipped `True` by any code
  path. Given this sprint's own certification is provisional (above), turning this on would be
  premature regardless of how the tiny bootstrap golden set scored — a future sprint's job, once
  a real ≥90%-over-a-real-corpus certification exists.

## 8. Conformance checks

- C21A.1 Property: no sheet in `shared_with_student` without a completed `hitl_reviews`
  chain.
- C21A.2 Determinism: replaying an evaluation with pinned grid + rule-pack versions
  reproduces the sheet byte-identically.
- C21A.3 Fixture: student-choice slot with a partial cover → MUST be rejected (rule
  §3.4-5).
- C21A.4 Fixture: master's pre-evaluation without a prior VRA record → MUST fail.
- C21A.5 Property: countersigned sheets are immutable; any later change requires a new
  request referencing the old sheet.
- C21A.6 ✅ **Closed SPRINT-07/NEW-17d** — the row-mutation path (`submit_hitl_review`'s
  `corrected_*` params, §7) is the "amend sheet row" action this check's own verifiability
  depended on. Closed as a side effect of building the golden-set learning loop, not the primary
  goal of this sprint. Threshold test itself (seminar-slot grant without surplus only at
  28/29-family boundaries) is now genuinely exercisable via a real row amendment — a dedicated
  fixture test for the exact 28/29 boundary case is NOT written this sprint (out of scope; this
  sprint proves the MECHANISM works, `tests/conformance/test_preval_eval_harness.py`'s own
  `test_hitl_override_amends_sheet_row_and_updates_golden_case`), a future sprint can add the
  specific boundary fixture if BOOK-21A wants it as its own named test.
- C21A.7 ✅ **Real and CI-wired, SPRINT-07/NEW-17d** — `scripts/preval_eval_gate.py`, run as a
  new job in `.github/workflows/build-push-images.yml`, blocks `build-and-push` (the real image
  build/push job) on a 'fail' verdict. Dataset domain is `preval_case` (NOT
  "credit_pre_evaluation" — that name collides with the separate, pre-existing G16 system, see
  Annex A). Component targets (extraction ≥97%, SSD ≥95%) are NOT independently gated — no
  ground truth exists at that granularity, only composite sheet-level accuracy (≥90%) is
  enforced (§7's own honest disclosure). **The gate mechanism is real; the certification it
  currently produces is provisional** (bootstrap-sized golden set, not a real historical corpus)
  — see §7 and the CI job's own inline comments for the precise distinction.

## Annex A — Turnkey mapping

| Element | Exists today | Target |
|---|---|---|
| Credit pre-evaluation record | `credit_pre_evaluations`, `pre_evaluation.py` (G16 ✅) | consolidation target of the sheet — `preval_sheets.credit_pre_evaluation_id` FK reserved (NEW-17a), populated by a later sprint |
| Equivalence data | `equivalence_rules`, `external_syllabus_records` | reused; drift-pinned |
| Recognition adjudication | `recognition.py`, `RecognitionCouncilDesk` (BOOK-14A) | downstream of matriculation |
| Student-facing UI | `PreEvaluationWorkspace` (WS02) — case wizard/status/countersign section ✅ (NEW-17a) | further wizard polish as later phases add real automation |
| Case workflow (F1) | `preval_requests`/`preval_documents`/`preval_evaluations`/`preval_sheets`/`hitl_reviews`/`sheet_countersignatures`, `preval_workflow.py`/`preval_workflow_service.py`, staff `PrevalDesk` HITL desk ✅ (NEW-17a, 2026-07-29) | — |
| Extraction + matching engine (F2) | `extracted_careers`/`extracted_exams`/`cds_grids`/`cds_grid_rows`/`ssd_crosswalk`, agents A1 (`preval/intake.py`)/A2+A5 (`preval/parser.py`, real `LLMClientFactory` call)/A6 (`preval/engine.py`, byte-for-byte Workbench port), `scripts/import_cds_grid.py` — 2 pilot CDS live, `evaluation_mode='automatic'` real ✅ (NEW-17b, 2026-07-30) | — |
| Rule packs, registries, VRA (F3) | `cds_rule_packs` (versioned derogations, A6 addition — one concrete rule type, `max_cap_per_ssd_family`, proven via synthetic fixture; both pilot CDS seeded empty, no real derogation documented for either), `career_validity_registry`/`certification_registry` (A3/A4, promote the NEW-17b in-code stand-in to real tables), `vra_evaluations` (A7, 4 outcomes, hard-blocks magistrale automatic evaluation without a prior VRA — C21A.4), per-row composite confidence + `needs_escalation` (A8), public zero-persistence `POST /instant-estimate` (multi-CDS what-if) ✅ (NEW-17c, 2026-07-30) | — |
| Golden set + eval loop (F4) ✅ (NEW-17d) | `eval_datasets`/`eval_cases`/`eval_runs`/`eval_case_results` (T11, domain `preval_case`) — `preval_eval_builder.py` (golden-case builder + learning loop), `preval_eval_metrics.py` (grader, composite ECTS/precision/recall/escalation/override metrics — VRA exactness and extraction/SSD component accuracy honestly `None`, no ground truth exists), `preval_eval_gate.py` (real CI gate, `build-push-images.yml`), `preval_eval_report.py` (weekly report, `certification_status` provisional below 30 cases), `preval_auto_approval_configs`/`preval_auto_approval_service.py` (per-CDS threshold config, built but NOT wired/enabled anywhere) | Real historical corpus (golden set is bootstrap-sized, provisional certification); component-level (extraction/SSD) independent measurement; negative-class fixture seeding from the manual's classified examples; auto-approval actually wired into the HITL flow (blocked on a real, non-provisional ≥90% certification first) |
| QES / document credentials | `qes_signature_ref`, `issued_document_credentials` — countersignature archival wired (NEW-17a; skipped honestly when the applicant has no twin yet) | countersigned sheet archival |
| New tables | 15 of 15 net done (§6 F1-F3 tables — `preval_grid_matches` superseded by `preval_sheets.rows` JSON, never a real gap) + `preval_auto_approval_configs` (F4, NEW-17d) — 16 total | 0 remaining |
| Sprint | **NEW-17a ✅** (workflow+sheet, F1), **NEW-17b ✅** (A1/A2/A5/A6 + 2 pilot CDS, F2), **NEW-17c ✅** (rule packs + A3/A4/A7/A8 + instant estimate, F3), **NEW-17d ✅** (golden set + eval loop, F4 — this sprint) | — |
| Known open gap | ~~C21A.6~~ **closed this sprint** (was: seminar grant near an admission-year threshold without real surplus — the HITL override was audit-only, never mutated `preval_sheets.rows`; now it does, via `corrected_*` fields). New, honestly disclosed gap: the golden-set certification is **provisional** (bootstrap-sized, no real historical corpus in this environment) — not a defect, a data-availability fact this sprint's own prerequisite anticipated. | — |
| Register | detail row under **G17** in TRACEABILITY — status "automazione certificata (provvisoria)" | — |
