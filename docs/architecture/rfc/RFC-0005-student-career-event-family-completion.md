# RFC-0005 — complete the `student_career.*` event family with the 8 statuses RFC-0004 missed

Status: Accepted (2026-08-29)

## Problem

RFC-0004 registered 19 `student_career.*` event types by walking
`DLU_Student_Lifecycle_Regulatory_State_Model_v1.0.md` §34's own prose list. Building Sprint 2's
transition engine against the FULL §19 matrix (34 rows, `backend/domains/student_career/
transitions.py`) surfaced that §34's list is incomplete relative to §19: §34 never mentions
`ENGAGED_PROSPECT`, `APPLICATION_STARTED`, `APPLICATION_UNDER_REVIEW`, `WAITLISTED`,
`STUDIES_SUSPENDED`, `STUDIES_INTERRUPTED`, `FORFEITED`, or `GRADUATION_PENDING` as event-producing
transitions, even though §19's matrix has real transition rows landing on every one of them. Found
the hard way: `tests/conformance/test_student_transitions.py` raised `UnknownEventTypeError` the
first time a real `apply_command()` call reached `SUSPEND_STUDIES`/`INITIATE_GRADUATION_WORKFLOW`
— confirming this is a genuine registry gap, not a test bug.

## Proposal

Register the 8 missing event types, same producer/aggregate as RFC-0004
(`backend/domains/student_career/`, aggregate `"student_career"`, via `event_outbox`):

| Event | Fires on transition to |
|---|---|
| `student_career.engaged` | `ENGAGED_PROSPECT` |
| `student_career.application_started` | `APPLICATION_STARTED` |
| `student_career.application_under_review` | `APPLICATION_UNDER_REVIEW` |
| `student_career.waitlisted` | `WAITLISTED` |
| `student_career.studies_suspended` | `STUDIES_SUSPENDED` |
| `student_career.studies_interrupted` | `STUDIES_INTERRUPTED` |
| `student_career.forfeited` | `FORFEITED` |
| `student_career.graduation_pending` | `GRADUATION_PENDING` |

This brings the family to 27 event types total (19 from RFC-0004 + 8 here), one per canonical
`StudentLifecycleStatus` value that is reachable as a `to_status` in the §19 matrix — every value
except `PROSPECT` itself (never a transition target, only the initial state a career is created at).

## Alternatives

**Wait and register incrementally, event by event, as each is first needed.** Rejected — this is
exactly what RFC-0004 already did (registering only the 19 events §34's prose happened to name) and
is what produced this gap in the first place. Registering the complete, matrix-derived set now,
while the full transition table is in hand, is cheaper than re-discovering each missing one via a
future `UnknownEventTypeError` at a less convenient time.

## Security and governance impact

None beyond RFC-0004's own (unchanged).

## Migration and rollout

Additive only. `backend/domains/student_career/events.py`'s `LIFECYCLE_STATUS_TO_EVENT` map gains
these 8 entries alongside the existing 18 (`ACTIVE` already covered both `ENROLLED→ACTIVE` and
`LEAVE_OF_ABSENCE→ACTIVE` under one event, so RFC-0004's 19 constants cover 18 distinct
`LIFECYCLE_STATUS_TO_EVENT` keys, not 19 — the 19th, `student_career.reopened`, is `REOPEN_CAREER`-
specific and keyed by command, not by `to_status`, so it was never part of this map).

## Open questions

None.
