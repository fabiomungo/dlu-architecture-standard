# Sprint STX-09 — Recommendations v2 + WS03 Knowledge Map
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: K1, K2 (gateway narration), STX-07 (path_alignment input)

## Role
`backend-dev` + `frontend-dev` (DAS constitution §10; BOOK-01 Ch. 7
personalization bounds; BOOK-13 Ch. 5–6 learner plane; BOOK-17 WS03).

## Context — read before coding
1. Constitution §10 — the three-stage pipeline, verbatim: stage 1
   candidate generation (existing rules + KG traversal + spaced-
   repetition due items, ~30 candidates) → stage 2 deterministic ranking
   (`w1·gap_relevance + w2·path_alignment(GPS) + w3·engagement_fit +
   w4·urgency`) → stage 3 LLM narration via the gateway that **may not
   reorder or add items**. §10.1 the `recommendations` table (
   `explanation_trace` mandatory), §10.2 non-negotiables (idempotency per
   `(twin_id, rec_type, payload_hash, day)`; consent degradation).
2. Existing (repo-verified):
   - `recommendation_engine.py` — the rule-based engine (mastery/
     temporal/engagement/completion triggers, DB-driven via
     `recommendation_rules` + `personalization_contexts`) becomes
     **stage 1**, not a rewrite; keep its existing route surfaces green
     (knowledge_mastery/mastery/pacing/search recommend endpoints —
     strangler).
   - The mesh `reco` consumer group in `event_consumers.py` is a
     **logging stub** — this sprint gives it real handlers
     (recommendation invalidation/refresh on mastery/competency/path
     events).
   - **No `recommendations` table, no `/api/recommendations` route** —
     both net-new (constitution §10.1/§14); migration chains off the
     current head.
   - `spaced_repetition_service.py` — full SM-2 (`get_due_reviews`,
     `initialize_schedule_from_mastery`): due items are stage-1
     candidates here; the Coach assembles them into *missions* in STX-10
     (same source, two consumers — don't duplicate the queue).
   - `kg_query_service` (STX-05) for frontier/gap traversal
     (`PREREQUISITE_FOR`-satisfied next concepts, `DEVELOPS` toward gap
     competencies); `KNOWS`/`EVIDENCES` learner overlay (kg_overlay_sync)
     powers the WS03 map.
   - STX-07's `path_scenarios` + adopted path → the `path_alignment`
     ranking weight (the GPS influences daily suggestions without
     micromanaging — BOOK-14 Ch. 7.2).
   - Frontend: `KnowledgeMastery`, `MasteryDashboard`, vis-network graph
     components exist for reuse in WS03; mirror the WS00 triad pattern
     (`pages/student/` + `components/`, lazy route, one `*API.js`).
3. **K2 debt intake (README):** (a) Discovery's `explain_concept`
   grounding gap — stage-1's KG/catalog retrieval path is the natural
   grounding source; wire Discovery's `_grounding_refs` to the
   program-catalog read this sprint builds (BOOK-10 Ch. 3 card). (b) the
   `ace.py` `/api/brain/memory/{id}` DELETE ownership check — mechanical
   fix while you're in the file (mirror the hardened
   `/api/twin/me/memory/{id}` route from NEW-03).
4. BOOK-01 Ch. 7: the serendipity quota is a personalization *bound* —
   a slice of every slate is deliberately off-model, labeled
   *"something different"* (BOOK-17 Ch. 7.2); never personalize the
   canon.
5. BOOK-06 Ch. 8.3: the learner MAY contest any displayed L3/L4 state —
   WS03's contest affordance files a HITL item (move_proposal/agent_
   proposals queue), never silently edits state.

## Deliverables
1. **Three-stage pipeline** (`recommendation_service_v2.py` or evolved
   engine): stage 1 candidates (existing rules + KG traversal + SM-2 due
   + serendipity pool), stage 2 deterministic ranking with inspectable
   weights, stage 3 gateway narration rendering card text from the
   ranking trace only (schema-constrained: item ids in = item ids out,
   order preserved).
2. **Persistence + API**: `recommendations` table per §10.1 (GUID,
   tenant, additive migration) — `explanation_trace` (rule ids, KG paths,
   weights) NOT NULL by schema; status flow
   proposed→shown→accepted/dismissed/expired with `recommendation.*`
   mesh events (closed taxonomy — the accept/dismiss stream is the
   feedback loop KPI). Routes per §14: `GET /api/recommendations/me`,
   `POST /{id}/accept`, `POST /{id}/dismiss`, `GET /{id}/explanation`.
3. **Non-negotiables wired**: idempotency per
   `(twin_id, rec_type, payload_hash, day)` — a re-run refreshes, never
   duplicates (no nagging); consent degradation —
   `ai_personalization=false` ⇒ rule-stage, course-scoped candidates
   only (no behaviour/career/GPS inputs), honestly labeled; serendipity
   quota present and labeled in every full slate.
4. **`reco` consumer goes real**: mastery/competency/path events
   invalidate + refresh affected recommendation slates (budgeted — no
   per-event full recompute).
5. **WS03 Personal Knowledge Map (Grow)**: the L4 graph
   mastery-colored (KNOWS overlay), frontier ("ready to learn"), gap
   paths toward goal competencies; contest affordance on any displayed
   state → HITL item; triad complete (canvas + companion bias + missions
   = today's recommendations incl. the serendipity slot).
6. **K2 debt chores**: Discovery `explain_concept` grounded via the
   program-catalog source; `ace.py` memory-DELETE ownership check
   (404-on-unowned, matching NEW-03's hardened route).

## Verifications
- **V1** narration cannot alter the item set: contract test — stage-3
  output ids ≡ stage-2 input ids, order preserved; a mutating narration
  is rejected and the deterministic fallback text serves.
- **V2** a recommendation without `explanation_trace` is invalid at the
  schema layer (insert attempt fails; API never returns one).
- **V3** idempotency: same twin/type/payload/day re-run ⇒ no duplicate
  row, no duplicate notification.
- **V4** consent degradation: `ai_personalization=false` ⇒ slate contains
  only rule-stage course-scoped items; restoring the flag resumes full
  pipeline (mirrors NEW-03's consent-amnesia test shape).
- **V5** serendipity quota: every full slate contains the labeled
  off-model slot; quota respected over N fixture slates.
- **V6** contest: contesting a WS03 state files a HITL item and changes
  nothing until a human acts (negative test on direct mutation).
- **V7** Discovery grounding: `explain_concept` now carries
  `_grounding_refs` from the catalog source (the NEW-02 scenario that
  found the gap now passes) · `ace.py` DELETE ownership negative test ·
  migration up/down/up clean · `pytest -m phase1` + legacy recommend
  endpoints green (strangler).

## DoD
V1–V7 green · constitution §10 marked implemented · BOOK-01 Annex
personalization-guardrails row + BOOK-13 learner-plane row updated ·
TRACEABILITY K3 row updated · decisions note (weight defaults w1–w4 +
serendipity quota % are v1 policy knobs — document as such) · next:
STX-10 consumes SM-2 due queue for Coach review missions.
