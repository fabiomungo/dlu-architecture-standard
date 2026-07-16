# Sprint NEW-01 — Move Catalog Binding
### DAS K2 · self-contained prompt · target: `dlu_builder_tk` · depends: K1 (STX-02/04)

## Role
`backend-dev` implementing the pedagogical move catalog as the symbolic
action space of the cognitive engine (DAS BOOK-09 Ch. 3, BOOK-10 Ch. 2).

## Context — read before coding
1. BOOK-09 Ch. 3.2 — the 17-move catalog (closed set: `elicit`, `hint`,
   `worked_example`, `explain_concept`, `check_retrieval`,
   `generate_formative`, `give_feedback`, `challenge`, `encourage`,
   `reframe_goal`, `replan_path`, `recommend_next`, `recognize_prior`,
   `flag_risk`, `celebrate`, `refer_to_human`, `abstain`) with classes,
   preconditions, autonomy tiers; BOOK-09 Ch. 2 (Diagnose →
   LearnerStateAssessment), Ch. 7.2 (deferral triggers).
2. Existing: `backend/database/models_ai.py` (`AiAgentConfig` /
   `ai_agent_configs`, tenant GUID, `lifecycle_state`, `scope_type/scope_id`),
   AI Management registry routes, STX-02 `TwinContextService`
   (entitlement matrix `AGENT_ENTITLEMENTS` — reuse, do not duplicate),
   STX-04 `CompetencyGraphService` (confidence/status), BKT mastery state.
3. BOOK-10 Ch. 2 deltas are ALL additive on `ai_agent_configs`.

## Deliverables
1. **Move catalog module** `backend/services/pedagogical_moves.py`:
   the closed catalog as data (move → class, autonomy tier, precondition
   spec, envelope-controllable flag); `validate_move(name)` raises loudly on
   unknown moves (same discipline as `event_taxonomy`). Docstring: "amend
   BOOK-09 Ch. 3.2 FIRST (RFC), then this module". Register move nouns in
   `dlu-core.yaml` if graph/event vocabulary is touched (it should not be).
2. **Additive migration** `_new_01_move_bindings.py` on `ai_agent_configs`:
   `move_bindings JSON NULL` (move → {enabled, autonomy_cap}),
   `entitlements JSON NULL` (twin layers readable — mirrors BOOK-06 Ch. 6),
   `envelope_defaults JSON NULL`, `calibration_ref GUID NULL`.
   **Schema constraint (CHECK or validation layer, negative-tested):**
   `refer_to_human` and `abstain` can never be disabled — any write that
   disables them is rejected.
3. **`LearnerStateAssessment`** (Pydantic, in `pedagogical_moves.py` or a
   sibling): typed diagnosis — CAT stage per relevant competency, mastery
   snapshot (BKT bands), affect/engagement signals (twin L6 summary), risk
   flags. Data-derived only: built from TwinContext + Competency Engine
   reads; no free-text fields the LLM could "invent state" into.
4. **Preconditions engine** `check_preconditions(move, assessment, envelope)
   -> MoveDecision(allowed, reasons[])`: reads ONLY `LearnerStateAssessment`
   fields (no hidden context — grep-testable); applies envelope constraints
   then move preconditions then autonomy tier; every denial carries a reason
   (feeds the trace's `candidates_rejected`).
5. **Registry API surface**: extend the AI Management agent config routes
   (GET/PUT move bindings, admin) — validation through the catalog module.

## Verifications
- **V1** an out-of-binding move is blocked and audited (audit row asserted);
  in-binding move with satisfied preconditions passes.
- **V2** no envelope/binding write can disable `refer_to_human`/`abstain`
  (negative test at both the API and the model-validation layer).
- **V3** preconditions engine provably reads only `LearnerStateAssessment`
  fields: property test feeding assessments with sentinel extra attributes —
  decisions identical; plus a grep gate (no `TwinContext` import in the
  preconditions module).
- **V4** unknown move name raises (catalog closed); all 17 moves round-trip
  through bindings serialization.
- **V5** migration up/down/up clean · `pytest -m phase1` green.

## DoD
V1–V5 green · catalog documented as the closed set (constitution §8 note) ·
BOOK-10 Ch. 2 Annex row (ACP deltas) → ✅ · unblocks STX-06 Decide phase.
