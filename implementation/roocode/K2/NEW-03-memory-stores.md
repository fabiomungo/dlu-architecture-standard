# Sprint NEW-03 — Memory Stores (M2 episodic + consolidation + retrieval)
### DAS K2 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-06

## Role
`backend-dev` implementing the four-store memory architecture
(DAS BOOK-12; BOOK-09 Ch. 9 contract).

## Context — read before coding
1. BOOK-12 Ch. 2 (store contracts M1–M4), Ch. 3 (consolidation R8 —
   extractive-first, supersession-not-mutation, ≤ 200 active M3 rows/twin),
   Ch. 4 (retrieval at Perceive, budgets, consent amnesia, cross-learner
   isolation HARD rule), Ch. 5 (course/institution scopes are PROHIBITED
   memory channels), Ch. 6 (forgetting by design).
2. Existing: `TwinAIMemory` (STX-01 — already carries `episode_refs` +
   `superseded_by` lineage columns), `ace_cycle_traces` + M1 Redis
   blackboard (STX-06), chroma vector substrate (RAG stack),
   `TwinContextService._fetch_ai` (L7 assembly — already filters
   superseded/expired), STX-02 consent gating, `/api/twin` memory panel
   (WS00), cognitive-budget stub from STX-06.
3. M2 is the record of AI interactions; xAPI/Caliper activity is kernel
   data — do NOT conflate (normative distinction, BOOK-12 Ch. 2).

## Deliverables
1. **M2 episodic store**: `ace_session_summaries` tenant table (GUID,
   additive migration `_new_03_memory_stores.py`) — per-session interaction
   summary generated at session close (Celery task; verbatim transcripts
   stay short-retention operational data); `agent_run_logs` linkage;
   twin-scoped vector index over summaries + traces in the chroma substrate
   (collection keyed per twin — isolation at the storage key, BOOK-12
   Ch. 4.4).
2. **M3 lineage completion** on `TwinAIMemory`: writes go through a single
   `MemoryWriteService` (ACE Learn phase is the only caller): atomicity/
   sourcing quality bar (one fact per row, episode citations required,
   inspectable phrasing), contradiction ⇒ superseding row linked via
   `superseded_by` + old row expired (never mutated); protected-attribute
   and third-party-fact rejection list (negative-tested).
3. **Consolidation missions (R8)**: session-close light pass + nightly
   Celery mission (cognitive-budget capped): extractive-first (quote the
   learner over inferring; inferences = `memory_type=summary`, confidence,
   ≥ 2 supporting episodes), salience scoring (recency × stakes ×
   repetition; retrieval strengthens), **volume discipline**: per-twin M3
   budget (default ≤ 200 active rows) with merge/expiry compression —
   consolidation that only grows is a failure.
4. **Retrieval assembly at Perceive** (upgrade STX-06 in place): M3 by
   salience × purpose relevance + M2 vector hits when the trigger suggests
   history; injection within the per-agent context budget with truncation
   markers; the trace records which memories were injected (explanations
   can cite them). `agent_key`-scoped rows only to their agent.
   **Consent amnesia:** `ai_personalization=false` ⇒ M2/M3 retrieval
   returns nothing (the engine is politely amnesic).
5. **Learner control**: DELETE endpoint on the WS00 memory panel
   (`/api/twin/me/memory/{id}`) — immediate effect, honored at next
   assembly; deletion cascades to vector index entries; audit row.
6. **M4 procedural (seed)**: L1 decision cache TTL discipline (STX-06) +
   per-(move, preset) calibration state table, release-scoped
   (inherited-but-flagged on new releases) — the store NEW-02's calibration
   seed writes into.

## Verifications
- **V1** supersession preserves lineage: contradicting fact ⇒ new row,
  `superseded_by` chain intact, old row expired, learner sees only the
  current fact, auditor sees the chain.
- **V2** deletion effective at next assembly: delete via API ⇒ subsequent
  `get_context`/Perceive contains neither the row nor its vector hit.
- **V3** cross-learner isolation fuzz: retrieval for twin A over a store
  seeded with N random twins never returns another twin's memory (property
  test at the storage layer + a NEW-02 harness privacy scenario).
- **V4** memory budget: exceeding the per-twin cap triggers compression
  (merge/expire) — row count returns within budget, nothing silently
  dropped without an expiry mark.
- **V5** consent amnesia: `ai_personalization=false` ⇒ Perceive injects
  zero memories; flag restored ⇒ retrieval resumes.
- **V6** migration up/down/up clean · `pytest -m phase1` green.

## DoD
V1–V6 green · BOOK-12 Annex rows ✅ · BOOK-06 L7 "memory control" row
updated (deletion live) · STX-06 Perceive/Learn upgraded in place (traces
now cite injected memories) · K2 exit report can be assembled.
