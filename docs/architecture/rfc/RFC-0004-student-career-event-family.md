# RFC-0004 — `student_career.*` event family for the canonical StudentCareer domain

Status: Accepted (2026-08-29)

## Problem

`DLU_Student_Lifecycle_Sprint_Backlog_v1.1.md` Sprint 1 (S1-6) requires the new
`backend/domains/student_career/` domain (ADR-0026) to emit domain events per
`DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §34 on every lifecycle transition
(`student.matriculated`, `student.registered`, `student.withdrawn`, etc., produced starting in
Sprint 2's `apply_command()`). `backend/services/event_taxonomy.py`'s registry is explicitly
closed: *"THE REGISTRY IS CLOSED. To add an event type: amend constitution
`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §7.3 + DAS BOOK-04 Ch. 7 FIRST... THEN add the constant
here."* This RFC is that amendment.

A real naming collision exists and must be resolved, not inherited blind: the constitution's §7.3
already registers `student.created` and `student.lifecycle.changed`, both **Twin-level** events
("twin service / n8n (ERPNext)" producer, per the existing table). Per ADR-0026, the new canonical
`StudentCareer.lifecycle_status` is a **separate layer beneath** the Twin — using the spec's literal
`student.*` event names verbatim (as §34 writes them) would make a career-level transition
indistinguishable from a Twin-level one in the same `student.*` event family, exactly the layering
ambiguity ADR-0026 exists to resolve. This RFC therefore registers the new family under a distinct
`student_career.*` prefix, not the literal `student.*` names §34 uses.

## Proposal

Register 19 new closed-taxonomy event types, all producer = `backend/domains/student_career/`
(via `event_outbox.emit_sync`/`emit_async`, the real live outbox — **not**
`domains/enrollment/events.py`'s `EnrollmentEventEmitter`, which is confirmed dead/unwired
scaffolding: no instantiation of it exists anywhere in the codebase outside its own file):

| Event | Fires on transition to | §19 matrix row |
|---|---|---|
| `student_career.created` | career row creation (pre-`APPLICATION_STARTED`) | — |
| `student_career.application_submitted` | `APPLICATION_SUBMITTED` | `APPLICATION_STARTED → APPLICATION_SUBMITTED` |
| `student_career.admission_approved` | `ADMITTED` / `ADMITTED_CONDITIONAL` | `APPLICATION_UNDER_REVIEW → ADMITTED[_CONDITIONAL]` |
| `student_career.admission_accepted` | `ADMISSION_ACCEPTED` | `ADMITTED → ADMISSION_ACCEPTED` |
| `student_career.ready_for_matriculation` | `READY_FOR_MATRICULATION` | `ADMISSION_ACCEPTED → READY_FOR_MATRICULATION` |
| `student_career.matriculated` | `MATRICULATED` | `READY_FOR_MATRICULATION → MATRICULATED` |
| `student_career.registered` | `REGISTERED` | `MATRICULATED → REGISTERED` |
| `student_career.enrolled` | `ENROLLED` | `REGISTERED → ENROLLED` |
| `student_career.activated` | `ACTIVE` | `ENROLLED → ACTIVE` |
| `student_career.never_attended` | `NEVER_ATTENDED` | `ENROLLED → NEVER_ATTENDED` |
| `student_career.leave_started` | `LEAVE_OF_ABSENCE` | `ACTIVE → LEAVE_OF_ABSENCE` |
| `student_career.leave_ended` | `ACTIVE` (from LOA) | `LEAVE_OF_ABSENCE → ACTIVE` |
| `student_career.withdrawal_requested` | `WITHDRAWAL_REQUESTED` | `ACTIVE → WITHDRAWAL_REQUESTED` |
| `student_career.withdrawn` | `WITHDRAWN` | multiple (§19) |
| `student_career.dismissed` | `DISMISSED` | `ACTIVE → DISMISSED` |
| `student_career.transferred_out` | `TRANSFERRED_OUT` | `ACTIVE → TRANSFERRED_OUT` |
| `student_career.program_requirements_completed` | `PROGRAM_REQUIREMENTS_COMPLETED` | `ACTIVE → PROGRAM_REQUIREMENTS_COMPLETED` |
| `student_career.graduated` | `GRADUATED` | `GRADUATION_PENDING → GRADUATED` |
| `student_career.deceased` | `DECEASED` | `any open career → DECEASED` |
| `student_career.reopened` | any terminal state reopened | `REOPEN_CAREER` (§5.1, §30) |

Deliberately **not** registered in this RFC (deferred to their own later sprint/epic, per this
program's own "don't front-load" discipline — see `DLU_Student_Lifecycle_Sprint_Backlog_v1.1.md`
Sprint 3/E-2):
- `student_career.hold.created` / `.released` — Sprint 3 (hold consolidation) scope.
- `student_career.academic_engagement.established` — E-2 epic scope.

Aggregate type for all of these: `"student_career"` (distinct from the existing `"twin"` aggregate
used by `student.lifecycle.changed`).

## Alternatives

1. **Reuse the literal `student.*` names from §34 verbatim.** Rejected — creates the exact
   Twin/career ambiguity ADR-0026 exists to resolve; a consumer subscribing to `student.*` could
   not tell a Twin-level change from a career-level one without inspecting `aggregate_type`, which
   defeats the taxonomy's own purpose of a self-describing event name.
2. **Wire the new domain to `domains/enrollment/events.py`'s `EnrollmentEventEmitter` instead of
   `event_outbox`.** Rejected — that emitter has zero real callers anywhere in the codebase (grep
   confirms no instantiation outside its own file); it is not "the existing event bus" in any live
   sense, despite the Sprint Backlog's S1-6 task text assuming it is. `event_outbox`/
   `event_taxonomy` is the actual live, transactionally-atomic mesh every real producer in this
   codebase uses.

## Security and governance impact

None beyond the standard event-mesh guarantees (tenant-scoped `domain_events` rows, at-least-once
delivery, consumer idempotency on `event_id`) already in place for every other producer.
`student_career.*` payloads carry no new PII beyond what `StudentCareer`/`StudentStatusTransition`
already store.

## Migration and rollout

Additive only — no existing event type is renamed or removed. Sprint 1 (S1-6) registers these
constants and a thin `emit_career_event` helper in the new domain's `events.py`; no code path
actually emits any of them until Sprint 2's `apply_command()` exists (Sprint 1's own scope is
"written to by nobody yet" — the canonical career has no writer until Sprint 2).

## Open questions

None — this RFC only needs to unblock Sprint 1's event-type registration; the exact payload shape
per event is finalized in Sprint 2 alongside `apply_command()`.
