# RFC-0008 — register 13 event nouns already used by DLU_BUILDER

Status: Proposed (2026-10-09) — **awaiting product-owner approval**. Requested by the product
owner (Fabio) on 2026-10-09 ("RFC nel repo DAS"). The registry change ships in the same PR as
this RFC, but it only takes effect when the PR is merged.

## Problem

BOOK-05 Ch. 8 makes `architecture/ontology/dlu-core.yaml` the closed registry of event-type noun
prefixes ("term addition = RFC → registry PR"). `dlu_builder_tk/scripts/ci/lint_ontology.py`
enforces it: the first segment of every event type in `backend/services/event_taxonomy.py` must
be in `event_nouns`. The taxonomy module's header gives the same rule: amend the constitution /
BOOK-04 Ch. 7 first, through an RFC to this repository, and only then add the constant.

Seven deliveries did it the other way round. They added event types to
`event_taxonomy.py`, along with real producers and in one case a consumer, under 13 noun
prefixes that were never registered here. Against `dlu-core.yaml` at `f495a50` the lint
reports **42 violations across 13 nouns** (28 of them are `student_career.*`). As a result
`dlu_builder_tk`'s `kg-gates` CI job was dropped from the required checks on 2026-09-16, the same
day it was added. `dlu_builder_tk/CLAUDE.md` §0.11 records the reason: the nouns "were never run
through the RFC-amends-BOOK-05 process the check itself requires — a real governance gap, not a
CI bug; editing the registry to make the gate pass would rubber-stamp unreviewed vocabulary."

The gap was already partly known in this repository. RFC-0001's comment in `dlu-core.yaml` lists
11 of the 13 nouns as "left for a dedicated ontology sync pass". RFC-0004 and RFC-0005 registered
the 28 `student_career.*` event types in the taxonomy and the constitution (§7.6/§7.7), but never
added the `student_career` noun to the registry. This RFC is that sync pass. It treats the nouns
as vocabulary to review, not as a lint error to suppress.

## Proposal

Register the 13 nouns below in `event_nouns` **verbatim**, with no change to any live event type.
For every noun, the owning Book already lists the event (in PascalCase), so each event has a
normative home. The only thing missing was the registry entry.

Evidence comes from `dlu_builder_tk` at `6b277ba`. "Emitter" is the module that calls
`event_outbox.emit_*`. "Aggregate" is the `(aggregate_type, id)` tuple that the emitter passes.
"Consumers" are the bindings in `backend/services/event_consumer_registry.py`.

| Noun | Definition | Owning Book / domain | Event types | Emitter (`dlu_builder_tk`) | Aggregate type | Consumers | Introduced by |
|---|---|---|---|---|---|---|---|
| `eligibility` | An admissions eligibility verdict on an application (eligible / not eligible + unmet requirements) | BOOK-21 §6 — T1 Admissions | `eligibility.decided` | `backend/services/admission_service.py` | `admission_application` | none | NEW-18 (`c1a513f`, PR #82, 2026-07-30) |
| `orientation` | An orientation recommendation batch for a prospect's application (program suggestions) | BOOK-21 §6 — T1 | `orientation.recommended` | `backend/services/orientation_service.py` (once per batch) | `application` | none | NEW-18 (`c1a513f`) |
| `offer` | An admission offer extended to an applicant and its acceptance | BOOK-21 §6 — T1 | `offer.issued`, `offer.accepted` | `backend/services/admission_service.py` | `admission_offer` | none | NEW-18 (`c1a513f`) |
| `faculty_document` | A document in a faculty member's onboarding journey (identity, fiscal, qualification) and its verification | BOOK-22 §5 — T4 Faculty lifecycle | `faculty_document.verified` | `backend/services/faculty_onboarding_service.py` | `faculty_document` | none | NEW-20a (`28af698`, 2026-07-30) |
| `teaching_assignment` | Confirmation that a faculty member teaches a teaching section (instructor / primary instructor) | BOOK-22 §5 — T9 Workforce | `teaching_assignment.confirmed` | `backend/api/routes/teaching_sections.py` | `faculty_assignment` | `hr-workload` → `hr_workload_consumers:_on_teaching_assignment_confirmed` | NEW-21 (`db45335`, 2026-07-30) |
| `workload` | An entry posted to the faculty workload ledger | BOOK-22 §5 — T9 | `workload.posted` | `backend/services/hr_workload_consumers.py` (emitted by the consumer that posts the ledger entry) | `faculty_workload_entry` | none | NEW-21 (`db45335`) |
| `fiscal_period` (was `period`, renamed by decision 2026-10-09) | Closing a **financial/accounting** period (locks invoice mutation in the period) | BOOK-23 §8 — T7 Finance | `fiscal_period.closed` (was `period.closed`) | `backend/services/period_close_service.py` | `period_close` | none | NEW-30 (`e8cafed`, 2026-08-01) |
| `forecast` | Publishing a **revenue** forecast | BOOK-23 §8 — T7 | `forecast.published` | `backend/services/revenue_forecast_service.py` | `revenue_forecast` | none | NEW-30 (`e8cafed`) |
| `variance` | A thresholded **budget-vs-actual** variance breach, recorded and routed to governance | BOOK-23 §8 — T7 | `variance.flagged` | `backend/services/variance_analysis_service.py` | `variance_analysis` | none | NEW-30 (`e8cafed`) |
| `governance_action` | An executive governance action taken (e.g. in response to a KPI or variance breach) | BOOK-24 §6 — T10 Executive | `governance_action.taken` | `backend/services/governance_action_service.py` | `governance_action` | none | NEW-27 (`b8539d8`, 2026-07-31) |
| `board_resolution` | A resolution passed by the governing board (`budget` resolutions additionally bind budgets) | BOOK-24 §6 — T10 | `board_resolution.passed` | `backend/services/board_service.py` | `board_resolution` | none | NEW-27 (`b8539d8`) |
| `ava` | The DM 1154/2021 AVA accreditation context (GLOSSARY: *AVA*): faculty-requirement evaluation and early-warning alerts | BOOK-26 §12 — accreditation (G22) | `ava.requirement.evaluated`, `ava.alert.fired` | `backend/services/ava_faculty_requirement_service.py`; `backend/services/ava_alert_service.py` (only when a NEW alert opens) | `program`; `ava_alert` | none on the mesh (`workers/ava_alert_worker.py` only tags notifications with `source_event="ava.alert.fired"`) | AVA-03 (`16484c7`), AVA-11 (`25ef636`), 2026-08-04 |
| `student_career` | The canonical `StudentCareer` lifecycle, a layer beneath the Twin (ADR-0026) | RFC-0004/RFC-0005; constitution §7.6/§7.7; BOOK-04 Ch. 7 | 28 types: `student_career.{created, engaged, application_started, application_submitted, application_under_review, waitlisted, admission_approved, admission_accepted, ready_for_matriculation, matriculated, registered, enrolled, activated, never_attended, leave_started, leave_ended, studies_suspended, studies_interrupted, forfeited, withdrawal_requested, withdrawn, dismissed, transferred_out, program_requirements_completed, graduation_pending, graduated, deceased, reopened}` | `backend/domains/student_career/` (`commands.apply_command` → `events.emit_career_event_*`) | `student_career` | `alumni-crm` → `alumni_consumers:_on_career_graduated` (`student_career.graduated`) | RFC-0004/0005 (2026-08-29); code in `3c72229` |

(Count note: the taxonomy holds **28** `student_career.*` constants, and the lint reports 28. RFC-0004's prose says it registers "19", but its own table lists 20 rows (`created` … `reopened`), so RFC-0005's "27 total" inherits an off-by-one. The vocabulary itself is unaffected, and `event_taxonomy.py` is authoritative for the list.)

### Naming review — conflicts and questionable nouns

The current registry and GLOSSARY show no hard collisions: no noun duplicates an existing
`event_nouns` entry or a GLOSSARY term with a different meaning. Several nouns are still weak
enough to flag. **None of the renames below is applied by this RFC.** Each would change a live
event type, which means new constants, a dual-emit or alias window (BOOK-05 Ch. 8.3), consumer
migration and outbox-replay compatibility. Whether to do that is a separate decision for the
product owner.

| Noun | Concern | Proposed rename (not applied) | Severity |
|---|---|---|---|
| `period` | Too generic. In an academic ontology "period" reads as an academic period (`AcademicTerm` is a registered class), but this event is a **fiscal** period close. The emitter's own aggregate is `period_close`. | `fiscal_period` → `fiscal_period.closed` | High |
| `offer` | Too generic, and it sits next to the registered relationship `OFFERS` (Institution/Program *offers* Course/Program — curriculum offering). This event is an **admission** offer. The emitter's own aggregate is `admission_offer`. | `admission_offer` → `admission_offer.issued/accepted` | High |
| `forecast` | Generic: the platform also forecasts graduation (`graduation.predicted`) and risk. This event is specifically a revenue forecast. The emitter's own aggregate is `revenue_forecast`. | `revenue_forecast` → `revenue_forecast.published` | Medium |
| `variance` | Generic, and it collides with the statistical sense of "variance" used throughout the mastery/psychometrics vocabulary (BOOK-06/15). This event is a budget variance. The emitter's own aggregate is `variance_analysis`. | `budget_variance` → `budget_variance.flagged` | Medium |
| `eligibility` | Generic, though at least scoped by its family. Eligibility also exists for financial aid, exam sessions and graduation clearance. | `admission_eligibility` (optional) | Low |
| `workload` | Acceptable. "Faculty workload ledger" is the BOOK-22 term, and the emitter's aggregate is `faculty_workload_entry`. | `faculty_workload` (optional) | Low |
| `ava` | Not an aggregate noun but a bounded-context acronym. The real aggregates are `program` and `ava_alert`, and the event types are three-segment (`ava.requirement.evaluated`, `ava.alert.fired`). The acronym is already a normative GLOSSARY term (BOOK-26), so it is legible. | keep. Alternative: `ava_requirement.evaluated` / `ava_alert.fired` | Low |
| `student_career` | Close to the registered `career` noun (`career.target_changed`, the EKG **job/career-path** layer). This is a deliberate disambiguation (RFC-0004 §Alternatives), not a collision. | keep | — |
| `faculty_document`, `teaching_assignment`, `governance_action`, `board_resolution` | Specific and aligned with each emitter's aggregate type. | keep | — |

Recommendation: register all 13 as-is now so the gate can be made required again. If the
product owner agrees, open one follow-up RFC for the two High items (`period`, `offer`), and
optionally the two Medium ones, using the alias-window process. All four currently have
**zero consumers**, so the migration cost is limited to the emitters and any external
subscribers (n8n). This is the cheapest moment to rename them.

## Decision (product owner, 2026-10-09)

- **Register the nouns, with one rename:** `period` becomes **`fiscal_period`**; the event type
  `period.closed` becomes `fiscal_period.closed`. It is renamed in `dlu_builder_tk` in the same
  change (`event_taxonomy.FISCAL_PERIOD_CLOSED`, one emitter: `period_close_service.py`). No alias
  window is needed (BOOK-05 Ch. 8.3): the event has zero consumers and no external subscriber,
  and the outbox relay does not re-validate event types, so a `period.closed` row already queued
  is still published (to no one).
- **`offer`, `forecast`, `variance`: kept as registered.** The rename proposals below are
  declined; they stay recorded for context.

## Alternatives

1. **Rename now (in this RFC) instead of registering verbatim.** Rejected for this RFC. A rename
   is a change to live event types, not a registry edit: new taxonomy constants, emitter changes,
   an alias window (BOOK-05 Ch. 8.3), and care for rows already in `domain_events` / Redis
   Streams. That is engineering work in `dlu_builder_tk` with its own PR and tests. Keeping the
   registry red until it is done would leave `kg-gates` non-required for longer, and the gate is
   the only thing preventing the next unregistered noun. The renames are proposed above as a
   follow-up decision instead.
2. **Deprecate / remove the events.** Rejected. All 13 nouns have live producers, and two
   have live consumers (`teaching_assignment.confirmed` → HR workload ledger;
   `student_career.graduated` → alumni CRM). Each event is listed in its owning Book's
   events section. Removing them would break shipped features.
3. **Add an `--ignore` / allowlist to `lint_ontology.py` for these nouns.** Rejected. That is
   the silent gate-widening `dlu_builder_tk/CLAUDE.md` §0.11 forbids, and it would leave the
   registry, which BOOK-05 calls the single source of truth, wrong.
4. **Register only the 12 nouns RFC-0001 already listed and leave `student_career` to an
   RFC-0004 erratum.** Rejected as needless ceremony. RFC-0004/0005 already reviewed and accepted
   the vocabulary; only the registry line is missing.

## Security and governance impact

- No runtime change: `event_taxonomy.py` is already the runtime gate (`event_outbox._build_event`
  validates every type), and all 13 nouns' types are already in it. This RFC changes vocabulary
  governance only.
- It closes the governance gap that made `kg-gates` non-blocking (`dlu_builder_tk/CLAUDE.md`
  §0.11). After merge, `kg-gates` can be re-required once its second, separate blocker is fixed:
  no `DAS_REPO_TOKEN` secret, so CI cannot check out this repository. Also, `kg-gates.yml` points
  at `h1gl/dlu-architecture-standard`, while this repository is `fabiomungo/dlu-architecture-standard`.
- The payloads of the 12 non-career events carry no new personal data beyond their source rows.
  `ava.*` carries program-level aggregates only. `student_career.*` is unchanged from RFC-0004.
- Process finding: seven deliveries (NEW-18, NEW-20a, NEW-21, NEW-27, NEW-30, AVA-03, AVA-11) and one RFC
  pair (0004/0005) shipped event nouns without updating this registry, because the lint that would
  have caught it never ran green in CI. The real fix is making `kg-gates` required again. This
  RFC is the precondition for that.

## Migration and rollout

Additive only. Registry entries are added, and no event type, constant, producer or consumer
changes. Same change set (BOOK-00 sync duty):

- `architecture/ontology/dlu-core.yaml` — 13 nouns appended under an RFC-0008 block. RFC-0001's
  "left for a dedicated ontology sync pass" comment now points here.
- `BOOK-04` Ch. 7 (Aggregate ↔ Event Map) — rows for the T1/T4-T9/T7/T10/AVA/StudentCareer
  families, which the map never carried.
- `BOOK-05` Annex A — the "Registry + CI gates" row records the drift and this reconciliation.
- `TRACEABILITY.md` — A6 row annotated, plus an RFC-0008 section.
- `CHANGELOG.md` — entry.
- GLOSSARY: no entries added. No previous event-noun registration (RFC-0001/0002, NEW-17f,
  NEW-33, EKG-W0/W1) added per-noun glossary rows. The only glossary-grade term here, *AVA*, is
  already defined (BOOK-26).

Verification: `ONTOLOGY_REGISTRY=<this repo>/architecture/ontology/dlu-core.yaml python3
scripts/ci/lint_ontology.py`, run from `dlu_builder_tk`, goes from **FAIL, 42 violations / 13
nouns** to **OK, exit 0**.

Follow-ups outside this repository (not done here):
- `dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §7 — add a pointer section for
  RFC-0008. The 12 non-student families are owned by BOOK-04 Ch. 7, not the constitution, but
  the taxonomy header names both.
- `dlu_builder_tk` `.github/workflows/kg-gates.yml` — repository owner fixed (dlu_builder #547; the
  repo is public, no `DAS_REPO_TOKEN` needed); checkout pinned to `das-k1-kernel-foundation`
  (dlu_builder, same change as the `fiscal_period` rename); then re-require the check with a dated
  decision in CLAUDE.md §0.11.
- Refresh the vendored registry fallback in `dlu_builder_tk`, if one is kept.

## Open questions

1. **Approval (product owner):** accept the 13 nouns verbatim?
2. ~~**Renames**~~ — decided 2026-10-09: `period` → `fiscal_period` in this RFC; the others are
   kept (see "Decision").
