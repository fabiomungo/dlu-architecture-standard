# Sprint NEW-13 — Compliance Registers + Calendar (G8, G12, G13, G14, AI Act)
### DAS K5 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-11 (ESSE3 boundary tables feed the G8 monitor — soft dependency, read-only), NEW-09/10 (I5's three pre-wired stub claims + `OfficeHourBooking`), NEW-06 (thesis-advisor approvals as RSI evidence), STX-11 (exam sign-offs, viva sessions as RSI evidence) · opus design review already completed — see `docs/sprint_decisions_YYYYMMDD_new13.md` once written

## Role
`backend-dev` executing an opus-reviewed architecture (RSI/DE-DI ledger
data-source strategy, AI Act register shape, identity-verification
policy resolution, calendar mechanism) resolving **G8** (BOOK-08 §6.3),
**G12** (BOOK-19 Ch. 6.1), **G13** (BOOK-19 Ch. 6.2), **G14** (BOOK-19
§5.1), plus the AI Act obligation register + FRIA (BOOK-19 Ch. 3) and
the compliance calendar (BOOK-19 Ch. 7). This is the largest single K5
sprint — four G-items plus two cross-cutting registers, all landing on
the same I5 surface — organize the work by the six deliverables below,
not as one undifferentiated register.

## Context — read before coding
1. **G12 — RSI, verbatim (BOOK-19 Ch. 6.1, 34 CFR 600.2):**
   "Substantive interaction" = teaching/learning/assessment PLUS at
   least two of: direct instruction; assessing/feedback on coursework;
   responding to content questions; facilitating content discussions;
   other agency-approved activities. "Regular" = predictable/scheduled +
   instructor monitoring. **AI interaction is explicitly NOT instructor
   interaction.** Courses failing RSI are reclassified as correspondence
   courses — Title IV repayment exposure. Required: (1) a declared RSI
   plan per US-profile course; (2) an RSI ledger aggregating instructor
   interaction events per course × student × term with zero-touchpoint
   alerting.
2. **G14 — DE/DI, verbatim (BOOK-19 §5.1, ANVUR telematic regime):**
   Didattica Erogativa (one-way: recorded lectures/courseware) vs
   Didattica Interattiva (instructor-involving: web-conference seminars,
   assessed e-tivities, facilitated discussion, virtual labs) —
   minimum-hours-per-CFU floors on each; **AI does not count toward
   DI** (same doctrine as RSI); a per-CFU ledger with under-quota alerts
   *before* CEV (accreditation site-visit) evaluations.
3. **The confirmed, load-bearing gap (Masterbook Review finding M3,
   TRACEABILITY's own cross-cutting-dependency note): "RSI/DI evidence
   depends on Moodle-side instructor activity... the Moodle driver
   contract must explicitly capture instructor-role events into xAPI,
   else the G12/G14 ledgers under-count and fail audits."** This has
   **not** been built — `backend/database/models_xapi.py::XAPIStatement`
   has a bare `actor_id` UUID with no role field, and
   `xapi_service.py::get_statements()` has no course filter or
   per-course×student aggregation at all. Forum facilitation and
   web-conference attendance are captured NOWHERE as role-attributed
   events today. **This sprint does NOT extend the Moodle driver
   contract** (that's out of scope, a separate future fix) — it builds
   the ledger honestly against what IS real today, with an explicit,
   surfaced under-count disclosure (Deliverable 1), never a silent gap
   and never a refusal to ship until Moodle is fixed.
4. **What IS real and course/student-attributed enough to aggregate
   today:** `StudentExamAttempt.grader_id`/`graded_at` (a human
   grade/feedback sign-off — the sign-off act, not the AI-drafted
   `ai_feedback_json` — the only source that is genuinely
   course-attributed); `ThesisMilestone.approved_by`/`approved_at` (an
   advisor approving a specific student's milestone — student-attributed,
   program-level, not course-attributed); `OfficeHourBooking
   .faculty_user_id`/`student_user_id`/`status='confirmed'` (a scheduled
   meeting — student-attributed, **no `course_id` column exists on this
   table** — do not fabricate one); STX-11's viva sessions
   (student-attributed). `TeachingRegisterSession` (a class session) and
   course-governance Gate-2 reviews are instructor↔COHORT/COURSE, never
   attributable to an individual student — exclude both from per-student
   ledger rows; they may appear as course-level context only.
5. **G13 — identity verification, verbatim (BOOK-19 Ch. 6.2, 34 CFR
   602.17(g)/(h)):** "layered verification = Keycloak MFA (+SPID-grade
   assurance where available) · assessment-integrity layers (BOOK-15
   Ch. 9: authentic tasks with process evidence, dialogic verification —
   a viva is the strongest identity check in existence) · session-based
   checks for high-stakes (proctoring last resort, consented, DPIA'd)."
   Deliverables: a per-tenant Identity Verification Policy artifact
   (methods per assessment class), registration-time disclosure
   (verification charges), privacy documentation — surfaced in I5.
6. **AI Act register + FRIA, verbatim (BOOK-19 Ch. 3):** a table mapping
   nine EU AI Act deployer obligations (risk management system; data
   governance & quality; technical documentation; record-keeping/logs;
   transparency to users; human oversight; accuracy & robustness; FRIA;
   serious-incident reporting) to kernel mechanisms — *"Register status
   renders in I5; red items are board-visible by construction."* FRIA =
   *"template + trigger list (new deployments, new cohort classes)."*
   **Two dead-code attempts already exist in this codebase — do NOT
   resurrect either:** `backend/domains/ai_governance/` (zero migration,
   zero caller anywhere) and `backend/database/models_ai_governance
   .py`'s `AIGovernancePolicy`/`AIExecutionAudit` (a real migration, but
   zero service/route ever reads or writes them — only that same file's
   `AIProvenance` is actually live). This codebase DOES have a real,
   live registry to extend instead: 9 seeded `ai_agent_configs` rows
   (all `lifecycle_state="testing"`, none yet steward-signed — unchanged
   by this sprint, a separate residual-debt item).
7. **G8, verbatim (BOOK-08 §6.3):** *"completeness"* = whether the
   ESSE3-mirrored career-event fields DLU already holds (via NEW-11's
   boundary tables, if executed by the time this sprint runs) are
   present/consistent for what an ANS spedizione needs — **never new
   ministerial data DLU authors**. Alert = missing career events,
   checked BEFORE a spedizione fails, never after. "Dossier export" = a
   Track-A view exported from the SAME generated accreditation dossier
   `compliance_posture_service.py` already produces for SUA-CdS quality
   sections — not a new document type. If NEW-11 has not yet been
   executed when this sprint runs, the monitor's completeness checks
   against ESSE3 boundary data degrade honestly to
   `not_yet_available` — never fabricated against tables that don't
   exist yet.
8. **I5's current shape** (`backend/services/compliance_posture_service.py
   ::compute_compliance_posture()`): returns a fixed ~10-claim list,
   each `{"claim", "status" ∈
   {"verified","partial","stale","not_yet_available"}, "evidence",
   "freshness_stamp"}`. **Three pre-written stub claims name this sprint
   explicitly and must be filled in for real:** `_claim_ai_act_register`,
   `_claim_g8_completeness_monitor`, `_claim_g14_de_di_ledger`. **There is
   no pre-wired stub for G12 or G13 at all** — those claims must be added
   from scratch, not merely filled in.
9. **M7 (Masterbook Review, licensure disclosures, 34 CFR
   668.43(a)(5)(v)) — textually adjacent to G13 but a DIFFERENT
   citation** (G13 = identity-verification-charge disclosure; M7 =
   per-state program-eligibility-for-licensure disclosure). The
   Masterbook's own review disposition already decided M7 is a
   compliance-calendar checklist item, not a new G-number — keep the
   two disclosures textually and structurally distinct even though they
   share the same versioned-consent mechanism (Deliverable 3).
10. **No FRIA-as-PDF requirement exists anywhere in the Book** — the I5
    dossier itself is pure JSON; a structured JSON report (not
    reportlab) is the right shape (Deliverable 2), reusing the existing
    `_claim()`/`_gap()` vocabulary rather than inventing a rendering
    layer this sprint doesn't need.
11. **Surfaces are minimal.** All new claims/registers surface through
    the EXISTING I5 read surface (`institution_workspaces.py`) — no new
    top-level UI page. The compliance calendar is a new section within
    I5, not a standalone workspace.

## Guardrails
Additive-only migration — new `platform`-schema tables
(`ai_act_obligations`, `fria_assessments`, `identity_verification_policies`,
`program_state_disclosures`) plus two new nullable columns on
`ai_agent_configs` (`ai_act_risk_class`, `ai_act_role`) plus two new
nullable JSON columns on the course-design row beside `media_mix`
(`rsi_plan`, `de_di_classification`) — named constraints, tested
`downgrade()`. No materialized ledger/calendar table — everything in
Deliverables 1, 4, and 5 is compute-on-read (see rationale in each), so
there is deliberately no new "ledger" or "calendar" table in the
migration beyond the four register tables listed above.

## Deliverables
1. **RSI/DE-DI interaction ledger** — `backend/services/
   interaction_ledger_service.py::compute_interaction_ledger(db,
   institution_id, term_id, *, regime: Literal["rsi","de_di"])`.
   Roster-anchored: LEFT JOIN active `CohortEnrollment` rows against
   real interaction events (Context point 4) — roster-anchoring is what
   makes a *zero*-touchpoint detectable at all (an event stream alone
   cannot prove absence). Emits per-`(course_id, student_id, term)` rows
   from `StudentExamAttempt` sign-offs (the only course-attributed
   source) plus a per-`(student_id, term)` supplementary tally from
   office-hours/thesis-advisor/viva events (student-attributed,
   course-agnostic — reported alongside, never silently merged into the
   course-level row as if course-attributed). **Every row carries a
   `data_completeness` block**: `{captured_sources: [...],
   uncaptured: ["moodle_forum_facilitation",
   "moodle_webconference_attendance"], caveat: "counts reflect
   structured platform events only — Moodle Mode-B instructor events are
   not yet role-attributed (XAPIStatement.actor_id has no role field);
   this ledger under-counts until that driver contract is extended"}`.
   Zero-touchpoint alerting fires on `total_events == 0`, always
   qualified by the same `data_completeness` block — an auditor reading
   the alert sees exactly what evidence it is (and isn't) checked
   against. `regime="rsi"` selects US-profile courses
   (`Institution.country_code`), `regime="de_di"` selects Italian
   telematic courses (`Program.credit_system == "ects"` + telematic
   flag) — same function, different event/threshold sets, never two
   parallel implementations.
2. **Declared RSI plan / DE-DI classification** — two new nullable JSON
   columns on the existing course-design row, colocated beside
   `media_mix` (`backend/database/models_content_creation.py`) rather
   than a new model: `rsi_plan` (scheduled instructor activities per
   BOOK-19 Ch. 6.1 requirement 1) and `de_di_classification`
   (`{de_hours_per_cfu, di_hours_per_cfu, di_activities: [...]}` per
   BOOK-19 §5.1 requirement 1 — this field does not exist anywhere yet,
   confirmed absent). Both nullable — a course with neither declared
   surfaces as `not_yet_available` in its ledger row, never a fabricated
   default classification.
3. **AI Act register + FRIA**:
   - `ai_agent_configs.ai_act_risk_class` (CHECK
     `minimal|limited|high|prohibited`) and `.ai_act_role` (CHECK
     `deployer|provider` — DLU is deployer per BOOK-19 Ch. 3) as two new
     nullable columns on the existing, live registry — risk class is an
     intrinsic property of the agent, not a relation.
   - `ai_act_obligations` table (`platform` schema): one row per
     `(ai_agent_config_id, obligation_key)` — `obligation_key` CHECK IN
     the nine BOOK-19 Ch. 3 obligations (`risk_management`,
     `data_governance`, `technical_documentation`, `record_keeping`,
     `transparency`, `human_oversight`, `accuracy_robustness`, `fria`,
     `incident_reporting`); `status` reuses the posture vocabulary
     (`verified|partial|not_yet_available`); `evidence_ref` (JSON),
     `freshness_stamp`.
   - `fria_assessments` table: `trigger_kind` (CHECK
     `new_deployment|new_cohort_class`), `subject_ref`,
     `template_json` (the structured JSON report body — no reportlab
     PDF), `status`, `completed_at`. Triggered on an agent's
     `lifecycle_state → "deployed"` transition and on new cohort-class
     creation — never retroactively fabricated for already-existing
     deployments without a real assessment.
4. **Identity Verification Policy** —
   `identity_verification_policies` table (`platform` schema,
   tenant-scoped): `methods_by_assessment_class` (JSON, e.g.
   `{"native_quiz": "keycloak_mfa", "proctored_exam":
   "session_proctoring_dpia'd", "viva": "dialogic"}`), `version`,
   `effective_at`. Live resolver
   `resolve_identity_verification_policy(db, tenant_id,
   assessment_class=None)` — read-only, mirrors
   `clearance_service.resolve_clearance_checklist`'s live-resolve,
   never-write discipline exactly. Registration-time disclosure is
   recorded as a new versioned key in the twin's EXISTING
   `StudentTwin.consent_flags` JSON
   (`consent_flags["identity_verification_disclosure"] = {version,
   acknowledged_at}`) — reusing the established consent/versioning
   mechanism rather than a new disclosure table.
5. **G8 ANS/SUA-CdS completeness monitor** — a new
   `compliance_posture_service` function reading NEW-11's ESSE3 boundary
   tables (`esse3_boundary_career` et al., if present) for missing/
   inconsistent career-event fields, alerting BEFORE a spedizione would
   fail — never generating or submitting anything itself (the
   submission stays ESSE3-side, per the driver doctrine). Dossier export
   = a Track-A view function over the SAME dossier
   `compliance_posture_service.py` already assembles — not a second
   document-generation pipeline.
6. **Compliance calendar** —
   `backend/services/compliance_calendar_service.py
   ::compute_compliance_calendar(db, tenant_id, institution_id, as_of)`
   — ONE compute-on-read function serving two row kinds, never
   materialized (the durable evidence already lives in the ledgers/
   registers above; materializing occurrences would add a
   reconciliation burden for zero audit benefit, the same reasoning
   `compliance_posture_service`/`clearance_service` already established
   for live-resolve over persisted-cache): **schedule-only rows**
   (AI Act register: continuous; DPIA register; consent/disclosure
   versions; ANS spedizioni: per MUR calendar; accreditation cycles; key
   ceremonies; DR exercises: quarterly; board reviews) with `next_due`
   from a small static cadence catalog; **evidence-driven rows** (RSI
   ledger review: per term; DE/DI ledger review: per term) with
   `status` computed live by calling Deliverable 1/3's functions.
   Includes the **M7 licensure-disclosure item** as one additional
   schedule-only row: a new, minimal `program_state_disclosures` table
   (`program_id`, `state_code`, `disclosure_status`, `reviewed_by`,
   `reviewed_at`) — human-attested, no live regulatory lookup (none
   exists or is requested; the Masterbook Review's own disposition
   already ruled this a checklist item, not a new G-number).
7. **I5 wiring** — fill in the three existing stub claims
   (`_claim_ai_act_register`, `_claim_g8_completeness_monitor`,
   `_claim_g14_de_di_ledger`) for real against Deliverables 3/5/1, and
   ADD two new claims from scratch (`_claim_g12_rsi_ledger`,
   `_claim_g13_identity_verification`) — neither had a pre-wired stub.
   Add the compliance calendar as a new I5 response section, reusing
   `institution_workspaces.py`'s existing read-time-aggregation
   discipline (no new tables written by the route itself).

## Verifications
- **V1** RSI ledger reproduces from kernel events: a fixture course with
  seeded exam sign-offs/office-hours/thesis-approval events produces
  the exact expected per-course×student ledger rows, each carrying a
  correct `data_completeness` block naming the Moodle gap.
- **V2** zero-touchpoint alert fires: a fixture student with zero
  interaction events across a term triggers the alert, qualified by
  `data_completeness` (never an unqualified "0 interactions" claim).
- **V3** identity-verification disclosure renders + is recorded: a
  fixture registration flow writes
  `consent_flags["identity_verification_disclosure"]` with the current
  policy version; re-registering with an unchanged policy version does
  not duplicate the disclosure record.
- **V4** G8 spedizione pre-check catches seeded incompleteness: a
  fixture with a deliberately missing ESSE3 boundary field is flagged
  BEFORE any spedizione-shaped export runs; a complete fixture passes
  clean.
- **V5** DE/DI ledger classifies a fixture course correctly and flags an
  under-quota CFU: a course declared with `di_hours_per_cfu` below the
  configured floor surfaces as under-quota in both the ledger and the
  I5 claim.
- **V6** AI interactions excluded from DI/RSI counts (negative test): a
  fixture agent-authored interaction (e.g. an AI-drafted feedback event
  with no human `grader_id`/`approved_by` sign-off) contributes ZERO to
  either ledger — a structural assertion that only human-attributed
  events are ever counted, mirroring the codebase's existing "AI ≠
  instructor/DI" doctrine.
- **V7** AI Act register negative test: an agent with any
  `ai_act_obligations` row `status != "verified"` renders as
  partial/gap in I5 ("red items are board-visible by construction") —
  never silently rolled up into an overall-green claim.
- **V8** structural: neither dead-code AI-governance module
  (`backend/domains/ai_governance/`, `models_ai_governance.py`'s
  `AIGovernancePolicy`/`AIExecutionAudit`) gains a new caller from this
  sprint — grep-based negative check, confirming Context point 6's
  "do not resurrect" instruction was honored.

## DoD
V1–V8 green · `pytest -m phase1` green · migration
`upgrade`/`downgrade`/`upgrade` verified on an isolated throwaway
Postgres · **G8, G12, G13, G14 dispositions updated in TRACEABILITY** —
each with its own honest status (G12/G14 explicitly note the Moodle
instructor-event under-count as a disclosed, not hidden, limitation;
G8 explicitly notes it degrades to `not_yet_available` if NEW-11 has
not yet been executed) · BOOK-08 §6.3 / BOOK-19 Ch. 3/Ch. 5.1/Ch. 6/
Ch. 7 Annex rows updated · BOOK-19 Ch. 7's compliance-calendar table
gets an implementation cross-reference · CLAUDE.md unaffected (no new
env vars this sprint) · decisions note
(`docs/sprint_decisions_YYYYMMDD_new13.md`) recording: the roster-
anchored ledger design and its explicit Moodle-gap disclosure
mechanism, the AI Act register's extend-not-resurrect decision, the
FRIA-as-JSON (not PDF) decision, and the compliance-calendar's
compute-on-read (not materialized) decision · next: **NEW-14** (cost
attribution) is independent of this sprint (no shared files); **NEW-15**
(conformance suites) is the sprint that turns V1–V8 here into a
permanent CI-runnable suite alongside every other phase's own
verifications.
