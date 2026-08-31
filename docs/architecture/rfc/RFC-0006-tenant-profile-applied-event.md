# RFC-0006 — `tenant.profile.applied` event for the tenant configuration bundle feature

Status: Accepted (2026-08-31)

## Problem

`docs/DLU_Tenant_Bundle_Feature_Evaluation_v1.0.md` (`dlu_builder_tk`) proposes a versioned "tenant
profile bundle" import/export feature: a small, personal-data-free JSON envelope (subdomain, country,
tier, and the existing `dlu_tenant_profile_v1`-shaped configuration) that can be exported from one
tenant, committed to git, and applied to another. Applying a bundle writes a new row to a new
`tenant_profile_editions` table (immutable, self-FK lineage, mirroring `CatalogEdition`) and must emit a
domain event so the rest of the mesh can react to a tenant's configuration changing — the same way every
other state-changing write in this codebase does.

`backend/services/event_taxonomy.py`'s own header states the registry is closed: *"THE REGISTRY IS
CLOSED. To add an event type: amend constitution `docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §7.3 + DAS
BOOK-04 Ch. 7 FIRST... THEN add the constant here."* This RFC is that amendment. `backend/services/
event_outbox.py`'s `_build_event()` calls `event_taxonomy.validate(event_type)` unconditionally at
runtime — an unregistered event type is a hard failure the first time a producer tries to emit it, not
a lint warning.

Three `tenant.*` event constants already exist in the registry — `TENANT_PROVISIONED`,
`TENANT_SUSPENDED`, `TENANT_DELETED` (registered under the BOOK-04 Ch. 7 "Tenant (C2)" aggregate row).
None fits "a configuration bundle was applied to an existing tenant" — confirmed by direct grep that
none of the three currently has a single live producer anywhere in the codebase either, so this is, in
practice, the first event this repository will actually emit under the Tenant (C2) aggregate.

## Proposal

Register one new closed-taxonomy event type under the existing Tenant (C2) aggregate:

| Event | Fires on |
|---|---|
| `tenant.profile.applied` | A `tenant_profile_editions` row is written for a tenant — i.e. a profile bundle (or a direct `PUT /admin/tenants/{id}/profile` call) is successfully applied, producing a new immutable edition. Not fired on a dry-run, and not fired on an idempotent no-op re-apply of an already-current bundle (same `sha256` as the latest edition). |

Producer: `backend/api/routes/admin_tenants.py`'s profile-bundle import route (and, if `PUT
/admin/tenants/{id}/profile` is later updated to also write an edition row, that route too), via
`event_outbox.emit_async` — the same live, transactionally-atomic outbox every other real producer in
this codebase uses. Aggregate type: `"tenant"` (matches the existing `TENANT_PROVISIONED`/`SUSPENDED`/
`DELETED` convention, distinct from `"student_career"`/`"twin"`/etc.).

Payload (informative, not part of the taxonomy contract itself): `edition_id`, `bundle_id`,
`supersedes_edition_id`, `changed_fields` (the ordinary/regulated diff keys, never full before/after
profile values — the payload must not become a second place personal-data-adjacent configuration
history lives, even though the profile itself carries no personal data).

## Alternatives

1. **Reuse `TENANT_PROVISIONED`.** Rejected — a re-provisioning event is not what happened; a consumer
   reacting to "tenant provisioned" (e.g. a welcome-email trigger) would misfire on every later
   configuration change to an already-live tenant.
2. **No event at all — the `tenant_profile_editions` row itself is the audit trail.** Rejected — every
   other write of comparable significance in this codebase (holds, career transitions, catalog
   editions) emits a domain event in addition to its own row; a tenant's regulatory configuration
   changing (currency, jurisdiction, SIS integration) is exactly the kind of fact other subsystems
   (KG projection, EKG, future compliance dashboards) should be able to react to without polling a new
   table nobody else knows exists yet.
3. **A broader `tenant.updated` covering every mutable tenant field (name, tier, profile, etc.).**
   Rejected for now — `PATCH /admin/tenants/{id}` already exists and today emits nothing; conflating
   "configuration/profile changed" (a regulated, reviewable, edition-tracked axis) with "display name
   changed" (an ordinary CRUD field) would blur exactly the distinction the profile-editions table
   exists to keep sharp. A future `tenant.updated` for the other fields is a separate RFC if that need
   materializes.

## Security and governance impact

None beyond the standard event-mesh guarantees (tenant-scoped `domain_events` rows, at-least-once
delivery, consumer idempotency on `event_id`) already in place for every other producer. The payload is
explicitly scoped (above) to exclude full profile values, keeping this event free of the personal-data
concerns the bundle feature's own design (§3 of the evaluation doc) was built to avoid — the profile
itself never carries personal data, but the event payload still shouldn't become a second full history
of it outside the `tenant_profile_editions` table.

## Migration and rollout

Additive only — no existing event type is renamed or removed. No code path emits this event until the
tenant-profile-bundle import route is built and reaches its apply (non-dry-run, non-idempotent-no-op)
branch; this RFC only unblocks registering the constant.

## Open questions

None — this RFC only needs to unblock the constant's registration; the exact `payload` dict shape is
finalized alongside the import route's own implementation.
