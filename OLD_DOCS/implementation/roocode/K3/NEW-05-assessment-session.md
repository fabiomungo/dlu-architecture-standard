# Sprint NEW-05 — AssessmentSession: the Appello Aggregate (G2)
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-08 (evidence ingress), NEW-04 (edge seam)

## Role
`backend-dev` + light `frontend-dev` (WS06 calendar half), resolving
G-register item **G2** (DAS BOOK-15 Ch. 5; BOOK-14 Ch. 3 examination-
decoupled model). Write a short design note on the native/mirror mode
boundary before implementing.

## Context — read before coding
1. BOOK-15 Ch. 5 — the aggregate, verbatim contract:
   `AssessmentSession (C6, GUID, tenant): assessment_ref · course_id ·
   term_id · session_date/window · enrollment_opens/closes · capacity ·
   location/modality · committee_id (nullable — NEW-06) · status
   (planned→open→closed→graded→finalized) · policy: min_sessions_rule
   ref · attempt_caps · grade_refusal_allowed`. Learner flow:
   self-enrollment within windows → enrollee list → communications →
   sitting → grading → result publication → (policy) grade-refusal
   window → retake eligibility.
2. **Grade refusal (rifiuto del voto)** — the subtle rule: a learner
   decision event on a *passing* result; the **mastery product stands**
   (they demonstrably know it — BKT updates normally); the *official*
   evidence enters the STX-08 pipeline **only on acceptance**. The GPS
   prices the retake (BOOK-14 `RETAKE` expected-value semantics).
3. **Two deployment modes, one aggregate** (tenant policy): *native*
   (DLU authoritative — greenfield/corporate) and *mirror* (ESSE3
   authoritative: sessions/enrollments/verbali mirror in via the driver;
   DLU adds intelligence — readiness prediction, session recommendation,
   list analytics). The full ESSE3 driver is NEW-11 (K5): this sprint
   ships the mirror-mode *contract* + a fixture-fed ingestion path, not
   the driver.
4. Existing (repo-verified): **fully greenfield** — no session/calendar/
   enrollment-window tables exist anywhere (`__tablename__` grep clean);
   the event taxonomy **already reserves**
   `assessment_session.published/changed` (constitution §7.3);
   `enrollment_service.py` exists for course enrollment (different
   concern — don't overload it); notification system exists for
   communications; `grading_service` grades attempts; STX-08 pipeline is
   the evidence ingress; NEW-04's `SIT_EXAM`/`RETAKE` edge seam awaits
   this feed. Migration chains off the current head.
5. Minimum-session rules (e.g. 3 sessions in winter/summer periods) are
   policy objects validated at **calendar publication** — a course
   failing its minimum is an I4 operational alert before it becomes a
   student complaint (BOOK-08).
6. Accommodations (BOOK-15 Ch. 11): L1 accessibility preferences apply
   automatically at session level, privately — no disclosure in enrollee
   lists.

## Deliverables
1. **Aggregate + migration**: `assessment_sessions` (tenant, GUID) per
   the Ch. 5 contract + enrollment rows (learner ↔ session, windowed,
   capacity-checked) + status machine with guarded transitions
   (additive migration, tested downgrade).
2. **Calendar + publication flow**: faculty/registrar publishes a term's
   session calendar (minimal API — the full FW2 surface is NEW-09/K4);
   publication validates minimum-session policy (violation ⇒ I4 alert,
   publication still possible with explicit override, audited); emits
   `assessment_session.published/changed` on the mesh.
3. **Learner flow**: self-enrollment within windows (capacity + attempt
   caps enforced; accommodations applied privately), withdrawal,
   communications via the existing notification system; result
   publication; **grade-refusal window** where
   `grade_refusal_allowed` — refusal keeps mastery, defers official
   evidence, sets retake eligibility.
4. **Evidence integration (STX-08)**: finalized session results enter
   the pipeline (`source_kind="assessment_session"`, proctored/official
   trust class 0.9); refused grades enter **nothing official** until
   acceptance; mirror-mode results enter with their external
   source_kind.
5. **Mirror mode contract**: ingestion interface + fixture: an external
   (ESSE3-shaped) session + enrollments + result set imports into the
   same aggregate with `mode="mirror"`; native-mode writes are blocked
   for mirrored sessions (authority boundary — BOOK-07 §6.3).
6. **GPS edge feed**: published sessions materialize as
   `SIT_EXAM`/`RETAKE` edges through NEW-04's seam (session calendar
   granularity, enrollment windows, capacity); calendar changes emit
   traffic events that recompile the affected map region.
7. **WS06 calendar half**: sessions calendar canvas (upcoming sessions,
   enrollment state, windows) + readiness surface rendering **with
   hedging** (bands + assumptions; the readiness *model* matures in
   STX-11 — render whatever exists honestly, no fake precision).
   Companion bias and the full WS06 triad complete in STX-11.

## Verifications
- **V1** refusal semantics: passing result refused ⇒ BKT/mastery
  updated, **zero** official `EvidenceRecord`, retake eligibility set;
  acceptance ⇒ evidence enters with correct trust (integration with
  STX-08).
- **V2** minimum-session violation at publication ⇒ I4 alert emitted
  (fixture: 2 sessions where policy requires 3).
- **V3** mirror mode: external session fixture ingests; native mutation
  of a mirrored session is rejected; the aggregate reads identically in
  both modes.
- **V4** readiness renders with hedging: band + assumptions present in
  the API payload; no point-estimate-only rendering (contract test).
- **V5** lifecycle events: publish/change emit taxonomy-valid mesh
  events; enrollment windows + capacity + attempt caps enforced
  (negative tests); `SIT_EXAM` edges appear for an entitled fixture
  learner after publication.
- **V6** migration up/down/up clean · `pytest -m phase1` green.

## DoD
V1–V6 green · **G2 disposition updated in TRACEABILITY** (aggregate
delivered; ESSE3 mirror driver remains NEW-11) · BOOK-15 Annex
AssessmentSession row + BOOK-14 Annex session-granular-routing row
updated · constitution §7.3/§14 sync (new routes) · design note on the
native/mirror boundary in `docs/sprint_decisions_*.md` · next: STX-11
completes WS06 + readiness prediction targeting these sessions.
