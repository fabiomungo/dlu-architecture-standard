# K5 Profiles & Compliance — Exit Report

**Phase:** K5 (BOOK-20 roadmap, final phase) · **Target repo:** `dlu_builder_tk`
**Executed:** 2026-07-29 → 2026-08-02 · **Sprints:** NEW-11, NEW-12,
NEW-13, NEW-14, NEW-15 (5/5 — all authored K5 sprints executed)

**This is the last exit report in the entire DAS Masterbook
implementation blueprint.** Per NEW-15's own explicit framing, this
report's job is to tell the truth about what's real vs. still-gap
across every phase this project has built — never to pad a checklist.
It follows the exact honest-audit discipline `K3-EXIT-REPORT.md`/
`K4-EXIT-REPORT.md` established: functional sprint delivery and
phase-level infrastructure completeness are reported separately, and
neither is conflated with the other.

---

## 1. Exit gate assessment (BOOK-20 Ch. 8.3, "DAS-Certified auditable")

Ch. 8.3's own wording: "Intelligent + : AI Act register complete with
FRIA; audit fabric hash-chained; regulatory profile suites (Italian:
SPID/eIDAS/ANS; US: RSI ledger + G13 policy + engagement mapping); DR
exercise on record; **external audit** of a sampled evidence→credential
chain and a sampled cycle trace."

| Gate criterion | Status |
|---|---|
| All 5 sprints' own V1–Vn checks green | ✅ NEW-11 through NEW-15, every named verification passing, confirmed by direct test runs, not assumed |
| AI Act register complete with FRIA | ✅ NEW-13 — deployer-obligation register extends the live `ai_agent_configs` registry, seeded at the real `deploy_agent` trigger point; a single non-verified obligation anywhere keeps the WHOLE register non-green |
| Audit fabric hash-chained | ✅ **NEW-15** — `backend/domains/audit/`'s hash-chained system extended with 7 DAS event types, wired into 6 real service call sites. Three real, previously-undiscovered bugs that silently broke this system against any real Postgres deployment (never SQLite) were found and fixed during this sprint — see §2's NEW-15 entry. The second, non-hash-chained `audit_service.py` remains a documented, cross-referenced, NOT consolidated redundancy — an honest residual, not a hidden one. |
| Regulatory profile suites (Italian SPID/eIDAS/ANS; US RSI/G13/engagement) | ✅ NEW-11 (SPID/CIE via Keycloak, ANS via NEW-13's monitor) + NEW-13 (RSI ledger, G13 policy, DE/DI engagement mapping) |
| DR exercise on record | ✅ **NEW-15** — `scripts/dr/run_dr_exercise.sh` automates a restore-mechanics drill (kg-rebuild + pg_restore + audit hash-chain integrity check), verified end-to-end against an isolated throwaway Postgres. **Explicitly NOT a production WAL-archived PITR claim** — that remains a documented ops task, stated plainly in the script's own header. |
| External audit (sampled evidence→credential chain, sampled cycle trace) | ⚪ **Cannot be code-complete by definition.** Needs an actual human auditor; no methodology is specified anywhere in the Masterbook. NEW-15 prepared the sampling/export tooling (the audit-fabric wiring itself) an auditor would use — it did not, and structurally could not, simulate being the auditor. |

**Verdict, stated as plainly as K3/K4's own exit reports state theirs:
all 5 sprints' own functional delivery PASSED. The phase-level
DAS-Certified criteria are genuinely partial** — every criterion that
CAN be code-complete now is; the external audit itself is, by BOOK-20's
own design, never closeable by a code sprint. **DAS-Certified is NOT
being declared achieved by this report** — this mirrors K3/K4's own
disclosure discipline exactly.

---

## 2. Per-sprint delivery and verification outputs

### NEW-11 — ESSE3 driver + Italian profile, G3 (✅ 2026-07-29)

Delivered: the first DAS-conformant, non-stub external driver — a real
`CircuitBreaker` (BOOK-03 Ch. 6, first landing in this codebase)
composed with a `RetryConfig` retry loop so a breaker "failure" counts
only once retries are exhausted; M-B notifications primary
(`normalize_and_dispatch` event map, idempotent per `(tenant_id,
notification_id)` — scoped per-tenant, fixed during independent
security review after a global-uniqueness DoS hypothesis was confirmed
real), M-A REST + M-C nightly reconciliation secondary; 7 new
`platform`-schema boundary/mapping tables, never written into kernel
aggregates directly; `verbale_firmato` closes NEW-06's
`pending_verbalization` via the existing consumer, completely
unmodified; new `degree.recorded` event; SPID/CIE identity brokered
entirely by Keycloak — no new SPID SAML SP built in DLU. See
`docs/sprint_decisions_20260729_new11.md`.

### NEW-12 — PagoPA + QES adapters, G9/G3 (✅ 2026-07-30)

Delivered: per-tenant `legal_act_routing.resolve_legal_act_driver` slot
(`esse3`/`qes_provider`/`native_vc` — the ONE place this routing
decision is made); PagoPA driver (`check_bollo_payment_status`, real
cache-only DB read, replacing NEW-08's always-unpaid stub); QES driver
(`qes_signature_ref`, the G3 attach point for non-ESSE3 institutions —
structural sibling of NEW-11's `grade.synced` path); `webhook_hmac.py`
extracted as the one shared HMAC primitive all three driver webhooks
now use. A real bug found via this sprint's own tests (a `"status"` key
collision silently overwriting `normalize_and_dispatch`'s own wrapper
key) and one design attempt tried and REVERTED after it broke three of
NEW-06's own tests. See `docs/sprint_decisions_20260730_new12.md`.

### NEW-13 — Compliance registers + calendar, G8/G12/G13/G14 + AI Act (✅ 2026-07-31)

The largest single K5 sprint. Delivered: roster-anchored RSI/DE-DI
interaction ledger (one function, two regimes, `data_completeness`
discloses the confirmed Moodle instructor-event gap on every row rather
than hiding it); AI Act deployer-obligation register; Identity
Verification Policy live-resolved per tenant; G8 monitor reads NEW-11's
own `ans_completeness_ok` signal, never a new computation; compliance
calendar compute-on-read, never materialized. A real CI-gate false
positive found (a docstring-matched grep) and a real cross-tenant IDOR
found by independent security review (`record_identity_verification_
disclosure` took no `tenant_id`) and fixed. See
`docs/sprint_decisions_20260731_new13.md`.

### NEW-14 — Cost attribution + economies (✅ 2026-08-01)

No G-register item (cross-cutting BOOK-02/BOOK-03/BOOK-08
instrumentation). Delivered: `cost_attribution_service.py`'s static,
versioned mapping from `LlmUsageLog.service_type` to BOOK-00's ten
kernel engines × BOOK-02's eight process areas — an unmapped
`service_type` is an alertable governance defect, never a silent
default; `C_learner` computed as an honest 1-of-5 partial sum (only
`C_inference` has real backing data); a real, already-existing
unattributed-spend call site found and fixed. A MEDIUM security-review
finding (missing tenant scoping on `_count_active_learners`, not
exploitable under the only real caller but a missing second line of
defense) fixed. See `docs/sprint_decisions_20260801_new14.md`.

### NEW-15 — Conformance suites + DR automation (✅ 2026-08-02, this exit report's own sprint)

Delivered all 7 named deliverables (audit-fabric consolidation, DR
automation, one-voice structural proxy, ACE trace-completeness
measurement, maturity-evidence collector, graph+streams cross-tenant
fuzz, DAS-Core meta-test + NFR panels). **The single most consequential
finding of this entire K5 phase surfaced here:** independent security
review of Deliverable 6's cross-tenant Neo4j fuzz test found that
`kg_build_service.py`'s Course/Lesson/Concept Cypher queries matched
nodes by integer `course_id`/`lesson_id` alone — unique only WITHIN a
tenant's Postgres schema, not globally — so two tenants sharing an
integer id (a certainty over time, every tenant's first course is
`course_id=1`) would silently clobber each other's Neo4j node. This
sprint's own first-pass fix (a mutable `tenant_id` property) was
insufficient; the real fix required folding `tenant_id` into every
node's MERGE/MATCH identity key AND replacing Neo4j's own global
uniqueness constraints (`course_id_unique`, `lesson_id_unique`,
`(course_id, name)` on Concept) with tenant-composite equivalents — the
identity-key fix alone would otherwise have turned silent data
corruption into a hard `ConstraintValidationFailed` crash the first
time two tenants' course ids collided. `delete_graph`/`remove_course_
prerequisite`/`create_same_as_link`/`delete_same_as_link` now all
require an explicit, caller-trusted `tenant_id`; two more call sites
with the same vulnerability class (`knowledge_graph.py`'s delete route,
`curriculum_mapping_service.py`'s prerequisite removal) were found and
fixed in the same pass.

Also found and fixed: three real, previously-undiscovered bugs in the
pre-existing hash-chained audit subsystem (a `native_enum`/VARCHAR
mismatch, a missing-`db.refresh()` `MissingGreenlet`, and a
naive-vs-timezone-aware timestamp bug that made `verify_integrity`
report 100% of events tampered on every real Postgres deployment this
system has ever run against) — none of these surfaced against SQLite,
only against a live throwaway Postgres. A HIGH security-review finding
(the DAS bridge's tenant sentinel using `0`, plausibly collidable with
a future "unset" placeholder) fixed by switching to `-1`. See
`docs/sprint_decisions_20260802_new15.md` for the full record.

---

## 3. Regression evidence

Full non-integration/non-slow suite, run after all fixes:
**50 failed, 2624 passed, 5 errors** — an exact match to the
established K5 baseline's failure categories (SAML, RAG, PI-3
consistency/security, KG ontology demo, PI-2/PI-4 load, Kong JWT,
`test_api`/`test_app_import`/`test_course_factory`/
`test_e2e_rag_workflow`), all confirmed pre-existing and unrelated to
any K5 sprint's own changes.

A genuine regression was found and fixed within this same pass, not
carried forward: 5 pre-existing test files that call `engine.
run_cycle`/`run_mission` (`test_new02_eval_harness_crisis.py`,
`test_new03_memory_stores.py`, `test_new10_institution_workspaces.py`,
`test_stx06_ace_runtime.py`, `test_stx07_academic_gps.py`,
`test_stx10_tutor_coach_agents.py`) each maintain their own explicit
SQLite fixture table list, none of which knew about NEW-15's new
`AceCycleAttempt` table — fixed by adding it to each file's existing
list, the same pattern each file already used for every prior sprint's
additions.

Every migration in K5 was verified by running the full chain from a
freshly created, isolated, disposable `pgvector/pgvector:pg15`
container (never the shared dev stack), then downgrade → upgrade
again, confirmed via direct schema inspection at each step. NEW-15's
own migration additionally required no `ALTER TYPE` step — a source
correction to the sprint's own Guardrails, confirmed via reading the
actual `EventType` column definition before writing any migration.

## 4. `git diff --stat` (implementation repo, K5 range)

Commit series (`das-k1-kernel-foundation`):
- NEW-11 — ESSE3 driver + Italian profile (2026-07-29)
- NEW-12 — PagoPA + QES adapters (2026-07-30)
- NEW-13 — Compliance registers + calendar (2026-07-31)
- NEW-14 — Cost attribution + economies (2026-08-01)
- NEW-15 — Conformance suites + DR automation (2026-08-02, this report's own commit)

## 5. Register updates (this repo)

- **TRACEABILITY.md:** K5 Profiles & Compliance row now closed out 5/5
  (NEW-11 through NEW-15 all ✅); G3/G8/G9/G12/G13/G14 register rows
  updated across NEW-11 through NEW-13 (see each sprint's own row);
  §5 conformance-criteria meta-rule line annotated complete.
- **BOOK-20-Implementation-Blueprint-v1.0.md:** §8.1 table gained a
  per-criterion Status column (✅/🟡/⚪, honest, never a blanket claim);
  §8.2/§8.3 gained inline Annex status prose, explicitly NOT declaring
  DAS-Certified achieved; Ch. 10's maturity table gained an
  Implementation reference.
- **Constitution** (`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`,
  `dlu_builder_tk`): §25 (NEW-11), §26 (NEW-12), §27 (NEW-13), §28
  (NEW-14), new §29 with 8 subsections (NEW-15); §14 API surface gained
  each sprint's new routes.
- **Design decision docs** (`dlu_builder_tk`):
  `sprint_decisions_20260729_new11.md`,
  `sprint_decisions_20260730_new12.md`,
  `sprint_decisions_20260731_new13.md`,
  `sprint_decisions_20260801_new14.md`,
  `sprint_decisions_20260802_new15.md` — each with a full design record
  and, where applicable, the independent security review's findings and
  fixes.

## 6. Residual debt / carried forward

Per NEW-15's own explicit non-goal ("never pad a checklist") and this
report's own honest-disclosure discipline, the following remain
genuinely open — carried forward, not silently closed:

| Item | Status | Owner/When |
|---|---|---|
| Erasure e2e chain (erasure request → credential PII purge → twin data purge, exercised end-to-end) | **✅ closed (2026-08-05, hardening pass, not a numbered sprint)** — `erasure_service.request_erasure` executes BOOK-06 Ch. 9.3's full procedure for real: anchor soft-delete, L5-L7 immediate hard purge, L3 deferred-purge (new `purge_after` column + nightly `erasure_purge_worker`), a structurally-ready L4/Neo4j no-op hook (no twin-owned graph data exists yet), Redis move-proposal cache flush, the credential-pseudonymization exception via `revoke_or_suspend(purge_pii=True)` (now finally called), a narrow audited bypass of `TwinSnapshot`'s immutability guard, and dual audit emission (DAS hash-chained fabric + the legacy `audit_logs` `user.data_delete` action, found to be referenced by `compliance_service`'s own GDPR report but never once emitted anywhere before this). Gated on `ComplianceService.get_legal_holds` (BOOK-19 RACI: DPO owns retention/erasure exceptions) — reused, not reinvented. Also adopted `platform.legal_holds` into the Alembic migration chain for the first time (it existed only via a standalone `sql/compliance_schema.sql` bootstrap script). See `docs/sprint_decisions_20260805_k5_erasure_hardening.md`. | Closed |
| One-voice + "why?" UX checks (the actual human audit) | A structural proxy now exists (NEW-15 Deliverable 3) — explicitly documented as never a substitute | The human UX audit itself, whenever prioritized |
| KPI scorecards/dashboards | Not built — the same gap K3/K4's own exit reports already flagged, carried forward a third time | Whenever prioritized |
| Cross-tenant leakage fuzz — cache dimension | **✅ closed (2026-08-07, hardening pass, not a numbered sprint)** — `move_proposal_service.store()`'s Redis-backed store carried no `tenant_id` anywhere; added as a required parameter, threaded through all 10 production + 3 test call sites, and `ace.py`'s `_require_own_proposal` now checks `tenant_id` in addition to the pre-existing `twin_id` check (defense-in-depth: two independent signals that must both agree). Same pass also adopted `platform.rate_limits` into the Alembic chain (same status `legal_holds`/`tenant_settings` had) and, via live-Postgres migration verification, found and fixed a real production bug — `RateLimitService.check_rate_limit` compared a timezone-aware Postgres `TIMESTAMPTZ` value against naive `datetime.utcnow()`, crashing on the second call for any identifier+endpoint (masked by mocked unit tests that never exercised a real driver). NEW-17's Tier-1 limiter was reviewed for coupling to `RateLimitService` and deliberately left self-contained (reviewed non-gap, not a deferred fix — see `docs/sprint_decisions_20260807_security_tenancy_hardening.md`). Of the suite's four dimensions, API/graph/cache are now closed; streams remains open (see next row). | Closed |
| Cross-tenant leakage fuzz — streams (event mesh relay) dimension | Needs a live-Redis integration test outside the unit suite's reach | Whenever prioritized |
| Driver bulkhead chaos tests | Partially closed — most drivers + ESSE3/PagoPA/QES coverage now real (NEW-11/12); Moodle/Frappe/Stripe/Keycloak/n8n chaos coverage remains open | Whenever prioritized |
| None of the 9 seeded agents has run `/agents/{id}/gate` + steward sign-off | Confirmed — all 9 remain `lifecycle_state="testing"`, zero `deployed` transitions | ops/steward action, explicitly out of every K5 sprint's own scope, not a code deliverable |
| Two audit implementations coexist (`backend/domains/audit/` hash-chained, `backend/services/audit_service.py` non-hash-chained) | Documented, cross-referenced, NOT consolidated — a deliberate, explicit scope decision this sprint (Deliverable 1) | Future RFC, if consolidation is ever prioritized |
| External audit of a sampled evidence→credential chain and cycle trace | Cannot be code-complete by definition — needs a human auditor, no methodology specified anywhere in the Masterbook | ops/compliance action, whenever an actual audit is commissioned |
| Postgres PITR (production WAL-archived, RPO 0) | NEW-15 built a restore-*mechanics* drill only, explicitly not a PITR claim | A documented ops task, not a code deliverable |
| NEW-17 (Credit Recognition & Pre-Evaluation, G16) | Was in progress on a separate, concurrent session/track as of K4's own exit report — not touched by this K5 pack | Whichever session owns it — not this pack's concern |
| `MOVE_CONSULTS` has exactly one entry (`reframe_goal`) | Open only if a future sprint finds a real need | Not touched by any K5 sprint |

---

## 7. Closing

**BOOK-00 through BOOK-20's implementation blueprint is complete
through K5.** All five phases (K1 Kernel Foundation, K2 Cognition, K3
Navigation & Evidence, K4 Trust & Institution, K5 Profiles &
Compliance) have been executed, verified, and honestly reported —
each phase's own exit report states plainly what is real and what
remains open, and none conflates functional sprint delivery with
phase-level infrastructure completeness.

Per NEW-15's own text: any further work from here is either genuine new
scope (a BOOK-21+ volume or an RFC) or closing one of the items §6
above honestly still lists as open. This report does not declare
DAS-Certified achieved, does not declare the residual debt table closed,
and does not claim more than what NEW-11 through NEW-15 actually built
and verified.

*Per aspera ad astra — one verified sprint at a time.*
