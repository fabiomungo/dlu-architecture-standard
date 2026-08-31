# K1 Prompt Pack — Kernel Foundation
### DAS BOOK-20 Phase K1 · sprints STX-01…05 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Execution rules:** BOOK-20 Ch. 12 bind every sprint — read them first.
Digest: Turnkey `CLAUDE.md` guardrails are absolute (GUID PKs for new tables,
`Integer` only for FKs to `courses.id`, platform vs tenant schema, async routes
/ sync Celery, additive-only migrations with tested downgrade, soft delete,
no column literally named `metadata`, no cross-file `relationship()`);
all V-checks green before DoD; docs sync in the same change set
(constitution + CLAUDE.md + Book Annexes); G/A-register duty; ontology naming
via `dlu-core.yaml` or RFC first.

## Order and dependencies

```text
STX-01 (twin+competency models, identity_map)
   └─► STX-02 (TwinContextService)      ─┐
STX-03 (Event Mesh — THE KEYSTONE)      ─┼─► STX-04 (Competency Engine)
   (03 can start in parallel with 01)    └─► STX-05 (KG v2.0 + overlay consumers)
```

STX-04 needs 01 (models) + 03 (outbox). STX-05 needs 03 (consumers) + 04
(events to consume). STX-02 needs 01; its cache-bust wiring completes when 03
lands.

## Phase exit gate

All sprint V-suites green + BOOK-20 §8.1 criteria 3 (mesh) and the twin/
competency contract tests in place. Produce `K1-EXIT-REPORT.md` (verification
outputs, `git diff --stat`, register updates) before requesting K2 prompts.

| Sprint | File | Model rec. (CLAUDE.md §14) |
|--------|------|---------------------------|
| STX-01 | STX-01-twin-core-identity.md | sonnet (impl) + haiku (tests) |
| STX-02 | STX-02-twin-context-service.md | sonnet |
| STX-03 | STX-03-event-mesh.md | opus for design review inside sprint, sonnet impl |
| STX-04 | STX-04-competency-engine.md | sonnet |
| STX-05 | STX-05-knowledge-graph-v2.md | sonnet + ontology-specialist review |
