# Sprint NEW-12 — PagoPA + QES Adapters (completes G9, closes G3's QES path)
### DAS K5 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-11 (circuit breaker + driver-package pattern, executed first), NEW-08 (the PagoPA stub + IssuedDocumentCredential being replaced/signed), NEW-06 (CommitteeVerdict's G3 boundary being closed for real) · opus design review already completed — see `docs/sprint_decisions_YYYYMMDD_new12.md` once written

## Role
`backend-dev` executing an opus-reviewed architecture (QES-vs-ESSE3
routing, signature round-trip, PagoPA cache-vs-live-call choice)
completing **G9** (BOOK-16 Ch. 6.2 — the PagoPA half NEW-08 deferred) and
closing the remaining **G3** path (BOOK-16 Ch. 8 — "executed in ESSE3 or
a QES provider"; NEW-11 closed the ESSE3 half, this sprint closes the
QES-provider half).

## Context — read before coding
1. **The exact stub being replaced, verbatim contract (frozen, do not
   change the shape):** `backend/drivers/pagopa_stub.py`'s
   `PagoPAStubDriver.check_bollo_payment_status(tenant_id, twin_id,
   document_type: str) -> BolloPaymentStatus` where `BolloPaymentStatus
   = @dataclass(frozen=True) {paid: bool, status: str, reference:
   Optional[str], checked_at: datetime}`. The stub's own docstring
   already committed to the real shape: *"OAuth2 client-credentials
   auth, POST to PagoPA's payment-position API, webhook-driven status
   callbacks."* The ONE call site is
   `backend/services/document_credential_service.py::
   generate_diploma_supplement`, which branches on `.paid` only (never
   `.status` string-matching) and raises `BolloPaymentRequiredError`
   (→ HTTP 402) before any expensive ELM-lite assembly if unpaid.
   Self-certifications and transcripts are NOT bollo-gated — do not
   widen that without cause.
2. **G3 boundary, verbatim (BOOK-16 Ch. 8):** step 2 — *"Legal act
   (driver): verbale with qualified electronic signature (FEA/QES per
   eIDAS in Italy), legal preservation (conservazione a norma) —
   executed in ESSE3 or a QES provider; DLU MUST NOT reimplement
   either."* Step 4 names a third path — *"Native mode (greenfield/
   corporate, unregulated credentials): DLU's signed VC IS the act; no
   external dependency"* (already real, STX-13). **BOOK-16 Ch. 8 does
   NOT specify a trigger condition for ESSE3-vs-QES-provider** — this
   sprint resolves it (Deliverable 1), it is not decided elsewhere.
3. **G9, verbatim (BOOK-16 Ch. 6.2):** *"Official certificates (with
   stamp duty / bollo, payments via PagoPA in Italy): DLU generates
   content; stamp duty, payment and signature/seal are driver acts
   (PagoPA driver, ESSE3/registrar seal — BOOK-18). The G3 doctrine
   again: content native, legal act at the driver."* Note this
   literally names "ESSE3/registrar" as the Diploma Supplement's seal
   driver — for an institution NOT running ESSE3 (the `qes_provider`
   slot, Deliverable 1), the QES driver this sprint builds is what
   performs that seal instead; this sprint makes that substitution
   explicit rather than leaving non-ESSE3 institutions with no way to
   complete a Diploma Supplement at all.
4. **Existing patterns this sprint reuses, never reinvents:**
   `backend/domains/payments/` (Stripe) — `PaymentIntentRecord.status`
   is a webhook-written, never-live-queried cached-last-known-status
   column (the *shape* to copy for `pagopa_payment_position.status`;
   Stripe's SDK-only retry, `stripe.max_network_retries=2`, is
   deliberately NOT the resilience layer to copy — that's NEW-11's
   `CircuitBreaker`+`RetryConfig`+`RateLimiter` composition).
   `backend/integrations/frappe/webhook_verifier.py` (HMAC-SHA256 over
   the raw body, `hmac.compare_digest`, replay window, idempotency-key
   dedup) — the base both new webhook routes reuse, same as NEW-11
   reused it for `ESSE3_GATEWAY_SECRET`.
   `backend/services/committee_service.py::close_verbalization` — the
   G3 one-shot closer (`pending_verbalization → False`,
   `verbalization_external_ref` set) this sprint's QES callback calls
   INTO for verbale acts, unmodified.
   **`backend/drivers/circuit_breaker.py` and `backend/drivers/esse3/`
   are NEW-11's deliverables — treat their API as a SPEC to mirror
   (quoted in NEW-11's own prompt), not as verified-in-code, unless
   NEW-11 has actually been executed by the time this sprint starts.**
   No PAdES/QES/eIDAS signing capability exists anywhere in this
   codebase today (grep-confirmed) — the QES driver is a from-scratch
   build, fixture/mock-fed (no live PagoPA or QES provider is reachable
   in this environment, same discipline every driver sprint this phase
   has used).
5. **No PagoPA/QES technical source citations exist anywhere in the
   Masterbook** — this sprint is the first to add them (a public
   PagoPA "Nodo dei Pagamenti" checkout-API reference and a generic
   eIDAS-qualified-TSP remote-signing API reference; cite generically,
   never as if one commercial vendor were contractually chosen — BOOK-18's
   own catalog row says "QES provider," not a named product).
6. **Surfaces are minimal.** No new learner/faculty UI — this sprint is
   driver plumbing plus whatever minimal payment-initiation route a
   student needs to actually start a bollo payment (the gating READ
   path already exists via `generate_diploma_supplement`; what's
   missing is the WRITE path that creates a `pagopa_payment_position`
   in the first place).

## Guardrails
Additive-only migration — two new `platform`-schema tables
(`pagopa_payment_position`, `qes_signature_ref`) plus their
`*_notification_log` idempotency tables, named constraints, tested
`downgrade()`. New PKs `GUID()`; soft GUID refs only
(`dlu_document_credential_id`, `dlu_committee_verdict_id`,
`dlu_twin_id`) — no cross-schema `relationship()`, matching every other
boundary table this phase has used (NEW-11's `esse3_verbale_ref`,
`interop_bridge.external_identifiers`). `qes_signature_ref` gets a
`CheckConstraint` enforcing exactly one of
`dlu_document_credential_id`/`dlu_committee_verdict_id` is non-null —
never both, never neither.

## Deliverables
1. **Per-tenant legal-act driver slot** — `Institution.config["legal_act
   _driver"] ∈ {"esse3", "qes_provider", "native_vc"}` (the existing
   `Institution.config` JSON column, no migration needed for the slot
   itself) — one uniform slot per tenant, analogous to ADR-0009's
   student-records slot. `esse3` routes G3 acts through NEW-11's
   `grade.synced` path (unchanged); `qes_provider` routes through this
   sprint's QES driver (both verbale acts AND, per Context point 3, the
   Diploma Supplement seal); `native_vc` uses the existing STX-13 VC
   engine (unchanged). A `resolve_legal_act_driver(institution)` helper
   is the single place this routing decision is made — no call site
   duplicates the branch.
2. **QES driver package** — `backend/drivers/qes/` (`client.py`,
   `auth.py`, `notifications.py`, `config.py`, `exceptions.py`,
   `health.py`, `models.py`), mirroring NEW-11's `esse3/` layout.
   Submits a SHA-256 hash (+ config-toggleable raw-bytes support for
   TSPs requiring it) of an assembled, unsigned PDF for remote PAdES
   signing; the returned signed PDF is stored under a new
   `signed_pdf_storage_key` (same `StorageManager` convention as the
   existing `pdf_storage_key`). Guarded status machine
   `pending_signature → sent_to_provider → signed → attached`
   (+ terminal `failed`), one-shot per row, mirroring
   `VERDICT_STATUS_TRANSITIONS`'s guard-table discipline.
3. **`qes_signature_ref` table** (`platform` schema): `id`, `tenant_id`,
   `dlu_document_credential_id` (nullable), `dlu_committee_verdict_id`
   (nullable, CheckConstraint: exactly one non-null),
   `provider_signature_id` (unique), `signature_format`
   (`'PAdES'`/`'CAdES'`), `signed_pdf_storage_key` (nullable until
   signed), `certificate_ref` (nullable), `status`, `submitted_at`,
   `signed_at`, `attached_at`, `error`. On a verbale signature-completion
   callback, the handler flips this row to `attached` THEN calls the
   existing `committee_service.close_verbalization(db, tenant_id,
   verdict_id, external_ref=provider_signature_id)` unmodified — the QES
   path is a structural sibling of NEW-11's ESSE3/`grade.synced` path,
   never a parallel reimplementation of verbalization-closure.
4. **PagoPA driver package** — `backend/drivers/pagopa/` (same file
   layout as `qes/`). `client.py`: OAuth2 client-credentials token
   fetch, `POST` to the payment-position API wrapped by
   `RateLimiter → RetryConfig → CircuitBreaker` (NEW-11's composition,
   invoked only from the payment-INITIATION write path, never from the
   gating read path). `check_bollo_payment_status` becomes a pure DB
   read of the cached `pagopa_payment_position` row for
   `(tenant_id, twin_id, document_type)` — **never a live call** (BOOK-18's
   own "financial-status cache holds last-known" phrase, Stripe's
   proven shape for exactly this kind of notification-driven payment
   flow) — returning the identical frozen `BolloPaymentStatus` shape,
   a literal drop-in replacement for `pagopa_stub_driver` at
   `document_credential_service.py`'s one call site. No row found ⇒
   `paid=False, status="not_initiated"` (an honest new status string,
   never fabricated as `"unpaid"` when payment was simply never
   started).
5. **`pagopa_payment_position` table** (`platform` schema): `id`,
   `tenant_id`, `dlu_twin_id`, `dlu_document_credential_id` (nullable —
   a position may be created before the DS row exists), `document_type`,
   `iuv` (unique — PagoPA's own Identificativo Univoco Versamento),
   `notice_number`, `amount_cents`, `status`
   (`created|pending|paid|expired|failed`, webhook-written only),
   `paid_at`, `created_at`/`updated_at`.
6. **Two HMAC webhook routes + a shared verifier base** —
   `backend/api/routes/pagopa.py` (`POST /api/internal/pagopa-notifications`,
   `PAGOPA_WEBHOOK_SECRET`) and `backend/api/routes/qes.py`
   (`POST /api/internal/qes-notifications`, `QES_PROVIDER_WEBHOOK_SECRET`),
   both in `EXEMPT_PATHS`, both idempotent via their own
   `pagopa_notification_log`/`qes_notification_log` tables (cloned
   shape from NEW-11's `esse3_notification_log`). Generalize
   `frappe/webhook_verifier.py` into a small, reusable HMAC-verification
   base (parameterized by secret + header names) both routes depend on,
   rather than each driver hand-rolling its own copy — the one piece of
   code these two otherwise-separate drivers legitimately share.
7. **Payment-initiation route** — a minimal `POST` endpoint (student- or
   staff-triggered, tenant-scoped) that creates a `pagopa_payment_position`
   row and calls the PagoPA client's outbound `create_payment_position`
   — the write-side half `check_bollo_payment_status`'s read-only cache
   needs to ever become non-empty.
8. **Env vars** — `PAGOPA_BASE_URL`, `PAGOPA_CLIENT_ID`,
   `PAGOPA_CLIENT_SECRET`, `PAGOPA_TOKEN_URL`, `PAGOPA_WEBHOOK_SECRET`,
   `PAGOPA_PA_FISCAL_CODE`, `PAGOPA_STATION_ID`; `QES_PROVIDER_BASE_URL`,
   `QES_PROVIDER_CLIENT_ID`, `QES_PROVIDER_CLIENT_SECRET`,
   `QES_PROVIDER_WEBHOOK_SECRET`, `QES_PROVIDER_CREDENTIAL_ID`,
   `QES_PROVIDER_TECH_USER` — appended to CLAUDE.md §13 in the same
   change set.

## Verifications
- **V1** PagoPA fixture round-trip: seed a `pending` position, feed an
  HMAC-signed payment-outcome fixture callback, assert
  `pagopa_notification_log` written, `status → "paid"`, `paid_at` set,
  then `check_bollo_payment_status(...).paid is True`; replay the
  identical payload ⇒ idempotent no-op, no double-write; a twin with no
  position ⇒ `paid=False, status="not_initiated"`.
- **V2** QES fixture round-trip, verbale path: seed a `CommitteeVerdict`
  with `pending_verbalization=True` and a `qes_signature_ref` in
  `sent_to_provider`; feed an HMAC-signed signature-completion fixture;
  assert `qes_notification_log` written, `ref.status → "signed" →
  "attached"`, `signed_pdf_storage_key` set, AND the linked verdict's
  `pending_verbalization → False`, `verbalized_at` set,
  `verbalization_external_ref == provider_signature_id` — i.e.
  `close_verbalization` actually ran, reused unmodified.
- **V3** QES fixture round-trip, Diploma Supplement path: same as V2 but
  `qes_signature_ref.dlu_document_credential_id` set instead of a
  verdict — asserts the DS-sealing substitution (Context point 3) works
  identically for a `qes_provider`-slot tenant, and that an
  `esse3`-slot tenant's Diploma Supplement never touches this table at
  all (structural negative check).
- **V4** legal-act routing: `resolve_legal_act_driver` returns exactly
  `esse3`/`qes_provider`/`native_vc` per `Institution.config`, and no
  call site branches on the slot value itself (grep-based structural
  check, mirroring NEW-06's sole-writer negative-test technique) —
  every routing decision goes through the one helper.
- **V5** PagoPA outbound resilience: mocked-transport test proving the
  circuit breaker opens after configured consecutive failures on
  `create_payment_position`, and that a transient single-failure-then-
  success sequence never opens it (reuses NEW-11's own V5 technique,
  proving composition-with-retry, not just that a breaker object
  exists).
- **V6** bollo-gate visibility preserved: `generate_diploma_supplement`
  still visibly blocks (402, clear reason) when
  `pagopa_payment_position` has no `paid` row for that twin/document —
  the exact NEW-08 V4 guarantee, now backed by a real (not stub) status
  source, never silently regressed by this sprint's replacement.

## DoD
V1–V6 green · `pytest -m phase1` green · migration
`upgrade`/`downgrade`/`upgrade` verified on an isolated throwaway
Postgres · **G9 disposition updated in TRACEABILITY** — now fully closed
(NEW-08's content-native half + this sprint's PagoPA-driver half) ·
**G3 disposition updated in TRACEABILITY** — now fully closed for both
named paths (NEW-11's ESSE3 execution + this sprint's QES-provider
execution; native-VC was already closed at STX-13) · BOOK-18 Ch. 3
driver-catalog rows for PagoPA and QES provider flipped from ⚪ to ✅ ·
BOOK-16 Ch. 6.2/Ch. 8 Annex notes updated with the resolved ESSE3-vs-
QES-provider trigger condition (Context point 2 — this was genuinely
undecided in the Book before this sprint) · CLAUDE.md §13 env-var table
appended · decisions note (`docs/sprint_decisions_YYYYMMDD_new12.md`)
recording: the per-tenant `legal_act_driver` slot design, the QES
round-trip state machine, the PagoPA cache-vs-live-call decision (and
why, unlike Moodle/Frappe's live-ping health check, PagoPA's status
read is cache-only), and the DS-sealing-via-QES scope decision (Context
point 3) · next: **NEW-13** builds the compliance registers/ledgers this
phase's driver sprints (NEW-11, NEW-12) only ever fed signals into,
never built themselves.
