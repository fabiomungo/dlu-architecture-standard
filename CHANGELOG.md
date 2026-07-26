# Changelog

## Unreleased

- **Investor-demo readiness — all 4 items delivered** (2026-08-20,
  `dlu_builder_tk`, no new G-register item — a demo/pilot-readiness
  pass, not a regulatory gap): the nine named agents seeded since
  STX-14/15 had never been seeded outside the test suite — a fresh
  environment showed an empty agent registry and no Twin/GPS/
  credential/recognition data to demo.
  **Demo data** (`--scenario=ai_native_demo`, `backend/scripts/
  seed_demo.py`): seeds all 9 agents, 5 Student Digital Twins, a real
  GPS `fastest_path` scenario, a signed credential, a granted
  recognition claim, a Tier-1 pre-evaluation, viva evidence, a real
  advisor caseload, and one demo login per persona (student/instructor/
  admin/platform_admin) — reusing real service functions throughout,
  never hand-written rows bypassing business logic. Found and worked
  around two pre-existing `academic_gps_service.py` bugs along the way
  (`platform.course_catalog_items` has no creation migration anywhere;
  a `not_yet_available` reason string exceeds `PathScenario.reason`'s
  own 200-char column limit, aborting the 4-scenario batch insert) —
  both disclosed, neither fixed, out of this pass's scope.
  **Nav/persona alignment**: the AI-native student pages were
  completely unreachable from the app's own navigation — the component
  first assumed to be the live nav (`Sidebar.js`) turned out to be dead
  code with zero imports anywhere, and the actual live one
  (`PaperNav.js`) showed the identical course-authoring toolbar to
  every logged-in persona regardless of role, including a
  `platform_admin` with no click-path to Operator Plane at all (nested
  under an `admin`-only dropdown, a different role set than
  `operator_plane.py`'s own `_require_operator`) despite being fully
  authorized server-side. Fixed: persona-aware post-login redirect, the
  course-authoring toolbar hidden for a "pure" student/operator
  account, Operator Plane promoted to its own persona-gated link.
  **New pages**: IW4 Advisor Workspace and IW6 Operator Plane, both
  left backend-only by the large-tier backlog below, now have real
  frontend pages.
  All four personas rehearsed and screen-recorded end to end against a
  live local instance; `docs/INVESTOR_DEMO_WALKTHROUGH.md` is the
  resulting script. Found, disclosed, not fixed here: the entire
  `backend/domains/payments/` subsystem (financial holds, invoices,
  installments) has no Alembic migration anywhere — surfaces as a real
  500 on the Credential Wallet's clearance-checklist section, degrading
  to an honest empty state rather than crashing.

- **Category 3 infrastructure gaps — all 3 items closed** (2026-08-19,
  `dlu_builder_tk`, no new G-register item): closes the user's own
  stated priority order's last tier — "no real deployment target/IaC,
  alerting not reaching anyone, no automated backup schedule"
  (`docs/sprint_decisions_20260807_security_tenancy_hardening.md`
  lines 3-5/159-161).
  **Alerting** (2026-08-16): Prometheus's `alerting:` block, commented
  out since inception, now points at a new Alertmanager instance
  (staging + production compose); a new in-app webhook receiver
  (`POST /api/internal/alerts/webhook`, mirrors `internal.py`'s shared-
  secret auth pattern) always logs every received alert and optionally
  forwards to a configured Slack/webhook URL. Found while closing this:
  most pre-existing alert rules (all of the orphaned `prometheus-
  alerts-pi4.yml`, a real subset of the already-mounted `alerts.yml`)
  reference metrics that are never incremented anywhere or don't exist
  at all — only the 2 confirmed-live orphaned rule files (event-mesh,
  eval-harness) are wired in; `pi4`'s stays deliberately unmounted
  rather than faking working payment/workflow/AI-governance alerting.
  **Backup automation** (2026-08-17): a dedicated Celery beat+worker
  pair runs `pg_dump` nightly with the existing `scripts/backup_
  production.sh`'s own 7-day retention policy; `postgresql-client`
  added to `backend/Dockerfile` so `pg_dump` is actually present in the
  worker container. Found while closing this: `celery beat` has never
  run in ANY environment (dev/turnkey/italian run a plain worker only;
  staging/production run no Celery process at all) — all ~20 pre-
  existing `beat_schedule` entries have therefore never fired anywhere.
  Surfaced to the user directly (turning that on wholesale would
  activate 20 previously-dormant production tasks at once); the user
  chose a minimal, dedicated beat+worker pair scoped to backup only,
  leaving the shared scheduler exactly as dormant as before.
  **Deployment/IaC** (2026-08-18): new CI workflow builds and pushes
  `backend`/`frontend` Dockerfiles to GitHub Container Registry using
  the repo's own `GITHUB_TOKEN` — closes the loop `docker-compose.
  production.yml` already assumed existed (`${PRODUCTION_BACKEND_
  IMAGE}`/`${PRODUCTION_FRONTEND_IMAGE}`, previously referencing images
  nothing ever built; `docker compose --profile ops config` now exits 0
  with zero env vars supplied). Deliberately no Kubernetes/Terraform —
  BOOK-18 Ch. 6 already treats orchestrator choice as an ops decision,
  not an architecture one.
  15 new tests; every new/changed infra file verified with its real
  authoritative tool (`promtool`, `amtool`, `docker compose config`,
  `actionlint`), not just visual inspection; full raw-suite regression
  (52 failed/5 errors) confirmed the same pre-existing, unrelated
  baseline documented one day earlier in the large-tier-backlog summary
  below (68 failed/5 errors, same categories, zero file overlap). See
  `docs/sprint_decisions_20260819_category3_summary.md` (cross-
  references all 3 per-item docs).

- **Large-tier driver/integration backlog — all 6 deferred items closed**
  (2026-08-15, `dlu_builder_tk`, no new G-register item): closes the
  moderate/large-tier backlog deferred by the two prior driver/
  integration hardening passes below — LTI 1.3 full JWT verification,
  GPS `lowest_cost`, G7 regulation-year schema binding, Institution
  Workspace IW4 (Advisor Workspace) + IW6 (Operator Plane), and a full
  ESCO occupation crosswalk. Planned as one 6-item effort, executed and
  committed one item at a time in dependency order (G7 → GPS-cost → LTI
  → IW4 → IW6 → ESCO).
  **G7**: `program_courses.program_version_id` (nullable FK, two
  PARTIAL unique indexes — a naive 3-column unique would have silently
  allowed duplicates for the version-agnostic NULL case every existing
  row is in) makes NEW-04's regulation-year fingerprint tag actually
  change computed plans instead of being cosmetic-only; no backfill to
  a specific version, to avoid silently emptying a different cohort's
  requirement set.
  **GPS `lowest_cost`**: new `cost_per_credit` column, honesty-gated
  total (any course missing cost/credits data keeps the whole scenario
  `not_yet_available`).
  **LTI**: new `LtiPlatform` registration table + a real JWKS-fetch-and-
  cryptographically-verify path (`PyJWT`'s `PyJWKClient`) — no genuine
  verified-JWT pattern existed anywhere in this codebase before this;
  OIDC init now redirects to a registered platform's real auth endpoint
  when one resolves, falling back to the prior demo behavior unchanged
  otherwise.
  **IW4**: new `AdvisorAssignment` table (partial-unique-indexed for
  soft-delete/reassignment) + management-gated CRUD + an own-caseload-
  default composite (GPS hedges, risk stream); also fixed a real latent
  bug in `move_proposal_service.list_for_twin` — reached into a
  client-specific private `_cache` dict instead of the real
  `redis.asyncio.Redis` `scan_iter` interface every other cache-backed
  service already uses (verified this doesn't currently manifest in
  production, since `redis_client` is still always the same in-process
  mock everywhere, but would silently break the moment a real Redis
  client is ever substituted).
  **IW6**: driver-health snapshot reusing the three existing per-driver
  `CircuitBreaker` singletons directly (already process-wide), a new
  read-only `ConsumerGroup.mesh_lag()` sibling to `drain()` (zero
  `XREADGROUP`/`XAUTOCLAIM`/handler dispatch), and one new anonymized
  cross-tenant AI-spend aggregate — gated to `platform_admin`/
  `super_admin` only, no new role invented.
  **ESCO**: sourced REAL data from the official public ESCO REST API
  (confirmed reachable — the plan's own honest "if not fetchable"
  fallback did not apply) — 2,700 of ESCO's ~2,942 published
  occupations (91.8%), 104,504 real skill-relation rows, via a
  pagination quirk found and fixed empirically (ESCO's own `offset`
  param is a page index, not an item-skip count); replaces the
  STX-14/15 hand-curated 8-occupation `urn:dlu-esco-lite:` seed via the
  first CSV-bundled bulk-insert migration in this codebase;
  `career_gap_service._skill_has_competency`'s matching logic
  deliberately unchanged (verified via a direct sanity break-and-revert
  check); every live "ESCO-lite" doc reference across `backend/` swept
  and corrected, including the eval scenario bank and the Career
  Advisor agent's own persisted system prompt.
  All 6 migrations verified end-to-end against a disposable Postgres
  (clean upgrade/downgrade/re-upgrade round-trip); 51 new tests;
  `phase1` gate 104 passed/3 skipped/0 failed unchanged throughout; a
  full raw-suite run's 68 failures confirmed pre-existing and unrelated
  (zero file overlap, spot-checked across 5 failure categories). See
  `docs/sprint_decisions_20260815_large_tier_backlog_summary.md`
  (cross-references all 6 per-item docs).
- **Category 2 hardening — governed per-institution policy calibration
  infrastructure** (2026-08-12, `dlu_builder_tk`, no new G-register
  item): the user's own next pick, continuing the priority order (code
  gaps, then ops/business gaps, then infrastructure) into category 2 for
  the first time. Fresh re-verification confirmed almost all of category
  2 genuinely cannot be substituted for by code (external audit, legal
  sign-off, agent GA gating, live third-party credentials, real
  production PITR all remain exactly as open as before) — but surfaced
  one real, code-shaped gap: per-institution policy calibration was a
  MIXED bag, not a uniform gap. `ItemCalibrationParams`/
  `CompetencyEngineParams` already had a real, governed, versioned,
  institution-scoped-with-global-fallback override mechanism (just never
  populated per-institution); `move_policy_service.RISK_THRESHOLD`,
  `recommendation_service_v2`'s rank weights + `SERENDIPITY_QUOTA`, and
  `consolidation_service`'s salience weights had NO override mechanism at
  all. New `RiskPolicyParams`/`RecommendationPolicyParams`/
  `SalienceWeightParams` (one migration, same immutable-row shape as
  `ItemCalibrationParams`) close that gap — the knob, not the calibration
  decision itself, which remains a genuine steward/institution-authority
  call, unmade for any institution before or after this pass.
  `build_assessment` resolving the new `RiskPolicyParams` rippled into 8
  existing test files (every agent's `run_cycle`/`run_mission` passes
  through it) — found running the full suite, not assumed. Full
  regression clean (12 new tests plus 150 passed across the 8
  ripple-affected files; `phase1` gate: 104 passed, 4 skipped, 0 failed).
  See
  `docs/sprint_decisions_20260812_category2_policy_calibration_hardening.md`.
- **Driver/integration hardening II — small/contained tier from the
  moderate/large backlog** (2026-08-11, `dlu_builder_tk`, no new
  G-register item): continuation of the pass below — re-surveyed the
  deferred moderate/large backlog and found several premises wrong once
  verified: analytics revenue/quality metrics is genuinely large (not
  moderate as first labeled), Moodle grade-passback is smaller than
  "large" (real driver + ID-mapping tables already existed, just
  unpopulated), and the marketing domain isn't a sizing problem at all —
  its routers were never mounted in `main.py`, so its real, routed
  frontend pages have 404'd since they were built (flagged for removal
  per the user's own choice, nothing implemented). GPS `best_career_path`
  premise-corrected and wired onto the existing ESCO-lite seed;
  `lowest_cost` stays an honest gap with its stale "STX-12 brings them"
  reason replaced by the real blocker. New IW5 Steward Console composes
  already-real agent-governance data (scorecards, release-gate history,
  incident queue, an honest calibration-drift gap) behind a narrower role
  gate than IW1-3. New Moodle `assessment.completed` grade-passback
  consumer on the `n8n-bridge` group. A test-infrastructure side-quest
  found and fixed four independent, pre-existing bugs blocking a
  real-Postgres container test run (a `DLU_TEST_PG_URL` clobber, a
  `metadata`/`meta_data` column typo, a dead duplicate SQLite-only DDL
  block, and a missing pgvector test image) — never exercised this way
  before. G7 regulation-year and LTI full JWT verification were
  re-verified and confirmed at their original size, both still deferred.
  Full regression clean (3071 tests collected, 18 more than the prior
  pass's own new tests; `phase1` gate: 104 passed, 4 skipped, 0 failed).
  See
  `docs/sprint_decisions_20260811_driver_integration_hardening_ii.md`.
- **Driver/integration + data/model hardening — small/mechanical tier**
  (2026-08-10, `dlu_builder_tk`, no new G-register item): the user's own
  next pick after agent-governance hardening, scoped to the
  small/mechanical tier only (LTI full JWT verification, analytics real
  SQL, Moodle grade-passback ID-mapping, marketing domain, GPS ESCO
  crosswalk, G7 schema change, and Institution workspaces IW4-6 all
  explicitly deferred). `gateway_config_sync.delete_provider` was a
  no-op — now calls the real gateway `/model/delete`, keyed by
  `provider_id` to match how the provider was registered, wired into
  `soft_delete_provider` post-commit with fail-open error handling.
  `ai_management`'s Test-Skill preview always returned a literal
  MVP-stub string — now a real LLM invocation mirroring the working
  Test-Agent pattern. `graduation.predicted` premise-corrected: its own
  docstring claimed no producer existed, already false when written
  (`gps_worker.recompute_path_health_task` has emitted it since STX-07's
  first commit) — the real bugs were an overly-broad emission gate
  (fired on nearly every recompute, predicting nothing — tightened to
  require completion within 1 term) and a dormant consumer stub, now
  wired to enqueue a real career-gap-refresh task. A critical, unrelated
  bug found first and fixed separately while researching LTI: a live,
  unauthenticated open redirect in `lti_oidc_init` (fixed with a
  same-origin/bare-path allow-list, committed separately). A live decoy
  found during research and separately confirmed for removal:
  `/advisor/dashboard` rendered hardcoded fake KPIs and two fabricated
  named students unconditionally, as if real — replaced with an honest
  not-yet-available state; the real underlying gap (no
  advisor-assignment relationship exists anywhere in this data model) is
  disclosed, not fixed. Full regression clean (3053 tests collected, 19
  more than the prior pass's own new tests; `phase1` CI gate: 104
  passed, 4 skipped, 0 failed, identical to the prior pass's own
  baseline). See
  `docs/sprint_decisions_20260810_driver_integration_hardening.md`.
- **Agent governance hardening — mission-budget gate generalized to all
  9 agents** (2026-08-09, `dlu_builder_tk`, no new G-register item):
  `ace_service.run_mission`'s BOOK-09 Ch. 6 budget check special-cased
  exactly two of the nine DAS agents (`learning_coach`, `student_success`)
  — the other seven had zero volume/rate protection on proactive
  missions. Replaced the `if/elif` ladder so every agent calls
  `mission_budget_service` (quiet hours + a daily-contact cap);
  `learning_coach` alone kept its own dedicated branch through
  `coach_etiquette_service` to preserve an existing test's patchable
  call site. Closes BOOK-09 Ch. 6 point 4 (budget lines) only —
  need-based priority allocation, an equity guardrail, and per-learner
  floors (Ch. 6 points 1-3) remain genuinely unbuilt, documented as such
  rather than implied closed. A real bug found first and fixed
  separately: re-verifying a stale "unreachable in production" docstring
  claim on `synthesize_blackboard` (carried forward, uncritically, into
  a prior hardening pass's own reasoning) found `_act_l4` IS reachable
  since STX-10 and never threaded its own `tenant_id` through — every
  real `consultation_deadlock` proposal was filed with `tenant_id=
  "unknown"`, which that earlier pass's own defense-in-depth check would
  then 404 the twin's own legitimate proposal against. Also corrected an
  initial research premise before acting on it:
  `consolidation_service`'s nightly job makes zero LLM calls (pure
  deterministic token-matching + DB row lifecycle) — applying the
  learner-contact cap gate there would have been a category error, left
  functionally untouched with its docstring corrected instead. Two other
  researched sub-items (per-move calibration + steward alerts;
  misbehaviour escalation ladder) remain open, both converging on the
  same missing piece — a real steward role + review surface — documented
  but not built this pass. See
  `docs/sprint_decisions_20260809_agent_governance_budget_hardening.md`.
- **Consolidation debt hardening — dead code removed, a much bigger
  audit-logging bug fixed** (2026-08-08, `dlu_builder_tk`, no new
  G-register item): deleted two dead-code AI-governance attempts
  (`backend/domains/ai_governance/`, zero migration ever created its
  tables; 6 dead PI-1 models from `models_ai_governance.py`, keeping the
  live `AIProvenance`) and the dead `PagoPAStubDriver` (kept the
  still-live `BolloPaymentStatus` dataclass NEW-12's real driver
  imports). Badge/credential research found a quadruple duplication,
  not the documented triple — deleted the fully-dead
  `backend/domains/badge/` (singular) + its broken frontend
  `BadgeWallet` widget (silently 404ing on every page that rendered it,
  since `badgeAPI.js` called the unregistered plural
  `backend/domains/badges/` route); left the plural domain and
  `services/dlu_badge`-vs-monolith as documented open architecture
  decisions. The real finding: the legacy audit trail was silently
  near-completely broken — nearly every `AuditService.log_action` call
  site never awaited it (an `async def`, silently a no-op),
  `log_action`'s own internal `execute()`/`commit()` calls weren't
  awaited either (no-op with `AsyncSession`, used by `auth.py`'s OIDC
  routes), `AuditLoggingMiddleware` had a permanent `lambda: None`
  session-factory placeholder since it was added, and — found only by
  testing against a real disposable Postgres — the table was missing
  `endpoint`/`http_method` columns in every definition (raw SQL
  bootstrap scripts and the ORM model) and `log_action` hardcoded the
  wrong Postgres metadata column name (`meta_data` instead of the real
  `metadata`, misreading an ORM attribute alias). Fixed all of it,
  adopted `platform.audit_logs` into the Alembic chain (same
  legacy-script-only status as `legal_holds`/`tenant_settings`/
  `rate_limits`), added a nightly partition-maintenance Celery beat job
  (the table's Postgres-native monthly partitioning had no partitions
  past March 2026), and mounted NEW-15's hash-chained audit fabric REST
  API (`backend/api/routes/audit.py`, fully built and tested but never
  mounted) — with `require_admin()` added to every route first, since it
  had none and would otherwise have been a new cross-tenant
  vulnerability (verified live: unauthenticated → 401, non-admin → 403).
  See `docs/sprint_decisions_20260808_consolidation_debt_hardening.md`.
- **Security/tenancy hardening — cross-tenant leakage fuzz cache dimension
  closed** (2026-08-07, `dlu_builder_tk`, no new G-register item):
  `move_proposal_service.store()`'s Redis-backed store carried no
  `tenant_id` anywhere (only `twin_id`/`agent_key`) — added as a required
  parameter, threaded through all 10 production call sites +
  3 test call sites; `ace.py`'s `_require_own_proposal` now checks
  `tenant_id` in addition to the pre-existing `twin_id` check (K3/K4
  hardening pass) — deliberate defense-in-depth, proven via a dedicated
  forged-record test. Also adopted `platform.rate_limits` into the
  Alembic chain (same legacy-script-only status `legal_holds`/
  `tenant_settings` had) — verified end-to-end against a disposable
  Postgres (full migration-chain replay, idempotency re-run, downgrade/
  upgrade round-trip) — and, via that same live-Postgres verification,
  found and fixed a real production bug: `RateLimitService.
  check_rate_limit` compared a timezone-aware Postgres `TIMESTAMPTZ`
  value against naive `datetime.utcnow()`, raising `TypeError` on the
  second call for any identifier+endpoint — would have hard-failed every
  second login/registration/password-reset attempt within a rate-limit
  window in any real deployment, fully masked by mocked unit tests that
  never exercised a real driver. NEW-17's Tier-1 pre-evaluation limiter
  was reviewed for coupling to `RateLimitService` and deliberately left
  self-contained — its business-data-derived rolling-window count has no
  drift risk, and genuine coupling would change actual block semantics
  (a product policy call, not a code gap). Streams dimension of the fuzz
  suite remains open. See
  `docs/sprint_decisions_20260807_security_tenancy_hardening.md`.
- **BOOK-14A** — Credit Recognition & Pre-Evaluation Framework (Italy & USA),
  from the comparative regulatory analysis: jurisdiction **RulePacks**
  (IT-CFU with DM 931/2024 caps 48/24, SSD matching, fraction tolerances,
  obsolescence, ITS/master rules, fees; US-SCH with PLA/CAEL, ACE/NCCRS,
  residency, exclusions), **G16** three-tier pre-evaluation for registered
  non-enrolled prospects (instant AI estimate + council HITL + Validated
  Pre-Evaluation Statement as signed credential), badge-to-credit automation
  (Bestr→ESSE3 pattern on the running OB 3.0 Badge Service), equivalence-
  precedent memory, curricular-drift answer (historic-syllabus endpoint on
  immutable CatalogEditions). Sprint **NEW-17** (K4). Register G1–G16.
- **K5 hardening — Erasure e2e chain closed** (2026-08-05, `dlu_builder_tk`,
  no new G-register item): `erasure_service.request_erasure` finally
  calls `credential_revocation_service.revoke_or_suspend(purge_pii=True)`
  (real since STX-13, zero callers until now) and executes BOOK-06 Ch.
  9.3's full erasure procedure — anchor soft-delete, immediate hard purge
  of L5 (Career)/L6 (Behaviour)/L7 (AI memory + episodic summaries), a
  deferred L3 (Competency) purge (new `purge_after` column + a nightly
  `erasure_purge_worker` — no Book anywhere specifies the actual
  "retention schedule" duration BOOK-06 refers to, so this is a
  documented 30-day default, not a silent guess), a structurally-ready
  L4/Neo4j no-op hook, a Redis move-proposal cache flush, and dual audit
  emission (the DAS hash-chained fabric + the legacy `audit_logs`
  `user.data_delete` action — found to be referenced by
  `compliance_service`'s own GDPR report query but never once emitted
  anywhere before this). Gated on the existing `ComplianceService.
  get_legal_holds` (BOOK-19 RACI: DPO owns retention/erasure exceptions)
  rather than a new approval workflow, which surfaced `platform.
  legal_holds` had existed only via a standalone `sql/compliance_schema
  .sql` bootstrap script, never any Alembic migration — adopted into the
  chain for the first time this pass. A real bug found and fixed while
  wiring `TwinSnapshot`'s new narrow, audited immutability bypass:
  committing the purge AFTER the authorization context manager had
  already exited meant the flush-time `before_delete` listener saw
  authorization already revoked and rejected its own legitimate caller.
  **Same-day follow-up, all three of this pass's own carried gaps
  closed:** the "no twin-owned Neo4j data exists" premise behind the L4
  no-op was found WRONG (`kg_overlay_sync.py` — live, registered on
  `kg-sync`, not dead code — writes real `(:Student {twin_id})` nodes) and
  fixed with a real `DETACH DELETE`, proven against an actual Neo4j
  instance (a new `@pytest.mark.integration` test, not mocked); the
  30-day L3 retention window is now per-tenant overridable via
  `platform.tenant_settings.erasure_l3_deferred_purge_days` (that table
  also adopted into the Alembic chain for the first time, same legacy-
  script-only status `legal_holds` had); a self-service `/student/privacy`
  frontend was built and browser-tested end-to-end (confirm-phrase gate,
  real request round-trip verified server-side, zero console errors). 9
  tests total, full regression clean. See
  `docs/sprint_decisions_20260805_k5_erasure_hardening.md`.
- **CORS preflight fix** (2026-08-04, `dlu_builder_tk`): `CORSMiddleware`
  was registered innermost (added first), so `TenantContextMiddleware`'s
  own OPTIONS short-circuit (a deliberate skip of tenant DB resolution on
  preflight) returned a bare 204 with zero `Access-Control-Allow-*`
  headers — silently breaking any cross-origin dev split of frontend/API.
  Found during NEW-18's own browser-testing pass, fixed same-day by
  reordering `app.add_middleware()` so `CORSMiddleware` is outermost.
  Verified via a standalone `TestClient` script plus a 161-test
  middleware/CORS/tenant/auth regression sweep — zero regressions.
- **NEW-18 executed — closes NEW-17's own carried-gaps note** (2026-08-04,
  `dlu_builder_tk`): Tier-2/registrar (`RecognitionCouncilDesk.js`) and
  badge-rule-authoring (`BadgeCreditRuleAdmin.js`) frontends — neither
  existed, both mirror the established `RegistrarDesk.js`/
  `LLMQuotaRules.js` Table+Modal+Form shape; two new read routes
  (`GET /api/pre-evaluations/registrar-queue`,
  `GET /api/committees?kind=`) the UIs needed; NEW-11's ESSE3 driver now
  consumes `credential.recognized` via a new `push_recognized_credit`
  method + `Esse3CredentialSyncLog` + an `n8n-bridge` consumer
  (`synced`/`no_mapping`/`failed`, the last never raised into the mesh);
  the Tier-1 frontend (`PreEvaluationWorkspace.js`) actually
  runtime-tested in a live browser for the first time — found (and,
  same-day, fixed — see the CORS preflight fix entry above) a
  pre-existing CORS bug; full Tier-1→Tier-2 queue→create/deactivate
  lifecycle exercised live end-to-end. 8 new
  tests, full regression clean. Anti-gaming rate-limit integration,
  `EquivalenceRule` consortium sharing, and the outbound
  historic-syllabus endpoint remain open (NEW-17's own carried debt,
  untouched by this sprint). See
  `docs/sprint_decisions_20260804_new18.md`.
- **NEW-17 executed — G16 resolved, register complete at G1–G16**
  (2026-08-03, `dlu_builder_tk`): `RecognitionRulePack`/
  `CreditPreEvaluation`/`EquivalenceRule`/`ExternalSyllabusRecord`/
  `BadgeCreditRule`. Tier 2 uses a dedicated `RecognitionCommitteeVerdict`
  (NEW-06's `CommitteeVerdict.thesis_id` is `NOT NULL` — concretely
  thesis-coupled despite its forward-looking docstring); reuses NEW-06's
  generic `Committee`/`CommitteeMember` formation only. Validated
  Pre-Evaluation Statement issued via STX-13's `_sign_and_persist`
  directly. Conversion executes the already-decided verdict at
  enrollment — no re-evaluation. Badge auto-convalida matches STX-13's
  live `credential_templates`, not the two dead badge implementations.
  25 tests green; migration verified up/down/up; full regression clean
  (`pytest -m phase1` stable at 104/3; combined NEW-17+STX-12+NEW-06+
  STX-13+NEW-16+STX-14/15: 108 passed). K4 pack now fully delivered
  (7/7 items — see `implementation/roocode/K4/README.md`).
- **K1 phase completed** in `dlu_builder_tk` (STX-01…05 ✅ per sprint status
  notes): twin core + identity_map, TwinContextService, Event Mesh,
  Competency Engine, KG v2.0 + `dlu-core.yaml`.

- **K2 prompt pack generated** (2026-07-16, post K1 exit gate):
  `implementation/roocode/K2/` — README (order: NEW-01 → STX-06 → NEW-03,
  NEW-02 in parallel as the GA gate; exit gate per TRACEABILITY K2 row) +
  self-contained prompts NEW-01 (move catalog binding, BOOK-09 Ch. 3 /
  BOOK-10 Ch. 2), STX-06 (PDDAEL runtime + one voice + Discovery + WS00
  triad, BOOK-09 / BOOK-17), NEW-02 (scenario bank + 3 grader tiers +
  lifecycle gate + crisis protocol zero-tolerance, BOOK-11 Ch. 5–6),
  NEW-03 (M1–M4 memory stores + consolidation R8 + consent amnesia,
  BOOK-12). Combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K2_PROMPTS.md`.
  Implementation may begin with NEW-01 (‖ NEW-02).

- **STX-05 executed — K1 COMPLETE** (2026-07-16, `dlu_builder_tk`):
  Knowledge Graph v2.0. Idempotent Cypher migration (`make kg-migrate`):
  A8 `REQUIRES`→`NEEDS_ASSET`, A9 →`ALIGNED_TO {strength}` (aliases
  flagged one minor release), v2.0 label constraints, `SchemaMeta` stamp.
  Student overlay via batched `kg-sync` consumers (KNOWS/EVIDENCES,
  DEFER-flush ≤100/pass, ack-after-flush, tenant-scoped). Definition-tier
  Competency/Framework sync (fire-and-forget preserved). **Ontology
  registry seeded**: `architecture/ontology/dlu-core.yaml` + lint in both
  repos' CI; A1-S1 staging gate live. `frontier`/`gap` canonical queries.
  V1–V7 green (incl. live-Neo4j idempotency/parity/tenant-fuzz and
  250-events→≤3-flushes batching). Registers: A1-S1 ✅, A8 ✅, A9 ✅.
  **All five K1 sprints delivered — K1 exit report can be assembled.**

- **STX-04 executed** (2026-07-15, `dlu_builder_tk`): Competency Engine.
  Deterministic §5.3 confidence (`Σ score·weight·recency·trust / Σ weight`)
  with versioned, immutable `competency_engine_params` seeded from BOOK-15
  §4.1; status machine with decay hysteresis → `expired` checkpoint (daily
  beat); `verified` = HITL `verify()` only (ADR-0012, negative-tested);
  `register_evidence` as the single writer entrypoint (STX-08 intake);
  CASE 1.1 idempotent import + round-trip export preview; student rows pin
  `framework_version` (Review M1); `/api/competencies` routes +
  `competencyAPI.js`; all mutations emit `competency.updated/mastered`,
  `evidence.recorded` via the STX-03 outbox. V1–V6 green (8 golden cases
  ≤1e-6). BOOK-04 C4 and BOOK-06 L3 Annex rows → ✅.
  K1 remaining: STX-05.

- **STX-02 executed** (2026-07-14, `dlu_builder_tk`): TwinContextService —
  the single door to student context. Purpose-audited reads, BOOK-06 Ch. 6
  entitlement matrix enforced in code (data-driven, denials audited),
  consent gating (Ch. 9, learner_self bypass per the Open Learner Model),
  per-layer version-keyed Redis cache, immutable `twin_snapshots` on
  lifecycle transitions, `/api/twin` routes (tenant-scoped), tutor context
  adapter with zero regression, `consent.changed` producer wired to the
  STX-03 mesh, twin-sync consumer now routes through
  `bump_version_sync`. V1–V6 green; BOOK-06 Annex A context-service and
  snapshot rows → ✅; constitution §4.4 marked implemented.
  K1 remaining: STX-04, STX-05.

- **STX-03 executed — THE KEYSTONE** (2026-07-14, `dlu_builder_tk`):
  Academic Event Mesh delivered. Transactional outbox `domain_events`
  (migration `20260714_1100`), closed taxonomy consolidating constitution
  §7.3 + BOOK-04 Ch. 7 (41 types, `event_taxonomy.py` — EVENT_CATALOG.md
  superseded for kernel events), Redis Streams relay (2 s beat, ≥7-day
  XTRIM retention), 5 consumer groups with exactly-once side effects,
  XAUTOCLAIM recovery, dead-letter stream and Prometheus lag alerting.
  twin-sync wired (`profile.updated` → twin_version bump); producers:
  mastery.updated, activity.recorded, course.* (governance workflow),
  legacy EventService dual-publish (strangler). OTel trace propagated
  producer → consumer via span links. V1–V7 green; register A6 closed;
  BOOK-03 Annex A Event Mesh row → ✅. Design decisions:
  `dlu_builder_tk/docs/sprint_decisions_20260714_stx03.md`.
  Next: STX-04 and STX-05 unblocked (STX-02 still pending).

- **STX-01 executed** (2026-07-14, `dlu_builder_tk`): Student Twin core
  models + Competency Graph tables + identity reconciliation. **ADR-0014**
  accepted — identity reconciliation Option A (additive `user_guid` +
  backfill + dual-write; mapping exclusively in
  `backend/services/identity_map.py`). Constitution §13.4 marked
  "decided: Option A". V1–V6 green; reconciliation report at
  `dlu_builder_tk/reports/stx01_identity_reconciliation.json` (100%
  matched, 0 orphans). Next: STX-02 (STX-03 may run in parallel).

- **G15** (catalog as legal contract + explorable what-if representation):
  `CatalogEdition` aggregate (04), `simulate_scenarios` GPS mode (14),
  catalog legal document (16 §6.4a), public explorer + FW1 authoring (17),
  sprint **NEW-16** (20); register now G1–G15.
- **K1 prompt pack generated**: `implementation/roocode/K1/` (README +
  STX-01…05 self-contained prompts with V-suites, dependencies, exit gate);
  combined copy in `dlu_builder_tk/docs/ROOCODE_DAS_K1_PROMPTS.md`.
  Implementation phase may begin with STX-01 (‖ STX-03).

## 1.0.0-draft (das-v1.0-draft) - 2026-07-14

### The Masterbook — complete

- **BOOK-00 v2.0** — Executive Vision & Manifesto: conformance model
  (DAS-Core/Intelligent/Certified), RFC 2119 normative language, Seven
  Canonical Questions, manifesto principles with tensions, 13 ADRs, expanded
  standards alignment (1EdTech, EU AI Act), Human Institution / Trust &
  Integrity / Viability chapters, full 20-book plan, **Annex A Turnkey
  baseline** (descriptive-where-running doctrine, source-of-content rule).
- **BOOK-01…20 v1.0** — full Masterbook per the BOOK-00 Ch. 16 plan:
  philosophy (01), institution theory (02), AOS (03), domain model (04),
  ontology (05), twin trilogy (06/07/08), AI spine (09/10/11/12),
  knowledge network (13), GPS (14), assessment & evidence (15),
  credentials & trust (16), experiences (17), technical/Turnkey integration
  (18), governance/security/compliance (19), implementation blueprint (20).

### Registers

- **A-register A1–A12** (structural/semantic anomalies) — all declared and
  closed with owners (incl. A8 `REQUIRES` collision, A9 alignment naming,
  A10–A12 FEX v1.3 bindings).
- **G-register G1–G14** (regulatory/functional gaps from ESSE3, ANVUR and US
  accreditation verifications) — all resolved or owned: appelli (G2), thesis
  (G5), committees (G6), regulation-year (G7), ANS/SUA-CdS (G8), certificates
  (G9), Diploma Supplement (G10), clearance (G11), **US RSI (G12)**, identity
  verification (G13), **ANVUR DE/DI telematic regime (G14)**.
- **Sprint set** STX-01…15 + NEW-01…15 in phases K1–K5 with verification
  cards and conformance exit gates (BOOK-20).

### Review & remediation

- **MASTERBOOK-REVIEW v1.0** — independent critical review (completeness,
  internal/external consistency): verdict *approved with reservations*;
  blocking findings **R1** (event-taxonomy registration: session/thesis/
  committee families) and **R2** (G14 DE/DI) **applied**; R4/R5 scheduled
  into K1 scopes.

### Catalog annex

- **BOOK-10A** — AI Workforce, Skills & MCP Catalog: exhaustive phased roster
  (24 agents across student/faculty/institutional/ops domains, 44 typed skills
  in 12 categories, 19 MCP servers internal/generic/external), usage modes
  (scoping, preset classes, quota classes), seeded-to-target mapping for the
  running `ai_university_defaults` (3 MCP servers, 10 skills, 4 agents),
  bilingual and least-privilege doctrines. Prerequisite refinement for the K1
  prompt pack.

- **BOOK-10B** — AI Execution Framework: three-plane model
  (definition/execution/observation), resolution pipeline with `ctx_hash`
  reproducibility token, skill execution engine, MCP integration layer
  (session manifests, server-side entitlements, circuit breakers),
  declarative mission runtime (generalizing the running orchestrator),
  five-tier testing (T1–T5 on mock-LLM/test-endpoints/harness/test-tenant),
  governed deployment with canary/shadow and seconds-scale kill switch, and
  the **unified execution record** (one query = full causal story; learner
  "why?" and auditors read the same records). Explicit ACP reuse-vs-extend
  map — the running control plane is the foundation.

### Apparatus (R3)

- `MASTERBOOK-INDEX.md` — volume map, reading paths, the Five Ideas.
- `TRACEABILITY.md` — G/A/sprint/conformance cross-matrix.
- `GLOSSARY.md` — unified normative glossary (≈130 terms).
- `scripts/sync-masterbook.sh` + `docs/masterbook/` — MkDocs rendering of the
  Masterbook (generated copies; root is source of truth).
- MkDocs nav: Masterbook section wired.

### Cross-repo (sync rule)

- `dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` (Turnkey
  implementation profile) amended in lockstep: A8 prerequisite canonicalization
  (`PREREQUISITE_FOR`), event-taxonomy additions (R1).

## 0.1.0 - 2026-07-12

- Created the initial DLU Architecture Standard repository.
- Added MkDocs Material configuration.
- Added initial manifesto, architecture-standard, reference-architecture and Turnkey sections.
- Added ADR, RFC, workspace and RooCode scaffolding.
