# Sprint STX-14/15 — Behaviour Recompute + Student Success + Career Advisor + WS08
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: K1 twin core (TwinBehaviourProfile, TwinCareerGoal), STX-12 (GPS career-scenario scaffolding), K3 (gate)

## Role
`backend-dev` + `frontend-dev` (DAS BOOK-10 Ch. 3 cards; BOOK-20 Ch. 6;
BOOK-09 Ch. 6 cognitive-budget concept — scoped, not fully built, see
below; BOOK-01 Ch. 10 wellbeing/belonging doctrine; BOOK-02 Ch. 6
belonging-first doctrine).

## Context — read before coding
1. BOOK-10 Ch. 3 cards, binding:
   - **Student Success Agent** — moves `flag_risk`, `encourage`,
     `refer_to_human`. Reads **L2/L4/L6**. Skills: risk interpretation
     (deterministically scored — v1: a documented weighted heuristic,
     not a trained ML model — agent-narrated; the agent never invents a risk
     score), intervention drafting, re-engagement campaigns. Tools:
     notification, advisor queue. Autonomy: **propose for
     interventions**; its detection missions run on the cognitive budget
     with the belonging-first doctrine — **the intervention is human
     connection**, not an AI chatbot substituting for one.
   - **Career Advisor** — moves `reframe_goal`, `recommend_next`,
     `explain_concept` (occupations). Reads **L3/L5**. Skills: ESCO gap
     analysis, competency-to-occupation mapping, CV/portfolio guidance
     from the evidence graph. Tools: ESCO, GPS career scenario, wallet
     export. Autonomy: propose (goals are self-determined); employer
     disclosure strictly consent-scoped.
2. BOOK-20 Ch. 6 deliverable text: nightly behaviour recompute
   (**aggregates only**), Success Agent (risk missions on cognitive
   budget, human-connection interventions), Career Advisor (ESCO gap
   analysis), WS08; load tests, docs, NFR dashboards.
3. **Repo-verified existing state — read before writing any code:**
   - `TwinBehaviourProfile` (`backend/database/models_student_twin.py`,
     tenant schema, GUID PK, unique `twin_id`) already has the exact
     column shape this sprint needs (`learning_style`, `study_habits`,
     `engagement_score`, `engagement_trend` — vocabulary is `up|flat|
     down`, `risk_score`, `features_version`, `computed_at`) and is
     already **read** by `move_policy_service.build_assessment` (derives
     `engagement_dip`, `effort_present`, `risk_over_threshold =
     risk_score >= 0.70`) — but has **zero writers anywhere**. This
     sprint's nightly recompute is the first thing that ever populates
     this table. Do not alter its schema unless a genuine gap is found;
     write to the existing columns.
   - `TwinCareerGoal` (same file, tenant schema, GUID PK) is already
     fully wired (populated via `PATCH /api/twin/me/career-goals`, read
     by `TwinContextService._fetch_career`, consumed by
     `academic_gps_service.py` for `esco_occupation`-targeted GPS
     scenarios) — `esco_occupation_uri` is a free-text `String(500)`
     with nothing behind it (no ESCO dataset exists anywhere in this
     repo — confirmed absent: no client, no cached snapshot, no seed
     rows; `academic_gps_service.py` itself has explicit code comments
     saying so). Career Advisor is the first feature that needs real
     data behind this field.
   - **No general cognitive-budget engine exists.** `ace_service.py`,
     `ace_worker.py`, and `consolidation_service.py` each carry an
     explicit `TODO(budget): BOOK-09 Ch. 6's general cognitive budget
     engine (floors/caps/equity guardrail, all agents) is later work`
     comment. The only budget-shaped precedent is
     `coach_etiquette_service.py` (`can_send_proactive_mission` — quiet
     hours + a daily contact cap counted from `ace_cycle_traces` rows,
     hardcoded to `agent_key == "learning_coach"`).
   - `flag_risk` (`Move(name="flag_risk", move_class="care",
     autonomy="propose", preconditions=["risk_over_threshold"])`,
     `backend/services/pedagogical_moves.py`) already exists in the
     closed move catalog, already has its precondition wired to
     `risk_score >= 0.70`, and `move_proposal_service.py` already
     reserves a 7-day TTL class for it (`"flag_risk": 7 * 24 * 3600`,
     comment: "a risk flag awaiting advisor review needs days, not the
     30-minute course-content TTL") and it is already in
     `consolidation_service.py`'s `_HIGH_STAKES_MOVES` set. **No agent
     currently binds it** — it has been sitting ready, unreachable,
     since before this session, because nothing populates `risk_score`.
   - `refer_to_human`'s generic path (`ace_service.py`, `_realize_l0`) is
     today a **scripted string only** ("I'm connecting you with a person
     who can help with this.") with no ticket/notification/DB artifact.
     The separate crisis path (`_handle_crisis`) does write a real,
     durable `CrisisIncident` row and emit `RISK_DETECTED`, but it is
     **pull-visible only** (a staff list route,
     `backend/api/routes/ai_management.py`) — no push notification to an
     advisor exists anywhere.
   - `event_taxonomy.py` already pre-reserves `RISK_DETECTED`,
     `RISK_CLEARED`, `GRADUATION_PREDICTED` in the closed `EVENT_TYPES`
     set (usable without an RFC), and `CONSUMER_GROUPS` already
     pre-reserves `"success-watch"` — but `event_consumers.py` shows it
     as a **stub with zero `.on()` handlers registered** (comment
     confirms STX-04 never added one). This is the natural place to wire
     real handlers.
   - `backend/workers/celery_app.py`'s `memory-consolidation-nightly`
     (`crontab(hour=2, minute=30)`) is the cleanest existing nightly-beat
     template — sync Celery task wrapping `asyncio.run()` around an
     async session, calling into a service function. Check at
     implementation time whether its own multi-tenant fan-out is
     unambiguous before copying the pattern; if it is not, this sprint's
     new task must do its own explicit per-tenant loop rather than
     inherit an undocumented gap.
   - `AGENT_ENTITLEMENTS["student_success"] = frozenset({L2_ACADEMIC,
     L4_KNOWLEDGE, L6_BEHAVIOUR})` and `AGENT_ENTITLEMENTS[
     "career_advisor"] = frozenset({L3_COMPETENCY, L5_CAREER})` already
     reserved in `twin_context_service.py` — reuse exactly.
     `Purpose.SUCCESS = "success"` already reserved in the `Purpose`
     enum; no `Purpose.CAREER` exists yet — add it. No
     `STUDENT_SUCCESS_AGENT_KEY`/`CAREER_ADVISOR_AGENT_KEY` constants, no
     `*_MOVE_BINDINGS`, no `AGENT_PURPOSE` entries, no
     `WORKSPACE_AGENT_BIAS["ws08"]`, no `seed_*` functions exist — add
     all per the established lock-step pattern (this is the 8th/9th
     agent — all nine BOOK-10 Ch.3 cards are covered after this sprint).
   - The constitution's own agent table uses short `agent_key`s
     (`success`, `career`) that don't match the code's actual long
     reserved keys (`student_success`, `career_advisor`) — this is a
     pre-existing, already-flagged doc-vs-code naming gap (same pattern
     already noted for Subject Tutor/Learning Coach); use the long
     code-accurate keys, note the doc uses short names.
   - L6 consent gating already exists:
     `CONSENT_LAYER_FLAGS[L6_BEHAVIOUR] = "behaviour_analytics"` in
     `twin_context_service.py` — the nightly recompute must check this
     flag per-twin before writing (matches the STX-09 "V4 consent
     degradation" precedent) rather than computing unconditionally.
   - Constitution §20 row 5 flags a compliance-review prerequisite:
     "Behaviour features & FERPA scope per region — review with
     `COMPLIANCE_MULTIREGION` doc before STX-14." Read
     `docs/UNIVERSITY_PLATFORM_COMPLIANCE_MULTIREGION.md`'s relevant
     section before finalizing what the nightly job may read/write, and
     record the review outcome in the decisions doc — do not skip this
     silently.
   - Pre-existing raw-event tables (`XAPIStatement`, `LearningEvent`) and
     the older `personalization.py` engagement-trend computation (a
     parallel, differently-worded ("increasing/stable/declining") ad hoc
     calculation straight off raw xAPI, unrelated to the Twin/L6
     pipeline) already exist. The nightly recompute may **read** from
     these (or from twin-scoped signals like `AceCycleTrace`,
     `Recommendation` accept/dismiss, `TutorDialogueState` struggle
     patterns, exam/quiz attempts) but must **never persist raw
     per-event rows into the twin or any L6-scoped table** — only
     scalar aggregates land in `TwinBehaviourProfile`. This is exactly
     what V1's schema audit checks.
4. **Design decision — cognitive-budget scope (opus design-review
   verdict: APPROVE WITH CHANGES; do not build the general BOOK-09
   engine):** the honest, bounded scope is a **mission-budget primitive**
   generalizing `coach_etiquette_service.py`'s shape (quiet hours + a
   daily/period cap counted from `ace_cycle_traces`), parameterized by
   **both `agent_key` and `mission_kind`** (still only quiet-hours + a
   period cap — no floors/equity-guardrail machinery) — this costs
   almost nothing over a single-agent version (the existing service is
   already one constant + one `.where()` clause away from generic) and
   avoids a guaranteed second rewrite the first time Career Advisor or
   another agent needs proactive-contact budgeting. It gates
   `flag_risk`/risk-detection missions for Student Success specifically —
   **not** a floors/caps/equity engine shared by all nine agents; that
   general engine remains explicitly deferred, re-flagged in this
   sprint's own decisions doc as still-open debt (do not claim it's
   done). Add a composite index `(twin_id, agent_key, created_at)` on
   `ace_cycle_traces` so the per-call "how many missions today" count
   query stays bounded as trace history grows (the table has no such
   index today — it has `tenant_id`/`twin_id` FK indexes only). V3's
   "cognitive-budget equity report" reports on **this scoped mechanism's
   own fairness** (e.g., are risk-mission caps/timing applied evenly
   across student segments, no systematic under- or over-contact of any
   cohort) — a real, bounded, measurable report, not a claim about a
   system-wide engine that doesn't exist. Separately: `move_policy_
   service.py`'s existing `RISK_THRESHOLD = 0.70` (already labelled a v1
   heuristic) is inherited as `flag_risk`'s firing threshold — but must
   be recorded explicitly in the decisions doc as an **unvalidated v1
   policy knob**, chosen before any real `risk_score` data existed and
   flagged for recalibration once real distributions are observed, not
   silently treated as already-settled the moment this sprint makes it
   reachable for the first time.
5. **Design decision — ESCO scope (opus design-review verdict: APPROVE
   WITH CHANGES; do not build a live ESCO API client):** per the
   constitution's own §20 suggestion ("local snapshot table, quarterly
   refresh"), build a small, clearly-labeled **local ESCO-lite seed** —
   drawn from a static, offline ESCO CSV/JSON fixture bundled with the
   migration or a seed script, not a live remote API call — but
   selected by a **stated inclusion rule, not ad hoc hand-picking**
   (arbitrary selection on a student-facing feature is itself an equity
   risk): seed every occupation already referenced by a live
   `TwinCareerGoal.esco_occupation_uri`, plus occupations current course
   learning outcomes already map to, plus the top-N occupations by
   declared `TwinCareerGoal` frequency. Gap analysis is real for the
   seeded set and honestly, **visibly** `not_yet_available` outside it
   (never silently degraded). Explicitly out of scope and named as
   deferred in the decisions doc: full ESCO coverage (~3000 occupations,
   multi-language), a live API client, and automated quarterly refresh
   tooling. This mirrors the established "real but bounded" precedent
   (STX-11's classical stats instead of a fitted IRT model; STX-09's
   KG-frontier reuse instead of a full catalog explorer).

## Deliverables
1. **Nightly behaviour recompute**: a new Celery beat task
   (`crontab`-scheduled, modeled on `memory-consolidation-nightly`,
   explicit per-tenant fan-out) computing, per twin with L6 consent
   granted: `engagement_score`/`engagement_trend` (`up|flat|down`) from
   recent mission/recommendation/tutor-dialogue activity, `risk_score`
   from a documented, deterministic (not LLM) weighted heuristic over the
   same aggregate signals, `study_habits`/`learning_style` summaries —
   writing only scalar aggregates to `TwinBehaviourProfile`, never a raw
   event row. Twins without L6 consent are skipped (degrade, don't
   error).
2. **Mission-budget gate, `(agent_key, mission_kind)`-parameterized**: a
   generalized `coach_etiquette_service.py` (or a small sibling service
   with the same signature shape) gating how often a given agent's given
   mission kind runs per twin/tenant — quiet hours + period cap, same
   shape as the Coach precedent, reusable by Student Success's
   risk-detection missions today without hardcoding to one agent_key;
   still explicitly not the general floors/equity engine. Add the
   `(twin_id, agent_key, created_at)` composite index on
   `ace_cycle_traces`.
3. **Student Success Agent**: seed row (`student_success`, `testing`);
   bindings `flag_risk` (propose — files a `move_proposal_service` HITL
   item using the already-reserved 7-day TTL class, real advisor-queue
   artifact), `encourage` (act, low-stakes), `refer_to_human` (existing
   scripted floor, kept as-is — `flag_risk` is the primary
   human-connection vehicle, not a replacement for `refer_to_human`).
   Wire a real notification (not just pull-visible) to the assigned
   advisor when a `flag_risk` proposal is filed, reusing the existing
   `NotificationPreference`-based mechanism the Coach etiquette service
   already reads from.
4. **`success-watch` consumer group made real**: register handlers for
   `RISK_DETECTED` (routes to the Student Success mission/notification
   path) and `GRADUATION_PREDICTED` (feeds Career Advisor's gap-refresh).
5. **ESCO-lite seed + Career Advisor gap analysis**: seed table(s) for a
   bounded occupation/skill set; gap analysis comparing a student's L3
   competencies against a target `TwinCareerGoal.esco_occupation_uri`'s
   seeded skill set, surfaced as `recommend_next` candidates (reusing the
   STX-09 recommendation-candidate shape) closing the largest gaps first.
6. **Career Advisor Agent**: seed row (`career_advisor`, `testing`);
   bindings `reframe_goal`, `recommend_next`, `explain_concept`
   (occupations); `AGENT_PURPOSE`, `Purpose.CAREER` added.
7. **WS08 (Engagement & Student Success)**: Canvas — a self-facing "how
   you're doing" view (engagement/risk framed supportively, never a raw
   numeric risk score shown to the student), career gap view; Companion
   bias `ws08` → student_success (primary) with career surfaced
   alongside; staff-facing HITL queue view for `flag_risk` proposals
   (extends the existing move-proposal review surface, not a new
   parallel queue UI). Missions: acknowledge a check-in, review career
   gap, accept/dismiss a recommendation.
8. **NEW-02 coverage + gate** for both agents: scenario banks incl. a
   wellbeing-guardrail scenario (Success never contacts outside quiet
   hours/cap) and a consent-boundary scenario (L6 processing declined ⇒
   recompute skips the twin, no error, no stale data reused
   silently); green + steward-signed before any `deployed` transition.
9. **Load tests + NFR notes**: a load test for the nightly recompute at a
   realistic tenant/twin count (measure and record wall-clock, not just
   "it ran"); document the measured NFR numbers, don't claim dashboards
   that weren't built (unified NFR dashboards remain K3/K4 residual
   debt — this sprint's own measured numbers go in its decisions doc,
   not a claim of platform-wide dashboard coverage).

## Verifications
- **V1** no raw streams in L6 (schema audit): a repo-wide check
  confirms `TwinBehaviourProfile` and any other L6-tagged table hold only
  scalar/aggregate columns — no per-event table is L6-scoped, and the
  nightly job's own write path never inserts a raw event row into any
  twin-scoped table.
- **V2** risk alerts route to humans (propose): `flag_risk` firing for a
  fixture twin with `risk_score >= 0.70` produces a real
  `move_proposal_service` HITL item (not just a trace) and a real
  notification artifact; no code path auto-resolves a `flag_risk`
  proposal without a human decision.
- **V3** cognitive-budget equity report generates: a report over a
  fixture population shows risk-mission timing/caps applied evenly
  across student segments (no systematic bias in who gets contacted vs.
  suppressed by the budget gate) — scoped explicitly to the
  Student-Success gate, not a system-wide claim.
- **V4** NFR budgets measured + alerting: the nightly recompute's
  measured wall-clock/throughput at the load-test's fixture scale is
  recorded against a stated budget, with at least a log-level/alerting
  hook on budget breach (even if a full dashboard is out of scope this
  sprint — the measurement and the hook must be real).
- **V5** (this pack's own addition, matching the pattern of every prior
  K3 sprint pairing a functional check with the harness gate) harness
  green incl. wellbeing-guardrail + consent-boundary scenarios ·
  `pytest -m phase1` stable · migrations up/down/up clean on an isolated
  Postgres.

## DoD
V1–V5 green · constitution §15 (WS08), §18 phasing, §20 (rows 4 and 5
resolved: ESCO scope decision recorded, FERPA/compliance review
outcome recorded) marked updated · BOOK-10 nine-agents row updated (9/9
— all BOOK-10 Ch.3 cards now have a real agent config) · TRACEABILITY K4
row updated · decisions note recording: the risk-score heuristic's exact
weights (v1 policy knobs, not Book-specified), the ESCO-lite seed set and
what's explicitly out of scope, the cognitive-budget gate's cap/quiet-hour
numbers, and the measured load-test numbers.
