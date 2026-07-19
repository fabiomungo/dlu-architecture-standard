# Sprint STX-03 — Event Mesh: Outbox + Redis Streams + Closed Taxonomy
### DAS K1 · THE KEYSTONE · self-contained prompt · target: `dlu_builder_tk`

> **STATUS: ✅ DONE 2026-07-14** — V1–V7 green · design-review note
> `docs/sprint_decisions_20260714_stx03.md` · constitution §7 marked
> implemented · BOOK-03 Annex A mesh row ✅ · TRACEABILITY A6 closed ·
> STX-04 and STX-05 unblocked (STX-02 pending — twin-sync bumps
> twin_version directly until TwinContextService lands).

## Role
`backend-dev` (with an opus-class design review pass before merge)
implementing the Academic Event Mesh (DAS BOOK-03 Ch. 4; constitution §7 —
including the R1-amended taxonomy with `assessment_session.*`, `thesis.*`,
`committee.*` families; BOOK-04 Ch. 7).

## Context
1. Constitution §7.1–7.3 (transport, envelope, full taxonomy table).
2. Existing: `backend/services/event_service.py` (in-memory — to be
   dual-published then superseded), `backend/services/kg_event_bus.py`,
   Redis conventions (`REDIS_URL`), Celery app (`backend/workers/celery_app.py`),
   OTel instrumentation, `docs/EVENT_CATALOG.md` (to be superseded with a
   banner pointing to the taxonomy module).
3. Strangler rule (BOOK-18 Ch. 1): old EventService keeps working and
   **dual-publishes** through the outbox during this sprint; retirement is a
   later mechanical PR after a parity report.

## Deliverables
1. **Model**: `DomainEvent` in new `backend/database/models_student_experience.py`
   (tenant schema, GUID PK = event_id, fields per constitution §7.1) +
   additive migration `_stx_03_domain_events.py` (indexes on event_type,
   tenant_id, occurred_at, published_at-null partial).
2. **Taxonomy module** `backend/services/event_taxonomy.py`: the closed set as
   constants (every row of constitution §7.3 incl. R1 families), envelope
   Pydantic model (event_id, event_type, occurred_at, tenant_id, actor,
   aggregate, payload, trace_id), `validate(event) -> None|raise` — unknown
   type raises loudly. Docstring: "amend constitution §7.3 + BOOK-04 Ch. 7
   FIRST (RFC), then this module".
3. **Producer API** `backend/services/event_outbox.py`:
   `emit(db_session, event_type, aggregate, payload, actor=None)` — writes the
   outbox row **in the caller's transaction** (works with both AsyncSession
   and sync Session — two thin entry points); captures current OTel trace_id.
4. **Relay**: Celery beat task every 2 s — publishes unpublished rows to
   Redis Stream `dlu:events:{tenant_id}` (XADD), marks published_at;
   batch-limited; idempotent on redelivery.
5. **Consumer framework** `backend/services/event_consumers.py`:
   base class with consumer-group registration (`twin-sync`, `kg-sync`,
   `reco`, `success-watch`, `n8n-bridge`), XREADGROUP loop (Celery worker
   entrypoint), **idempotency** via processed-set (Redis SET of event_ids per
   group, TTL ≥ stream retention), ack/pending recovery, dead-letter after N
   attempts, per-group lag metric exported to Prometheus.
6. **First consumers wired**: `twin-sync` handler for `profile.updated` →
   `TwinContextService.bump_version` (completes the STX-02 TODO); stub
   handlers logging for the other groups.
7. **Producers wired** (dual-publish where legacy exists):
   `mastery_tracking_service` → `mastery.updated`; xAPI ingestion →
   `activity.recorded`; course workflow transitions → course events;
   consent changes (STX-02) → `consent.changed` (add to taxonomy module —
   already in BOOK-04 Ch. 7).
8. **Trace propagation**: relay puts trace_id in the stream entry; consumers
   restore it as span link — request → event → consumer visible in Tempo.
9. **Docs**: `EVENT_CATALOG.md` banner ("superseded for kernel events by
   `event_taxonomy.py` / constitution §7.3"); stream retention configured
   ≥ 7 days (XTRIM policy documented).

## Verifications
- **V1 atomicity**: test — service raises after `emit()` → transaction rolls
  back → no outbox row, nothing published.
- **V2 idempotency (mandatory)**: same event delivered twice to a consumer
  group → handler side effect exactly once (duplicate test with forced
  redelivery via XCLAIM).
- **V3 closed set**: emitting an unregistered type raises; consumer receiving
  unknown type rejects loudly + dead-letters (negative tests).
- **V4 trace**: integration test asserts trace_id equality across producer
  span and consumer span (OTel in-memory exporter).
- **V5 replay**: events re-readable from stream ≥ 7 days (XRANGE on seeded
  history; retention config test).
- **V6 lag metric**: Prometheus endpoint exposes per-group lag; alert rule
  file added to `monitoring/`.
- **V7 regression**: legacy EventService consumers still receive (dual-publish
  parity assertion); `make dev-unit` + `pytest -m phase1` green.

## DoD
V1–V7 green · design-review note committed (`docs/sprint_decisions_*.md`) ·
constitution §7 marked implemented · BOOK-03 Annex A mesh row → ✅ ·
TRACEABILITY sprint row updated · next: STX-04, STX-05 unblocked.
