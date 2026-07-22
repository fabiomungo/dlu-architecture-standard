# Sprint NEW-14 — Cost Attribution + Economies
### DAS K5 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-10 (`three_economies_service.py`/`program_health_service.py` — the I2/I3 composites this sprint extends, not rebuilds) · no G-register item (a BOOK-20 blueprint sprint, cross-cutting instrumentation — confirmed absent from TRACEABILITY's G1-G16 register)

## Role
`backend-dev` extending the existing, already-production-grade ACP
Gateway usage-accounting infrastructure with a per-engine/process-area
cost-attribution rollup (BOOK-02 Ch. 8.1; BOOK-03 Ch. 7) and computing
`C_learner` unit economics (BOOK-02 Ch. 8.1) into the I2/I3 composites
NEW-10 already built. Lower design risk than NEW-11/12/13 — the Book
fully specifies the shape and the infrastructure to extend already
exists — but real scope-honesty discipline is required (Context points
2-4) to avoid silently fabricating data that doesn't exist yet.

## Context — read before coding
1. **Two distinct Book concepts, one sprint title — do not conflate
   them.** (a) The **three economies** (BOOK-02 Ch. 3.1: Knowledge,
   Trust, Attention — NOT a learner/institutional/instructor-time split)
   are ALREADY fully panelled by NEW-10's
   `backend/services/three_economies_service.py` — this sprint does
   **not** rebuild that panel, it only feeds the gaps that panel and
   `program_health_service.py`'s I2 composite already explicitly flag
   (Context point 5). (b) **Unit economics** (BOOK-02 Ch. 8.1,
   `C_learner`) is a separate, previously entirely un-modeled concept
   this sprint builds from scratch.
2. **`C_learner`, verbatim formula (BOOK-02 Ch. 8.1):**
   `C_learner = C_inference + C_content_maint + C_human_attention +
   C_platform + C_compliance` — "unit economics per active learner per
   term; the Institution Twin MUST compute these continuously."
   **Confirmed: only `C_inference` has any real backing data anywhere in
   this codebase** (`llm_usage_logs.cost_usd`, real USD, already
   populated by the live ACP Gateway usage callback). The other four
   terms have ZERO instrumentation anywhere (no loaded-rate/salary
   table, no infra-cost allocation, no compliance-cost tracking) — this
   sprint computes `C_learner` HONESTLY as real `C_inference` plus four
   `not_yet_available` sub-fields, mirroring NEW-10's own
   Attention-economy honesty convention exactly (`mentorship_hours_
   per_learner`/`hitl_queue_health`/`belonging_index` all
   `not_yet_available` there, for the identical reason: no backing data
   exists). **Never fabricate the other four terms as zero or as an
   estimate presented as measured** — an honest partial sum, clearly
   labeled, is correct; a complete-looking number that silently drops
   four of five terms is not.
3. **Per-engine/process-area cost attribution, verbatim (BOOK-02 Ch.
   8.1):** *"`C_inference` observable today per tenant/agent/model via
   the ACP Gateway usage accounting... inference cost MUST be
   attributable per engine and per process area (P0x) — unattributable
   AI spend is a governance defect."* "Engine" = the BOOK-00 ten kernel
   engines (ACE, Knowledge, Competency, Assessment, Credential,
   Academic GPS, Digital Twin, Event Mesh, Identity, AI substrate);
   "process area" = P01-P08. **Per-agent attribution ALREADY EXISTS as
   a string convention** — `backend/services/llm_client_factory.py`
   (the mandatory, centralized "all AI-calling services MUST use this
   factory" client) already tags `service_type=f"agent:{agent_slug}"`
   for the nine seeded agents, plus flat strings (`course_factory`,
   `kg_nlp`, `quiz_gen`, `legacy_import`, `media_gen`, `tutor`, etc.) for
   authoring/content-pipeline calls. **No per-engine ROLLUP dimension
   exists** — this sprint's job is a mapping layer over already-captured
   `service_type` values, never a new instrumentation pass across dozens
   of call sites.
4. **Margin per program — a real cross-domain join, not "just extend
   the gateway."** BOOK-02 Ch. 12 (Executive Scorecard) and BOOK-08 Ch.
   4.1 (I2 economics: `C_learner · contribution margin · AI cost
   share`) both require joining computed AI-cost data against REVENUE
   (tuition per program, `backend/domains/payments/` — confirmed
   entirely separate, revenue-only, zero cost-of-delivery concept
   anywhere in that domain today). This join is genuinely new logic,
   more substantive than the attribution-rollup piece, even though both
   are fully Book-specified — do not underscope it as "just a read."
5. **Named, pre-existing gap this sprint closes (`program_health_service
   .py`, verbatim, already in the codebase):** `economics = _not_available(
   "No cost-attribution/contribution-margin model exists anywhere in
   this codebase (confirmed absent — no cost_per_student/program_cost/
   cost_attribution field in any models_*.py file).")` — this is I2's
   own pre-written stub for exactly this sprint's deliverable.
   `three_economies_service.py`'s own remaining `not_yet_available`
   fields (`grounding_health`, `verification_sla`,
   `mentorship_hours_per_learner`, `hitl_queue_health`,
   `belonging_index`, `coherence`) are **NOT** this sprint's job — they
   have no cost/economics relationship and stay open, unchanged, for
   whichever future sprint has the backing data (Moodle instructor
   events, a verification-timestamp column, etc.) to close them
   honestly.
6. **Existing infrastructure to extend, never rebuild:**
   `backend/database/models_llm.py::LlmUsageLog` (append-only, already
   tracks tenant/institution/college/department/course/user, real
   `cost_usd`, `service_type`, `model`, `provider_id`) and
   `QuotaUsageSnapshot`; `backend/api/routes/internal.py`'s
   `/api/internal/llm-usage-callback` (the idempotent LiteLLM callback
   writing these rows — `service_type`/`scope_type`/`scope_id` come from
   caller-supplied metadata, defaulting to `"default"`/`"tenant"` if a
   call site forgets to tag them — **there is no current alert on this
   silent default**, which is exactly BOOK-20's V1 requirement);
   `backend/api/routes/llm_usage.py` + `llm_usage_service.py` (an
   already-mature dashboard API: `/summary` by_service/by_model/
   by_provider, `/breakdown?group_by=...`, `/export`, `/quota-status`) —
   adding `group_by=engine` is the natural, low-risk extension point,
   not new architecture. Note a pre-existing minor wrinkle: `scope_type`
   is enumerated inconsistently across `LlmQuotaRule`
   (org/college/department/course) vs. `GatewayVirtualKey`/
   `QuotaUsageSnapshot` (tenant/college/department/agent/user) — resolve
   the engine dimension via a pure read-time mapping table, never by
   adding a new migrated scope value to either enum (would touch three
   tables for a reporting-only concern).
7. **Surfaces:** extend the existing `InstitutionDashboard.js`/`GET
   /api/institution/dashboard` (NEW-09/10's own established convention:
   extend, don't build a disconnected page) with the economics view, and
   extend `llm_usage.py`'s existing dashboard routes with the
   engine-attribution breakdown — no new top-level page.

## Deliverables
1. **Engine/process-area attribution mapping** — a static, versioned
   mapping (`backend/services/cost_attribution_service.py` or a config
   constant) from `service_type` values (both the `agent:{slug}` form
   and the flat authoring-pipeline strings) to one of the ten BOOK-00
   engines + one of the eight P0x process areas. A `service_type` with
   no mapping entry is an explicit, alertable **unattributed** case
   (Verification V1) — never silently bucketed into a default/"other"
   engine.
2. **Unattributed-call alert** — extend the usage-callback path
   (`internal.py`) or a scheduled sweep over recent `LlmUsageLog` rows
   to flag any row whose `service_type` has no attribution-mapping
   entry (Context point 6's silent-default gap) — surfaced as an
   I4/I5-visible alert, matching this codebase's existing
   "governance defects are board-visible by construction" posture
   (mirrors NEW-13's AI Act register red-item visibility).
3. **`C_learner` computation** — a new function (institution/program ×
   term scoped) summing real `C_inference` (aggregated `LlmUsageLog
   .cost_usd`) with the four other terms explicitly returned as
   `not_yet_available` (Context point 2) — never a fabricated estimate.
   Feeds I2's existing `economics` stub in `program_health_service.py`.
4. **Contribution margin / AI cost share** — the revenue-join
   (Context point 4): tuition revenue per program (from the existing
   payments/finance domain) minus computed AI-inference cost for that
   program's term, surfaced alongside `C_learner` in I2. AI cost share =
   `C_inference / revenue` (or a documented honest partial if program-
   level revenue attribution itself has gaps — degrade honestly, never
   silently assume 100% attribution coverage).
5. **Three-economy dashboard feed extension** — wire the engine-
   attribution rollup and `C_learner`/margin figures into the EXISTING
   `three_economies_service.py`/`program_health_service.py` read paths
   as new, clearly-labeled fields — never a parallel dashboard, never a
   restructuring of the already-shipped Knowledge/Trust/Attention panel.
6. **`llm_usage.py` extension** — `group_by=engine` and
   `group_by=process_area` options on the existing `/breakdown` route,
   reusing Deliverable 1's mapping.

## Verifications
- **V1** every gateway call attributed, unattributed = alert: a fixture
  `LlmUsageLog` row with an unmapped `service_type` triggers the
  Deliverable 2 alert; a fixture row with a mapped `service_type`
  produces no alert and rolls up correctly under its engine/process
  area.
- **V2** `C_learner` reconciles with usage snapshots: a fixture set of
  `LlmUsageLog` rows for a given institution/program/term produces a
  `C_learner.c_inference` value that exactly matches the sum of those
  rows' `cost_usd`, with the other four sub-fields explicitly
  `not_yet_available` (never zero, never a fabricated placeholder
  number).
- **V3** margin-per-program honesty: a fixture program with known
  revenue and known AI-inference cost produces the correct contribution
  margin and AI-cost-share figures; a program with incomplete revenue
  attribution surfaces that incompleteness explicitly rather than
  computing a margin against a silently-assumed-complete revenue figure.
- **V4** structural: `three_economies_service.py`'s existing
  Knowledge/Trust/Attention field set and values are byte-identical
  before/after this sprint for any fixture unrelated to cost/economics
  (a regression guard proving this sprint is additive, never a
  restructuring of the already-shipped panel).
- **V5** the `scope_type` enum inconsistency (Context point 6) is
  resolved via the Deliverable 1 mapping table only — no migration
  touches `LlmQuotaRule`/`GatewayVirtualKey`/`QuotaUsageSnapshot`'s
  existing scope columns (grep-based structural check).

## DoD
V1–V5 green · `pytest -m phase1` green · migration (if any — Deliverable
1's mapping may be a pure code constant needing no migration at all;
only add one if a persisted table is genuinely required, e.g. for
per-tenant engine-mapping overrides) `upgrade`/`downgrade`/`upgrade`
verified on an isolated throwaway Postgres if a migration exists ·
BOOK-02 Ch. 8.1 / BOOK-08 Annex A (I2 economics, I4 per-engine
attribution) / BOOK-03 Ch. 7 Annex updated from 🔵/⚪ to ✅ with this
sprint's implementation detail, explicitly noting `C_learner`'s
honest 1-of-5-terms scope · decisions note
(`docs/sprint_decisions_YYYYMMDD_new14.md`) recording: the engine/
process-area mapping table design, the `C_learner` partial-sum honesty
decision (and exactly which four terms remain `not_yet_available` and
why), and the margin-per-program revenue-join scope · next: **NEW-15**
turns this sprint's own V1-V5 (and every other K5 sprint's
verifications) into a permanent, CI-runnable conformance suite.
