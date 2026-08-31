# K2 Prompt Pack — Cognition
### DAS BOOK-20 Phase K2 · sprints STX-06 · NEW-01 · NEW-02 (GA gate) · NEW-03 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Prerequisite:** K1 exit gate PASSED (see `../K1/K1-EXIT-REPORT.md`) — the
Event Mesh, TwinContextService, Competency Engine and KG v2.0 are live and
every K2 sprint builds on them.

**Execution rules:** BOOK-20 Ch. 12 bind every sprint — read them first.
Digest: Turnkey `CLAUDE.md` guardrails are absolute (GUID PKs for new tables,
`Integer` only for FKs to `courses.id`, platform vs tenant schema, async routes
/ sync Celery, additive-only migrations with tested downgrade, soft delete,
no column literally named `metadata`, no cross-file `relationship()`);
all V-checks green before DoD; docs sync in the same change set
(constitution + CLAUDE.md + Book Annexes + TRACEABILITY); G/A-register duty;
ontology naming via `dlu-core.yaml` or RFC first; **all LLM calls via the ACP
gateway (ADR-0013) — never direct provider calls**.

## Order and dependencies

```text
NEW-01 (move catalog binding — the symbolic action space)
   └─► STX-06 (ACE runtime + Discovery + WS00 Companion) ─► NEW-03 (memory stores)
NEW-02 (eval harness + crisis protocol — THE GA GATE, build in parallel from day 1)
```

- **NEW-01 first** (small, schema + preconditions engine): STX-06's Decide
  phase consumes `move_bindings`; building the runtime against a stub catalog
  wastes a rework cycle.
- **NEW-02 in parallel from day 1**: it gates every learner-facing deployment
  (`testing → deployed` requires a green harness run). STX-06's Discovery
  Agent and Companion stay in `lifecycle_state='testing'` until NEW-02 passes
  them. **Nothing learner-facing GAs before NEW-02 — no exceptions.**
- **NEW-03 after STX-06**: the PDDAEL runtime ships with M1 working memory and
  the existing `TwinAIMemory` (L7) as its M3 shim; NEW-03 completes episodic
  (M2) + consolidation + retrieval budgets, then STX-06's Perceive/Learn
  phases are upgraded in place.

## Phase exit gate

Harness gates wired to ACP `lifecycle_state` (deployment blocked without a
green run, steward-signed) · **crisis protocol zero-tolerance class live and
negative-tested** · every deployed agent has a complete PDDAEL trace per turn
· deterministic-only degradation demonstrated (gateway down ⇒ L0/L1 moves
serve) · memory deletion + cross-learner isolation verified. Produce
`K2-EXIT-REPORT.md` (verification outputs, `git diff --stat`, register
updates) before requesting K3 prompts.

| Sprint | File | Model rec. (CLAUDE.md §14) |
|--------|------|---------------------------|
| NEW-01 | NEW-01-move-catalog-binding.md | sonnet |
| STX-06 | STX-06-ace-discovery-companion.md | opus for PDDAEL/one-voice design review, sonnet impl |
| NEW-02 | NEW-02-eval-harness-crisis.md | opus (scenario bank + gate design is hard to reverse), sonnet impl |
| NEW-03 | NEW-03-memory-stores.md | sonnet |
