# Sprint NEW-11 — ESSE3 Driver + Italian Profile (G3 execution, feeds G8/G14)
### DAS K5 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-05 (mirror-mode contract), NEW-06 (G3 prepare-side + n8n-bridge), STX-08 (evidence pipeline) · opus design review already completed — see `docs/sprint_decisions_YYYYMMDD_new11.md` once written

## Role
`backend-dev` executing an opus-reviewed architecture (circuit breaker,
adapter layout, boundary tables, SPID/CIE brokering scope — see the
design review this prompt is built from) resolving the EXECUTION side of
**G3** (BOOK-16 Ch. 8; DLU's own prepare-side has been real since NEW-06)
and feeding — never resolving — **G8** (ANS completeness monitor, the
ledger itself is NEW-13) and **G14** (DE/DI ledger, entirely NEW-13). This
is the first sprint in the codebase that builds a REAL, DAS-conformant
external driver — everything before this sprint only *prepared* for one
(`pending_verbalization` states, fixture-fed mirror ingestion, an
always-stub PagoPA driver).

## Context — read before coding
1. **BOOK-18 Ch. 4 — the ESSE3 driver contract, verbatim.** Three
   integration modes: **M-A REST** (ESSE3 REST web services, API-key +
   technical-user groups — on-demand reads + sanctioned writes, e.g.
   session-enrollment relay), **M-B Notifications** (ESSE3 Gateway
   module, notification-driven — **the primary mode**, matches the
   mesh), **M-C Replica** (replica/boundary tables, ODS-style — nightly
   bulk mirror refresh + reconciliation/drift detection). Event map
   (ESSE3 fact → DLU event → consumers): immatricolazione/iscrizione
   anno → `enrollment.synced`; piano di studi approvato →
   `enrollment.synced` (plan payload, feeds G7 regulation-year binding —
   already closed, K1+NEW-04, not this sprint's job); appello
   pubblicato/modificato → `assessment_session.published`/`changed`;
   iscrizione appello → session-enrollment mirror; **verbale firmato**
   (the legal grade act) → `grade.synced` with a verbale reference
   attached — this is where G3 execution actually happens; conseguimento
   titolo → a degree-recorded event; ANS spedizione outcomes →
   completeness signals (BOOK-08 §6.3 monitor — that monitor is **NEW-13**,
   this sprint only emits the signal it will consume). Profile rules:
   ESSE3 occupies the student-records slot (ADR-0009) in Italian
   deployments; DLU never writes official records into ESSE3 except via
   sanctioned M-A endpoints, each write idempotent + audit-paired;
   verbalization/preservation stay ESSE3-side — **DLU MUST NOT
   reimplement qualified signature or legal preservation**; the adapter
   is a standalone worker with its own boundary tables, circuit breaker,
   and health panel (I4).
2. **BOOK-03 Ch. 6 — the generic driver contract binding ALL drivers,
   normative:** (1) a driver failure degrades its capability visibly,
   MUST NOT cascade into kernel unavailability (bulkhead + circuit
   breaker per driver); (2) inbound driver data enters as events with
   source attribution, lands in mirror/boundary tables, never written
   into kernel-owned aggregates directly; (3) webhook endpoints
   authenticate via shared-secret HMAC and are idempotent; (4) new
   drivers require an ownership-map row, event contract, failure-mode
   statement.
3. **BOOK-16 Ch. 8 — the G3 boundary, verbatim structure:** (1)
   Preparation (DLU) — committee/examiner verdicts, evidence-complete —
   **already real**, `backend/services/committee_service.py` (NEW-06).
   (2) Legal act (driver) — verbale with qualified electronic signature
   (FEA/QES per eIDAS), legal preservation (*conservazione a norma*) —
   executed in ESSE3, **DLU MUST NOT reimplement either** — THIS
   sprint's job. (3) Confirmation — `grade.synced` closes
   `pending_verbalization` — **already real**,
   `committee_service.close_verbalization_from_grade_synced_sync`,
   consumed on the `n8n-bridge` mesh group via
   `thesis_committee_consumers.py` (NEW-06). BOOK-16 itself does not
   mandate a specific API/record format for step 2 — BOOK-18 Ch. 4 (the
   M-A/M-B split above) is what makes it concrete, and this sprint wires
   it for real.
4. **BOOK-19 Ch. 2.1/5 — the Italian regulatory profile.** SPID/CIE
   access to online services is exclusive since 1 Oct 2021 (CAD art. 63;
   narrow exceptions: foreign students, minors) and is brokered through
   Keycloak (Ch. 2.1: *"Italian profile: SPID/CIE brokered through
   Keycloak"*) — this is the literal mechanism, not a paraphrase. Unlike
   the US profile (G13), **there is no separate Italian
   identity-verification ledger requirement** — SPID/CIE brokering IS the
   entire mechanism; do not invent a parallel ledger by false symmetry
   with G13. G14 (DE/DI classification + per-CFU ledger, ANVUR telematic
   regime) and G8 (ANS/SUA-CdS completeness monitor) are BOTH owned by
   **NEW-13** — this sprint supplies plumbing (events, driver
   scaffolding) neither of those sprints has to build themselves, but
   builds neither ledger nor monitor itself.
5. **Existing, repo-verified state — call into it, never reinvent it:**
   `backend/services/assessment_session_service.py::ingest_mirror_session`
   (NEW-05) is the write-side contract for career/session/exam-grade
   facts — upserts `AssessmentSession`(mode="mirror") by
   `(tenant_id, external_ref)`, upserts enrollments, emits `grade.synced`
   idempotently (gated on `evidence_written_at is None`) when a result is
   published and not refused. `backend/services/committee_service.py
   ::close_verbalization_from_grade_synced_sync` +
   `backend/services/thesis_committee_consumers.py` (NEW-06) is the
   thesis/committee verbale-closure path — untouched by this sprint,
   only fed correctly. **No circuit breaker exists anywhere in this
   codebase** (grep-confirmed) — `docs/sprint_decisions_20260724_
   k3k4_hardening.md`'s own residual-debt table names this gap and names
   ESSE3/NEW-11 as where it finally gets built; every driver until now
   has retry+timeout only. `backend/integrations/moodle/` and
   `backend/integrations/frappe/` are the real-network-client template
   (`RetryConfig`+`RateLimiter`, `health_check()` that never raises,
   dedicated per-tenant `*Mapping` tables with `sync_status`) —
   `backend/drivers/pagopa_stub.py` is explicitly NOT that template
   (zero I/O, a placeholder). `interop_bridge.external_identifiers` is a
   1EdTech-standard-scoped identity spine (`standard_family` CHECK:
   `oneroster|case|lti|xapi|scorm|qti|other` — does NOT include
   `'esse3'`, and carries no sync bookkeeping) — the wrong home for
   ESSE3 mapping; dedicated tables follow the Moodle/Frappe precedent
   instead (see Deliverable 3).
6. **SPID/CIE brokering scope (a resolved design decision, not left
   open):** Keycloak already runs as SSO infra with a working OIDC
   consumer (`backend/services/oidc_service.py`) and natively brokers an
   upstream SAML IdP, presenting a normal OIDC identity downstream.
   `backend/api/routes/saml.py`/`backend/services/saml_service.py` is a
   generic eduGAIN SP (hardcoded eduPerson attribute OIDs, fixed
   `NameIDFormat=emailAddress`, no `AuthnContextClassRef`, no
   `AttributeConsumingService`) — **it is explicitly NOT the vehicle for
   SPID and must not be extended for it**; building a parallel SPID SAML
   SP inside DLU would duplicate what Keycloak's IdP-broker already does.
   The real, non-hand-waved DLU-side gap is narrower: (a) SPID's
   `fiscalNumber`/`spidCode` claims (surfaced as custom OIDC claims by a
   Keycloak IdP mapper) aren't read by `provision_user` today, and (b)
   nothing enforces SPID's L2-minimum `AuthnContextClassRef` on the DLU
   side (defense-in-depth — Keycloak requests it upstream, but DLU
   should still check). Both are small, real extensions to
   `oidc_service.py`, not a new SP.
7. **No live ESSE3 instance or SPID IdP is reachable in this
   environment** (same constraint NEW-05/NEW-06 already navigated for
   their own fixture-fed contracts). The adapter is built against
   CINECA's published REST/Gateway API shape ([Servizi REST su
   ESSE3](https://wiki.u-gov.it/confluence/display/ESSE3/Servizi+REST+su+ESSE3),
   [GATEWAY: Repliche e
   Import](https://wiki.u-gov.it/confluence/display/ESSE3/GATEWAY+-+Repliche+e+Import))
   and Keycloak's identity-broker capability, fixture/test-IdP-fed —
   never a fabricated "it works against production" claim.
8. **Surfaces are minimal, deliberately.** No new learner/faculty UI
   this sprint — this is kernel/driver plumbing, a health panel, and a
   compose overlay. Any faculty-facing ESSE3 status view is out of
   scope.

## Guardrails
Additive-only migration (new `platform`-schema tables + one new
`User.spid_fiscal_number` column) — no `DROP`/`ALTER … DROP`, named
constraints throughout, full tested `downgrade()`. New PKs are `GUID()`;
`dlu_course_id` stays `Integer` wherever a table references `courses.id`
(CLAUDE.md §4.2). No new `relationship()` reaching across into
`models.py`/`models_institution.py`/etc. from `models_esse3.py` — soft
refs (plain FK columns, no ORM relationship) only, matching every other
cross-schema/cross-model reference this phase has used. `EVENT_TYPES` is
a closed set (`STUDENT_EXPERIENCE_ARCHITECTURE.md` §7.3: "extend only via
PR to this doc") — adding `degree.recorded` updates that doc in the same
change set, not after.

## Deliverables
1. **Circuit breaker primitive** — `backend/drivers/circuit_breaker.py`:
   a `CircuitBreaker` class with `CLOSED`/`OPEN`/`HALF_OPEN` states
   (`failure_threshold`, `recovery_timeout`, `half_open_max_calls`
   configurable), `async def call(self, fn, *args, **kwargs)` raising
   `CircuitOpenError` when `OPEN`, `.snapshot()` for health-panel
   consumption. Composes with (never duplicates) the existing
   `RetryConfig`/`RateLimiter` — nests as `RateLimiter.acquire()` →
   `RetryConfig` retry loop → the actual call, with the breaker wrapping
   the whole retry-wrapped call: a breaker "failure" counts only once
   `RetryConfig` has *exhausted* its retries, so transient blips never
   trip it. No external dependency (`pybreaker`/`tenacity`) — hand-rolled,
   matching how this codebase already hand-rolls `RetryConfig`/
   `RateLimiter` rather than importing them.
2. **ESSE3 adapter package** — `backend/drivers/esse3/`: `client.py`
   (M-A REST client — `httpx.AsyncClient` + `RateLimiter`+`RetryConfig`,
   wrapped by the circuit breaker, `health_check()` that never raises),
   `auth.py` (M-A API-key + technical-user-group auth, static
   key/secret, Frappe-style), `notifications.py` (M-B normalizer, see
   Deliverable 5), `replica.py` (M-C bulk mirror refresh +
   reconciliation), `health.py` (assembles the I4 health-panel dict:
   breaker snapshot + mirror staleness), `config.py`, `exceptions.py`.
   Broaden `backend/drivers/__init__.py`'s docstring in the same change
   set to state the DAS BOOK-03 Ch. 6 driver contract (bidirectional
   adapter, boundary tables, circuit breaker, health panel) — the
   existing docstring describes only the narrower PagoPA-stub shape.
3. **Boundary/mapping tables + migration** —
   `backend/database/models_esse3.py` (`platform` schema): 
   `esse3_student_mapping` (`dlu_twin_id`/`dlu_user_id` ↔ `matricola`,
   `esse3_person_id`, `codice_fiscale`; unique per tenant+twin),
   `esse3_course_mapping` (`dlu_course_id` Integer ↔ `ad_id`/`cod_ins`,
   `cds_cod`, `af_id`), `esse3_session_mapping` (`dlu_session_id` ↔
   `appello_id`, `external_ref` — the reverse lookup + sync cursor
   alongside `ingest_mirror_session`'s own forward upsert-by-`external_ref`),
   `esse3_verbale_ref` (the G3 legal-act attach point: `dlu_verdict_id`/
   `dlu_enrollment_id`, `verbale_number`, `protocollo`, `signature_ref`,
   `conservazione_ref`, `signed_at` — references only, never the
   signature/preservation itself), `esse3_notification_log` (M-B
   idempotency + audit: `idempotency_key` unique, `notification_type`,
   `payload_hash`, `status`, `received_at`/`processed_at`, `error`),
   `esse3_boundary_career`(+`esse3_boundary_appello`) (M-C ODS replica
   rows, keyed by `matricola`/`external_ref`, `data_as_of`). All tables:
   `sync_status String(20) default "pending"`, `last_sync_at`,
   `created_at`/`updated_at`, named constraints, additive migration with
   tested `downgrade()`.
4. **M-B webhook + health route** — `backend/api/routes/esse3.py`:
   `POST /api/internal/esse3-notifications` (prefix `/api/internal`, add
   to `EXEMPT_PATHS` — tenant resolved from payload/`X-Tenant-ID`, same
   convention as `internal.py`; auth = `ESSE3_GATEWAY_SECRET`
   HMAC-SHA256 over the raw body, `hmac.compare_digest`, idempotent via
   `esse3_notification_log.idempotency_key`) and `GET /health/esse3`
   (breaker state + mirror staleness + `data_as_of`). Register via
   `_import_router("esse3", "backend.api.routes.esse3")` in
   `backend/api/main.py`.
5. **Event-map wiring** —
   `backend/drivers/esse3/notifications.py::normalize_and_dispatch(db,
   tenant_id, notification)` resolves mappings (Deliverable 3) and calls
   INTO the existing functions, inventing no new write-side contract:
   immatricolazione/piano-di-studi → `event_outbox.emit_sync(
   ENROLLMENT_SYNCED, …)`; appello published/modified/enrolled →
   `ingest_mirror_session(...)`; **verbale firmato, ordinary exam** →
   `ingest_mirror_session(...)` with a published result (its own
   internal gated `grade.synced`, `source_kind="esse3"`); **verbale
   firmato, thesis/committee** → `event_outbox.emit_sync(GRADE_SYNCED,
   {"verdict_id": …, "external_ref": verbale_ref}, …)` — the SAME event
   type fans out independently to both the `evidence-pipeline` group
   (ordinary grades) and the `n8n-bridge` group (thesis verdicts, a safe
   no-op when `verdict_id` is absent) via their own Redis-Streams
   cursors — the adapter's only job is choosing the payload shape, never
   which consumer runs; conseguimento titolo → a NEW `DEGREE_RECORDED =
   "degree.recorded"` event, added to the closed `EVENT_TYPES` set
   (`backend/services/event_taxonomy.py` + constitution §7.3 in the same
   change set) — registered and emitted this sprint, consumed by a later
   Credential-Engine sprint (an intentionally reserved slot, the same
   posture `n8n-bridge` had before NEW-06); ANS spedizione outcomes → a
   completeness signal emitted (never a monitor built — NEW-13's job).
6. **M-C reconciliation worker** — `backend/workers/esse3_worker.py`
   (Celery, dedicated `esse3` queue — never the kernel `worker`'s queue,
   the bulkhead itself), `run_all_tenants`/`_reconcile_tenant(tenant_id)`
   pattern mirroring `frappe_reconciliation_worker.py` exactly, wrapping
   the async normalizer via `asyncio.run(...)` (CLAUDE.md §7.2). Celery
   beat entry for a nightly schedule alongside the existing fixed-hour
   entries in `backend/workers/celery_app.py`.
7. **SPID/CIE Keycloak brokering** — a new Italian realm artifact
   `config/keycloak/realms/dlu-realm-it.json` (SPID/CIE
   `identityProvider` + attribute mappers — the existing `dlu-realm.json`
   has zero `identityProviders` and stays untouched, so non-Italian
   tenants are unaffected); a small extension to
   `backend/services/oidc_service.py::provision_user` to read the
   Keycloak-mapped `fiscal_number`/`spid_code`/`spid_level` claims and
   persist `codice_fiscale` into a new nullable `User.spid_fiscal_number`
   column (one additive migration) plus the rest into the existing
   `User.metadata` JSON blob; a small guard rejecting logins below a
   configured `SPID_MIN_LEVEL` (defense-in-depth — Keycloak requests the
   AuthnContext upstream, DLU verifies it landed). **No new SPID SAML
   SP** — `saml_service.py`/`saml.py` stay untouched.
8. **Italian compose overlay** — `docker-compose.italian.yml` (an
   overlay file, `-f docker-compose.dev.yml -f docker-compose.italian.yml`):
   an `esse3-worker` service (the Deliverable 6 Celery worker on its own
   `esse3` queue), a `keycloak` service copied from the turnkey
   precedent with `--import-realm` + the `dlu-realm-it.json` import
   volume, `ESSE3_BASE_URL`/`ESSE3_API_KEY`/`ESSE3_TECH_USER`/
   `ESSE3_GATEWAY_SECRET`/`SPID_MIN_LEVEL` env vars on `backend` +
   `esse3-worker`. Append the new env vars to CLAUDE.md §13.

## Verifications
- **V1** event-map fixtures round-trip: one fixture per event-map row
  (`tests/fixtures/esse3/*.json` — immatricolazione, piano_studi_approvato,
  appello_pubblicato, appello_modificato, iscrizione_appello,
  verbale_firmato_exam, verbale_firmato_thesis, conseguimento_titolo,
  ans_spedizione), each asserting: the exact existing function was
  invoked (spy/monkeypatch), the emitted event type + key payload fields
  match the event-map row, and delivering the same fixture twice produces
  exactly one effect (idempotency via `esse3_notification_log`).
- **V2** `pending_verbalization` closes on a `verbale_firmato_thesis`
  fixture: drain the `n8n-bridge` group, assert
  `CommitteeVerdict.pending_verbalization` flips `False` — reusing
  `close_verbalization_from_grade_synced_sync` completely unmodified
  (this sprint proves only that the adapter emits the right payload).
- **V3** adapter down ⇒ mirrors stale-with-notice, kernel green: force
  retry-exhausted failures on the M-A client until the breaker opens;
  assert `GET /health/esse3` reports `status="degraded"`, `stale=true`,
  `data_as_of` set to the last successful sync; mirror reads serve
  last-known boundary-table rows flagged stale (never a live call while
  `OPEN`); `GET /health/ready` stays 200; zero writes to any
  kernel-owned aggregate while the breaker is open.
- **V4** SPID-brokered login e2e (test IdP), two layers: (a) a `unit`
  test feeding a fixture OIDC `id_token` carrying SPID claims
  (`fiscal_number`, `spid_level=SpidL2`) into `provision_user` + the L2
  guard, asserting a `User` is provisioned with `spid_fiscal_number`
  populated, and that a `SpidL1`-claim token is rejected; (b) an
  `integration`-marked e2e brokering a SAML test IdP through Keycloak,
  asserting the full redirect → broker → OIDC-callback → provisioned-User
  flow. Both test DLU's consumption of a *brokered* identity — neither
  certifies against AgID's live SPID federation.
- **V5** the circuit breaker only trips after retry-exhaustion — a
  transient single-failure-then-success sequence never opens the
  circuit (proves composition-with-retry per Deliverable 1, not just
  that a breaker object exists).
- **V6** structural: `grep` confirms `grade.synced`'s two independent
  consumer-groups (`n8n-bridge`, `evidence-pipeline`) are never
  conflated by this sprint's own code — the adapter chooses payload
  shape only, no new dispatch logic reaches into either consumer
  directly (mirrors NEW-06's own `test_no_non_committee_path_writes_
  committee_verdict_evidence_type` structural-negative-test technique).

## DoD
V1–V6 green · `pytest -m phase1` green · migration
`upgrade`/`downgrade`/`upgrade` verified on an isolated throwaway Postgres
· **G3 disposition updated in TRACEABILITY** — honestly partial: the
ESSE3-path execution is now real (V2), the QES-provider alternative path
(BOOK-18's separate "QES provider, G3, where not ESSE3" driver row)
remains **NEW-12**, not claimed closed here · BOOK-18 Ch. 3 driver-catalog
row for ESSE3 flipped from ⚪ to ✅ with this sprint's implementation
detail · BOOK-03 Ch. 6 Annex (if one exists) or the nearest normative
reference updated to note the first real circuit-breaker landing ·
constitution (`STUDENT_EXPERIENCE_ARCHITECTURE.md`) §7.3 gains
`degree.recorded`, plus a new numbered section for this sprint · CLAUDE.md
§13 env-var table appended (`ESSE3_*`/`SPID_*`) · `backend/drivers
/__init__.py` docstring broadened (sync duty) · decisions note
(`docs/sprint_decisions_YYYYMMDD_new11.md`) recording: the circuit-breaker
design and its composition with `RetryConfig`, the boundary-tables-vs-
`interop_bridge` decision, the SPID/Keycloak-brokering scope decision
(why no new SPID SP was built) · next: **NEW-12** (PagoPA + QES adapters)
reuses this sprint's boundary-table/circuit-breaker pattern and closes
G3's remaining QES-provider path; **NEW-13** consumes the ANS-completeness
signal this sprint emits and builds the DE/DI ledger (G14) this sprint
only feeds, never builds.
