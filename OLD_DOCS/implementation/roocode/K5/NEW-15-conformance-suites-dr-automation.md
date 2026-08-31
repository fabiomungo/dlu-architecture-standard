# Sprint NEW-15 — Conformance Suites + DR Automation (BOOK-20 Ch. 8/10, final K5 sprint)
### DAS K5 · self-contained prompt · target: `dlu_builder_tk` · depends: every prior sprint this phase (this sprint audits/instruments what they built — see per-deliverable notes for soft dependencies on NEW-11/NEW-13 specifically) · no G-register item (a BOOK-20 blueprint sprint) · opus design review already completed — see `docs/sprint_decisions_YYYYMMDD_new15.md` once written

## Role
`backend-dev` executing an opus-reviewed architecture (audit-fabric
consolidation, DR-automation mechanics, a UX-audit structural proxy,
ACE trace-completeness measurement, a maturity-evidence collector,
graph/streams tenant-isolation fuzz) turning BOOK-20 Ch. 8's three
conformance tiers into CI-runnable packs, automating a quarterly DR
exercise, and building Ch. 10's maturity-evidence collectors. **This is
the last sprint of the entire DAS Masterbook implementation blueprint**
— its job is to tell the truth about what's real vs. still-gap across
every phase this project has built, never to pad a checklist.

## Context — read before coding
1. **BOOK-20 Ch. 8, verbatim, all three tiers** — **DAS-Core (§8.1, exit
   K3, 7 criteria):** (1) layering — grep/CI gates, no experience-owned
   tables, no layer-skipping imports; (2) engine contracts — a contract
   test per engine invariant (evidence append-only, GPS determinism,
   twin single-door, KG fire-and-forget); (3) mesh — STX-03 V1-V5 as a
   permanent suite; (4) tenancy — cross-tenant leakage fuzz (API + graph
   + streams + cache); (5) drivers — bulkhead chaos tests; (6)
   gateway-only — egress network-policy test + code grep gate; (7) NFR —
   budget dashboards + alert wiring proof. **DAS-Intelligent (§8.2, exit
   K4):** Core + twin-7-layers-live with consent/erasure e2e; ACE trace
   completeness (100% sampled cycles); harness gates enforced in ACP
   lifecycle; GPS sovereignty audit (weights inspectable); credential
   survival suite; one-voice + "why?" UX checks; scorecards live.
   **DAS-Certified (§8.3, K5 + audit):** Intelligent + AI Act register
   complete with FRIA; audit fabric hash-chained; regulatory profile
   suites (Italian SPID/eIDAS/ANS; US RSI ledger + G13 policy +
   engagement mapping); DR exercise on record; **external audit** of a
   sampled evidence→credential chain and a sampled cycle trace.
2. **BOOK-20 Ch. 10, verbatim** — the maturity-evidence promotion table
   (M1: process digitized, L2 sequence + system-of-record identified;
   M2: dashboards live ≥1 term of data + alert wiring; M3: agent(s) at
   propose-tier with HITL queue metrics + harness green + incident count
   in bounds; M4: event-driven execution proof, no manual step in happy
   path, economics attributed, human accountability points sampled) —
   "collected automatically (NEW-15)." The Book gives no artifact shape
   beyond this table; Deliverable 5 resolves that.
3. **The existing CI-gate-script pattern (settled, reuse exactly, do not
   redesign):** `scripts/ci/*.sh` (5 existing gates) — `set -euo
   pipefail`, grep `backend/` for a forbidden pattern against a small
   commented allowlist, `exit 1` + list violators on any hit outside it;
   self-test pairing is a red/green recipe (assert clean pass → plant a
   violation → assert fail + violator named → clean up in `finally` →
   assert pass again).
4. **Audit fabric — two disconnected systems exist, resolve by
   consolidation, never by building a third:** `backend/domains/audit/`
   is a REAL, working, hash-chained tamper-evident log (`AuditEvent
   .event_hash`/`.previous_event_hash`, `AuditIntegrityHash` daily
   checkpoints, `AuditService.verify_integrity()` walks the chain) with
   a complete API — but its `EventType` enum has zero DAS-specific
   values and ZERO DAS service calls it today.
   `backend/services/audit_service.py` is a SEPARATE, differently-shaped
   `AuditService` (no hashing) actively used by auth/admin routes — a
   known, pre-existing redundancy (same class as this codebase's
   documented three-overlapping-badge-implementations pattern) — **out
   of scope to consolidate, leave it running, just cross-reference it
   honestly.** The per-model SQLAlchemy `before_update`/`before_delete`
   immutability guards on `EvidenceRecord`/`AceCycleTrace`/
   `issued_credentials`/`CommitteeVerdict` are a DIFFERENT, weaker
   property (append-only ≠ verifiable hash chain) — complementary to the
   hash-chained system, never a substitute for it; claiming they satisfy
   §8.3's "audit fabric hash-chained" would be dishonest.
5. **DR automation — confirmed entirely greenfield.** No `make
   kg-rebuild` target exists (the Makefile's `turnkey-rebuild-*` targets
   are unrelated Docker image rebuilds). No Postgres PITR/backup
   automation exists in-repo. `tests/chaos/test_pi2_disaster_recovery.py`
   (27 tests, fully mocked) tests only driver-failure graceful
   degradation — never an actual backup, restore, or KG rebuild.
   Normative spec (BOOK-13 Ch. 8, BOOK-18 Ch. 6): kg-rebuild = "full
   reconstruction from PG + import provenance + event log, idempotent,
   tenant-scopeable... rebuild time is a measured DR metric"; PG gets
   PITR (RPO 0 for committed transactions); Redis streams get "replay
   ≥7 days" (a retention guarantee, not a restore drill). **What Neo4j
   actually holds today is course/concept ontology, not twin-owned
   data** — this sprint's kg-rebuild is a faithful rebuild of what's
   really there, never a claim of twin-data DR.
6. **ACE trace-completeness — confirmed asserted-by-construction, never
   measured.** `AceCycleTrace` is written via one primitive
   (`_persist_trace`) on all 3 cycle-exit paths, immutable via event
   listeners — but nothing independently counts cycle ATTEMPTS to diff
   against trace rows, so a hard process kill mid-cycle (or an exception
   inside `_persist_error_trace` itself, which has no further fallback)
   would silently violate the 100% claim today and nothing would notice.
7. **One-voice/"why?" — inherently not a pure-code-automatable thing** (a
   UX audit implies human/visual judgment) but BOOK-20 frames it as a
   CI-suite "check" — some executable proxy is expected, never a literal
   claim that CI performed the human audit. Per-feature explanation
   fields already exist scattered across services (recommendations,
   ACE's `get_trace`) with no cross-agent consistency check today.
8. **Explicitly OUT of scope, confirmed, do not re-litigate:** agent GA
   gating (`POST /agents/{id}/gate` already exists and works fully — the
   gap is purely an ops/steward decision to run it against the 9 real
   agents, unchanged, re-carried, not a code deliverable this sprint);
   the external audit itself (BOOK-20 §8.3's "external audit" needs an
   actual human auditor — no methodology is specified anywhere in the
   Masterbook — this sprint's job re: it is to prepare the sampling/
   export tooling an auditor would use, via Deliverable 1's wiring,
   never to simulate being the auditor in CI); NFR budget dashboards
   beyond what Deliverable 7 scopes (generic PI-3/PI-4 Grafana
   dashboards already exist — this sprint adds the DAS-specific budget
   panels named in BOOK-03 Ch. 8, not a new observability stack).
9. **Soft dependencies:** Deliverable 2's DR-exercise calendar write
   integrates with NEW-13's `compute_compliance_calendar` if that
   sprint has been executed by the time this one runs; if not, it
   degrades honestly to a standalone JSON evidence artifact with the
   calendar integration documented as a one-line future hook, never
   blocked on NEW-13. Deliverable 6's Neo4j fuzz test builds on
   `kg_build_service.py`'s existing cross-tenant guard (already raises
   `ValueError` on cross-tenant concept linking) — hardens/pins it,
   never replaces it.

## Guardrails
`EventType` (Deliverable 1) is a Postgres enum type — adding values
requires an Alembic migration using `ALTER TYPE ... ADD VALUE`, which
cannot run inside a transaction block on the Postgres versions this
project targets; the migration must set the appropriate non-transactional
execution option (flag this explicitly in the migration file's own
docstring, the one non-obvious risk in this sprint). `AceCycleAttempt`
(Deliverable 4) is additive-only, append-only (no `updated_at`, no
mutation path — same discipline as `EvidenceRecord`). No new CI gate
script bypasses the existing red/green self-test recipe (Context point
3). DR scripts (Deliverable 2) are read/derive-only against production
data paths — they operate against the isolated throwaway-Postgres
pattern this project already uses for migration testing, never against
a shared dev/staging database.

## Deliverables
1. **Audit-fabric consolidation** — extend `backend/domains/audit/`'s
   `EventType` enum with `CREDENTIAL_ISSUED`, `CREDENTIAL_SIGNED`,
   `EVIDENCE_REGISTERED`, `EVIDENCE_VERIFIED`, `ACE_CYCLE_TRACED`,
   `GPS_REPLAN`, `COMMITTEE_VERDICT_RECORDED`; wire best-effort,
   post-commit, non-blocking `capture_event` calls into
   `credential_signing_service.py`/`document_credential_service.py`
   (issuance/signing), `assessment_evidence_service.py` (after
   `competency_graph_service.register_evidence`),
   `ace_service._persist_trace` (after flush), and the committee-verdict
   writer (`committee_service.decide_verdict`) — the exact same
   "an audit-store outage must not break the caller, but is logged
   loudly" discipline `_persist_error_trace` already established. No
   historical backfill — these four events start being captured from
   this sprint forward. Leave `backend/services/audit_service.py`
   running unchanged; add one cross-reference docstring line pointing at
   the canonical hash-chained system so the redundancy is documented,
   never silent.
2. **DR automation** — three scripts, one seam:
   - `scripts/dr/kg_rebuild.py` + a `make kg-rebuild` target: enumerates
     courses (optional `--tenant <id>` for tenant-scopeability),
     `kg_build_service.delete_graph` then `.build_full_graph` per
     course, timed through the EXISTING `record_kg_build` histogram
     (`backend/api/routes/metrics.py`) — zero new metric plumbing.
   - `scripts/dr/pg_restore_drill.sh`: `pg_dump` the current DB →
     `pg_restore` into a fresh throwaway DB (the same
     `DLU_TEST_PG_URL`-pattern isolated container this project already
     uses for migration testing) → post-restore integrity check = row-
     count parity PLUS `AuditService.verify_integrity()`'s hash-chain
     walk must pass on the restored copy (this is where Deliverable 1
     pays off directly — the drill verifies the audit chain survived
     restore) → timed, pass/fail. The script's own header states plainly
     this is a restore-*mechanics* drill, not a production WAL-archived
     PITR claim — that remains a documented ops task.
   - `scripts/dr/run_dr_exercise.sh` (a manually-triggered ops runbook,
     deliberately NOT an unattended Celery beat task — a DR restore
     drill is a human-supervised exercise, matching this Masterbook's
     own "steward action" framing elsewhere) running both scripts,
     capturing durations + pass/fail, through a thin
     `record_dr_exercise(cadence="quarterly", last_run_at, duration_s,
     status, evidence_ref)` seam — writes NEW-13's compliance-calendar
     register row if that service exists at implementation time,
     otherwise a standalone JSON evidence artifact (Context point 9).
3. **One-voice/"why?" structural proxy** —
   `tests/conformance/test_explanation_trace_coverage.py` (`unit`-marked):
   an explicit registry of every agent-facing response type (ACE
   `CycleResult`/`get_trace`, recommendations' `explanation_trace`, GPS
   scenario, issued credential, committee verdict) mapped to its
   explanation accessor, asserting each surface exposes a non-empty,
   resolvable why-field for a representative constructed instance. The
   test's own docstring AND the maturity-collector output (Deliverable
   5) both state verbatim: this is a structural proxy for the BOOK-20
   one-voice UX audit, which remains an open human task — passing this
   test never marks the human audit "done."
4. **ACE trace-completeness measurement** — a new, append-only
   `AceCycleAttempt` row (`tenant_id`, `cycle_id`, `agent_key`,
   `trigger_kind`, `started_at`) written in its own autonomous
   transaction at `run_cycle`'s entry (immediately after `cycle_id` is
   minted — the canonical attempt boundary both `route()` and
   `run_mission()` funnel through), reusing `_persist_error_trace`'s
   "own transaction, best-effort" discipline — committing BEFORE
   `_run_phases` runs, so a hard kill leaves a visible, checkable gap
   where today there is none. Reconciliation:
   `reconcile_ace_trace_completeness(db, tenant_id, window)` —
   `AceCycleAttempt LEFT JOIN AceCycleTrace ON cycle_id`, any attempt
   past a short grace period with no matching trace is a completeness
   violation; a daily Celery beat task
   (`ace.reconcile_trace_completeness`) runs it over the prior
   24h+grace window, logging structured errors and incrementing a new
   `ace_trace_gaps_total` counter (mirrors `record_kg_build`'s shape) on
   any gap, consumed by Deliverable 5's collector. A new
   `ace_cycles_attempted_total` counter lands alongside for dashboard
   visibility, but the durable table is what makes the guarantee
   actually checkable.
5. **Maturity-evidence collector** —
   `backend/services/maturity_evidence_service.py
   ::compute_maturity_evidence(db, tenant_id, institution_id)` —
   mirrors `compliance_posture_service.py`'s `_claim()`/`_gap()` pattern
   exactly: one cell per (process-area P0x × M-level) from the Ch. 10
   table, each `{"process_area", "m_level", "criterion", "status" ∈
   {"verified","partial","not_yet_available"}, "evidence",
   "freshness_stamp"}`, evaluated against REAL signals — dashboard
   liveness/freshness, agent propose-tier + HITL-queue metrics,
   event-driven-execution-proof (`domain_events` outbox + mesh-drain
   metrics), Deliverable 4's trace-completeness reconciliation result,
   Deliverable 3's explanation-coverage proxy, and an explicit
   `_gap()`-shaped cell recording "two audit implementations coexist;
   consolidation beyond Deliverable 1's four events is deferred." New
   `GET /api/institution/maturity-evidence` route in
   `institution_workspaces.py` (standalone), also called by the QA
   Console (IW3) — the exact dual-surface pattern
   `compliance_posture_service` already established.
6. **Cross-tenant fuzz — graph + streams** — closes the two dimensions
   the existing `tests/test_cross_tenant_leakage_fuzz.py` already
   honestly flagged as uncovered: (a) `kg_integration`-marked
   `tests/integration/test_kg_cross_tenant_fuzz.py` (needs
   `NEO4J_TEST_URI` — mocking Neo4j here would test the mock, not the
   isolation) — structural: every read-query template carries a
   tenant/institution discriminator; behavioral: seed two tenants'
   course graphs, prove a tenant-A-scoped traversal cannot reach
   tenant-B nodes, hardening `kg_build_service.py`'s existing
   cross-tenant-linking guard rather than inventing a new one; (b) a
   `unit`-marked extension to the EXISTING
   `test_cross_tenant_leakage_fuzz.py` asserting
   `event_relay.stream_key(tenant_id)` and its entry fields are
   injective and tenant-carrying (structural, no live service — stream
   keys are already tenant-namespaced,
   `dlu:events:{tenant_id}`, so this pins existing behavior) PLUS a new
   `integration`-marked `tests/integration/test_stream_cross_tenant_
   fuzz.py` proving a consumer draining tenant A's stream never receives
   tenant B's entries through the real `drain_group` path (the
   behavioral proof the by-construction namespacing actually holds).
7. **Remaining DAS-Core criteria → CI-runnable packs** — a meta-test
   (`tests/conformance/test_ch8_criteria_have_executable_checks.py`)
   asserting each of BOOK-20 §8.1's 7 criteria has ≥1 named, discoverable
   executable check in the test suite (the sprint's own "verify" clause,
   per BOOK-20 Ch. 7's stub: *"the suites verify themselves"*) — a
   registry mapping criterion → test path/CI-gate-script, failing loudly
   if any of the 7 has zero mapped checks. DAS-specific NFR budget
   panels (kernel-read p95<300ms, verification-endpoint 99.95%
   availability, event-propagation p95<5s, GPS-recompute<60s async) added
   to the EXISTING Grafana dashboards (`grafana/dashboards/`) alongside
   the generic PI-3/PI-4 panels already there — extending, never
   replacing.

## Verifications
- **V1** structural: every one of the four Deliverable-1 event types has
  ≥1 real call site outside its own migration/model file (mirrors
  NEW-06's sole-writer negative-test technique, inverted — here proving
  presence, not absence).
- **V2** the PG restore drill round-trips clean on a fixture DB: row
  counts match, and a hash-chained audit event written before the dump
  is verified intact (`verify_integrity()` passes) after restore.
- **V3** kg-rebuild is idempotent and tenant-scopeable: running it twice
  for the same tenant produces byte-identical graph state; running it
  for `--tenant A` never touches tenant B's nodes.
- **V4** the explanation-trace-coverage proxy: every registered
  agent-facing response type resolves a non-empty why-field; a
  deliberately-stripped fixture response fails the check (negative
  test, proving the proxy actually checks something).
- **V5** ACE trace-completeness reconciliation: a fixture with a
  deliberately orphaned `AceCycleAttempt` (no matching trace) is flagged
  by `reconcile_ace_trace_completeness`; a fixture with a matched
  attempt+trace pair is not.
- **V6** maturity collector: a fixture institution with known signal
  states (some verified, some gap) produces exactly the expected
  per-(P0x × M-level) cell statuses — no cell silently defaults to
  `"verified"` without real evidence.
- **V7** graph/streams fuzz: the Neo4j integration test proves
  cross-tenant traversal is blocked (positive) and that the guard fires
  on a deliberately malformed cross-tenant fixture (negative); the
  streams integration test proves a tenant-A consumer draining
  `drain_group` never yields a tenant-B entry.
- **V8** meta-test: all 7 DAS-Core criteria resolve to ≥1 mapped
  executable check; a deliberately unmapped 8th fixture criterion fails
  the meta-test (proving it actually checks coverage, not just counts
  to 7).

## DoD
V1–V8 green · `pytest -m phase1` green · migration
`upgrade`/`downgrade`/`upgrade` verified on an isolated throwaway
Postgres, including the `ALTER TYPE ... ADD VALUE` non-transactional
step (Guardrails) · full regression sweep against the current baseline
· BOOK-20 §8.1/§8.2/§8.3 Annex updated per-criterion with honest
✅/🟡/⚪ status (never a blanket "DAS-Certified achieved" claim — the
external audit and agent GA gating remain explicitly open, ops-owned
items per Context point 8) · BOOK-20 Ch. 10 Annex updated with the
maturity-collector's implementation reference · TRACEABILITY's K5
phase-exit-gate row annotated with this sprint's honest completion
state (which of §8.3's items are code-complete vs. still requiring a
human/ops action) · decisions note
(`docs/sprint_decisions_YYYYMMDD_new15.md`) recording: the audit-fabric
consolidation decision (and why `audit_service.py` was left alone), the
DR-automation scope (restore-mechanics drill vs. production PITR claim),
the one-voice UX-audit proxy's explicit honesty framing, and the
maturity-collector's evidence-cell design · **produce
`K5-EXIT-REPORT.md`** (`implementation/roocode/K5/`), following the
exact honest-audit discipline `K3-EXIT-REPORT.md`/`K4-EXIT-REPORT.md`
established — functional delivery vs. phase-infrastructure completeness
reported separately, residual debt (if any remains) named explicitly,
never silently claimed closed · next: this is the last authored K5
sprint — once NEW-11 through NEW-15 are all executed and this exit
report is produced, the DAS Masterbook's BOOK-00 through BOOK-20
implementation blueprint is complete through K5; any further work is
either genuine new scope (a BOOK-21+ or an RFC) or closing whatever this
exit report honestly still lists as open.
